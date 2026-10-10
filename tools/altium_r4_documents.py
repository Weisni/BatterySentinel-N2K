"""R4 native Altium documents from the reviewed manufacturing design model."""
from __future__ import annotations
from collections import Counter
from pathlib import Path
import math
import re

from altium_pcb import record, base, mil, transform
from altium_routed_pcb import build_routed_pcb, fields
from build_altium_project import uid


def outline_points(board, steps=64):
    w,h=board['width_mm'],board['height_mm'];r=board.get('corner_radius_mm',0)
    if not r:return [(0,0),(w,0),(w,h),(0,h)]
    result=[]
    for cx,cy,start in [(w-r,r,270),(w-r,h-r,0),(r,h-r,90),(r,r,180)]:
        for i in range(steps+1):
            a=math.radians(start+90*i/steps)
            result.append((cx+r*math.cos(a),cy+r*math.sin(a)))
    return result


def build_pcb(data,path,routing):
    """Preserve native source links; replace prototype-specific R3 annotations."""
    path=Path(path)
    summary=build_routed_pcb(data,path,routing)
    rows=[];parts=data['components'];outline=outline_points(data['board'])
    for line in path.read_text('cp1252').splitlines():
        p=fields(line);kind=p.pop('RECORD')
        if kind=='Board' and 'FILENAME' in p:
            p={k:v for k,v in p.items() if not re.fullmatch(r'(KIND|VX|VY|CX|CY|SA|EA|R)\d+',k)}
            for i,(x,y) in enumerate(outline+[outline[0]]):
                p.update({f'KIND{i}':0,f'VX{i}':mil(x),f'VY{i}':mil(y),f'CX{i}':mil(0),
                          f'CY{i}':mil(0),f'SA{i}':0,f'EA{i}':0,f'R{i}':mil(0)})
        if kind in ('Track','Arc') and p.get('LAYER')=='MECHANICAL1' and 'COMPONENT' not in p:continue
        if kind=='Text' and 'COMPONENT' not in p:continue
        if kind=='Pad' and 'COMPONENT' in p:
            part=parts[int(p['COMPONENT'])]
            spec=next(q for q in part['pcb_footprint']['pads'] if str(q['number'])==p['NAME'])
            if spec.get('paste') is False or part.get('assembly',{}).get('populate') is False:
                p.update(PASTEMASKEXPANSIONMODE='Manual',PASTEMASKEXPANSION_MANUAL=mil(-10),CPEV=2,CPE=mil(-10))
            if spec.get('mask_expansion_mm') is not None:
                p.update(SOLDERMASKEXPANSIONMODE='Manual',SOLDERMASKEXPANSION_MANUAL=mil(spec['mask_expansion_mm']),
                         CSEV=2,CSE=mil(spec['mask_expansion_mm']))
        if kind in ('DXPRule','Rule') and p.get('RULEKIND')=='Width':
            p['MINLIMIT']=mil(data['routing_constraints']['signal_width'])
            p['PRIORITY']=2
        if kind in ('DXPRule','Rule') and p.get('NAME')=='PadSolderMask':
            p['EXPANSION']=mil(data['manufacturing']['mask_expansion_mm'])
        if kind=='DXPRule' and p.get('NAME')=='Clearance':
            p['PRIORITY']=10
        if kind=='Pad' and 'COMPONENT' not in p and p.get('PLATED')=='FALSE':
            p.update(SOLDERMASKEXPANSION_MANUAL=mil(.05),CSEV=2,CSE=mil(.05),
                     PASTEMASKEXPANSIONMODE='Manual',PASTEMASKEXPANSION_MANUAL=mil(-10),CPEV=2,CPE=mil(-10))
        rows.append(record(kind,**p))
    for a,b in zip(outline,outline[1:]+outline[:1]):
        rows.append(record('Track',**base('MECHANICAL1'),X1=mil(a[0]),Y1=mil(a[1]),X2=mil(b[0]),Y2=mil(b[1]),WIDTH=mil(.05)))
    for ci,c in enumerate(parts):
        for hole in c.get('pcb_footprint',{}).get('holes',[]):
            x,y=transform(c,hole['x'],hole['y']);d=hole['drill']
            rows.append(record('Pad',**base('MULTILAYER'),COMPONENT=ci,NAME='',X=mil(x),Y=mil(y),
                XSIZE=mil(d),YSIZE=mil(d),SHAPE='ROUND',HOLESIZE=mil(d),ROTATION=0,PLATED=False,
                SOLDERMASKEXPANSIONMODE='Manual',SOLDERMASKEXPANSION_MANUAL=mil(.05),CSEV=2,CSE=mil(.05),
                PASTEMASKEXPANSIONMODE='Manual',PASTEMASKEXPANSION_MANUAL=mil(-10),CPEV=2,CPE=mil(-10),
                PADMODE=0,DRILLTYPE=0,HOLETYPE=0))
    from export_jlcpcb_r4 import silk_segments
    for label in data.get('silkscreen',[]):
        silk_layer={'TOP':'TOPOVERLAY','BOTTOM':'BOTTOMOVERLAY'}.get(label.get('layer','TOP'),label.get('layer','TOPOVERLAY'))
        for points,width in silk_segments(label):
            for a,b in zip(points,points[1:]):
                rows.append(record('Track',**base(silk_layer),X1=mil(a[0]),Y1=mil(a[1]),X2=mil(b[0]),Y2=mil(b[1]),WIDTH=mil(width)))
    for item in data.get('design_rules',[]):
        p=dict(item);kind=p.pop('kind');name=p.pop('name',kind)
        args=dict(RULEKIND=kind,NETSCOPE='AnyNet',LAYERKIND='SameLayer',NAME=name,ENABLED=True,
                  SCOPE1EXPRESSION='All',SCOPE2EXPRESSION='All',PRIORITY=1,
                  UNIQUEID=uid('R4-rule-'+name),DEFINEDBYLOGICALDOCUMENT=False)
        args.update(p)
        rows.append(record('DXPRule',**base(),**args))
    count=Counter();out=[]
    for line in rows:
        p=fields(line);kind=p.pop('RECORD')
        if kind!='Board':p['INDEXFORSAVE']=count[kind];count[kind]+=1
        out.append(record(kind,**p))
    path.write_bytes(('\r\n'.join(out)+'\r\n').encode('cp1252'))
    summary['primitive_counts']=dict(count)
    return summary


