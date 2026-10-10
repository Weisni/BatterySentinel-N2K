"""Produce a 1-up 70 x 70 mm routed customer panel from the checked R4 unit.

No unit copper/paste/pin geometry is redesigned here: only a common XY
translation is applied. The disposable frame adds three fiducials, four
tooling holes and four perforated support tabs. Real profile cutouts keep the
WROOM antenna and USB shell clear of the frame. Unit CAD remains authoritative.

Run after the final unit routing, then independently verify the generated files.
This script does not imply electrical qualification or a JLC order acceptance.
"""
from __future__ import annotations

import argparse
import copy
import csv
import hashlib
import json
from pathlib import Path
import zipfile

from export_jlcpcb_r4 import Gerber, LAYER_FILES, assembly_lists, export
from verify_jlcpcb_r4 import (affinity, box, circle, expected_geometry, parse_drill,
                              parse_gerber, Polygon, rounded_board, unary_union)
from altium_pcb import footprint

SIZE = 70.0
GAP = 2.0
TAB_WIDTH = 5.1
MOUSE_DIAMETER = .6
MOUSE_PITCH = .9
TAB_SPECS = [('left', 7.5), ('bottom', 8.0), ('top', 10.0), ('right', 10.5)]
NAME = 'Orion-Bridge-R4-Panel'
SOURCE_URLS = [
    'https://jlcpcb.com/capabilities/pcb-capabilities',
    'https://jlcpcb.com/capabilities/pcb-assembly-capabilities',
    'https://jlcpcb.com/blog/mouse-bite-panelization-guide',
    'https://jlcpcb.com/help/article/how-to-add-edge-rails-fiducials-for-pcb-assembly-order',
]


def polygons(geometry):
    if geometry.is_empty:
        return []
    return [geometry] if geometry.geom_type == 'Polygon' else list(geometry.geoms)


def rounded(geometry, radius=.5):
    """Tool-accessible cavity: no convex cavity corner tighter than R0.5."""
    return geometry.buffer(-radius, quad_segs=90).buffer(radius, quad_segs=90)


def points(ring):
    return [[round(x, 6), round(y, 6)] for x, y in ring.coords]


