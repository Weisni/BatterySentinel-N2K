"""Native binary Altium component libraries for the Orion bridge.

The library records are based on the Altium AD25 supplied Harness Demo library
files, with independently generated geometry and metadata. CFB containers are
written by the installed OpenMCDF library; Altium is never launched. The native
binary primitive layouts can also be cross-checked against KiCad's importer:
https://dev-docs.kicad.org/en/import-formats/altium/index.html

Public API: enrich_components(data), component_parameters(part),
build_libraries(data, output_directory), read_cfb_streams(path).
"""
from __future__ import annotations

import base64
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile
import uuid

SCHLIB_NAME = 'Orion-Bridge.SchLib'
PCBLIB_NAME = 'Orion-Bridge.PcbLib'
OPENMCDF_DLL = Path(os.environ.get('ALTIUM_OPENMCDF_DLL',
    'C:/Program Files/Altium/AD25/System/OpenMCDF.dll'))


def _uid(text):
    return ''.join(chr(65+b % 26) for b in hashlib.sha256(text.encode()).digest()[:8])


def component_parameters(part):
    return {
        'Manufacturer': part.get('manufacturer',''),
        'MPN': part.get('mpn',''),
        'Manufacturer Part Number': part.get('mpn',''),
        'Description': part.get('description',part['value']),
        'Datasheet': part.get('datasheet',''),
        'Supplier 1': 'LCSC' if part.get('assembly',{}).get('lcsc_confirmed') else '',
        'Supplier Part Number 1': part.get('assembly',{}).get('lcsc','') if part.get('assembly',{}).get('lcsc_confirmed') else '',
        'Footprint Status': part['pcb']['status'],
    }


def enrich_components(data):
    """Add stable, value/part-based local library identifiers, in place.

    Unselected generic devices retain empty Manufacturer/MPN fields. Supplier
    choices remain empty for the user to populate. Role is instance metadata.
    """
    known = {
        'Q1': ('DMP6023LE','Diodes Incorporated','DMP6023LE',
               'https://www.diodes.com/datasheet/download/DMP6023LE.pdf'),
        'U1': ('ISO1042DWV','Texas Instruments','ISO1042DWV',
               'https://www.ti.com/lit/ds/symlink/iso1042.pdf'),
        'U2': ('R3M-2405S_SMD','RECOM','R3M-2405S/SMD',
               'https://recom-power.com/pdf/Econoline/R3M.pdf'),
        'U3': ('TPS7B6950QDCYRQ1','Texas Instruments','TPS7B6950QDCYRQ1',
               'https://www.ti.com/lit/ds/symlink/tps7b69-q1.pdf'),
        'L1': ('ACT45B5102PTL003','TDK','ACT45B5102PTL003',
               'https://www.tdk-electronics.tdk.com/inf/30/ds/act45b.pdf'),
        'D3': ('PESD2CAN24T-QR','Nexperia','PESD2CAN24T-QR',
               'https://assets.nexperia.com/documents/data-sheet/PESD2CAN24T-Q.pdf'),
    }
    generic = {
        'J1':'NMEA_PIGTAIL_5_P3_5', 'TP1':'TESTPOINT_2MM',
        'F1':'FUSE_T0_8A_60V_TBD', 'Z1':'BZT52C12_SOD123_GENERIC',
        'D1':'SMBJ20A_SMB_GENERIC', 'D2':'SS36_SMB_GENERIC',
        'R1':'R_0805_100K', 'R2':'R_0805_10K', 'R3':'R_0805_33R', 'R4':'R_0805_33R',
        'C1':'C_RADIAL_47UF_50V_D8_P2_5', 'C6':'C_RADIAL_47UF_10V_D6_3_P2_5',
        'C2':'C_0805_1UF_50V_X7R', 'C3':'C_1206_10UF_16V_X7R',
        'C4':'C_0805_100NF_16V_X7R', 'C5':'C_0805_100NF_16V_X7R',
        'C7':'C_0805_100NF_16V_X7R', 'C8':'C_1210_10UF_50V_X7R',
        'C9':'C_1210_10UF_50V_X7R', 'L2':'L_15UH_1A_5X5_TBD',
        'JP1':'JUMPER_1X2_P2_54', 'MCU1':'ESP32_C3_SUPERMINI_NOLOGO',
    }
    for part in data['components']:
        ref = part['ref']
        if ref in ('R3','R4'):
            part['value'] = '33R'
            part['role'] = 'R_TX' if ref == 'R3' else 'R_RX'
        if ref in ('C4','C5','C7') and not part.get('assembly',{}).get('lcsc_confirmed'):
            part['value'] = '100nF 16V X7R'
        if ref in known:
            libref,manufacturer,mpn,datasheet = known[ref]
        else:
            libref = generic.get(ref, re.sub('[^A-Z0-9_]+','_',part['value'].upper())[:31])
            manufacturer = mpn = datasheet = ''
        # Preserve explicitly provided module research and selected generic MPNs.
        part['libref'] = part.get('libref') or libref
        part.setdefault('manufacturer',manufacturer)
        part.setdefault('mpn',mpn)
        part.setdefault('datasheet',datasheet)
        part.setdefault('description', part['value'] + ('' if manufacturer else ' - generic specification; manufacturer/MPN not selected'))
        part['parameters'] = component_parameters(part)
        if part.get('role'):
            part['parameters']['Role'] = part['role']
    return data


