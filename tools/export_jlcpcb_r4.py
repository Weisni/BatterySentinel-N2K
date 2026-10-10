"""Deterministic manufacturing export for the Orion carrier.

Gerber: RS-274X / X2, absolute 4.6 mm, top-view coordinates on EVERY layer.
Drill: Ucamco XNC-compatible Excellon, explicit decimal mm, PTH/NPTH separate.
This exporter does not imply electrical/thermal qualification or JLC stock.

Optional component assembly schema:
  {"populate": true, "lcsc": "C123", "lcsc_confirmed": true,
   "source_url": "https://...", "rotation_offset_deg": 0,
   "centroid_offset_mm": [0,0], "note": "..."}
Only confirmed, sourced components enter the paired upload BOM/CPL. Unresolved
components are listed separately and make pcba_bom_complete false. Populate=false
is an explicit assembly exclusion, not a claim that the component is unnecessary.
Footprint pad metadata may set paste=false, mask_expansion_mm, paste_expansion_mm,
or paste_windows (local x/y/sx/sy relative to pad center). Component paste=false
disables all of its paste. Default paste is 1:1 for SMD except test points.

board.silkscreen: list of {text,x,y,height,width,rotation,layer} or
{points:[[x,y],...],width,layer}; the origin of text is its bottom-left.
board.fiducials_mm: list of {x,y,diameter_mm,mask_diameter_mm,layer}.
All such geometry must also exist in the CAD master; nothing is auto-placed.

Primary format references (checked 2026-09-23):
https://www.ucamco.com/en/guest/downloads/gerber-format
https://jlcpcb.com/help/article/bill-of-materials-for-pcb-assembly
https://jlcpcb.com/help/article/pick-place-file-for-pcb-assembly
"""
from __future__ import annotations

import argparse
from collections import defaultdict
import csv
import hashlib
import json
import math
from pathlib import Path
import re
import zipfile

from altium_pcb import footprint, transform

LAYER_FILES = {
    'GTL': 'Copper,L1,Top', 'GBL': 'Copper,L2,Bot',
    'GTS': 'Soldermask,Top', 'GBS': 'Soldermask,Bot',
    'GTP': 'Paste,Top', 'GBP': 'Paste,Bot',
    'GTO': 'Legend,Top', 'GBO': 'Legend,Bot', 'GKO': 'Profile,NP',
}


def coord(value):
    if not math.isfinite(value) or abs(value) >= 10000:
        raise ValueError(f'Coordinate outside 4.6 mm format: {value}')
    return str(round(value * 1_000_000))


def decimals(value):
    return f'{value:.6f}'.rstrip('0').rstrip('.') or '0'


def quantized_contours(points):
    """Split touching contours caused by nanometre quantization, without area loss.

    A finite-width region can have a neck narrower than the output grid. Its
    collapsed repeated vertex must be expressed as two Gerber contours, not a
    self-touching polygon. Non-vertex intersections are rejected on readback.
    """
    quantized = []
    for x, y in points:
        p = (int(coord(x)), int(coord(y)))
        if not quantized or quantized[-1] != p:
            quantized.append(p)
    if quantized and quantized[-1] == quantized[0]:
        quantized.pop()
    # Node vertices which fall exactly on a nonadjacent edge after rounding.
    # Integer cross products avoid tolerance-dependent topology decisions.
    noded = []
    for a, b in zip(quantized, quantized[1:]+quantized[:1]):
        dx, dy = b[0]-a[0], b[1]-a[1]
        points_on_edge = [p for p in quantized if (p[0]-a[0])*dy == (p[1]-a[1])*dx
                          and min(a[0],b[0]) <= p[0] <= max(a[0],b[0])
                          and min(a[1],b[1]) <= p[1] <= max(a[1],b[1]) and p != b]
        noded.extend(sorted(set(points_on_edge), key=lambda p: (p[0]-a[0])*dx+(p[1]-a[1])*dy))
    def split(vertices):
        seen = {}
        for j, p in enumerate(vertices):
            if p in seen:
                i = seen[p]
                return split(vertices[i:j]) + split(vertices[:i] + vertices[j:])
            seen[p] = j
        return [vertices] if len(vertices) >= 3 else []
    return [[(x/1e6, y/1e6) for x,y in contour] for contour in split(noded)]


