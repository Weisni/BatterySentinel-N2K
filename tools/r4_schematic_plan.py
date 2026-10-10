"""Human-readable functional arrangement for the two R4 schematic sheets."""
from __future__ import annotations
import copy


def apply_plan(data):
    power={
      'J1':(140,1150,0),'TP1':(140,930,0),'F1':(460,1250,0),'D5':(640,1250,0),
      'D1':(820,1140,0),'C20':(1000,1140,0),'C21':(1160,1140,0),
      'U3':(1420,1200,0),'C24':(1610,1350,90),'L2':(1760,1200,0),
      'C22':(1920,1100,0),'C23':(2080,1100,0),
      'C25':(190,690,0),'C26':(370,610,0),'U2':(620,700,0),
      'C27':(840,690,0),'C28':(1030,690,0),'R20':(820,410,270),'R21':(1030,410,270),
      'D2':(1320,790,0),'D4':(1320,610,0),'C29':(1570,930,0),'C30':(1760,930,0),
      'U4':(1640,640,0),'C31':(1990,840,90),'L3':(1930,640,0),
      'C32':(1920,390,0),'C33':(2100,390,0),
    }
    logic={
      'L1':(250,1130,0),'D3':(270,960,0),'C4':(580,1320,0),
      'U1':(760,1130,0),'C5':(1020,1320,0),'R2':(1010,1130,270),
      'R3':(1220,1150,180),'R4':(1220,970,0),
      'MCU1':(1740,1120,0),'R5':(1450,810,0),'R6':(1690,810,0),
      'R7':(1950,810,0),'R8':(1950,650,0),'C10':(1440,630,0),
      'C11':(1640,630,0),'C12':(1780,540,0),'SW1':(1910,410,0),'SW2':(1600,410,0),
      'J2':(180,420,0),'D6':(700,570,0),'R9':(450,340,270),'R10':(650,340,270),
      'R11':(1030,570,0),'R12':(1030,390,0),
    }
    for c in data['components']:
        spec=power if c['ref'] in power else logic
        x,y,a=spec[c['ref']]
        c['schematic']=dict(x=x,y=y,rotation=a,stub_length=30)
        c['sheet']='Orion-Bridge-R4-'+('Power' if c['ref'] in power else 'Logic')
        # Explicit text overrides remove legacy revision-specific coordinates.
        if c['ref']=='D3':c['schematic_label_offset']=[55,15]
        if c['ref']=='R4':c['schematic_label_offset']=[-20,30]
        if c['ref'] in ['C24','C31']:c['schematic_label_offset']=[-20,45]
        if c['ref']=='D3':c['schematic']['stub_length_by_pin']={'1':60,'2':30}
    data['schematics']=[
      dict(stem='Orion-Bridge-R4-Power',title='01  Versorgung / 9-16 V NMEA 2000 / isolierte Logik',
        sections=[dict(x=65,y=1400,width=2050,title='01  Anschluss, Verpolschutz und geregelte 5-V-Busversorgung'),
                  dict(x=65,y=850,width=1070,title='02  Galvanische Trennung und Mindestlast'),
                  dict(x=1220,y=1020,width=900,title='03  USB-Entkopplung und 3,3-V-Logikversorgung')],
        wires=[dict(**{'from':['F1','2'],'to':['D5','2']},net='FUSED_IN'),
               dict(**{'from':['U3','5'],'to':['L2','1']},net='SW_BUS'),
               dict(**{'from':['U4','5'],'to':['L3','1']},net='SW_LOGIC')],
        notes=[dict(x=65,y=180,text='NET-S: 9-16 V DC gegen NET-C (GND_BUS). Konservatives Firmware-Buslastbudget: LEN 12.'),
               dict(x=65,y=145,text='GND_BUS und GND_LOGIC bleiben galvanisch getrennt. USB-GND und USB-Schirm gehoeren zu GND_LOGIC.'),
               dict(x=65,y=110,text='D2/D4 entkoppeln die Versorgung automatisch. R20/R21 stellen die Mindestlast des isolierten Wandlers bereit.'),
               dict(x=65,y=75,text='J1: Kabel-Loetanschluss; Pin 1 Schirm, 2 NET-S, 3 NET-C, 4 CAN-H, 5 CAN-L. Keine 120-Ohm-Terminierung.')]),
      dict(stem='Orion-Bridge-R4-Logic',title='02  CAN / ESP32-C3 / USB und Service',
        sections=[dict(x=65,y=1400,width=1240,title='04  Geschuetzter, isolierter CAN-Anschluss'),
                  dict(x=1370,y=1400,width=750,title='05  ESP32-C3-WROOM-02-N4 / GPIO6 TX, GPIO7 RX'),
                  dict(x=65,y=790,width=1240,title='06  USB-C, ESD-Schutz und Abschlusswiderstaende')],
        wires=[dict(**{'from':['MCU1','9'],'to':['MCU1','19']},via=[[1720,880],[1760,880]],net='GND_LOGIC',label_at=[1720,880])],
        notes=[dict(x=1360,y=260,text='BOOT halten und RESET kurz druecken: ROM-Downloadmodus.'),
               dict(x=1360,y=220,text='ESP-Antennenbereich ragt ueber den Platinenrand.'),
               dict(x=1360,y=180,text='EP19 ohne Paste; optionales EPAD bleibt ungeloetet.'),
               dict(x=1360,y=140,text='Alle gleichnamigen Netze sind projektweit verbunden.'),
               dict(x=1360,y=100,text='Bauteile und Pins referenzieren lokale SchLib/PcbLib.')])
    ]
    return data


def sheet_data(data,spec):
    d=copy.deepcopy(data)
    d['components']=[c for c in d['components'] if c['sheet']==spec['stem']]
    d['sheet_title']=spec['title']
    d['schematic_sections']=spec.get('sections',[])
    d['schematic_wires']=spec.get('wires',[])
    d['schematic_notes']=spec.get('notes',[])
    return d
