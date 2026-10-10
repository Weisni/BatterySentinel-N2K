"""R5 manufacturing adapter using actual saved Altium TrueType outlines.

Copper, mask, paste, drills, BOM and CPL use the reviewed R4 format engine.
Both overlay layers are replaced in full by the saved native PCB's visible
primitive geometry. The final font is never regenerated from installed fonts.
board.native_texts declares the intended overlay Text objects for stale-file
protection; complete copper/link/DRC validation remains a separate release gate.
"""
from __future__ import annotations
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import struct
import sys
import zipfile

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tmp/pcb-python'))
from shapely.geometry import Polygon,LineString
from shapely.ops import unary_union
from altium_libraries import read_cfb_streams,_read_props
from export_jlcpcb_r4 import export as export_core,Gerber
from r5_branding import emit_gerber_regions,region_data,regions_geometry,logo_regions
from r5_native_typography import read_native_text_artwork
from verify_altium_binary_r3 import primitives,UNIT

STEM='BatterySentinel-N2K-Orion-R5'
OVERLAY={33:'GTO',34:'GBO'}


def board_profile(board):
    """Source profile, including the USB edge notch and routed RF window."""
    if not board.get('outline_points_mm'):
        if board.get('cutouts_mm'):raise ValueError('R5 cutouts require an explicit external outline')
        return None
    exterior=Polygon(board['outline_points_mm'])
    if not exterior.is_valid or exterior.area<=0:raise ValueError('Invalid R5 external profile')
    holes=[]
    for item in board.get('cutouts_mm',[]):
        cut=Polygon(item['outline_points_mm'])
        if not cut.is_valid or not exterior.contains(cut):raise ValueError('R5 internal cutout must be valid and strictly inside the external profile')
        if any(cut.intersects(previous) for previous in holes):raise ValueError('R5 board cutouts overlap')
        holes.append(cut)
    return Polygon(exterior.exterior.coords,[list(cut.exterior.coords) for cut in holes])


def layer_name(value):
    return {'TOP':'TOPOVERLAY','BOTTOM':'BOTTOMOVERLAY'}.get(value.upper(),value.upper())


def read_overlay_artwork(path):
    """Read every supported native overlay primitive, rejecting omissions."""
    path=Path(path);streams=read_cfb_streams(path)
    evidence,_=read_native_text_artwork(path)
    layers={'GTO':[],'GBO':[]};native_regions={'GTO':[],'GBO':[]};counts={'text':0,'region':0,'track':0}
    for item in evidence['texts']:
        ext={'TOPOVERLAY':'GTO','BOTTOMOVERLAY':'GBO'}.get(item['layer'])
        if ext:
            layers[ext].append(regions_geometry(item['regions']));counts['text']+=1
    for blocks in primitives(streams.get('Regions6/Data',b''),11):
        raw=blocks[0];ext=OVERLAY.get(raw[0])
        if not ext:continue
        size=struct.unpack_from('<I',raw,18)[0];props=_read_props(raw[22:22+size]);offset=22+size
        if props.get('KIND')!='0':raise ValueError('Unsupported native overlay region kind')
        count=struct.unpack_from('<I',raw,offset)[0];offset+=4
        if offset+16*count!=len(raw):raise ValueError('Unsupported overlay region holes/trailing data')
        g=Polygon([(x*UNIT,y*UNIT) for x,y in struct.iter_unpack('<dd',raw[offset:])])
        if not g.is_valid:raise ValueError('Invalid native overlay region')
        layers[ext].append(g);native_regions[ext].append(g);counts['region']+=1
    for blocks in primitives(streams.get('Tracks6/Data',b''),4):
        raw=blocks[0];ext=OVERLAY.get(raw[0])
        if not ext:continue
        x1,y1,x2,y2,w=[v*UNIT for v in struct.unpack_from('<iiiii',raw,13)]
        if w<=0:raise ValueError('Nonpositive native overlay track width')
        layers[ext].append(LineString([(x1,y1),(x2,y2)]).buffer(w/2,quad_segs=64));counts['track']+=1
    for stream,kind in [('Arcs6/Data',1),('Fills6/Data',6)]:
        for blocks in primitives(streams.get(stream,b''),kind):
            if blocks[0][0] in OVERLAY:raise ValueError('Unsupported overlay primitive: '+stream)
    for blocks in primitives(streams.get('Pads6/Data',b''),2,6):
        if blocks[4][0] in OVERLAY:raise ValueError('Unsupported overlay pad')
    evidence['overlay_primitive_counts']=counts
    evidence['overlay_regions']={ext:region_data(unary_union(parts)) for ext,parts in native_regions.items()}
    evidence['scope']='Actual saved native TrueType LettersGeometry, solid overlay Regions and overlay Tracks; unsupported types rejected.'
    return {ext:unary_union(parts) for ext,parts in layers.items()},evidence