class Gerber:
    """Small explicit RS-274X writer; no hidden image transforms or mirroring."""
    def __init__(self, function):
        self.function = function
        self.definitions = []
        self.body = []
        self.apertures = {}
        self.selected = None

    def aperture(self, shape, sx, sy=None, rotation=0):
        sy = sx if sy is None else sy
        if min(sx, sy) <= 0:
            raise ValueError('Apertures require positive dimensions')
        rotation %= 360
        shape = shape.upper()
        if shape == 'ROUND' and abs(sx - sy) < 1e-10:
            shape, rotation = 'C', 0
        elif shape in ('RECTANGLE', 'RECT'):
            shape = 'R'
        if shape == 'R' and abs(rotation % 180 - 90) < 1e-9:
            sx, sy, rotation = sy, sx, 0
        if shape == 'R' and abs(rotation % 180) < 1e-9:
            rotation = 0
        key = (shape, round(sx, 6), round(sy, 6), round(rotation, 6))
        if key not in self.apertures:
            code = 10 + len(self.apertures)
            self.apertures[key] = code
            if shape == 'C':
                definition = f'%ADD{code}C,{decimals(sx)}*%'
            elif shape == 'R' and rotation == 0:
                definition = f'%ADD{code}R,{decimals(sx)}X{decimals(sy)}*%'
            elif shape == 'R':
                macro = f'RECT{code}'
                self.definitions.append(f'%AM{macro}*21,1,{decimals(sx)},{decimals(sy)},0,0,{decimals(rotation)}*%')
                definition = f'%ADD{code}{macro}*%'
            elif shape == 'ROUND':
                # Elliptical lands are represented as a high-resolution outline
                # aperture; error is below 0.2 um for these package dimensions.
                macro = f'ELLIPSE{code}'
                points = [(sx / 2 * math.cos(i * math.tau / 256),
                           sy / 2 * math.sin(i * math.tau / 256)) for i in range(257)]
                values = ','.join(decimals(v) for p in points for v in p)
                self.definitions.append(f'%AM{macro}*4,1,256,{values},{decimals(rotation)}*%')
                definition = f'%ADD{code}{macro}*%'
            else:
                raise ValueError(f'Unsupported pad shape {shape}; do not approximate silently')
            self.definitions.append(definition)
        code = self.apertures[key]
        if self.selected != code:
            self.body.append(f'D{code}*')
            self.selected = code

    def flash(self, x, y, shape, sx, sy=None, rotation=0):
        self.aperture(shape, sx, sy, rotation)
        self.body.append(f'X{coord(x)}Y{coord(y)}D03*')

    def line(self, points, width):
        if len(points) < 2:
            raise ValueError('A line needs two points')
        self.aperture('C', width)
        self.body.append('G01*')
        for i, (x, y) in enumerate(points):
            self.body.append(f'X{coord(x)}Y{coord(y)}D{2 if i == 0 else 1:02}*')

    def region(self, points, holes=()):
        self.body.extend(['G01*', 'G36*'])
        for contour in [part for contour in [points, *holes] for part in quantized_contours(contour)]:
            contour = list(contour)
            if contour[-1] != contour[0]:
                contour.append(contour[0])
            for i, (x, y) in enumerate(contour):
                self.body.append(f'X{coord(x)}Y{coord(y)}D{2 if i == 0 else 1:02}*')
        self.body.append('G37*')

    def rounded_outline(self, width, height, radius):
        if not 0 <= radius <= min(width, height) / 2:
            raise ValueError('Invalid corner radius')
        if radius == 0:
            self.line([(0, 0), (width, 0), (width, height), (0, height), (0, 0)], .05)
            return
        r, w, h = radius, width, height
        self.aperture('C', .05)
        self.body.extend(['G75*', f'X{coord(r)}Y0D02*'])
        for end, arc, offset in [((w-r, 0), (w, r), (0, r)),
                                  ((w, h-r), (w-r, h), (-r, 0)),
                                  ((r, h), (0, h-r), (0, -r)),
                                  ((0, r), (r, 0), (r, 0))]:
            self.body.extend(['G01*', f'X{coord(end[0])}Y{coord(end[1])}D01*', 'G03*',
                              f'X{coord(arc[0])}Y{coord(arc[1])}I{coord(offset[0])}J{coord(offset[1])}D01*'])
        self.body.append('G01*')

    def write(self, path):
        polarity = 'Negative' if self.function.startswith('Soldermask,') else 'Positive'
        header = ['G04 Orion carrier manufacturing export - mm - common top-view origin*',
                  '%FSLAX46Y46*%', '%MOMM*%', f'%TF.FileFunction,{self.function}*%',
                  f'%TF.FilePolarity,{polarity}*%', '%TF.Part,Single*%', '%TF.SameCoordinates*%',
                  *self.definitions, '%LPD*%', 'G01*', 'G75*']
        Path(path).write_text('\n'.join(header + self.body + ['M02*', '']), encoding='ascii')


