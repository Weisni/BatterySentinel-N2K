"""R4 mechanical audit and placement-aware routing, with explicit critical nets."""
from __future__ import annotations
import argparse
from collections import defaultdict
import copy
import hashlib
import json
import math
from pathlib import Path
import sys
import time

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tmp/pcb-python'))
import numpy as np
from shapely.geometry import Point,LineString,Polygon,box
from shapely import affinity
from shapely.ops import unary_union
from altium_pcb import footprint,transform
from route_altium_r3 import Router,DEFAULTS,LAYERS,extract_pads,verify_routing,board_geometry,add_ground_fills,_shape,_polygons,_hole_free


def component_holes(data):
    holes=[]
    for c in data['components']:
        for h in c.get('pcb_footprint',{}).get('holes',[]):
            x,y=transform(c,h['x'],h['y'])
            holes.append(dict(x=x,y=y,drill=h['drill'],ref=c['ref'],clearance=h.get('copper_clearance_mm',.25)))
    return holes


class R4Router(Router):
    def __init__(self,data,cfg):
        super().__init__(data,cfg)
        critical=fixed_routes(data)
        self.usb_reference=unary_union([_shape(t).buffer(.3) for t in critical['tracks'] if t['net'].startswith('USB_D')])
        self.switch_shadow=unary_union([_shape(t).buffer(.3) for t in critical['tracks'] if t['net'].startswith('SW_')])

    def fixed_obstacles(self,net,radius):
        block=super().fixed_obstacles(net,radius)
        for h in component_holes(self.data):
            block|=self.raster(Point(h['x'],h['y']).buffer(h['drill']/2),h['clearance']+radius+self.margin)
        if net!='GND_LOGIC':block[1]|=self.raster(self.usb_reference,radius+self.margin)
        if net not in ('GND_LOGIC','GND_BUS'):block[1]|=self.raster(self.switch_shadow,radius+self.margin)
        return block

    def route_net(self,net):
        pads=self.pads_by_net[net]
        if len(pads)<2:
            self.net_results[net]=dict(complete=True,pads=len(pads),connections=0);return True
        block=self.obstacles(net,self.width_for(net)/2)
        viablock=self.obstacles(net,self.cfg['via_diameter']/2).any(axis=0)
        free=np.zeros((self.ny,self.nx),dtype=bool)
        for p in pads:
            if p['drill']:free|=self.pad_masks[id(p)]
            else:viablock|=self.raster(p['geometry'],self.cfg['via_diameter']/2+.15)
        for v in self.vias:
            if v['net']==net:free|=self.raster(Point(v['x'],v['y']).buffer(.01))
        cx=sum(p['x'] for p in pads)/len(pads);cy=sum(p['y'] for p in pads)/len(pads)
        remaining=sorted(pads,key=lambda p:(p['x']-cx)**2+(p['y']-cy)**2)
        connected=[remaining.pop(0)];done=0
        def closure():
            geometries={l:[p['geometry'] for p in connected if l in p['layers']] for l in LAYERS}
            pieces=[dict(layers=(t['layer'],),g=_shape(t)) for t in self.tracks if t['net']==net]
            pieces += [dict(layers=LAYERS,g=_shape(v)) for v in self.vias if v['net']==net]
            pieces += [dict(layers=p['layers'],g=p['geometry'],pad=p) for p in list(remaining)]
            changed=True
            while changed:
                changed=False
                union={l:unary_union(geometries[l]).buffer(1e-7) for l in LAYERS}
                for it in list(pieces):
                    if any(it['g'].intersects(union[l]) for l in it['layers']):
                        for l in it['layers']:geometries[l].append(it['g'])
                        if it.get('pad') is not None:
                            connected.append(it['pad']);remaining.remove(it['pad'])
                        pieces.remove(it);changed=True
            tree=np.zeros((2,self.ny,self.nx),dtype=bool)
            for i,l in enumerate(LAYERS):
                g=unary_union(geometries[l])
                if not g.is_empty:tree[i]=self.raster(g)
            return tree
        tree=closure()
        def start_island(p):
            # A manually placed escape via belongs to its pad even when that
            # island has not reached the main tree. Start from the whole island.
            gs={l:[p['geometry']] if l in p['layers'] else [] for l in LAYERS}
            pieces=[dict(layers=(t['layer'],),g=_shape(t)) for t in self.tracks if t['net']==net]
            pieces += [dict(layers=LAYERS,g=_shape(v)) for v in self.vias if v['net']==net]
            changed=True
            while changed:
                changed=False;unions={l:unary_union(gs[l]).buffer(1e-7) for l in LAYERS}
                for it in list(pieces):
                    if any(it['g'].intersects(unions[l]) for l in it['layers']):
                        for l in it['layers']:gs[l].append(it['g'])
                        pieces.remove(it);changed=True
            nodes=np.zeros((2,self.ny,self.nx),dtype=bool)
            for i,l in enumerate(LAYERS):
                g=unary_union(gs[l])
                if not g.is_empty:nodes[i]=self.raster(g)
            return nodes
        while remaining:
            remaining.sort(key=lambda p:min((p['x']-q['x'])**2+(p['y']-q['y'])**2 for q in connected))
            found=False
            for p in list(remaining):
                path=self.search(start_island(p),tree,block,viablock,free)
                if path is None:continue
                self.path_copper(net,path,free)
                connected.append(p);remaining.remove(p);done+=1
                tree=closure()
                for v in self.vias:
                    if v['net']==net:free|=self.raster(Point(v['x'],v['y']).buffer(.01))
                found=True;break
            if not found:
                self.net_results[net]=dict(complete=False,pads=len(pads),connections=done,missing=[p['ref']+'.'+p['number'] for p in remaining]);return False
        self.net_results[net]=dict(complete=True,pads=len(pads),connections=done);return True


