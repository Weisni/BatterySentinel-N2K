"""Read-only physical connectivity and local-library audit of the Orion R2 project.

Runs schematic wire/label/power-port checks before other checks. Bare crossings
without a junction, endpoint or pin remain disconnected. Checks native binary
SchLib/PcbLib via altium_libraries.read_cfb_streams, not the library generator.
No design files are modified, and Altium is never launched or controlled.
This is a structural/connectivity audit, not an Altium ERC/DRC or load test.
"""
from __future__ import annotations
import argparse
from collections import defaultdict
import configparser
import copy
import json
import math
from pathlib import Path
import re
import struct
import sys

sys.dont_write_bytecode = True

from verify_altium_project import (Audit, properties, records, point, on_segment,
    DisjointSet, unique, expected_nets, check_model as check_r1_model,
    mm, pad_corners, envelopes_overlap)

STEM = 'Orion-Bridge-R2'
SCHLIB = 'Orion-Bridge.SchLib'
PCBLIB = 'Orion-Bridge.PcbLib'

def check_schematic(audit, path, model):
    rows = records(path)
    header, rows = rows[0], rows[1:]
    audit.check(header.get('HEADER') == 'Protel for Windows - Schematic Capture Ascii File Version 5.0',
                'SchDoc: wrong ASCII header')
    audit.check(int(header.get('WEIGHT', -1)) == len(rows), 'SchDoc: header WEIGHT disagrees with record count')
    audit.check(rows[0].get('RECORD') == '31', 'SchDoc: first indexed record must be sheet')
    unique(audit, [r['UNIQUEID'] for r in rows if r.get('UNIQUEID')], 'SchDoc UIDs')
    children = defaultdict(list)
    for index, row in enumerate(rows):
        if 'OWNERINDEX' in row:
            owner = int(row['OWNERINDEX'])
            audit.check(-1 <= owner < index, f'SchDoc record {index}: invalid/nonpreceding owner {owner}')
            if owner >= 0:
                children[owner].append((index, row))
    graph = DisjointSet()
    segments = []
    labels = []
    noerc = set()
    all_points = set()
    for row in rows:
        if row.get('RECORD') == '27':
            n = int(row['LOCATIONCOUNT'])
            audit.check(n >= 2, 'SchDoc: wire has fewer than two vertices')
            pts = [point(row, f'X{i}', f'Y{i}') for i in range(1,n+1)]
            all_points.update(pts)
            for a, b in zip(pts, pts[1:]):
                audit.check(a != b, 'SchDoc: zero-length wire')
                graph.union(a,b)
                segments.append((a,b))
        elif row.get('RECORD') in ('25', '17'):
            p = point(row)
            labels.append((p, row['TEXT']))
            all_points.add(p)
        elif row.get('RECORD') in ('22', '29'):
            p = point(row)
            all_points.add(p)
            if row['RECORD'] == '22':
                noerc.add(p)
    schpins = {}
    seen_refs = []
    for index, row in enumerate(rows):
        if row.get('RECORD') != '1':
            continue
        owned = children[index]
        designators = [q['TEXT'] for _,q in owned if q.get('RECORD') == '34']
        audit.check(len(designators) == 1, f'SchDoc component {index}: requires one designator')
        if len(designators) != 1:
            continue
        ref = designators[0]
        seen_refs.append(ref)
        audit.check(ref in model, f'SchDoc: unexpected component {ref}')
        if ref not in model:
            continue
        audit.check(row.get('UNIQUEID') == model[ref]['uid'], ref+': schematic component UID mismatch')
        pins = [q for _,q in owned if q.get('RECORD') == '2']
        audit.check(int(row.get('ALLPINCOUNT',-1)) == len(pins), ref+': ALLPINCOUNT mismatch')
        unique(audit, [q.get('DESIGNATOR') for q in pins], ref+' SchDoc pin numbers')
        audit.check({q.get('DESIGNATOR') for q in pins} == {str(p['number']) for p in model[ref]['pins']},
                    ref+': schematic pin set differs from model')
        for pin in pins:
            pin_id = (ref,pin['DESIGNATOR'])
            start = point(pin)
            rotation = int(pin.get('PINCONGLOMERATE',0)) & 3
            length = float(pin.get('PINLENGTH',0))
            audit.check(length > 0, f'{pin_id}: pin length must be positive')
            dx,dy = [(1,0),(0,1),(-1,0),(0,-1)][rotation]
            hotspot = (start[0]+dx*length, start[1]+dy*length)
            schpins[pin_id] = hotspot
            all_points.add(hotspot)
            expected = next((p for p in model[ref]['pins'] if str(p['number']) == pin['DESIGNATOR']), None)
            if expected:
                audit.check(pin.get('NAME') == expected['name'], f'{pin_id}: pin name mismatch')
                audit.check(int(pin.get('ELECTRICAL',0)) == expected['type'], f'{pin_id}: electrical type mismatch')
    unique(audit, seen_refs, 'SchDoc references')
    audit.check(set(seen_refs) == set(model), 'SchDoc component set differs from model')
    for p in all_points:
        graph.find(p)
        for a,b in segments:
            if on_segment(p,a,b):
                graph.union(p,a)
    # Multiple equal labels represent one named net; first reject physical shorts.
    netnames = defaultdict(set)
    for p,name in labels:
        netnames[graph.find(p)].add(name)
        audit.check(any(on_segment(p,a,b) for a,b in segments), f'SchDoc: floating label {name} at {p}')
    for names in netnames.values():
        audit.check(len(names) == 1, f'SchDoc: physically shorted differently named nets {sorted(names)}')
    extracted = defaultdict(set)
    for ref, part in model.items():
        for pin in part['pins']:
            key = (ref,str(pin['number']))
            if key not in schpins:
                continue
            hotspot = schpins[key]
            names = netnames.get(graph.find(hotspot),set())
            expected = {pin['net']} if pin['net'] else set()
            audit.check(names == expected, f'SchDoc {ref}-{pin["number"]}: hotspot reaches {sorted(names)}, expected {sorted(expected)}')
            if pin['net']:
                audit.check(hotspot not in noerc, f'SchDoc {key}: connected pin has an unintended NoERC marker')
                audit.check(any(on_segment(hotspot,a,b) for a,b in segments), f'SchDoc {key}: connected pin has no wire')
                extracted[pin['net']].add(key)
            else:
                audit.check(hotspot in noerc, f'SchDoc {key}: intentional NC lacks marker')
                audit.check(not any(on_segment(hotspot,a,b) for a,b in segments), f'SchDoc {key}: NC is wired')
    audit.check(dict(extracted) == expected_nets({'components':list(model.values())}),
                'SchDoc extracted netlist differs from model')
    for marker in noerc:
        audit.check(marker in schpins.values(), f'SchDoc: orphan NoERC marker at {marker}')
    return len(rows)


