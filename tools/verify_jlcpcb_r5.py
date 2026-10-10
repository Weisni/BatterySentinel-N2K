"""Strict R5 manufacturing readback plus exact native overlay comparison."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tmp/pcb-python'))
from export_jlcpcb_r5 import STEM,read_overlay_artwork,validate_text_declarations
from verify_jlcpcb_r4 import verify as verify_core,parse_gerber,parse_drill
from shapely.geometry import Polygon,LineString
from verify_native_gerber_r4 import drill_shape


def verify_profile(data,directory,name,result):
    """Replace only the R4 rectangular-profile assumptions with R5 topology."""
    board=data['board']
    if not board.get('outline_points_mm'):return
    old_labels={'Outline has expected segment count','Outline segment is continuous','Outline is closed',
                'Outline polygon valid','Rounded outline area equals design'}
    result['errors']=[error for error in result['errors'] if error['check'] not in old_labels]
    paths=parse_gerber(directory/f'{name}.GKO')['paths'];result['checks']-=len(paths)+3
    def check(ok,label,detail=None):
        result['checks']+=1
        if not ok:result['errors'].append(dict(check=label,detail=detail))
    contours=[];current=[]
    for path in paths:
        points=path['points']
        if current:
            if current[-1]!=points[0]:
                check(False,'Profile segments join before starting another contour');current=[]
            else:current.extend(points[1:])
        if not current:current=list(points)
        if len(current)>2 and current[-1]==current[0]:contours.append(current);current=[]
    check(not current,'No open fabrication profile contour remains')
    check(len(contours)==1+len(board.get('cutouts_mm',[])),'Profile has one exterior and exactly the declared internal cutouts')
    polygons=[]
    for points in contours:
        check(points[0]==points[-1],'Every profile contour is independently closed')
        g=Polygon(points);check(g.is_valid,'Every profile contour is simple and valid');polygons.append(g)
    if not polygons:return
    actual=polygons[0]
    for hole in polygons[1:]:
        check(actual.contains(hole),'Internal routed window is strictly inside board exterior')
        actual=actual.difference(hole)
    reference=Polygon(board['outline_points_mm'],[c['outline_points_mm'] for c in board.get('cutouts_mm',[])])
    check(reference.is_valid,'Declared profile topology is valid')
    check(actual.symmetric_difference(reference).area<.0001,'Fabrication profile equals declared notched board and RF cutout',actual.symmetric_difference(reference).area)
    for ext in ('GTL','GBL'):
        copper=parse_gerber(directory/f'{name}.{ext}')['geometry'];gap=data.get('routing_constraints',{}).get('edge_clearance',.3)
        check(copper.is_empty or actual.buffer(-gap+.00001).covers(copper),ext+' copper clearance to all routed board edges',gap)
    for ext in ('GTO','GBO'):
        silk=parse_gerber(directory/f'{name}.{ext}')['geometry']
        check(silk.is_empty or actual.buffer(.00001).covers(silk),ext+' silk does not cross notch or routed window')
    for kind in ('PTH','NPTH'):
        for hole in parse_drill(directory/f'{name}-{kind}.drl'):
            check(actual.buffer(.00001).covers(drill_shape(hole)),kind+' drill remains in actual notched board material',hole)
    result['geometry']['profile']=dict(area_mm2=actual.area,cutouts=len(polygons)-1,difference_mm2=actual.symmetric_difference(reference).area)


def verify(data,routing,directory,native_pcb,name=STEM):
    directory=Path(directory);native_pcb=Path(native_pcb)
    result=verify_core(data,routing,directory,name)
    verify_profile(data,directory,name,result)
    def check(ok,label,detail=None):
        result['checks']+=1
        if not ok:result['errors'].append(dict(check=label,detail=detail))
    native,evidence=read_overlay_artwork(native_pcb)
    try:validate_text_declarations(data,evidence)
    except ValueError as exc:check(False,'Native lettering matches intended R5 text objects',str(exc))
    else:check(True,'Native lettering matches intended R5 text objects')
    for ext,expected in native.items():
        actual=parse_gerber(directory/f'{name}.{ext}')['geometry'];tol=.000004
        same=(expected.is_empty and actual.is_empty) or (expected.buffer(tol).covers(actual) and actual.buffer(tol).covers(expected))
        check(same,ext+' equals saved native TrueType/logo/overlay geometry',expected.symmetric_difference(actual).area)
        result['geometry'][ext]=dict(area_mm2=actual.area,native_area_mm2=expected.area,difference_mm2=expected.symmetric_difference(actual).area)
    manifest=json.loads((directory/'manufacturing-manifest.json').read_text('utf8'))
    check(manifest.get('native_silkscreen',{}).get('source_sha256')==evidence['source_sha256'],'Native PCB hash matches exported lettering')
    proof=json.loads((directory/'native-typography-readback.json').read_text('utf8'))
    check(proof==json.loads(json.dumps(evidence)),'Saved typography evidence equals fresh native readback')
    for source in manifest['sources']:
        path=Path(source['path'])
        check(path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest()==source['sha256'],'Manufacturing source hash remains current',str(path))
    result['native_pcb_sha256']=evidence['source_sha256']
    result['scope']+=' R5 additionally checks actual saved native font outlines, all supported overlay geometry, explicit text declarations and source hashes. No font substitution.'
    result['passed']=not result['errors']
    return result


def self_test():
    """Exercise genuine saved TTF, mirrored/rotated text and stale/moved faults."""
    from copy import deepcopy
    import tempfile
    from export_jlcpcb_r5 import export
    pcb=ROOT/'hardware/altium-r5/typography/R5-Beschriftungsprobe.PcbDoc'
    _,evidence=read_overlay_artwork(pcb)
    texts=[{k:t[k] for k in ('text','x','y','height','rotation','layer','font_name','mirror')} for t in evidence['texts']]
    fixture=dict(ref='J1',value='SYNTHETIC TEST ONLY',footprint='REGRESSION',pins=[dict(number='1',net='TEST')],
                 pcb=dict(x=60,y=40,rotation=0),assembly=dict(populate=False,note='Synthetic regression fixture'),
                 pcb_footprint=dict(pads=[dict(number='1',x=0,y=0,sx=2,sy=2,drill=.8,shape='ROUND')],body=[2,2],height=1,note='Synthetic fixture'))
    data=dict(board=dict(width_mm=65,height_mm=45,corner_radius_mm=2,holes_mm=[],native_texts=texts),components=[fixture],routing_constraints=dict(edge_clearance=.3))
    data['board']['native_logos']=[dict(x=35,y=19,width=7,layer='TOP')]
    data['board']['outline_points_mm']=[[0,0],[65,0],[65,15],[55,15],[55,25],[65,25],[65,45],[0,45],[0,0]]
    data['board']['cutouts_mm']=[dict(name='Synthetic routed window',outline_points_mm=[[45,35],[50,35],[50,39],[45,39],[45,35]])]
    route=dict(tracks=[],vias=[],regions=[])
    with tempfile.TemporaryDirectory(prefix='r5-native-text-format-',dir=ROOT/'tmp') as folder:
        export(data,route,folder,pcb,'Coupon')
        result=verify(data,route,folder,pcb,'Coupon')
        if not result['passed']:raise AssertionError(result['errors'])
        changed=deepcopy(data);changed['board']['native_texts'][0]['x']+=.1
        result_bad=verify(changed,route,folder,pcb,'Coupon')
        if result_bad['passed']:raise AssertionError('Moved text declaration was accepted')
        changed=deepcopy(data);changed['board']['native_logos'][0]['x']+=.5
        if verify(changed,route,folder,pcb,'Coupon')['passed']:raise AssertionError('Misplaced declared logo was accepted')
        path=Path(folder)/'Coupon.GTO';text=path.read_text('ascii')
        path.write_text(text.replace('D01*','D02*',1),encoding='ascii')
        # A deleted contour edge either fails strict region parsing or exact
        # geometry/ZIP/hash comparison; both are deliberate fail-closed results.
        try:mutated=verify(data,route,folder,pcb,'Coupon');rejected=not mutated['passed']
        except ValueError:rejected=True
        if not rejected:raise AssertionError('Modified manufacturing text was accepted')
    return dict(passed=True,positive_checks=result['checks'],native_texts=len(texts),profile='Edge notch and separate internal routed window',negative_controls=['Moved text declaration','Misplaced declared logo','Changed Gerber contour/ZIP/hash'])


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--self-test',action='store_true')
    for key in ('design','routing','pcb','manufacturing','out'):p.add_argument('--'+key,type=Path)
    p.add_argument('--name',default=STEM);a=p.parse_args()
    if a.self_test:result=self_test()
    else:
        if not all((a.design,a.routing,a.pcb,a.manufacturing)):p.error('--design, --routing, --pcb and --manufacturing are required')
        try:result=verify(json.loads(a.design.read_text('utf8')),json.loads(a.routing.read_text('utf8')),a.manufacturing,a.pcb,a.name)
        except Exception as exc:result=dict(passed=False,errors=[str(exc)])
    if a.out:a.out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
    print(json.dumps(result,indent=2));raise SystemExit(0 if result['passed'] else 1)


if __name__=='__main__':main()
