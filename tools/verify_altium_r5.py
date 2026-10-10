"""Independent readback of the Orion R5 sources and JLCPCB assembly data.

Reads real SchDoc wires, native SchLib/PcbLib streams and exported PcbDoc
copper. It never launches Altium or trusts a router/mechanical cache. This is
not Altium's native ERC/DRC, manufacturer DFM, or physical qualification.
Use --model-only during development; it cannot produce a release pass.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import configparser
import csv
import hashlib
import json
import math
from pathlib import Path
import re
import struct
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
from shapely import affinity
from shapely.geometry import Point, LineString, Polygon, box
from shapely.ops import unary_union
from shapely.strtree import STRtree
from verify_altium_project import Audit, records, mm, unique, expected_nets
import verify_altium_r2 as reference
from altium_libraries import read_cfb_streams, decode_schematic_library

STEM = 'BatterySentinel-N2K-Orion-R5'
SCHLIB = 'Orion-Bridge.SchLib'
PCBLIB = 'Orion-Bridge.PcbLib'
CFB_MAGIC = bytes.fromhex('d0cf11e0a1b11ae1')
LAYERS = ('TOP', 'BOTTOM')
TOL = .001
BUS_NETS = {'NET_S', 'FUSED_IN', 'BUS_PROT', '5V_BUS', 'GND_BUS',
            'SW_BUS', 'BST_BUS', 'CANH_EXT', 'CANL_EXT', 'CANH', 'CANL', 'SHIELD'}


def close(a, b, tolerance=TOL):
    return math.isclose(float(a), float(b), abs_tol=tolerance)


def transform(part, shape):
    p = part['pcb']
    return affinity.translate(affinity.rotate(shape, p.get('rotation', 0), origin=(0, 0)), p['x'], p['y'])


def pad_shape(x, y, sx, sy, shape, rotation=0):
    if shape in ('ROUND', 1):
        geom = affinity.scale(Point(0, 0).buffer(1, quad_segs=64), sx/2, sy/2)
    elif shape in ('RECTANGLE', 2):
        geom = box(-sx/2, -sy/2, sx/2, sy/2)
    elif shape in ('OCTAGON', 3):
        # Altium octagon is a rectangle with equal 45-degree corner cuts.
        cut = min(sx, sy) * (1 - 1/math.sqrt(2)) / 2
        geom = Polygon([(-sx/2+cut,-sy/2), (sx/2-cut,-sy/2), (sx/2,-sy/2+cut),
                        (sx/2,sy/2-cut), (sx/2-cut,sy/2), (-sx/2+cut,sy/2),
                        (-sx/2,sy/2-cut), (-sx/2,-sy/2+cut)])
    else:
        raise ValueError('Unsupported copper pad shape '+str(shape))
    return affinity.translate(affinity.rotate(geom, rotation, origin=(0,0)), x, y)


def hole_shape(x, y, diameter, length=0, angle=0):
    if length > diameter:
        half = (length-diameter)/2
        geom = LineString([(-half,0),(half,0)]).buffer(diameter/2, quad_segs=64)
        geom = affinity.rotate(geom, angle, origin=(0,0))
    else:
        geom = Point(0,0).buffer(diameter/2, quad_segs=64)
    return affinity.translate(geom, x, y)


def rounded_board(board):
    w,h,r = board['width_mm'],board['height_mm'],board.get('corner_radius_mm',0)
    if not 0 < r <= min(w,h)/2:
        raise ValueError('R5 requires a valid positive corner radius')
    return box(r,r,w-r,h-r).buffer(r, quad_segs=128)


def reviewed_profile(board):
    """Reconstruct the intended mechanical features independently of vertices."""
    outer=rounded_board(board);cutouts=[]
    for feature in board.get('mechanical_features',[]):
        x1,y1,x2,y2=feature['bounds_mm'];r=feature.get('corner_radius_mm',0)
        shape=box(x1+r,y1+r,x2-r,y2-r).buffer(r,quad_segs=128) if r else box(x1,y1,x2,y2)
        if feature['kind']=='edge_notch':outer=outer.difference(shape)
        elif feature['kind']=='internal_cutout':cutouts.append(shape)
        else:raise ValueError('Unknown mechanical feature '+feature['kind'])
    return outer,cutouts


def check_model(a, data):
    model = {p['ref']:p for p in data['components']}
    unique(a, [p['ref'] for p in data['components']], 'Model references')
    unique(a, [p['uid'] for p in data['components']], 'Model component UIDs')
    # Independently reviewed manufacturer pin functions, not generated from
    # the design's own connectivity. Updating the circuit needs re-review.
    maps = {
        'U1': ['3V3_LOGIC','TXD','RXD','GND_LOGIC','GND_BUS','CANL','CANH','5V_BUS'],
        'U3': ['5V_BUS','BUS_PROT','BUS_PROT','GND_BUS','SW_BUS','BST_BUS'],
        'U4': ['5V_REG','5V_ISO','5V_ISO','GND_LOGIC','SW_LOGIC','BST_LOGIC'],
        'U2': {'1':'5V_BUS','2':'GND_BUS','4':'GND_LOGIC','6':'5V_ISO'},
        'MCU1': {'5':None,'6':'GPIO6','7':'GPIO7','8':None,'9':None,'10':None,'20':None,'21':None,
                 '5V':'5V_MODULE','GND':'GND_LOGIC','3V3':'3V3_LOGIC','4':None,'3':None,'2':None,'1':None,'0':None},
        'D1': ['BUS_PROT','GND_BUS'], 'D5': ['BUS_PROT','FUSED_IN'],
        'D3': ['CANH_EXT','CANL_EXT','GND_BUS'],
        'L1': ['CANH_EXT','CANL_EXT','CANL','CANH'],
        'L2': ['SW_BUS','5V_BUS'], 'L3': ['SW_LOGIC','5V_REG'],
        'F1': ['NET_S','FUSED_IN'], 'TP1': ['SHIELD'],
        'J1': ['SHIELD','NET_S','GND_BUS','CANH_EXT','CANL_EXT'],
        'R2': ['3V3_LOGIC','TXD'], 'R3': ['GPIO6','TXD'], 'R4': ['RXD','GPIO7'],
        'R20': ['5V_ISO','GND_LOGIC'], 'R21': ['5V_ISO','GND_LOGIC'],
        'SW3': ['5V_REG','5V_MODULE',None,'GND_LOGIC','GND_LOGIC','GND_LOGIC','GND_LOGIC'],
        'C4': ['5V_BUS','GND_BUS'], 'C5': ['3V3_LOGIC','GND_LOGIC'],
        'C20': ['BUS_PROT','GND_BUS'],
        'C21': ['BUS_PROT','GND_BUS'], 'C22': ['5V_BUS','GND_BUS'],
        'C23': ['5V_BUS','GND_BUS'], 'C24': ['BST_BUS','SW_BUS'],
        'C25': ['5V_BUS','GND_BUS'], 'C26': ['5V_BUS','GND_BUS'],
        'C27': ['5V_ISO','GND_LOGIC'], 'C28': ['5V_ISO','GND_LOGIC'],
        'C29': ['5V_ISO','GND_LOGIC'], 'C30': ['5V_ISO','GND_LOGIC'],
        'C31': ['BST_LOGIC','SW_LOGIC'], 'C32': ['5V_REG','GND_LOGIC'],
        'C33': ['5V_REG','GND_LOGIC'], 'C34':['5V_MODULE','GND_LOGIC'],
    }
    a.check(set(maps)==set(model), 'Unreviewed or missing component in R5 electrical reference: '+str(sorted(set(maps)^set(model))))
    for ref, want in maps.items():
        if ref not in model:
            continue
        if isinstance(want,list): want={str(i+1):n for i,n in enumerate(want)}
        got={str(p['number']):p['net'] for p in model[ref]['pins']}
        a.check(got==want, ref+': pin/net functions differ from reviewed electrical reference')
    expected_parts={'U1':('ISO1042DWVR','C2671714'),'U2':('B0505S-3WR2','C7500927'),
                    'U3':('AP63205WU-7','C2071056'),'U4':('AP63205WU-7','C2071056'),
                    'L3':('SWPA4030S4R7MT','C57269'),'SW3':('MK-12C02-G020','C963206')}
    for ref,(mpn,code) in expected_parts.items():
        if ref in model:
            a.check(model[ref].get('mpn')==mpn and model[ref].get('assembly',{}).get('lcsc')==code,
                    ref+': approved manufacturer part/source changed')
    values={'R2':'10k','R3':'33R','R4':'33R','R20':'150R','R21':'150R',
            'L2':'4.7uH','L3':'4.7uH','C20':'10uF','C21':'10uF',
            'C22':'22uF','C23':'22uF','C24':'100nF','C25':'10uF','C27':'22uF',
            'C29':'10uF','C31':'100nF','C32':'22uF','C33':'22uF','C34':'10uF'}
    for ref,value in values.items():
        if ref in model: a.check(model[ref]['value'].split()[0]==value,ref+': incorrect electrical value')
    for ref,part in model.items():
        unique(a,[str(p['number']) for p in part['pins']],ref+' model pin numbers')
        fp=part.get('pcb_footprint',{})
        a.check({str(p['number']) for p in fp.get('pads',[])}=={str(p['number']) for p in part['pins']},
                ref+': explicit local footprint does not have every schematic pin')
        a.check(bool(part.get('libref')) and bool(part.get('sheet')),ref+': missing library/sheet identity')
        assembly=part.get('assembly',{})
        if assembly.get('populate'):
            a.check(bool(re.fullmatch(r'C\d+',assembly.get('lcsc',''))),ref+': no JLC/LCSC source code')
            a.check(assembly.get('lcsc_confirmed') is True,ref+': source identity not confirmed')
            a.check(all(part.get(k) for k in ('manufacturer','mpn','datasheet')),ref+': incomplete manufacturer reference')
            a.check(fp.get('provisional') is False,ref+': populated footprint is provisional')
            a.check(part.get('parameters',{}).get('Supplier Part Number 1')==assembly.get('lcsc'),
                    ref+': source parameter differs from assembly source')
    if 'MCU1' in model:
        m=model['MCU1']; fp=m['pcb_footprint']
        a.check('B0FN4F6244' in m.get('source_url',''),'MCU1 is not the user-selected Amazon C3 module')
        a.check(m.get('assembly',{}).get('populate') is False and not m.get('assembly',{}).get('lcsc'),
                'Original SuperMini must remain explicitly manual assembly, without invented JLC source')
        a.check(fp.get('holes',[])==[] and len(fp['pads'])==16,'SuperMini carrier must have exactly16 SMD contacts and no header holes')
        for side,order in [(-1,('5','6','7','8','9','10','20','21')),(1,('5V','GND','3V3','4','3','2','1','0'))]:
            for i,n in enumerate(order):
                p=next((p for p in fp['pads'] if str(p['number'])==n),{})
                a.check(all(close(p.get(k,-999),v) for k,v in dict(x=side*8.6,y=9.7006-2.54*i,sx=2.8,sy=1.8,drill=0).items()),
                        'MCU1.'+n+': selected castellated land geometry changed')
                a.check(p.get('paste') is False,'MCU1.'+n+': manual module must suppress stencil paste')
        types={str(p['number']):p['type'] for p in m['pins']}
        a.check(types=={n:7 if n in ('5V','GND','3V3') else 1 for n in maps['MCU1']},'MCU1 electrical pin types differ')
        a.check(not any('header ' in b['name'].lower() for b in m.get('bodies_3d',[])), 'MCU1 unexpectedly contains header geometry')
    a.check(len(data['board'].get('holes_mm',[]))==4,'R5 requires four mounting holes')
    a.check(bool(data['board'].get('outline_points_mm')) and len(data['board'].get('cutouts_mm',[]))==1,
            'R5 requires actual USB-notched outline and one routed RF window')
    declared=data['board'].get('native_texts',[])
    a.check({'BatterySentinel-N2K','Orion-R5','RUN','SERVICE'}<={t['text'] for t in declared},'R5 branding/service text declarations missing')
    a.check(bool(data['board'].get('native_logos')),'R5 PCB logo missing')
    return model


def check_schematic_links(a,path,model):
    rows=records(path)[1:]; children=reference.indexed_children(rows)
    for i,row in enumerate(rows):
        if row.get('RECORD')!='1': continue
        refs=[r.get('TEXT') for _,r in children[i] if r.get('RECORD')=='34']
        if len(refs)!=1 or refs[0] not in model: continue
        part=model[refs[0]]; ref=part['ref']
        a.check(row.get('LIBREFERENCE')==row.get('DESIGNITEMID')==part['libref'],ref+': schematic library identity')
        a.check(row.get('SOURCELIBRARYNAME')==SCHLIB,ref+': schematic library is not local')
        params={r.get('NAME'):r.get('TEXT','') for _,r in children[i] if r.get('RECORD')=='41'}
        for key,value in part.get('parameters',{}).items():
            if key!='Role': a.check(params.get(key)==value,ref+': schematic parameter '+key)
        reference.check_model_link(a,rows,i,part,ref+' SchDoc')


def check_project(a,path,sheets,allow_missing_pcb=False):
    project=configparser.ConfigParser(interpolation=None)
    project.read(path,encoding='utf-8-sig')
    docs=[project[s].get('DocumentPath','') for s in project.sections() if re.fullmatch(r'Document\d+',s)]
    expected={s+'.SchDoc' for s in sheets}|{STEM+'.PcbDoc',SCHLIB,PCBLIB}
    # Native Save Project can register the generated DRC HTML as a document.
    # It is not an extra schematic or PCB and must remain inside the package.
    normalized={d.replace('\\','/') for d in docs}
    report='Project Outputs/Design Rule Check - '+STEM+'.html'
    a.check(normalized-{report}==expected,'Project does not include exactly all schematic sheets, PCB and local libraries')
    unique(a,docs,'Project document paths')
    for document in docs:
        target=(path.parent/document).resolve()
        a.check(path.parent.resolve() in target.parents,'Project reference escapes package: '+document)
        if not(allow_missing_pcb and document==STEM+'.PcbDoc'):
            a.check(target.is_file(),'Project document is missing: '+document)


def decode_footprints(streams):
    """Read native PCB6 primitive blocks including NPTH and slot extensions.

    Slot fields follow the PCB6 extended pad record, rather than trusting the
    generator's decoded Pad object (which historically omitted this data).
    """
    result={}
    def block(data,offset):
        size=struct.unpack_from('<I',data,offset)[0]&0xffffff
        end=offset+4+size
        if end>len(data): raise ValueError('Truncated native library block')
        return data[offset+4:end],end
    for stream,data in streams.items():
        if not stream.endswith('/Data') or stream.startswith('Library/'): continue
        prefix=stream.rsplit('/',1)[0]
        name,offset=block(data,0); name=name[1:1+name[0]].decode('cp1252')
        prims=[]
        while offset<len(data):
            kind=data[offset];offset+=1
            if kind==2:
                chunks=[]
                for _ in range(6):
                    chunk,offset=block(data,offset);chunks.append(chunk)
                body=chunks[4]; ex=chunks[5]; number=chunks[0][1:1+chunks[0][0]].decode('cp1252')
                x,y,sx,sy=struct.unpack_from('<iiii',body,13)
                prims.append(dict(kind='Pad',number=number,layer=body[0],plated=bool(body[60]),
                    **dict(zip(('x','y','sx','sy'),(v*.0254/10000 for v in (x,y,sx,sy)))),
                    drill=struct.unpack_from('<i',body,45)[0]*.0254/10000,shape=body[49],
                    rotation=struct.unpack_from('<d',body,52)[0],
                    slot_type=ex[262] if len(ex)>262 else 0,
                    slot_length=struct.unpack_from('<i',ex,263)[0]*.0254/10000 if len(ex)>=267 else 0,
                    slot_angle=struct.unpack_from('<d',ex,267)[0] if len(ex)>=275 else 0,
                    paste_disabled=body[101]==2 and struct.unpack_from('<i',body,86)[0]<0))
            elif kind in (4,12):
                chunk,offset=block(data,offset)
                primitive={'kind':'Track' if kind==4 else 'ComponentBody'}
                if kind==12:
                    size=struct.unpack_from('<I',chunk,18)[0]
                    props={k:v for field in chunk[22:22+size].rstrip(b'\0').decode('cp1252').split('|')
                           if '=' in field for k,v in [field.split('=',1)]}
                    count=struct.unpack_from('<I',chunk,22+size)[0]
                    primitive.update(properties=props,vertices=count)
                prims.append(primitive)
            else: raise ValueError(f'Unexpected native PcbLib primitive {kind}: {prefix}')
        count=struct.unpack('<I',streams[prefix+'/Header'])[0]
        if name!=prefix or len(prims)!=count: raise ValueError('Native footprint header/count mismatch: '+prefix)
        result[name]=prims
    return result


def check_libraries(a,root,model):
    for name in (SCHLIB,PCBLIB):
        a.check((root/name).read_bytes().startswith(CFB_MAGIC),name+': not native binary CFB')
    sch=decode_schematic_library(read_cfb_streams(root/SCHLIB))
    pcb=decode_footprints(read_cfb_streams(root/PCBLIB))
    a.check(set(sch)=={p['libref'] for p in model.values()},'SchLib identities differ from model')
    a.check(set(pcb)=={p['footprint'] for p in model.values()},'PcbLib identities differ from model')
    for ref,part in model.items():
        if part['libref'] not in sch or part['footprint'] not in pcb: continue
        rows=sch[part['libref']]
        components=[(i,r) for i,r in enumerate(rows) if r.get('RECORD')=='1']
        a.check(len(components)==1,ref+': library entry requires one component')
        for i,r in components:
            a.check(r.get('LIBREFERENCE')==r.get('DESIGNITEMID')==part['libref'],ref+': SchLib identity')
            reference.check_model_link(a,rows,i,part,ref+' SchLib')
        pins=[r for r in rows if r.get('RECORD')=='2']
        unique(a,[p['DESIGNATOR'] for p in pins],ref+' SchLib pin numbers')
        got={p['DESIGNATOR']:(p['NAME'],int(p.get('ELECTRICAL',0))) for p in pins}
        a.check(got=={str(p['number']):(p['name'],p['type']) for p in part['pins']},ref+': SchLib pin map')
        params={r.get('NAME'):r.get('TEXT','') for r in rows if r.get('RECORD')=='41'}
        for key,value in part.get('parameters',{}).items():
            if key!='Role': a.check(params.get(key)==value,ref+': SchLib parameter '+key)
        primitives=pcb[part['footprint']]
        pads=[p for p in primitives if p['kind']=='Pad' and p['plated']]
        holes=[p for p in primitives if p['kind']=='Pad' and not p['plated']]
        unique(a,[p['number'] for p in pads],ref+' PcbLib pad designators')
        expected={str(p['number']):p for p in part['pcb_footprint']['pads']}
        a.check({p['number'] for p in pads}==set(expected),ref+': PcbLib electrical pad set')
        for pad in pads:
            if pad['number'] not in expected: continue
            want=expected[pad['number']]; label=ref+'.'+pad['number']
            for key in ('x','y','sx','sy','drill'):
                a.check(close(pad[key],want.get(key,0)),label+': library '+key+' differs from reviewed footprint')
            a.check(pad['shape']=={'ROUND':1,'RECTANGLE':2,'OCTAGON':3}[want.get('shape','RECTANGLE')],label+': library pad shape')
            a.check(pad['layer']==(74 if want.get('drill') else 1),label+': library pad layer')
            length=want.get('drill_slot_length_mm',0)
            a.check(pad['slot_type']==(2 if length else 0) and close(pad['slot_length'],length),label+': library slot length/type')
            a.check(close(pad['slot_angle'],want.get('drill_slot_angle_deg',0)),label+': library slot angle')
            if want.get('paste') is False or want.get('drill'):
                a.check(pad['paste_disabled'],label+': library must suppress solder paste')
        expected_holes=part['pcb_footprint'].get('holes',[])
        a.check(len(holes)==len(expected_holes),ref+': library NPTH count')
        for hole in expected_holes:
            a.check(any(all(close(p[k],hole[k]) for k in ('x','y','drill')) and p['layer']==74 for p in holes),ref+': library NPTH geometry')
        bodies=[p for p in primitives if p['kind']=='ComponentBody']
        a.check(bool(bodies),ref+': no library 3D model')
        for body in bodies:
            props=body['properties']
            a.check(props.get('BODYPROJECTION')=='0',ref+': library body not top side')
            a.check(mm(props['OVERALLHEIGHT'])>mm(props['STANDOFFHEIGHT']),ref+': library body invalid height')
    return {'library_components':len(sch),'library_footprints':len(pcb)}


def check_rules(a,rows,data,allow_uniform_board_edge=False):
    rules={r['NAME']:r for r in rows if r.get('RECORD')=='DXPRule'}
    required={'Clearance','Width','ShortCircuit','UnRoutedNet','TentedVias','PadSolderMask',
              'MinimumSolderMaskSliver','RoutingVias','ComponentClearance'}
    a.check(required<=set(rules),'Missing modern DXP native design rules')
    cfg=data['routing_constraints']; manufacturing=data.get('manufacturing',{})
    if 'Clearance' in rules:
        a.check(close(mm(rules['Clearance']['GAP']),cfg['clearance']),'Native clearance rule differs from routed requirement')
    if 'Width' in rules:
        a.check(close(mm(rules['Width']['MINLIMIT']),cfg['signal_width']),'Native minimum width differs from routed requirement')
    if 'ShortCircuit' in rules: a.check(rules['ShortCircuit'].get('ALLOWED')=='FALSE','Short circuits allowed by native rule')
    if 'TentedVias' in rules:
        r=rules['TentedVias']
        a.check(r.get('SCOPE1EXPRESSION')=='IsVia' and r.get('PRIORITY')=='1','Via mask scope/priority incorrect')
        a.check(mm(r['EXPANSION'])<=-cfg['via_diameter']/2+TOL,'Via mask expansion does not fully close via')
    if 'PadSolderMask' in rules:
        r=rules['PadSolderMask']
        a.check(r.get('PRIORITY')=='2','Pad mask priority overrides via tenting')
        a.check(close(mm(r['EXPANSION']),manufacturing.get('mask_expansion_mm',.05)),'Native pad mask differs from manufactured mask')
    if 'MinimumSolderMaskSliver' in rules:
        a.check(mm(rules['MinimumSolderMaskSliver']['MINSOLDERMASKWIDTH'])>=.099,'Native mask web rule is below 0.1 mm')
    if 'RoutingVias' in rules:
        r=rules['RoutingVias']
        a.check(close(mm(r['HOLEWIDTH']),cfg['via_drill']) and close(mm(r['WIDTH']),cfg['via_diameter']),
                'Native via geometry differs from router')
    isolation=[r for r in rules.values() if r.get('RULEKIND')=='Clearance' and mm(r.get('GAP','0mil'))>=3.199]
    a.check(bool(isolation),'Native rules omit the 3.2 mm BUS/LOGIC isolation constraint')
    for r in isolation:
        a.check(r.get('SCOPE1EXPRESSION','All')!='All' and r.get('SCOPE2EXPRESSION','All')!='All',
                'Isolation rule must explicitly scope both electrical domains')
        first=set(re.findall(r"InNet\('([^']+)'\)",r.get('SCOPE1EXPRESSION','')))
        second=set(re.findall(r"InNet\('([^']+)'\)",r.get('SCOPE2EXPRESSION','')))
        nets=set(expected_nets(data))
        a.check((first==nets&BUS_NETS and second==nets-BUS_NETS)
                or (second==nets&BUS_NETS and first==nets-BUS_NETS),
                'Isolation rule does not cover exactly the BUS and LOGIC net domains')
    for name,kind,key,value,scope in (
        ('PTH_AnnularRing','MinimumAnnularRing','MINIMUMRING',.18,"IsPad And (PadIsPlated = 'True')"),
        ('Via_AnnularRing','MinimumAnnularRing','MINIMUMRING',.15,'IsVia'),
        ('HoleToHoleClearance','HoleToHoleClearance','GAP',.25,None),
        ('BoardEdge_0_30mm','BoardOutlineClearance','GAP',.3,None),
        ('Paste_1to1','PasteMaskExpansion','EXPANSION',0,None),
        ('Mounting_NPTH','Clearance','GAP',1.7,None),
        ('Switch_Locating_Holes','Clearance','GAP',.25,None),
        ('R5_Legend_Clearance','SilkToSolderMaskClearance','MINSILKSCREENTOMASKGAP',.15,'IsPad'),
        ('SilkToSilk','SilkToSilkClearance','SILKTOSILKCLEARANCE',.1,None)):
        a.check(name in rules,'Missing native manufacturing rule '+name)
        if name not in rules:continue
        r=rules[name]
        a.check(r.get('RULEKIND')==kind and close(mm(r.get(key,'0mil')),value),name+': wrong native manufacturing constraint')
        if scope:a.check(r.get('SCOPE1EXPRESSION')==scope,name+': wrong native rule scope')
    if 'ComponentClearance' in rules:
        r=rules['ComponentClearance']
        a.check(close(mm(r['GAP']),.25) and close(mm(r.get('VERTICALGAP','0mil')),.25),
                'Native horizontal/vertical component clearance must be 0.25 mm')
        a.check(r.get('COLLISIONCHECKMODE')=='3','Native component clearance must use actual 3D component bodies')
    if 'HoleSize' in rules:
        a.check(close(mm(rules['HoleSize']['MINLIMIT']),.3) and close(mm(rules['HoleSize']['MAXLIMIT']),6.3),
                'Native drill-size rule differs from selected 0.3–6.3 mm')
    else:a.check(False,'Missing native HoleSize rule')
    for name in ('Mounting_NPTH','Switch_Locating_Holes'):
        if name in rules:
            scope=re.sub(r'\s+','',rules[name].get('SCOPE1EXPRESSION',''))
            a.check('HoleSize>0' in scope,name+': scope also selects SMD pads without positive drilled-hole test')
    if 'BoardEdge_0_30mm' in rules:
        matrix={k:int(v) for term in re.split(r'[,;]',rules['BoardEdge_0_30mm'].get('OBJECTCLEARANCES',''))
                if ':' in term for k,v in [term.split(':',1)]}
        if not matrix and allow_uniform_board_edge:
            a.check(close(mm(rules['BoardEdge_0_30mm'].get('GENERICCLEARANCE','0mil')),.3),
                    'Behaviorally verified uniform board-edge rule is not restored to 0.30 mm')
        else:
            for edge in ('OutlineEdge','CavityEdge','CutoutEdge'):
                for obj in ('Arc','Track','SMDPad','THPad','Via','Fill','Poly','Region','Text'):
                    key=f'ClearanceObj_{obj}-ClearanceObj_{edge}'
                    a.check(key in matrix and close(matrix.get(key,0)*.0254/10000,.3),
                            'Native board-edge clearance matrix missing/incorrect: '+key)
    return rules


def check_pcb(a,path,data,model):
    rows=records(path)
    a.check(rows[0].get('RECORD')=='Board' and rows[0].get('KIND')=='Protel_Advanced_PCB','Wrong native PCB source format')
    rules=check_rules(a,rows,data)
    nets={r['ID']:r['NAME'] for r in rows if r.get('RECORD')=='Net'}
    components={r['ID']:r for r in rows if r.get('RECORD')=='Component'}
    unique(a,[r['SOURCEDESIGNATOR'] for r in components.values()],'PCB references')
    unique(a,list(nets.values()),'PCB net names')
    a.check(set(nets.values())==set(expected_nets(data)),'PCB net names differ from model')
    a.check({r['SOURCEDESIGNATOR'] for r in components.values()}==set(model),'PCB component set differs from model')
    unique(a,[r.get('SOURCEUNIQUEID') for r in components.values()],'PCB source UIDs')
    for row in components.values():
        ref=row['SOURCEDESIGNATOR']
        if ref not in model: continue
        p=model[ref]
        a.check(row.get('SOURCEUNIQUEID','').lstrip('\\')==p['uid'],ref+': schematic/PCB UID mismatch')
        a.check(row.get('SOURCEHIERARCHICALPATH')==p['sheet'],ref+': PCB source sheet mismatch')
        a.check(row.get('PATTERN')==p['footprint'],ref+': PCB footprint mismatch')
        a.check(row.get('SOURCELIBREFERENCE')==p['libref'],ref+': PCB library reference mismatch')
        a.check(row.get('SOURCECOMPONENTLIBRARY')==SCHLIB and row.get('SOURCEFOOTPRINTLIBRARY')==PCBLIB,
                ref+': PCB library references are not local')
        for key in ('x','y'):
            a.check(close(mm(row[key.upper()]),p['pcb'][key]),ref+': PCB placement differs on '+key)
        a.check(close(float(row.get('ROTATION',0))%360,p['pcb'].get('rotation',0)%360),ref+': PCB rotation differs')
    comments={r['COMPONENT']:r['TEXT'] for r in rows if r.get('RECORD')=='Text' and r.get('COMMENT')=='TRUE'}
    for cid,c in components.items():
        if c['SOURCEDESIGNATOR'] in model:
            a.check(comments.get(cid)==model[c['SOURCEDESIGNATOR']]['value'],c['SOURCEDESIGNATOR']+': PCB value/comment missing')
    actual=defaultdict(dict); items=[]; holes=[]; drills=[]; bodies=defaultdict(list); mask=[]
    counts=Counter(); annuli=[]
    maskexp=data.get('manufacturing',{}).get('mask_expansion_mm',.05)
    for index,r in enumerate(rows):
        kind=r.get('RECORD'); layer=r.get('LAYER'); counts[kind]+=1
        net=nets.get(r.get('NET'))
        if kind=='Pad':
            x,y,sx,sy,drill=[mm(r.get(k,'0mil')) for k in ('X','Y','XSIZE','YSIZE','HOLESIZE')]
            rotation=float(r.get('ROTATION',0)); plated=r.get('PLATED')!='FALSE'
            slot=mm(r.get('HOLEWIDTH','0mil')) if r.get('HOLETYPE')=='2' else 0
            hole=hole_shape(x,y,drill,slot,rotation+float(r.get('HOLEROTATION',0))) if drill else None
            ref=components.get(r.get('COMPONENT'),{}).get('SOURCEDESIGNATOR')
            if hole is not None:drills.append(dict(label=f"{ref}.{r.get('NAME','')}",geometry=hole))
            if not plated:
                a.check(net is None,'NPTH has an electrical net')
                a.check(drill>0,'NPTH has no drill diameter')
                holes.append(dict(ref=ref,x=x,y=y,drill=drill,slot=slot,geometry=hole))
                continue
            a.check(ref in model,'Electrical PCB pad has no valid component')
            if ref not in model: continue
            number=r.get('NAME',''); label=ref+'.'+number
            a.check(number not in actual[ref],label+': duplicate electrical pad')
            actual[ref][number]=r
            pins={str(p['number']):p for p in model[ref]['pins']}
            a.check(number in pins,label+': unknown PCB pad')
            if number in pins: a.check(net==pins[number]['net'],label+': actual PCB net differs from pin net')
            a.check(sx>0 and sy>0,label+': pad size must be positive')
            geom=pad_shape(x,y,sx,sy,r.get('SHAPE'),rotation)
            item=dict(net=net,layers=LAYERS if drill else (layer,),geometry=geom,kind='pad',label=label,ref=ref)
            items.append(item)
            if hole is not None:
                a.check(geom.covers(hole.buffer(-.00001)),label+': plated drill lies outside copper')
                annulus=geom.boundary.distance(hole)
                annuli.append(annulus)
                a.check(annulus>=.1799,label+f': plated pad annulus only {annulus:.4f} mm (requires 0.18)')
                a.check(drill>=.1999,label+': plated drill below selected manufacturing minimum')
            want=next((p for p in model[ref]['pcb_footprint']['pads'] if str(p['number'])==number),None)
            if want:
                point=transform(model[ref],Point(want['x'],want['y']))
                for key,got,expected in [('X',x,point.x),('Y',y,point.y),('XSIZE',sx,want['sx']),
                                        ('YSIZE',sy,want['sy']),('HOLESIZE',drill,want.get('drill',0))]:
                    a.check(close(got,expected),label+': native '+key+' differs from reviewed land pattern')
                a.check(r.get('SHAPE')==want.get('shape','RECTANGLE'),label+': native pad shape mismatch')
                a.check(close(rotation%360,model[ref]['pcb'].get('rotation',0)%360),label+': native pad rotation mismatch')
                a.check(close(slot,want.get('drill_slot_length_mm',0)),label+': native slot length mismatch')
                a.check(close(float(r.get('HOLEROTATION',0)),want.get('drill_slot_angle_deg',0)),label+': native slot angle mismatch')
                a.check(layer==('MULTILAYER' if drill else 'TOP'),label+': native pad layer mismatch')
                no_paste=bool(drill) or want.get('paste') is False or model[ref].get('assembly',{}).get('populate') is False
                paste_mode=r.get('PASTEMASKEXPANSIONMODE')
                paste_closed=paste_mode=='None' or (paste_mode=='Manual' and
                    mm(r.get('PASTEMASKEXPANSION_MANUAL','0mil'))<=-max(sx,sy)/2)
                a.check(paste_closed==no_paste,label+': native paste aperture mode')
            mode=r.get('SOLDERMASKEXPANSIONMODE')
            expansion=mm(r.get('SOLDERMASKEXPANSION_MANUAL','0mil')) if mode=='Manual' else maskexp
            a.check(mode in ('Manual','Rule'),label+': unknown mask expansion mode')
            mask.append(dict(label=label,ref=ref,net=net,layers=item['layers'],geometry=geom.buffer(expansion,join_style=2)))
        elif kind=='Track' and layer in LAYERS:
            a.check(net is not None,'Unnetted copper track')
            width=mm(r['WIDTH'])
            # width_by_net is the autorouter's preferred bulk width; manually
            # routed feedback/pull-up branches legitimately use signal width.
            # High-current supply-path continuity is checked separately below.
            required=.15 if str(net).startswith(('USB_D','USB_CC')) else data['routing_constraints']['signal_width']
            a.check(width>=required-TOL,'Native copper track below required width: '+str(net))
            geom=LineString([(mm(r['X1']),mm(r['Y1'])),(mm(r['X2']),mm(r['Y2']))]).buffer(width/2,quad_segs=32)
            items.append(dict(net=net,layers=(layer,),geometry=geom,kind='track',label='T'+str(index),width=width))
        elif kind=='Via':
            a.check(net is not None,'Unnetted copper via')
            diameter,drill=mm(r['DIAMETER']),mm(r['HOLESIZE'])
            a.check((diameter-drill)/2>=.1499,'Via annulus below 0.15 mm')
            a.check(drill>=.2999,'Via drill below selected 0.3 mm manufacturing rule')
            a.check(r.get('TENTINGTOP')==r.get('TENTINGBOTTOM')=='TRUE','Via is not tented on both sides')
            a.check(r.get('CSEV')=='2' and mm(r.get('CSE','0mil'))<=-diameter/2+TOL,'Via manual mask cache not closed')
            drills.append(dict(label='V'+str(index),geometry=Point(mm(r['X']),mm(r['Y'])).buffer(drill/2,quad_segs=64)))
            items.append(dict(net=net,layers=LAYERS,geometry=Point(mm(r['X']),mm(r['Y'])).buffer(diameter/2,quad_segs=64),
                              kind='via',label='V'+str(index)))
        elif kind in ('Region','Fill') and layer in LAYERS:
            if kind!='Region':
                a.check(False,'Unsupported copper Fill requires independent geometry implementation');continue
            a.check(net is not None,'Unnetted copper region')
            a.check(int(r.get('HOLECOUNT',0))==0,'Copper region with holes requires explicit readback support')
            pts=[(mm(r[f'VX{i}']),mm(r[f'VY{i}'])) for i in range(int(r['MAINCONTOURVERTEXCOUNT']))]
            geom=Polygon(pts)
            a.check(geom.is_valid and not geom.is_empty,'Invalid actual copper region')
            items.append(dict(net=net,layers=(layer,),geometry=geom,kind='region',label='R'+str(index)))
        elif kind=='Arc' and layer in LAYERS:
            a.check(False,'Copper arc requires explicit independent readback support')
        elif kind=='ComponentBody':
            ref=components.get(r.get('COMPONENT'),{}).get('SOURCEDESIGNATOR')
            a.check(ref in model,'3D body has no valid component')
            a.check(r.get('BODYPROJECTION')=='0','3D body projects to bottom')
            a.check(mm(r['OVERALLHEIGHT'])>mm(r['STANDOFFHEIGHT']),'3D body has invalid height')
            a.check(r.get('MODEL.EMBED')=='FALSE','Unexpected embedded external 3D payload')
            points=[(mm(r[f'VX{i}']),mm(r[f'VY{i}'])) for i in range(int(r['MAINCONTOURVERTEXCOUNT']))]
            bodies[ref].append(dict(geometry=Polygon(points),z0=mm(r['STANDOFFHEIGHT']),z1=mm(r['OVERALLHEIGHT'])))
    for ref,part in model.items():
        a.check(set(actual[ref])=={str(p['number']) for p in part['pins']},ref+': actual PCB pad set differs from schematic')
        a.check(bool(bodies[ref]),ref+': missing actual 3D model')
        wants=part.get('bodies_3d',[])
        if wants:
            a.check(len(bodies[ref])==len(wants),ref+': native body count differs')
            for want in wants:
                poly=transform(part,Polygon(want['outline']))
                a.check(any(close(b['z0'],want['z0']) and close(b['z1'],want['z1'])
                            and poly.hausdorff_distance(b['geometry'])<TOL for b in bodies[ref]),ref+': native 3D body geometry mismatch')
    expected_holes=[]
    for x,y in data['board'].get('holes_mm',[]):
        expected_holes.append(dict(x=x,y=y,drill=data['board'].get('hole_diameter_mm',2.2),ref=None))
    for ref,part in model.items():
        for hole in part['pcb_footprint'].get('holes',[]):
            point=transform(part,Point(hole['x'],hole['y']))
            expected_holes.append(dict(x=point.x,y=point.y,drill=hole['drill'],ref=ref))
    a.check(len(holes)==len(expected_holes),'Actual NPTH count differs from mounting and component holes')
    for want in expected_holes:
        a.check(any(all(close(h[k],want[k]) for k in ('x','y','drill')) for h in holes),
                f"Missing NPTH {want['ref']} at ({want['x']:.3f}, {want['y']:.3f})")
    boardprops={}
    for row in rows:
        if row.get('RECORD')=='Board':boardprops.update(row)
    points=[];i=0
    while f'VX{i}' in boardprops:
        points.append((mm(boardprops[f'VX{i}']),mm(boardprops[f'VY{i}'])))
        a.check(boardprops.get(f'KIND{i}','0')=='0','Board arc contour requires explicit native arc readback')
        i+=1
    a.check(len(points)>8,'R5 native outline lacks rounded corner vertices')
    exterior=Polygon(points)
    a.check(exterior.is_valid,'Native board contour invalid')
    a.check(points[0]==points[-1],'Native board contour is not explicitly closed')
    ideal,ideal_holes=reviewed_profile(data['board'])
    a.check(ideal.hausdorff_distance(exterior)<.015,'Native outline differs from reviewed rounded notched board')
    declared=Polygon(data['board']['outline_points_mm'])
    a.check(declared.hausdorff_distance(exterior)<TOL,'Native outline differs from declared source profile')
    cutouts=[]
    for r in rows:
        if r.get('RECORD')!='Region' or r.get('ISBOARDCUTOUT')!='TRUE':continue
        a.check(r.get('LAYER')=='MULTILAYER' and r.get('KIND')=='0','Actual board cutout must be multilayer KIND0 plus ISBOARDCUTOUT=TRUE')
        contour=[(mm(r[f'VX{i}']),mm(r[f'VY{i}'])) for i in range(int(r['MAINCONTOURVERTEXCOUNT']))]
        shape=Polygon(contour)
        a.check(shape.is_valid and exterior.contains(shape),'Actual native routed window invalid or outside board')
        cutouts.append(shape)
    a.check(len(cutouts)==len(data['board'].get('cutouts_mm',[]))==len(ideal_holes)==1,'R5 requires exactly one actual board cutout')
    for expected in ideal_holes:
        a.check(any(expected.hausdorff_distance(g)<.015 for g in cutouts),'Actual routed window differs from reviewed feature')
    for expected in data['board'].get('cutouts_mm',[]):
        shape=Polygon(expected['outline_points_mm'])
        a.check(any(shape.hausdorff_distance(g)<TOL for g in cutouts),'Actual board cutout differs from declared source contour')
    outline=exterior.difference(unary_union(cutouts))
    check_declared_text_records(a,rows,data)
    a.check(boardprops.get('LAYER1NEXT')=='32' and boardprops.get('LAYER32PREV')=='1'
            and boardprops.get('LAYER32NEXT')=='0','Native board stack must contain two copper layers')
    for i in range(2,32):
        a.check(boardprops.get(f'LAYER{i}PREV','0')==boardprops.get(f'LAYER{i}NEXT','0')=='0','Unexpected active internal copper layer')
    return dict(rows=rows,items=items,holes=holes,drills=drills,bodies=bodies,mask=mask,outline=outline,
                counts=dict(counts),min_annulus=min(annuli) if annuli else None,rules=rules,
                exterior=exterior,cutouts=cutouts)


def check_declared_text_records(a,rows,data):
    texts=[r for r in rows if r.get('RECORD')=='Text' and r.get('LAYER') in ('TOPOVERLAY','BOTTOMOVERLAY')
           and r.get('TEXT',r.get('STRING','')) and r.get('HIDDEN')!='TRUE']
    expected=data['board'].get('native_texts',[])
    a.check(len(texts)==len(expected),'Visible native source Text count differs from declared TTF labels')
    unmatched=list(texts)
    for want in expected:
        layer={'TOP':'TOPOVERLAY','BOTTOM':'BOTTOMOVERLAY'}.get(want.get('layer','TOP'),want.get('layer'))
        candidates=[r for r in unmatched if r.get('TEXT')==want['text'] and r.get('LAYER')==layer
                    and close(mm(r['X']),want['x']) and close(mm(r['Y']),want['y'])]
        a.check(len(candidates)==1,'Native source TTF label missing/duplicated: '+want['text'])
        if not candidates:continue
        r=candidates[0];unmatched.remove(r)
        a.check(r.get('USETTFONTS')=='TRUE','PCB label is not an actual TrueType Text object: '+want['text'])
        a.check(r.get('FONTNAME')=='Arial Rounded MT Bold','PCB label changed selected rounded typeface: '+want['text'])
        a.check(close(mm(r['HEIGHT']),want['height']) and close(float(r.get('ROTATION',0))%360,want.get('rotation',0)%360),
                'PCB TTF label height/rotation differs: '+want['text'])
        a.check((r.get('MIRROR')=='TRUE')==want.get('mirror',layer=='BOTTOMOVERLAY'),'PCB TTF mirror differs: '+want['text'])


def check_geometry(a,data,model,pcb):
    items=pcb['items']; cfg=data['routing_constraints']; errors=[]
    geometries=[it['geometry'] for it in items];tree=STRtree(geometries)
    parents=list(range(len(items)))
    def find(i):
        while parents[i]!=i:parents[i]=parents[parents[i]];i=parents[i]
        return i
    def union(i,j):parents[find(i)]=find(j)
    minimum=math.inf
    for i,first in enumerate(items):
        for j in tree.query(first['geometry'].buffer(max(2.,cfg['clearance']+.01))):
            j=int(j)
            if j<=i:continue
            second=items[j]
            if not set(first['layers']).intersection(second['layers']):continue
            distance=first['geometry'].distance(second['geometry'])
            if first['net'] is not None and first['net']==second['net']:
                if distance<1e-6:union(i,j)
            else:
                minimum=min(minimum,distance)
                if distance<cfg['clearance']-1e-5:
                    errors.append(f"Copper clearance {first['label']} / {second['label']}: {distance:.4f} mm")
    groups=defaultdict(lambda:defaultdict(list))
    for i,it in enumerate(items):
        if it['net'] and it['kind']=='pad':groups[it['net']][find(i)].append(it['label'])
    for net,connected in groups.items():
        if len(connected)>1:errors.append(f'Unrouted {net}: {list(connected.values())}')
    for i,it in enumerate(items):
        if it['net'] and it['kind']!='pad' and find(i) not in groups[it['net']]:
            errors.append('Orphan native copper '+it['label']+' on '+it['net'])
    power_paths=[]
    for net,first,last,width in (
            ('NET_S','J1.2','F1.1',.4),('FUSED_IN','F1.2','D5.2',.4),
            ('BUS_PROT','D5.1','U3.3',.4),('SW_BUS','U3.5','L2.1',.4),
            ('5V_BUS','L2.2','U2.1',.4),('5V_BUS','L2.2','U1.8',.4),
            ('5V_ISO','U2.6','U4.3',.4),('SW_LOGIC','U4.5','L3.1',.4),
            ('5V_REG','L3.2','C32.1',.4),('5V_REG','C32.1','SW3.1',.4),
            ('5V_MODULE','SW3.2','MCU1.5V',.4),('3V3_LOGIC','MCU1.3V3','U1.1',.2)):
        eligible=[i for i,it in enumerate(items) if it['net']==net and
                  (it['kind']!='track' or it.get('width',0)>=width-TOL)]
        remaining=set(eligible);source=next((i for i in eligible if items[i]['label']==first),None)
        destination=next((i for i in eligible if items[i]['label']==last),None)
        visited=set();queue=[] if source is None else [source]
        while queue:
            i=queue.pop()
            if i in visited:continue
            visited.add(i);remaining.discard(i)
            for j in tree.query(items[i]['geometry'].buffer(.000002)):
                j=int(j)
                if j in remaining and set(items[i]['layers']).intersection(items[j]['layers']) and items[i]['geometry'].distance(items[j]['geometry'])<1e-6:
                    queue.append(j)
        passed=destination is not None and destination in visited
        if not passed:errors.append(f'Main power path below reviewed {width:.2f} mm width or disconnected: {first} / {last}')
        power_paths.append(dict(net=net,start=first,end=last,minimum_track_width_mm=width,passed=passed))
    edge=cfg.get('edge_clearance',.3)
    allowed_board=pcb['outline'].buffer(-edge)
    for it in items:
        if not allowed_board.buffer(1e-5).covers(it['geometry']):errors.append('Copper too close to rounded board edge: '+it['label'])
        for hole in pcb['holes']:
            distance=it['geometry'].distance(hole['geometry'])
            required=cfg.get('component_hole_clearance',{}).get(hole['ref'],cfg.get('hole_clearance',.25))
            if required<.1999:errors.append('Unreviewed component NPTH clearance below 0.20 mm')
            if distance<required-1e-5:
                errors.append(f"Copper too close to NPTH: {it['label']} / {hole['ref']}, {distance:.4f} mm")
        for keep in cfg.get('keepouts',[]):
            if it['net'] in keep.get('allowed_nets',[]):continue
            if not set(it['layers']).intersection(keep.get('layers',LAYERS)):continue
            if it['geometry'].intersection(box(keep['x1'],keep['y1'],keep['x2'],keep['y2'])).area>1e-7:
                errors.append('Copper enters keepout '+keep.get('name','unnamed')+': '+it['label'])
        if it['net'] in cfg.get('net_regions',{}):
            if not box(*cfg['net_regions'][it['net']]).buffer(1e-5).covers(it['geometry']):
                errors.append('Copper crosses domain boundary: '+it['label'])
    drills=pcb.get('drills',[])
    for i,first in enumerate(drills):
        for second in drills[i+1:]:
            distance=first['geometry'].distance(second['geometry'])
            if distance<.2499:
                errors.append(f"Drill-to-drill clearance {first['label']} / {second['label']}: {distance:.4f} mm")
    bus=unary_union([it['geometry'] for it in items if it['net'] in BUS_NETS])
    logic=unary_union([it['geometry'] for it in items if it['net'] and it['net'] not in BUS_NETS])
    isolation=bus.distance(logic)
    if isolation<3.1999:errors.append(f'BUS/LOGIC projected copper separation only {isolation:.4f} mm (required 3.2)')
    # Recompute actual body clearance; cached placement reports are not evidence.
    # The manually soldered SuperMini remains a real assembled physical body.
    populated=[p for p in model.values() if p.get('assembly',{}).get('populate') or p['ref']=='MCU1']
    body_polys={}
    for part in populated:
        width,height=part['pcb_footprint']['body']
        envelope=transform(part,box(-width/2,-height/2,width/2,height/2))
        body_polys[part['ref']]=envelope
    body_min=math.inf;native_body_min=math.inf
    body_clear=cfg.get('component_clearance',data.get('manufacturing',{}).get('component_clearance_mm',.25))
    for i,part in enumerate(populated):
        ref=part['ref'];poly=body_polys[ref]
        if not pcb['outline'].buffer(1e-5).covers(poly) and not part.get('allow_body_overhang'):
            errors.append('Populated body outside rounded board: '+ref)
        if part.get('allow_body_overhang') and ref not in ('MCU1','SW3'):
            errors.append('Unreviewed body-overhang exception: '+ref)
        for other in populated[i+1:]:
            distance=poly.distance(body_polys[other['ref']]);body_min=min(body_min,distance)
            required=body_clear if any('0603' in p['footprint'] for p in (part,other)) else cfg.get('large_component_clearance',.5)
            if distance<required-1e-5:
                errors.append(f"Body clearance {ref} / {other['ref']}: {distance:.4f} mm")
            # Extruded native models include metal terminals as well as the
            # nominal plastic envelope. Match the effective ComponentBody
            # clearance check in three dimensions instead of checking only
            # projected overlap, which missed real <0.25 mm terminal gaps.
            native_distance=math.inf
            for first in pcb['bodies'][ref]:
                for second in pcb['bodies'][other['ref']]:
                    dz=max(0,first['z0']-second['z1'],second['z0']-first['z1'])
                    dxy=first['geometry'].distance(second['geometry'])
                    native_distance=min(native_distance,math.hypot(dxy,dz))
            native_body_min=min(native_body_min,native_distance)
            if native_distance<body_clear-1e-5:
                errors.append(f"Native 3D body clearance {ref} / {other['ref']}: {native_distance:.4f} mm")
        for item in items:
            if item['kind']!='pad' or item.get('ref')==ref:continue
            if poly.distance(item['geometry'])<cfg.get('pad_body_clearance',.15)-1e-5:
                errors.append(f"Other-component pad/body clearance: {item['label']} / {ref}")
        for hole in pcb['holes']:
            if hole['ref']==ref:continue
            # Component alignment holes belong under their own connector.
            if poly.distance(hole['geometry'])<.2499:
                errors.append('Body encroaches mounting/alignment hole: '+ref)
    for hole in pcb['holes']:
        if hole['ref'] is not None:continue
        head=Point(hole['x'],hole['y']).buffer(data['board'].get('mounting_courtyard_diameter_mm',5.6)/2,quad_segs=64)
        for ref,poly in body_polys.items():
            if poly.intersection(head).area>1e-7:errors.append('Package under mounting screw head: '+ref)
        for item in items:
            if item['kind']=='pad' and item['geometry'].intersection(head).area>1e-7:
                errors.append('Solder pad under mounting screw head: '+item['label'])
    mcu=model['MCU1']
    antenna=transform(mcu,box(-6,-13.76,6,-5.5))
    ceramic=transform(mcu,box(-3.5,-11.1,3.5,-8.8))
    a.check(ceramic.intersection(pcb['outline']).area<1e-5,'SuperMini ceramic antenna does not lie over actual routed air window')
    for body in mcu.get('bodies_3d',[]):
        if body['z0']<0:
            shape=transform(mcu,Polygon(body['outline']))
            a.check(shape.intersection(pcb['outline']).area<1e-5,'SuperMini USB underside tail intersects carrier material')
    for it in items:
        if it['geometry'].intersection(antenna).area>1e-7:errors.append('Copper inside SuperMini RF reservation: '+it['label'])
    for ref,poly in body_polys.items():
        if ref!='MCU1' and poly.intersection(antenna).area>1e-7:errors.append('Body inside SuperMini RF reservation: '+ref)
    # Solder-mask web is measured from actual pad shape/rotation and effective
    # expansion; same-net touching apertures are intentionally one opening.
    openings=pcb['mask']; maskmin=math.inf; masktree=STRtree([o['geometry'] for o in openings])
    for i,first in enumerate(openings):
        for j in masktree.query(first['geometry'].buffer(.11)):
            j=int(j)
            if j<=i:continue
            second=openings[j]
            if not set(first['layers']).intersection(second['layers']):continue
            distance=first['geometry'].distance(second['geometry'])
            if distance<1e-5 and first['net'] and first['net']==second['net']:continue
            maskmin=min(maskmin,distance)
            if distance<.0999:errors.append(f"Solder mask web {first['label']} / {second['label']}: {distance:.4f} mm")
    a.check(not errors,'Native geometric audit has findings')
    a.errors.extend(errors)
    return {'passed':not errors,'errors':errors,'connected_nets':sum(len(g)==1 for g in groups.values()),
            'main_supply_paths':power_paths,
            'total_nets':len(groups),'minimum_copper_clearance_mm':None if math.isinf(minimum) else round(minimum,6),
            'minimum_domain_separation_mm':round(isolation,6),
            'minimum_body_clearance_mm':None if math.isinf(body_min) else round(body_min,6),
            'minimum_native_3d_body_clearance_mm':None if math.isinf(native_body_min) else round(native_body_min,6),
            'minimum_mask_web_mm':None if math.isinf(maskmin) else round(maskmin,6),
            'minimum_plated_annulus_mm':pcb['min_annulus'],
            'npth_holes':len(pcb['holes']),
            'method':'Independent decoded PCB pad/track/via/region/body geometry, native slot angles and component NPTH; connectivity across plated pads and vias.'}


def check_assembly(a,root,model,bom_path=None,cpl_path=None):
    """Check uploaded assembly CSV content, not merely source availability flags."""
    root=Path(root).resolve()
    populated={ref:p for ref,p in model.items() if p.get('assembly',{}).get('populate')}
    def locate(explicit,needle):
        if explicit:return Path(explicit).resolve()
        preferred=list(root.rglob(needle.upper()+'-JLCPCB.csv'))
        if len(preferred)==1:return preferred[0]
        candidates=[p for p in root.rglob('*.csv') if needle in p.stem.lower()
                    and not any(s in str(p).lower() for s in ('draft','archive','unresolved','excluded'))]
        if len(candidates)!=1:raise ValueError(f'Expected one final {needle.upper()} CSV, found {len(candidates)}; specify --{needle}')
        return candidates[0]
    bom_path=locate(bom_path,'bom');cpl_path=locate(cpl_path,'cpl')
    bom=list(csv.DictReader(bom_path.open(encoding='utf-8-sig',newline='')))
    cpl=list(csv.DictReader(cpl_path.open(encoding='utf-8-sig',newline='')))
    a.check(bool(bom),'Empty assembly BOM');a.check(bool(cpl),'Empty assembly CPL')
    if bom:a.check({'Comment','Designator','Footprint','LCSC Part #'}<=set(bom[0]),'BOM missing JLCPCB required columns')
    if cpl:a.check({'Designator','Mid X','Mid Y','Layer','Rotation'}<=set(cpl[0]),'CPL missing JLCPCB required columns')
    seen=[]
    for row in bom:
        refs=[r.strip() for r in re.split(r'[,;\s]+',row.get('Designator','')) if r.strip()]
        seen.extend(refs)
        for ref in refs:
            a.check(ref in populated,'BOM contains an unexpected/unpopulated reference '+ref)
            if ref not in populated:continue
            p=populated[ref]
            a.check(row.get('LCSC Part #')==p['assembly']['lcsc'],ref+': BOM source code mismatch')
            a.check(row.get('Footprint')==p['footprint'],ref+': BOM footprint mismatch')
            a.check(row.get('Comment')==p['value'],ref+': BOM comment/value mismatch')
    unique(a,seen,'BOM populated references')
    a.check(set(seen)==set(populated),'BOM does not contain every populated component exactly once')
    seen=[]
    for row in cpl:
        ref=row.get('Designator','');seen.append(ref)
        a.check(ref in populated,'CPL contains unexpected/unpopulated reference '+ref)
        if ref not in populated:continue
        p=populated[ref];assembly=p['assembly']
        offset=assembly.get('centroid_offset_mm',[0,0]);angle=math.radians(p['pcb'].get('rotation',0))
        wantx=p['pcb']['x']+offset[0]*math.cos(angle)-offset[1]*math.sin(angle)
        wanty=p['pcb']['y']+offset[0]*math.sin(angle)+offset[1]*math.cos(angle)
        def number(key):return float(row[key].lower().replace('mm','').strip())
        a.check(close(number('Mid X'),wantx) and close(number('Mid Y'),wanty),ref+': CPL centroid mismatch')
        wantrot=(p['pcb'].get('rotation',0)+assembly.get('rotation_offset_deg',0))%360
        a.check(close(number('Rotation')%360,wantrot),ref+': CPL orientation differs from declared package mapping')
        a.check(row.get('Layer','').lower()=='top',ref+': CPL assembly side must be top')
    unique(a,seen,'CPL populated references')
    a.check(set(seen)==set(populated),'CPL does not contain every populated component exactly once')
    unresolved=bom_path.parent/'BOM-UNRESOLVED.csv'
    if unresolved.is_file():
        rows=list(csv.DictReader(unresolved.open(encoding='utf-8-sig',newline='')))
        a.check(not rows,'Assembly export still contains unresolved required components')
    return {'populated_components':len(populated),'bom_file':str(bom_path.relative_to(root)),
            'cpl_file':str(cpl_path.relative_to(root)),'bom_rows':len(bom),'cpl_rows':len(cpl),
            'scope':'CSV data consistency only; sourcing stock and JLCPCB rotation preview are not checkout approvals.'}


def audit_native(root,model_only=False,schematics_only=False,bom_path=None,cpl_path=None):
    a=Audit();report={};read_files=[];binary=False
    scope='model_only' if model_only else 'schematics_and_libraries' if schematics_only else 'full_generated_package'
    def stage(name,fn):
        try:return fn()
        except Exception as error:
            a.errors.append(f'{name} could not complete: {type(error).__name__}: {error}')
            return None
    design_path=root/'orion-r5-design.json'
    try:data=json.loads(design_path.read_text(encoding='utf-8'))
    except (OSError,ValueError) as error:
        return {'passed':False,'release_checks_complete':False,'checks':0,'errors':[str(error)],'scope':scope}
    read_files.append(design_path)
    model=stage('Electrical/source model',lambda:check_model(a,data))
    if model is None:model={p['ref']:p for p in data['components']}
    report.update(components=len(model),nets=len(expected_nets(data)),
        manual_module='Original user-selected Amazon B0FN4F6244,16 castellation lands; excluded only from machine BOM/CPL, included in assembled geometry',
        service_switch={'RUN':['1','2'],'SERVICE':['2','3'],'service_contact_3':'unconnected',
            'intent':'Disconnect external 5V_MODULE supply before inserting USB; no simultaneous source promise.'})
    if not model_only:
        sheets=sorted({p['sheet'] for p in model.values()})
        schematic_counts={}
        for sheet in sheets:
            path=root/(sheet+'.SchDoc');subset={ref:p for ref,p in model.items() if p['sheet']==sheet}
            value=stage(sheet+' physical wires',lambda path=path,subset=subset:reference.check_schematic(a,path,subset))
            if value is not None:schematic_counts[sheet]=value;read_files.append(path)
            stage(sheet+' library links',lambda path=path,subset=subset:check_schematic_links(a,path,subset))
        report['schematic_records']=schematic_counts
        stage('Project document links',lambda:check_project(a,root/(STEM+'.PrjPcb'),sheets,schematics_only))
        read_files.append(root/(STEM+'.PrjPcb'))
        libs=stage('Native local libraries',lambda:check_libraries(a,root,model))
        if libs:report.update(libs);read_files.extend([root/SCHLIB,root/PCBLIB])
        if not schematics_only:
            pcb_path=root/(STEM+'.PcbDoc')
            binary=False
            if pcb_path.is_file() and pcb_path.read_bytes().startswith(CFB_MAGIC):
                pcb_path=root/'source'/(STEM+'.PcbDoc')
                binary=True
            pcb=stage('Native PCB readback',lambda:check_pcb(a,pcb_path,data,model))
            if pcb:
                read_files.append(pcb_path);report['pcb_readback_file']=str(pcb_path.relative_to(root))
                report['pcb_primitive_counts']=pcb['counts']
                report['copper_and_mechanical']=stage('Native exact geometry',lambda:check_geometry(a,data,model,pcb))
            report['assembly']=stage('Assembly output files',lambda:check_assembly(a,root,model,bom_path,cpl_path))
            if report['assembly']:
                read_files.extend(root/report['assembly'][key] for key in ('bom_file','cpl_file'))
            if binary:
                from verify_altium_binary_r5 import audit_binary
                report['native_binary']=stage('Saved native PCB binary',lambda:audit_binary(root))
                report['final_binary_checked']=bool(report['native_binary'] and report['native_binary']['passed'])
                if report['native_binary']:
                    a.check(report['native_binary']['passed'],'Saved native PCB binary readback has findings')
                    a.errors.extend(report['native_binary']['errors'])
                    read_files.append(root/(STEM+'.PcbDoc'))
    report.update(passed=not a.errors,release_checks_complete=not(model_only or schematics_only) and binary and not a.errors,
                  checks=a.checks,errors=a.errors,scope=scope,
                  qualification='Checks the generated package/source files only. Native Altium ERC/DRC, fabrication DFM, assembly orientation approval and hardware qualification are separate.')
    report['input_sha256']={str(path.relative_to(root)):hashlib.sha256(path.read_bytes()).hexdigest()
                            for path in read_files if path.is_file()}
    return report


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory',nargs='?',type=Path,default=ROOT/'hardware/altium-r5')
    mode=parser.add_mutually_exclusive_group()
    mode.add_argument('--model-only',action='store_true')
    mode.add_argument('--schematics-only',action='store_true')
    parser.add_argument('--bom',type=Path)
    parser.add_argument('--cpl',type=Path)
    parser.add_argument('--report',type=Path,help='Write JSON only to this explicitly chosen path')
    args=parser.parse_args()
    result=audit_native(args.directory,args.model_only,args.schematics_only,args.bom,args.cpl)
    if args.report:args.report.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,indent=2))
    return 0 if result['passed'] else 1


if __name__=='__main__':sys.exit(main())
