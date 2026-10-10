"""Read back manufacturing files and compare their actual geometry to CAD JSON.

This deliberately parses the output, rather than trusting its manifest or the
exporter's internal lists. It accepts only the explicit Gerber/XNC subset emitted
by export_jlcpcb_r4; unfamiliar commands fail closed. Geometry is reconstructed
with Shapely. A successful result is a conversion/geometry check, not a claim of
complete electrical, mechanical, thermal or assembly-process qualification.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import csv
import hashlib
import json
import math
from pathlib import Path
import re
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
if (ROOT / 'tmp/pcb-python').exists():
    sys.path.insert(0, str(ROOT / 'tmp/pcb-python'))
from shapely import affinity
from shapely.geometry import Point, LineString, Polygon, box, GeometryCollection
from shapely.ops import unary_union

from altium_pcb import footprint, transform


def circle(x, y, diameter):
    return Point(x, y).buffer(diameter / 2, quad_segs=64)


def pad_shape(x, y, sx, sy, shape, rotation=0):
    if shape == 'ROUND':
        g = affinity.scale(circle(0, 0, 2), sx / 2, sy / 2)
        if abs(sx - sy) < 1e-10:
            rotation = 0
    elif shape in ('RECT', 'RECTANGLE'):
        g = box(-sx / 2, -sy / 2, sx / 2, sy / 2)
    else:
        raise ValueError(f'Unrecognized shape {shape}')
    return affinity.translate(affinity.rotate(g, rotation), x, y)


def parse_gerber(path):
    raw = Path(path).read_text('ascii')
    if '%FSLAX46Y46*%' not in raw or '%MOMM*%' not in raw or not raw.endswith('M02*\n'):
        raise ValueError('Gerber must explicitly use absolute 4.6 mm and terminate with M02')
    tokens = re.findall(r'%.*?%|[^%]*?\*', raw, flags=re.S)
    macros, apertures, objects, paths, flashes, regions = {}, {}, [], [], [], []
    current, aperture, mode, contours, region = None, None, 'G01', [], False
    function, polarity = None, None
    for token in tokens:
        token = token.strip()
        if not token:
            continue
        if token.startswith('%AM'):
            values = token[3:-1].split('*')
            name, primitives = values[0], [v for v in values[1:] if v]
            if len(primitives) != 1:
                raise ValueError('Only single-primitive apertures are supported')
            v = [float(n) for n in primitives[0].split(',')]
            if v[:2] == [21, 1]:
                g = box(v[4] - v[2] / 2, v[5] - v[3] / 2, v[4] + v[2] / 2, v[5] + v[3] / 2)
                macros[name] = affinity.rotate(g, v[6], origin=(0, 0))
            elif v[:2] == [4, 1]:
                n = int(v[2])
                coords = v[3:3+2*(n+1)]
                if len(coords) != 2*(n+1) or len(v) != 4+2*(n+1):
                    raise ValueError('Invalid outline macro length')
                macros[name] = affinity.rotate(Polygon(list(zip(coords[::2], coords[1::2]))), v[-1], origin=(0, 0))
            else:
                raise ValueError('Unsupported aperture primitive')
            continue
        match = re.fullmatch(r'%ADD(\d+)([A-Za-z][A-Za-z0-9]*)(?:,([^*]+))?\*%', token)
        if match:
            code, shape, args = int(match[1]), match[2], match[3]
            v = [] if args is None else [float(a) for a in args.split('X')]
            if shape == 'C':
                g = circle(0, 0, v[0])
            elif shape == 'R':
                g = box(-v[0]/2, -v[1]/2, v[0]/2, v[1]/2)
            elif shape in macros and not v:
                g = macros[shape]
            else:
                raise ValueError(f'Unknown aperture {shape}')
            apertures[code] = dict(shape=shape, geometry=g, diameter=v[0] if shape == 'C' else None)
            continue
        if token.startswith('%TF.FileFunction,'):
            function = token[len('%TF.FileFunction,'):-2]
            continue
        if token.startswith('%TF.FilePolarity,'):
            polarity = token[len('%TF.FilePolarity,'):-2]
            continue
        if token.startswith(('G04 ', '%TF.')) or token in ('%FSLAX46Y46*%', '%MOMM*%', '%LPD*%', 'G75*', 'M02*'):
            continue
        if token in ('G01*', 'G02*', 'G03*'):
            mode = token[:-1]
            continue
        if token == 'G36*':
            if region:
                raise ValueError('Nested region')
            region, contours = True, []
            continue
        if token == 'G37*':
            if not region or not contours:
                raise ValueError('Unbalanced/empty region')
            g = GeometryCollection()
            for contour in contours:
                if len(contour) < 4 or contour[0] != contour[-1]:
                    raise ValueError('Region contour must close')
                p = Polygon(contour)
                if not p.is_valid:
                    raise ValueError('Invalid region polygon')
                g = g.symmetric_difference(p)
            objects.append(g)
            regions.append(g)
            region = False
            continue
        match = re.fullmatch(r'D(\d+)\*', token)
        if match:
            aperture = int(match[1])
            if aperture not in apertures:
                raise ValueError(f'Undefined aperture D{aperture}')
            continue
        match = re.fullmatch(r'X(-?\d+)Y(-?\d+)(?:I(-?\d+)J(-?\d+))?D0([123])\*', token)
        if match:
            end = (int(match[1])/1e6, int(match[2])/1e6)
            operation = int(match[5])
            if operation == 2:
                if region:
                    contours.append([end])
            elif operation == 3:
                if region or aperture is None:
                    raise ValueError('Flash without aperture / in region')
                g = affinity.translate(apertures[aperture]['geometry'], *end)
                objects.append(g)
                flashes.append(dict(x=end[0], y=end[1], aperture=aperture, geometry=g))
            else:
                if current is None:
                    raise ValueError('Draw without current point')
                if mode == 'G01':
                    points = [current, end]
                else:
                    if match[3] is None:
                        raise ValueError('Circular draw without I/J')
                    cx, cy = current[0]+int(match[3])/1e6, current[1]+int(match[4])/1e6
                    radius = math.hypot(current[0]-cx, current[1]-cy)
                    if abs(radius-math.hypot(end[0]-cx, end[1]-cy)) > 2e-6:
                        raise ValueError('Arc endpoints do not share a radius')
                    a = math.atan2(current[1]-cy, current[0]-cx)
                    b = math.atan2(end[1]-cy, end[0]-cx)
                    sweep = (b-a) % math.tau if mode == 'G03' else -((a-b) % math.tau)
                    n = max(2, math.ceil(abs(sweep)/math.radians(.1)))
                    points = [(cx+radius*math.cos(a+sweep*i/n), cy+radius*math.sin(a+sweep*i/n)) for i in range(n+1)]
                    points[0], points[-1] = current, end
                if region:
                    if not contours:
                        raise ValueError('Region draw without start')
                    contours[-1].extend(points[1:])
                else:
                    if aperture is None or apertures[aperture]['diameter'] is None:
                        raise ValueError('Draw requires circular aperture')
                    d = apertures[aperture]['diameter']
                    geometry = (circle(*points[0], d) if all(p == points[0] for p in points)
                                else LineString(points).buffer(d/2, quad_segs=64))
                    objects.append(geometry)
                    paths.append(dict(points=points, width=d, mode=mode))
            current = end
            continue
        raise ValueError(f'Unsupported/malformed Gerber command: {token[:150]}')
    if region:
        raise ValueError('Unterminated region')
    return dict(function=function, polarity=polarity, geometry=unary_union(objects), objects=objects,
                apertures=apertures, flashes=flashes, paths=paths, regions=regions)


def parse_drill(path):
    rows = Path(path).read_text('ascii').splitlines()
    if rows[0] != 'M48' or rows[-1] != 'M30' or 'METRIC' not in rows:
        raise ValueError('Drill lacks explicit metric header or terminator')
    tools, holes, selected = {}, [], None
    body, route_start, tool_down = False, None, False
    for row in rows:
        if row.startswith(';') or row in ('M48', 'METRIC', 'M30'):
            continue
        if row == 'G05':
            route_start = None
            continue
        if row in ('M15', 'M16'):
            if route_start is None:
                raise ValueError('Route tool operation outside route mode')
            tool_down = row == 'M15'
            continue
        if row == '%':
            body = True
            continue
        match = re.fullmatch(r'T(\d+)C(\d+(?:\.\d+)?)', row)
        if match:
            if body:
                raise ValueError('Tool declaration inside drill body')
            tools[int(match[1])] = float(match[2])
            continue
        match = re.fullmatch(r'T(\d+)', row)
        if match:
            selected = int(match[1])
            if selected not in tools:
                raise ValueError('Unknown drill tool')
            continue
        match = re.fullmatch(r'X(-?\d+\.\d+)Y(-?\d+\.\d+)', row)
        if match:
            if not body or selected is None or route_start is not None:
                raise ValueError('Drill point without selected tool')
            holes.append((float(match[1]), float(match[2]), tools[selected]))
            continue
        match = re.fullmatch(r'G0([01])X(-?\d+\.\d+)Y(-?\d+\.\d+)', row)
        if match:
            point = (float(match[2]), float(match[3]))
            if match[1] == '0':
                if tool_down:
                    raise ValueError('Route reposition with tool down')
                route_start = point
            else:
                if not tool_down or route_start is None or selected is None:
                    raise ValueError('Linear route without selected tool and start')
                dx, dy = point[0]-route_start[0], point[1]-route_start[1]
                holes.append(((point[0]+route_start[0])/2, (point[1]+route_start[1])/2,
                              tools[selected], math.hypot(dx,dy)+tools[selected], math.degrees(math.atan2(dy,dx)) % 180))
                route_start = point
            continue
        raise ValueError(f'Unknown drill command {row}')
    return holes


def expected_geometry(data, route):
    layers = defaultdict(list)
    holes = {'PTH': [], 'NPTH': []}
    identities, apertures = [], defaultdict(list)
    cfg = data.get('manufacturing', {})
    for c in data['components']:
        if c['pcb'].get('layer', 'TOP').upper() != 'TOP':
            raise ValueError('CAD master supports top-side components only')
        rot = c['pcb'].get('rotation', 0)
        metadata = {str(p['number']): p for p in c.get('pcb_footprint', {}).get('pads', [])}
        for hole in c.get('pcb_footprint', {}).get('holes', []):
            if hole.get('plated') is not False:
                raise ValueError('Mechanical footprint holes must explicitly be nonplated')
            x,y = transform(c,hole['x'],hole['y'])
            holes['NPTH'].append((x,y,hole['drill']))
            for ext in ('GTS','GBS'):
                layers[ext].append(circle(x,y,hole['drill']+2*hole.get('mask_expansion_mm',cfg.get('mask_expansion_mm',.05))))
        for p in footprint(c).pads:
            meta = metadata.get(p.number, {})
            x, y = transform(c, p.x, p.y)
            shape = pad_shape(x, y, p.sx, p.sy, p.shape, rot)
            for side in ('T', 'B') if p.drill else ('T',):
                layers[f'G{side}L'].append(shape)
                identities.append(dict(ref=f'{c["ref"]}.{p.number}', side=side, shape=shape,
                                       net=next((pin.get('net') for pin in c['pins'] if str(pin['number']) == p.number), None)))
                expansion = meta.get('mask_expansion_mm', cfg.get('mask_expansion_mm', .05))
                if expansion is not None:
                    m = pad_shape(x, y, p.sx+2*expansion, p.sy+2*expansion, p.shape, rot)
                    layers[f'G{side}S'].append(m)
                    apertures[f'G{side}S'].append((f'{c["ref"]}.{p.number}', m))
            if p.drill:
                hole = (x, y, p.drill)
                if meta.get('drill_slot_length_mm'):
                    hole += (meta['drill_slot_length_mm'], (rot+meta.get('drill_slot_angle_deg', 0)) % 180)
                holes['PTH'].append(hole)
            elif c.get('assembly',{}).get('populate',True) is not False and c.get('paste', True) and meta.get('paste', not c['ref'].startswith('TP')):
                expansion = meta.get('paste_expansion_mm', cfg.get('paste_expansion_mm', 0))
                if 'paste_windows' in meta:
                    for window in meta['paste_windows']:
                        wx, wy = transform(c, p.x+window.get('x', 0), p.y+window.get('y', 0))
                        layers['GTP'].append(pad_shape(wx, wy, window['sx'], window['sy'], window.get('shape', 'RECTANGLE'), rot))
                else:
                    layers['GTP'].append(pad_shape(x, y, p.sx+2*expansion, p.sy+2*expansion, p.shape, rot))
    for track in route['tracks']:
        ext = 'GTL' if track['layer'] == 'TOP' else 'GBL'
        line = LineString([(track['x1'], track['y1']), (track['x2'], track['y2'])])
        layers[ext].append(line.buffer(track['width']/2, quad_segs=64))
    for via in route['vias']:
        for ext in ('GTL', 'GBL'):
            layers[ext].append(circle(via['x'], via['y'], via['diameter']))
        holes['PTH'].append((via['x'], via['y'], via['drill']))
    for region in route.get('regions', []):
        ext = 'GTL' if region['layer'] == 'TOP' else 'GBL'
        layers[ext].append(Polygon(region.get('points', region.get('exterior')), region.get('holes', [])))
    b = data['board']
    for hole in b.get('holes_mm', []):
        x, y, d = (hole['x'], hole['y'], hole['diameter_mm']) if isinstance(hole, dict) else (*hole, b['hole_diameter_mm'])
        holes['NPTH'].append((x, y, d))
        for ext in ('GTS', 'GBS'):
            layers[ext].append(circle(x, y, d+2*cfg.get('mask_expansion_mm',.05)))
    for fid in b.get('fiducials_mm', []):
        side = 'T' if fid.get('layer', 'TOP') == 'TOP' else 'B'
        layers[f'G{side}L'].append(circle(fid['x'], fid['y'], fid.get('diameter_mm', 1)))
        layers[f'G{side}S'].append(circle(fid['x'], fid['y'], fid.get('mask_diameter_mm', 2)))
    return {ext: unary_union(layers[ext]) for ext in ('GTL','GBL','GTS','GBS','GTP','GBP')}, holes, identities, apertures


def rounded_board(board):
    w, h, r = board['width_mm'], board['height_mm'], board.get('corner_radius_mm', 0)
    if r == 0:
        return box(0, 0, w, h)
    # Same physical contour, independently created by an offset rectangle.
    return box(r, r, w-r, h-r).buffer(r, quad_segs=900)


def verify(data, routing, directory, name='Orion-Bridge-R4'):
    directory = Path(directory)
    errors, warnings, checks = [], [], []
    def check(condition, label, detail=None):
        checks.append(label)
        if not condition:
            errors.append(dict(check=label, detail=detail))
    expected, holes, pads, apertures = expected_geometry(data, routing)
    functions = {'GTL':'Copper,L1,Top','GBL':'Copper,L2,Bot','GTS':'Soldermask,Top','GBS':'Soldermask,Bot',
                 'GTP':'Paste,Top','GBP':'Paste,Bot','GTO':'Legend,Top','GBO':'Legend,Bot','GKO':'Profile,NP'}
    parsed = {}
    geometry_statistics = {}
    for ext, function in functions.items():
        path = directory / f'{name}.{ext}'
        try:
            parsed[ext] = parse_gerber(path)
        except Exception as exc:
            check(False, f'{ext} parses', str(exc))
            continue
        check(parsed[ext]['function'] == function, f'{ext} file function')
        check(parsed[ext]['polarity'] == ('Negative' if ext in ('GTS','GBS') else 'Positive'), f'{ext} material polarity')
        if ext in expected:
            a, b = parsed[ext]['geometry'], expected[ext]
            # Six decimal places in mm means 1 nm coordinate quantization.
            tolerance = .000004
            same = (a.is_empty and b.is_empty) or (a.buffer(tolerance).covers(b) and b.buffer(tolerance).covers(a))
            difference = a.symmetric_difference(b).area
            check(same, f'{ext} equals CAD geometry', dict(symmetric_difference_mm2=difference))
            geometry_statistics[ext] = dict(area_mm2=a.area, difference_mm2=difference,
                                            flashes=len(parsed[ext]['flashes']), paths=len(parsed[ext]['paths']), regions=len(parsed[ext]['regions']))
    contour = []
    if 'GKO' in parsed:
        paths = parsed['GKO']['paths']
        check(len(paths) == (8 if data['board'].get('corner_radius_mm', 0) else 4), 'Outline has expected segment count')
        for path in paths:
            points = path['points']
            if contour:
                check(contour[-1] == points[0], 'Outline segment is continuous')
                contour.extend(points[1:])
            else:
                contour.extend(points)
        check(bool(contour) and contour[0] == contour[-1], 'Outline is closed')
        if contour:
            poly = Polygon(contour)
            check(poly.is_valid, 'Outline polygon valid')
            check(abs(poly.area-rounded_board(data['board']).area) < .00005, 'Rounded outline area equals design')
    board = rounded_board(data['board'])
    edge_clearance = data.get('routing_constraints', {}).get('edge_clearance', .25)
    for ext in ('GTL', 'GBL'):
        if ext in parsed:
            copper = parsed[ext]['geometry']
            check(board.buffer(-edge_clearance+.00001).covers(copper), f'{ext} copper to rounded edge clearance', edge_clearance)
    drill_results = {}
    for kind in ('PTH', 'NPTH'):
        try:
            actual = parse_drill(directory / f'{name}-{kind}.drl')
            def normalized(entries):
                answer = []
                for p in entries:
                    x,y,d = p[:3]
                    if len(p) == 3:
                        answer.append((round(x,6),round(y,6),round(d,6)))
                    else:
                        half = (p[3]-d)/2
                        dx,dy = half*math.cos(math.radians(p[4])), half*math.sin(math.radians(p[4]))
                        endpoints = sorted([(round(x-dx,6),round(y-dy,6)),(round(x+dx,6),round(y+dy,6))])
                        answer.append((round(d,6),*endpoints[0],*endpoints[1]))
                return Counter(answer)
            check(normalized(actual) == normalized(holes[kind]), f'{kind} drills equal CAD centers and finished diameters')
            check(len(actual) == len(set(actual)), f'{kind} no duplicate drill hits')
            drill_results[kind] = dict(count=len(actual), diameters_mm=sorted({v[2] for v in actual}))
            for hole in actual:
                x, y, diameter = hole[:3]
                geometry = circle(x,y,diameter)
                if len(hole) > 3:
                    length, angle = hole[3:]
                    dx = (length-diameter)/2*math.cos(math.radians(angle))
                    dy = (length-diameter)/2*math.sin(math.radians(angle))
                    geometry = LineString([(x-dx,y-dy),(x+dx,y+dy)]).buffer(diameter/2,quad_segs=64)
                check(board.covers(geometry), f'{kind} drill within rounded board')
        except Exception as exc:
            check(False, f'{kind} parses', str(exc))
    for via in routing['vias']:
        check((via['diameter']-via['drill'])/2 >= .15-1e-6, 'Via annular ring >=0.15 mm')
        for mask in ('GTS', 'GBS'):
            if mask in parsed:
                # A tented via beneath an unrelated open land is not tented in
                # physical production, even if it lacks its own aperture.
                overlap = parsed[mask]['geometry'].intersection(circle(via['x'], via['y'], via['drill'])).area
                check(overlap < 1e-8, f'{mask} via drill remains tented', dict(x=via['x'], y=via['y'], overlap_mm2=overlap))
    for c in data['components']:
        metadata={str(p['number']):p for p in c.get('pcb_footprint',{}).get('pads',[])}
        for p in footprint(c).pads:
            if not p.drill:continue
            x,y=transform(c,p.x,p.y);rot=c['pcb'].get('rotation',0);meta=metadata.get(p.number,{})
            copper=pad_shape(x,y,p.sx,p.sy,p.shape,rot)
            half=(meta.get('drill_slot_length_mm',p.drill)-p.drill)/2
            angle=math.radians(rot+meta.get('drill_slot_angle_deg',0))
            if half:
                dx,dy=half*math.cos(angle),half*math.sin(angle)
                hole=LineString([(x-dx,y-dy),(x+dx,y+dy)]).buffer(p.drill/2,quad_segs=64)
            else:hole=circle(x,y,p.drill)
            check(copper.buffer(1e-6).covers(hole.buffer(.18,quad_segs=64)),
                  'Component PTH/slot annular ring >=0.18 mm',f'{c["ref"]}.{p.number}')
    hole_clearance={(round(transform(c,h['x'],h['y'])[0],6),round(transform(c,h['x'],h['y'])[1],6)):
                    h.get('copper_clearance_mm',data.get('routing_constraints',{}).get('component_hole_clearance',{}).get(c['ref'],.25))
                    for c in data['components'] for h in c.get('pcb_footprint',{}).get('holes',[])}
    for x,y,diameter in holes['NPTH']:
        for ext in ('GTL','GBL'):
            if ext in parsed:
                clearance=parsed[ext]['geometry'].distance(circle(x,y,diameter))
                required=hole_clearance.get((round(x,6),round(y,6)),data.get('routing_constraints',{}).get('hole_clearance',.25))
                check(clearance>=required-1e-5,
                      f'{ext} copper clearance from nonplated hole',dict(x=x,y=y,clearance_mm=clearance))
    for side, mask in apertures.items():
        for i, (ref_a, a) in enumerate(mask):
            for ref_b, b in mask[i+1:]:
                gap = a.distance(b)
                if 1e-6 < gap < data.get('manufacturing', {}).get('minimum_mask_sliver_mm', .1)-1e-6:
                    check(False, f'{side} minimum mask sliver', dict(a=ref_a,b=ref_b,gap_mm=gap))
                if a.intersects(b) and ref_a.split('.')[0] != ref_b.split('.')[0]:
                    warnings.append(f'{side} soldermask openings merge: {ref_a}/{ref_b}')
    for ext, mask in (('GTO', 'GTS'), ('GBO', 'GBS')):
        if ext not in parsed or mask not in parsed:
            continue
        silk = parsed[ext]['geometry']
        check(silk.is_empty or board.buffer(.00001).covers(silk), f'{ext} silkscreen within board')
        silk_gap=data.get('manufacturing',{}).get('silkscreen_clearance_mm',.15)
        check(silk.intersection(parsed[mask]['geometry'].buffer(silk_gap)).area < 1e-8, f'{ext} silkscreen to openings >={silk_gap} mm')
        for path in parsed[ext]['paths']:
            check(path['width'] >= .15-1e-6, f'{ext} line width >=0.15 mm')
    for side, mask in (('GTP','GTL'), ('GBP','GBL')):
        if side in parsed and mask in parsed:
            check(parsed[side]['geometry'].is_empty or parsed[mask]['geometry'].buffer(.00001).covers(parsed[side]['geometry']), f'{side} paste lies on copper')
    def read_csv(filename):
        with (directory / filename).open(encoding='utf-8-sig', newline='') as handle:
            return list(csv.DictReader(handle))
    bom, cpl = read_csv('BOM-JLCPCB.csv'), read_csv('CPL-JLCPCB.csv')
    bom_refs, cpl_refs = [], []
    by_ref = {c['ref']: c for c in data['components']}
    for row in bom:
        check(bool(re.fullmatch(r'C[0-9]+', row['LCSC Part #'])), 'BOM code syntactically valid')
        for ref in row['Designator'].split(','):
            bom_refs.append(ref)
            check(ref in by_ref, 'BOM reference exists', ref)
            a = by_ref.get(ref, {}).get('assembly', {})
            check(a.get('lcsc_confirmed') is True and a.get('source_url') and a.get('lcsc') == row['LCSC Part #'],
                  'BOM uses confirmed supplier evidence', ref)
    for row in cpl:
        ref = row['Designator']
        cpl_refs.append(ref)
        check(ref in by_ref, 'CPL reference exists', ref)
        if ref not in by_ref:
            continue
        c = by_ref[ref]
        a = c.get('assembly', {})
        x, y = transform(c, *a.get('centroid_offset_mm', [0,0]))
        check(abs(float(row['Mid X'].removesuffix('mm'))-x)<1e-6 and abs(float(row['Mid Y'].removesuffix('mm'))-y)<1e-6,
              'CPL centroid matches CAD mm', ref)
        check(row['Layer'] == c['pcb'].get('layer', 'TOP').title(), 'CPL side matches CAD', ref)
        check(abs(float(row['Rotation'])-(c['pcb'].get('rotation',0)+a.get('rotation_offset_deg',0))%360)<1e-6,
              'CPL CCW rotation matches CAD and explicit offset', ref)
    check(Counter(bom_refs) == Counter(cpl_refs), 'BOM/CPL references match exactly')
    check(len(bom_refs) == len(set(bom_refs)) and len(cpl_refs) == len(set(cpl_refs)), 'No duplicate BOM/CPL references')
    unresolved = read_csv('BOM-UNRESOLVED.csv')
    excluded = read_csv('BOM-EXCLUDED.csv')
    represented = bom_refs + [r['Designator'] for r in unresolved] + [r['Designator'] for r in excluded]
    check(Counter(represented) == Counter(by_ref.keys()), 'Every CAD component has explicit assembly disposition')
    if unresolved:
        warnings.append('PCBA BOM is incomplete: ' + ', '.join(r['Designator'] for r in unresolved))
    manifest = json.loads((directory / 'manufacturing-manifest.json').read_text('utf-8'))
    for filename, digest in manifest['files'].items():
        check(hashlib.sha256((directory/filename).read_bytes()).hexdigest() == digest, 'Manufacturing file checksum', filename)
    with zipfile.ZipFile(directory / f'{name}-Gerber.zip') as archive:
        check(archive.testzip() is None, 'Gerber ZIP integrity')
        check(set(archive.namelist()) == set(manifest['files']), 'ZIP has exactly fabrication layers and drill files')
        for filename in archive.namelist():
            check(archive.read(filename) == (directory/filename).read_bytes(), 'ZIP matches actual manufacturing data', filename)
    return dict(passed=not errors, checks=len(checks), errors=errors, warnings=warnings,
                geometry=geometry_statistics, drills=drill_results, pcba_bom_complete=not unresolved,
                scope='Independent strict Gerber/XNC readback; copper, mask, paste, outline and drill geometry versus CAD JSON; local DFM checks and BOM/CPL consistency. Does not replace native CAD DRC, JLC assembly orientation review or hardware qualification.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--design', type=Path)
    parser.add_argument('--routing', type=Path)
    parser.add_argument('--out', type=Path)
    parser.add_argument('--name', default='Orion-Bridge-R4')
    parser.add_argument('--self-test', action='store_true', help='Exercise rotated pads, slots, rounded outline, region holes and deliberate bad files')
    args = parser.parse_args()
    if args.self_test:
        print(json.dumps(self_test(), indent=2))
        return
    if not all((args.design,args.routing,args.out)):
        parser.error('--design, --routing and --out are required unless --self-test is used')
    result = verify(json.loads(args.design.read_text('utf-8')), json.loads(args.routing.read_text('utf-8')), args.out, args.name)
    (args.out / 'manufacturing-verification.json').write_text(json.dumps(result, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')
    print(json.dumps(result, indent=2))
    raise SystemExit(0 if result['passed'] else 1)


def self_test():
    """Manufacturing failure-mode regression fixtures, never a real assembly BOM."""
    import tempfile
    from export_jlcpcb_r4 import export
    data = dict(board=dict(width_mm=24,height_mm=20,corner_radius_mm=2,
                           holes_mm=[[3,17]],hole_diameter_mm=1.2,
                           silkscreen=[dict(text='TEST R4',x=11,y=2,height=1,width=.15)]),
                components=[],routing_constraints=dict(edge_clearance=.25))
    def comp(ref,x,y,rot,shape,sx,sy,drill=0,**meta):
        return dict(ref=ref,value='TEST ONLY',footprint='TEST FIXTURE',pins=[dict(number='1',net='TEST')],
                    pcb=dict(x=x,y=y,rotation=rot),assembly=dict(populate=False,note='Synthetic regression fixture'),
                    pcb_footprint=dict(pads=[dict(number='1',x=0,y=0,sx=sx,sy=sy,drill=drill,shape=shape,**meta)],
                                       body=[sx,sy],height=1,note='Synthetic regression fixture'))
    data['components'] = [comp('R1',4,4,37,'RECTANGLE',2,1), comp('C1',9,6,23,'ROUND',2,1),
                          comp('J1',4,10,33,'RECTANGLE',4,2,.6,drill_slot_length_mm=2.5,drill_slot_angle_deg=0),
                          comp('U1',17,7,90,'RECTANGLE',3,3,paste_windows=[dict(x=-.75,y=0,sx=1,sy=2),dict(x=.75,y=0,sx=1,sy=2)])]
    # A populated but deliberately unsourced fixture exercises real paste
    # windows without inventing an orderable supplier code. DNP R1/C1 stay dry.
    data['components'][-1]['assembly']['populate']=True
    data['board']['silkscreen'].append(dict(text='B',x=6,y=15,height=1,width=.15,layer='BOTTOM'))
    route = dict(tracks=[dict(layer='BOTTOM',net='TEST',x1=9,y1=10,x2=12,y2=10,width=.3)],
                 vias=[dict(x=9,y=10,diameter=.6,drill=.3,net='TEST')],
                 regions=[dict(layer='TOP',net='TEST',points=[[12,12],[20,12],[20,18],[12,18]],
                               holes=[[[14,14],[14,16],[18,16],[18,14]]])])
    with tempfile.TemporaryDirectory(prefix='jlc-format-regression-', dir=ROOT/'tmp') as folder:
        export(data,route,folder,'Fixture')
        result = verify(data,route,folder,'Fixture')
        if not result['passed']:
            raise AssertionError(result['errors'])
        paste=parse_gerber(Path(folder)/'Fixture.GTP')['geometry']
        if abs(paste.area-4)>1e-8 or paste.intersects(circle(4,4,.2)):
            raise AssertionError('Windowed paste or DNP paste suppression is wrong')
        silk=parse_gerber(Path(folder)/'Fixture.GBO')['geometry']
        if silk.bounds[2]>6.075001 or silk.bounds[0]>5.426:
            raise AssertionError('Bottom lettering is not mirrored in common top-view coordinates')
        path=Path(folder)/'Fixture.GTL'
        good=path.read_text('ascii')
        path.write_text(good.replace('%MOMM*%','%MOIN*%'),encoding='ascii')
        try:
            parse_gerber(path)
        except ValueError:
            pass
        else:
            raise AssertionError('Mixed units escaped validation')
        path.write_text(good.replace('X4000000Y4000000D03*','X5000000Y4000000D03*'),encoding='ascii')
        mutated=verify(data,route,folder,'Fixture')
        if not any(e['check']=='GTL equals CAD geometry' for e in mutated['errors']):
            raise AssertionError('A moved copper pad escaped validation')
        return dict(passed=True,geometry_checks=result['checks'],mutations_detected=['mixed units','moved pad'],
                    exercised=['37-degree rectangle','rotated elliptical aperture','angled plated slot',
                               'four true rounded-corner arcs','region hole','windowed thermal-pad paste',
                               'tented via','nonplated drill','single-stroke silkscreen','mirrored bottom lettering','explicit DNP BOM and paste suppression'])


if __name__ == '__main__':
    main()
