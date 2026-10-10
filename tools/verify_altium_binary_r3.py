"""Read the native PCB6 binary back and compare copper to the checked ASCII source.

Only the simple pad stacks, straight tracks, through vias and straight-sided
solid regions emitted by this R3 generator are supported. Unexpected primitive
types/layouts fail explicitly. This is not a replacement for Altium's DRC.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import struct
import sys
from collections import Counter,defaultdict

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tmp/pcb-python'))
from shapely.geometry import Polygon
from shapely.ops import unary_union
from altium_libraries import read_cfb_streams,_read_block,_read_props
from verify_altium_project import properties,mm
from route_altium_r3 import verify_routing

UNIT=.0254/10000
LAYERS={1:'TOP',32:'BOTTOM',74:'MULTILAYER',56:'KEEPOUT'}
OUT=ROOT/'hardware/altium-r3'


def props_records(raw):
    offset=0;result=[]
    while offset<len(raw):
        block,offset,kind=_read_block(raw,offset)
        if kind:raise ValueError('Unexpected typed property record')
        result.append(_read_props(block))
    return result


def primitives(raw,expected_kind,block_count=1):
    offset=0;result=[]
    while offset<len(raw):
        kind=raw[offset];offset+=1
        if kind!=expected_kind:raise ValueError(f'Expected primitive {expected_kind}, found {kind}')
        blocks=[]
        for _ in range(block_count):
            block,offset,flags=_read_block(raw,offset)
            if flags:raise ValueError('Unexpected primitive block flags')
            blocks.append(block)
        result.append(blocks)
    return result


def common(block,nets):
    net,polygon,component=struct.unpack_from('<HHH',block,3)
    return dict(layer=LAYERS.get(block[0],f'LAYER{block[0]}'),
                net=None if net==65535 else nets[net],component=None if component==65535 else component)


def decode_board(path):
    streams=read_cfb_streams(path)
    counts={k[:-7]:struct.unpack('<I',v)[0] for k,v in streams.items() if k.endswith('/Header') and len(v)==4}
    nets=props_records(streams['Nets6/Data'])
    components=props_records(streams['Components6/Data'])
    names=[n['NAME'] for n in nets]
    route=dict(tracks=[],vias=[],regions=[])
    track_rows=primitives(streams['Tracks6/Data'],4)
    for blocks in track_rows:
        block=blocks[0];row=common(block,names)
        if len(block)<33:raise ValueError('Truncated native track')
        if row['layer'] not in ('TOP','BOTTOM'):continue
        row.update({key:value*UNIT for key,value in zip(('x1','y1','x2','y2','width'),struct.unpack_from('<iiiii',block,13))})
        route['tracks'].append(row)
    via_rows=primitives(streams['Vias6/Data'],3)
    for blocks in via_rows:
        block=blocks[0];row=common(block,names)
        if len(block)<31 or block[29]!=1 or block[30]!=32:raise ValueError('Only top-to-bottom through vias are supported')
        row.update({key:value*UNIT for key,value in zip(('x','y','diameter','drill'),struct.unpack_from('<iiii',block,13))})
        route['vias'].append(row)
    pads=[];pad_rows=primitives(streams['Pads6/Data'],2,6)
    for blocks in pad_rows:
        name=blocks[0][1:1+blocks[0][0]].decode('cp1252');body=blocks[4]
        if len(body)<104:raise ValueError('Truncated native pad')
        row=common(body,names);row['name']=name
        sizes=[struct.unpack_from('<ii',body,i) for i in (21,29,37)]
        if len(set(sizes))!=1 or len(set(body[49:52]))!=1:raise ValueError('Complex pad stack requires a dedicated decoder')
        row.update({key:value*UNIT for key,value in zip(('x','y','sx','sy'),struct.unpack_from('<iiii',body,13))})
        row.update(drill=struct.unpack_from('<i',body,45)[0]*UNIT,shape=body[49],rotation=struct.unpack_from('<d',body,52)[0],plated=bool(body[60]))
        pads.append(row)
    region_rows=primitives(streams['Regions6/Data'],11)
    regions_all=[]
    for blocks in region_rows:
        block=blocks[0];row=common(block,names)
        length=struct.unpack_from('<I',block,18)[0]
        props=_read_props(block[22:22+length]);offset=22+length
        count=struct.unpack_from('<I',block,offset)[0];offset+=4
        if offset+16*count!=len(block):raise ValueError('Unexpected region holes or trailing geometry')
        row.update(points=[[x*UNIT,y*UNIT] for x,y in struct.iter_unpack('<dd',block[offset:])],holes=[],properties=props)
        if len(row['points'])!=count:raise ValueError('Region vertex count differs')
        regions_all.append(row)
        if row['layer'] in ('TOP','BOTTOM'):
            if props.get('KIND')!='0':raise ValueError('Copper region is not a solid region')
            route['regions'].append(row)
    # Component-body geometry is counted and projection/height is read, while
    # colour and model rendering remain the separate 3D review's responsibility.
    body_rows=primitives(streams['ComponentBodies6/Data'],12)
    bodies=[]
    for blocks in body_rows:
        block=blocks[0];length=struct.unpack_from('<I',block,18)[0]
        row=common(block,names);row['properties']=_read_props(block[22:22+length]);bodies.append(row)
    params={};rows=props_records(streams.get('PrimitiveParameters/Data',b''));i=0
    while i<len(rows):
        r=rows[i];i+=1
        if not r.get('ID','').startswith('Component#'):continue
        count=int(r.get('COUNT','0'));part=int(r['ID'].split('#')[1])
        if not r.get('VARIANTGUID'):
            params[part]={p['NAME']:p.get('VALUE','') for p in rows[i:i+count]}
        i+=count
    actual={'Nets6':len(nets),'Components6':len(components),'Tracks6':len(track_rows),'Vias6':len(via_rows),
            'Pads6':len(pad_rows),'Regions6':len(region_rows),'ComponentBodies6':len(body_rows)}
    if any(counts.get(key)!=value for key,value in actual.items()):raise ValueError('Native stream count mismatch')
    return dict(nets=names,components=components,parameters=params,pads=pads,route=route,
                regions_all=regions_all,bodies=bodies,counts=counts,sha256=hashlib.sha256(Path(path).read_bytes()).hexdigest())


def audit(directory=OUT):
    design=json.loads((directory/'orion-r3-design.json').read_text())
    binary=decode_board(directory/'Orion-Bridge-R3.PcbDoc')
    source=directory/'source/Orion-Bridge-R3.PcbDoc'
    rows=[properties(line) for line in source.read_text(encoding='cp1252').splitlines() if line.startswith('|RECORD=')]
    ref_nets={int(r['ID']):r['NAME'] for r in rows if r.get('RECORD')=='Net'}
    ref_parts={int(r['ID']):r for r in rows if r.get('RECORD')=='Component'}
    models={c['ref']:c for c in design['components']}
    errors=[];checks=0
    def check(value,description):
        nonlocal checks
        checks+=1
        if not value:errors.append(description)
    check(sorted(binary['nets'])==sorted(ref_nets.values()),'Native net names differ from source')
    check(len(binary['components'])==len(ref_parts)==len(models),'Component counts differ')
    ref_by_name={r['SOURCEDESIGNATOR']:r for r in ref_parts.values()}
    for index,c in enumerate(binary['components']):
        name=c['SOURCEDESIGNATOR'];r=ref_by_name[name];m=models[name]
        for field in ('SOURCEUNIQUEID','SOURCEHIERARCHICALPATH','SOURCEFOOTPRINTLIBRARY','SOURCECOMPONENTLIBRARY','SOURCELIBREFERENCE','PATTERN'):
            check(c.get(field)==r.get(field),f'{name}: native {field} differs')
        for field in ('X','Y','HEIGHT'):
            check(abs(mm(c.get(field,'0mil'))-mm(r.get(field,'0mil')))<1e-5,f'{name}: native {field} differs')
        check(abs(float(c['ROTATION'])-float(r['ROTATION']))<1e-7,f'{name}: native rotation differs')
        for key,value in m.get('parameters',{}).items():
            if key=='Description':
                check(c.get('SOURCEDESCRIPTION')==value,f'{name}: description differs')
            else:
                check(binary['parameters'].get(index,{}).get(key)==str(value),f'{name}: native parameter {key} differs')
    q=lambda v:round(v,4)
    pad_keys=[]
    for p in binary['pads']:
        ref=None if p['component'] is None else binary['components'][p['component']]['SOURCEDESIGNATOR']
        pad_keys.append((ref,p['name'],p['net'],p['layer'],*[q(p[k]) for k in ('x','y','sx','sy','drill')],p['shape'],q(p['rotation']),p['plated']))
    expected=[]
    for p in (r for r in rows if r.get('RECORD')=='Pad'):
        ref=ref_parts[int(p['COMPONENT'])]['SOURCEDESIGNATOR'] if 'COMPONENT' in p else None
        expected.append((ref,p['NAME'],ref_nets.get(int(p.get('NET','-1'))),p['LAYER'],
             *[q(mm(p[k])) for k in ('X','Y','XSIZE','YSIZE','HOLESIZE')],
             {'ROUND':1,'RECTANGLE':2,'OCTAGON':3}[p['SHAPE']],q(float(p['ROTATION'])),p.get('PLATED')=='TRUE'))
    check(Counter(pad_keys)==Counter(expected),'Native pad geometry/net/layer/plating differs from source')
    track_key=lambda t:(t['net'],t['layer'],q(t['width']),tuple(sorted([(q(t['x1']),q(t['y1'])),(q(t['x2']),q(t['y2']))])))
    native_tracks=Counter(track_key(t) for t in binary['route']['tracks'])
    reference_tracks=Counter(track_key(dict(net=ref_nets[int(r['NET'])],layer=r['LAYER'],**{k.lower():mm(r[k]) for k in ('X1','Y1','X2','Y2','WIDTH')}))
         for r in rows if r.get('RECORD')=='Track' and r.get('LAYER') in ('TOP','BOTTOM'))
    check(native_tracks==reference_tracks,'Native copper track geometry/net/layer differs from source')
    via_key=lambda v:(v['net'],*[q(v[k]) for k in ('x','y','diameter','drill')])
    native_vias=Counter(via_key(v) for v in binary['route']['vias'])
    reference_vias=Counter(via_key(dict(net=ref_nets[int(r['NET'])],x=mm(r['X']),y=mm(r['Y']),diameter=mm(r['DIAMETER']),drill=mm(r['HOLESIZE']))) for r in rows if r.get('RECORD')=='Via')
    check(native_vias==reference_vias,'Native via geometry/net differs from source')
    source_regions=defaultdict(list);native_regions=defaultdict(list)
    for r in rows:
        if r.get('RECORD')=='Region' and r.get('LAYER') in ('TOP','BOTTOM'):
            source_regions[(ref_nets[int(r['NET'])],r['LAYER'])].append(Polygon([(mm(r[f'VX{i}']),mm(r[f'VY{i}'])) for i in range(int(r['MAINCONTOURVERTEXCOUNT']))]))
    for r in binary['route']['regions']:native_regions[(r['net'],r['layer'])].append(Polygon(r['points']))
    check(set(source_regions)==set(native_regions),'Native region net/layer groups differ')
    differences=[]
    for key,reference in source_regions.items():
        a=unary_union(reference);b=unary_union(native_regions.get(key,[]));distance=a.hausdorff_distance(b)
        difference=a.symmetric_difference(b).area
        check(distance<1e-5 and difference<.01,f'Native copper regions differ for {key}')
        differences.append(dict(net=key[0],layer=key[1],hausdorff_mm=distance,symmetric_difference_mm2=difference,
                                native_area_mm2=b.area,regions=len(native_regions.get(key,[]))))
    for body in binary['bodies']:
        p=body['properties']
        check(p.get('BODYPROJECTION')=='0','Native 3D body projection is not top')
        check(mm(p['OVERALLHEIGHT'])>mm(p['STANDOFFHEIGHT']),'Native 3D body height invalid')
    check(len(binary['bodies'])==sum(r.get('RECORD')=='ComponentBody' for r in rows),'3D body count differs')
    copper=verify_routing(design,binary['route'])
    check(copper['passed'],'Native binary copper geometry/connectivity check failed')
    errors.extend(copper['errors'])
    return dict(passed=not errors,checks=checks,errors=errors,binary_sha256=binary['sha256'],
       source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),components=len(binary['components']),
       nets=len(binary['nets']),pads=len(binary['pads']),tracks=len(binary['route']['tracks']),vias=len(binary['route']['vias']),
       copper_regions=len(binary['route']['regions']),component_bodies=len(binary['bodies']),
       component_parameters=sum(len(p) for p in binary['parameters'].values()),region_comparison=differences,
       copper_verification=copper,scope='PCB6 native binary readback: component source UIDs/library links/placements and imported parameters; simple pad stacks including hole/plating/net assignments; copper track/via geometry; solid copper region unions; 3D body count/projection/heights. Compared with corrected ASCII source, then independent copper clearance/connectivity/keepout checks. Native DRC and full rule/3D-render semantics are separate checks.')


if __name__=='__main__':
    result=audit()
    (OUT/'native-binary-verification.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k not in ('copper_verification','region_comparison')},indent=2))
    sys.exit(0 if result['passed'] else 1)
