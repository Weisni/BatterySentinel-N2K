"""Direct native PCB6-to-Gerber/XNC geometry comparison for the R5 release, including saved TrueType outlines and cutouts.

Reads native pad stacks, resolved mask/paste expansion, tracks, vias, regions,
silk strokes, board contour and finished drills. Requires the restricted native
primitive set emitted by this project. Run native DRC and the full source-link
audit separately; this comparison does not model arbitrary Altium pad stacks.
"""
from __future__ import annotations
import argparse
from collections import defaultdict
import hashlib
import json
import math
from pathlib import Path
import struct
import sys

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tmp/pcb-python'))
from shapely.geometry import LineString,Polygon
from shapely.ops import unary_union
from altium_libraries import read_cfb_streams
from verify_altium_binary_r4 import decode_r4
from verify_altium_binary_r3 import primitives,UNIT
from verify_altium_project import mm
from verify_jlcpcb_r4 import parse_gerber,parse_drill,pad_shape,circle
from export_jlcpcb_r5 import read_overlay_artwork,STEM


def drill_shape(hole):
    x,y,d=hole[:3]
    if len(hole)==3:return circle(x,y,d)
    length,angle=hole[3:];half=(length-d)/2
    dx,dy=half*math.cos(math.radians(angle)),half*math.sin(math.radians(angle))
    return LineString([(x-dx,y-dy),(x+dx,y+dy)]).buffer(d/2,quad_segs=64)


def native_geometry(path):
    native=decode_r4(path);streams=read_cfb_streams(path)
    layers=defaultdict(list);drills=defaultdict(list)
    rules={r['NAME']:r for r in native['rules']}
    for name in ('PadSolderMask','Paste_1to1','TentedVias'):
        if name not in rules:raise ValueError('Missing required native mask/paste rule '+name)
    mask_default=mm(rules['PadSolderMask']['EXPANSION'])
    paste_default=mm(rules['Paste_1to1']['EXPANSION'])
    for p in native['pads']:
        if p['layer'] not in ('TOP','BOTTOM','MULTILAYER'):raise ValueError('Unsupported native pad layer')
        shape={1:'ROUND',2:'RECTANGLE'}.get(p['shape'])
        if not shape:raise ValueError('Unsupported native pad shape')
        sides=['T','B'] if p['layer']=='MULTILAYER' else ['T' if p['layer']=='TOP' else 'B']
        make=lambda expansion:pad_shape(p['x'],p['y'],p['sx']+2*expansion,p['sy']+2*expansion,shape,p['rotation'])
        for side in sides:
            if p['plated']:layers['G'+side+'L'].append(make(0))
            if p['mask_mode'] not in (1,2):raise ValueError('Unsupported native solder mask mode')
            expansion=p['mask_expansion'] if p['mask_mode']==2 else mask_default
            if min(p['sx'],p['sy'])+2*expansion>0:layers['G'+side+'S'].append(make(expansion))
            if p['paste_mode'] not in (1,2):raise ValueError('Unsupported native paste mode')
            expansion=p['paste_expansion'] if p['paste_mode']==2 else paste_default
            if min(p['sx'],p['sy'])+2*expansion>0:layers['G'+side+'P'].append(make(expansion))
        if p['drill']:
            h=(p['x'],p['y'],p['drill'])
            if p['slot_type']:
                if p['slot_type']!=2:raise ValueError('Unsupported native hole type')
                h+=(p['slot_length'],p['rotation']+p['slot_angle'])
            drills['PTH' if p['plated'] else 'NPTH'].append(h)
    for t in native['route']['tracks']:
        layers['GTL' if t['layer']=='TOP' else 'GBL'].append(LineString([(t['x1'],t['y1']),(t['x2'],t['y2'])]).buffer(t['width']/2,quad_segs=64))
    for v in native['route']['vias']:
        for ext in ('GTL','GBL'):layers[ext].append(circle(v['x'],v['y'],v['diameter']))
        if mm(rules['TentedVias']['EXPANSION'])>-v['diameter']/2+1e-5:raise ValueError('Native via mask rule is not fully tented')
        drills['PTH'].append((v['x'],v['y'],v['drill']))
    region_layers={'TOP':'GTL','BOTTOM':'GBL','LAYER33':'GTO','LAYER34':'GBO','LAYER35':'GTP','LAYER36':'GBP','LAYER37':'GTS','LAYER38':'GBS'}
    for r in native['regions_all']:
        if r['layer'] in region_layers:layers[region_layers[r['layer']]].append(Polygon(r['points']))
    # Native Altium layer enum: Top/Bottom Overlay=33/34, Paste=35/36,
    # Solder=37/38. Ordinary copper tracks were decoded above.
    explicit_layers={33:'GTO',34:'GBO',35:'GTP',36:'GBP',37:'GTS',38:'GBS'}
    for blocks in primitives(streams.get('Tracks6/Data',b''),4):
        raw=blocks[0]
        if raw[0] not in explicit_layers:continue
        x1,y1,x2,y2,width=[v*UNIT for v in struct.unpack_from('<iiiii',raw,13)]
        g=LineString([(x1,y1),(x2,y2)]).buffer(width/2,quad_segs=64) if (x1,y1)!=(x2,y2) else circle(x1,y1,width)
        layers[explicit_layers[raw[0]]].append(g)
    for kind,stream,blocks in [(1,'Arcs6/Data',1),(6,'Fills6/Data',1)]:
        for records in primitives(streams.get(stream,b''),kind,blocks):
            if records[0][0] in explicit_layers:raise ValueError('Unsupported manufacturing primitive in '+stream)
    overlay,_=read_overlay_artwork(path)
    for ext,g in overlay.items():layers[ext]=[g]
    points=[];index=0
    while f'VX{index}' in native['board']:
        if native['board'].get(f'KIND{index}','0')!='0':raise ValueError('Unexpected native board contour arc')
        points.append((mm(native['board'][f'VX{index}']),mm(native['board'][f'VY{index}'])));index+=1
    return {ext:unary_union(layers[ext]) for ext in ('GTL','GBL','GTS','GBS','GTP','GBP','GTO','GBO')},drills,Polygon(points,[r['points'] for r in native['regions_all'] if r.get('properties',{}).get('ISBOARDCUTOUT','').upper()=='TRUE'])