def fixed_routes(data):
    parts={c['ref']:c for c in data['components']}
    pads={(p['ref'],p['number']):p for p in extract_pads(data)}
    tracks=[];vias=[]
    def pin(ref,n):
        p=pads[ref,str(n)];return (p['x'],p['y'])
    def wire(net,points,width=.2,layer='TOP'):
        for a,b in zip(points,points[1:]):
            if a==b:continue
            tracks.append(dict(net=net,layer=layer,x1=a[0],y1=a[1],x2=b[0],y2=b[1],width=width))
    def via(net,x,y):
        vias.append(dict(net=net,x=x,y=y,diameter=.6,drill=.3));return (x,y)
    # Connector/TVS/choke/CAN chain, deliberately routed before the power and
    # logic nets. Two local vias resolve the choke winding pin-order crossover.
    wire('CANH_EXT',[pin('J1',4),(4.55,19),pin('D3',1),(7.75,20.8),pin('L1',1)],.2)
    wire('CANL_EXT',[pin('J1',5),pin('D3',2),via('CANL_EXT',6.5,22.65)],.2)
    wire('CANL_EXT',[(6.5,22.65),(10,22.65),via('CANL_EXT',11.2,21.425)],.2,'BOTTOM')
    wire('CANL_EXT',[(11.2,21.425),pin('L1',2)],.2)
    wire('CANH',[pin('L1',4),(7.1,25.325),(7.1,23.8),(8.5,22.4),(13.515,22.4),pin('U1',7)],.2)
    wire('CANL',[pin('L1',3),(12.3,23.925),(12.3,23.135),pin('U1',6)],.2)
    # Both switching nodes stay entirely on top. The short under-package
    # approach uses the free channel between pin rows, avoiding BST and FB.
    wire('SW_BUS',[pin('U3',5),(11.5,10.45),(10,10.45),(9,9.45)],.5)
    wire('SW_BUS',[pin('U3',5),pin('C24',2)],.4)
    wire('BST_BUS',[pin('U3',6),pin('C24',1)],.2)
    wire('SW_LOGIC',[pin('U4',5),(29.5,14.0),(28,14.0),pin('L3',1)],.5)
    wire('SW_LOGIC',[pin('U4',5),pin('C31',2)],.4)
    wire('BST_LOGIC',[pin('U4',6),pin('C31',1)],.2)
    # Quiet feedback take-off comes from output capacitors, not the switch node.
    fb_bus=via('5V_BUS',10,9);out_bus=via('5V_BUS',8,5)
    wire('5V_BUS',[pin('U3',1),fb_bus],.2)
    wire('5V_BUS',[fb_bus,(10,7.4),(8,5.4),out_bus],.2,'BOTTOM')
    wire('5V_BUS',[out_bus,pin('C23',1)],.3)
    wire('5V_BUS',[pin('L2',2),(6,7.4),pin('C22',1),pin('C23',1),pin('C25',1)],.5)
    wire('5V_BUS',[pin('C25',1),(13.67,6.05),pin('U2',1)],.5)
    fb_logic=via('3V3_LOGIC',28,12.55);out_logic=via('3V3_LOGIC',23.1,12.5)
    wire('3V3_LOGIC',[pin('U4',1),fb_logic],.2)
    wire('3V3_LOGIC',[fb_logic,(26.5,12.55),out_logic],.2,'BOTTOM')
    wire('3V3_LOGIC',[out_logic,pin('C32',1)],.25)
    wire('3V3_LOGIC',[pin('L3',2),(22.4,13.35),(21.95,12.9),pin('C32',1),pin('C33',1)],.5)
    # Short VIN ties and local ground stitching around the switching cells.
    wire('BUS_PROT',[pin('U3',2),pin('U3',3),pin('C20',1)],.4)
    wire('5V_SYS',[pin('U4',2),pin('U4',3),pin('C29',1)],.4)
    a=via('GND_BUS',12.7,12.15);b=via('GND_BUS',15.9,10.5)
    wire('GND_BUS',[pin('U3',4),a],.4);wire('GND_BUS',[pin('C20',2),b],.4)
    wire('GND_BUS',[a,(14.1,10.95),(15.45,10.95),b],.5,'BOTTOM')
    wire('GND_BUS',[pin('C22',2),pin('C23',2)],.5)
    wire('GND_BUS',[pin('C22',2),via('GND_BUS',6.925,2)],.4)
    a=via('GND_LOGIC',31.25,15.6);b=via('GND_LOGIC',35.1,12.1)
    wire('GND_LOGIC',[pin('U4',4),a],.4);wire('GND_LOGIC',[pin('C29',2),b],.4)
    wire('GND_LOGIC',[a,(34.75,12.1),b],.5,'BOTTOM')
    wire('GND_LOGIC',[pin('C32',2),pin('C33',2),via('GND_LOGIC',25.4,7.75)],.4)
    # Reversible USB-C D+/D- crossover stays on top and below/above the pad row.
    dm1,dm2=pin('J2','B7'),pin('J2','A7');dp1,dp2=pin('J2','A6'),pin('J2','B6')
    wire('USB_DM_IN',[dm1,(dm1[0],7.75),(dm2[0],7.75),dm2],.15)
    wire('USB_DM_IN',[(dm1[0],7.75),(41.105,7.95),pin('D6',1)],.15)
    wire('USB_DP_IN',[dp1,(dp1[0],6.05),(dp2[0],6.05),dp2,(dp2[0],7.65),(43.005,7.85),pin('D6',3)],.15)
    # ST USBLC6 connects 1--6 and 3--4 inside the die. Distinct input/output
    # PCB nets make the intended flow-through path explicit without a stub.
    wire('USB_VBUS',[pin('D6',5),(42.055,10.24),(40.25,10.24),pin('D4',2)],.3)
    wire('GND_LOGIC',[pin('D6',2),(42.055,9.75),via('GND_LOGIC',44.1,9.75)],.2)
    wire('GND_LOGIC',[pin('C12',2),via('GND_LOGIC',24.4,28.7)],.2)
    wire('3V3_LOGIC',[pin('R7',1),via('3V3_LOGIC',35.6,16.35)],.25)
    wire('USB_DM',[pin('D6',6),(41.105,12.15),(44.2,12.15),(45.1,13.05),(45.1,16.8),
                    (47.1,18.8),(47.1,21.5),pin('R11',1)],.15)
    wire('USB_DP',[pin('D6',4),(43.655,11.8),(44.55,11.8),(45.55,12.8),(45.55,16.8),
                    (47.55,18.8),(47.55,25.8),pin('R12',1)],.15)
    wire('USB_DM_MCU',[pin('R11',2),pin('MCU1',13)],.15)
    wire('USB_DP_MCU',[pin('R12',2),pin('MCU1',14)],.15)
    return dict(tracks=tracks,vias=vias)