def check_pcb(audit, path, model, board):
    rows = records(path)
    audit.check(rows[0].get('RECORD','').lower() == 'board', 'PcbDoc: first record must be Board')
    audit.check(rows[0].get('KIND') == 'Protel_Advanced_PCB', 'PcbDoc: wrong document kind')
    unique(audit, [r['UNIQUEID'] for r in rows if r.get('UNIQUEID')], 'PCB UIDs')
    components, nets, pads = {}, {}, []
    for row in rows:
        kind = row.get('RECORD','').lower()
        if kind == 'component':
            component_id = row.get('ID',row.get('INDEXFORSAVE'))
            audit.check(component_id not in components, 'PCB: duplicate component ID '+str(component_id))
            components[component_id] = row
        elif kind == 'net':
            net_id = row.get('ID',row.get('INDEXFORSAVE'))
            audit.check(net_id not in nets, 'PCB: duplicate net ID '+str(net_id))
            nets[net_id] = row.get('NAME')
        elif kind == 'pad':
            pads.append(row)
        elif kind == 'track' and row.get('LAYER') in ('TOP','BOTTOM'):
            audit.check(False, 'PCB: draft unexpectedly has copper routing; rerun route/clearance verification')
    refs = [r.get('SOURCEDESIGNATOR') for r in components.values()]
    unique(audit, refs, 'PCB references')
    audit.check(set(refs) == set(model), 'PCB component set differs from model')
    unique(audit, list(nets.values()), 'PCB net names')
    audit.check(set(nets.values()) == set(expected_nets({'components':list(model.values())})),
                'PCB net names differ from model')
    actual_pads = defaultdict(dict)
    width,height = board['width_mm'],board['height_mm']
    for cid,row in components.items():
        ref = row.get('SOURCEDESIGNATOR')
        if ref not in model:
            continue
        part = model[ref]
        audit.check(row.get('PATTERN') == part['footprint'], ref+': PCB footprint mismatch')
        audit.check(row.get('SOURCEUNIQUEID','').lstrip('\\') == part['uid'], ref+': source UID mismatch')
        for axis in ('X','Y'):
            audit.check(math.isclose(mm(row.get(axis,'0')),part['pcb'][axis.lower()],abs_tol=0.001),
                        ref+': PCB '+axis+' placement differs from model')
        audit.check(math.isclose(float(row.get('ROTATION','0')),part['pcb']['rotation'],abs_tol=0.001),
                    ref+': PCB rotation differs from model')
    holes = []
    for pad in pads:
        cid = pad.get('COMPONENT')
        if cid not in components:
            if pad.get('PLATED') == 'FALSE' and float(mm(pad.get('HOLESIZE','0'))) > 0:
                holes.append((mm(pad['X']),mm(pad['Y']),mm(pad['HOLESIZE'])))
                audit.check(not pad.get('NET') or pad.get('NET') in ('-1','65535'), 'PCB NPTH: unexpected net')
                continue
            audit.check(False, 'PCB: pad has invalid/missing component '+str(cid))
            continue
        ref = components[cid].get('SOURCEDESIGNATOR')
        number = pad.get('NAME')
        audit.check(number not in actual_pads[ref], f'PCB {ref}: duplicate pad {number}')
        net_id = pad.get('NET')
        audit.check(net_id in nets or net_id in (None,'','-1','65535'), f'PCB {ref}-{number}: invalid net reference {net_id}')
        actual_pads[ref][number] = nets.get(net_id)
        for axis,size in [('X','XSIZE'),('Y','YSIZE')]:
            center,dimension = mm(pad.get(axis,'0')),mm(pad.get(size,'0'))
            audit.check(dimension > 0, f'PCB {ref}-{number}: non-positive {size}')
        audit.check(all(0 <= x <= width and 0 <= y <= height for x,y in pad_corners(pad)),
                    f'PCB {ref}-{number}: rotated pad envelope extends outside board')
        audit.check(pad.get('SHAPE','').upper() in ('ROUND','RECTANGLE','OCTAGON','ROUNDEDRECTANGLE'),
                    f'PCB {ref}-{number}: unsupported pad shape {pad.get("SHAPE")}')
    for ref,part in model.items():
        expected = {str(p['number']):p['net'] for p in part['pins']}
        audit.check(actual_pads.get(ref,{}) == expected, f'PCB {ref}: pad numbers/nets differ from model')
    component_pads = [p for p in pads if p.get('COMPONENT') in components]
    for i,first in enumerate(component_pads):
        for second in component_pads[i+1:]:
            if first.get('LAYER') != second.get('LAYER') and 'MULTILAYER' not in (first.get('LAYER'),second.get('LAYER')):
                continue
            a = components[first['COMPONENT']]['SOURCEDESIGNATOR']+'-'+first['NAME']
            b = components[second['COMPONENT']]['SOURCEDESIGNATOR']+'-'+second['NAME']
            audit.check(not envelopes_overlap(first,second),
                        f'PCB: pad envelopes overlap: {a} ({nets.get(first.get("NET"))}) / '
                        f'{b} ({nets.get(second.get("NET"))})')
    audit.check(len(holes) == len(board['holes_mm']), 'PCB: mounting-hole count mismatch')
    for x,y in board['holes_mm']:
        audit.check(any(abs(hx-x)<0.001 and abs(hy-y)<0.001 and abs(d-3.2)<0.001 for hx,hy,d in holes),
                    f'PCB: missing 3.2mm NPTH at {(x,y)}')
    boardprops = {}
    for row in rows:
        if row.get('RECORD','').lower() == 'board':
            boardprops.update(row)
    vertices = []
    i = 0
    while f'VX{i}' in boardprops:
        vertices.append((mm(boardprops[f'VX{i}']),mm(boardprops[f'VY{i}'])))
        i += 1
    audit.check(len(vertices) >= 4, 'PCB: missing board contour vertices')
    if vertices:
        audit.check(vertices[0] == vertices[-1], 'PCB contour must explicitly close')
        audit.check(abs(max(x for x,_ in vertices)-min(x for x,_ in vertices)-width)<0.001,
                    'PCB board contour width differs from model')
        audit.check(abs(max(y for _,y in vertices)-min(y for _,y in vertices)-height)<0.001,
                    'PCB board contour height differs from model')
    audit.check(boardprops.get('LAYER1NEXT') == '32' and boardprops.get('LAYER32PREV') == '1'
                and boardprops.get('LAYER32NEXT') == '0', 'PCB: copper stack must contain top and bottom only')
    for i in range(2,32):
        audit.check(boardprops.get(f'LAYER{i}PREV','0') == '0' and boardprops.get(f'LAYER{i}NEXT','0') == '0',
                    f'PCB: unexpected active internal copper layer {i}')
    return len(pads)