def verify(pcb,directory,name=STEM):
    layers,drills,outline=native_geometry(pcb)
    errors=[];checks=[];stats={}
    def check(ok,description):
        checks.append(description)
        if not ok:errors.append(description)
    for ext,a in layers.items():
        b=parse_gerber(directory/f'{name}.{ext}')['geometry']
        tol=1e-5 # Altium internal coordinate quantum is 2.54 nm.
        same=(a.is_empty and b.is_empty) or (a.buffer(tol).covers(b) and b.buffer(tol).covers(a))
        check(same,ext+' native geometry equals Gerber')
        stats[ext]=dict(native_area_mm2=a.area,gerber_area_mm2=b.area,difference_mm2=a.symmetric_difference(b).area)
    contours=[];current=[]
    for p in parse_gerber(directory/f'{name}.GKO')['paths']:
        if current:
            if current[-1]!=p['points'][0]:raise ValueError('Discontinuous manufacturing profile')
            current.extend(p['points'][1:])
        else:current=list(p['points'])
        if len(current)>2 and current[-1]==current[0]:contours.append(current);current=[]
    check(not current and bool(contours),'Manufacturing profile contours all close')
    reference=Polygon(contours[0],contours[1:])
    distance=outline.hausdorff_distance(reference)
    check(outline.is_valid and distance<.00001,'Native notched outline and internal cutouts equal fabrication profile within10nm')
    stats['outline_max_difference_mm']=distance
    for kind in ('PTH','NPTH'):
        actual=parse_drill(directory/f'{name}-{kind}.drl');remaining=list(drills[kind])
        check(len(actual)==len(remaining),kind+' drill/slot counts match')
        for h in actual:
            g=drill_shape(h)
            candidates=[(g.hausdorff_distance(drill_shape(n)),i) for i,n in enumerate(remaining)]
            distance,i=min(candidates,default=(math.inf,-1))
            check(distance<1e-5,kind+' native finished hole/slot matches XNC')
            if i>=0:remaining.pop(i)
    return dict(passed=not errors,checks=len(checks),errors=errors,geometry=stats,
        native_sha256=hashlib.sha256(Path(pcb).read_bytes()).hexdigest(),
        scope='Direct native PCB6 geometry versus Gerber and XNC. Includes copper, pad mask/paste, actual saved TrueType/logo/overlay geometry, notched outline, internal board cutouts and plated/nonplated slots. Via mask follows checked native TentedVias rule; full native source/link audit and native DRC are separate requirements.')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pcb',type=Path,default=ROOT/'hardware/altium-r5'/f'{STEM}.PcbDoc')
    parser.add_argument('--manufacturing',type=Path,default=ROOT/'hardware/altium-r5/manufacturing')
    parser.add_argument('--out',type=Path,default=ROOT/'hardware/altium-r5/native-gerber-review.json')
    args=parser.parse_args()
    try:result=verify(args.pcb,args.manufacturing)
    except Exception as exc:result=dict(passed=False,errors=[str(exc)])
    args.out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf8');print(json.dumps(result,indent=2))
    if not result['passed']:raise SystemExit(2)


if __name__=='__main__':main()