def component_body(c):
    w,h=footprint(c).body
    return affinity.translate(affinity.rotate(box(-w/2,-h/2,w/2,h/2),c['pcb'].get('rotation',0),origin=(0,0)),c['pcb']['x'],c['pcb']['y'])


def mechanical_audit(data):
    parts={c['ref']:c for c in data['components']}
    bodies={r:component_body(c) for r,c in parts.items() if not r.startswith('TP')}
    pads=extract_pads(data)
    board=board_geometry(data,0)
    errors=[];minimum_body=math.inf;minimum_pad_body=math.inf
    for ref,b in bodies.items():
        if not parts[ref].get('allow_body_overhang') and not board.buffer(1e-6).covers(b):
            errors.append(dict(kind='body_outside',ref=ref,bounds=b.bounds))
    for i,(a,ba) in enumerate(bodies.items()):
        for b,bb in list(bodies.items())[i+1:]:
            small=any('0603' in parts[r]['footprint'] for r in (a,b))
            required=.25 if small else .5
            gap=ba.distance(bb);minimum_body=min(minimum_body,gap)
            if gap<required-1e-6:errors.append(dict(kind='body_gap',a=a,b=b,gap=round(gap,4),required=required))
    for p in pads:
        for ref,b in bodies.items():
            if p['ref']==ref:continue
            gap=p['geometry'].distance(b);minimum_pad_body=min(minimum_pad_body,gap)
            if gap<.15-1e-6:errors.append(dict(kind='pad_body',pad=p['ref']+'.'+p['number'],body=ref,gap=round(gap,4)))
    for x,y in data['board']['holes_mm']:
        head=Point(x,y).buffer(2.4)
        for ref,b in bodies.items():
            if b.intersects(head):errors.append(dict(kind='screw_body',ref=ref,x=x,y=y))
        for p in pads:
            if p['geometry'].intersects(head):errors.append(dict(kind='screw_pad',ref=p['ref'],pin=p['number'],x=x,y=y))
    blank=verify_routing(data,dict(tracks=[],vias=[]))
    errors += [e for e in blank['errors'] if e['kind']!='unconnected']
    return dict(passed=not errors,errors=errors,minimum_body_gap=minimum_body,minimum_pad_body_gap=minimum_pad_body,
                policy='0.5 mm package-to-package, 0.25 mm when a 0603 passive is involved; 0.15 mm pad-to-foreign-body; no components below castellated module; 4.8 mm screw heads')