def panel_mechanics(data):
    b = data['board']
    w,h=b['width_mm'],b['height_mm']
    if not (47<=w<=50 and h==32 and b.get('corner_radius_mm')==2):
        raise ValueError('This reviewed panel supports only the 47..50 x 32 mm R2 R4 carrier')
    offset=((SIZE-w)/2,16.)
    unit = rounded_board(b)
    # CNC-clear windows, not merely graphical keepouts. There is at least 1 mm
    # around the documented overhanging package envelopes. No copper is added.
    mcu=next(c for c in data['components'] if c['ref']=='MCU1')
    usb=next(c for c in data['components'] if c['ref']=='J2')
    if mcu['pcb'].get('rotation',0) or usb['pcb'].get('rotation',0):
        raise ValueError('Panel overhang clearances assume upright MCU1 and J2 footprints')
    antenna_window = box(mcu['pcb']['x']-10, h-.5, mcu['pcb']['x']+10, mcu['pcb']['y']+11)
    usb_window = box(usb['pcb']['x']-5.47, -2.0, usb['pcb']['x']+5.47, .1)
    exterior = unary_union([unit.buffer(GAP, quad_segs=180), antenna_window, usb_window])
    tabs, holes, bridges = [], [], []
    for side, centre in TAB_SPECS:
        half = TAB_WIDTH / 2
        if side in ('left', 'right'):
            x = 0 if side == 'left' else w
            bridge = box(x-GAP-.1, centre-half, x+GAP+.1, centre+half)
            row = [(x, centre+(i-2.5)*MOUSE_PITCH) for i in range(6)]
        else:
            y = 0 if side == 'bottom' else h
            bridge = box(centre-half, y-GAP-.1, centre+half, y+GAP+.1)
            row = [(centre+(i-2.5)*MOUSE_PITCH, y) for i in range(6)]
        bridges.append(bridge)
        holes.extend([dict(x=x+offset[0], y=y+offset[1], diameter_mm=MOUSE_DIAMETER,
                           type='mouse_bite', tab=side) for x,y in row])
        tabs.append(dict(side=side, unit_edge_centre_mm=centre, width_mm=TAB_WIDTH,
                         hole_diameter_mm=MOUSE_DIAMETER, hole_pitch_mm=MOUSE_PITCH,
                         hole_edge_spacing_mm=MOUSE_PITCH-MOUSE_DIAMETER,
                         holes_mm=[[x+offset[0],y+offset[1]] for x,y in row]))
    cavities = rounded(exterior.difference(unit).difference(unary_union(bridges)))
    # A CAM profile is a set of simple closed contours. Nested holes or dropped
    # islands would change topology and must fail closed rather than be guessed.
    cutouts = polygons(cavities)
    if len(cutouts) != len(TAB_SPECS) or any(p.interiors for p in cutouts):
        raise ValueError(f'Expected four simple routed cavities, found {len(cutouts)}')
    cutouts = [affinity.translate(p, *offset) for p in cutouts]
    translated_unit = affinity.translate(unit, *offset)
    outer = box(0, 0, SIZE, SIZE)
    frame_and_unit = outer.difference(unary_union(cutouts))
    if frame_and_unit.geom_type != 'Polygon' or not frame_and_unit.is_valid:
        raise ValueError('Support tabs do not connect the panel into one valid substrate')
    if not box(5,5,65,65).contains(unary_union(cutouts)):
        raise ValueError('Cavities violate the four 5 mm outer transport rails')
    tooling = [dict(x=x,y=y,diameter_mm=2.,type='tooling')
               for x,y in [(3.85,12), (66.15,12), (3.85,58), (66.15,58)]]
    fiducials = [dict(x=x,y=y,diameter_mm=1.,mask_diameter_mm=2.,layer='TOP')
                 for x,y in [(3.85,3.85), (66.15,3.85), (3.85,66.15)]]
    return dict(unit=translated_unit, unit_size=[w,h], offset=offset, substrate=frame_and_unit, cutouts=cutouts,
                tabs=tabs, mouse_bites=holes, tooling=tooling, fiducials=fiducials,
                antenna_window=affinity.translate(antenna_window,*offset),
                usb_window=affinity.translate(usb_window,*offset))


def translate_inputs(data, route, mechanics):
    d, r = copy.deepcopy(data), copy.deepcopy(route)
    dx,dy = mechanics['offset']
    for c in d['components']:
        c['pcb']['x'] += dx
        c['pcb']['y'] += dy
    b = d['board']
    holes = []
    for h in b.get('holes_mm', []):
        x,y,diam = (h['x'],h['y'],h['diameter_mm']) if isinstance(h,dict) else (*h,b['hole_diameter_mm'])
        holes.append(dict(x=x+dx,y=y+dy,diameter_mm=diam,type='unit_mounting'))
    b.update(width_mm=SIZE,height_mm=SIZE,corner_radius_mm=0,
             holes_mm=holes+mechanics['mouse_bites']+mechanics['tooling'])
    for f in b.get('fiducials_mm', []):
        f['x'] += dx; f['y'] += dy
    b['fiducials_mm'] = b.get('fiducials_mm', []) + mechanics['fiducials']
    for item in b.get('silkscreen', []):
        if 'points' in item:
            item['points'] = [[x+dx,y+dy] for x,y in item['points']]
        else:
            item['x'] += dx; item['y'] += dy
    b.setdefault('silkscreen', []).extend([
        dict(text='ORION R4',x=9,y=64,height=1.5,width=.18,layer='TOP'),
        dict(text='1X1 PANEL 70X70',x=9,y=61,height=1.2,width=.16,layer='TOP'),
        dict(text='ROUTED TABS - NO V-CUT',x=9,y=7.5,height=1.,width=.15,layer='TOP'),
    ])
    for t in r['tracks']:
        for k in ('x1','x2'): t[k] += dx
        for k in ('y1','y2'): t[k] += dy
    for v in r['vias']:
        v['x'] += dx; v['y'] += dy
    for reg in r.get('regions', []):
        for key in ('points','exterior'):
            if key in reg: reg[key] = [[x+dx,y+dy] for x,y in reg[key]]
        reg['holes'] = [[[x+dx,y+dy] for x,y in hole] for hole in reg.get('holes',[])]
    d['panelization'] = dict(unit_offset_mm=mechanics['offset'], unit_size_mm=mechanics['unit_size'], count=1,
                             profile_cutouts_mm=[points(p.exterior) for p in mechanics['cutouts']])
    return d,r