def design_rules(data):
    """Native editable constraints, in addition to geometric release checks."""
    bus={'NET_S','FUSED_IN','BUS_PROT','5V_BUS','SW_BUS','BST_BUS','GND_BUS','CANH_EXT','CANL_EXT','CANH','CANL','SHIELD'}
    nets={p['net'] for c in data['components'] for p in c['pins'] if p.get('net')}
    scope=lambda ns:' Or '.join("InNet('"+n+"')" for n in sorted(ns))
    return [
        dict(kind='Width',name='USB_FullSpeed',SCOPE1EXPRESSION=scope(nets & {'USB_DM_IN','USB_DP_IN','USB_DM','USB_DP','USB_DM_MCU','USB_DP_MCU','USB_CC1','USB_CC2'}),
             MINLIMIT=mil(.15),MAXLIMIT=mil(.5),PREFEREDWIDTH=mil(.15)),
        dict(kind='Clearance',name='Isolation_BUS_LOGIC',NETSCOPE='DifferentNets',
             SCOPE1EXPRESSION=scope(nets&bus),SCOPE2EXPRESSION=scope(nets-bus),GAP=mil(3.2),GENERICCLEARANCE=mil(3.2)),
        dict(kind='Clearance',name='Mounting_NPTH',SCOPE1EXPRESSION="IsPad And (HoleSize > 0) And (PadIsPlated = 'False') And (Not InComponent('J2'))",
             GAP=mil(.25),GENERICCLEARANCE=mil(.25),PRIORITY=2),
        dict(kind='Clearance',name='USB_Alignment_NPTH',SCOPE1EXPRESSION="IsPad And (HoleSize > 0) And (PadIsPlated = 'False') And InComponent('J2')",
             GAP=mil(.20),GENERICCLEARANCE=mil(.20),PRIORITY=3),
        dict(kind='MinimumAnnularRing',name='PTH_AnnularRing',SCOPE1EXPRESSION="IsPad And (PadIsPlated = 'True')",MINIMUMRING=mil(.18)),
        dict(kind='MinimumAnnularRing',name='Via_AnnularRing',SCOPE1EXPRESSION='IsVia',MINIMUMRING=mil(.15),PRIORITY=2),
        dict(kind='HoleSize',name='HoleSize',MINLIMIT=mil(.3),MAXLIMIT=mil(6.3)),
        dict(kind='HoleToHoleClearance',name='HoleToHoleClearance',GAP=mil(.25),ALLOWSTACKEDMICROVIAS=False),
        dict(kind='BoardOutlineClearance',name='BoardEdge_0_30mm',GAP=mil(.3),GENERICCLEARANCE=mil(.3),
             OBJECTCLEARANCES=';'.join(f'ClearanceObj_{obj}-ClearanceObj_{edge}:118110'
                 for obj in ['Arc','Track','SMDPad','THPad','Via','Fill','Poly','Region','Text']
                 for edge in ['OutlineEdge','CavityEdge','CutoutEdge'])),
        dict(kind='PasteMaskExpansion',name='Paste_1to1',EXPANSION=mil(0)),
        dict(kind='SilkToSolderMaskClearance',name='SilkToMask_0_15mm',SCOPE1EXPRESSION='IsPad',
             MINSILKSCREENTOMASKGAP=mil(.15),CLEARANCETOEXPOSEDCOPPER=False),
        dict(kind='SilkToSilkClearance',name='SilkToSilk',SILKTOSILKCLEARANCE=mil(.1)),
    ]


