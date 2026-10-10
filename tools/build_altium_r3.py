"""Compact, routed Orion carrier; R2 remains a read-only source revision."""
from __future__ import annotations
import argparse
import copy
import json
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'hardware/altium-r3'
STEM='Orion-Bridge-R3'

# All component positions are in mm, viewed from above, origin bottom left.
PLACEMENT={
 'J1':(2.5,24,0), 'TP1':(2.5,33.2,0), 'F1':(6.7,25.5,0),
 'Q1':(10,19,0), 'Z1':(5.8,12,90), 'R1':(3.4,12.5,90),
 'D1':(11.5,3.6,0), 'C1':(17.7,19.5,0),
 'U3':(10.5,31,180), 'C2':(16.6,34.4,0), 'C3':(20.8,32.8,90),
 'C8':(8.4,8.25,90), 'L2':(12.8,8.25,0), 'C9':(17.6,9.75,90),
 'U2':(28,11.05,0), 'C6':(33.5,3.3,0), 'C7':(43.1,11.2,0),
 'D2':(40.8,4.5,180), 'JP1':(52.1,9.2,90),
 'D3':(6,22.5,0), 'L1':(17.2,27,0), 'U1':(28,27,180),
 'C4':(24.5,31.05,0), 'C5':(39.1,25.1,90), 'R2':(39.55,22.3,0),
 'R3':(47.8,16.8394,180), 'R4':(47.8,19.3794,0), 'MCU1':(44.2,24,180),
}

def make_design():
    data=json.loads((ROOT/'hardware/altium-r2/orion-r2-design.json').read_text(encoding='utf8'))
    data['revision']='R3 compact routed carrier'
    data['board'].update(width_mm=54,height_mm=36,holes_mm=[[3,3],[51,3]],
                         hole_diameter_mm=2.2,thickness_mm=1.6,copper_um=35)
    data['pcb_title']='ORION BRIDGE R3'
    data['pcb_review_note']='Compact routed engineering prototype. Verify thermal behavior and actual module before production.'
    data['notes']=[
      'Compact routed engineering prototype; electrical/thermal qualification and final component release remain pending.',
      'GND_BUS and GND_LOGIC stay separated by at least 3.8 mm of copper-free carrier area.',
      'U2 needs >=9V at its input after protection/filter losses; start-up at exactly 9V NET-S is not guaranteed.',
      'Open JP1 BEFORE connecting USB; close JP1 only with USB disconnected.',
      'Direct-soldered module headers; module underside 3.1 mm above carrier. No carrier copper below antenna.',
      'Mechanical models are local envelope approximations, not manufacturer STEP models.',
    ]
    review_path=OUT/'parts-review.json'
    review=json.loads(review_path.read_text(encoding='utf8')) if review_path.exists() else {}
    overrides=review.get('components',review.get('overrides',{}))
    if isinstance(overrides,list): overrides={c['ref']:c for c in overrides}
    from altium_libraries import component_parameters
    for c in data['components']:
        x,y,a=PLACEMENT[c['ref']]
        c['pcb'].update(x=x,y=y,rotation=a)
        c['sheet']=STEM
        if c['ref'] in overrides:
            update=copy.deepcopy(overrides[c['ref']])
            if 'pcb' in update:
                c['pcb'].update(update.pop('pcb'))
            c.update(update)
        c['parameters']={**component_parameters(c),**({'Role':c['role']} if c.get('role') else {})}
    data['routing_constraints']={
      'grid':.15,'clearance':.2,'edge_clearance':.3,'signal_width':.25,'power_width':.5,
      'via_diameter':.6,'via_drill':.3,
      'ground_fill':True,'thermal_vias':True,
      'width_by_net':{'GND_BUS':.6,'GND_LOGIC':.6,'5V_BUS':.4,'3V3_LOGIC':.3},
      'keepouts':[
        {'name':'Isolation barrier','x1':26.1,'y1':0,'x2':29.9,'y2':36,'layers':['TOP','BOTTOM']},
        {'name':'SuperMini antenna','x1':34,'y1':33.1,'x2':54,'y2':36,'layers':['TOP','BOTTOM']},
      ],
    }
    return data

def build_artifacts(data,routing):
    from altium_libraries import build_libraries
    from altium_3d import add_library_3d,write_model_manifest
    from altium_routed_pcb import build_routed_pcb
    import build_altium_r2 as sch
    from build_altium_project import uid
    libs=build_libraries(data,OUT)
    add_library_3d(OUT/'Orion-Bridge.PcbLib',data)
    write_model_manifest(data,OUT/'models')
    sch.STEM=STEM
    schpath=OUT/(STEM+'.SchDoc')
    sch.schematic(data,schpath)
    source=schpath.read_text('ascii').replace('R2 - lokale Bauteilbibliotheken','R3 - kompakte Leiterplatte / lokale Bauteilbibliotheken')
    source=source.replace('80 x 60 mm','54 x 36 mm').replace('und Routing vor Fertigung pruefen','vor Fertigung pruefen')
    schpath.write_bytes(source.replace('\n','\r\n').encode('ascii'))
    pcb=build_routed_pcb(data,OUT/(STEM+'.PcbDoc'),routing)
    project=(ROOT/'hardware/altium-r2/Orion-Bridge-R2.PrjPcb').read_text('ascii')
    project=project.replace('Orion-Bridge-R2',STEM).replace(uid('Orion-Bridge-R2Sheet'),uid(STEM+'Sheet'))
    (OUT/(STEM+'.PrjPcb')).write_bytes(project.replace('\n','\r\n').encode('ascii'))
    (OUT/'Orion-Bridge.LibPkg').write_bytes((ROOT/'hardware/altium-r2/Orion-Bridge.LibPkg').read_bytes())
    (OUT/'orion-r3-design.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf8')
    return {'libraries':libs,'pcb':pcb}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--artifacts',action='store_true',help='Create routed PCB, schematic and native libraries')
    parser.add_argument('--routing',type=Path,help='Reuse a route generated from the same placement')
    args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True)
    data=make_design()
    path=OUT/'orion-r3-design.json'
    path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf8')
    if args.artifacts:
        from route_altium_r3 import route,verify_routing
        routing=json.loads(args.routing.read_text()) if args.routing else route(data,data['routing_constraints'])
        check=verify_routing(data,routing,data['routing_constraints'])
        if not check['passed']:raise ValueError(json.dumps(check['errors'],indent=2))
        routing['verification']=check
        (OUT/'routing.json').write_text(json.dumps(routing,indent=2)+'\n',encoding='utf8')
        print(json.dumps(build_artifacts(data,routing),indent=2))
    else:print(path)

if __name__=='__main__':main()
