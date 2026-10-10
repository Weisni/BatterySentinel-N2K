"""Local-library Altium revision. R1/user documents are never overwritten."""
from pathlib import Path
import json
import math
import re

from build_altium_project import design, uid, record
from altium_symbols import symbol_for
from altium_libraries import enrich_components, component_parameters, build_libraries
from altium_pcb import build_pcb

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'hardware'/'altium-r2'
STEM = 'Orion-Bridge-R2'
SCHLIB = 'Orion-Bridge.SchLib'
PCBLIB = 'Orion-Bridge.PcbLib'


def transform(x, y, angle, ox=0, oy=0):
    a = math.radians(angle)
    return (round(ox+x*math.cos(a)-y*math.sin(a),5), round(oy+x*math.sin(a)+y*math.cos(a),5))


class Sheet:
    def __init__(self, data):
        self.rows=[]
        self.parts={c['ref']:c for c in data['components']}
        self.points={}
        self.wires=[]
        self.add(RECORD=31, FontIdCount=3, Size1=9, FontName1='Arial', Size2=14,
                 FontName2='Arial', Bold2='T', Size3=8, FontName3='Arial', SheetStyle=2,
                 BorderOn='T', TitleBlockOn='F', HotSpotGridOn='T', HotSpotGridSize=5,
                 SnapGridOn='T', SnapGridSize=5, VisibleGridOn='F', VisibleGridSize=10,
                 CustomX=2230, CustomY=1570, SystemFont=1, Display_Unit=0,
                 AreaColor=16777215, UseMBCS='T', IsBOC='T')

    def add(self, **fields):
        index=len(self.rows)
        fields={k:(int(v) if isinstance(v,float) and v.is_integer() else v) for k,v in fields.items()}
        self.rows.append(fields)
        return index

    def text(self,x,y,text,bold=False,color=0):
        self.add(RECORD=4,OwnerPartId=-1,**{'Location.X':x,'Location.Y':y},
                 FontID=2 if bold else 1,Text=text,Color=color)

    def line(self,a,b,color=12040119):
        self.add(RECORD=13,OwnerPartId=-1,**{'Location.X':a[0],'Location.Y':a[1],
                 'Corner.X':b[0],'Corner.Y':b[1]},Color=color,LineWidth=1)

    def section(self,x,y,title,width):
        self.text(x,y,title,True)
        self.line((x,y-15),(x+width,y-15))

    def wire(self,*pts):
        pts=[(round(x,5),round(y,5)) for x,y in pts]
        for a,b in zip(pts,pts[1:]):
            if a==b: continue
            if a[0]!=b[0] and a[1]!=b[1]: raise ValueError(f'Diagonal wire {a} -> {b}')
            self.wires.append((a,b))
            self.add(RECORD=27,OwnerPartId=-1,LineWidth=1,Color=8388608,
                     LocationCount=2,X1=a[0],Y1=a[1],X2=b[0],Y2=b[1])

    def label(self,p,name):
        self.add(RECORD=25,OwnerPartId=-1,**{'Location.X':p[0],'Location.Y':p[1]},
                 Color=128,FontID=3,Text=name)

    def power(self,p,name,ground=False):
        self.add(RECORD=17,OwnerPartId=-1,Style=4 if ground else 2,ShowNetName='T',
                 **{'Location.X':p[0],'Location.Y':p[1]},Orientation=3 if ground else 1,
                 Color=128,Text=name,FontID=3)

    def ground(self,p,name,y):
        self.wire(p,(p[0],y))
        self.power((p[0],y),name,True)

    def nc(self,p):
        self.add(RECORD=22,OwnerPartId=-1,**{'Location.X':p[0],'Location.Y':p[1]},Color=255)

    def place(self,ref,x,y,angle=0):
        c=self.parts[ref]
        symbol=symbol_for(c)
        owner=self.add(RECORD=1,LibReference=c['libref'],DesignItemId=c['libref'],
                       ComponentDescription=c['description'],PartCount=2,DisplayModeCount=1,
                       OwnerPartId=-1,**{'Location.X':x,'Location.Y':y},CurrentPartId=1,
                       SourceLibraryName=SCHLIB,TargetFileName='*',UniqueID=c['uid'],
                       Color=128,AreaColor=16777215,Orientation=angle//90,
                       PartIDLocked='F',AllPinCount=len(c['pins']))
        for original in symbol['graphics']:
            g=dict(original)
            g.update(OwnerIndex=owner,OwnerPartId=1,IsNotAccesible='T')
            pairs=[]
            for key in list(g):
                if key.endswith('.X') and key[:-1]+'Y' in g: pairs.append((key,key[:-1]+'Y'))
                elif re.fullmatch(r'X\d+',key) and 'Y'+key[1:] in g: pairs.append((key,'Y'+key[1:]))
            for kx,ky in pairs: g[kx],g[ky]=transform(float(g[kx]),float(g[ky]),angle,x,y)
            if g.get('RECORD') in (8,10,14):
                if 'Corner.X' in g:
                    g['Location.X'],g['Corner.X']=sorted([g['Location.X'],g['Corner.X']])
                    g['Location.Y'],g['Corner.Y']=sorted([g['Location.Y'],g['Corner.Y']])
            if g.get('RECORD') in (11,12):
                for key in ('StartAngle','EndAngle'):
                    if key in g: g[key]=(float(g[key])+angle)%360
            self.add(**g)
        bynumber={str(p['number']):p for p in c['pins']}
        for pin in symbol['pins']:
            number=str(pin['number']); model=bynumber[number]
            px,py=transform(pin['x'],pin['y'],angle,x,y)
            ori=(pin['orientation']+angle//90)%4
            length=pin['length']
            bits=32+ori+(8 if pin.get('show_name',True) else 0)+(16 if pin.get('show_number',True) else 0)
            self.add(RECORD=2,OwnerIndex=owner,OwnerPartId=1,FormalType=1,Electrical=model['type'],
                     PinConglomerate=bits,PinLength=length,**{'Location.X':px,'Location.Y':py},
                     Name=model['name'],Designator=number,SwapIdPart='1',
                     UniqueID=uid(ref+':'+number),Name_CustomFontID=3,Designator_CustomFontID=3,
                     PinName_PositionConglomerate=16,PinDesignator_PositionConglomerate=16)
            dx,dy=[(1,0),(0,1),(-1,0),(0,-1)][ori]
            self.points[(ref,number)]=(px+dx*length,py+dy*length)
        # Keep text horizontal and outside symbol body after rotation.
        left,bottom,right,top=symbol['bbox']
        bounds=[transform(a,b,angle,x,y) for a,b in [(left,bottom),(left,top),(right,bottom),(right,top)]]
        tx=min(a for a,b in bounds); ty=max(b for a,b in bounds)+22
        if ref.startswith('C') or ref in ('D1','Z1') or angle in (90,270):
            tx=max(a for a,b in bounds)+12; ty=y+10
        if ref=='R4': tx=x-20; ty=y-34
        if ref=='MCU1': tx=1640; ty=535
        if ref=='D3': tx=x+50; ty=y+10
        if c.get('schematic_label_offset'):
            tx=x+c['schematic_label_offset'][0];ty=y+c['schematic_label_offset'][1]
        self.add(RECORD=34,OwnerIndex=owner,OwnerPartId=-1,**{'Location.X':tx,'Location.Y':ty},
                 Color=128,FontID=1,Text=ref,Name='Designator',ReadOnlyState=1)
        self.add(RECORD=41,OwnerIndex=owner,OwnerPartId=-1,**{'Location.X':tx,'Location.Y':ty-17},
                 Color=128,FontID=3,Text=c['value'],Name='Comment')
        # Instance metadata (for example R3/R4's TX/RX role) must travel with
        # the placed component without changing its shared library symbol.
        parameters={**component_parameters(c),**c.get('parameters',{})}
        for name,value in parameters.items():
            self.add(RECORD=41,OwnerIndex=owner,OwnerPartId=-1,IsHidden='T',FontID=1,Text=value,Name=name)
        self.add(RECORD=41,OwnerIndex=owner,OwnerPartId=-1,IsHidden='T',FontID=1,
                 Text=c['pcb']['status'],Name='ReviewStatus')
        models=self.add(RECORD=44,OwnerIndex=owner)
        model=self.add(RECORD=45,OwnerIndex=models,ModelName=c['footprint'],ModelType='PCBLIB',
                       DatafileCount=1,ModelDatafile0=PCBLIB,ModelDatafileEntity0=c['footprint'],
                       ModelDatafileKind0='PCBLib',IsCurrent='T',UniqueID=uid('model'+ref))
        self.add(RECORD=46,OwnerIndex=model)
        self.add(RECORD=48,OwnerIndex=model)
        return self

    def at(self,ref,pin,p,angle=0):
        symbol=symbol_for(self.parts[ref])
        q=next(q for q in symbol['pins'] if str(q['number'])==str(pin))
        dx,dy=[(1,0),(0,1),(-1,0),(0,-1)][q['orientation']]
        hx,hy=transform(q['x']+dx*q['length'],q['y']+dy*q['length'],angle)
        return self.place(ref,p[0]-hx,p[1]-hy,angle)

    def p(self,ref,pin): return self.points[(ref,str(pin))]

    def finish(self,path):
        # Explicit T-junction dots. Plain crossings do not connect nets.
        joints=set()
        for a,b in self.wires:
            for p in (a,b):
                touching=sum(1 for c,d in self.wires if
                    min(c[0],d[0])<=p[0]<=max(c[0],d[0]) and
                    min(c[1],d[1])<=p[1]<=max(c[1],d[1]) and
                    (p[0]-c[0])*(d[1]-c[1])==(p[1]-c[1])*(d[0]-c[0]))
                if touching>=3: joints.add(p)
        for x,y in sorted(joints): self.add(RECORD=29,OwnerPartId=-1,**{'Location.X':x,'Location.Y':y},Color=8388608,Size=1)
        header=record(HEADER='Protel for Windows - Schematic Capture Ascii File Version 5.0',
                      Weight=len(self.rows),MinorVersion=2,UniqueID=uid(STEM+'Sheet'))
        path.write_bytes(('\r\n'.join([header]+[record(**r) for r in self.rows])+'\r\n').encode('ascii'))


def schematic(data,path):
    s=Sheet(data)
    s.text(70,1490,'ORION BRIDGE / NMEA 2000 - BLE',True)
    s.text(70,1460,'R2 - lokale Bauteilbibliotheken / getrennte Versorgung fuer Bus und Logik')
    s.text(1570,1490,'80 x 60 mm / 2 Lagen / 21.09.2026')
    s.line((70,1430),(2140,1430))
    s.section(70,1380,'01  Anschluss',290)
    s.section(420,1380,'02  Schutz und Busversorgung',1720)
    s.place('J1',160,1220)
    for pin in s.parts['J1']['pins']:
        p=s.p('J1',pin['number']); end=(p[0]+90,p[1])
        s.wire(p,end); s.label((p[0]+10,p[1]),pin['net'])
    s.at('TP1','1',(190,1040))
    p=s.p('TP1',1); s.wire(p,(p[0]-60,p[1]));s.label((p[0]-60,p[1]),'SHIELD')
    s.text(80,990,'Micro-C: Pinfolge, keine Frontansicht.')
    s.text(80,965,'Schirm bleibt von GND getrennt.')
    s.at('F1',1,(460,1290))
    s.wire((420,1290),s.p('F1',1));s.label((420,1290),'NET_S')
    s.at('Q1',2,(700,1290))
    s.wire(s.p('F1',2),s.p('Q1',2));s.label((600,1290),'FUSED_IN')
    tab=s.p('Q1',4);s.wire(tab,(660,tab[1]),(660,1290))
    out=s.p('Q1',3)
    s.at('U3',1,(1480,1290))
    s.wire(out,s.p('U3',1));s.label((1100,1290),'BUS_PROT')
    s.wire(s.p('U3',3),(1980,1290));s.power((1980,1290),'5V_BUS')
    s.at('Z1',1,(920,1190))
    s.wire(s.p('Z1',1),(920,1290))
    gate=s.p('Q1',1); za=s.p('Z1',2)
    gy=min(gate[1],za[1])-20
    s.wire(gate,(gate[0],gy),(za[0],gy),za);s.label((gate[0],gy),'GATE')
    s.at('R1',1,(gate[0],gy-40),270)
    s.wire((gate[0],gy),s.p('R1',1));s.ground(s.p('R1',2),'GND_BUS',940)
    for ref,x in [('D1',1070),('C1',1210),('C2',1390),('C3',1880)]:
        s.at(ref,1,(x,1190));s.wire(s.p(ref,1),(x,1290));s.ground(s.p(ref,2),'GND_BUS',1060)
    for pin in (2,4): s.ground(s.p('U3',pin),'GND_BUS',1090 if pin==2 else 1040)

    s.section(70,900,'03  Galvanisch getrennte Logikversorgung',2070)
    rail=790
    s.at('L2',1,(520,rail));s.at('U2',1,(990,rail))
    s.wire((300,rail),s.p('L2',1));s.label((300,rail),'BUS_PROT')
    s.wire(s.p('L2',2),s.p('U2',1));s.label((790,rail),'DCDC_IN')
    for ref,x in [('C8',390),('C9',780)]:
        s.at(ref,1,(x,rail-50));s.wire(s.p(ref,1),(x,rail));s.ground(s.p(ref,2),'GND_BUS',610)
    s.ground(s.p('U2',2),'GND_BUS',610)
    s.nc(s.p('U2',4));s.nc(s.p('U2',5))
    s.text(1010,650,'CTRL offen = EIN')
    yp=s.p('U2',7)[1]
    s.at('D2',2,(1560,yp));s.wire(s.p('U2',7),s.p('D2',2));s.label((1230,yp),'5V_ISO')
    s.ground(s.p('U2',6),'GND_LOGIC',610)
    for ref,x in [('C6',1320),('C7',1450)]:
        s.at(ref,1,(x,yp-50));s.wire(s.p(ref,1),(x,yp));s.ground(s.p(ref,2),'GND_LOGIC',610)
    s.at('JP1',1,(1820,yp));s.wire(s.p('D2',1),s.p('JP1',1));s.label((1680,yp),'5V_AFTER_DIODE')
    s.wire(s.p('JP1',2),(2030,yp));s.power((2030,yp),'5V_MODULE')
    s.text(1660,665,'RUN: JP1 zu, USB abgezogen.')
    s.text(1660,635,'SERVICE: JP1 vor USB oeffnen.')

    s.section(70,555,'04  CAN-Schnittstelle und Controller',1480)
    s.at('L1',1,(600,400));s.at('U1',7,(980,400))
    for pin,net in [(1,'CANH_EXT'),(2,'CANL_EXT')]:
        p=s.p('L1',pin);s.wire((200,p[1]),p);s.label((200,p[1]),net)
    for a,b in [(4,7),(3,6)]:
        p,q=s.p('L1',a),s.p('U1',b)
        s.wire(p,(850,p[1]),(850,q[1]),q);s.label((870,q[1]),'CANH' if b==7 else 'CANL')
    s.at('D3',1,(330,300))
    for dp,lp in [(1,1),(2,2)]:
        p=s.p('D3',dp);s.wire(p,(p[0],s.p('L1',lp)[1]))
    s.ground(s.p('D3',3),'GND_BUS',180)
    for cap,powerpin,gnd,x,net in [('C4',8,'GND_BUS',830,'5V_BUS'),('C5',1,'GND_LOGIC',1230,'3V3_LOGIC')]:
        p=s.p('U1',powerpin)
        y=470
        s.at(cap,1,(x,y));s.wire(p,(p[0],y+20),(x,y+20),s.p(cap,1));s.power((x,y+20),net)
        s.ground(s.p(cap,2),gnd,320 if cap=='C5' else 250)
    s.ground(s.p('U1',5),'GND_BUS',180);s.ground(s.p('U1',4),'GND_LOGIC',150)
    tx,rx=s.p('U1',2),s.p('U1',3)
    s.at('R3',2,(1460,tx[1]),180);s.wire(tx,s.p('R3',2));s.label((1310,tx[1]),'TXD')
    s.at('R4',1,(1460,rx[1]));s.wire(rx,s.p('R4',1));s.label((1320,rx[1]),'RXD')
    s.at('R2',2,(1360,tx[1]),270);s.wire((1360,tx[1]),s.p('R2',2))
    s.wire(s.p('R2',1),(1360,490));s.power((1360,490),'3V3_LOGIC')
    s.at('MCU1','6',(1780,tx[1]))
    for rp,mp,net in [('R3','6','GPIO6'),('R4','7','GPIO7')]:
        a=s.p(rp,1 if rp=='R3' else 2);b=s.p('MCU1',mp)
        s.wire(a,(1650,a[1]),(1650,b[1]),b);s.label((1670,b[1]),net)
    for pin in s.parts['MCU1']['pins']:
        p=s.p('MCU1',pin['number'])
        if pin['net'] is None: s.nc(p)
        elif pin['number'] in ('5V','3V3'):
            s.wire(p,(p[0],540));s.power((p[0],540),pin['net'])
        elif pin['number']=='GND': s.ground(p,'GND_LOGIC',130)

    s.line((70,95),(2140,95))
    s.text(70,65,'Lokale Referenzen: Orion-Bridge.SchLib / Orion-Bridge.PcbLib. Supplier-Daten werden separat gepflegt.')
    s.text(70,40,'Entwicklungsstand: Versorgung ab 9 V, Thermik, Bauteilfreigabe und Routing vor Fertigung pruefen. Keine 120-Ohm-Terminierung auf dem Drop.')
    s.finish(path)
    return s


def make_design():
    data=design()
    data['revision']='R2 local-library schematic'
    data['pcb_title']='ORION BRIDGE R2 - PLACEMENT DRAFT'
    data['pcb_review_note']='Nologo 16-pin carrier. Verify module, generic parts and supply before routing.'
    data['notes']=[
        'Unrouted engineering draft. No fabrication release or completed electrical/thermal qualification.',
        'GND_BUS and GND_LOGIC are galvanically separated; only U1/U2 bridge the domains.',
        'U2 requires >=9V after protection/filter losses; operation at 9V NET-S is not guaranteed.',
        'RUN: JP1 closed, USB disconnected. SERVICE: open JP1 BEFORE connecting USB.',
        'No 120-ohm termination on this drop. MCU1 uses the Nologo 16-pin geometry; verify the actual module and sockets.',
        'R3/R4 are TX/RX series resistors. TP1 is the isolated shield pad.'
    ]
    module=json.loads((OUT/'supermini-nologo.json').read_text('utf-8'))
    for c in data['components']:
        c['sheet']=STEM
        c['source_schlib']=SCHLIB
        c['source_pcblib']=PCBLIB
        if c['ref']=='MCU1':
            c['footprint']=module['footprint_name']
            c['value']='ESP32-C3 SuperMini'
            c['manufacturer']=module['manufacturer']
            c['mpn']=module['manufacturer_part_number']
            c['description']='Nologo ESP32-C3 SuperMini module, two 1x8 carrier headers, GPIO6 TX / GPIO7 RX'
            c['datasheet']='https://github.com/NologoTech/ESP32C3-Supermini/tree/main/Hardware'
            c['pins']=[dict(number=p['designator'],name=p['name'],net=p['orion_net'],
                           type=7 if p['designator'] in ('5V','3V3','GND') else
                           (2 if p['designator']=='6' else 0 if p['designator']=='7' else 1))
                       for p in module['pins']]
            c['pcb']['rotation']=180
            c['pcb']['status']='Nologo source-based header geometry; selected clone, sockets and USB clearance require mechanical review'
            c['pcb_footprint']=dict(body=[18,22.5],height=12,
                note='Nologo 16-pin interface; 15.24 mm rows / 2.54 mm pitch; carrier pads 1.8 mm / holes 1.0 mm; verify sockets',
                provisional=True,pads=[dict(number=p['designator'],x=p['x_mm'],y=p['y_mm'],
                    sx=1.8,sy=1.8,drill=1.0,shape='RECTANGLE' if p['designator']=='5' else 'ROUND') for p in module['pins']])
    data=enrich_components(data)
    for c in data['components']:
        names={str(p['number']):p['name'] for p in symbol_for(c)['pins']}
        for p in c['pins']:
            p['name']=names[str(p['number'])]
    return data


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    data=make_design()
    (OUT/'orion-r2-design.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
    build_libraries(data,OUT)
    schematic(data,OUT/(STEM+'.SchDoc'))
    build_pcb(data,OUT/(STEM+'.PcbDoc'))
    lines=['[Design]','Version=1.0','HierarchyMode=0','DefaultConfiguration=Sources',
           'AllowPortNetNames=0','AllowSheetEntryNetNames=1','NetlistSinglePinNets=0',
           'DefaultPcbProtel=1','AutoSheetNumbering=1','OutputPath=Project Outputs','']
    for i,name in enumerate([STEM+'.SchDoc',STEM+'.PcbDoc',SCHLIB,PCBLIB],1):
        lines += [f'[Document{i}]',f'DocumentPath={name}','AnnotationEnabled=1','AnnotateScope=All',
                  'DoLibraryUpdate=1','DoDatabaseUpdate=0','ClassGenCCAutoEnabled=1',
                  'ClassGenCCAutoRoomEnabled=0','ClassGenNCAutoScope=None','GenerateClassCluster=0',
                  'DocumentUniqueId='+ (uid(STEM+'Sheet') if i==1 else ''),'']
    (OUT/(STEM+'.PrjPcb')).write_bytes('\r\n'.join(lines).encode('ascii'))
    print(OUT/(STEM+'.PrjPcb'))


if __name__=='__main__': main()