def check_reference_model(audit, data, research):
    """Keep the independent R1 electrical reference, adding all MCU pins."""
    reduced = copy.deepcopy(data)
    mcu = next(p for p in reduced['components'] if p['ref'] == 'MCU1')
    mcu['pins'] = [p for p in mcu['pins'] if str(p['number']) in ('5V','GND','3V3','6','7')]
    # R2 uses a compact TAB label on the symbol. Normalize only this label
    # for the historical R1 pin-function check, and only when the electrical
    # connection is the required bus ground. Other names/nets remain strict.
    regulator = next(p for p in reduced['components'] if p['ref'] == 'U3')
    for pin in regulator['pins']:
        if str(pin['number']) == '4' and pin['name'] == 'TAB' and pin['net'] == 'GND_BUS':
            pin['name'] = 'TAB=GND'
    check_r1_model(audit, reduced)
    actual = next(p for p in data['components'] if p['ref'] == 'MCU1')
    expected = {p['designator']:p['orion_net'] for p in research['pins']}
    audit.check(len(expected) == 16, 'Module research must contain sixteen unique pins')
    audit.check({str(p['number']):p['net'] for p in actual['pins']} == expected,
                'MCU1: full pin/net map differs from independently researched Nologo reference')
    audit.check(actual['pcb']['rotation'] == 180, 'MCU1: antenna must face positive PCB Y (rotation 180)')
    audit.check(actual['footprint'] == 'NOLOGO_C3_SUPERMINI_THT_2X8',
                'MCU1: expected the researched Nologo header footprint')
    for part in data['components']:
        audit.check(bool(part.get('libref')), part['ref']+': missing local library component ID')


