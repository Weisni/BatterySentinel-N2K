"""Deterministic, geometry-checked two-layer routing for the Orion R3 carrier.

Routing is an A* search on an orthogonal/45 degree grid. Copper geometry, not
just grid occupancy, is checked independently after routing. This does not
replace manufacturer DFM or Altium's native DRC. Dependencies: numpy, scipy,
shapely (install normally, or put them in this repository's tmp/pcb-python).
"""
from __future__ import annotations

import argparse
from collections import defaultdict
import heapq
import hashlib
import json
import math
from pathlib import Path
import random
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
if (ROOT / 'tmp/pcb-python').exists():
    sys.path.insert(0, str(ROOT / 'tmp/pcb-python'))
import numpy as np
from scipy.ndimage import distance_transform_edt
import shapely
from shapely.geometry import Point, LineString, Polygon, box
from shapely.ops import unary_union, nearest_points
from shapely import affinity
from shapely.strtree import STRtree
from altium_pcb import footprint, transform

LAYERS = ('TOP', 'BOTTOM')
POWER = {'NET_S', 'FUSED_IN', 'BUS_PROT', 'DCDC_IN', '5V_ISO',
         '5V_AFTER_DIODE', '5V_MODULE', 'GND_BUS', 'GND_LOGIC'}
DEFAULTS = dict(grid=.15, clearance=.2, signal_width=.25, power_width=.5,
                edge_clearance=.25, hole_clearance=.25, via_diameter=.6, via_drill=.3,
                via_cost=5.0, bend_cost=.10, attempts=6, seed=31, max_expansions=300000,
                width_by_net={}, keepouts=[], net_regions={}, order=None,
                ground_fill=False, ground_domains={}, ground_clearance=.25,
                ground_min_neck=.35, fill_no_holes=True, thermal_vias=False)


def board_geometry(data, inset=0):
    """Actual routed perimeter, including optional rounded external corners."""
    b=data['board'];w,h=b['width_mm'],b['height_mm']
    radius=b.get('corner_radius_mm',0)
    if radius:
        if not 0 < radius <= min(w,h)/2:raise ValueError('Invalid corner radius')
        outline=box(radius,radius,w-radius,h-radius).buffer(radius,quad_segs=64)
        return outline.buffer(-inset,quad_segs=64) if inset else outline
    return box(inset,inset,w-inset,h-inset)


def extract_pads(data):
    pads = []
    for c in data['components']:
        pins = {str(p['number']): p for p in c['pins']}
        for p in footprint(c).pads:
            x,y = transform(c,p.x,p.y)
            if p.shape == 'ROUND':
                geometry = affinity.scale(Point(0,0).buffer(1, quad_segs=32),p.sx/2,p.sy/2)
            else:
                geometry = box(-p.sx/2,-p.sy/2,p.sx/2,p.sy/2)
            geometry = affinity.translate(affinity.rotate(geometry,c['pcb'].get('rotation',0)),x,y)
            pads.append(dict(ref=c['ref'], number=p.number, net=pins[p.number].get('net'),
                             x=x,y=y,geometry=geometry,drill=p.drill,
                             layers=LAYERS if p.drill else ('TOP',)))
    return pads


def _shape(item):
    if 'x1' in item:
        return LineString([(item['x1'],item['y1']),(item['x2'],item['y2'])]).buffer(item['width']/2,quad_segs=16)
    return Point(item['x'],item['y']).buffer(item['diameter']/2,quad_segs=32)


def copper_items(data, result):
    items=[]
    for p in extract_pads(data):
        items.append(dict(net=p['net'],layers=p['layers'],geometry=p['geometry'],
                          kind='pad',label=f"{p['ref']}.{p['number']}",drill=p['drill']))
    for i,t in enumerate(result['tracks']):
        items.append(dict(net=t['net'],layers=(t['layer'],),geometry=_shape(t),kind='track',label=f'T{i}'))
    for i,v in enumerate(result['vias']):
        items.append(dict(net=v['net'],layers=LAYERS,geometry=_shape(v),kind='via',label=f'V{i}',drill=v['drill']))
    for i,r in enumerate(result.get('regions',[])):
        items.append(dict(net=r['net'],layers=(r['layer'],),geometry=Polygon(r['points'],r.get('holes',[])),kind='region',label=f'R{i}'))
    return items


