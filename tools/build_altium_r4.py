"""Build the R4 manufacturing candidate; previous revisions stay untouched."""
from __future__ import annotations
import argparse
import copy
import json
from pathlib import Path
from build_altium_project import uid
from altium_symbols import pin,rectangle,poly,circle,diode_graphics,label
from altium_pcb import footprint
from altium_libraries import component_parameters

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'hardware/altium-r4'
STEM='Orion-Bridge-R4'


def passive_fp(size='0603',height=.8):
    specs={'0603':(1.6,.8,1.55,.9,.95),'0805':(2,1.25,1.9,1.1,1.45),
           '1206':(3.2,1.6,3,1.3,1.8),'1210':(3.2,2.5,3,1.5,2.8)}
    w,d,pitch,sx,sy=specs[size]
    return dict(body=[w,d],height=height,pads=[dict(number=str(i+1),x=x,y=0,sx=sx,sy=sy)
                     for i,x in enumerate([-pitch/2,pitch/2])],
                note=f'IPC-style {size} solder lands; selected MPN dimensions reviewed separately.',provisional=False)


def part(ref,value,nets,fp=None,**kwargs):
    c=dict(ref=ref,value=value,footprint=ref+'_FOOTPRINT',
           pins=[dict(number=str(i+1),name=str(i+1),net=n,type=4) for i,n in enumerate(nets)])
    if fp:c['pcb_footprint']=fp
    c.update(kwargs)
    return c


