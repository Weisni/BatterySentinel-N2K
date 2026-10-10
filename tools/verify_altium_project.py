"""Independently check the Orion Altium draft without starting Altium.

Usage: python tools/verify_altium_project.py [hardware/altium]
This is a structural/connectivity audit, not an Altium ERC/DRC or load test.
Only the Python standard library is used; no design generator is imported.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import configparser
import json
import math
from pathlib import Path
import re
import sys


class Audit:
    def __init__(self):
        self.errors = []
        self.checks = 0

    def check(self, condition, message):
        self.checks += 1
        if not condition:
            self.errors.append(message)


def properties(line):
    """Altium property names are case insensitive; values are not."""
    return {key.upper(): value for token in line.strip().split('|') if '=' in token
            for key, value in [token.split('=', 1)]}


def records(path):
    return [properties(line) for line in path.read_text(encoding='ascii').splitlines()
            if line.strip()]


def point(row, x='LOCATION.X', y='LOCATION.Y'):
    # A schematic base coordinate is 10 mil; FRAC is 1/100000 base units.
    return (float(row.get(x, 0)) + float(row.get(x+'_FRAC', 0))/100000,
            float(row.get(y, 0)) + float(row.get(y+'_FRAC', 0))/100000)


def on_segment(p, a, b):
    cross = (p[0]-a[0])*(b[1]-a[1]) - (p[1]-a[1])*(b[0]-a[0])
    return abs(cross) < 1e-6 and min(a[0], b[0])-1e-6 <= p[0] <= max(a[0], b[0])+1e-6 \
        and min(a[1], b[1])-1e-6 <= p[1] <= max(a[1], b[1])+1e-6


class DisjointSet:
    def __init__(self):
        self.parent = {}

    def find(self, p):
        self.parent.setdefault(p, p)
        if self.parent[p] != p:
            self.parent[p] = self.find(self.parent[p])
        return self.parent[p]

    def union(self, a, b):
        self.parent[self.find(a)] = self.find(b)


def unique(audit, values, description):
    for value, count in Counter(values).items():
        audit.check(count == 1, f'{description}: duplicate {value!r} ({count})')


def expected_nets(data):
    nets = defaultdict(set)
    for part in data['components']:
        for pin in part['pins']:
            if pin['net'] is not None:
                nets[pin['net']].add((part['ref'], str(pin['number'])))
    return dict(nets)


def check_model(audit, data):
    parts = data['components']
    unique(audit, [p['ref'] for p in parts], 'model references')
    unique(audit, [p['uid'] for p in parts], 'model component UIDs')
    for part in parts:
        unique(audit, [str(p['number']) for p in part['pins']], part['ref']+' pin numbers')
    # Independently transcribed from the R1 reference drawing and its pin notes.
    # R3/R4 and TP1 are the Altium references for R_TX/R_RX and TP_SH.
    required = {
        'J1': {'1':'SHIELD', '2':'NET_S', '3':'GND_BUS', '4':'CANH_EXT', '5':'CANL_EXT'},
        'TP1': {'1':'SHIELD'}, 'F1': {'1':'NET_S', '2':'FUSED_IN'},
        'Q1': {'1':'GATE', '2':'FUSED_IN', '3':'BUS_PROT', '4':'FUSED_IN'},
        'Z1': {'1':'BUS_PROT', '2':'GATE'}, 'R1': {'1':'GATE', '2':'GND_BUS'},
        'D1': {'1':'BUS_PROT', '2':'GND_BUS'}, 'C1': {'1':'BUS_PROT', '2':'GND_BUS'},
        'U3': {'1':'BUS_PROT', '2':'GND_BUS', '3':'5V_BUS', '4':'GND_BUS'},
        'C2': {'1':'BUS_PROT', '2':'GND_BUS'}, 'C3': {'1':'5V_BUS', '2':'GND_BUS'},
        'C8': {'1':'BUS_PROT', '2':'GND_BUS'}, 'L2': {'1':'BUS_PROT', '2':'DCDC_IN'},
        'C9': {'1':'DCDC_IN', '2':'GND_BUS'},
        'U2': {'1':'DCDC_IN', '2':'GND_BUS', '4':None, '5':None, '6':'GND_LOGIC', '7':'5V_ISO'},
        'C6': {'1':'5V_ISO', '2':'GND_LOGIC'}, 'C7': {'1':'5V_ISO', '2':'GND_LOGIC'},
        'D2': {'1':'5V_AFTER_DIODE', '2':'5V_ISO'},
        'JP1': {'1':'5V_AFTER_DIODE', '2':'5V_MODULE'},
        'D3': {'1':'CANH_EXT', '2':'CANL_EXT', '3':'GND_BUS'},
        'L1': {'1':'CANH_EXT', '2':'CANL_EXT', '3':'CANL', '4':'CANH'},
        'U1': {'1':'3V3_LOGIC', '2':'TXD', '3':'RXD', '4':'GND_LOGIC',
               '5':'GND_BUS', '6':'CANL', '7':'CANH', '8':'5V_BUS'},
        'C4': {'1':'5V_BUS', '2':'GND_BUS'}, 'C5': {'1':'3V3_LOGIC', '2':'GND_LOGIC'},
        'R2': {'1':'3V3_LOGIC', '2':'TXD'}, 'R3': {'1':'GPIO6', '2':'TXD'},
        'R4': {'1':'RXD', '2':'GPIO7'},
        'MCU1': {'5V':'5V_MODULE', 'GND':'GND_LOGIC', '3V3':'3V3_LOGIC', '6':'GPIO6', '7':'GPIO7'},
    }
    actual = {p['ref']: {str(q['number']):q['net'] for q in p['pins']} for p in parts}
    audit.check(set(actual) == set(required), 'model component set differs from R1 reference')
    for ref, pins in required.items():
        audit.check(actual.get(ref) == pins, f'{ref}: model pin/net map differs from independent R1 reference')
    byref = {p['ref']:p for p in parts}
    for ref in ('D1', 'D2', 'Z1'):
        names = {str(p['number']):p['name'] for p in byref[ref]['pins']}
        audit.check(names == {'1':'K', '2':'A'}, ref+': polarity labels must match cathode 1/anode 2')
    for ref, expected in [('Q1', {'1':'G', '2':'D', '3':'S', '4':'TAB=D'}),
                          ('U3', {'1':'IN', '2':'GND', '3':'OUT', '4':'TAB=GND'})]:
        audit.check({str(p['number']):p['name'] for p in byref[ref]['pins']} == expected,
                    ref+': pin functions or tab polarity differ from R1')
    bus = {'NET_S', 'FUSED_IN', 'GATE', 'BUS_PROT', 'DCDC_IN', 'GND_BUS', '5V_BUS',
           'CANH_EXT', 'CANL_EXT', 'CANH', 'CANL'}
    logic = {'5V_ISO', '5V_AFTER_DIODE', '5V_MODULE', 'GND_LOGIC', '3V3_LOGIC',
             'TXD', 'RXD', 'GPIO6', 'GPIO7'}
    for part in parts:
        nets = {p['net'] for p in part['pins']}
        audit.check(not (nets & bus and nets & logic) or part['ref'] in ('U1', 'U2'),
                    part['ref']+': unexpected component crossing the galvanic isolation domains')
    audit.check(expected_nets(data).get('SHIELD') == {('J1','1'), ('TP1','1')},
                'SHIELD must remain separate from bus and logic grounds')
    return byref


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
        elif row.get('RECORD') == '25':
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
                audit.check(any(on_segment(hotspot,a,b) for a,b in segments), f'SchDoc {key}: connected pin has no wire')
                extracted[pin['net']].add(key)
            else:
                audit.check(hotspot in noerc, f'SchDoc {key}: intentional NC lacks marker')
                audit.check(not any(on_segment(hotspot,a,b) for a,b in segments), f'SchDoc {key}: NC is wired')
    audit.check(dict(extracted) == expected_nets({'components':list(model.values())}),
                'SchDoc extracted netlist differs from model')
    return len(rows)


def check_netlist(audit, path, model):
    lines = path.read_text(encoding='ascii').splitlines()
    parts, nets = {}, {}
    i = 0
    while i < len(lines):
        opening = lines[i]
        audit.check(opening in ('[','('), f'NET line {i+1}: unexpected entry {opening!r}')
        if opening not in ('[','('):
            i += 1
            continue
        closing = ']' if opening == '[' else ')'
        try:
            end = lines.index(closing,i+1)
        except ValueError:
            audit.check(False, 'NET: unterminated block')
            break
        block = lines[i+1:end]
        if opening == '[':
            audit.check(len(block) == 3, 'NET: component block must contain ref, footprint, value')
            if len(block) == 3:
                audit.check(block[0] not in parts, 'NET: duplicate component '+block[0])
                parts[block[0]] = block[1:]
        elif block:
            audit.check(block[0] not in nets, 'NET: duplicate net '+block[0])
            unique(audit, block[1:], 'NET '+block[0]+' pins')
            nets[block[0]] = {tuple(item.rsplit('-',1)) for item in block[1:]}
        i = end+1
    audit.check(parts == {ref:[p['footprint'],p['value']] for ref,p in model.items()},
                'NET: component metadata differs from model')
    audit.check(nets == expected_nets({'components':list(model.values())}), 'NET: connectivity differs from model')


def mm(value):
    match = re.fullmatch(r'\s*([+-]?[0-9.]+(?:[eE][+-]?[0-9]+)?)\s*(mil|mm)?\s*',value)
    if not match:
        raise ValueError('unsupported coordinate '+repr(value))
    return float(match[1]) * (0.0254 if match[2] == 'mil' else 1)


def pad_corners(pad):
    x,y = mm(pad['X']),mm(pad['Y'])
    w,h = mm(pad['XSIZE'])/2,mm(pad['YSIZE'])/2
    angle = math.radians(float(pad.get('ROTATION',0)))
    c,s = math.cos(angle),math.sin(angle)
    return [(x+dx*c-dy*s,y+dx*s+dy*c) for dx,dy in [(-w,-h),(w,-h),(w,h),(-w,h)]]


def envelopes_overlap(first, second):
    """Separating-axis test, conservative for round/rounded pad envelopes."""
    a,b = pad_corners(first),pad_corners(second)
    for poly in (a,b):
        for i in (0,1):
            dx,dy = poly[i+1][0]-poly[i][0],poly[i+1][1]-poly[i][1]
            axis = (-dy,dx)
            ap = [x*axis[0]+y*axis[1] for x,y in a]
            bp = [x*axis[0]+y*axis[1] for x,y in b]
            if min(max(ap),max(bp))-max(min(ap),min(bp)) <= 1e-6:
                return False
    return True


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
        expected = {} if ref == 'MCU1' else {str(p['number']):p['net'] for p in part['pins']}
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


def check_project(audit, path):
    project = configparser.ConfigParser(interpolation=None)
    project.read(path,encoding='ascii')
    documents = [project[s].get('DocumentPath','') for s in project.sections() if re.fullmatch(r'Document\d+',s)]
    audit.check(set(documents) == {'Orion-Bridge-R1.SchDoc','Orion-Bridge-R1.PcbDoc'},
                'PrjPcb: expected exactly the schematic and PCB documents')
    unique(audit, documents, 'PrjPcb documents')
    for document in documents:
        target = (path.parent/document).resolve()
        audit.check(target.parent == path.parent.resolve(), 'PrjPcb: path escapes project folder')
        audit.check(target.is_file(), 'PrjPcb: missing document '+document)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory',nargs='?',type=Path,
                        default=Path(__file__).resolve().parents[1]/'hardware'/'altium')
    args = parser.parse_args()
    audit = Audit()
    root = args.directory
    try:
        data = json.loads((root/'orion-r1-design.json').read_text(encoding='utf-8'))
        model = check_model(audit,data)
        count = check_schematic(audit,root/'Orion-Bridge-R1.SchDoc',model)
        check_project(audit,root/'Orion-Bridge-R1.PrjPcb')
        check_netlist(audit,root/'Orion-Bridge-R1.NET',model)
        padcount = check_pcb(audit,root/'Orion-Bridge-R1.PcbDoc',model,data['board'])
    except (OSError,ValueError,KeyError,IndexError,configparser.Error) as error:
        audit.errors.append(f'Unable to complete audit: {type(error).__name__}: {error}')
    if audit.errors:
        print(f'FAIL: {len(audit.errors)} issue(s) in {audit.checks} checks')
        for error in audit.errors:
            print(' - '+error)
        return 1
    print(f'PASS: {audit.checks} structural/connectivity checks; {len(model)} components; '
          f'{len(expected_nets(data))} nets; {count} schematic records; {padcount} PCB pads including holes.')
    print('Checks cover the independent R1 pin map, SchDoc wire connectivity, NET, PCB and project links.')
    print('This is not an Altium open/save test, ERC, DRC, thermal analysis or fabrication approval.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
