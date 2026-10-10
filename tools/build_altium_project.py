"""Build the editable, deliberately unrouted Altium R1 engineering draft.

No Altium process is launched. ASCII SchDoc/PcbDoc are native document formats.
Run with Python 3; no third-party packages are needed for generation.
"""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "hardware" / "altium"


def uid(text):
    return ''.join(chr(65 + b % 26) for b in hashlib.sha256(text.encode()).digest()[:8])


def pin(number, name, net, kind=4):
    return dict(number=str(number), name=name, net=net, type=kind)


def design():
    parts = []

    def add(ref, value, fp, pins, x, y, group, status="PROVISIONAL - verify landpattern before fabrication"):
        parts.append(dict(ref=ref, value=value, footprint=fp, uid=uid(ref), pins=pins,
                          group=group, pcb=dict(x=x, y=y, rotation=0, status=status)))

    def two(ref, value, fp, a, b, x, y, group, names=('1', '2')):
        add(ref, value, fp, [pin(1, names[0], a), pin(2, names[1], b)], x, y, group)

    add('J1', 'NMEA Micro-C pigtail', 'TBD_TERMINAL_5_3.5', [
        pin(1, 'SHIELD', 'SHIELD'), pin(2, 'NET-S', 'NET_S'), pin(3, 'NET-C', 'GND_BUS'),
        pin(4, 'CAN-H', 'CANH_EXT'), pin(5, 'CAN-L', 'CANL_EXT')], 6, 33, 'connector',
        'TBD terminal MPN, pitch and pin order; logical Micro-C numbering, not a connector face view')
    add('TP1', 'Shield / chassis pad', 'TESTPOINT_2MM', [pin(1, 'SHIELD', 'SHIELD')], 14, 45, 'connector')
    two('F1', 'T0.8A >=60V', 'TBD_FUSE_9X6', 'NET_S', 'FUSED_IN', 16, 16, 'protection')
    add('Q1', 'DMP6023LE', 'SOT223_PMOS', [pin(1, 'G', 'GATE'), pin(2, 'D', 'FUSED_IN'),
        pin(3, 'S', 'BUS_PROT'), pin(4, 'TAB=D', 'FUSED_IN')], 25.5, 16, 'protection')
    two('Z1', 'BZT52C12', 'SOD123', 'BUS_PROT', 'GATE', 28, 10, 'protection', ('K', 'A'))
    two('R1', '100k', 'R0805', 'GATE', 'GND_BUS', 22, 10, 'protection')
    two('D1', 'SMBJ20A', 'SMB', 'BUS_PROT', 'GND_BUS', 16, 8, 'protection', ('K', 'A'))
    two('C1', '47uF 50V', 'TBD_CAP_RADIAL_P2.5_D8', 'BUS_PROT', 'GND_BUS', 27, 4, 'protection', ('+', '-'))
    add('U3', 'TPS7B6950QDCYRQ1', 'SOT223_LDO', [pin(1, 'IN', 'BUS_PROT', 7), pin(2, 'GND', 'GND_BUS', 7),
        pin(3, 'OUT', '5V_BUS', 7), pin(4, 'TAB=GND', 'GND_BUS', 7)], 26.5, 24, 'bus_supply')
    two('C2', '1uF 50V X7R', 'C0805', 'BUS_PROT', 'GND_BUS', 20, 26, 'bus_supply')
    two('C3', '10uF 16V X7R', 'C1206', '5V_BUS', 'GND_BUS', 33, 25, 'bus_supply')
    two('C8', '10uF 50V X7R', 'C1210', 'BUS_PROT', 'GND_BUS', 31, 5, 'isolated_supply')
    two('L2', '15uH Isat>=1A', 'TBD_INDUCTOR_5X5', 'BUS_PROT', 'DCDC_IN', 33, 10, 'isolated_supply')
    two('C9', '10uF 50V X7R', 'C1210', 'DCDC_IN', 'GND_BUS', 33, 17, 'isolated_supply')
    add('U2', 'R3M-2405S/SMD', 'R3M_SMD', [pin(1, '+VIN', 'DCDC_IN', 7), pin(2, '-VIN', 'GND_BUS', 7),
        pin(4, 'CTRL=open/on', None, 0), pin(5, 'NC', None), pin(6, '-VOUT', 'GND_LOGIC', 7),
        pin(7, '+VOUT', '5V_ISO', 7)], 40, 12.5, 'isolated_supply')
    two('C6', '47uF 10V', 'TBD_CAP_RADIAL_P2.5_D6.3', '5V_ISO', 'GND_LOGIC', 54, 9, 'isolated_supply', ('+', '-'))
    two('C7', '100nF 16V', 'C0805', '5V_ISO', 'GND_LOGIC', 59, 10, 'isolated_supply')
    two('D2', 'SS36', 'SMB', '5V_AFTER_DIODE', '5V_ISO', 54, 17, 'isolated_supply', ('K', 'A'))
    two('JP1', 'RUN closed / USB open', 'HDR1X2_2.54', '5V_AFTER_DIODE', '5V_MODULE', 62, 18, 'isolated_supply')
    add('D3', 'PESD2CAN24T-Q', 'SOT23', [pin(1, 'K1', 'CANH_EXT'), pin(2, 'K2', 'CANL_EXT'),
        pin(3, 'CC', 'GND_BUS')], 17, 32, 'can')
    add('L1', 'ACT45B-510-2P-TL003', 'ACT45B', [pin(1, 'H_EXT', 'CANH_EXT'), pin(2, 'L_EXT', 'CANL_EXT'),
        pin(3, 'L_IC', 'CANL'), pin(4, 'H_IC', 'CANH')], 25.5, 33.5, 'can')
    add('U1', 'ISO1042DWV', 'SOIC8_DWV', [pin(1, 'VCC1', '3V3_LOGIC', 7), pin(2, 'TXD', 'TXD', 0),
        pin(3, 'RXD', 'RXD', 2), pin(4, 'GND1', 'GND_LOGIC', 7), pin(5, 'GND2', 'GND_BUS', 7),
        pin(6, 'CANL', 'CANL', 1), pin(7, 'CANH', 'CANH', 1), pin(8, 'VCC2', '5V_BUS', 7)], 40, 36.5, 'can')
    parts[-1]['pcb']['rotation'] = 180  # BUS pads left, LOGIC pads right.
    two('C4', '100nF', 'C0805', '5V_BUS', 'GND_BUS', 31.5, 41, 'can')
    two('C5', '100nF', 'C0805', '3V3_LOGIC', 'GND_LOGIC', 48.5, 41, 'logic')
    two('R2', '10k', 'R0805', '3V3_LOGIC', 'TXD', 52.5, 24, 'logic')
    two('R3', '33R (R_TX)', 'R0805', 'GPIO6', 'TXD', 55, 29, 'logic')
    two('R4', '33R (R_RX)', 'R0805', 'RXD', 'GPIO7', 50.5, 33, 'logic')
    add('MCU1', 'ESP32-C3 SuperMini 4MB', 'TBD_SUPERMINI_NO_PADS', [
        pin('5V', '5V', '5V_MODULE', 7), pin('GND', 'GND', 'GND_LOGIC', 7),
        pin('3V3', '3V3', '3V3_LOGIC', 7), pin('6', 'GPIO6 / TX', 'GPIO6', 2),
        pin('7', 'GPIO7 / RX', 'GPIO7', 0)], 70, 34, 'logic',
        'MECHANICAL RESERVATION ONLY: no pads; measure exact module header positions and map pins before ECO/routing')
    # Refine the illustrative placement for actual pad extents. The reference
    # drawing used reservation rectangles and is not a placement database.
    revised = {'F1': (12, 18), 'Q1': (24, 19), 'Z1': (19, 11), 'R1': (26, 6),
               'D1': (10, 7), 'C1': (20, 5), 'U3': (24, 28), 'C2': (18, 27),
               'C3': (31, 28), 'C8': (31, 4), 'L2': (28, 11), 'C9': (31, 20),
               'L1': (25.5, 36)}
    for component in parts:
        if component['ref'] in revised:
            component['pcb']['x'], component['pcb']['y'] = revised[component['ref']]
    return dict(revision='R1 engineering draft', board=dict(width_mm=80, height_mm=60,
                holes_mm=[[4, 56], [4, 4], [76, 4]], origin='bottom-left; +Y up'),
                components=parts, notes=[
                    'Unrouted engineering draft. Not fabrication-ready. No Altium ERC/DRC or open/save validation performed.',
                    'GND_BUS and GND_LOGIC are galvanically separated; no copper crossing except U1/U2.',
                    'U2 requires >=9V after protection/filter losses; operation at 9V NET-S is not guaranteed.',
                    'RUN: JP1 closed, USB disconnected. SERVICE: open JP1 BEFORE connecting USB.',
                    'No 120-ohm termination on this drop. MCU1 header geometry is unresolved.',
                    'R3/R4 correspond to R_TX/R_RX in the R1 reference drawing. TP1 is its TP_SH shield pad.'])