def preflight(data, route, mech):
    offset=mech['offset']
    layers, holes, *_ = expected_geometry(data,route)
    copper = affinity.translate(unary_union([layers['GTL'],layers['GBL']]),*offset)
    checks,errors = [],[]
    def check(ok,label,detail):
        (checks if ok else errors).append(dict(check=label,detail=detail))
    for i,p in enumerate(mech['cutouts']):
        clearance = p.distance(copper)
        check(clearance >= .2-1e-5,f'cutout_{i+1}_copper_clearance',clearance)
    for h in mech['mouse_bites']+mech['tooling']:
        hole = circle(h['x'],h['y'],h['diameter_mm'])
        gap = hole.distance(copper)
        check(gap >= .2-1e-5,f"{h['type']}_to_copper",dict(x=h['x'],y=h['y'],clearance_mm=gap))
        for source in holes['PTH']+holes['NPTH']:
            # Slots are conservatively enclosed by their full-length circle;
            # none are close to panel features. Round holes use true diameter.
            x,y,diam = source[:3]
            other = circle(x+offset[0],y+offset[1],source[3] if len(source)>3 else diam)
            gap = hole.distance(other)
            check(gap >= .3-1e-5,'panel_hole_to_unit_drill',gap)
    unit = mech['unit']
    cavities = unary_union(mech['cutouts'])
    for c in data['components']:
        f=footprint(c)
        body=box(-f.body[0]/2,-f.body[1]/2,f.body[0]/2,f.body[1]/2)
        body=affinity.translate(affinity.rotate(body,c['pcb'].get('rotation',0)),c['pcb']['x']+offset[0],c['pcb']['y']+offset[1])
        outside=body.difference(unit.buffer(1e-5))
        if not outside.is_empty:
            check(outside.difference(cavities.buffer(1e-5)).area<1e-7,'overhanging_body_inside_actual_cutout',c['ref'])
    # No FR4/copper is allowed beneath the six millimetres of the module antenna
    # outside the carrier. The closed profile actually removes this material.
    mcu=next(c for c in data['components'] if c['ref']=='MCU1')
    antenna=box(mcu['pcb']['x']-9+offset[0],data['board']['height_mm']+offset[1]+.001,
                mcu['pcb']['x']+9+offset[0],mcu['pcb']['y']+10+offset[1])
    check(antenna.difference(cavities).area<1e-7,'antenna_clear_of_panel_material',antenna.bounds)
    return dict(passed=not errors,checks=checks,errors=errors)


