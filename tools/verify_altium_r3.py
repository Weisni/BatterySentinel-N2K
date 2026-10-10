"""Read native R3 artifacts back and check connectivity, libraries and copper.

This does not run Altium's own DRC or qualify a manufactured prototype.
"""
import json,sys,math
from pathlib import Path
from collections import Counter
import verify_altium_r2 as reference
from verify_altium_project import Audit,records,mm,unique
from route_altium_r3 import verify_routing
from altium_libraries import read_cfb_streams,decode_pcb_library

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'hardware/altium-r3'
STEM='Orion-Bridge-R3'

def audit_native(root=OUT):
    a=Audit();data=json.loads((root/'orion-r3-design.json').read_text())
    model={c['ref']:c for c in data['components']}
    reference.STEM=STEM
    reference.check_schematic(a,root/(STEM+'.SchDoc'),model)
    reference.check_project(a,root/(STEM+'.PrjPcb'))
    research=json.loads((ROOT/'hardware/altium-r2/supermini-nologo.json').read_text())
    pcb_path=root/(STEM+'.PcbDoc')
    # Keep the generated native ASCII source when the deliverable has been
    # saved by Altium as Binary 6.0 after its metadata ECO. The final binary
    # has its own readback and native DRC reports.
    if pcb_path.read_bytes().startswith(bytes.fromhex('d0cf11e0a1b11ae1')):
        pcb_path=root/'source'/(STEM+'.PcbDoc')
    reference.check_local_links(a,root,model,pcb_path=pcb_path)
    counts=reference.check_libraries(a,root,model,research,pcb_path=pcb_path)
    rows=records(pcb_path)
    # A legacy Rule record alone is silently replaced by Altium defaults.
    rules={r['NAME']:r for r in rows if r.get('RECORD')=='DXPRule'}
    required={'Clearance','Width','ShortCircuit','UnRoutedNet','TentedVias',
              'PadSolderMask','MinimumSolderMaskSliver','RoutingVias','ComponentClearance'}
    a.check(required<=set(rules),'Missing modern Altium design rules')
    if required<=set(rules):
        a.check(abs(mm(rules['Clearance']['GAP'])-.2)<1e-5,'Wrong native copper clearance')
        a.check(abs(mm(rules['Width']['MINLIMIT'])-.25)<1e-5,'Wrong native minimum width')
        tent=rules['TentedVias']
        a.check(tent['SCOPE1EXPRESSION']=='IsVia' and tent['PRIORITY']=='1','Via-mask rule scope/priority')
        a.check(mm(tent['EXPANSION'])<=-.29999,'Via mask is not fully closed')
        a.check(rules['PadSolderMask']['PRIORITY']=='2','Pad-mask rule overrides via tenting')
        a.check(abs(mm(rules['ComponentClearance']['GAP'])-.25)<1e-5,'Wrong component clearance')
    nets={r['ID']:r['NAME'] for r in rows if r.get('RECORD')=='Net'}
    components={r['ID']:r for r in rows if r.get('RECORD')=='Component'}
    unique(a,[c['SOURCEUNIQUEID'] for c in components.values()],'Component UID')
    a.check(set(c['SOURCEDESIGNATOR'] for c in components.values())==set(model),'PCB components differ')
    for c in components.values():
        part=model[c['SOURCEDESIGNATOR']]
        a.check(c['SOURCEUNIQUEID'].lstrip('\\')==part['uid'],part['ref']+': schematic/PCB UID mismatch')
        a.check(c['SOURCEHIERARCHICALPATH']==STEM,part['ref']+': wrong source sheet')
    comments={r['COMPONENT']:r['TEXT'] for r in rows
              if r.get('RECORD')=='Text' and r.get('COMMENT')=='TRUE'}
    for index,c in components.items():
        a.check(comments.get(index)==model[c['SOURCEDESIGNATOR']]['value'],
                c['SOURCEDESIGNATOR']+': PCB comment/value missing')
    for r in rows:
        if r.get('RECORD')=='Pad' and 'COMPONENT' in r:
            part=model[components[r['COMPONENT']]['SOURCEDESIGNATOR']]
            pins={str(p['number']):p for p in part['pins']}
            a.check(nets.get(r.get('NET'))==pins[r['NAME']]['net'],part['ref']+'.'+r['NAME']+': wrong net')
    # Reconstruct the actual exported native copper, not the router's cache.
    route={'tracks':[],'vias':[],'regions':[]}
    body_counts=Counter()
    for r in rows:
        kind=r.get('RECORD');layer=r.get('LAYER')
        if kind=='Track' and layer in ('TOP','BOTTOM'):
            route['tracks'].append(dict(net=nets[r['NET']],layer=layer,
                **{k.lower():mm(r[k]) for k in ('X1','Y1','X2','Y2','WIDTH')}))
        elif kind=='Via':
            a.check(r.get('CSEV')=='2' and mm(r.get('CSE','0mil'))<=-.29999,
                    'Via manual solder-mask cache is missing or incorrect')
            a.check(r.get('TENTINGTOP')==r.get('TENTINGBOTTOM')=='TRUE','Via is not tented on both sides')
            route['vias'].append(dict(net=nets[r['NET']],x=mm(r['X']),y=mm(r['Y']),
                diameter=mm(r['DIAMETER']),drill=mm(r['HOLESIZE'])))
        elif kind=='Region' and layer in ('TOP','BOTTOM'):
            n=int(r['MAINCONTOURVERTEXCOUNT'])
            route['regions'].append(dict(net=nets[r['NET']],layer=layer,holes=[],
                points=[[mm(r[f'VX{i}']),mm(r[f'VY{i}'])] for i in range(n)]))
            a.check(r.get('HOLECOUNT')=='0','Unexpected region holes')
        elif kind=='ComponentBody':
            body_counts[r['COMPONENT']]+=1
            a.check(r.get('BODYPROJECTION')=='0','3D body projects to bottom')
            a.check(mm(r['OVERALLHEIGHT'])>mm(r['STANDOFFHEIGHT']),'3D body height invalid')
            a.check(r.get('MODEL.EMBED')=='FALSE','Unexpected external/embedded 3D payload')
    a.check(set(body_counts)==set(components),'Some PCB components lack 3D bodies')
    pcb_library=decode_pcb_library(read_cfb_streams(root/'Orion-Bridge.PcbLib'))
    for name,prims in pcb_library.items():
        bodies=[p for p in prims if p['kind']=='ComponentBody']
        a.check(bool(bodies),name+': no library 3D model')
        a.check(all(p['properties']['BODYPROJECTION']=='0' for p in bodies),name+': bottom-projected model')
    # Pad center/size have already been independently read against the libraries.
    cfg=data['routing_constraints']
    copper=verify_routing(data,route,cfg)
    a.check(copper['passed'],'Native copper geometric audit failed')
    a.errors.extend(str(e) for e in copper['errors'])
    mechanical=json.loads((root/'mechanical-review.json').read_text())
    a.check(not mechanical.get('errors'),'Mechanical review has findings')
    result={'passed':not a.errors,'checks':a.checks,'errors':a.errors,
        'components':len(model),'nets':len(nets),'library_components':counts[0],
        'library_footprints':counts[1],'tracks':len(route['tracks']),'vias':len(route['vias']),
        'copper_regions':len(route['regions']),'component_bodies':sum(body_counts.values()),
        'copper_verification':copper,'mechanical_review':mechanical,
        'pcb_readback_file':str(pcb_path.relative_to(root)),
        'scope':'Generated native ASCII source readback, library/pin/net/UID links, exact copper and assembly geometry. Final Altium binary readback and DRC are reported separately. Not hardware qualification.'}
    return result

if __name__=='__main__':
    report=audit_native()
    (OUT/'verification.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k not in ('copper_verification','mechanical_review')},indent=2))
    sys.exit(0 if report['passed'] else 1)