def schematic(data,path):
    """Draw real symbols and explicitly wired named nets in functional sections.

    Placements, optional direct wires and text live in the reviewable design JSON.
    All unconnected pins receive intentional NC markers, never fictitious nets.
    """
    import build_altium_r2 as sch
    from altium_symbols import symbol_for
    sch.STEM=Path(path).stem
    s=sch.Sheet(data)
    s.text(65,1490,'ORION BRIDGE R4 / NMEA 2000 - BLE',True)
    s.text(65,1460,data.get('sheet_title','SMD-Modul / galvanisch getrennte Versorgung und CAN'))
    s.text(1670,1490,'23.09.2026 / Altium / JLCPCB')
    s.line((65,1435),(2160,1435))
    for sec in data.get('schematic_sections',[]):
        s.section(sec['x'],sec['y'],sec['title'],sec['width'])
    for part in data['components']:
        p=part['schematic'];s.place(part['ref'],p['x'],p['y'],p.get('rotation',0))
    explicit=set()
    for wire in data.get('schematic_wires',[]):
        a,b=wire['from'],wire['to'];pa=s.p(*a);pb=s.p(*b)
        explicit.update([(a[0],str(a[1])),(b[0],str(b[1]))])
        pts=[pa]+[tuple(p) for p in wire.get('via',[])]+[pb]
        s.wire(*pts)
        if wire.get('net'):s.label(tuple(wire.get('label_at',pa)),wire['net'])
    for part in data['components']:
        symbol=symbol_for(part);by_number={p['number']:p for p in symbol['pins']}
        for pin in part['pins']:
            key=(part['ref'],str(pin['number']));p=s.p(*key)
            if not pin.get('net'):s.nc(p);continue
            if key in explicit:continue
            ori=(by_number[str(pin['number'])]['orientation']+part['schematic'].get('rotation',0)//90)%4
            dx,dy=[(1,0),(0,1),(-1,0),(0,-1)][ori]
            stub=part['schematic'].get('stub_length_by_pin',{}).get(str(pin['number']),part['schematic'].get('stub_length',30))
            if dx<0:stub=max(stub,20+10*math.ceil(len(pin['net'])*.65))
            q=(p[0]+stub*dx,p[1]+stub*dy);s.wire(p,q)
            if pin['net'].startswith('GND') and dy==-1:s.power(q,pin['net'],True)
            else:s.label(q,pin['net'])
    for note in data.get('schematic_notes',[]):s.text(note['x'],note['y'],note['text'])
    s.finish(Path(path))
    return len(s.rows)


def write_project(data,folder):
    folder=Path(folder);stem='Orion-Bridge-R4'
    source=Path(__file__).resolve().parents[1]/'hardware/altium-r2/Orion-Bridge-R2.PrjPcb'
    project=source.read_text('ascii').replace('Orion-Bridge-R2',stem)
    # Automatic scope selects Global when sheets contain labels and no ports
    # or sheet entries (Altium documented behavior). Set hierarchy explicitly.
    project=re.sub(r'(?m)^HierarchyMode=.*$','HierarchyMode=0',project)
    project=re.sub(r'(?ms)^\[Document\d+\].*?(?=^\[|\Z)','',project)
    documents=[s['stem']+'.SchDoc' for s in data['schematics']]+[stem+'.PcbDoc','Orion-Bridge.SchLib','Orion-Bridge.PcbLib']
    for i,name in enumerate(documents,1):
        project+='\n'+f'[Document{i}]\nDocumentPath={name}\nAnnotationEnabled=1\nAnnotateScope=All\nDoLibraryUpdate=1\n'
        project+='ClassGenCCAutoEnabled=1\nClassGenCCAutoRoomEnabled=0\nClassGenNCAutoScope=None\n'
        identity=Path(name).stem+'Sheet' if name.endswith('.SchDoc') else name+'Document'
        project+='DocumentUniqueId='+uid(identity)+'\n'
    (folder/(stem+'.PrjPcb')).write_bytes(project.replace('\n','\r\n').encode('ascii'))