def block_symbol(c,left,right,bottom=(),width=70,step=30):
    half=max(40,((max(len(left),len(right))-1)*step+20)//20*10)
    ps=[]
    for side,nums in [(-1,left),(1,right)]:
        for i,n in enumerate(nums):
            ps.append(dict(number=str(n),x=side*width,y=(len(nums)-1)*step//2-i*step,
                           orientation=2 if side<0 else 0,show_name=True))
    for i,n in enumerate(bottom):
        ps.append(dict(number=str(n),x=(i-(len(bottom)-1)/2)*40,y=-half,orientation=3,show_name=True))
    c['schematic_symbol']=dict(kind='functional_ic',pins=ps,graphics=[rectangle(-width,-half,width,half)],
                               bbox=[-width-20,-half-20,width+20,half],designator_pos=[-width,half+30],value_pos=[-width,half+15])
    c['schematic_label_offset']=[-width,half+35]
    return c


def diode_symbol(c):
    c['schematic_symbol']=dict(kind='schottky',pins=[dict(number='2',x=-20,y=0,orientation=2),dict(number='1',x=20,y=0,orientation=0)],
        graphics=diode_graphics(cathode=(10,0),anode=(-10,0),style='schottky')+[poly([(-20,0),(-10,0)]),poly([(10,0),(20,0)])],
        bbox=[-40,-10,40,10])


def model_box(name,w,d,h,color=(38,42,48),x=0,y=0,z=.1):
    return dict(name=name,outline=[[x-w/2,y-d/2],[x+w/2,y-d/2],[x+w/2,y+d/2],[x-w/2,y+d/2]],z0=z,z1=h,rgb=list(color))


def make_design():
    old=json.loads((ROOT/'hardware/altium-r3/orion-r3-design.json').read_text('utf8'))
    keep={'J1','TP1','F1','D3','L1','U1','C4','C5','R2','R3','R4'}
    components=[copy.deepcopy(c) for c in old['components'] if c['ref'] in keep]
    power=json.loads((OUT/'power-components.json').read_text('utf8'))
    components+=power['components']
    sourcing=json.loads((OUT/'jlcpcb-recommendations.json').read_text('utf8'))
    m=copy.deepcopy(sourcing['components']['MCU1']);m['ref']='MCU1'
    spec=m['pcb_footprint'];pads=[]
    for i in range(9):
        y=spec['first_pad_y_mm']-i*spec['pitch_y_mm']
        for n,x in [(i+1,spec['left_pad_x_mm']),(18-i,spec['right_pad_x_mm'])]:
            pads.append(dict(number=str(n),x=x,y=y,sx=1.5,sy=.9))
    # Espressif explicitly permits the EP unsoldered; edge GND is soldered.
    pads.append(dict(number='19',x=.96,y=-3.3,sx=2.9,sy=2.9,paste=False))
    m['pcb_footprint']=dict(body=[18,20],height=3.35,pads=pads,provisional=False,
        note='Espressif WROOM-02 v1.7 Fig11-1. EP19 ground copper with NO paste; optional EP left unsoldered per manufacturer.')
    netmap={'1':'3V3_LOGIC','2':'ESP_EN','5':'GPIO6','6':'GPIO7','7':'ESP_GPIO8','8':'ESP_BOOT',
            '9':'GND_LOGIC','13':'USB_DM_MCU','14':'USB_DP_MCU','16':'ESP_GPIO2','19':'GND_LOGIC'}
    m['pins']=[dict(number=n,name=name,net=netmap.get(n),type=7 if n in ['1','9','19'] else 0 if n in ['2','6'] else 2 if n=='5' else 1)
              for n,name in m.pop('pin_names').items()]
    block_symbol(m,['1','2','5','6','7','8','16'],['18','17','15','14','13','12','11','10','4','3'],['9','19'],width=110,step=40)
    m['bodies_3d']=[model_box('Espressif module PCB',18,20,1.0,(25,78,60)),
                    model_box('RF shield',17.5,13.5,3.35,(183,187,190),y=-3.1,z=1.0)]
    m['allow_body_overhang']=True
    components.append(m)
    for ref,value,nets,size in [
        ('R5','10k',['3V3_LOGIC','ESP_EN'],'0603'),('R6','10k',['3V3_LOGIC','ESP_GPIO2'],'0603'),
        ('R7','10k',['3V3_LOGIC','ESP_GPIO8'],'0603'),('R8','10k',['3V3_LOGIC','ESP_BOOT'],'0603'),
        ('R9','5.1k',['USB_CC1','GND_LOGIC'],'0603'),('R10','5.1k',['USB_CC2','GND_LOGIC'],'0603'),
        ('R11','22R',['USB_DM','USB_DM_MCU'],'0603'),('R12','22R',['USB_DP','USB_DP_MCU'],'0603'),
        ('C10','1uF 25V X7R',['ESP_EN','GND_LOGIC'],'0603'),('C11','10uF 16V X5R',['3V3_LOGIC','GND_LOGIC'],'0805'),
        ('C12','100nF 25V X7R',['3V3_LOGIC','GND_LOGIC'],'0603')]:
        components.append(part(ref,value,nets,passive_fp(size),footprint=('R' if ref.startswith('R') else 'C')+size))
    logic_path=OUT/'logic-sourcing-overrides.json'
    logic=json.loads(logic_path.read_text('utf8')).get('components',{}) if logic_path.exists() else {}
    for ref in ['J2','D6','SW1','SW2']:
        if ref not in logic:continue
        c=copy.deepcopy(logic[ref]);c.update(ref=ref,value=c['mpn'])
        if ref=='J2':
            nets={'GND':'GND_LOGIC','SHIELD':'GND_LOGIC','VBUS':'USB_VBUS','D-':'USB_DM_IN','D+':'USB_DP_IN',
                  'CC1':'USB_CC1','CC2':'USB_CC2'}
        elif ref=='D6':nets={'IO1':'USB_DM','IO2':'USB_DP','GND':'GND_LOGIC','VBUS':'USB_VBUS'}
        else:nets={'A':'ESP_BOOT' if ref=='SW1' else 'ESP_EN','B':'GND_LOGIC'}
        c['pins']=[dict(number=n,name=name,net=nets.get(name),type=4) for n,name in c['pin_names'].items()]
        if ref=='D6':
            for p in c['pins']:
                if p['number'] in ('1','3'):p['net']+='_'+'IN'
        if ref=='J2':
            block_symbol(c,[],list(c['pin_names']),width=70,step=40)
            c['allow_body_overhang']=True
        elif ref=='D6':
            block_symbol(c,['1','3'],['6','4'],['2','5'],step=40)
            # Manufacturer flow-through channels: these are internal connections,
            # not PCB shorting tracks between input and output pad pairs.
            c['schematic_symbol']['graphics'] += [poly([(-70,20),(70,20)]),poly([(-70,-20),(70,-20)])]
            for p in c['schematic_symbol']['pins']:
                if p['number'] in ('1','3','4','6'):p['show_name']=False
            c['schematic_symbol']['graphics'] += [label(-12,25,'I/O1'),label(-12,-15,'I/O2')]
            c['internal_connections']=[['1','6'],['3','4']]
        else:
            c['schematic_symbol']=dict(kind='normally_open_pushbutton',
                pins=[dict(number='1',x=-20,y=0,orientation=2),dict(number='2',x=20,y=0,orientation=0)],
                graphics=[poly([(-20,0),(-10,0)]),poly([(10,0),(20,0)]),circle(-10,0,2),circle(10,0,2),
                          poly([(-14,9),(14,9)]),poly([(0,9),(0,18)]),poly([(-8,18),(8,18)])],bbox=[-40,-3,40,20])
        components.append(c)
    byref={c['ref']:c for c in components}
    for ref,update in sourcing.get('components',{}).items():
        if ref in byref and ref!='MCU1':byref[ref].update(copy.deepcopy(update))
    for ref,update in logic.items():
        if ref in byref:byref[ref].update(copy.deepcopy(update))
    # Supplemental exact MPN/passive/USB overrides from sourcing review.
    overrides_path=OUT/'sourcing-overrides.json'
    if overrides_path.exists():
        overrides=json.loads(overrides_path.read_text('utf8'))
        for ref,update in overrides.get('components',{}).items():
            if ref in byref:byref[ref].update(copy.deepcopy(update))
    for c in components:
        ref=c['ref']
        if ref in ('C4','C5','R2','R3','R4'):
            c['pcb_footprint']=passive_fp('0603');c['footprint']=('C' if ref.startswith('C') else 'R')+'0603'
        if not c.get('pcb_footprint'):
            fpname=c.get('footprint','')
            size=next((s for s in ['1210','1206','0805','0603'] if s in fpname),None)
            if size:c['pcb_footprint']=passive_fp(size,1.5 if size in ['1210','1206'] else .8)
        if not c.get('pcb_footprint'):
            from dataclasses import asdict
            fp=footprint(c)
            c['pcb_footprint']=dict(pads=[asdict(p) for p in fp.pads],body=list(fp.body),height=fp.height,note=fp.note,provisional=fp.provisional)
        c['pcb_footprint'].setdefault('note',c['pcb_footprint'].get('source_note','Reviewed manufacturer land pattern'))
        c['pcb_footprint'].setdefault('provisional',False)
        if ref in ('J1','TP1'):c['pcb_footprint']['provisional']=False
        if ref in ('U3','U4'):block_symbol(c,['3','2'],['6','5','1'],['4'],step=40)
        if ref=='U2':block_symbol(c,['1','2'],['6','4'],step=40)
        if ref in ('D2','D4','D5'):diode_symbol(c)
        if ref=='L3':
            from altium_symbols import symbol_for
            clone=dict(c,ref='L2');sym=symbol_for(clone)
            c['schematic_symbol']=dict(kind=sym['kind'],pins=[{k:v for k,v in p.items() if k in ['number','x','y','orientation','length','show_name','show_number','name']} for p in sym['pins']],
                graphics=sym['graphics'],bbox=list(sym['bbox']))
        c['uid']=uid('R4-'+ref);c['sheet']=STEM
        c['source_schlib']='Orion-Bridge.SchLib';c['source_pcblib']='Orion-Bridge.PcbLib'
        c['libref']='R4_'+ref+'_'+c['value'].split()[0].replace('/','_').replace('-','_')
        c.setdefault('description',c['value'])
        c.setdefault('assembly',dict(populate=not ref.startswith(('TP','J1')),lcsc_confirmed=False))
        c['pcb']=dict(x=0,y=0,rotation=0,status='R4 reviewed package; see source and assembly audit')
        c['parameters']=component_parameters(c)
        c['parameters'].update({'Supplier 1':'LCSC' if c['assembly'].get('lcsc_confirmed') else '',
                                'Supplier Part Number 1':c['assembly'].get('lcsc','')})
        if ref=='MCU1':continue
        if c.get('pcb_footprint'):
            w,h=c['pcb_footprint']['body'];z=c['pcb_footprint']['height']
            c.setdefault('bodies_3d',[model_box('package',w,h,max(z,.11))])
    model_path=OUT/'model-overrides.json'
    if model_path.exists():
        for ref,update in json.loads(model_path.read_text('utf8')).get('components',{}).items():
            if ref in byref:byref[ref].update(copy.deepcopy(update))
    data=dict(revision='R4 compact PCBA',board=dict(width_mm=46,height_mm=32,corner_radius_mm=2,
         holes_mm=[[3,3],[3,29]],hole_diameter_mm=2.2,thickness_mm=1.6,copper_um=35,
         origin='lower left, millimetres; +Y up'),components=components)
    placement_path=OUT/'placement.json'
    if placement_path.exists():
        for ref,p in json.loads(placement_path.read_text('utf8')).items():byref[ref]['pcb'].update(x=p[0],y=p[1],rotation=p[2])
    data['routing_constraints']=dict(grid=.1,clearance=.15,edge_clearance=.3,signal_width=.2,power_width=.5,
        via_diameter=.6,via_drill=.3,ground_fill=True,thermal_vias=False,ground_clearance=.2,
        width_by_net={'GND_BUS':.5,'GND_LOGIC':.5,'3V3_LOGIC':.5,'5V_SYS':.5,'5V_BUS':.5,
                      'SW_BUS':.5,'SW_LOGIC':.5,'USB_DM':.2,'USB_DP':.2},
        keepouts=[dict(name='Isolation barrier',x1=17.9,y1=0,x2=21.1,y2=32,layers=['TOP','BOTTOM'])])
    data['manufacturing']=dict(mask_expansion_mm=.05,paste_expansion_mm=0)
    data['silkscreen']=[]
    layout_path=OUT/'layout-constraints.json'
    if layout_path.exists():
        layout=json.loads(layout_path.read_text('utf8'))
        data['board'].update(layout.get('board',{}))
        data['routing_constraints'].update(layout.get('routing_constraints',{}))
        data['silkscreen']=layout.get('silkscreen',[])
        data['board']['silkscreen']=data['silkscreen']
        for ref,pads in layout.get('pad_overrides',{}).items():
            for pad in byref[ref]['pcb_footprint']['pads']:
                pad.update(pads.get(str(pad['number']),{}))
    from r4_schematic_plan import apply_plan
    apply_plan(data)
    from altium_r4_documents import design_rules
    data['design_rules']=design_rules(data)
    return data


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--schematics',action='store_true')
    parser.add_argument('--artifacts',action='store_true')
    parser.add_argument('--routing',type=Path)
    args=parser.parse_args()
    OUT.mkdir(exist_ok=True,parents=True)
    data=make_design();path=OUT/'orion-r4-design.json'
    if args.schematics or args.artifacts:
        from altium_libraries import build_libraries
        from altium_3d import add_library_3d,write_model_manifest
        from altium_r4_documents import schematic,write_project
        from r4_schematic_plan import sheet_data
        build_libraries(data,OUT)
        add_library_3d(OUT/'Orion-Bridge.PcbLib',data)
        write_model_manifest(data,OUT/'models')
        for spec in data['schematics']:schematic(sheet_data(data,spec),OUT/(spec['stem']+'.SchDoc'))
        write_project(data,OUT)
        (OUT/'Orion-Bridge.LibPkg').write_bytes((ROOT/'hardware/altium-r2/Orion-Bridge.LibPkg').read_bytes())
    if args.artifacts:
        if not args.routing:raise ValueError('--artifacts needs separately verified --routing')
        from altium_r4_documents import build_pcb
        from route_altium_r3 import verify_routing
        routing=json.loads(args.routing.read_text('utf8'))
        check=verify_routing(data,routing,data['routing_constraints'])
        if not check['passed']:raise ValueError(json.dumps(check['errors'],indent=2))
        print(json.dumps(build_pcb(data,OUT/(STEM+'.PcbDoc'),routing),indent=2))
    path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf8')
    print(path)

if __name__=='__main__':main()
