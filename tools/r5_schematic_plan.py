"""Readable functional sheets for the original SuperMini R5 carrier."""
from __future__ import annotations
import copy

STEM='BatterySentinel-N2K-Orion-R5'


def apply_plan(data):
    power={
        'J1':(140,1150,0),'TP1':(140,930,0),'F1':(460,1250,0),'D5':(640,1250,0),
        'D1':(820,1140,0),'C20':(1000,1140,0),'C21':(1160,1140,0),
        'U3':(1420,1200,0),'C24':(1610,1350,90),'L2':(1760,1200,0),
        'C22':(1920,1100,0),'C23':(2080,1100,0),
        'C25':(190,690,0),'C26':(370,610,0),'U2':(620,700,0),
        'C27':(840,690,0),'C28':(1030,690,0),'R20':(820,410,270),'R21':(1030,410,270),
        'C29':(1300,930,0),'C30':(1510,930,0),'U4':(1440,640,0),
        'C31':(1760,840,90),'L3':(1750,640,0),
        'C32':(1920,660,0),'C33':(2080,660,0),'SW3':(1770,350,0),'C34':(2070,350,0),
    }
    logic={
        'L1':(270,1130,0),'D3':(270,900,0),'C4':(650,1320,0),
        'U1':(800,1130,0),'C5':(1080,1320,0),'R2':(1080,1120,270),
        'R3':(1280,1150,180),'R4':(1280,970,0),'MCU1':(1750,1100,0),
    }
    for c in data['components']:
        ref=c['ref'];plan=power if ref in power else logic
        if ref not in plan:raise ValueError('Unplaced R5 schematic component '+ref)
        x,y,a=plan[ref];c['schematic']=dict(x=x,y=y,rotation=a,stub_length=30)
        c['sheet']=STEM+('-Power' if ref in power else '-Logic')
        if ref=='D3':c['schematic_label_offset']=[55,15];c['schematic']['stub_length_by_pin']={'1':60,'2':30}
        if ref=='R4':c['schematic_label_offset']=[-20,30]
        if ref in ('C24','C31'):c['schematic_label_offset']=[-20,45]
    data['schematics']=[
        dict(stem=STEM+'-Power',title='01  Versorgung / NMEA 2000 / galvanisch getrennte Modulversorgung',
            sections=[dict(x=65,y=1400,width=2050,title='01  Busanschluss, Verpolschutz und geregelte 5-V-Busversorgung'),
                      dict(x=65,y=850,width=1070,title='02  Galvanische Trennung und dauerhafte Mindestlast'),
                      dict(x=1200,y=1020,width=920,title='03  Geregelte Modulversorgung und RUN / SERVICE')],
            wires=[dict(**{'from':['F1','2'],'to':['D5','2']},net='FUSED_IN'),
                   dict(**{'from':['U3','5'],'to':['L2','1']},net='SW_BUS'),
                   dict(**{'from':['U4','5'],'to':['L3','1']},net='SW_LOGIC')],
            notes=[dict(x=65,y=200,text='NET-S: 9-16 V DC gegen NET-C. GND_BUS und GND_LOGIC bleiben galvanisch getrennt.'),
                   dict(x=65,y=165,text='SERVICE vor dem Einstecken von USB waehlen. SW3 trennt die externe positive Modulversorgung.'),
                   dict(x=65,y=130,text='R20/R21 bleiben auch in SERVICE am isolierten Wandler. Keine parallele Einspeisung in Modul-3V3.'),
                   dict(x=65,y=95,text='J1: 1 Schirm, 2 NET-S, 3 NET-C, 4 CAN-H, 5 CAN-L. Keine 120-Ohm-Terminierung am Drop.')]),
        dict(stem=STEM+'-Logic',title='02  Geschuetzter CAN-Anschluss / ESP32-C3 SuperMini / lokale Bibliotheken',
            sections=[dict(x=65,y=1400,width=1260,title='04  CAN-Schutz und galvanisch getrennter Transceiver'),
                      dict(x=1370,y=1400,width=750,title='05  Originales ESP32-C3 SuperMini / direkte Loetmontage')],
            wires=[],
            notes=[dict(x=120,y=600,text='MCU1: die vom Nutzer bestaetigte Amazon-Ausfuehrung, ASIN B0FN4F6244.'),
                   dict(x=120,y=555,text='GPIO6 = CAN TX; GPIO7 = CAN RX. USB-C, Boot/Reset und 3,3-V-Regler sind bereits auf dem Modul.'),
                   dict(x=120,y=510,text='Der Modul-3V3-Ausgang versorgt ausschliesslich die Logikseite von U1 und deren Entkopplung.'),
                   dict(x=120,y=465,text='Vor USB: SW3 auf SERVICE. Modul-5V und USB-VBUS sind ohne interne Quellentrennung zu behandeln.'),
                   dict(x=120,y=420,text='Alle gleichnamigen Netze sind projektweit verbunden. Unbenutzte Modulpins sind bewusst NC.'),
                   dict(x=120,y=375,text='SchLib/PcbLib, Pinnummern und eindeutige IDs verknuepfen Schaltplan, Bauteile und PCB.')])]
    return data


def sheet_data(data,spec):
    d=copy.deepcopy(data)
    d['components']=[c for c in d['components'] if c['sheet']==spec['stem']]
    d['sheet_title']=spec['title'];d['schematic_sections']=spec.get('sections',[])
    d['schematic_wires']=spec.get('wires',[]);d['schematic_notes']=spec.get('notes',[])
    return d
