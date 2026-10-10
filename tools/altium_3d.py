"""Editable Altium extruded component models for the Orion carrier.

These are locally generated package/assembly envelopes, not supplier STEP files.
Colours, markings and the SuperMini on-board parts are illustrative.  PCB pad
locations and selected package outlines come from the shared design model.
All lengths are millimetres; Z=0 is the carrier's top surface.

The binary body layout is verified against Altium's installed example PcbLibs.
No geometry or third-party model payload is copied from those libraries.
"""
from __future__ import annotations

from dataclasses import asdict, dataclass
import argparse
import json
import math
from pathlib import Path
import struct
import subprocess
import uuid

from altium_pcb import footprint, mil, transform, record, base
from altium_libraries import read_cfb_streams, write_cfb_streams

MODEL_NAMESPACE = uuid.UUID('2bbf8d9d-7543-4f7b-ae2f-9a5e8754113e')
SILVER = (179, 188, 198)
DARK = (40, 43, 47)
GOLD = (207, 163, 58)
CERAMIC = (180, 146, 100)
GREEN = (27, 91, 77)


@dataclass(frozen=True)
class Body:
    name: str
    outline: tuple[tuple[float, float], ...]
    z0: float
    z1: float
    rgb: tuple[int, int, int]


def rectangle(name, x, y, width, depth, z0, z1, colour):
    return Body(name, ((x-width/2, y-depth/2), (x+width/2, y-depth/2),
                       (x+width/2, y+depth/2), (x-width/2, y+depth/2)),
                z0, z1, colour)


def cylinder(name, x, y, radius, z0, z1, colour, segments=32):
    return Body(name, tuple((x+radius*math.cos(i*2*math.pi/segments),
                            y+radius*math.sin(i*2*math.pi/segments)) for i in range(segments)),
                z0, z1, colour)