def extra_routing_checks(data,result):
    from route_altium_r3 import copper_items
    errors=[]
    items=copper_items(data,result)
    for h in component_holes(data):
        shape=Point(h['x'],h['y']).buffer(h['drill']/2,quad_segs=64)
        for it in items:
            gap=shape.distance(it['geometry'])
            if gap<h['clearance']-1e-5:
                errors.append(dict(kind='component_hole',ref=h['ref'],x=h['x'],y=h['y'],item=it['label'],gap=gap))
    if result.get('regions'):
        reference=unary_union([it['geometry'] for it in items if it['net']=='GND_LOGIC' and 'BOTTOM' in it['layers']])
        checked=0
        for i,t in enumerate(result['tracks']):
            if t['net'].startswith('USB_D'):
                checked+=1
                if _shape(t).difference(reference.buffer(1e-6)).area>1e-8:
                    errors.append(dict(kind='usb_reference_gap',track=i,net=t['net']))
        result['usb_reference_review']=dict(passed=not any(e['kind']=='usb_reference_gap' for e in errors),
            checked_tracks=checked,description='Every USB data track has uninterrupted GND_LOGIC copper beneath its full projected width. Full-speed 12 Mbit/s only; no controlled-impedance claim.')
    return errors


def route_board(data,attempts=None):
    import random
    cfg=dict(DEFAULTS,**data.get('routing_constraints',{}));cfg['width_by_net']=dict(cfg['width_by_net'])
    cfg['width_by_net'].update({n:.15 for n in ['USB_DM_IN','USB_DP_IN','USB_DM','USB_DP','USB_DM_MCU','USB_DP_MCU','USB_CC1','USB_CC2']})
    if attempts is not None:cfg['attempts']=attempts
    nets=sorted({p['net'] for c in data['components'] for p in c['pins'] if p.get('net')})
    priority=['USB_CC1','USB_CC2','USB_VBUS','GPIO7','ESP_EN','ESP_BOOT','ESP_GPIO8','ESP_GPIO2',
              'TXD','RXD','GPIO6','BUS_PROT','FUSED_IN','NET_S','5V_ISO','5V_SYS',
              '3V3_LOGIC','5V_BUS','SHIELD','GND_BUS','GND_LOGIC']
    order=[n for n in nets if n not in priority]+[n for n in priority if n in nets]
    best=None;start=time.time();rng=random.Random(48)
    for attempt in range(cfg['attempts']):
        router=R4Router(data,cfg);fixed=fixed_routes(data)
        router.tracks=copy.deepcopy(fixed['tracks']);router.vias=copy.deepcopy(fixed['vias'])
        for net in order:
            completed=router.route_net(net)
            print(f'Attempt {attempt+1}: {net}: {"OK" if completed else "FAILED"}, {len(router.tracks)} tracks/{len(router.vias)} vias',flush=True)
        result=dict(tracks=router.tracks,vias=router.vias,net_results=router.net_results,constraints=cfg,
                    stats=dict(attempt=attempt+1,expansions=router.expansions,
                               completed_nets=sum(n['complete'] for n in router.net_results.values()),total_nets=len(nets)))
        result['verification']=verify_routing(data,result,cfg)
        result['verification']['errors']+=extra_routing_checks(data,result)
        result['verification']['passed']=not result['verification']['errors']
        score=(len(result['verification']['errors']),-result['stats']['completed_nets'],len(result['vias']))
        if best is None or score<best[0]:best=(score,result)
        if result['verification']['passed']:break
        failed=[n for n in order if not router.net_results[n]['complete']]
        rest=[n for n in order if n not in failed]
        if attempt%2:rng.shuffle(rest)
        order=failed+rest
    result=best[1]
    if result['verification']['passed']:
        # Main ESP current must not use the 0.2 mm feedback sensing branch.
        # This dedicated 0.5 mm feed ties the output-capacitor/L3 copper to the
        # existing broad MCU supply island through the output take-off via.
        for layer,a,b in [('TOP',(22.5,12.3),(22.9,12.3)),
                          ('TOP',(22.9,12.3),(23.1,12.5)),
                          ('BOTTOM',(23.1,12.5),(24.2,12.5))]:
            result['tracks'].append(dict(net='3V3_LOGIC',layer=layer,x1=a[0],y1=a[1],x2=b[0],y2=b[1],width=.5))
        result['verification']=verify_routing(data,result,cfg)
    if result['verification']['passed'] and cfg['ground_fill']:
        add_ground_fills(data,result,cfg)
        holes=unary_union([Point(h['x'],h['y']).buffer(h['drill']/2+h['clearance']+.025,quad_segs=64) for h in component_holes(data)])
        regions=[]
        for region in result['regions']:
            g=Polygon(region['points'],region.get('holes',[])).difference(holes)
            for p in _polygons(g):
                for piece in _hole_free(p):
                    if piece.area<1e-6:continue
                    regions.append(dict(net=region['net'],layer=region['layer'],points=[[round(x,7),round(y,7)] for x,y in list(piece.exterior.coords)[:-1]],holes=[]))
        result['regions']=regions
        result['verification']=verify_routing(data,result,cfg)
        # Subtracting mechanical holes can detach a tiny fill fragment. Retain
        # only regions connected to actual same-net copper after that cut.
        removed=0
        while True:
            orphaned={int(e['item'][1:]) for e in result['verification']['errors'] if e['kind']=='unconnected_region'}
            if not orphaned:break
            result['regions']=[r for i,r in enumerate(result['regions']) if i not in orphaned]
            removed+=len(orphaned)
            result['verification']=verify_routing(data,result,cfg)
        result['stats']['removed_orphan_regions']=removed
        result['verification']['errors']+=extra_routing_checks(data,result)
        result['verification']['passed']=not result['verification']['errors']
    result['stats'].update(track_count=len(result['tracks']),via_count=len(result['vias']),region_count=len(result.get('regions',[])),
        track_length_mm=sum(math.hypot(t['x2']-t['x1'],t['y2']-t['y1']) for t in result['tracks']),elapsed_seconds=time.time()-start)
    result['source_design_sha256']=hashlib.sha256(json.dumps(data,sort_keys=True,separators=(',',':')).encode('utf8')).hexdigest()
    return result


