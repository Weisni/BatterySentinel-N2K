"""R5 exact-contour routing. Historical R4 generators remain unchanged."""
from __future__ import annotations
import argparse,copy,hashlib,json,math,random,time
from pathlib import Path
from shapely.geometry import Point,Polygon
from shapely.ops import unary_union
import route_altium_r3 as base
import route_altium_r4 as prior
from r5_geometry import install_routing_geometry
install_routing_geometry()
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'hardware/altium-r5'

def fixed_routes(data):
    old=json.loads((ROOT/'hardware/altium-r4/orion-r4-design.json').read_text('utf8'))
    source=prior.fixed_routes(old);result=dict(tracks=[],vias=[])
    bus={'NET_S','FUSED_IN','BUS_PROT','5V_BUS','GND_BUS','SW_BUS','BST_BUS','CANH_EXT','CANL_EXT','CANH','CANL','SHIELD'}
    sec={'SW_LOGIC','BST_LOGIC','5V_SYS','3V3_LOGIC','GND_LOGIC'}
    for kind,items in source.items():
        if kind not in result:continue
        for it in items:
            if it['net'] in bus:result[kind].append(copy.deepcopy(it));continue
            if it['net'] not in sec:continue
            points=[(it['x'],it['y'])] if kind=='vias' else [(it['x1'],it['y1']),(it['x2'],it['y2'])]
            if not all(21<=x<=35.2 and 7<=y<=16.9 for x,y in points):continue
            n=copy.deepcopy(it);n['net']={'5V_SYS':'5V_ISO','3V3_LOGIC':'5V_REG'}.get(it['net'],it['net'])
            for suffix in ([''] if kind=='vias' else ['1','2']):
                x,y=n['x'+suffix],n['y'+suffix]
                n['x'+suffix]=x+10.75;n['y'+suffix]=1.2 if abs(x-25.4)<1e-6 and abs(y-7.75)<1e-6 else y-7.5
            result[kind].append(n)
    # Broad output takeoff keeps load current out of the thin feedback branch.
    for layer,a,b in [('TOP',(33.25,4.8),(33.65,4.8)),('TOP',(33.65,4.8),(33.85,5.0))]:
        result['tracks'].append(dict(net='5V_REG',layer=layer,x1=a[0],y1=a[1],x2=b[0],y2=b[1],width=.5))
    return result

class R5Router(prior.R4Router):
    def __init__(self,data,cfg):
        base.Router.__init__(self,data,cfg)
        self.usb_reference=Polygon()
        self.switch_shadow=unary_union([base._shape(t).buffer(.3) for t in fixed_routes(data)['tracks'] if t['net'].startswith('SW_')])
    def fixed_obstacles(self,net,radius):
        block=base.Router.fixed_obstacles(self,net,radius)
        for h in prior.component_holes(self.data):
            block|=self.raster(Point(h['x'],h['y']).buffer(h['drill']/2),h['clearance']+radius+self.margin)
        if net not in ('GND_LOGIC','GND_BUS'):block[1]|=self.raster(self.switch_shadow,radius+self.margin)
        return block

def mechanical_audit(data):
    result=prior.mechanical_audit(data)
    radius=data['board']['mounting_courtyard_diameter_mm']/2
    for x,y in data['board']['holes_mm']:
        for c in data['components']:
            if prior.component_body(c).intersects(Point(x,y).buffer(radius)):
                result['errors'].append(dict(kind='mounting_courtyard_body',ref=c['ref'],hole=[x,y]))
    result['passed']=not result['errors'];result['policy']=result['policy'].replace('4.8 mm screw heads','5.6 mm screw/assembly courtyards')
    return result