def verify_routing(data, result, constraints=None):
    """Independent exact-geometry clearance/connectivity checks on emitted copper."""
    cfg = dict(DEFAULTS, **data.get('routing_constraints',{}))
    cfg.update(constraints or {})
    items=copper_items(data,result)
    geometries=[x['geometry'] for x in items]
    tree=STRtree(geometries)
    errors=[]
    min_clearance=math.inf
    parents=list(range(len(items)))
    def find(n):
        while parents[n]!=n:
            parents[n]=parents[parents[n]];n=parents[n]
        return n
    def union(a,b):
        parents[find(a)]=find(b)
    for i,a in enumerate(items):
        # A generous local query also yields a meaningful measured minimum,
        # rather than reporting only pairs which already violate clearance.
        for j in tree.query(a['geometry'].buffer(max(cfg['clearance']+.001,2.0))):
            j=int(j)
            if j<=i:continue
            b=items[j]
            if not set(a['layers']).intersection(b['layers']):continue
            dist=a['geometry'].distance(b['geometry'])
            if a['net'] is not None and a['net']==b['net']:
                if dist < 1e-6:union(i,j)
            else:
                min_clearance=min(min_clearance,dist)
                if dist < cfg['clearance']-1e-6:
                    errors.append(dict(kind='clearance',a=a['label'],b=b['label'],
                                       nets=[a['net'],b['net']],distance=round(dist,6)))
    nets=defaultdict(list)
    for i,it in enumerate(items):
        if it['kind']=='pad' and it['net']:
            nets[it['net']].append((i,it))
    connectivity={}
    for net,pts in nets.items():
        groups=defaultdict(list)
        for i,it in pts:groups[find(i)].append(it['label'])
        connectivity[net]=list(groups.values())
        if len(groups)>1:
            errors.append(dict(kind='unconnected',net=net,groups=list(groups.values())))
    for i,it in enumerate(items):
        if it['kind']=='region' and not any(find(i)==find(pi) for pi,_ in nets.get(it['net'],[])):
            errors.append(dict(kind='unconnected_region',item=it['label'],net=it['net']))
    width,height=data['board']['width_mm'],data['board']['height_mm']
    board=board_geometry(data,cfg['edge_clearance'])
    for it in items:
        if not board.buffer(1e-6).covers(it['geometry']):
            errors.append(dict(kind='board_edge',item=it['label'],net=it['net']))
        for k,keep in enumerate(cfg['keepouts']):
            if it['net'] in keep.get('allowed_nets',[]):continue
            if not set(it['layers']).intersection(keep.get('layers',LAYERS)):continue
            polygon=box(keep['x1'],keep['y1'],keep['x2'],keep['y2'])
            if it['geometry'].intersection(polygon).area>1e-8:
                errors.append(dict(kind='keepout',item=it['label'],net=it['net'],keepout=k))
        if it['net'] in cfg['net_regions']:
            bounds=cfg['net_regions'][it['net']]
            if not box(*bounds).buffer(1e-6).covers(it['geometry']):
                errors.append(dict(kind='net_region',item=it['label'],net=it['net']))
        for h in data['board'].get('holes_mm',[]):
            hole=Point(h[0],h[1]).buffer(data['board'].get('hole_diameter_mm',3.2)/2)
            if it['geometry'].distance(hole)<cfg['hole_clearance']-1e-6:
                errors.append(dict(kind='mounting_hole',item=it['label']))
    if math.isinf(min_clearance):
        for i,a in enumerate(items):
            for b in items[i+1:]:
                if set(a['layers']).intersection(b['layers']) and not (a['net'] is not None and a['net']==b['net']):
                    min_clearance=min(min_clearance,a['geometry'].distance(b['geometry']))
    return dict(passed=not errors,errors=errors,connected_nets=sum(len(g)==1 for g in connectivity.values()),
                total_nets=len(connectivity),connectivity=connectivity,
                minimum_clearance_mm=None if math.isinf(min_clearance) else round(min_clearance,6),
                method='Shapely exact pad/track/via geometry, copper islands joined through plated holes; both layers checked')


