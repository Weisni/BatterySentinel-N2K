"""Independent geometry/assembly review of the R4 single-unit customer panel.

Reads actual Gerber and Excellon output. Does not call the panel generator or
trust its preflight results. A prototype check never gives a release pass.
"""
from __future__ import annotations
import argparse
from collections import Counter
import copy
import hashlib
import json
from pathlib import Path
import sys
import zipfile

ROOT=Path(__file__).resolve().parents[1]
sys.dont_write_bytecode=True
sys.path.insert(0,str(ROOT/'tmp/pcb-python'))
from shapely import affinity
from shapely.geometry import Point,LineString,Polygon,box
from shapely.ops import unary_union
from verify_altium_project import Audit
from verify_altium_r4 import rounded_board,transform,hole_shape,check_assembly
from verify_jlcpcb_r4 import parse_gerber,parse_drill,expected_geometry,circle

NAME='Orion-Bridge-R4-Panel'
LAYERS=('GTL','GBL','GTS','GBS','GTP','GBP','GTO','GBO','GKO')


def profile_contours(a,paths):
    contours=[];pending=[]
    for path in paths:
        a.check(path.get('mode')=='G01','Panel profile uses unsupported curved path record')
        pts=path['points']
        if not pending:pending=list(pts)
        elif Point(pending[-1]).distance(Point(pts[0]))<1e-7:pending.extend(pts[1:])
        else:
            a.check(False,'Panel profile has a discontinuity');pending=list(pts)
        if len(pending)>=4 and Point(pending[0]).distance(Point(pending[-1]))<1e-7:
            poly=Polygon(pending);a.check(poly.is_valid and poly.area>0,'Invalid panel profile contour')
            contours.append(poly);pending=[]
    a.check(not pending,'Panel profile contains an unclosed contour')
    return contours