# Compact single-stroke engineering lettering. Grid coordinates are normalized;
# typography is deliberately independent of installed fonts and OS rendering.
GLYPHS = {
 'A': '04 12 24|03 23', 'B': '00 04 14 23 12 02|12 21 10 00',
 'C': '24 04 00 20', 'D': '00 04 14 23 21 10 00', 'E': '24 04 00 20|02 12',
 'F': '00 04 24|02 12', 'G': '24 04 00 20 22 12', 'H': '00 04|20 24|02 22',
 'I': '04 24|14 10|00 20', 'J': '24 21 10 00 01', 'K': '00 04|24 02 20',
 'L': '04 00 20', 'M': '00 04 12 24 20', 'N': '00 04 20 24',
 'O': '00 04 24 20 00', 'P': '00 04 24 22 02', 'Q': '00 04 24 20 00|11 20',
 'R': '00 04 24 22 02|12 20', 'S': '24 04 02 22 20 00', 'T': '04 24|14 10',
 'U': '04 00 20 24', 'V': '04 10 24', 'W': '04 00 12 20 24',
 'X': '04 20|00 24', 'Y': '04 12 24|12 10', 'Z': '04 24 00 20',
 '0': '00 04 24 20 00', '1': '03 14 10|00 20', '2': '04 24 22 02 00 20',
 '3': '04 24 20 00|02 22', '4': '04 02 22|24 20', '5': '24 04 02 22 20 00',
 '6': '24 04 00 20 22 02', '7': '04 24 00', '8': '00 04 24 20 00|02 22',
 '9': '20 24 04 02 22', '-': '02 22', '+': '02 22|10 14',
 '/': '00 24', ':': '11 11|13 13', '.': '10 10', '_': '00 20',
}


def silk_segments(item):
    width = item.get('width', .15)
    if 'points' in item:
        return [(item['points'], width)]
    height = item.get('height', 1)
    angle = math.radians(item.get('rotation', 0))
    answer = []
    for index, char in enumerate(item['text'].upper()):
        if char == ' ':
            continue
        if char not in GLYPHS:
            raise ValueError(f'Unsupported silkscreen character {char!r}')
        for path in GLYPHS[char].split('|'):
            pts = []
            for pair in path.split():
                x, y = (int(pair[0]) + index * 3) * height / 4, int(pair[1]) * height / 4
                if item.get('layer','TOP').upper() in ('BOTTOM','BOTTOMOVERLAY'):
                    x = -x
                pts.append((item['x'] + x * math.cos(angle) - y * math.sin(angle),
                            item['y'] + x * math.sin(angle) + y * math.cos(angle)))
            answer.append((pts, width))
    return answer


def component_side(component):
    side = component.get('pcb', {}).get('layer', 'TOP').upper()
    if side not in ('TOP', 'BOTTOM'):
        raise ValueError(f'Unknown component layer {side}')
    # Existing altium_pcb.transform is top-placement only. Reject bottom assembly
    # until the CAD master explicitly provides its already mirrored geometry.
    if side == 'BOTTOM':
        raise ValueError('Bottom components require a reviewed bottom-footprint transform; not supported by this CAD master')
    return side


def pad_metadata(component, number):
    return next((p for p in component.get('pcb_footprint', {}).get('pads', [])
                 if str(p['number']) == str(number)), {})


def write_drill(path, holes, plated):
    tools = {d: i + 1 for i, d in enumerate(sorted({round(h[2], 6) for h in holes}))}
    rows = ['M48', '; EXPLICIT DECIMAL MM; COMMON GERBER ORIGIN',
            f'; TYPE={"PLATED" if plated else "NON_PLATED"}',
            f'; #@! TF.FileFunction,{"Plated" if plated else "NonPlated"},1,2,{"PTH" if plated else "NPTH"}*', 'METRIC']
    rows.extend(f'T{n:02}C{decimals(d)}' for d, n in tools.items())
    rows.extend(['%', 'G05'])
    for d, n in tools.items():
        rows.append(f'T{n:02}')
        for hole in holes:
            x, y, drill = hole[:3]
            if round(drill, 6) == d:
                if len(hole) == 3:
                    rows.extend(['G05', f'X{x:.6f}Y{y:.6f}'])
                else:
                    length, angle = hole[3:]
                    if length < drill:
                        raise ValueError('Finished slot length cannot be less than its width')
                    a = math.radians(angle)
                    dx, dy = (length-drill)/2*math.cos(a), (length-drill)/2*math.sin(a)
                    rows.extend([f'G00X{x-dx:.6f}Y{y-dy:.6f}', 'M15',
                                 f'G01X{x+dx:.6f}Y{y+dy:.6f}', 'M16'])
    rows.append('M30')
    Path(path).write_text('\n'.join(rows) + '\n', encoding='ascii')