def readback(out,data,route,mech,unit_data):
    offset=mech['offset']
    checks,errors=[],[]
    def check(ok,label,detail=None):
        (checks if ok else errors).append(dict(check=label,detail=detail))
    expected,holes,*_=expected_geometry(data,route)
    parsed={ext:parse_gerber(out/f'{NAME}.{ext}') for ext in LAYER_FILES}
    for ext,g in expected.items():
        got=parsed[ext]['geometry']
        delta=got.symmetric_difference(g).area
        check(got.difference(g.buffer(.000002)).area<1e-7 and g.difference(got.buffer(.000002)).area<1e-7,
              'readback_'+ext,dict(symmetric_difference_mm2=delta))
    for typ in ('PTH','NPTH'):
        got=parse_drill(out/f'{NAME}-{typ}.drl')
        normalize=lambda rows:sorted(tuple(round(v,6) for v in row) for row in rows)
        check(normalize(got)==normalize(holes[typ]),'readback_'+typ,len(got))
    # Profile line centres, not their display stroke edges, define the routed
    # substrate. Every contour is explicitly closed in the manufacturing data.
    paths=parsed['GKO']['paths']
    assembled=[];pending=[]
    for p in paths:
        a,b=p['points'][0],p['points'][-1]
        if not pending: pending=[a,b]
        elif tuple(pending[-1])==tuple(a):pending.append(b)
        else:
            check(False,'profile_continuity',dict(previous=pending[-1],start=a));pending=[a,b]
        if len(pending)>3 and tuple(pending[0])==tuple(pending[-1]):
            assembled.append(Polygon(pending));pending=[]
    check(not pending,'profile_all_contours_closed',len(pending))
    check(len(assembled)==5,'profile_has_outer_and_four_routed_cutouts',len(assembled))
    if len(assembled)==5:
        board=max(assembled,key=lambda p:p.area)
        cavity=unary_union([p for p in assembled if p is not board])
        substrate=board.difference(cavity)
        check(substrate.symmetric_difference(mech['substrate']).area<.001,'profile_substrate_matches_design',substrate.area)
        copper=unary_union([parsed['GTL']['geometry'],parsed['GBL']['geometry']])
        check(copper.difference(substrate).area<1e-7,'readback_no_copper_in_routed_voids',copper.difference(substrate).area)
        clearance=cavity.distance(copper)
        check(clearance>=.2-1e-5,'readback_cutout_copper_clearance',clearance)
    with (out/'CPL-JLCPCB.csv').open(encoding='utf-8-sig',newline='') as handle:
        cpl=list(csv.DictReader(handle))
    with (out/'BOM-JLCPCB.csv').open(encoding='utf-8-sig',newline='') as handle:
        bom=list(csv.DictReader(handle))
    original_bom,original_cpl,unresolved,_=assembly_lists(unit_data)
    check(not unresolved,'original_unit_bom_fully_sourced',unresolved)
    check(bom==original_bom,'panel_bom_identical_to_single_unit',len(bom))
    by_ref={row['Designator']:row for row in original_cpl}
    check(len(cpl)==len(by_ref)==len({r['Designator'] for r in cpl}),
          'panel_cpl_exactly_one_copy_of_each_component',len(cpl))
    for row in cpl:
        old=by_ref[row['Designator']]
        coordinates=[float(row['Mid X'].removesuffix('mm')),
                     float(row['Mid Y'].removesuffix('mm'))]
        expected_xy=[float(old['Mid X'].removesuffix('mm'))+offset[0],
                     float(old['Mid Y'].removesuffix('mm'))+offset[1]]
        check(max(abs(x-y) for x,y in zip(coordinates,expected_xy))<1e-5
              and row['Rotation']==old['Rotation'] and row['Layer']==old['Layer'],
              'panel_cpl_translation_only',row['Designator'])
    return dict(passed=not errors,checks=checks,errors=errors)


