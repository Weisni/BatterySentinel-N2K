"""R5 document identity and rules; physical geometry is supplied by the R5 model.

The R3/R4 builders remain historical inputs. Never substitute an MCU or infer a
module land pattern here: the reviewed R5 component model owns that decision.
"""
from __future__ import annotations

from pathlib import Path
from collections import Counter
import copy
import re

from build_altium_project import uid

ROOT = Path(__file__).resolve().parents[1]
STEM = 'BatterySentinel-N2K-Orion-R5'


def design_rules(data):
    """Keep reviewed fabrication rules and omit rules with no matching nets."""
    from altium_r4_documents import design_rules as previous_rules

    rules = previous_rules(data)
    rules = [rule for rule in rules
             if not ('SCOPE1EXPRESSION' in rule and not rule['SCOPE1EXPRESSION'])
             and rule['name']!='USB_Alignment_NPTH']
    from altium_pcb import mil
    for rule in rules:
        if rule['kind'] == 'SilkToSolderMaskClearance':
            rule['name'] = 'R5_Legend_Clearance'
        if rule['name']=='Mounting_NPTH':
            rule.update(SCOPE1EXPRESSION="IsPad And (HoleSize > 0) And (PadIsPlated = 'False') And (Not InComponent('SW3'))",
                        GAP=mil(1.7),GENERICCLEARANCE=mil(1.7))
    rules.append(dict(kind='Clearance',name='Switch_Locating_Holes',
                      SCOPE1EXPRESSION="IsPad And (HoleSize > 0) And (PadIsPlated = 'False') And InComponent('SW3')",
                      GAP=mil(.25),GENERICCLEARANCE=mil(.25),PRIORITY=3))
    return rules


def build_pcb(data,path,routing):
    """Native editable text, physical notch/cutout and linked component bodies."""
    from altium_r4_documents import build_pcb as previous_build
    from altium_pcb import record,base,mil
    from altium_routed_pcb import fields,contour_record
    from r5_branding import native_text_record,native_logo_records,FONT_NAME
    path=Path(path);source=copy.deepcopy(data);source['silkscreen']=[]
    summary=previous_build(source,path,routing)
    outline=data['board']['outline_points_mm'];rows=[]
    for line in path.read_text('cp1252').splitlines():
        p=fields(line);kind=p.pop('RECORD')
        if kind=='Board' and 'FILENAME' in p:
            p={k:v for k,v in p.items() if not re.fullmatch(r'(KIND|VX|VY|CX|CY|SA|EA|R)\d+',k)}
            for i,(x,y) in enumerate(outline):
                p.update({f'KIND{i}':0,f'VX{i}':mil(x),f'VY{i}':mil(y),f'CX{i}':mil(0),f'CY{i}':mil(0),f'SA{i}':0,f'EA{i}':0,f'R{i}':mil(0)})
        if kind in ('Track','Arc') and p.get('LAYER')=='MECHANICAL1' and 'COMPONENT' not in p:continue
        if kind=='Text':p.update(USETTFONTS=True,FONTNAME=FONT_NAME,BOLD=False,ITALIC=False,INVERTED=False)
        rows.append(record(kind,**p))
    for ring in [outline]+[c['outline_points_mm'] for c in data['board'].get('cutouts_mm',[])]:
        for a,b in zip(ring,ring[1:]):
            rows.append(record('Track',**base('MECHANICAL1'),X1=mil(a[0]),Y1=mil(a[1]),X2=mil(b[0]),Y2=mil(b[1]),WIDTH=mil(.05)))
    for cutout in data['board'].get('cutouts_mm',[]):
        rows.append(contour_record('Region',cutout['outline_points_mm'],**base('MULTILAYER'),
                                  NAME=cutout['name'],KEEPOUT=False,ISBOARDCUTOUT=True))
    for label in data['board'].get('native_texts',[]):rows.append(native_text_record(label))
    for logo in data['board'].get('native_logos',[]):rows.extend(native_logo_records(logo))
    count=Counter();out=[]
    for line in rows:
        p=fields(line);kind=p.pop('RECORD')
        if kind!='Board':p['INDEXFORSAVE']=count[kind];count[kind]+=1
        out.append(record(kind,**p))
    path.write_bytes(('\r\n'.join(out)+'\r\n').encode('cp1252'))
    summary['primitive_counts']=dict(count);return summary


def schematic(data, path):
    """Reuse the symbol/wire renderer with R5-specific visible project names."""
    from altium_r4_documents import schematic as render

    path = Path(path)
    count = render(data, path)
    content = path.read_text('cp1252')
    content = content.replace('ORION BRIDGE R4 / NMEA 2000 - BLE',
                              'BatterySentinel-N2K / Orion-R5 / NMEA 2000 - BLE')
    content = content.replace('SMD-Modul / galvanisch getrennte Versorgung und CAN',
                              'ESP32-C3 SuperMini / galvanisch getrennte Versorgung und CAN')
    path.write_bytes(content.replace('\r\n', '\n').replace('\n', '\r\n').encode('cp1252'))
    return count


def write_project(data, folder):
    folder = Path(folder)
    template = ROOT / 'hardware/altium-r2/Orion-Bridge-R2.PrjPcb'
    content = template.read_text('ascii').replace('Orion-Bridge-R2', STEM)
    content = re.sub(r'(?m)^HierarchyMode=.*$', 'HierarchyMode=0', content)
    content = re.sub(r'(?ms)^\[Document\d+\].*?(?=^\[|\Z)', '', content)
    documents = [sheet['stem'] + '.SchDoc' for sheet in data['schematics']]
    documents += [STEM + '.PcbDoc', 'Orion-Bridge.SchLib', 'Orion-Bridge.PcbLib']
    for index, name in enumerate(documents, 1):
        identity = Path(name).stem + 'Sheet' if name.endswith('.SchDoc') else name + 'Document'
        content += (
            f'\n[Document{index}]\nDocumentPath={name}\n'
            'AnnotationEnabled=1\nAnnotateScope=All\nDoLibraryUpdate=1\n'
            'ClassGenCCAutoEnabled=1\nClassGenCCAutoRoomEnabled=0\nClassGenNCAutoScope=None\n'
            f'DocumentUniqueId={uid(identity)}\n'
        )
    folder.mkdir(parents=True, exist_ok=True)
    result = folder / (STEM + '.PrjPcb')
    result.write_bytes(content.replace('\r\n', '\n').replace('\n', '\r\n').encode('ascii'))
    return result