def indexed_children(rows):
    children = defaultdict(list)
    for index,row in enumerate(rows):
        owner = int(row.get('OWNERINDEX', -1))
        if owner >= 0:
            children[owner].append((index,row))
    return children


def check_model_link(audit, rows, component_index, part, prefix):
    children = indexed_children(rows)
    lists = [(i,r) for i,r in children[component_index] if r.get('RECORD') == '44']
    models = [(j,q) for i,_ in lists for j,q in children[i] if q.get('RECORD') == '45'
              and q.get('MODELTYPE','').upper() == 'PCBLIB']
    audit.check(len(models) == 1, prefix+': requires exactly one PCBLIB model link')
    for index,row in models:
        audit.check(row.get('MODELNAME') == part['footprint'], prefix+': footprint model name mismatch')
        audit.check(row.get('ISCURRENT') in ('T','TRUE','1'), prefix+': footprint model is not current')
        audit.check(row.get('DATAFILECOUNT') == '1', prefix+': missing single local PCBLIB datafile')
        audit.check(row.get('MODELDATAFILE0','').replace('\\','/').split('/')[-1] == PCBLIB,
                    prefix+': footprint model does not reference the local PcbLib')
        audit.check(row.get('MODELDATAFILEENTITY0') == part['footprint'],
                    prefix+': footprint datafile entity mismatch')
        audit.check(row.get('MODELDATAFILEKIND0','').upper() == 'PCBLIB',
                    prefix+': footprint datafile kind mismatch')
        # R2 intentionally uses matching pin/pad designators and Altium's
        # default identity map. A future nonidentity map needs explicit audit.
        descendants = [q for j,q in children[index]]
        descendants += [q for j,_ in children[index] for _,q in children[j]]
        audit.check(not any(q.get('RECORD') == '47' for q in descendants),
                    prefix+': custom pin mapping needs a corresponding verifier implementation')