def bodies_for(part):
    """Return component-local extrusions, including recognisable leads/details."""
    if part.get('bodies_3d'):
        return [Body(b['name'],tuple(tuple(p) for p in b['outline']),b['z0'],b['z1'],tuple(b['rgb']))
                for b in part['bodies_3d']]
    ref = part['ref']
    fp = footprint(part)
    w, d = fp.body
    h = max(fp.height, .1)
    bodies = []
    if ref == 'MCU1':
        # Nologo top view: USB at +Y, antenna at -Y.  Direct-soldered 2.54 mm
        # headers, not sockets. Module/component Z is an assembly assumption.
        for side, x in [('left', -7.62), ('right', 7.62)]:
            ys = [p.y for p in fp.pads if abs(p.x-x) < .05]
            bodies.append(rectangle(side+' header insulator', x, (min(ys)+max(ys))/2,
                                    2.54, max(ys)-min(ys)+2.54, .1, 2.6, DARK))
        for p in fp.pads:
            bodies.append(rectangle('header '+p.number, p.x, p.y, .64, .64,
                                    -2.5, 4.0, GOLD))
        bodies += [rectangle('module PCB', 0, 0, w, d, 2.6, 3.6, GREEN),
                   rectangle('ESP32-C3 package envelope', 0, -1.5, 5, 5, 3.6, 4.55, DARK),
                   rectangle('USB-C shell top', 0, d/2-3.1, 8.8, 7.2, 6.35, 6.7, SILVER),
                   rectangle('USB-C shell bottom', 0, d/2-3.1, 8.8, 7.2, 3.6, 3.95, SILVER),
                   rectangle('USB-C shell left', -4.25, d/2-3.1, .3, 7.2, 3.95, 6.35, SILVER),
                   rectangle('USB-C shell right', 4.25, d/2-3.1, .3, 7.2, 3.95, 6.35, SILVER),
                   rectangle('USB-C tongue', 0, d/2-1.6, 6.5, 3.6, 5.0, 5.35, DARK),
                   rectangle('ceramic antenna envelope', 0, -d/2+1.2, 3.2, 1.6, 3.6, 4.65, (196, 173, 125)),
                   rectangle('reset switch base', -5.8, 2.3, 3.3, 3.3, 3.6, 4.2, SILVER),
                   rectangle('reset switch cap', -5.8, 2.3, 1.6, 1.6, 4.2, 4.7, DARK),
                   rectangle('boot switch base', 5.8, 2.3, 3.3, 3.3, 3.6, 4.2, SILVER),
                   rectangle('boot switch cap', 5.8, 2.3, 1.6, 1.6, 4.2, 4.7, DARK)]
        # At least 3 mm clear space under the module for carrier passives.
        # Pins retain their penetration through the carrier; only the module
        # and its components move up with the taller insulating spacers.
        raised = []
        for body in bodies:
            if body.name.endswith('header insulator'):
                raised.append(Body(body.name, body.outline, body.z0, 3.1, body.rgb))
            elif body.name.startswith('header '):
                raised.append(Body(body.name, body.outline, body.z0, 4.5, body.rgb))
            else:
                raised.append(Body(body.name, body.outline, body.z0+.5, body.z1+.5, body.rgb))
        return raised
    if ref == 'J1':
        # J1 is a soldered pigtail, never imply a selected connector housing.
        colours = [(145, 151, 162), (184, 46, 47), (38, 40, 45), (226, 225, 213), (62, 108, 175)]
        for p, colour in zip(fp.pads, colours):
            bodies += [cylinder('wire '+p.number+' conductor', p.x, p.y, .35, -1.8, 1.8, SILVER),
                       cylinder('wire '+p.number+' insulation', p.x, p.y, .8, 1.8, 6, colour)]
        return bodies
    if ref.startswith('TP'):
        return [cylinder('exposed test pad', 0, 0, 1, 0, .035, GOLD)]
    if ref == 'JP1':
        bodies.append(rectangle('header insulator', 0, 0, w, d, .1, 2.6, DARK))
        for p in fp.pads:
            bodies.append(rectangle('header '+p.number, p.x, p.y, .64, .64, -2.5, 6, GOLD))
        # A removable shunt fitted in normal operation. No assumed exact MPN.
        bodies += [rectangle('removable shunt', 0, 0, 5.1, 2.5, 3.2, 6.8, (42, 83, 128)),
                   rectangle('shunt grip', 0, 0, 4.2, 2.3, 6.8, 7.2, (49, 95, 143))]
        return bodies
    if ref in {'C1', 'C6'}:
        model = part.get('model_3d', {})
        smd = model.get('style') == 'smd_electrolytic'
        diameter = model.get('can_diameter_nominal', w)
        bodies += [cylinder('aluminium can' if smd else 'electrolytic sleeve', 0, 0, diameter/2,
                            .6 if smd else .3, h-.3, SILVER if smd else (35, 49, 59)),
                   cylinder('aluminium top', 0, 0, max(.1, diameter/2-.25), h-.3, h, SILVER),
                   rectangle('vent groove X', 0, 0, diameter*.55, .08, h, h+.015, DARK),
                   rectangle('vent groove Y', 0, 0, .08, diameter*.55, h, h+.015, DARK),
                   rectangle('negative polarity stripe', diameter/2-.15, 0, .3, diameter*.3,
                             .7 if smd else .5, h-.5, DARK if smd else (155, 167, 179))]
        if any(p.drill for p in fp.pads):
            for p in fp.pads:
                bodies.append(cylinder('lead '+p.number, p.x, p.y, .3, -2.2, .4, SILVER, 12))
        else:
            base_w, base_d = model.get('base_nominal', [w, d])
            bodies.append(rectangle('SMD insulating base', 0, 0, base_w, base_d, .05, .65, DARK))
            for p in fp.pads:
                bodies.append(rectangle('SMD lead '+p.number, p.x, p.y, p.sx*.75, p.sy*.6, .02, .25, SILVER))
        return bodies
    if ref == 'F1':
        bodies.append(rectangle('fuse package envelope', 0, 0, w, d, .15, h, (178, 159, 113)))
        for p in fp.pads:
            if p.drill:
                bodies.append(cylinder('lead '+p.number, p.x, p.y, .4, -2.2, .5, SILVER, 12))
            else:
                cap_width = min(.8, w*.16)
                tx = math.copysign(w/2-cap_width/2, p.x)
                bodies.append(rectangle('end cap '+p.number, tx, 0, cap_width, d+.02, .02, h+.02, SILVER))
        return bodies
    if ref == 'U2':
        bodies += [rectangle('isolated converter moulding', 0, 0, w, d, .3, h, DARK),
                   rectangle('converter top label', 0, 0, w*.8, d*.6, h, h+.025, (69, 73, 78))]
        for p in fp.pads:
            bodies.append(rectangle('terminal '+p.number, p.x, p.y, p.sx*.95, p.sy*.6, .02, .3, SILVER))
        return bodies
    colour = CERAMIC if ref.startswith('C') else DARK
    if ref == 'L2': colour = (72, 69, 67)
    bodies.append(rectangle('package envelope', 0, 0, w, d, .12, h, colour))
    for p in fp.pads:
        # Leads extend from pad centre to package edge; small SMD passives have
        # metallised end caps. Geometry depicts the package, not the solder land.
        if ref.startswith(('R', 'C')) and len(fp.pads) == 2:
            terminal_w = min(.4, w*.2)
            tx = (-1 if p.x < 0 else 1)*(w/2-terminal_w/2)
            bodies.append(rectangle('end cap '+p.number, tx, 0, terminal_w, d+.02, .02, h+.025, SILVER))
        elif ref in {'Q1', 'U3'}:
            py = (-1 if p.y < 0 else 1)*(abs(p.y)+d/2)/2
            bodies.append(rectangle('lead '+p.number, p.x, py,
                                    min(p.sx*.85, 3.2 if p.number == '4' else .85),
                                    abs(p.y)-d/2+.65, .02, .28, SILVER))
        else:
            # The short straight lead span is an envelope of formed/gull-wing
            # terminals; a bend profile is deliberately not asserted.
            tx, ty = p.x, p.y
            if abs(p.x) > w/2:
                tx = (p.x + math.copysign(w/2-.05, p.x))/2
                sx, sy = abs(p.x)-w/2+.65, min(p.sy*.7, .9)
            elif abs(p.y) > d/2:
                ty = (p.y + math.copysign(d/2-.05, p.y))/2
                sx, sy = min(p.sx*.8, .8), abs(p.y)-d/2+.65
            else:
                sx, sy = p.sx*.55, p.sy*.65
            bodies.append(rectangle('terminal '+p.number, tx, ty, sx, sy, .02, min(.28, h*.4), SILVER))
    if ref in {'D1', 'D2', 'Z1'}:
        bodies.append(rectangle('cathode stripe', -w*.32, 0, .25, d*.93, h, h+.015, (188, 190, 189)))
    if ref in {'U1', 'U3', 'Q1', 'D3'}:
        bodies.append(cylinder('pin 1 mark', -w*.32, d*.28, .16, h, h+.015, (148, 150, 153), 16))
    return bodies


