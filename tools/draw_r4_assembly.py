"""Review-only top assembly drawing and explicit CPL orientation provenance.

No manufacturing artwork is changed. Marks identify actual reviewed pad centres.
This cannot certify a JLC library's machine-zero rotation without its preview.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import html
import json
import math
from pathlib import Path
import re
from altium_pcb import footprint,transform
from export_jlcpcb_r4 import assembly_lists


def natural(ref):
    return [int(s) if s.isdigit() else s for s in re.split(r'(\d+)',ref)]


def generate(source,out):
    data=json.loads(source.read_text('utf8'))
    out.mkdir(parents=True,exist_ok=True)
    _,cpl,unresolved,_=assembly_lists(data)
    if unresolved:raise ValueError('Unresolved assembly components')
    cpl_by_ref={r['Designator']:r for r in cpl}
    components=sorted(data['components'],key=lambda c:natural(c['ref']))
    populated=[c for c in components if c['ref'] in cpl_by_ref]
    rows=[]
    for c in populated:
        fp=footprint(c)
        p=next((p for p in fp.pads if p.number=='1'),None)
        if p is None and c['ref']=='J2':p=next(p for p in fp.pads if p.number=='A1_B12')
        if p is None:raise ValueError('No orientation reference pad for '+c['ref'])
        x,y=transform(c,p.x,p.y)
        cathode=c['ref'].startswith('D') and len(c['pins'])==2
        rows.append(dict(Designator=c['ref'],LCSC=c['assembly']['lcsc'],
            CPL_Rotation_deg=cpl_by_ref[c['ref']]['Rotation'],
            CAD_to_CPL_offset_deg=c['assembly'].get('rotation_offset_deg',0),
            Reference_pad=p.number,Reference_role='K (cathode)' if cathode else ('GND A1/B12' if c['ref']=='J2' else '1'),
            Pad_local_X_mm=round(p.x,6),Pad_local_Y_mm=round(p.y,6),
            Pad_unit_X_mm=round(x,6),Pad_unit_Y_mm=round(y,6),
            CPL_unit_X_mm=cpl_by_ref[c['ref']]['Mid X'],CPL_unit_Y_mm=cpl_by_ref[c['ref']]['Mid Y'],
            Local_footprint_source=c.get('datasheet',''),
            Rotation_provenance='CAD counterclockwise top view; JLC machine zero not independently verified; compare actual JLC assembly preview'))
    with (out/'Bestueckung-R4-Orientierung.csv').open('w',encoding='utf-8-sig',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
    refs={r['Designator']:r for r in rows}
    scale=22.;ox=70.;oy=1020.
    xy=lambda x,y:(ox+scale*x,oy-scale*y)
    esc=lambda s:html.escape(str(s))
    svg=['<svg xmlns="http://www.w3.org/2000/svg" width="2250" height="1370" viewBox="0 0 2250 1370">',
         '<rect width="2250" height="1370" fill="white"/>',
         '<g font-family="Arial, sans-serif" fill="#162d40">',
         '<text x="65" y="55" font-size="31" font-weight="bold">Orion R4 · Bestückungsplan und Orientierung</text>',
         '<text x="65" y="90" font-size="19">Oberseite, +X rechts / +Y oben · 50 bestückte Teile · Einheit 48 × 32 mm · nur Prüfzeichnung, kein Fertigungs-Siebdruck</text>',
         '<text x="65" y="124" font-size="17">Orange: Referenzpad 1 / USB A1-B12 · Rot K: Diodenkathode · Bestückungswinkel positiv gegen den Uhrzeigersinn</text>',
         '<text x="65" y="157" font-size="17">CPL-Offset 0° ist die CAD-Konvention. Die JLC-Maschinen-Nullorientierung muss in der konkreten Bestückungsvorschau abgeglichen werden.</text>']
    left,bottom=xy(0,0);top=oy-scale*data['board']['height_mm']
    svg.append(f'<rect x="{left}" y="{top}" width="{data["board"]["width_mm"]*scale}" height="{data["board"]["height_mm"]*scale}" rx="{2*scale}" fill="#edf4ef" stroke="#456458" stroke-width="2"/>')
    for h in data['board']['holes_mm']:
        x,y,diam=(h['x'],h['y'],h['diameter_mm']) if isinstance(h,dict) else (*h,data['board']['hole_diameter_mm'])
        x,y=xy(x,y);svg.append(f'<circle cx="{x}" cy="{y}" r="{diam/2*scale}" fill="white" stroke="#668075" stroke-width="1"/>')
    for c in components:
        fp=footprint(c);w,h=fp.body
        corners=[transform(c,x,y) for x,y in [(-w/2,-h/2),(w/2,-h/2),(w/2,h/2),(-w/2,h/2)]]
        cs=' '.join(f'{xy(x,y)[0]:.3f},{xy(x,y)[1]:.3f}' for x,y in corners)
        pop=c['ref'] in refs
        svg.append(f'<polygon points="{cs}" fill="{"#d7e0e8" if pop else "#f3f5f6"}" stroke="#5f7483" stroke-width="1.3"/>')
        for p in fp.pads:
            x,y=transform(c,p.x,p.y);x,y=xy(x,y)
            # Pads are transparent enough to show reference markers and bodies.
            if p.shape=='ROUND':svg.append(f'<circle cx="{x}" cy="{y}" r="{p.sx*scale/2}" fill="#b3913e" opacity=".7"/>')
            else:svg.append(f'<rect x="{x-p.sx*scale/2}" y="{y-p.sy*scale/2}" width="{p.sx*scale}" height="{p.sy*scale}" transform="rotate({-c["pcb"].get("rotation",0)} {x} {y})" fill="#b3913e" opacity=".65"/>')
            if p.drill:
                if p.drill_slot_length_mm:
                    dl=p.drill_slot_length_mm*scale;dd=p.drill*scale;angle=-(c['pcb'].get('rotation',0)+p.drill_slot_angle_deg)
                    svg.append(f'<rect x="{x-dl/2}" y="{y-dd/2}" width="{dl}" height="{dd}" rx="{dd/2}" transform="rotate({angle} {x} {y})" fill="white"/>')
                else:svg.append(f'<circle cx="{x}" cy="{y}" r="{p.drill*scale/2}" fill="white"/>')
        x,y=xy(c['pcb']['x'],c['pcb']['y'])
        angle=-c['pcb'].get('rotation',0)
        # Orient small labels along each package's long direction, preserving
        # readability in the crowded 0603 rows. All exact refs also appear tabled.
        if w<h:angle-=90
        while angle>90:angle-=180
        while angle<-90:angle+=180
        font=11 if max(w,h)<2 else (14 if max(w,h)<4 else 19)
        svg.append(f'<text x="{x}" y="{y+font*.34}" text-anchor="middle" transform="rotate({angle} {x} {y})" font-size="{font}" font-weight="bold" paint-order="stroke" stroke="white" stroke-width="3">{esc(c["ref"])}</text>')
        if pop:
            r=refs[c['ref']];px,py=xy(r['Pad_unit_X_mm'],r['Pad_unit_Y_mm']);k=r['Reference_role'].startswith('K')
            svg.append(f'<circle cx="{px}" cy="{py}" r="5.2" fill="{"#c63a30" if k else "#e78016"}" stroke="white" stroke-width="1.2"/>')
            if k:svg.append(f'<text x="{px-10}" y="{py-7}" font-size="15" font-weight="bold" fill="#ba2c24" paint-order="stroke" stroke="white" stroke-width="3">K</text>')
    svg.extend(['<text x="70" y="1080" font-size="18">J1 und TP1: nicht bestücken; externe Kabelanschlüsse/Testfläche. Kondensatoren sind unpolar.</text>',
        '<text x="70" y="1110" font-size="18">MCU1: Antenne nach +Y · J2: USB-Öffnung nach −Y · U2: Referenzpad 1 = +5V_BUS.</text>',
        '<text x="70" y="1140" font-size="18">D1/D2/D4/D5: Pad 1 = Kathode K · D3/D6: Pin 1 ist ein Signalanschluss, keine Kathodenmarke.</text>',
        '<text x="70" y="1180" font-size="17">Quelle: ausgewählte Hersteller-Footprints im Projekt; vollständige Links/Koordinaten in Bestueckung-R4-Orientierung.csv.</text>',
        '<text x="70" y="1210" font-size="17">Die Marker dienen dem Preview-Abgleich und werden nicht zusätzlich auf die Leiterplatte gedruckt.</text>'])
    tx=1190;ty=205;step=20.5
    columns=[(0,'Ref'),(75,'JLC-Teil'),(210,'CPL°'),(280,'Referenz'),(395,'lokal X/Y mm'),(605,'Einheit X/Y mm')]
    for x,label in columns:svg.append(f'<text x="{tx+x}" y="{ty}" font-size="17" font-weight="bold">{esc(label)}</text>')
    for i,r in enumerate(rows):
        y=ty+27+i*step
        if i%2==0:svg.append(f'<rect x="{tx-8}" y="{y-16}" width="950" height="{step}" fill="#f0f4f6"/>')
        values=[r['Designator'],r['LCSC'],r['CPL_Rotation_deg'],r['Reference_role'],
                f'{r["Pad_local_X_mm"]:.3f} / {r["Pad_local_Y_mm"]:.3f}',
                f'{r["Pad_unit_X_mm"]:.3f} / {r["Pad_unit_Y_mm"]:.3f}']
        for (x,_),value in zip(columns,values):svg.append(f'<text x="{tx+x}" y="{y}" font-size="16">{esc(value)}</text>')
    digest=hashlib.sha256(source.read_bytes()).hexdigest()
    svg.extend([f'<text x="65" y="1320" font-size="15">Design SHA256: {digest}</text>','</g></svg>'])
    (out/'Bestueckung-R4.svg').write_text('\n'.join(svg),encoding='utf8')
    report=dict(populated_components=len(rows),unique_references=len(refs),
        reference_markers=len(rows),diode_cathode_refs=[r['Designator'] for r in rows if r['Reference_role'].startswith('K')],
        cpl_rotations_match=True,source_sha256=digest,
        machine_zero_independently_verified=False,
        note='Review actual JLC preview; reference land1 / USB A1-B12 shown at exact manufacturer local footprint positions.')
    (out/'Bestueckung-R4-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
    return report


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--design',type=Path,required=True);p.add_argument('--out',type=Path,required=True)
    args=p.parse_args();print(json.dumps(generate(args.design,args.out),indent=2))