def check_local_links(audit, root, model, pcb_path=None):
    rows = records(root/(STEM+'.SchDoc'))[1:]
    children = indexed_children(rows)
    for index,row in enumerate(rows):
        if row.get('RECORD') != '1':
            continue
        refs = [q.get('TEXT') for _,q in children[index] if q.get('RECORD') == '34']
        if len(refs) != 1 or refs[0] not in model:
            continue
        ref = refs[0]; part = model[ref]
        audit.check(row.get('LIBREFERENCE') == part['libref'], ref+': SchDoc LibReference mismatch')
        audit.check(row.get('DESIGNITEMID') == part['libref'], ref+': SchDoc DesignItemId mismatch')
        audit.check(row.get('SOURCELIBRARYNAME') == SCHLIB, ref+': SchDoc source is not the local SchLib')
        params = {q.get('NAME'):q.get('TEXT','') for _,q in children[index] if q.get('RECORD') == '41'}
        for name,value in part.get('parameters',{}).items():
            if name == 'Role':
                continue
            audit.check(params.get(name) == value, f'{ref}: SchDoc parameter {name!r} mismatch')
        check_model_link(audit, rows, index, part, ref+' SchDoc')
    for row in records(pcb_path or root/(STEM+'.PcbDoc')):
        if row.get('RECORD','').lower() != 'component':
            continue
        ref = row.get('SOURCEDESIGNATOR')
        if ref not in model:
            continue
        part = model[ref]
        audit.check(row.get('SOURCELIBREFERENCE') == part['libref'], ref+': PCB source library reference mismatch')
        audit.check(row.get('SOURCECOMPONENTLIBRARY') == SCHLIB, ref+': PCB source component library mismatch')
        audit.check(row.get('SOURCEFOOTPRINTLIBRARY') == PCBLIB, ref+': PCB source footprint library mismatch')


def check_libraries(audit, root, model, research, pcb_path=None):
    from altium_libraries import read_cfb_streams, decode_schematic_library, decode_pcb_library
    for name in (SCHLIB,PCBLIB):
        path = root/name
        audit.check(path.is_file(), 'Missing local library '+name)
        audit.check(path.read_bytes()[:8] == bytes.fromhex('d0cf11e0a1b11ae1'),
                    name+': expected real native binary CFB file')
    sch = decode_schematic_library(read_cfb_streams(root/SCHLIB))
    pcb = decode_pcb_library(read_cfb_streams(root/PCBLIB))
    audit.check(set(sch) == {p['libref'] for p in model.values()}, 'SchLib component IDs differ from project')
    audit.check(set(pcb) == {p['footprint'] for p in model.values()}, 'PcbLib footprints differ from project')
    pcb_rows = records(pcb_path or root/(STEM+'.PcbDoc'))
    pcb_components = {r.get('ID',r.get('INDEXFORSAVE')):r for r in pcb_rows
                      if r.get('RECORD','').lower() == 'component'}
    placed = defaultdict(dict)
    for row in pcb_rows:
        if row.get('RECORD','').lower() == 'pad' and row.get('COMPONENT') in pcb_components:
            ref = pcb_components[row['COMPONENT']]['SOURCEDESIGNATOR']
            placed[ref][row['NAME']] = row
    for ref,part in model.items():
        if part['libref'] not in sch or part['footprint'] not in pcb:
            continue
        entries = sch[part['libref']]
        components = [(i,r) for i,r in enumerate(entries) if r.get('RECORD') == '1']
        audit.check(len(components) == 1, part['libref']+': library entry must contain one component')
        if components:
            index,row = components[0]
            audit.check(row.get('LIBREFERENCE') == part['libref'], ref+': SchLib LibReference mismatch')
            audit.check(row.get('DESIGNITEMID') == part['libref'], ref+': SchLib DesignItemId mismatch')
            check_model_link(audit, entries, index, part, ref+' SchLib')
        pins = [r for r in entries if r.get('RECORD') == '2']
        unique(audit,[p.get('DESIGNATOR') for p in pins],ref+' SchLib pins')
        actual = {p['DESIGNATOR']:(p['NAME'],int(p.get('ELECTRICAL',0))) for p in pins}
        required = {str(p['number']):(p['name'],p['type']) for p in part['pins']}
        audit.check(actual == required, ref+': native SchLib pin names/types/numbers differ from model')
        params = {r.get('NAME'):r.get('TEXT','') for r in entries if r.get('RECORD') == '41'}
        for name,value in part.get('parameters',{}).items():
            if name != 'Role':
                audit.check(params.get(name) == value, f'{ref}: SchLib parameter {name!r} mismatch')
        pads = [r for r in pcb[part['footprint']] if r.get('kind') == 'Pad']
        unique(audit,[p['number'] for p in pads],ref+' PcbLib pads')
        audit.check({p['number'] for p in pads} == set(required),
                    ref+': native PcbLib pads do not match every SchLib pin (identity map)')
        angle = math.radians(part['pcb']['rotation']); cs,sn = math.cos(angle),math.sin(angle)
        for pad in pads:
            number = pad['number']; instance = placed[ref].get(number)
            audit.check(instance is not None, f'{ref}-{number}: library pad missing on PCB')
            if instance is None:
                continue
            x = part['pcb']['x']+pad['x']*cs-pad['y']*sn
            y = part['pcb']['y']+pad['x']*sn+pad['y']*cs
            for key,want in [('X',x),('Y',y),('XSIZE',pad['sx']),('YSIZE',pad['sy']),('HOLESIZE',pad['drill'])]:
                audit.check(math.isclose(mm(instance.get(key,'0')),want,abs_tol=.001),
                            f'{ref}-{number}: PCB {key} differs from native library geometry')
            audit.check(instance.get('LAYER') == ('MULTILAYER' if pad['layer'] == 74 else 'TOP'),
                        f'{ref}-{number}: PCB/library pad layer mismatch')
        if ref == 'MCU1':
            researched = {p['designator']:p for p in research['pins']}
            for pad in pads:
                rp = researched.get(pad['number'])
                audit.check(rp is not None, 'MCU1: unresearched library pad '+pad['number'])
                if rp is not None:
                    audit.check(abs(pad['x']-rp['x_mm'])<.001 and abs(pad['y']-rp['y_mm'])<.001,
                                'MCU1-'+pad['number']+': native library geometry differs from Nologo research')
                    audit.check(abs(pad['drill']-research['carrier_lands_mm']['finished_hole'])<.001,
                                'MCU1-'+pad['number']+': carrier hole differs from selected header interface')
    return len(sch),len(pcb)