def svg_preview(out,data,mech):
    offset=mech['offset']
    def ring(coords):
        return 'M '+' L '.join(f'{x:.4f},{y:.4f}' for x,y in coords)+' Z'
    def shape(g,fill,stroke='none',width=.1):
        return ''.join(f'<path d="{ring(p.exterior.coords)} '+''.join(ring(r.coords)+' ' for r in p.interiors)+
                       f'" fill="{fill}" fill-rule="evenodd" stroke="{stroke}" stroke-width="{width}"/>' for p in polygons(g))
    rows=['<svg xmlns="http://www.w3.org/2000/svg" width="1050" height="1170" viewBox="-5 -10 80 90">',
          '<rect x="-5" y="-10" width="80" height="90" fill="#f4f6f8"/>',
          '<text x="0" y="-5" font-family="sans-serif" font-size="2.4" font-weight="bold">Orion R4 · Kundenpanel 1 × 1 · 70 × 70 mm</text>',
          '<g transform="translate(0,70) scale(1,-1)">',shape(mech['substrate'],'#cfdfd4','#314a3a'),
          shape(mech['unit'],'#5c9c75','#214b35')]
    for c in data['components']:
        f=footprint(c);p=box(-f.body[0]/2,-f.body[1]/2,f.body[0]/2,f.body[1]/2)
        p=affinity.translate(affinity.rotate(p,c['pcb'].get('rotation',0)),c['pcb']['x']+offset[0],c['pcb']['y']+offset[1])
        rows.append(shape(p,'#354452','#182630',.06))
    mounting=[]
    for h in data['board'].get('holes_mm',[]):
        x,y,diam=(h['x'],h['y'],h['diameter_mm']) if isinstance(h,dict) else (*h,data['board']['hole_diameter_mm'])
        mounting.append(dict(x=x+offset[0],y=y+offset[1],diameter_mm=diam))
    for h in mech['mouse_bites']+mech['tooling']+mounting:
        rows.append(f'<circle cx="{h["x"]}" cy="{h["y"]}" r="{h["diameter_mm"]/2}" fill="white" stroke="#213b31" stroke-width=".05"/>')
    for f in mech['fiducials']:
        rows.append(f'<circle cx="{f["x"]}" cy="{f["y"]}" r="1" fill="#f6d071"/><circle cx="{f["x"]}" cy="{f["y"]}" r=".5" fill="#bb7721"/>')
    rows.extend(['</g>',
        f'<text x="0" y="74" font-family="sans-serif" font-size="1.8">Einzelplatine: {mech["unit_size"][0]:g} × {mech["unit_size"][1]:g} mm, R2 · Versatz: +{offset[0]:g} / +{offset[1]:g} mm</text>',
        '<text x="0" y="77" font-family="sans-serif" font-size="1.65">4 Tabs · je 6 × Ø0,60 / Raster 0,90 · CNC-Freiräume für Antenne und USB</text>',
        '<text x="0" y="79" font-family="sans-serif" font-size="1.65">3 Fiducials Ø1 / Maske Ø2 · 4 Werkzeugbohrungen Ø2 · kein V-Cut</text>','</svg>'])
    (out/'Panel-70x70.svg').write_text('\n'.join(rows),encoding='utf8')