def verify_panel(directory,design_path,routing_path,allow_prototype=False):
    a=Audit();report={}
    try:
        manifest=json.loads((directory/'manufacturing-manifest.json').read_text('utf-8'))
        spec=manifest['panelization'];dx,dy=spec['unit_translation_mm']
        design=json.loads(design_path.read_text('utf-8'));route=json.loads(routing_path.read_text('utf-8'))
        source_hashes={Path(s['path'].replace('\\','/')).name:s['sha256'] for s in manifest['sources']}
        for path in (design_path,routing_path):
            a.check(source_hashes.get(path.name)==hashlib.sha256(path.read_bytes()).hexdigest(),
                    'Panel was produced from a different source snapshot: '+path.name)
        if not allow_prototype:
            a.check(not manifest.get('prototype_only',False),'Panel is explicitly marked prototype-only')
            a.check(route.get('verification',{}).get('passed') is True,'Unit routing has not passed its own audit')
        a.check(spec['count']==1 and spec['panel_size_mm']==[70,70],'Expected one unit on a 70 x 70 mm panel')
        a.check(spec['unit_size_mm']==[design['board']['width_mm'],design['board']['height_mm']],
                'Panel unit dimensions differ from reviewed carrier')
        a.check(spec['unit_corner_radius_mm']==design['board']['corner_radius_mm'],'Panel changed rounded carrier corner radius')
        a.check(spec['minimum_transport_rail_mm']>=5,'Panel transport rail below 5 mm')
        parsed={ext:parse_gerber(directory/f'{NAME}.{ext}') for ext in LAYERS}
        for ext in LAYERS:
            raw=(directory/f'{NAME}.{ext}').read_text('ascii')
            a.check('%TF.Part,Panel*%' in raw,ext+': not marked as a customer panel')
        contours=profile_contours(a,parsed['GKO']['paths'])
        a.check(len(contours)==5,'Panel must have one outer profile and four routed voids')
        if len(contours)!=5:raise ValueError('Cannot reconstruct panel substrate')
        outer=max(contours,key=lambda p:p.area)
        cavities=[p for p in contours if p is not outer]
        void=unary_union(cavities);substrate=outer.difference(void)
        a.check(outer.hausdorff_distance(box(0,0,70,70))<1e-5,'Actual outer profile is not 70 x 70 mm')
        a.check(substrate.geom_type=='Polygon' and substrate.is_valid,'Routed voids disconnect the panel/support tabs')
        a.check(box(5,5,65,65).covers(void),'Actual routed void enters the 5 mm outer rail')
        want_void=unary_union([Polygon(p) for p in spec['routed_void_contours_mm']])
        a.check(void.hausdorff_distance(want_void)<1e-5 and void.symmetric_difference(want_void).area<.001,
                'Actual CNC void contours differ from the declared panel drawing')
        unit=affinity.translate(rounded_board(design['board']),dx,dy)
        # The independent analytic rounded-board reconstruction and exported
        # contour use different arc tessellations. Fifty nanometres bounds
        # their chord/coordinate rounding error without hiding a routed cut.
        contour_tolerance=.00005
        a.check(substrate.buffer(contour_tolerance).covers(unit),'Routed cavity removes material from the nominal unit outline')
        copper=unary_union([parsed['GTL']['geometry'],parsed['GBL']['geometry']])
        a.check(substrate.buffer(1e-5).covers(copper),'Actual copper enters a routed void or leaves panel outline')
        a.check(copper.distance(void)>=.1999,'Actual panel copper is less than 0.20 mm from a routed cavity')
        expected,drills,*_=expected_geometry(design,route)
        unit_directory=directory.parent/'manufacturing'
        unit_layers={ext:parse_gerber(unit_directory/f'Orion-Bridge-R4.{ext}')['geometry']
                     for ext in ('GTL','GBL','GTP','GBP','GTS','GBS')}
        for ext,got in unit_layers.items():
            want=expected[ext]
            a.check(got.difference(want.buffer(.000003)).area<1e-7 and want.difference(got.buffer(.000003)).area<1e-7,
                    'Actual single-board Gerber does not match its reviewed source: '+ext)
        fids=spec['fiducials']
        a.check(len(fids)==3,'Panel requires three global fiducials')
        fid_copper=unary_union([circle(f['x'],f['y'],f['diameter_mm']) for f in fids])
        fid_mask=unary_union([circle(f['x'],f['y'],f['mask_diameter_mm']) for f in fids])
        added=spec['mouse_bites']+spec['tooling_holes']
        added_mask=unary_union([circle(h['x'],h['y'],h['diameter_mm']+
                           2*design.get('manufacturing',{}).get('mask_expansion_mm',.05)) for h in added])
        for ext in ('GTL','GBL','GTP','GBP','GTS','GBS'):
            want=affinity.translate(unit_layers[ext],dx,dy)
            if ext=='GTL':want=unary_union([want,fid_copper])
            if ext in ('GTS','GBS'):want=unary_union([want,added_mask])
            if ext=='GTS':want=unary_union([want,fid_mask])
            got=parsed[ext]['geometry']
            a.check(got.difference(want.buffer(.000003)).area<1e-7 and want.difference(got.buffer(.000003)).area<1e-7,
                    'Panel altered/mirrored unit '+ext+' rather than translating it')
        for fid in fids:
            a.check(fid['diameter_mm']==1 and fid['mask_diameter_mm']==2 and fid['layer']=='TOP','Unexpected global fiducial dimensions/side')
            fidshape=Point(fid['x'],fid['y']).buffer(.5,quad_segs=180)
            a.check(fidshape.distance(outer.boundary)>=2.9999,'Global fiducial copper is too close to panel edge')
            a.check(fidshape.distance(unit)>1,'Global fiducial intrudes on assembled carrier')
            aperture=circle(fid['x'],fid['y'],2)
            a.check(parsed['GTS']['geometry'].buffer(.000003).covers(aperture),'Missing actual global fiducial mask opening')
            a.check(parsed['GTP']['geometry'].intersection(aperture).area<1e-7,'Global fiducial has a solder-paste aperture')
        actual_holes={typ:parse_drill(directory/f'{NAME}-{typ}.drl') for typ in ('PTH','NPTH')}
        shift=lambda h:(h[0]+dx,h[1]+dy,*h[2:])
        normalize=lambda holes:Counter(tuple(round(v,5) for v in h) for h in holes)
        for typ in ('PTH','NPTH'):
            actual_unit=parse_drill(unit_directory/f'Orion-Bridge-R4-{typ}.drl')
            a.check(normalize(actual_unit)==normalize(drills[typ]),'Actual single-board '+typ+' drill file differs from reviewed source')
        a.check(normalize(actual_holes['PTH'])==normalize([shift(h) for h in drills['PTH']]),
                'Panel changed plated unit holes/slots or mirrored their coordinates')
        want_npth=[shift(h) for h in drills['NPTH']]+[(h['x'],h['y'],h['diameter_mm']) for h in added]
        a.check(normalize(actual_holes['NPTH'])==normalize(want_npth),'Actual panel NPTH differs from unit + mouse bites + tooling')
        minimum_hole=float('inf')
        unit_holes=[hole_shape(*shift(h)[:3],*(shift(h)[3:] if len(h)>3 else ())) for h in drills['PTH']+drills['NPTH']]
        for h in added:
            geom=Point(h['x'],h['y']).buffer(h['diameter_mm']/2,quad_segs=180)
            clearance=geom.distance(copper);minimum_hole=min(minimum_hole,clearance)
            a.check(clearance>=.1999,'Added panel hole approaches actual copper: '+str((h['x'],h['y'])))
            for other in unit_holes:
                a.check(geom.distance(other)>=.2999,'Added panel hole approaches an existing unit drill/slot')
        a.check(len(spec['tooling_holes'])==4,'Panel requires four tooling holes')
        for h in spec['tooling_holes']:
            a.check(h['diameter_mm']==2,'Unexpected tooling hole size')
            geom=Point(h['x'],h['y']).buffer(1,quad_segs=180)
            a.check(substrate.covers(geom) and geom.distance(outer.boundary)>=1.9999,'Tooling hole not safely contained in rail')
        a.check(len(spec['tabs'])==4 and len(spec['mouse_bites'])==24,'Expected four tabs and six mouse bites per tab')
        for tab in spec['tabs']:
            a.check(tab['width_mm']>=5 and tab['hole_edge_spacing_mm']>=.2999,'Tab width or inter-hole material web insufficient')
            a.check(tab['hole_diameter_mm']==.6 and tab['hole_pitch_mm']==.9,'Unexpected reviewed mouse-bite dimensions')
            a.check(len(tab['holes_mm'])==6,'Tab does not have six perforations')
            pts=[Point(p) for p in tab['holes_mm']]
            for first,second in zip(pts,pts[1:]):
                a.check(abs(first.distance(second)-.9)<1e-6,'Mouse-bite pitch differs from 0.9 mm')
            a.check(all(p.distance(unit.boundary)<1e-5 for p in pts),'Mouse-bite row does not follow unit breakaway edge')
            c=tab['unit_edge_centre_mm'];half=tab['width_mm']/2;gap=spec['routing_gap_mm']
            if tab['side']=='left':bridge=box(dx-gap,dy+c-half,dx,dy+c+half)
            elif tab['side']=='right':bridge=box(dx+design['board']['width_mm'],dy+c-half,dx+design['board']['width_mm']+gap,dy+c+half)
            elif tab['side']=='bottom':bridge=box(dx+c-half,dy-gap,dx+c+half,dy)
            elif tab['side']=='top':bridge=box(dx+c-half,dy+design['board']['height_mm'],dx+c+half,dy+design['board']['height_mm']+gap)
            else:raise ValueError('Unknown panel tab side')
            a.check(substrate.buffer(1e-5).covers(bridge),'Actual support tab is narrower/disconnected: '+tab['side'])
        for part in design['components']:
            if not part.get('assembly',{}).get('populate'):continue
            width,height=part['pcb_footprint']['body']
            body=affinity.translate(transform(part,box(-width/2,-height/2,width/2,height/2)),dx,dy)
            outside=body.difference(unit.buffer(contour_tolerance))
            a.check(outside.is_empty or void.buffer(contour_tolerance).covers(outside),'Frame material lies beneath overhanging package '+part['ref'])
        mcu=next(c for c in design['components'] if c['ref']=='MCU1')
        antenna=affinity.translate(transform(mcu,box(-9,4,9,10)),dx,dy)
        a.check(antenna.intersection(substrate).area<1e-5,'Panel leaves FR4 under WROOM antenna')
        a.check(antenna.intersection(copper).area<1e-7,'Panel leaves copper under WROOM antenna')
        translated=copy.deepcopy(design)
        for p in translated['components']:p['pcb']['x']+=dx;p['pcb']['y']+=dy
        report['assembly']=check_assembly(a,directory,{p['ref']:p for p in translated['components']},
                            directory/'BOM-JLCPCB.csv',directory/'CPL-JLCPCB.csv')
        files=[directory/f'{NAME}.{ext}' for ext in LAYERS]+[directory/f'{NAME}-{typ}.drl' for typ in ('PTH','NPTH')]
        with zipfile.ZipFile(directory/f'{NAME}-Gerber.zip') as archive:
            a.check(set(archive.namelist())=={p.name for p in files},'Panel ZIP contains missing/additional files')
            for path in files:
                a.check(archive.read(path.name)==path.read_bytes(),'Panel ZIP differs from reviewed actual file '+path.name)
                a.check(manifest['files'].get(path.name)==hashlib.sha256(path.read_bytes()).hexdigest(),'Panel manifest hash mismatch '+path.name)
        report.update(panel_size_mm=[70,70],unit_translation_mm=[dx,dy],tabs=len(spec['tabs']),
                      profile_contours=len(contours),minimum_cavity_copper_clearance_mm=copper.distance(void),
                      minimum_added_hole_copper_clearance_mm=minimum_hole,plated_drills=len(actual_holes['PTH']),
                      nonplated_drills=len(actual_holes['NPTH']),contour_comparison_tolerance_mm=contour_tolerance)
    except Exception as error:
        a.errors.append(f'Panel audit could not complete: {type(error).__name__}: {error}')
    report.update(passed=not a.errors,release_checks_complete=not a.errors and not allow_prototype,
                  checks=a.checks,errors=a.errors,
                  scope='Independent actual single-board and panel Gerber/Excellon profile, copper/mask/paste translation, support tabs, holes, antenna/body voids, BOM/CPL translation and ZIP/hash audit. Unit electrical/native DRC and JLC manufacturing review are separate prerequisites.')
    return report


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory',type=Path)
    parser.add_argument('--design',type=Path,default=ROOT/'hardware/altium-r4/orion-r4-design.json')
    parser.add_argument('--routing',type=Path,default=ROOT/'hardware/altium-r4/orion-r4-routing.json')
    parser.add_argument('--allow-prototype',action='store_true')
    parser.add_argument('--report',type=Path)
    args=parser.parse_args()
    result=verify_panel(args.directory,args.design,args.routing,args.allow_prototype)
    if args.report:args.report.write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
    print(json.dumps(result,indent=2))
    return 0 if result['passed'] else 1


if __name__=='__main__':sys.exit(main())