def check_project(audit,path):
    project = configparser.ConfigParser(interpolation=None)
    project.read(path,encoding='ascii')
    documents = [project[s].get('DocumentPath','') for s in project.sections() if re.fullmatch(r'Document\d+',s)]
    audit.check(set(documents) == {STEM+'.SchDoc',STEM+'.PcbDoc',SCHLIB,PCBLIB},
                'PrjPcb: must reference schematic, PCB and both local libraries')
    unique(audit,documents,'PrjPcb documents')
    for document in documents:
        target = (path.parent/document).resolve()
        audit.check(target.parent == path.parent.resolve(), 'PrjPcb: reference escapes project folder')
        audit.check(target.is_file(), 'PrjPcb: missing document '+document)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory',nargs='?',type=Path,
                        default=Path(__file__).resolve().parents[1]/'hardware'/'altium-r2')
    parser.add_argument('--connectivity-only',action='store_true',
                        help='Check physical SchDoc connectivity first while other files are being prepared')
    args = parser.parse_args(); root = args.directory; audit = Audit()
    counts = {}
    try:
        data = json.loads((root/'orion-r2-design.json').read_text(encoding='utf-8'))
        model = {p['ref']:p for p in data['components']}
        # Physical wire errors always come first; useful while arranging symbols.
        counts['schematic_records'] = check_schematic(audit,root/(STEM+'.SchDoc'),model)
        if not args.connectivity_only:
            research = json.loads((root/'supermini-nologo.json').read_text(encoding='utf-8'))
            check_reference_model(audit,data,research)
            counts['pcb_pads'] = check_pcb(audit,root/(STEM+'.PcbDoc'),model,data['board'])
            check_local_links(audit,root,model)
            check_project(audit,root/(STEM+'.PrjPcb'))
            counts['library_parts'],counts['library_footprints'] = check_libraries(audit,root,model,research)
    except (OSError,ValueError,KeyError,IndexError,TypeError,struct.error,RuntimeError,configparser.Error) as error:
        audit.errors.append(f'Unable to complete audit: {type(error).__name__}: {error}')
    if audit.errors:
        print(f'FAIL: {len(audit.errors)} issue(s) in {audit.checks} checks')
        for error in audit.errors:
            print(' - '+error)
        return 1
    print(f'PASS: {audit.checks} checks; {len(model)} components; {len(expected_nets(data))} nets; '+
          ', '.join(f'{value} {key.replace("_"," ")}' for key,value in counts.items()))
    print('Read-only wire/power-port/NoERC, UID, pin/pad and native local-library audit.')
    print('This does not replace opening in Altium, ERC/DRC, hardware validation or fabrication approval.')
    return 0


if __name__ == '__main__':
    sys.exit(main())