def _world_body(body, part):
    return Body(body.name, tuple(transform(part, x, y) for x, y in body.outline),
                body.z0, body.z1, body.rgb)


def _props(body, identity, xy=(0, 0)):
    colour = body.rgb[0] | (body.rgb[1] << 8) | (body.rgb[2] << 16)
    return {
        'V7_LAYER': 'MECHANICAL13', 'NAME': ' ', 'KIND': 0, 'SUBPOLYINDEX': -1,
        'UNIONINDEX': 0, 'ARCRESOLUTION': '0.5mil', 'ISSHAPEBASED': 'FALSE',
        'CAVITYHEIGHT': '0mil', 'STANDOFFHEIGHT': mil(body.z0),
        'OVERALLHEIGHT': mil(body.z1), 'BODYPROJECTION': 0, 'BODYCOLOR3D': colour,
        'BODYOPACITY3D': '1.000', 'IDENTIFIER': ','.join(str(ord(c)) for c in body.name),
        'TEXTURE': '', 'TEXTURECENTERX': '0mil', 'TEXTURECENTERY': '0mil',
        'TEXTURESIZEX': '0mil', 'TEXTURESIZEY': '0mil', 'TEXTUREROTATION': '0.000',
        'MODELID': '{'+str(uuid.uuid5(MODEL_NAMESPACE, identity)).upper()+'}',
        'MODEL.CHECKSUM': 0, 'MODEL.EMBED': 'FALSE', 'MODEL.NAME': '',
        'MODEL.2D.X': mil(xy[0]), 'MODEL.2D.Y': mil(xy[1]), 'MODEL.2D.ROTATION': '0.000',
        'MODEL.3D.ROTX': '0.000', 'MODEL.3D.ROTY': '0.000', 'MODEL.3D.ROTZ': '0.000',
        'MODEL.3D.DZ': '0mil', 'MODEL.MODELTYPE': 0,
        'MODEL.EXTRUDED.MINZ': mil(body.z0), 'MODEL.EXTRUDED.MAXZ': mil(body.z1),
    }