def record(**fields):
    for value in fields.values():
        if any(c in str(value) for c in '|\r\n'):
            raise ValueError(f'Unsafe Altium ASCII value: {value!r}')
    return '|' + '|'.join(f'{k}={v}' for k, v in fields.items())


class Schematic:
    """Native schematic ASCII records; sheet coordinates use 10-mil units."""
    def __init__(self):
        self.rows = []
        self.add(RECORD=31, FontIdCount=3, Size1=9, FontName1='Arial', Size2=12,
                 FontName2='Arial', Bold2='T', Size3=7, FontName3='Arial', SheetStyle=2,
                 BorderOn='T', TitleBlockOn='T', HotSpotGridOn='T', HotSpotGridSize=10,
                 SnapGridOn='T', SnapGridSize=10, VisibleGridOn='T', VisibleGridSize=10,
                 CustomX=2230, CustomY=1570, SystemFont=1, Display_Unit=0,
                 AreaColor=16317695, UseMBCS='T', IsBOC='T')

    def add(self, **fields):
        index = len(self.rows)
        self.rows.append(record(**fields))
        return index

    def text(self, x, y, text, bold=False, color=0):
        self.add(RECORD=4, OwnerPartId=-1, **{'Location.X': x, 'Location.Y': y},
                 Color=color, FontID=2 if bold else 1, Text=text, UniqueID=uid('label'+str(len(self.rows))))

    def net(self, x, y, text):
        self.add(RECORD=25, OwnerPartId=-1, **{'Location.X': x, 'Location.Y': y},
                 Color=128, FontID=3, Text=text, UniqueID=uid('net'+str(len(self.rows))))

    def wire(self, x1, y1, x2, y2):
        self.add(RECORD=27, OwnerPartId=-1, LineWidth=1, Color=8388608,
                 LocationCount=2, X1=x1, Y1=y1, X2=x2, Y2=y2,
                 UniqueID=uid('wire'+str(len(self.rows))))

    def block(self, component, x, y):
        ps = component['pins']
        two = len(ps) == 2
        left = ps[:1] if two else ps[:(len(ps)+1)//2]
        right = ps[1:] if two else ps[(len(ps)+1)//2:]
        width = 130
        height = max(len(left), len(right)) * 30 + 20
        owner = self.add(RECORD=1, LibReference=component['ref']+'_R1',
                         ComponentDescription=component['value'], PartCount=2, DisplayModeCount=1,
                         OwnerPartId=-1, **{'Location.X': x, 'Location.Y': y}, CurrentPartId=1,
                         SourceLibraryName='*', TargetFileName='*', UniqueID=component['uid'],
                         AreaColor=11599871, Color=128, PartIDLocked='F', AllPinCount=len(ps))
        self.add(RECORD=14, OwnerIndex=owner, OwnerPartId=1, IsNotAccesible='T',
                 **{'Location.X': x, 'Location.Y': y-height, 'Corner.X': x+width, 'Corner.Y': y},
                 LineWidth=1, Color=128, AreaColor=11599871, IsSolid='T')
        for side, items in [('left', left), ('right', right)]:
            for j, p in enumerate(items):
                py = y - 30 - j*30
                # Pin location is body end; orientation points toward the electrical end.
                px = x if side == 'left' else x + width
                outer = px - 20 if side == 'left' else px + 20
                end = outer - 90 if side == 'left' else outer + 70
                self.add(RECORD=2, OwnerIndex=owner, OwnerPartId=1, FormalType=1,
                         Electrical=p['type'], PinConglomerate=58 if side == 'left' else 56,
                         PinLength=20, **{'Location.X': px, 'Location.Y': py},
                         Name=p['name'], Designator=p['number'], SwapIdPart='1',
                         UniqueID=uid(component['ref']+':'+p['number']))
                if p['net']:
                    self.wire(outer, py, end, py)
                    self.net(min(outer, end), py, p['net'])
                else:
                    self.add(RECORD=22, OwnerPartId=-1, **{'Location.X': outer, 'Location.Y': py},
                             Color=255)
        self.add(RECORD=34, OwnerIndex=owner, OwnerPartId=-1, **{'Location.X': x, 'Location.Y': y+22},
                 Color=128, FontID=2, Text=component['ref'], Name='Designator', ReadOnlyState=1)
        self.add(RECORD=41, OwnerIndex=owner, OwnerPartId=-1, **{'Location.X': x, 'Location.Y': y+7},
                 Color=128, FontID=1, Text=component['value'], Name='Comment')
        for name, value in [('Footprint', component['footprint']), ('ReviewStatus', component['pcb']['status'])]:
            self.add(RECORD=41, OwnerIndex=owner, OwnerPartId=-1, IsHidden='T', FontID=1, Text=value, Name=name)
        models = self.add(RECORD=44, OwnerIndex=owner)
        model = self.add(RECORD=45, OwnerIndex=models, ModelName=component['footprint'], ModelType='PCBLIB',
                         IsCurrent='T', DatafileCount=0, UniqueID=uid('model'+component['ref']))
        self.add(RECORD=46, OwnerIndex=model)
        self.add(RECORD=48, OwnerIndex=model)

    def write(self, path):
        header = record(HEADER='Protel for Windows - Schematic Capture Ascii File Version 5.0',
                        Weight=len(self.rows), MinorVersion=2, UniqueID=uid('OrionR1Sheet'))
        path.write_bytes(('\r\n'.join([header]+self.rows)+'\r\n').encode('ascii'))


def build_schematic(data, path):
    s = Schematic()
    s.text(60, 1510, 'ORION BRIDGE R1 - NMEA 2000 / ESP32-C3', True)
    s.text(60, 1480, 'ENGINEERING DRAFT - not fabrication-ready - native editable Altium ASCII', color=255)
    s.text(60, 1450, 'All wires with the same net label are connected on this sheet. GND_BUS and GND_LOGIC remain separate.')
    # Fixed functional blocks on one sheet avoid ambiguous cross-sheet net scope.
    cells = [
        ('connector', 60, 1380, 2, '01  NMEA connector / shield'),
        ('protection', 780, 1380, 4, '02  Input protection'),
        ('bus_supply', 60, 1010, 2, '03  Bus-side 5V regulator'),
        ('isolated_supply', 780, 1010, 4, '04  Isolated supply / USB service jumper'),
        ('can', 60, 570, 3, '05  CAN bus interface / isolation'),
        ('logic', 1150, 570, 3, '06  Logic / SuperMini'),
    ]
    for group, gx, gy, columns, title in cells:
        s.text(gx, gy, title, True)
        rows = [p for p in data['components'] if p['group'] == group]
        for i, part in enumerate(rows):
            s.block(part, gx + 110 + (i % columns)*350, gy - 60 - (i//columns)*185)
    s.text(60, 150, 'U2: CTRL left open (ON); pin 5 NC. No 120-ohm termination on this NMEA drop.', color=255)
    s.text(60, 125, 'USB SERVICE: open JP1 before connecting USB. RUN: close JP1 only with USB disconnected.', color=255)
    s.text(60, 100, '9V at NET-S is not yet covered after protection/filter losses. U3 thermal design remains to be verified.')
    s.text(60, 75, 'MCU1 pin labels are logical signals. Exact module header geometry is unresolved; PCB reservation has no pads.')
    s.text(60, 50, 'R3 = R_TX / R4 = R_RX / TP1 = TP_SH in reference drawing. All landpatterns require review; no ERC/DRC sign-off.')
    s.write(path)


def build_project():
    OUT.mkdir(parents=True, exist_ok=True)
    data = design()
    (OUT/'orion-r1-design.json').write_text(json.dumps(data, indent=2)+'\n', encoding='utf-8')
    build_schematic(data, OUT/'Orion-Bridge-R1.SchDoc')
    lines = ['[Design]', 'Version=1.0', 'HierarchyMode=0', 'DefaultConfiguration=Sources',
             'AllowPortNetNames=0', 'AllowSheetEntryNetNames=1', 'AppendSheetNumberToLocalNets=0',
             'NetlistSinglePinNets=1', 'DefaultPcbProtel=1', 'AutoSheetNumbering=1',
             'AutoCrossReferences=1', 'NewIndexingOfSheetSymbols=1', 'OutputPath=Project Outputs', '']
    for i, filename in enumerate(['Orion-Bridge-R1.SchDoc', 'Orion-Bridge-R1.PcbDoc'], 1):
        lines += [f'[Document{i}]', f'DocumentPath={filename}', 'AnnotationEnabled=1',
                  'AnnotateScope=All', 'DoLibraryUpdate=1', 'DoDatabaseUpdate=0',
                  'ClassGenCCAutoEnabled=1', 'ClassGenCCAutoRoomEnabled=0',
                  'ClassGenNCAutoScope=None', 'GenerateClassCluster=0',
                  'DocumentUniqueId='+ (uid('OrionR1Sheet') if i==1 else ''), '']
    (OUT/'Orion-Bridge-R1.PrjPcb').write_bytes('\r\n'.join(lines).encode('ascii'))
    # The simple Protel netlist is an independently inspectable hand-off file.
    nets = {}
    netlist = []
    for part in data['components']:
        netlist += ['[', part['ref'], part['footprint'], part['value'], ']']
        for p in part['pins']:
            if p['net']:
                nets.setdefault(p['net'], []).append(part['ref']+'-'+p['number'])
    for name, pins in sorted(nets.items()):
        netlist += ['(', name, *pins, ')']
    (OUT/'Orion-Bridge-R1.NET').write_bytes(('\r\n'.join(netlist)+'\r\n').encode('ascii'))
    from altium_pcb import build_pcb
    build_pcb(data, OUT/'Orion-Bridge-R1.PcbDoc')
    print(f'Created {len(data["components"])} components, {len(nets)} nets in {OUT}')


if __name__ == '__main__':
    build_project()