def _polygons(geometry):
    if geometry.is_empty:return []
    if geometry.geom_type=='Polygon':return [geometry]
    if hasattr(geometry,'geoms'):
        return [p for g in geometry.geoms for p in _polygons(g)]
    return []


def _hole_free(polygon):
    """Cut at hole X-extrema; triangulate rare residual touching-ring pieces."""
    if not polygon.interiors:return [polygon]
    x1,y1,x2,y2=polygon.bounds
    cuts=sorted(set([x1,x2]+[v for ring in polygon.interiors for v in (ring.bounds[0],ring.bounds[2])]))
    result=[]
    for left,right in zip(cuts,cuts[1:]):
        if right-left<1e-7:continue
        for p in _polygons(polygon.intersection(box(left,y1-1,right,y2+1))):
            if p.area<1e-7:continue
            if not p.interiors:result.append(p)
            else:result.extend(_polygons(shapely.constrained_delaunay_triangles(p)))
    return result


def add_thermal_vias(data,result,cfg):
    """Adjacent-tab vias with short top-copper spokes; no via-in-pad required."""
    pads=extract_pads(data)
    tab=next((p for p in pads if p['ref']=='U3' and p['number']=='4'),None)
    if not tab or tab['net']!='GND_BUS':return []
    net=tab['net'];radius=cfg['via_diameter']/2
    x1,y1,x2,y2=tab['geometry'].bounds
    cx,cy=tab['x'],tab['y'];gap=radius+.18
    candidates=[]
    for offset in [0,-.6,.6,-1.2,1.2]:
        if y1+.1<=cy+offset<=y2-.1:
            candidates.extend([(x2+gap,cy+offset),(x1-gap,cy+offset)])
        if x1+.1<=cx+offset<=x2-.1:
            candidates.extend([(cx+offset,y1-gap),(cx+offset,y2+gap)])
    added=[]
    for x,y in candidates:
        if len(added)>=4:break
        if any(math.hypot(x-v['x'],y-v['y'])<cfg['via_diameter']+.25 for v in result['vias']):continue
        # Keep the drilled hole outside all solder lands (including this tab).
        if any(p['geometry'].distance(Point(x,y))<radius+.15-1e-6 for p in pads):continue
        via=dict(net=net,x=round(x,5),y=round(y,5),diameter=cfg['via_diameter'],drill=cfg['via_drill'],purpose='U3 thermal')
        anchor=nearest_points(tab['geometry'],Point(x,y))[0]
        spoke=dict(net=net,layer='TOP',x1=round(anchor.x,5),y1=round(anchor.y,5),x2=round(x,5),y2=round(y,5),width=max(.5,cfg['power_width']),purpose='U3 thermal')
        # Check the complete proposed copper against all foreign copper,
        # mounting holes, board edge, and both explicit keepout zones.
        trial=dict(result,tracks=result['tracks']+[spoke],vias=result['vias']+[via])
        if verify_routing(data,trial,cfg)['passed']:
            result['tracks'].append(spoke);result['vias'].append(via);added.append(via)
    return added


