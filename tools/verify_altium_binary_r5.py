"""Compare a saved native R5 PCB6 binary with its independently checked source.

Extends R3 readback with component NPTH, extended plated slots, complete native
board contour, scoped rules, paste suppression and actual 3D body contours.
No Altium automation is used. Unexpected copper primitive types fail closed.
"""
from __future__ import annotations
import argparse
from collections import Counter,defaultdict
from datetime import datetime
import hashlib
import json
import math
from pathlib import Path
import re
import struct
import sys

ROOT=Path(__file__).resolve().parents[1]
sys.dont_write_bytecode=True
from shapely.geometry import Polygon
from shapely.ops import unary_union
from altium_libraries import read_cfb_streams,_read_block,_read_props
from verify_altium_project import Audit,records,mm
from verify_altium_binary_r3 import decode_board,primitives,props_records,common,UNIT

STEM='BatterySentinel-N2K-Orion-R5'


def drc_timestamp(raw):
    date=re.search(r'^Date\s*:\s*(\S+)',raw,re.M)
    time=re.search(r'^Time\s*:\s*(\S+)',raw,re.M)
    if not date or not time:raise ValueError('Native DRC date/time missing')
    return datetime.strptime(date.group(1)+' '+time.group(1),'%d.%m.%Y %H:%M:%S').isoformat()


def check_board_edge_negative_control(a,directory):
    """Use an actual native failing run to prove uniform-rule serialization."""
    evidence_directory=directory
    inherited=False
    if not (directory/'validation/BoardEdge-negative-0_31mm.drc').is_file():
        # This is format/Altium-engine behavior evidence only, not a transfer
        # of an R4 board or routing pass. Fresh R5 numeric rules and DRC remain
        # mandatory and are checked independently against R5 actual copper.
        evidence_directory=ROOT/'hardware/altium-r4'
        inherited=True
    report=evidence_directory/'validation/BoardEdge-negative-0_31mm.drc'
    snapshot=evidence_directory/'validation/BoardEdge-negative-0_31mm-rule.json'
    provenance=evidence_directory/'validation/BoardEdge-serializer-evidence.json'
    if provenance.is_file():
        saved_provenance=json.loads(provenance.read_text('utf8'))
        inherited=saved_provenance.get('source_revision')=='R4'
        for row in saved_provenance.get('files',[]):
            file=evidence_directory/'validation'/row['path']
            a.check(file.is_file() and hashlib.sha256(file.read_bytes()).hexdigest()==row['sha256'],
                    'Inherited serializer behavior evidence changed: '+row['path'])
    raw=report.read_text('cp1252');saved=json.loads(snapshot.read_text('utf8'))
    violations=re.findall(r'Violation between Board Outline Clearance\(Outline Edge\): \(([\d.]+)mil < ([\d.]+)mil\)',raw)
    total=re.search(r'Violations Detected\s*:\s*(\d+)\b',raw)
    checks=[bool(violations) and total is not None and int(total.group(1))==len(violations),
            all(abs(float(limit)*.0254-.31)<.00004 for _,limit in violations),
            any(.3<float(gap)*.0254<.31 for gap,_ in violations),
            abs(mm(saved['rule']['GENERICCLEARANCE'])-.31)<.00001,
            saved['rule']['NAME']=='BoardEdge_0_30mm',
            bool(re.search(r'Waived Violations\s*:\s*0\b',raw))]
    a.check(all(checks),'Native board-edge negative-control evidence is missing or inconsistent')
    return dict(passed=all(checks),violations=len(violations),test_clearance_mm=.31,
                report_timestamp=drc_timestamp(raw),
                report_sha256=hashlib.sha256(report.read_bytes()).hexdigest(),
                captured_native_sha256=saved['native_pcb_sha256'],
                evidence_files=[str(report.resolve()),str(snapshot.resolve())],
                inherited_serializer_evidence=inherited,
                evidence_revision='R4 only as Altium uniform-rule serializer behavior proof' if inherited else 'R5 local evidence',
                conclusion='Actual native violations enforce 0.31 mm even though the legacy rule header prints Gap=0mil and uniform OBJECTCLEARANCES serializes empty. Final native GENERICCLEARANCE must be restored to 0.30 mm with a new zero-violation run.')