def csv_write(path, fieldnames, rows):
    with Path(path).open('w', newline='', encoding='utf-8-sig') as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def assembly_lists(data):
    groups = defaultdict(list)
    cpl, unresolved, excluded = [], [], []
    for c in data['components']:
        a = c.get('assembly', {})
        if a.get('populate') is False:
            excluded.append(dict(Designator=c['ref'], Comment=c['value'], Reason=a.get('note', 'Explicitly excluded from assembly')))
            continue
        code = a.get('lcsc', '')
        if not (re.fullmatch(r'C[0-9]+', code) and a.get('lcsc_confirmed') is True and a.get('source_url')):
            unresolved.append(dict(Designator=c['ref'], Comment=c['value'], Footprint=c['footprint'],
                                   MPN=c.get('mpn', ''), Reason=a.get('note', 'No confirmed supplier code and source evidence')))
            continue
        groups[(c['value'], c['footprint'], code)].append(c['ref'])
        ox, oy = a.get('centroid_offset_mm', [0, 0])
        x, y = transform(c, ox, oy)
        cpl.append({'Designator': c['ref'], 'Mid X': f'{x:.6f}mm', 'Mid Y': f'{y:.6f}mm',
                    'Layer': component_side(c).title(),
                    'Rotation': decimals((c['pcb'].get('rotation', 0) + a.get('rotation_offset_deg', 0)) % 360)})
    bom = [dict(Comment=value, Designator=','.join(refs), Footprint=fp, **{'LCSC Part #': code})
           for (value, fp, code), refs in sorted(groups.items())]
    return bom, cpl, unresolved, excluded