def _binary_body(body, identity, component=65535):
    prefix = bytearray(18)
    prefix[0:3] = bytes((69, 12, 0))
    prefix[3:13] = b'\xff'*10
    struct.pack_into('<H', prefix, 7, component)
    params = '|'.join(f'{k}={v}' for k, v in _props(body, identity).items()).encode('cp1252')+b'\0'
    vertices = b''.join(struct.pack('<dd', round(x/.0254*10000), round(y/.0254*10000)) for x, y in body.outline)
    payload = bytes(prefix)+struct.pack('<I', len(params))+params+struct.pack('<I', len(body.outline))+vertices
    return b'\x0c'+struct.pack('<I', len(payload))+payload


def pcb_3d_records(data):
    """Yield native PCB ASCII body records from the shared placement model.

    Shape contour syntax follows a native Altium 26 ASCII export of an installed
    example board. All contours contain straight vertices; curved packages use
    fine polygonal approximations, which retain fully editable native bodies.
    """
    index = 0
    for ci, part in enumerate(data['components']):
        for local in bodies_for(part):
            body = _world_body(local, part)
            params = base('MECHANICAL13')
            params.update(COMPONENT=ci, INDEXFORSAVE=index)
            params.update(_props(body, part['ref']+':'+body.name,
                                 (part['pcb']['x'], part['pcb']['y'])))
            params.pop('V7_LAYER')
            params['ISSHAPEBASED'] = True
            params['MAINCONTOURVERTEXCOUNT'] = len(body.outline)
            for i, (x, y) in enumerate(body.outline):
                params.update({f'KIND{i}': 0, f'VX{i}': mil(x), f'VY{i}': mil(y),
                               f'CX{i}': '0mil', f'CY{i}': '0mil', f'SA{i}': 0,
                               f'EA{i}': 0, f'R{i}': '0mil'})
            params['HOLECOUNT'] = 0
            yield record('ComponentBody', **params)
            index += 1


def add_library_3d(path, data):
    """Add bodies to a newly generated R3 PcbLib; refuses accidental duplicate use."""
    path = Path(path)
    streams = read_cfb_streams(path)
    by_pattern = {}
    for part in data['components']:
        by_pattern.setdefault(part['footprint'], part)
    count = 0
    for pattern, part in by_pattern.items():
        key = pattern+'/Data'
        if b'MODEL.EXTRUDED.MAXZ' in streams[key]:
            raise ValueError('3D bodies already present; start from newly generated PcbLib')
        bodies = bodies_for(part)
        streams[key] += b''.join(_binary_body(body, pattern+':'+body.name) for body in bodies)
        old_count, = struct.unpack('<I', streams[pattern+'/Header'])
        streams[pattern+'/Header'] = struct.pack('<I', old_count+len(bodies))
        count += len(bodies)
    write_cfb_streams(path, streams)
    assert read_cfb_streams(path) == streams
    return {'footprints': len(by_pattern), 'bodies': count}


def add_binary_pcb_3d(path, data):
    """Attach bodies to a native binary board, preserving all existing streams.

    Used after Altium converts an ASCII board to native PCB6 binary. Components
    are addressed by native SOURCEDESIGNATOR, never an assumed import order.
    """
    path = Path(path)
    streams = read_cfb_streams(path)
    raw = streams['Components6/Data']
    mapping, offset, index = {}, 0, 0
    while offset < len(raw):
        length, = struct.unpack_from('<I', raw, offset)
        text = raw[offset+4:offset+4+length].rstrip(b'\0').decode('cp1252')
        props = dict(v.split('=', 1) for v in text.split('|') if '=' in v)
        mapping[props['SOURCEDESIGNATOR']] = index
        offset += 4+length
        index += 1
    bodies = []
    for part in data['components']:
        for body in bodies_for(part):
            bodies.append(_binary_body(_world_body(body, part), part['ref']+':'+body.name, mapping[part['ref']]))
    streams['ComponentBodies6/Data'] = b''.join(bodies)
    streams['ComponentBodies6/Header'] = struct.pack('<I', len(bodies))
    # ShapeBased bodies are only an optional alternate arc-aware representation.
    streams['ShapeBasedComponentBodies6/Data'] = b''
    streams['ShapeBasedComponentBodies6/Header'] = struct.pack('<I', 0)
    write_cfb_streams(path, streams)
    assert read_cfb_streams(path) == streams
    return {'components': len(data['components']), 'bodies': len(bodies)}