def preview(data,path,routing=None):
    from html import escape
    w,h=data['board']['width_mm'],data['board']['height_mm'];s=22;m=35
    X=lambda x:m+x*s;Y=lambda y:m+(h+7-y)*s
    rows=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{w*s+2*m}" height="{(h+7)*s+2*m}">',
          '<rect width="100%" height="100%" fill="#0d1720"/>']
    outline=board_geometry(data,0)
    pts=' '.join(f'{X(x)},{Y(y)}' for x,y in outline.exterior.coords)
    rows.append(f'<polygon points="{pts}" fill="#174739" stroke="#87d5b8" stroke-width="2"/>')
    for k in data['routing_constraints']['keepouts']:
        rows.append(f'<rect x="{X(k["x1"])}" y="{Y(k["y2"])}" width="{(k["x2"]-k["x1"])*s}" height="{(k["y2"]-k["y1"])*s}" fill="#a97f2444"/>')
    if routing:
        for t in routing['tracks']:
            color='#fb7a71' if t['layer']=='TOP' else '#69a9ff'
            rows.append(f'<path d="M{X(t["x1"])} {Y(t["y1"])}L{X(t["x2"])} {Y(t["y2"])}" stroke="{color}" stroke-width="{t["width"]*s}" stroke-linecap="round"/>')
    for c in data['components']:
        body=component_body(c)
        pts=' '.join(f'{X(x)},{Y(y)}' for x,y in body.exterior.coords)
        rows.append(f'<polygon points="{pts}" fill="#132927b0" stroke="#cee5d7" stroke-width="1"/>')
        rows.append(f'<text x="{X(c["pcb"]["x"])}" y="{Y(c["pcb"]["y"])}" fill="white" text-anchor="middle" font-family="Arial" font-size="11">{escape(c["ref"])}</text>')
    for p in extract_pads(data):
        pts=' '.join(f'{X(x)},{Y(y)}' for x,y in p['geometry'].exterior.coords)
        rows.append(f'<polygon points="{pts}" fill="#d8bd73" stroke="#fff0b9" stroke-width=".3"/>')
    for x,y in data['board']['holes_mm']:
        rows.append(f'<circle cx="{X(x)}" cy="{Y(y)}" r="{data["board"]["hole_diameter_mm"]/2*s}" fill="#0d1720" stroke="#aaa"/>')
    rows.append('</svg>');Path(path).write_text('\n'.join(rows),encoding='utf8')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--design',type=Path,default=ROOT/'hardware/altium-r4/orion-r4-design.json')
    parser.add_argument('--out',type=Path,default=ROOT/'hardware/altium-r4')
    parser.add_argument('--audit-only',action='store_true')
    parser.add_argument('--fixed-only',action='store_true')
    parser.add_argument('--attempts',type=int)
    args=parser.parse_args();data=json.loads(args.design.read_text('utf8'))
    audit=mechanical_audit(data)
    (args.out/'mechanical-review.json').write_text(json.dumps(audit,indent=2),encoding='utf8')
    preview(data,args.out/'PCB-R4-placement.svg')
    print(json.dumps(audit,indent=2))
    if not audit['passed']:raise SystemExit(2)
    if args.audit_only:return
    fixed=fixed_routes(data)
    audit_fixed=verify_routing(data,fixed)
    non_connectivity=[e for e in audit_fixed['errors'] if e['kind']!='unconnected']
    (args.out/'fixed-routing-review.json').write_text(json.dumps(dict(errors=non_connectivity,verification=audit_fixed),indent=2),encoding='utf8')
    preview(data,args.out/'PCB-R4-fixed-routes.svg',fixed)
    print(json.dumps(non_connectivity,indent=2))
    if non_connectivity:raise SystemExit(2)
    if args.fixed_only:return
    result=route_board(data,args.attempts)
    (args.out/'orion-r4-routing.json').write_text(json.dumps(result,indent=2),encoding='utf8')
    preview(data,args.out/'PCB-R4-routing.svg',result)
    print(json.dumps(dict(stats=result['stats'],errors=result['verification']['errors']),indent=2))
    if not result['verification']['passed']:raise SystemExit(2)


if __name__=='__main__':main()