def export(data, routing, out, name='Orion-Bridge-R4', source_paths=()):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    gerbers = {ext: Gerber(function) for ext, function in LAYER_FILES.items()}
    pth, npth = [], []
    mask_expansion = data.get('manufacturing', {}).get('mask_expansion_mm', .05)
    paste_expansion = data.get('manufacturing', {}).get('paste_expansion_mm', 0)
    counts = defaultdict(int)
    for c in data['components']:
        side = component_side(c)
        rotation = c['pcb'].get('rotation', 0)
        for hole in c.get('pcb_footprint', {}).get('holes', []):
            if hole.get('plated') is not False:
                raise ValueError('Mechanical footprint holes must explicitly be nonplated')
            x, y = transform(c, hole['x'], hole['y'])
            npth.append((x, y, hole['drill']))
            for ext in ('GTS', 'GBS'):
                gerbers[ext].flash(x, y, 'ROUND', hole['drill']+2*hole.get('mask_expansion_mm', mask_expansion))
        for p in footprint(c).pads:
            meta = pad_metadata(c, p.number)
            if meta.get('plated') is False or meta.get('rotation', 0):
                raise ValueError(f'{c["ref"]}.{p.number}: unsupported pad metadata in CAD master')
            x, y = transform(c, p.x, p.y)
            copper = ('GTL', 'GBL') if p.drill else ('GTL',)
            mask = ('GTS', 'GBS') if p.drill else ('GTS',)
            for ext in copper:
                gerbers[ext].flash(x, y, p.shape, p.sx, p.sy, rotation)
            expansion = meta.get('mask_expansion_mm', mask_expansion)
            for ext in mask:
                if expansion is not None:
                    gerbers[ext].flash(x, y, p.shape, p.sx + 2 * expansion, p.sy + 2 * expansion, rotation)
            if p.drill:
                hole = (x, y, p.drill)
                if meta.get('drill_slot_length_mm'):
                    hole += (meta['drill_slot_length_mm'], (rotation+meta.get('drill_slot_angle_deg', 0)) % 180)
                pth.append(hole)
            elif c.get('assembly',{}).get('populate',True) is not False and c.get('paste', True) and meta.get('paste', not c['ref'].startswith('TP')):
                expansion = meta.get('paste_expansion_mm', paste_expansion)
                windows = meta.get('paste_windows')
                if windows is None:
                    gerbers['GTP'].flash(x, y, p.shape, p.sx + 2 * expansion, p.sy + 2 * expansion, rotation)
                else:
                    for window in windows:
                        wx, wy = transform(c, p.x + window.get('x', 0), p.y + window.get('y', 0))
                        gerbers['GTP'].flash(wx, wy, window.get('shape', 'RECTANGLE'), window['sx'], window['sy'], rotation)
            counts['pads'] += 1
    for track in routing['tracks']:
        gerbers['GTL' if track['layer'] == 'TOP' else 'GBL'].line(
            [(track['x1'], track['y1']), (track['x2'], track['y2'])], track['width'])
    for via in routing['vias']:
        for ext in ('GTL', 'GBL'):
            gerbers[ext].flash(via['x'], via['y'], 'ROUND', via['diameter'])
        pth.append((via['x'], via['y'], via['drill']))
        # Both sides tented: intentionally no soldermask or paste aperture.
    for region in routing.get('regions', []):
        ext = 'GTL' if region['layer'] == 'TOP' else 'GBL'
        gerbers[ext].region(region.get('points', region.get('exterior')), region.get('holes', []))
    board = data['board']
    for hole in board.get('holes_mm', []):
        if isinstance(hole, dict):
            x, y, d = hole['x'], hole['y'], hole['diameter_mm']
        else:
            x, y = hole
            d = board['hole_diameter_mm']
        npth.append((x, y, d))
        for ext in ('GTS', 'GBS'):
            gerbers[ext].flash(x, y, 'ROUND', d + 2*mask_expansion)
    for fid in board.get('fiducials_mm', []):
        layer = fid.get('layer', 'TOP')
        gerbers['GTL' if layer == 'TOP' else 'GBL'].flash(fid['x'], fid['y'], 'ROUND', fid.get('diameter_mm', 1))
        gerbers['GTS' if layer == 'TOP' else 'GBS'].flash(fid['x'], fid['y'], 'ROUND', fid.get('mask_diameter_mm', 2))
    for item in board.get('silkscreen', []):
        ext = 'GTO' if item.get('layer', 'TOP') == 'TOP' else 'GBO'
        for points, width in silk_segments(item):
            gerbers[ext].line(points, width)
    gerbers['GKO'].rounded_outline(board['width_mm'], board['height_mm'], board.get('corner_radius_mm', 0))
    files = []
    for ext, gerber in gerbers.items():
        path = out / f'{name}.{ext}'
        gerber.write(path)
        files.append(path)
    for suffix, holes, plated in [('PTH', pth, True), ('NPTH', npth, False)]:
        path = out / f'{name}-{suffix}.drl'
        write_drill(path, holes, plated)
        files.append(path)
    with zipfile.ZipFile(out / f'{name}-Gerber.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in files:
            archive.write(path, path.name)
    bom, cpl, unresolved, excluded = assembly_lists(data)
    csv_write(out / 'BOM-JLCPCB.csv', ['Comment', 'Designator', 'Footprint', 'LCSC Part #'], bom)
    csv_write(out / 'CPL-JLCPCB.csv', ['Designator', 'Mid X', 'Mid Y', 'Layer', 'Rotation'], cpl)
    csv_write(out / 'BOM-UNRESOLVED.csv', ['Designator', 'Comment', 'Footprint', 'MPN', 'Reason'], unresolved)
    csv_write(out / 'BOM-EXCLUDED.csv', ['Designator', 'Comment', 'Reason'], excluded)
    manifest = dict(format='Orion manufacturing manifest v1', name=name,
                    coordinate_system='mm, bottom-left origin, top-view +X right +Y up; no layer mirrored',
                    board=board, pad_count=counts['pads'], tracks=len(routing['tracks']),
                    vias=len(routing['vias']), regions=len(routing.get('regions', [])),
                    pth_count=len(pth), npth_count=len(npth),
                    pcba_bom_complete=not unresolved, sourced_components=len(cpl),
                    unresolved_components=unresolved, excluded_components=excluded,
                    qualification='Manufacturing file conversion only; see design, geometry, native CAD DRC and sourcing reviews',
                    sources=[dict(path=str(p), sha256=hashlib.sha256(Path(p).read_bytes()).hexdigest()) for p in source_paths],
                    files={p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in files},
                    references=[
                        'https://www.ucamco.com/en/guest/downloads/gerber-format',
                        'https://jlcpcb.com/help/article/bill-of-materials-for-pcb-assembly',
                        'https://jlcpcb.com/help/article/pick-place-file-for-pcb-assembly'])
    (out / 'manufacturing-manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--design', type=Path, required=True)
    parser.add_argument('--routing', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--name', default='Orion-Bridge-R4')
    args = parser.parse_args()
    manifest = export(json.loads(args.design.read_text('utf-8')), json.loads(args.routing.read_text('utf-8')),
                      args.out, args.name, [args.design, args.routing])
    print(json.dumps({key: manifest[key] for key in ('pad_count', 'tracks', 'vias', 'pth_count',
                                                    'npth_count', 'pcba_bom_complete', 'sourced_components')}, indent=2))


if __name__ == '__main__':
    main()