def build(design_path,routing_path,out,allow_unverified_route=False):
    source_bytes={p:p.read_bytes() for p in (design_path,routing_path)}
    data=json.loads(source_bytes[design_path]);route=json.loads(source_bytes[routing_path])
    out.mkdir(parents=True,exist_ok=True)
    archive_path=out/f'{NAME}-Gerber.zip'
    archive_path.unlink(missing_ok=True)
    if not allow_unverified_route and route.get('verification',{}).get('passed') is not True:
        raise ValueError('Source unit routing is not verified; release panel export refused')
    mech=panel_mechanics(data)
    before=preflight(data,route,mech)
    (out/'panel-preflight.json').write_text(json.dumps(before,indent=2)+'\n',encoding='utf8')
    svg_preview(out,data,mech)
    if not before['passed']:
        raise ValueError(f"Panel preflight failed: {before['errors']}")
    panel,translated_route=translate_inputs(data,route,mech)
    manifest=export(panel,translated_route,out,NAME,[design_path,routing_path,Path(__file__)])
    profile=Gerber('Profile,NP')
    profile.rounded_outline(SIZE,SIZE,0)
    for p in mech['cutouts']:profile.line(points(p.exterior),.05)
    profile.write(out/f'{NAME}.GKO')
    for ext in LAYER_FILES:
        p=out/f'{NAME}.{ext}'
        p.write_text(p.read_text('ascii').replace('%TF.Part,Single*%','%TF.Part,Panel*%'),encoding='ascii')
    after=readback(out,panel,translated_route,mech,data)
    (out/'panel-readback.json').write_text(json.dumps(after,indent=2)+'\n',encoding='utf8')
    # Rebuild the zip after replacing the actual CNC profile. A failed result
    # never leaves a zip that could be confused with the production package.
    archive_path.unlink(missing_ok=True)
    if not after['passed']:
        raise ValueError(f"Panel output readback failed: {after['errors']}")
    if any(p.read_bytes()!=raw for p,raw in source_bytes.items()):
        raise ValueError('Source design or routing changed during export; rerun against stable files')
    files=[out/f'{NAME}.{ext}' for ext in LAYER_FILES]+[out/f'{NAME}-{typ}.drl' for typ in ('PTH','NPTH')]
    with zipfile.ZipFile(archive_path,'w',zipfile.ZIP_DEFLATED) as archive:
        for p in files:archive.write(p,p.name)
    manifest['format']='Orion manufacturing manifest v2 - customer panel'
    manifest['files']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
    manifest['panelization']=dict(
        count=1,unit_size_mm=mech['unit_size'],unit_corner_radius_mm=2,unit_translation_mm=list(mech['offset']),
        panel_size_mm=[SIZE,SIZE],minimum_transport_rail_mm=5,
        routing_gap_mm=GAP,minimum_cavity_corner_radius_mm=.5,
        profile_curve_chord_tolerance_mm=.001,profile_line_width_mm=.05,
        profile_line_interpretation='CNC finished cavity boundary; stroke centre is the profile',
        tabs=mech['tabs'],mouse_bites=mech['mouse_bites'],tooling_holes=mech['tooling'],
        fiducials=mech['fiducials'],
        outer_profile_mm=[[0,0],[SIZE,0],[SIZE,SIZE],[0,SIZE],[0,0]],
        routed_void_contours_mm=[points(p.exterior) for p in mech['cutouts']],
        antenna_opening_mm=list(mech['antenna_window'].bounds),
        usb_opening_mm=list(mech['usb_window'].bounds),
        copper_transform=f"All original unit geometry translated +{mech['offset'][0]:g},+{mech['offset'][1]:g} mm without mirroring or rotation; only three isolated frame fiducials added",
        cpl_transform=f"All positions translated +{mech['offset'][0]:g},+{mech['offset'][1]:g} mm; refs, side and rotation unchanged; exactly one assembled unit",
        bom_transform='No duplication or substitutions; frame fiducials and holes are not BOM components',
        depanelization='After assembly support unit and cut perforated tabs; dress breakaway remnants flush with nominal outline. Do not flex under WROOM or converter.',
        sources=SOURCE_URLS)
    manifest['panel_preflight_passed']=before['passed']
    manifest['panel_output_readback_passed']=after['passed']
    manifest['source_unit_routing_verified']=route.get('verification',{}).get('passed') is True
    manifest['prototype_only']=allow_unverified_route
    manifest['qualification']='Geometric panel conversion checked; also requires final unit routing/electrical/native checks and manufacturer order review. No assembly order placed.'
    (out/'manufacturing-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
    (out/'panel-design.json').write_text(json.dumps(panel,indent=2)+'\n',encoding='utf8')
    (out/'panel-routing.json').write_text(json.dumps(translated_route,indent=2)+'\n',encoding='utf8')
    return dict(passed=True,preflight_checks=len(before['checks']),readback_checks=len(after['checks']),
                output=str(out),panel=[SIZE,SIZE],offset=list(mech['offset']),assembled_units=1)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--design',type=Path,required=True)
    parser.add_argument('--routing',type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--allow-unverified-route',action='store_true',help='Prototype only; never use for a manufacturing release')
    args=parser.parse_args()
    print(json.dumps(build(args.design,args.routing,args.out,args.allow_unverified_route),indent=2))