def check_native_drc(a,path,board_edge_behavior_verified=False,after_timestamp=None):
    """Check executed constraints in Altium's report, not just stored fields."""
    raw=path.read_text('cp1252')
    timestamp=drc_timestamp(raw)
    if after_timestamp:a.check(timestamp>after_timestamp,'Final native DRC is older than the deliberate negative control')
    a.check(bool(re.search(r'Violations Detected\s*:\s*0\b',raw)),'Native DRC reports violations or lacks completion')
    a.check(bool(re.search(r'Waived Violations\s*:\s*0\b',raw)),'Native DRC has waived violations or lacks waiver count')
    required=('Short-Circuit Constraint','Un-Routed Net Constraint','Width Constraint',
              'Routing Via (','Minimum Annular Ring','Hole Size Constraint','Hole To Hole Clearance',
              'Minimum Solder Mask Sliver','Silk To Solder Mask','Silk to Silk','Net Antennae',
              'Board Clearance Constraint','Component Clearance Constraint')
    processed=re.findall(r'^Processing Rule : (.*)$',raw,re.M)
    for kind in required:
        a.check(any(kind in row for row in processed),'Native batch DRC did not execute '+kind)
    edge=re.search(r'Processing Rule : Board Clearance Constraint \(Gap=([\d.]+)mil\)',raw)
    a.check(bool(edge) and (abs(float(edge.group(1))*.0254-.3)<.00004 or board_edge_behavior_verified),
            'Native DRC did not effectively enforce 0.30 mm board-edge clearance')
    return dict(report_file=str(path),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                report_timestamp=timestamp,
                processed_rules=len(processed),scope='Executed batch DRC constraints and zero unwaived/waived violations; report file snapshot must be regenerated after any physical edit.')


def decode_r5(path):
    binary=decode_board(path)
    streams=read_cfb_streams(path)
    for pad,blocks in zip(binary['pads'],primitives(streams['Pads6/Data'],2,6)):
        body,ex=blocks[4:6]
        pad.update(slot_type=ex[262] if len(ex)>262 else 0,
            slot_length=struct.unpack_from('<i',ex,263)[0]*UNIT if len(ex)>=267 else 0,
            slot_angle=struct.unpack_from('<d',ex,267)[0] if len(ex)>=275 else 0,
            paste_mode=body[101],paste_expansion=struct.unpack_from('<i',body,86)[0]*UNIT,
            mask_mode=body[102],mask_expansion=struct.unpack_from('<i',body,90)[0]*UNIT)
    for body,blocks in zip(binary['bodies'],primitives(streams['ComponentBodies6/Data'],12)):
        raw=blocks[0];size=struct.unpack_from('<I',raw,18)[0];offset=22+size
        count=struct.unpack_from('<I',raw,offset)[0];offset+=4
        if offset+16*count!=len(raw):raise ValueError('Unexpected native body geometry layout')
        body['points']=[(x*UNIT,y*UNIT) for x,y in struct.iter_unpack('<dd',raw[offset:])]
    boards=props_records(streams['Board6/Data'])
    binary['board']={k:v for r in boards for k,v in r.items()}
    raw=streams['Rules6/Data'];offset=0;rules=[]
    while offset<len(raw):
        type_id=struct.unpack_from('<H',raw,offset)[0];offset+=2
        block,offset,flags=_read_block(raw,offset)
        if flags:raise ValueError('Unexpected typed native rule block')
        row=_read_props(block);row['RECORD']='DXPRule';row['TYPE_ID']=type_id;rules.append(row)
    expected=struct.unpack('<I',streams['Rules6/Header'])[0]
    if len(rules)!=expected:raise ValueError('Native rule stream count mismatch')
    binary['rules']=rules
    binary['cutouts']=[]
    for r in binary['regions_all']:
        props=r['properties']
        if props.get('ISBOARDCUTOUT') in ('TRUE','T'):
            if props.get('KIND')!='0' or r['layer']!='MULTILAYER':
                raise ValueError('Actual board cutout is not KIND0 MULTILAYER with ISBOARDCUTOUT')
            shape=Polygon(r['points'])
            if not shape.is_valid or shape.is_empty:raise ValueError('Invalid actual native board cutout contour')
            binary['cutouts'].append(shape)
        elif r['layer']=='MULTILAYER':
            raise ValueError('Unrecognized multilayer Region; do not silently treat a drawing as a board cutout')
    # A generator which starts emitting an unsupported primitive cannot be
    # silently accepted because an old decoder simply ignored its stream.
    for stream,kind in [('Arcs6/Data',1),('Fills6/Data',6)]:
        for blocks in primitives(streams.get(stream,b''),kind):
            row=common(blocks[0],binary['nets'])
            if row['layer'] in ('TOP','BOTTOM'):
                raise ValueError('Unexpected native copper primitive in '+stream)
    if streams.get('Polygons6/Data',b''):
        raise ValueError('Unexpected native polygon objects require poured-geometry review')
    return binary