def validate_text_declarations(data,evidence):
    declared=data['board'].get('native_texts')
    if not declared:raise ValueError('R5 requires board.native_texts to identify intended native PCB lettering')
    actual=[t for t in evidence['texts'] if t['layer'] in ('TOPOVERLAY','BOTTOMOVERLAY')]
    if len(declared)!=len(actual):raise ValueError('Declared/native overlay Text count differs')
    remaining=list(actual)
    for expected in declared:
        match=[]
        for i,t in enumerate(remaining):
            if t['text']!=expected['text'] or t['layer']!=layer_name(expected.get('layer','TOP')):continue
            if any(abs(t[key]-expected.get(key,0))>1e-5 for key in ('x','y','height','rotation')):continue
            if 'font_name' in expected and t['font_name']!=expected['font_name']:continue
            if 'mirror' in expected and t['mirror']!=expected['mirror']:continue
            if 'bold' in expected and t['bold']!=expected['bold']:continue
            if 'italic' in expected and t['italic']!=expected['italic']:continue
            match.append(i)
        if not match:raise ValueError('Native PCB lettering differs from declared item: '+expected['text'])
        remaining.pop(match[0])
    for logo in data['board'].get('native_logos',[]):
        ext='GTO' if layer_name(logo.get('layer','TOP'))=='TOPOVERLAY' else 'GBO'
        desired=regions_geometry(logo_regions(logo));actual=regions_geometry(evidence['overlay_regions'][ext])
        if not actual.buffer(.00001).covers(desired):raise ValueError('Declared project logo is absent or misplaced in native '+ext)


def export(data,routing,out,native_pcb,name=STEM,source_paths=()):
    native_pcb=Path(native_pcb);out=Path(out)
    overlay,evidence=read_overlay_artwork(native_pcb)
    validate_text_declarations(data,evidence)
    core=deepcopy(data);core['board']['silkscreen']=[]
    sources=list(source_paths)+[native_pcb]
    manifest=export_core(core,routing,out,name,sources)
    profile=board_profile(data['board'])
    if profile is not None:
        gerber=Gerber('Profile,NP')
        for contour in [profile.exterior,*profile.interiors]:gerber.line(list(contour.coords),.05)
        gerber.write(out/f'{name}.GKO')
    for ext,g in overlay.items():
        gerber=Gerber('Legend,'+('Top' if ext=='GTO' else 'Bot'))
        emit_gerber_regions(gerber,region_data(g));gerber.write(out/f'{name}.{ext}')
    manifest['format']='Orion manufacturing manifest v2 / native R5 lettering'
    manifest['board']=data['board']
    manifest['native_silkscreen']={key:evidence[key] for key in ('source','source_sha256','text_count','cache_groups','overlay_primitive_counts','scope')}
    manifest['native_silkscreen']['font_substitution']=False
    manifest['profile_geometry']='Explicit source exterior plus closed routed internal cutouts; all coordinates common top view' if profile is not None else 'Rounded rectangular source profile'
    manifest['files']={filename:hashlib.sha256((out/filename).read_bytes()).hexdigest() for filename in manifest['files']}
    with zipfile.ZipFile(out/f'{name}-Gerber.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for filename in manifest['files']:archive.write(out/filename,filename)
    (out/'native-typography-readback.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf8')
    (out/'manufacturing-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
    return manifest


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--design',type=Path,required=True);p.add_argument('--routing',type=Path,required=True)
    p.add_argument('--pcb',type=Path,required=True);p.add_argument('--out',type=Path,required=True)
    p.add_argument('--name',default=STEM);a=p.parse_args()
    result=export(json.loads(a.design.read_text('utf8')),json.loads(a.routing.read_text('utf8')),a.out,a.pcb,a.name,[a.design,a.routing])
    print(json.dumps({key:result[key] for key in ('name','pad_count','tracks','vias','pcba_bom_complete','native_silkscreen')},indent=2))


if __name__=='__main__':main()