def write_model_manifest(data, output):
    """Save exact reusable source geometry and transparent provenance metadata."""
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    components, total = [], 0
    for part in data['components']:
        bodies = bodies_for(part)
        total += len(bodies)
        filename = part['ref']+'.model.json'
        model = {'designator': part['ref'], 'footprint': part['footprint'], 'units': 'mm',
                 'origin': 'footprint origin; z=0 at carrier top surface',
                 'model_class': 'locally generated approximate package/assembly envelope',
                 'manufacturer_certified': False,
                 'bodies': [asdict(body) for body in bodies]}
        (output/filename).write_text(json.dumps(model, indent=2)+'\n', encoding='utf-8')
        components.append({'ref': part['ref'], 'footprint': part['footprint'], 'file': filename,
                           'body_count': len(bodies), 'height_mm': max(b.z1 for b in bodies),
                           'source': part.get('datasheet') or 'Generic footprint dimensions in design model'})
    manifest = {'components': components, 'body_count': total,
                'format': 'Altium native editable extruded 3D bodies plus local JSON geometry',
                'native_format_validation': {
                    'application': 'Altium Designer Professional 26.10.1',
                    'date': '2026-09-21',
                    'representation': 'Native PCB ASCII ComponentBody records',
                    'result': 'Opaque coloured bodies visible in native 2D/3D proof document after setting BODYPROJECTION=0 (top side).',
                    'scope': 'Serialization and top-side placement verified using a proof document; this is not a fabrication/thermal qualification of the final placement.',
                },
                'notes': ['No supplier STEP data or manufacturer certification is implied.',
                          'Pin centres and package outlines follow the linked PCB footprint.',
                          ('WROOM module is soldered directly to the carrier; package details and antenna artwork are illustrative.'
                           if any('WROOM' in p.get('value','') for p in data['components']) else
                           'SuperMini on-board component locations/colours are illustrative; module uses headers with 3.1 mm standoff, no sockets.'),
                          ('J1 is shown as bare wire-solder pads; cable wires and housing are not included.'
                           if any('WROOM' in p.get('value','') for p in data['components']) else
                           'J1 shows five pigtail wires; no selected connector housing is implied.'),
                          'Generic package heights must be checked against selected ordering codes.'],
                'references': ['https://www.altium.com/documentation/altium-designer/pcb/3d-bodies',
                               'https://www.altium.com/documentation/altium-designer/pcb/extruded-spherical-cylindrical-3d-bodies']}
    (output/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
    return {'components': len(components), 'bodies': total, 'output': str(output)}


def export_step_models(data, output, executable='C:/Program Files/FreeCAD 1.1/bin/python.exe', routing=None):
    """Export the same envelope geometry as portable STEP solids using FreeCAD.

    Colour is retained in the native Altium bodies, while these neutral CAD
    exchange files contain geometry only. The assembly includes a drilled board.
    """
    output = Path(output).resolve()
    write_model_manifest(data, output)
    if data.get('panelization'):
        raise ValueError('This STEP exporter models the single carrier; use the separate panel profile drawing for panel geometry')
    assembly = {'board': data['board'], 'parts': [], 'vias': (routing or {}).get('vias', [])}
    for part in data['components']:
        assembly['parts'].append({'ref': part['ref'], 'placement': part['pcb'],
                                  'pads': [asdict(p) for p in footprint(part).pads],
                                  'holes':part.get('pcb_footprint',{}).get('holes',[])})
    (output/'assembly-placement.json').write_text(json.dumps(assembly, indent=2)+'\n', encoding='utf-8')
    script = r'''
import json, sys
from pathlib import Path
import FreeCAD as App
import Part
sys.path.insert(0,sys.argv[2])
from altium_3d_geometry import rounded_carrier,drill_solid,world_drill
root = Path(sys.argv[1])
assembly = json.loads((root/'assembly-placement.json').read_text())
model_solids = []
for entry in assembly['parts']:
    model = json.loads((root/(entry['ref']+'.model.json')).read_text())
    solids=[]
    for body in model['bodies']:
        vertices=[App.Vector(x,y,body['z0']) for x,y in body['outline']]
        shape=Part.Face(Part.makePolygon(vertices+[vertices[0]])).extrude(App.Vector(0,0,body['z1']-body['z0']))
        if not shape.isValid(): raise ValueError('Invalid solid '+entry['ref']+' '+body['name'])
        solids.append(shape)
    compound=Part.makeCompound(solids)
    compound.exportStep(str(root/(entry['ref']+'.step')))
    placement=entry['placement']
    compound.rotate(App.Vector(0,0,0),App.Vector(0,0,1),placement.get('rotation',0))
    compound.translate(App.Vector(placement['x'],placement['y'],0))
    model_solids.append(compound)
board=assembly['board']
thickness=board.get('thickness_mm',1.6)
carrier=rounded_carrier(board)
import math
for entry in assembly['parts']:
    for pad in entry['pads']+entry.get('holes',[]):
        if not pad['drill']: continue
        x,y,diameter,length,angle=world_drill(entry,pad)
        carrier=carrier.cut(drill_solid(x,y,diameter,-thickness,thickness,length,angle))
for hole in board.get('holes_mm',[]):
    x,y,d=(hole['x'],hole['y'],hole['diameter_mm']) if isinstance(hole,dict) else (*hole,board.get('hole_diameter_mm',3.2))
    carrier=carrier.cut(Part.makeCylinder(d/2,thickness,App.Vector(x,y,-thickness)))
for via in assembly.get('vias',[]):
    carrier=carrier.cut(Part.makeCylinder(via['drill']/2,thickness,App.Vector(via['x'],via['y'],-thickness)))
if not carrier.isValid():raise ValueError('Invalid rounded/drilled carrier')
Part.makeCompound([carrier]+model_solids).exportStep(str(root/'Orion-Bridge-assembly.step'))
readback=Part.read(str(root/'Orion-Bridge-assembly.step'))
if not readback.isValid():raise ValueError('Exported assembly STEP failed OCCT readback')
print(json.dumps({'components':len(assembly['parts']),'valid_solids':sum(len(json.loads((root/(p['ref']+'.model.json')).read_text())['bodies']) for p in assembly['parts']),
                  'assembly':'Orion-Bridge-assembly.step','step_readback_valid':True,'step_readback_solids':len(readback.Solids),
                  'assembly_envelope_mm':[readback.BoundBox.XLength,readback.BoundBox.YLength,readback.BoundBox.ZLength]}))
'''
    result = subprocess.run([executable, '-c', script, str(output),str(Path(__file__).resolve().parent)], capture_output=True,
                            text=True, encoding='utf-8', errors='replace',
                            creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
    if result.returncode:
        raise RuntimeError('FreeCAD STEP export failed: '+result.stdout+'\n'+result.stderr)
    (output/'step-validation.txt').write_text(result.stdout, encoding='utf-8')
    manifest_path = output/'manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    manifest['step_exports'] = {
        'assembly': 'Orion-Bridge-assembly.step',
        'individual': {part['ref']: part['ref']+'.step' for part in data['components']},
        'colour': 'Native Altium bodies retain colours; portable STEP files contain neutral geometry.',
        'validation': 'Every generated solid passed FreeCAD/OCCT isValid() before STEP export; assembly STEP was reimported and passed isValid().',
    }
    manifest_path.write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
    return {'components': len(data['components']), 'assembly': str(output/'Orion-Bridge-assembly.step'),
            'validated_by': 'FreeCAD/OCCT solid validity checks before STEP export'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('design', type=Path)
    parser.add_argument('--models', type=Path)
    parser.add_argument('--pcblib', type=Path)
    parser.add_argument('--binary-pcb', type=Path)
    parser.add_argument('--step', type=Path)
    parser.add_argument('--routing', type=Path, help='Optional routing data to include via holes in the STEP carrier')
    args = parser.parse_args()
    data = json.loads(args.design.read_text(encoding='utf-8'))
    if args.models: print(json.dumps(write_model_manifest(data, args.models)))
    if args.pcblib: print(json.dumps(add_library_3d(args.pcblib, data)))
    if args.binary_pcb: print(json.dumps(add_binary_pcb_3d(args.binary_pcb, data)))
    if args.step: print(json.dumps(export_step_models(data, args.step, routing=json.loads(args.routing.read_text('utf8')) if args.routing else None)))