def check_native_typography(a,path,design,pcb):
    """Read saved font cache, not an installed-font approximation."""
    before=len(a.errors)
    from export_jlcpcb_r5 import read_overlay_artwork,validate_text_declarations
    overlay,evidence=read_overlay_artwork(path)
    try:validate_text_declarations(design,evidence)
    except ValueError as error:a.check(False,str(error))
    else:a.check(True,'Native TrueType labels match intended design')
    visible=[t for t in evidence['texts'] if t['layer'] in ('TOPOVERLAY','BOTTOMOVERLAY')]
    for text in visible:
        a.check(text['true_type'] and text['font_name']=='Arial Rounded MT Bold',
                'Final PCB text is not the selected actual rounded TrueType: '+text['text'])
        a.check(text['metric_error_native_units']<=1.1 and text['anchor_error_mm']<=.00000762,
                'Final PCB glyph cache metrics or anchor differs: '+text['text'])
    for ext,geometry in overlay.items():
        a.check(pcb['outline'].buffer(.00001).covers(geometry),ext+': native legend crosses actual board notch/window')
        layer='TOP' if ext=='GTO' else 'BOTTOM'
        mask=unary_union([m['geometry'] for m in pcb['mask'] if layer in m['layers']])
        gap=math.inf if mask.is_empty or geometry.is_empty else geometry.distance(mask)
        a.check(gap>=.1499,ext+f': native actual legend-to-mask clearance below .15 mm ({gap:.5f})')
    return dict(passed=len(a.errors)==before,source_sha256=evidence['source_sha256'],
                visible_text_count=len(visible),all_text_count=evidence['text_count'],
                cache_groups=evidence['cache_groups'],font_substitution=False,
                texts=[{k:t[k] for k in ('text','layer','font_name','height','rotation','mirror','bounds')} for t in visible],
                method='Actual LettersGeometry contours with exact native metrics/anchors and explicit Text declarations; overlay PCB edges and solder-mask clearance checked')