def _psquote(value):
    return "'"+str(value).replace("'","''")+"'"


def _powershell(script):
    encoded = base64.b64encode(script.encode('utf-16le')).decode('ascii')
    # Altium's modern OpenMCDF build targets .NET Standard; use PowerShell 7's
    # .NET runtime rather than the legacy Windows PowerShell 5.1 runtime.
    executable = shutil.which('pwsh') or shutil.which('powershell.exe')
    if not executable:
        raise RuntimeError('PowerShell is required to use the installed OpenMCDF assembly')
    result = subprocess.run([executable,'-NoProfile','-NonInteractive','-EncodedCommand',encoded],
                            capture_output=True,check=False,encoding='utf-8',errors='replace',
                            creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
    if result.returncode:
        raise RuntimeError('OpenMCDF operation failed: '+result.stderr.strip())
    return result.stdout.lstrip('\ufeff')


def write_cfb_streams(path, streams):
    """Write named streams as a real CFB file, including proper mini streams."""
    if not OPENMCDF_DLL.is_file():
        raise FileNotFoundError('Set ALTIUM_OPENMCDF_DLL to an installed OpenMCDF.dll')
    path = Path(path).resolve()
    path.parent.mkdir(parents=True,exist_ok=True)
    if any(len(section)>31 for key in streams for section in key.split('/')):
        raise ValueError('CFB directory names may not exceed 31 characters')
    with tempfile.TemporaryDirectory(prefix='orion-library-cfb-') as tmp:
        spec = Path(tmp)/'streams.json'
        spec.write_text(json.dumps({k:base64.b64encode(v).decode('ascii') for k,v in streams.items()}),encoding='utf-8')
        script = f"""
$ErrorActionPreference='Stop'
Add-Type -Path {_psquote(OPENMCDF_DLL)}
$spec=Get-Content -Raw -LiteralPath {_psquote(spec)} | ConvertFrom-Json
$cf=[OpenMcdf.CompoundFile]::new()
try {{
  foreach($property in $spec.PSObject.Properties) {{
    $parts=$property.Name.Split('/')
    $storage=$cf.RootStorage
    for($i=0;$i -lt $parts.Length-1;$i++) {{
      $child=$storage.TryGetStorage($parts[$i])
      if($null -eq $child) {{$child=$storage.AddStorage($parts[$i])}}
      $storage=$child
    }}
    $stream=$storage.AddStream($parts[$parts.Length-1])
    $stream.SetData([Convert]::FromBase64String($property.Value))
  }}
  $cf.Save({_psquote(path)})
}} finally {{$cf.Close()}}
"""
        _powershell(script)
    if path.read_bytes()[:8] != bytes.fromhex('d0cf11e0a1b11ae1'):
        raise ValueError('CFB signature missing after write')


def read_cfb_streams(path):
    """Read native streams through OpenMCDF for structural roundtrip checks."""
    script = f"""
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.Encoding]::UTF8
Add-Type -Path {_psquote(OPENMCDF_DLL)}
function Read-Streams($storage,$prefix,$result) {{
  $items=[Collections.Generic.List[OpenMcdf.CFItem]]::new()
  $storage.VisitEntries([Action[OpenMcdf.CFItem]]{{param($item) $items.Add($item)}},$false)
  foreach($item in $items) {{
    if($item.IsStorage) {{Read-Streams ([OpenMcdf.CFStorage]$item) ($prefix+$item.Name+'/') $result}}
    else {{$result[$prefix+$item.Name]=[Convert]::ToBase64String(([OpenMcdf.CFStream]$item).GetData())}}
  }}
}}
$cf=[OpenMcdf.CompoundFile]::new({_psquote(Path(path).resolve())})
try {{$streams=@{{}};Read-Streams $cf.RootStorage '' $streams;$streams | ConvertTo-Json -Compress}}
finally {{$cf.Close()}}
"""
    return {k:base64.b64decode(v) for k,v in json.loads(_powershell(script)).items()}


def _read_block(data,offset):
    raw_size = struct.unpack_from('<I',data,offset)[0]
    size = raw_size & 0xffffff
    end = offset+4+size
    if end>len(data):
        raise ValueError('Truncated Altium record')
    return data[offset+4:end],end,raw_size>>24


def _read_props(data):
    return {k.upper():v for token in data.rstrip(b'\0').decode('cp1252').split('|')
            if '=' in token for k,v in [token.split('=',1)]}


def decode_schematic_library(streams):
    """Decode emitted binary records for cross-document verification."""
    components = {}
    for stream,data in streams.items():
        if not stream.endswith('/Data'):
            continue
        rows,offset = [],0
        while offset<len(data):
            block,offset,kind = _read_block(data,offset)
            if kind == 0:
                rows.append(_read_props(block))
                continue
            if kind != 1 or struct.unpack_from('<i',block)[0] != 2:
                raise ValueError('Unexpected schematic binary record')
            # Pin layout: record id, reserved byte, part id, display mode,
            # four decoration codes, Pascal description, typed geometry, names.
            cursor = 12
            cursor += 1+block[cursor]
            formal,electrical,flags = block[cursor:cursor+3]
            cursor += 3
            length,x,y,color = struct.unpack_from('<hhhI',block,cursor)
            cursor += 10
            values = []
            for _ in range(5):
                size = block[cursor]
                values.append(block[cursor+1:cursor+1+size].decode('cp1252'))
                cursor += 1+size
            if cursor != len(block):
                raise ValueError('Unexpected trailing schematic pin bytes')
            rows.append({'RECORD':'2','OWNERINDEX':'0','OWNERPARTID':str(struct.unpack_from('<h',block,5)[0]),
                         'FORMALTYPE':str(formal),'ELECTRICAL':str(electrical),'PINCONGLOMERATE':str(flags),
                         'PINLENGTH':str(length),'LOCATION.X':str(x),'LOCATION.Y':str(y),
                         'COLOR':str(color),'NAME':values[0],'DESIGNATOR':values[1]})
        components[stream.rsplit('/',1)[0]] = rows
    return components


def decode_pcb_library(streams):
    """Decode simple native pad/track footprints without invoking Altium."""
    footprints = {}
    for stream,data in streams.items():
        if not stream.endswith('/Data') or stream.startswith('Library/'):
            continue
        prefix = stream.rsplit('/',1)[0]
        block,offset,_ = _read_block(data,0)
        name = block[1:1+block[0]].decode('cp1252')
        count = struct.unpack('<I',streams[prefix+'/Header'])[0]
        primitives = []
        while offset<len(data):
            kind = data[offset]
            offset += 1
            if kind == 2:
                blocks = []
                for _ in range(6):
                    block,offset,_ = _read_block(data,offset)
                    blocks.append(block)
                number = blocks[0][1:1+blocks[0][0]].decode('cp1252')
                body = blocks[4]
                layer = body[0]
                x,y,sx,sy = struct.unpack_from('<iiii',body,13)
                drill = struct.unpack_from('<i',body,45)[0]
                primitives.append(dict(kind='Pad',number=number,layer=layer,
                    x=x*.0254/10000,y=y*.0254/10000,sx=sx*.0254/10000,sy=sy*.0254/10000,
                    drill=drill*.0254/10000,shape=body[49],rotation=struct.unpack_from('<d',body,52)[0]))
            elif kind == 4:
                block,offset,_ = _read_block(data,offset)
                coords = struct.unpack_from('<iiiii',block,13)
                primitives.append(dict(kind='Track',layer=block[0],
                    **{key:value*.0254/10000 for key,value in zip(('x1','y1','x2','y2','width'),coords)}))
            elif kind == 12:
                block,offset,_ = _read_block(data,offset)
                size=struct.unpack_from('<I',block,18)[0]
                props=dict(p.split('=',1) for p in block[22:22+size].rstrip(b'\0').decode('cp1252').split('|') if '=' in p)
                vertices=struct.unpack_from('<I',block,22+size)[0]
                if len(block)!=26+size+16*vertices:
                    raise ValueError('Invalid 3D body contour length: '+prefix)
                primitives.append(dict(kind='ComponentBody',layer=block[0],properties=props,vertices=vertices))
            else:
                raise ValueError(f'Unexpected footprint primitive {kind} in {prefix}')
        if len(primitives)!=count or name!=prefix:
            raise ValueError('Footprint header/data names or primitive counts differ: '+prefix)
        footprints[name] = primitives
    return footprints


def _block(data, binary=False):
    return struct.pack('<I',len(data)|(0x01000000 if binary else 0))+data


def _props(fields):
    def value(v):
        if isinstance(v,bool):
            return 'T' if v else 'F'
        return str(v)
    if any(any(c in value(v) for c in '|\x00\r\n') for v in fields.values()):
        raise ValueError('Unsafe property value')
    raw = ('|'+ '|'.join(f'{k}={value(v)}' for k,v in fields.items())).encode('cp1252')+b'\0'
    return _block(raw)


def _pstr(text):
    data = str(text).encode('cp1252')
    if len(data)>255:
        raise ValueError('Pascal shortstring too long')
    return bytes([len(data)])+data


def _sch_pin(pin, modelpin):
    flags = 32 + int(pin['orientation']) + (8 if pin.get('show_name',True) else 0) + (16 if pin.get('show_number',True) else 0)
    data = struct.pack('<iBhBBBBB',2,0,1,0,0,0,0,0)
    data += _pstr('')+bytes([1,int(pin.get('type',modelpin['type'])),flags])
    data += struct.pack('<hhhI',int(pin['length']),int(pin['x']),int(pin['y']),128)
    data += _pstr(pin.get('name',modelpin['name']))+_pstr(pin['number'])+_pstr('')+_pstr('')+_pstr('')
    return _block(data,True)


def _unique_parts(data):
    result = {}
    for part in data['components']:
        libref = part['libref']
        if libref in result:
            previous = result[libref]
            pinmap = lambda p: [(str(x['number']),x['name'],x['type']) for x in p['pins']]
            if part['value'] != previous['value'] or part['footprint'] != previous['footprint'] or pinmap(part) != pinmap(previous):
                raise ValueError('Shared libref has inconsistent component definition: '+libref)
        else:
            result[libref] = part
    return result


def schematic_library_streams(data):
    from altium_symbols import symbol_for
    parts = _unique_parts(data)
    streams = {'Storage':_props({'HEADER':'Icon storage'})}
    header = dict(HEADER='Protel for Windows - Schematic Library Editor Binary File Version 5.0',
                  Weight=0,MinorVersion=2,UniqueID=_uid('Orion-SchLib'),FontIdCount=3,
                  Size1=9,FontName1='Arial',Size2=12,FontName2='Arial',Bold2=True,
                  Size3=8,FontName3='Arial',UseMBCS=True,IsBOC=True,SheetStyle=9,
                  SnapGridOn=True,SnapGridSize=10,VisibleGridOn=False,VisibleGridSize=10,
                  AreaColor=16777215,BorderOn=False,TitleBlockOn=False,SystemFont=1,
                  CustomX=18000,CustomY=18000,UseCustomSheet=True,CompCount=len(parts))
    weight = 0
    for i,(name,part) in enumerate(parts.items()):
        header.update({f'LibRef{i}':name,f'CompDescr{i}':part['description'],f'PartCount{i}':2})
        symbol = symbol_for(part)
        entries = []
        def add(**fields):
            index = len(entries)
            entries.append(_props(fields))
            return index
        add(RECORD=1,LibReference=name,ComponentDescription=part['description'],PartCount=2,
            DisplayModeCount=1,IndexInSheet=-1,OwnerPartId=-1,CurrentPartId=1,
            SourceLibraryName=SCHLIB_NAME,TargetFileName='*',UniqueID=_uid('lib:'+name),
            AreaColor=11599871,Color=128,PartIDLocked=False,DesignItemId=name,AllPinCount=len(part['pins']))
        pinmap = {str(p['number']):p for p in part['pins']}
        for pin in symbol['pins']:
            entries.append(_sch_pin(pin,pinmap[str(pin['number'])]))
        for graphic in symbol['graphics']:
            fields = dict(graphic)
            fields.update(OwnerIndex=0,OwnerPartId=1,IsNotAccesible=True,IndexInSheet=len(entries))
            add(**fields)
        dx,dy = symbol['designator_pos']
        vx,vy = symbol['value_pos']
        designator = re.sub(r'\d+$','',part['ref'])+'?'
        add(RECORD=34,OwnerIndex=0,OwnerPartId=-1,IndexInSheet=-1,
            **{'Location.X':dx,'Location.Y':dy},Color=128,FontID=1,Text=designator,Name='Designator',ReadOnlyState=1)
        add(RECORD=41,OwnerIndex=0,OwnerPartId=-1,IndexInSheet=-1,
            **{'Location.X':vx,'Location.Y':vy},Color=128,FontID=1,Text=part['value'],Name='Comment')
        for parameter,value in component_parameters(part).items():
            add(RECORD=41,OwnerIndex=0,OwnerPartId=-1,IndexInSheet=len(entries),
                Color=128,FontID=1,IsHidden=True,Text=value,Name=parameter)
        models = add(RECORD=44,OwnerIndex=0)
        model = add(RECORD=45,OwnerIndex=models,IndexInSheet=-1,Description=part['footprint'],
                    ModelName=part['footprint'],ModelType='PCBLIB',DatafileCount=1,
                    ModelDatafile0=PCBLIB_NAME,ModelDatafileEntity0=part['footprint'],
                    ModelDatafileKind0='PCBLib',IsCurrent=True,UniqueID=_uid('footprint:'+name))
        add(RECORD=46,OwnerIndex=model)
        add(RECORD=48,OwnerIndex=model)
        streams[name+'/Data'] = b''.join(entries)
        weight += len(entries)
    header['Weight'] = weight
    streams['FileHeader'] = _props(header)
    return streams


def _coord(mm):
    return round(mm/0.0254*10000)


def _pcb_track(x1,y1,x2,y2,width,layer=33):
    # Native PCB6 track record, exactly 49 bytes as in AD25 example libraries.
    payload = bytearray(49)
    struct.pack_into('<BBBHHH',payload,0,layer,12,0,65535,65535,65535)
    payload[9:13] = b'\xff'*4
    struct.pack_into('<iiiii',payload,13,*map(_coord,(x1,y1,x2,y2,width)))
    extended = 0x01030006 if layer == 33 else 0x01020000+(layer-56)
    struct.pack_into('<I',payload,41,extended)
    return b'\x04'+_block(payload)


def _pcb_pad(pad,identity,plated=True):
    # AD25's observed 194-byte simple pad body. Unused caches are initialized to
    # documented defaults; identities are generated uniquely, never copied.
    payload = bytearray(194)
    layer = 74 if pad.drill else 1
    struct.pack_into('<BBBHHH',payload,0,layer,12,0,65535,65535,65535)
    payload[9:13] = b'\xff'*4
    struct.pack_into('<ii',payload,13,_coord(pad.x),_coord(pad.y))
    for offset in (21,29,37):
        struct.pack_into('<ii',payload,offset,_coord(pad.sx),_coord(pad.sy))
    struct.pack_into('<i',payload,45,_coord(pad.drill))
    shape = {'ROUND':1,'RECTANGLE':2,'OCTAGON':3}[pad.shape]
    payload[49:52] = bytes([shape])*3
    struct.pack_into('<d',payload,52,0.0)
    payload[60] = int(plated)
    struct.pack_into('<i',payload,68,100000)  # thermal conductor width
    struct.pack_into('<h',payload,72,4)
    struct.pack_into('<iii',payload,74,100000,200000,200000)
    struct.pack_into('<i',payload,90,40000)   # 4 mil solder mask expansion
    payload[101:104] = b'\x01\x01\x01'    # rule-driven mask/clearance caches
    if not pad.paste or pad.drill:
        struct.pack_into('<i',payload,86,_coord(-10))
        payload[101]=2
    struct.pack_into('<d',payload,106,pad.drill_slot_angle_deg)
    struct.pack_into('<I',payload,114,0x0103000F if layer == 74 else 0x01000001)
    struct.pack_into('<i',payload,120,40000)
    payload[126:142] = uuid.uuid5(uuid.NAMESPACE_URL,identity+':a').bytes_le
    payload[142:158] = uuid.uuid5(uuid.NAMESPACE_URL,identity+':b').bytes_le
    struct.pack_into('<ii',payload,162,0x7fffffff,0x7fffffff)
    payload[171] = 1
    payload[172] = 18
    payload[184:186] = b'\x01\x03'
    extension=b''
    if pad.drill_slot_length_mm:
        # PCB6 pad subrecord6, documented by KiCad's APAD6 parser. Native
        # TExtendedHoleType eSlotHole=2. Sizes are 1/10000mil, angle degrees.
        ex=bytearray(596)
        for i in range(29):
            struct.pack_into('<i',ex,4*i,_coord(pad.sx))
            struct.pack_into('<i',ex,116+4*i,_coord(pad.sy))
            ex[232+i]=shape
        ex[262]=2
        struct.pack_into('<i',ex,263,_coord(pad.drill_slot_length_mm))
        struct.pack_into('<d',ex,267,pad.drill_slot_angle_deg)
        ex[532:564]=bytes([shape])*32
        extension=bytes(ex)
    return b'\x02'+_block(_pstr(pad.number))+_block(_pstr(''))+_block(_pstr('|&|0')) \
        +_block(_pstr(''))+_block(payload)+_block(extension)


def _pcb_library_settings():
    """Full native editor defaults, needed when opening a PcbLib directly.

    Loading a footprint through SchLib previews bypasses these settings. An
    abbreviated layer list can therefore appear to work while direct PcbLib
    opening raises an exception in Altium's Library-section loader. This
    neutral fixture was saved from a new empty AD26 library, with user paths
    removed and document identities regenerated; it has no footprint content.
    """
    fixture = Path(__file__).with_name('altium_defaults')/'pcb_library_header.json'
    records = json.loads(fixture.read_text(encoding='utf-8'))['records']
    text = '\r'.join(records)
    for number,name in ((69,'Component bodies'),(71,'Courtyards')):
        text = re.sub(rf'(?<=\|LAYER{number}NAME=)[^|\r]*',name,text)
        text = re.sub(rf'(?<=\|LAYER{number}MECHENABLED=)[^|\r]*','TRUE',text)
        extended = 0x01020000+(number-56)
        # V9's cache index is distinct from the legacy layer number.
        prefixes = re.findall(rf'\|(V9_CACHE_LAYER\d+)_LAYERID={extended}(?=\||\r)',text)
        for prefix in prefixes:
            text = re.sub(rf'(?<=\|{prefix}_NAME=)[^|\r]*',name,text)
            text = re.sub(rf'(?<=\|{prefix}_MECHENABLED=)[^|\r]*','TRUE',text)
            text = re.sub(rf'(?<=\|{prefix}_USEDBYPRIMS=)[^|\r]*','TRUE',text)
    if re.search(r'[A-Za-z]:\\',text):
        raise ValueError('Native library defaults contain an absolute user path')
    return _block(text.encode('cp1252')+b'\0')


def pcb_library_streams(data):
    from altium_pcb import footprint,mil
    footprints = {}
    for part in data['components']:
        fp = footprint(part)
        name = part['footprint']
        if name in footprints and fp.pads != footprints[name][1].pads:
            raise ValueError('Shared footprint has inconsistent pads: '+name)
        footprints.setdefault(name,(part,fp))
    title = 'PCB 6.0 Binary Library File'
    streams = {
        'FileHeader':struct.pack('<I',len(title))+_pstr(title)+struct.pack('<dI',5.01,8)+_pstr(_uid('Orion-PcbLib')),
        'Library/Header':struct.pack('<I',1),
        'Library/Models/Header':struct.pack('<I',0),'Library/Models/Data':b'',
        'Library/ModelsNoEmbed/Header':struct.pack('<I',0),'Library/ModelsNoEmbed/Data':b'',
        'Library/Textures/Header':struct.pack('<I',0),'Library/Textures/Data':b'',
        'Library/EmbeddedFonts':struct.pack('<I',0),
        'Library/LayerKindMapping/Header':struct.pack('<I',1),
        'Library/LayerKindMapping/Data':bytes.fromhex('0800000031002e00300000000000000000000000'),
        'Library/PadViaLibrary/Header':struct.pack('<I',0),
        'Library/PadViaLibrary/Data':_props({
            'PADVIALIBRARY.LIBRARYID':'{'+str(uuid.uuid5(uuid.NAMESPACE_URL,'Orion-Bridge.PadViaLibrary')).upper()+'}',
            'PADVIALIBRARY.LIBRARYNAME':'<Local>','PADVIALIBRARY.DISPLAYUNITS':1}),
        'Library/ComponentParamsTOC/Header':struct.pack('<I',1),
    }
    streams['Library/ComponentParamsTOC/Data'] = _block((''.join(
        f'Name={name}|Pad Count={len(fp.pads)}|Height={_coord(fp.height)}|Description={fp.note}\r\n'
        for name,(_,fp) in footprints.items())+'\0').encode('cp1252'))
    streams['Library/Data'] = _pcb_library_settings()+struct.pack('<I',len(footprints)) \
        +b''.join(_block(_pstr(name)) for name in footprints)
    for name,(part,fp) in footprints.items():
        primitives = [_pcb_pad(p,name+':'+p.number) for p in fp.pads]
        from altium_pcb import Pad
        for i,hole in enumerate(part.get('pcb_footprint',{}).get('holes',[])):
            p=Pad('',hole['x'],hole['y'],hole['drill'],hole['drill'],hole['drill'],'ROUND',paste=False)
            primitives.append(_pcb_pad(p,name+':NPTH'+str(i),plated=False))
        w,h = fp.body
        # The mechanical outline preserves the package envelope. A sparse
        # corner mark in silkscreen identifies orientation without crossing pads.
        corners = [(-w/2,-h/2),(w/2,-h/2),(w/2,h/2),(-w/2,h/2)]
        for a,b in zip(corners,corners[1:]+corners[:1]):
            primitives.append(_pcb_track(*a,*b,.10,69))
        all_x = [p.x-p.sx/2 for p in fp.pads]+[p.x+p.sx/2 for p in fp.pads]+[-w/2,w/2]
        all_y = [p.y-p.sy/2 for p in fp.pads]+[p.y+p.sy/2 for p in fp.pads]+[-h/2,h/2]
        left,right,bottom,top = min(all_x)-.25,max(all_x)+.25,min(all_y)-.25,max(all_y)+.25
        corners = [(left,bottom),(right,bottom),(right,top),(left,top)]
        for a,b in zip(corners,corners[1:]+corners[:1]):
            primitives.append(_pcb_track(*a,*b,.05,71))
        if fp.pads:
            first = fp.pads[0]
            sx = first.x-first.sx/2-.35
            sy = first.y+first.sy/2+.35
            primitives.append(_pcb_track(sx,sy,sx+.5,sy,.15))
            primitives.append(_pcb_track(sx,sy,sx,sy-.5,.15))
        streams[name+'/Header'] = struct.pack('<I',len(primitives))
        streams[name+'/Data'] = _block(_pstr(name))+b''.join(primitives)
        streams[name+'/Parameters'] = _props({'PATTERN':name,'HEIGHT':mil(fp.height),
                                             'DESCRIPTION':fp.note,'ITEMGUID':'','REVISIONGUID':''})
        streams[name+'/WideStrings'] = _block(b'\0')
    return streams


def build_libraries(data,output_directory):
    """Create both native libraries and verify every CFB stream byte for byte."""
    enrich_components(data)
    output_directory = Path(output_directory)
    libraries = [(SCHLIB_NAME,schematic_library_streams(data)),
                 (PCBLIB_NAME,pcb_library_streams(data))]
    for filename,streams in libraries:
        path = output_directory/filename
        write_cfb_streams(path,streams)
        restored = read_cfb_streams(path)
        if restored != streams:
            raise ValueError(filename+': CFB stream roundtrip differs')
        if filename == SCHLIB_NAME:
            decoded = decode_schematic_library(restored)
            for name,part in _unique_parts(data).items():
                pins = {r['DESIGNATOR'] for r in decoded[name] if r.get('RECORD')=='2'}
                if pins != {str(p['number']) for p in part['pins']}:
                    raise ValueError(name+': decoded binary symbol pins differ from model')
        else:
            from altium_pcb import footprint
            decoded = decode_pcb_library(restored)
            for part in data['components']:
                actual = {p['number']:p for p in decoded[part['footprint']] if p['kind']=='Pad' and p['number']}
                holes=[p for p in decoded[part['footprint']] if p['kind']=='Pad' and not p['number']]
                expected_holes=part.get('pcb_footprint',{}).get('holes',[])
                if len(holes)!=len(expected_holes):raise ValueError(part['footprint']+': mechanical hole count differs')
                for hole,spec in zip(holes,expected_holes):
                    if any(abs(hole[k]-spec[k])>.000003 for k in ('x','y','drill')):
                        raise ValueError(part['footprint']+': mechanical hole position differs')
                expected = {p.number:p for p in footprint(part).pads}
                if set(actual)!=set(expected):
                    raise ValueError(part['footprint']+': decoded pad numbers differ')
                for number,pad in expected.items():
                    for key in ('x','y','sx','sy','drill'):
                        if abs(actual[number][key]-getattr(pad,key))>0.000003:
                            raise ValueError(part['footprint']+': decoded pad geometry differs')
    return {'schematic_library':SCHLIB_NAME,'pcb_library':PCBLIB_NAME,
            'components':len(_unique_parts(data)),
            'footprints':len({p['footprint'] for p in data['components']})}


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('design',type=Path)
    parser.add_argument('output',type=Path)
    args = parser.parse_args()
    print(json.dumps(build_libraries(json.loads(args.design.read_text(encoding='utf-8')),args.output),indent=2))