def add_ground_fills(data,result,cfg):
    """Create connected, explicit solid copper geometry with no orphan islands."""
    width,height=data['board']['width_mm'],data['board']['height_mm']
    edge=cfg['edge_clearance']+.005
    board=board_geometry(data,edge)
    items=copper_items(data,result)
    keepouts=unary_union([box(k['x1'],k['y1'],k['x2'],k['y2']) for k in cfg['keepouts']])
    holes=unary_union([Point(*h).buffer(data['board'].get('hole_diameter_mm',3.2)/2+cfg['hole_clearance']+.01,quad_segs=24)
                       for h in data['board'].get('holes_mm',[])])
    domains=cfg['ground_domains']
    if not domains:
        isolation=next((k for k in cfg['keepouts'] if 'isol' in k.get('name','').lower()),None)
        if not isolation:raise ValueError('Ground fills need ground_domains or a named isolation keepout')
        domains={'GND_BUS':[0,0,isolation['x1'],height],'GND_LOGIC':[isolation['x2'],0,width,height]}
    result['regions']=[]
    summary=[]
    for net,bounds in domains.items():
        for layer in LAYERS:
            seeds=unary_union([it['geometry'] for it in items if it['net']==net and layer in it['layers']])
            foreign=unary_union([it['geometry'] for it in items if it['net']!=net and layer in it['layers']])
            # Extra 0.025 mm guard accounts for the 0.005 mm simplification
            # tolerance while retaining at least the requested clearance.
            allowed=board.intersection(box(*bounds)).difference(keepouts).difference(holes)
            if not foreign.is_empty:allowed=allowed.difference(foreign.buffer(cfg['ground_clearance']+.025,quad_segs=12))
            opening=cfg['ground_min_neck']/2
            allowed=allowed.buffer(-opening,quad_segs=12).buffer(opening,quad_segs=12).simplify(.005,preserve_topology=True)
            allowed=allowed.difference(keepouts.buffer(.005,quad_segs=8)).intersection(board)
            retained=[p for p in _polygons(allowed) if p.area>.05 and p.intersects(seeds)]
            count=0;area=sum(p.area for p in retained)
            for polygon in retained:
                pieces=_hole_free(polygon) if cfg['fill_no_holes'] else [polygon]
                for piece in pieces:
                    result['regions'].append(dict(net=net,layer=layer,
                        points=[[round(x,7),round(y,7)] for x,y in list(piece.exterior.coords)[:-1]],
                        holes=[[[round(x,7),round(y,7)] for x,y in list(r.coords)[:-1]] for r in piece.interiors]))
                    count+=1
            summary.append(dict(net=net,layer=layer,area_mm2=round(area,3),regions=count,connected_islands=len(retained)))
    return summary


