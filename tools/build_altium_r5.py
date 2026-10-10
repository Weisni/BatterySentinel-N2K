"""Build the original-SuperMini R5 carrier with linked local Altium libraries."""
from __future__ import annotations
import argparse
import copy
import json
from pathlib import Path
from build_altium_project import uid
from altium_libraries import component_parameters
from r5_geometry import apply_outline
from r5_schematic_plan import apply_plan,sheet_data
from altium_r5_documents import STEM

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'hardware/altium-r5'


def make_design():
    old=json.loads((ROOT/'hardware/altium-r4/orion-r4-design.json').read_text('utf8'))
    keep={'J1','TP1','D3','L1','U1','C4','C5','R2','R3','R4'}
    components=[copy.deepcopy(c) for c in old['components'] if c['ref'] in keep]
    power=json.loads((OUT/'power-components.json').read_text('utf8'))
    components+=copy.deepcopy(power['components'])
    from r5_supermini import make_component
    components.append(make_component())
    positions={
        'J1':(2.5,16,180),'TP1':(3,27,0),'F1':(5.5,14,90),
        'D3':(5.5,20.5,90),'L1':(9,23.7,90),'U1':(19.5,22.5,180),
        'C4':(14.9,18.7,0),'C5':(24.575,18.2,0),
        'R2':(26.0,30.9,0),'R3':(29,30.9,0),'R4':(32,32.2,0),
        'U3':(11.5,10.3,0),'L2':(7.5,9.2,180),'C20':(15.35,10.5,0),
        'C21':(15.35,13.5,0),'C22':(6.925,4.65,270),'C23':(9.025,4.65,270),
        'C24':(11,12.6,0),'C25':(10.95,7,90),'C26':(16.5,8.5,0),
        'D1':(10.5,18.65,180),'D5':(9.2,14.8,180),'U2':(22.035,4.2,0),
        'U4':(40.25,6.35,0),'L3':(36.25,7.45,180),'C29':(43.8,4.825,0),
        'C30':(44.025,6.25,0),'C31':(39.7,8.6,0),'C32':(34.3,3.9,0),'C33':(34.3,1.7,0),
        'C27':(26.7,10.125,90),'C28':(29.1,9.2,0),
        'R20':(23.6,11.8,0),'R21':(23.6,14.4,0),'SW3':(39,33.5,0),
        'C34':(46.8,7.8,0),
        'MCU1':(40,20,270),
    }
    overrides=OUT/'placement.json'
    if overrides.exists():positions.update(json.loads(overrides.read_text('utf8')))
    for c in components:
        ref=c['ref']
        if ref not in positions:raise ValueError('No R5 placement for '+ref)
        x,y,rotation=positions[ref]
        c['pcb']=dict(x=x,y=y,rotation=rotation,status='R5 placement with enclosure interface')
        c['uid']=uid('R5-'+ref);c['libref']='R5_'+ref+'_'+c['value'].split()[0].replace('/','_').replace('-','_')
        c['source_schlib']='Orion-Bridge.SchLib';c['source_pcblib']='Orion-Bridge.PcbLib'
        c['parameters']=component_parameters(c)
        assy=c.get('assembly',{})
        c['parameters'].update({'Supplier 1':'LCSC' if assy.get('lcsc_confirmed') else '',
                                'Supplier Part Number 1':assy.get('lcsc','')})
    data=dict(revision='Orion-R5',project='BatterySentinel-N2K',components=components,
        board=dict(width_mm=52,height_mm=36,corner_radius_mm=2,thickness_mm=1.6,copper_um=35,
                   holes_mm=[[3,3],[3,33],[49,3],[49,33]],hole_diameter_mm=2.2,
                   mounting_courtyard_diameter_mm=5.6,origin='lower left; millimetres; +Y up'),
        manufacturing=dict(mask_expansion_mm=.05,paste_expansion_mm=0),silkscreen=[])
    apply_outline(data['board'])
    data['board']['native_texts']=[
        dict(text='BatterySentinel-N2K',x=6.5,y=33,height=2.8,rotation=0,layer='TOP'),
        dict(text='Orion-R5',x=6.5,y=29.8,height=2.6,rotation=0,layer='TOP'),
        dict(text='BatterySentinel-N2K',x=45,y=27,height=3.0,rotation=0,layer='BOTTOM'),
        dict(text='Orion-R5',x=43.6,y=22,height=2.6,rotation=0,layer='BOTTOM'),
        dict(text='RUN',x=37.0,y=30.7,height=1.5,rotation=0,layer='TOP'),
        dict(text='SERVICE',x=43.5,y=33.5,height=1.5,rotation=90,layer='BOTTOM'),
    ]
    data['board']['native_logos']=[dict(x=18,y=19,width=7,layer='BOTTOM')]
    data['routing_constraints']=dict(grid=.1,clearance=.15,edge_clearance=.3,signal_width=.2,power_width=.5,
        via_diameter=.6,via_drill=.3,ground_fill=True,thermal_vias=False,ground_clearance=.2,
        hole_clearance=1.7,component_hole_clearance={'SW3':.25},attempts=5,width_by_net={n:.5 for n in ['GND_BUS','GND_LOGIC','5V_ISO','5V_REG','5V_MODULE','5V_BUS','SW_BUS','SW_LOGIC']},
        keepouts=[dict(name='Isolation barrier',x1=17.9,y1=0,x2=21.1,y2=36,layers=['TOP','BOTTOM']),
                  dict(name='SuperMini antenna clearance',x1=26.24,y1=14,x2=34.5,y2=26,layers=['TOP','BOTTOM'])])
    apply_plan(data)
    from altium_r5_documents import design_rules
    data['design_rules']=design_rules(data)
    return data


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--schematics',action='store_true');p.add_argument('--artifacts',action='store_true')
    p.add_argument('--routing',type=Path);args=p.parse_args()
    OUT.mkdir(exist_ok=True,parents=True);data=make_design()
    if args.schematics or args.artifacts:
        from altium_libraries import build_libraries
        from altium_3d import add_library_3d,write_model_manifest
        from altium_r5_documents import schematic,write_project
        build_libraries(data,OUT);add_library_3d(OUT/'Orion-Bridge.PcbLib',data)
        write_model_manifest(data,OUT/'models')
        for s in data['schematics']:schematic(sheet_data(data,s),OUT/(s['stem']+'.SchDoc'))
        write_project(data,OUT)
        (OUT/'Orion-Bridge.LibPkg').write_bytes((ROOT/'hardware/altium-r2/Orion-Bridge.LibPkg').read_bytes())
    if args.artifacts:
        if not args.routing:raise ValueError('--artifacts requires --routing')
        from altium_r5_documents import build_pcb
        from r5_geometry import install_routing_geometry
        from route_altium_r3 import verify_routing
        install_routing_geometry();routing=json.loads(args.routing.read_text('utf8'))
        check=verify_routing(data,routing,data['routing_constraints'])
        if not check['passed']:raise ValueError(json.dumps(check['errors'],indent=2))
        print(json.dumps(build_pcb(data,OUT/(STEM+'.PcbDoc'),routing),indent=2))
    result=OUT/'orion-r5-design.json';result.write_text(json.dumps(data,indent=2)+'\n',encoding='utf8')
    print(result)


if __name__=='__main__':main()