def route_board(data,attempts=None):
    cfg=dict(base.DEFAULTS,**data['routing_constraints']);cfg['attempts']=attempts or cfg['attempts']
    nets=sorted({p['net'] for c in data['components'] for p in c['pins'] if p.get('net')})
    priority=['GPIO7','TXD','RXD','GPIO6','BUS_PROT','FUSED_IN','NET_S','5V_MODULE','5V_ISO','5V_REG','3V3_LOGIC','5V_BUS','SHIELD','GND_BUS','GND_LOGIC']
    order=[n for n in nets if n not in priority]+[n for n in priority if n in nets]
    best=None;start=time.time();rng=random.Random(52)
    for attempt in range(cfg['attempts']):
        router=R5Router(data,cfg);fixed=fixed_routes(data)
        router.tracks=copy.deepcopy(fixed['tracks']);router.vias=copy.deepcopy(fixed['vias'])
        for net in order:
            ok=router.route_net(net)
            print(f'Attempt {attempt+1}: {net}: {"OK" if ok else "FAILED"}, {len(router.tracks)} tracks/{len(router.vias)} vias',flush=True)
        result=dict(tracks=router.tracks,vias=router.vias,net_results=router.net_results,constraints=cfg,stats=dict(attempt=attempt+1,expansions=router.expansions,completed_nets=sum(n['complete'] for n in router.net_results.values()),total_nets=len(nets)))
        check=base.verify_routing(data,result,cfg);check['errors']+=prior.extra_routing_checks(data,result);check['passed']=not check['errors'];result['verification']=check
        score=(len(check['errors']),-result['stats']['completed_nets'],len(result['vias']))
        if best is None or score<best[0]:best=(score,result)
        if check['passed']:break
        failed=[n for n in order if not router.net_results[n]['complete']];rest=[n for n in order if n not in failed]
        if attempt%2:rng.shuffle(rest)
        order=failed+rest
    result=best[1]
    if result['verification']['passed'] and cfg['ground_fill']:
        base.add_ground_fills(data,result,cfg)
        holes=unary_union([Point(h['x'],h['y']).buffer(h['drill']/2+h['clearance']+.025,quad_segs=64) for h in prior.component_holes(data)])
        regions=[]
        for region in result['regions']:
            for p in base._polygons(Polygon(region['points'],region.get('holes',[])).difference(holes)):
                for piece in base._hole_free(p):
                    if piece.area>1e-6:regions.append(dict(net=region['net'],layer=region['layer'],points=[[round(x,7),round(y,7)] for x,y in list(piece.exterior.coords)[:-1]],holes=[]))
        result['regions']=regions;removed=0
        while True:
            result['verification']=base.verify_routing(data,result,cfg)
            orphaned={int(e['item'][1:]) for e in result['verification']['errors'] if e['kind']=='unconnected_region'}
            if not orphaned:break
            result['regions']=[r for i,r in enumerate(result['regions']) if i not in orphaned];removed+=len(orphaned)
        result['stats']['removed_orphan_regions']=removed
        result['verification']['errors']+=prior.extra_routing_checks(data,result);result['verification']['passed']=not result['verification']['errors']
    result['stats'].update(track_count=len(result['tracks']),via_count=len(result['vias']),region_count=len(result.get('regions',[])),track_length_mm=sum(math.hypot(t['x2']-t['x1'],t['y2']-t['y1']) for t in result['tracks']),elapsed_seconds=time.time()-start)
    result['source_design_sha256']=hashlib.sha256(json.dumps(data,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    return result

def main():
    p=argparse.ArgumentParser();p.add_argument('--audit-only',action='store_true');p.add_argument('--fixed-only',action='store_true');p.add_argument('--attempts',type=int);args=p.parse_args()
    data=json.loads((OUT/'orion-r5-design.json').read_text('utf8'))
    audit=mechanical_audit(data);(OUT/'mechanical-review.json').write_text(json.dumps(audit,indent=2)+'\n');print(json.dumps(audit,indent=2));prior.preview(data,OUT/'PCB-R5-placement.svg')
    if not audit['passed']:raise SystemExit(2)
    if args.audit_only:return
    fixed=fixed_routes(data);check=base.verify_routing(data,fixed);errors=[e for e in check['errors'] if e['kind']!='unconnected']
    (OUT/'fixed-routing-review.json').write_text(json.dumps(dict(errors=errors,verification=check),indent=2)+'\n');print(json.dumps(errors,indent=2));prior.preview(data,OUT/'PCB-R5-fixed-routes.svg',fixed)
    if errors:raise SystemExit(2)
    if args.fixed_only:return
    result=route_board(data,args.attempts);(OUT/'orion-r5-routing.json').write_text(json.dumps(result,indent=2)+'\n');prior.preview(data,OUT/'PCB-R5-routing.svg',result)
    print(json.dumps(dict(stats=result['stats'],errors=result['verification']['errors']),indent=2))
    if not result['verification']['passed']:raise SystemExit(2)
if __name__=='__main__':main()