def audit_binary(directory=ROOT/'hardware/altium-r5'):
    from verify_altium_r5 import check_rules,check_geometry,check_pcb,pad_shape,hole_shape
    a=Audit();report={}
    binary_path=directory/(STEM+'.PcbDoc');source=directory/'source'/(STEM+'.PcbDoc')
    try:
        design=json.loads((directory/'orion-r5-design.json').read_text('utf-8'))
        models={c['ref']:c for c in design['components']}
        binary=decode_r5(binary_path);rows=records(source)
        source_pcb=check_pcb(a,source,design,models)
        ref_nets={int(r['ID']):r['NAME'] for r in rows if r.get('RECORD')=='Net'}
        ref_parts={int(r['ID']):r for r in rows if r.get('RECORD')=='Component'}
        by_name={r['SOURCEDESIGNATOR']:r for r in ref_parts.values()}
        a.check(sorted(binary['nets'])==sorted(ref_nets.values()),'Native net names differ from source')
        a.check(len(binary['components'])==len(ref_parts)==len(models),'Native component count differs')
        a.check({p['SOURCEDESIGNATOR'] for p in binary['components']}==set(models),'Native component identities differ')
        for index,c in enumerate(binary['components']):
            name=c['SOURCEDESIGNATOR']
            if name not in by_name or name not in models:continue
            r=by_name[name];m=models[name]
            for field in ('SOURCEUNIQUEID','SOURCEHIERARCHICALPATH','SOURCEFOOTPRINTLIBRARY',
                          'SOURCECOMPONENTLIBRARY','SOURCELIBREFERENCE','PATTERN'):
                a.check(c.get(field)==r.get(field),name+': native '+field+' differs')
            for field in ('X','Y','HEIGHT'):
                a.check(abs(mm(c.get(field,'0mil'))-mm(r.get(field,'0mil')))<1e-5,name+': native '+field+' differs')
            a.check(abs(float(c['ROTATION'])-float(r['ROTATION']))<1e-7,name+': native rotation differs')
            for key,value in m.get('parameters',{}).items():
                if key=='Description':a.check(c.get('SOURCEDESCRIPTION')==value,name+': native description differs')
                else:a.check(binary['parameters'].get(index,{}).get(key)==str(value),name+': native parameter '+key+' differs')
        q=lambda v:round(v,4)
        padkeys=[];expected=[]
        def ref_for(component):return None if component is None else binary['components'][component]['SOURCEDESIGNATOR']
        for p in binary['pads']:
            ref=ref_for(p['component'])
            padkeys.append((ref,p['name'],p['net'],p['layer'],*[q(p[k]) for k in ('x','y','sx','sy','drill')],
                            p['shape'],q(p['rotation']),p['plated'],p['slot_type'],q(p['slot_length']),q(p['slot_angle'])))
        sourcepads={}
        for p in (r for r in rows if r.get('RECORD')=='Pad'):
            ref=ref_parts[int(p['COMPONENT'])]['SOURCEDESIGNATOR'] if 'COMPONENT' in p else None
            sourcepads[(ref,p['NAME'],q(mm(p['X'])),q(mm(p['Y'])))]=p
            expected.append((ref,p['NAME'],ref_nets.get(int(p.get('NET','-1'))),p['LAYER'],
                *[q(mm(p[k])) for k in ('X','Y','XSIZE','YSIZE','HOLESIZE')],
                {'ROUND':1,'RECTANGLE':2,'OCTAGON':3}[p['SHAPE']],q(float(p['ROTATION'])),p.get('PLATED')=='TRUE',
                int(p.get('HOLETYPE',0)),q(mm(p.get('HOLEWIDTH','0mil'))),q(float(p.get('HOLEROTATION',0)))))
        a.check(Counter(padkeys)==Counter(expected),'Native pad geometry/net/layer/plating/slots differ from source')
        for p in binary['pads']:
            ref=ref_for(p['component']);r=sourcepads.get((ref,p['name'],q(p['x']),q(p['y'])))
            if not r:continue
            label=f"{ref}.{p['name']}"
            if r.get('PASTEMASKEXPANSIONMODE')=='Manual':
                want=mm(r.get('PASTEMASKEXPANSION_MANUAL','0mil'))
                # Altium normalizes paste-disabled drilled pads to its large
                # negative sentinel (-99999 mil), while SMD EPs retain -10 mm.
                # Compare effective closed apertures, not those equivalent
                # internal representations.
                if want<=-max(p['sx'],p['sy'])/2:
                    a.check(p['paste_mode']==2 and p['paste_expansion']<=-max(p['sx'],p['sy'])/2,
                            label+': native solder paste aperture is no longer fully closed')
                else:
                    a.check(p['paste_mode']==2 and abs(p['paste_expansion']-want)<1e-5,label+': native manual paste expansion differs')
            if r.get('SOLDERMASKEXPANSIONMODE')=='Manual':
                want=mm(r.get('SOLDERMASKEXPANSION_MANUAL','0mil'))
                a.check(p['mask_mode']==2 and abs(p['mask_expansion']-want)<1e-5,label+': native manual solder mask differs')
        trackkey=lambda t:(t['net'],t['layer'],q(t['width']),tuple(sorted([(q(t['x1']),q(t['y1'])),(q(t['x2']),q(t['y2']))])))
        native=Counter(trackkey(t) for t in binary['route']['tracks'])
        expected=Counter(trackkey(dict(net=ref_nets[int(r['NET'])],layer=r['LAYER'],
                 **{k.lower():mm(r[k]) for k in ('X1','Y1','X2','Y2','WIDTH')}))
                 for r in rows if r.get('RECORD')=='Track' and r.get('LAYER') in ('TOP','BOTTOM'))
        a.check(native==expected,'Native copper track geometry/net/layer differs')
        viakey=lambda v:(v['net'],*[q(v[k]) for k in ('x','y','diameter','drill')])
        native=Counter(viakey(v) for v in binary['route']['vias'])
        expected=Counter(viakey(dict(net=ref_nets[int(r['NET'])],x=mm(r['X']),y=mm(r['Y']),
                        diameter=mm(r['DIAMETER']),drill=mm(r['HOLESIZE']))) for r in rows if r.get('RECORD')=='Via')
        a.check(native==expected,'Native via geometry/net differs')
        source_regions=defaultdict(list);native_regions=defaultdict(list)
        for r in rows:
            if r.get('RECORD')=='Region' and r.get('LAYER') in ('TOP','BOTTOM'):
                source_regions[(ref_nets[int(r['NET'])],r['LAYER'])].append(Polygon(
                    [(mm(r[f'VX{i}']),mm(r[f'VY{i}'])) for i in range(int(r['MAINCONTOURVERTEXCOUNT']))]))
        for r in binary['route']['regions']:native_regions[(r['net'],r['layer'])].append(Polygon(r['points']))
        a.check(set(source_regions)==set(native_regions),'Native copper region net/layer groups differ')
        for key,polys in source_regions.items():
            first=unary_union(polys);second=unary_union(native_regions.get(key,[]))
            a.check(first.hausdorff_distance(second)<1e-5 and first.symmetric_difference(second).area<.01,
                    'Native copper region geometry differs: '+str(key))
        # Logo artwork stays actual solid native overlay regions. Font outlines
        # have their own native text cache and are audited below.
        for layer in ('TOPOVERLAY','BOTTOMOVERLAY'):
            source_logo=unary_union([Polygon([(mm(r[f'VX{i}']),mm(r[f'VY{i}']))
                            for i in range(int(r['MAINCONTOURVERTEXCOUNT']))])
                            for r in rows if r.get('RECORD')=='Region' and r.get('LAYER')==layer])
            native_layer='LAYER33' if layer=='TOPOVERLAY' else 'LAYER34'
            native_logo=unary_union([Polygon(r['points']) for r in binary['regions_all'] if r['layer']==native_layer])
            a.check(source_logo.is_empty==native_logo.is_empty and
                    (source_logo.is_empty or (source_logo.hausdorff_distance(native_logo)<1e-5
                                              and source_logo.symmetric_difference(native_logo).area<.0001)),
                    'Native logo geometry differs from source on '+layer)
        # Native board contour and all scoped rules survive Altium's importer.
        points=[];i=0
        while f'VX{i}' in binary['board']:
            a.check(binary['board'].get(f'KIND{i}','0')=='0','Unexpected native board-contour arc')
            points.append((mm(binary['board'][f'VX{i}']),mm(binary['board'][f'VY{i}'])));i+=1
        native_exterior=Polygon(points)
        a.check(native_exterior.is_valid and native_exterior.hausdorff_distance(source_pcb['exterior'])<1e-5,
                'Native rounded notched exterior contour differs')
        a.check(len(binary['cutouts'])==len(source_pcb['cutouts'])==1,'Native routed RF window count differs')
        for expected in source_pcb['cutouts']:
            a.check(any(expected.hausdorff_distance(g)<1e-5 and expected.symmetric_difference(g).area<.0001
                        for g in binary['cutouts']),'Native ISBOARDCUTOUT geometry differs from source')
        for cutout in binary['cutouts']:
            a.check(native_exterior.contains(cutout),'Native routed cutout is outside exterior profile')
        native_outline=native_exterior.difference(unary_union(binary['cutouts']))
        a.check(native_outline.is_valid and native_outline.hausdorff_distance(source_pcb['outline'])<1e-5,
                'Actual native board material differs from source')
        native_rules={r['NAME']:r for r in binary['rules']}
        report['board_edge_negative_control']=check_board_edge_negative_control(a,directory)
        check_rules(a,binary['rules'],design,allow_uniform_board_edge=report['board_edge_negative_control']['passed'])
        numeric={'GAP','GENERICCLEARANCE','EXPANSION','MINLIMIT','MAXLIMIT','MINIMUMRING',
                 'MINSOLDERMASKWIDTH','MINHOLEWIDTH','MAXHOLEWIDTH','MINWIDTH','MAXWIDTH',
                 'HOLEWIDTH','WIDTH','MINSILKSCREENTOMASKGAP','SILKTOSILKCLEARANCE'}
        for name,rule in source_pcb['rules'].items():
            a.check(name in native_rules,'Native rule missing: '+name)
            if name not in native_rules:continue
            n=native_rules[name]
            for field in ('RULEKIND','SCOPE1EXPRESSION','SCOPE2EXPRESSION','ENABLED'):
                normalize=lambda s:re.sub(r'\s+','',str(s)).lower()
                a.check(normalize(n.get(field))==normalize(rule.get(field)),name+': native rule '+field+' differs')
            for field in numeric&set(rule):
                a.check(abs(mm(n.get(field,'0mil'))-mm(rule[field]))<1e-5,name+': native rule '+field+' differs')
        source_bodies=source_pcb['bodies'];native_bodies=defaultdict(list)
        for b in binary['bodies']:
            ref=ref_for(b['component']);p=b['properties']
            poly=Polygon(b['points'])
            native_bodies[ref].append(dict(geometry=poly,z0=mm(p['STANDOFFHEIGHT']),z1=mm(p['OVERALLHEIGHT'])))
            a.check(p.get('BODYPROJECTION')=='0','Native component body not top side')
        a.check(set(source_bodies)==set(native_bodies),'Native component body identities differ')
        for ref,wants in source_bodies.items():
            got=native_bodies[ref]
            a.check(len(got)==len(wants),ref+': native 3D body count differs')
            for b in wants:
                a.check(any(abs(b['z0']-g['z0'])<1e-5 and abs(b['z1']-g['z1'])<1e-5
                        and b['geometry'].hausdorff_distance(g['geometry'])<1e-5 for g in got),ref+': native 3D body contour/height differs')
        # Recheck physical spacing/connectivity on binary coordinates, rather
        # than assuming an approximately identical source necessarily passes.
        from shapely.geometry import Point,LineString
        items=[];holes=[];masks=[];drills=[]
        for i,p in enumerate(binary['pads']):
            ref=ref_for(p['component']);label=f"{ref}.{p['name']}"
            drill_geometry=None
            if p['drill']:
                drill_geometry=hole_shape(p['x'],p['y'],p['drill'],p['slot_length'],p['rotation']+p['slot_angle'])
                drills.append(dict(label=label,geometry=drill_geometry))
            if not p['plated']:
                holes.append(dict(ref=ref,x=p['x'],y=p['y'],drill=p['drill'],slot=p['slot_length'],
                    geometry=hole_shape(p['x'],p['y'],p['drill'],p['slot_length'],p['rotation']+p['slot_angle'])))
                continue
            geom=pad_shape(p['x'],p['y'],p['sx'],p['sy'],p['shape'],p['rotation'])
            if drill_geometry is not None:
                a.check(geom.covers(drill_geometry.buffer(-.00001)) and geom.boundary.distance(drill_geometry)>=.1799,
                        label+': native plated-pad annulus below 0.18 mm')
            layers=('TOP','BOTTOM') if p['drill'] else (p['layer'],)
            items.append(dict(net=p['net'],layers=layers,geometry=geom,kind='pad',label=label,ref=ref))
            expansion=p['mask_expansion'] if p['mask_mode']==2 else design.get('manufacturing',{}).get('mask_expansion_mm',.05)
            masks.append(dict(label=label,ref=ref,net=p['net'],layers=layers,geometry=geom.buffer(expansion,join_style=2)))
        for i,t in enumerate(binary['route']['tracks']):
            geom=LineString([(t['x1'],t['y1']),(t['x2'],t['y2'])]).buffer(t['width']/2,quad_segs=32)
            items.append(dict(net=t['net'],layers=(t['layer'],),geometry=geom,kind='track',label='T'+str(i),width=t['width']))
        for i,v in enumerate(binary['route']['vias']):
            drills.append(dict(label='V'+str(i),geometry=Point(v['x'],v['y']).buffer(v['drill']/2,quad_segs=64)))
            a.check((v['diameter']-v['drill'])/2>=.1499,'Native via annulus below 0.15 mm')
            items.append(dict(net=v['net'],layers=('TOP','BOTTOM'),geometry=Point(v['x'],v['y']).buffer(v['diameter']/2,quad_segs=64),kind='via',label='V'+str(i)))
        for i,r in enumerate(binary['route']['regions']):
            items.append(dict(net=r['net'],layers=(r['layer'],),geometry=Polygon(r['points']),kind='region',label='R'+str(i)))
        actual=dict(source_pcb,items=items,holes=holes,drills=drills,mask=masks,bodies=native_bodies,outline=native_outline,
                    exterior=native_exterior,cutouts=binary['cutouts'])
        report['geometry']=check_geometry(a,design,models,actual)
        report['typography']=check_native_typography(a,binary_path,design,actual)
        report.update(binary_sha256=binary['sha256'],source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                      components=len(binary['components']),nets=len(binary['nets']),pads=len(binary['pads']),
                      plated_slots=sum(p['slot_type']==2 for p in binary['pads']),
                      npth_holes=sum(not p['plated'] for p in binary['pads']),
                      tracks=len(binary['route']['tracks']),vias=len(binary['route']['vias']),
                      regions=len(binary['route']['regions']),component_bodies=len(binary['bodies']),
                      native_rule_count=len(binary['rules']),actual_board_cutouts=len(binary['cutouts']))
        drc_path=directory/'Project Outputs'/f'Design Rule Check - {STEM}.drc'
        if drc_path.is_file():report['native_drc_execution']=check_native_drc(a,drc_path,
            report['board_edge_negative_control']['passed'],report['board_edge_negative_control']['report_timestamp'])
        else:a.check(False,'Final native Altium DRC report missing')
    except Exception as error:
        a.errors.append(f'Binary readback could not complete: {type(error).__name__}: {error}')
    report.update(passed=not a.errors,checks=a.checks,errors=a.errors,
        scope='Saved PCB6 binary compared with generated ASCII: component source identity/parameters, every pad/net/layer/drill/slot/plating, paste suppression, copper, rounded contour, scoped design rules, actual 3D contours; then actual binary copper/mechanical geometry and executed native DRC checked. Manufacturer/hardware qualification remains separate.')
    return report


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory',nargs='?',type=Path,default=ROOT/'hardware/altium-r5')
    parser.add_argument('--report',type=Path)
    args=parser.parse_args();result=audit_binary(args.directory)
    if args.report:args.report.write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
    print(json.dumps({k:v for k,v in result.items() if k!='geometry'},indent=2))
    return 0 if result['passed'] else 1


if __name__=='__main__':sys.exit(main())