class Router:
    def __init__(self,data,cfg):
        self.data,self.cfg=data,cfg
        self.grid=cfg['grid']
        self.width=data['board']['width_mm'];self.height=data['board']['height_mm']
        self.nx=math.floor(self.width/self.grid)+1;self.ny=math.floor(self.height/self.grid)+1
        self.size=self.nx*self.ny
        self.xx,self.yy=np.meshgrid(np.arange(self.nx)*self.grid,np.arange(self.ny)*self.grid)
        self.pads=extract_pads(data)
        self.pads_by_net=defaultdict(list)
        for p in self.pads:
            if p['net']:self.pads_by_net[p['net']].append(p)
        self.tracks=[];self.vias=[]
        self.net_results={};self.expansions=0
        self.margin=self.grid*math.sqrt(2)/2+.003
        self.pad_masks={id(p):self.raster(p['geometry']) for p in self.pads}
        self.fixed_masks={}

    def raster(self,geometry,buffer=0):
        if buffer:geometry=geometry.buffer(buffer,quad_segs=16)
        out=np.zeros((self.ny,self.nx),dtype=bool)
        x1,y1,x2,y2=geometry.bounds
        a=max(0,int(math.floor(x1/self.grid))-1);b=min(self.nx,int(math.ceil(x2/self.grid))+2)
        c=max(0,int(math.floor(y1/self.grid))-1);d=min(self.ny,int(math.ceil(y2/self.grid))+2)
        if a<b and c<d:
            out[c:d,a:b]=shapely.intersects_xy(geometry,self.xx[c:d,a:b],self.yy[c:d,a:b])
        return out

    def width_for(self,net):
        return self.cfg['width_by_net'].get(net,self.cfg['power_width'] if net in POWER else self.cfg['signal_width'])

    def fixed_obstacles(self,net,radius):
        key=(net,radius)
        if key in self.fixed_masks:return self.fixed_masks[key].copy()
        block=np.zeros((2,self.ny,self.nx),dtype=bool)
        limit=self.cfg['edge_clearance']+radius+self.margin
        block[:]=((self.xx<limit)|(self.xx>self.width-limit)|(self.yy<limit)|(self.yy>self.height-limit))
        if self.data['board'].get('corner_radius_mm',0):
            block|=~self.raster(board_geometry(self.data,limit))
        for p in self.pads:
            if p['net']==net:continue
            mask=self.raster(p['geometry'],self.cfg['clearance']+radius+self.margin)
            for layer in p['layers']:block[LAYERS.index(layer)]|=mask
        for keep in self.cfg['keepouts']:
            if net in keep.get('allowed_nets',[]):continue
            mask=self.raster(box(keep['x1'],keep['y1'],keep['x2'],keep['y2']),radius+self.margin)
            for layer in keep.get('layers',LAYERS):block[LAYERS.index(layer)]|=mask
        if net in self.cfg['net_regions']:
            x1,y1,x2,y2=self.cfg['net_regions'][net]
            block|=((self.xx<x1+radius+self.margin)|(self.xx>x2-radius-self.margin)|
                    (self.yy<y1+radius+self.margin)|(self.yy>y2-radius-self.margin))
        for h in self.data['board'].get('holes_mm',[]):
            mask=self.raster(Point(h[0],h[1]).buffer(self.data['board'].get('hole_diameter_mm',3.2)/2),
                             self.cfg['hole_clearance']+radius+self.margin)
            block|=mask
        self.fixed_masks[key]=block.copy()
        return block

    def obstacles(self,net,radius):
        block=self.fixed_obstacles(net,radius)
        for t in self.tracks:
            if t['net']!=net:
                block[LAYERS.index(t['layer'])]|=self.raster(_shape(t),self.cfg['clearance']+radius+self.margin)
        for v in self.vias:
            if v['net']!=net:block|=self.raster(_shape(v),self.cfg['clearance']+radius+self.margin)
        return block

    def pad_nodes(self,p):
        nodes=np.zeros((2,self.ny,self.nx),dtype=bool)
        for layer in p['layers']:nodes[LAYERS.index(layer)]=self.pad_masks[id(p)]
        return nodes

    def search(self,start,goal,block,via_block,free_transitions):
        start=start&~block;goal=goal&~block
        if not start.any() or not goal.any():return None
        target2=goal.any(axis=0)
        heuristic=distance_transform_edt(~target2).ravel()
        g=np.full(self.size*2,np.inf,dtype=np.float64)
        parent=np.full(self.size*2,-1,dtype=np.int32)
        closed=np.zeros(self.size*2,dtype=bool)
        goalflat=goal.ravel();blocked=block.ravel();viaflat=via_block.ravel();freeflat=free_transitions.ravel()
        heap=[]
        for n in np.flatnonzero(start.ravel()):
            n=int(n);g[n]=0;heapq.heappush(heap,(float(heuristic[n%self.size]),0.,n))
        expansions=0
        moves=((-1,0,1.),(1,0,1.),(0,-1,1.),(0,1,1.),(-1,-1,math.sqrt(2)),(-1,1,math.sqrt(2)),(1,-1,math.sqrt(2)),(1,1,math.sqrt(2)))
        while heap:
            _,gn,n=heapq.heappop(heap)
            if closed[n]:continue
            if goalflat[n]:
                path=[n]
                while parent[n]!=-1:n=int(parent[n]);path.append(n)
                self.expansions+=expansions
                return list(reversed(path))
            closed[n]=True;expansions+=1
            if expansions>self.cfg['max_expansions']:break
            layer=n//self.size;pos=n%self.size;y=pos//self.nx;x=pos%self.nx
            prev=int(parent[n]);previous_direction=None
            if prev>=0 and prev//self.size==layer:
                previous_direction=(x-(prev%self.size)%self.nx,y-(prev%self.size)//self.nx)
            for dx,dy,cost in moves:
                nx=x+dx;ny=y+dy
                if not (0<=nx<self.nx and 0<=ny<self.ny):continue
                m=n+dx+dy*self.nx
                if blocked[m] or closed[m]:continue
                # Obstacle masks include half a diagonal grid step, so edges
                # joining unblocked centres cannot cut through foreign copper.
                ng=gn+cost*(1.0+(0.025 if ((layer==0 and dy!=0) or (layer==1 and dx!=0)) else 0))
                if previous_direction is not None and previous_direction!=(dx,dy):
                    ng+=self.cfg['bend_cost']/self.grid
                if ng<g[m]:
                    g[m]=ng;parent[m]=n
                    heapq.heappush(heap,(ng+float(heuristic[m%self.size]),ng,m))
            m=n+self.size if layer==0 else n-self.size
            if not closed[m] and not blocked[m] and (freeflat[pos] or not viaflat[pos]):
                ng=gn+(.1 if freeflat[pos] else self.cfg['via_cost']/self.grid)
                if ng<g[m]:
                    g[m]=ng;parent[m]=n;heapq.heappush(heap,(ng+float(heuristic[pos]),ng,m))
        self.expansions+=expansions
        return None

    def point(self,n):
        pos=n%self.size
        return ((pos%self.nx)*self.grid,(pos//self.nx)*self.grid)

    def path_copper(self,net,path,free):
        width=self.width_for(net)
        sections=[];section=[path[0]]
        for a,b in zip(path,path[1:]):
            if a//self.size!=b//self.size:
                if len(section)>1:sections.append(section)
                x,y=self.point(a)
                if not free.ravel()[a%self.size] and not any(abs(v['x']-x)<1e-6 and abs(v['y']-y)<1e-6 and v['net']==net for v in self.vias):
                    self.vias.append(dict(net=net,x=round(x,5),y=round(y,5),diameter=self.cfg['via_diameter'],drill=self.cfg['via_drill']))
                section=[b]
            else:section.append(b)
        if len(section)>1:sections.append(section)
        for section in sections:
            compressed=[section[0]];lastdir=None
            for i,(a,b) in enumerate(zip(section,section[1:])):
                xa,ya=self.point(a);xb,yb=self.point(b)
                direction=(round((xb-xa)/self.grid),round((yb-ya)/self.grid))
                if lastdir is not None and direction!=lastdir:compressed.append(a)
                lastdir=direction
            compressed.append(section[-1])
            for a,b in zip(compressed,compressed[1:]):
                x1,y1=self.point(a);x2,y2=self.point(b)
                self.tracks.append(dict(net=net,layer=LAYERS[a//self.size],x1=round(x1,5),y1=round(y1,5),
                                        x2=round(x2,5),y2=round(y2,5),width=width))

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
        # Start near the centre of this net's terminals to grow a short tree.
        cx=sum(p['x'] for p in pads)/len(pads);cy=sum(p['y'] for p in pads)/len(pads)
        remaining=sorted(pads,key=lambda p:(p['x']-cx)**2+(p['y']-cy)**2)
        connected=[remaining.pop(0)];tree=self.pad_nodes(connected[0]);done=0
        while remaining:
            remaining.sort(key=lambda p:min((p['x']-q['x'])**2+(p['y']-q['y'])**2 for q in connected))
            found=False
            for p in remaining:
                path=self.search(self.pad_nodes(p),tree,block,viablock,free)
                if path is None:continue
                self.path_copper(net,path,free)
                for n in path:tree.ravel()[n]=True
                tree|=self.pad_nodes(p)
                for v in self.vias:
                    if v['net']==net:
                        mask=self.raster(Point(v['x'],v['y']).buffer(.01))
                        free|=mask
                connected.append(p);remaining.remove(p);done+=1;found=True;break
            if not found:
                self.net_results[net]=dict(complete=False,pads=len(pads),connections=done,
                                           missing=[f"{p['ref']}.{p['number']}" for p in remaining]);return False
        self.net_results[net]=dict(complete=True,pads=len(pads),connections=done);return True


def route(data,constraints=None):
    cfg=dict(DEFAULTS,**data.get('routing_constraints',{}))
    cfg.update(constraints or {})
    start=time.time()
    nets=sorted({p['net'] for c in data['components'] for p in c['pins'] if p.get('net')})
    default=['CANH_EXT','CANL_EXT','CANH','CANL','GPIO6','GPIO7','RXD','TXD','GATE',
             'DCDC_IN','5V_AFTER_DIODE','5V_MODULE','5V_ISO','3V3_LOGIC','5V_BUS',
             'FUSED_IN','NET_S','BUS_PROT','SHIELD','GND_BUS','GND_LOGIC']
    order=cfg['order'] or [n for n in default if n in nets]+[n for n in nets if n not in default]
    best=None;rng=random.Random(cfg['seed'])
    for attempt in range(cfg['attempts']):
        router=Router(data,cfg)
        for net in order:router.route_net(net)
        result=dict(tracks=router.tracks,vias=router.vias,net_results=router.net_results,
                    constraints=cfg,stats=dict(attempt=attempt+1,expansions=router.expansions,
                    completed_nets=sum(n['complete'] for n in router.net_results.values()),
                    total_nets=len(nets),track_length_mm=round(sum(math.hypot(t['x2']-t['x1'],t['y2']-t['y1']) for t in router.tracks),3)))
        result['verification']=verify_routing(data,result,cfg)
        score=(len(result['verification']['errors']),-result['stats']['completed_nets'],len(result['vias']),result['stats']['track_length_mm'])
        print(f"Attempt {attempt+1}: {result['stats']['completed_nets']}/{len(nets)} nets, {len(result['vias'])} vias, {len(result['verification']['errors'])} errors",file=sys.stderr,flush=True)
        if best is None or score<best[0]:best=(score,result)
        if result['verification']['passed']:break
        failed=[n for n in order if not router.net_results[n]['complete']]
        # Prioritize previously trapped nets; deterministic variation permits
        # an alternate channel plan on the next complete rip-up attempt.
        rest=[n for n in order if n not in failed]
        if attempt%2:rng.shuffle(rest)
        order=failed+rest
    result=best[1]
    if result['verification']['passed']:
        if cfg['thermal_vias']:
            result['stats']['thermal_vias']=len(add_thermal_vias(data,result,cfg))
        if cfg['ground_fill']:
            result['stats']['ground_fills']=add_ground_fills(data,result,cfg)
        result['verification']=verify_routing(data,result,cfg)
    result['stats']['track_count']=len(result['tracks'])
    result['stats']['via_count']=len(result['vias'])
    result['stats']['region_count']=len(result.get('regions',[]))
    result['stats']['track_length_mm']=round(sum(math.hypot(t['x2']-t['x1'],t['y2']-t['y1']) for t in result['tracks']),3)
    result['source_design_sha256']=hashlib.sha256(json.dumps(data,sort_keys=True,separators=(',',':')).encode('utf-8')).hexdigest()
    result['stats']['elapsed_seconds']=round(time.time()-start,2)
    return result


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('design',type=Path);parser.add_argument('output',type=Path)
    parser.add_argument('--constraints',type=Path)
    args=parser.parse_args()
    data=json.loads(args.design.read_text(encoding='utf-8'))
    cfg=json.loads(args.constraints.read_text(encoding='utf-8')) if args.constraints else data.get('routing_constraints',{})
    result=route(data,cfg)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result['stats'],indent=2))
    if not result['verification']['passed']:sys.exit(2)
