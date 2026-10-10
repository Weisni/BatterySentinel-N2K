"""Build release-bound hand-assembly documents without changing Altium sources.

Requires reportlab, openpyxl and pypdf. Geometry and nets come exclusively from
the ASCII PCB inside the release ZIP. The procurement overlay is explicit.
"""
from __future__ import annotations

import csv
import hashlib
import io
import json
import math
import re
import sys
from collections import Counter
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from xml.sax.saxutils import escape

import openpyxl
from pypdf import PdfReader
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph, Table, TableStyle
from reportlab.graphics.shapes import Drawing, Line, Rect, Circle, Polygon, String
from reportlab.graphics import renderPDF, renderSVG

ROOT = Path(__file__).resolve().parents[1]
R5 = ROOT / 'hardware/altium-r5'
RELEASE = R5 / 'Project Outputs/BatterySentinel-N2K-Orion-R5.zip'
OUT = R5 / 'Project Outputs/Hand Assembly'
PDF = ROOT / 'output/pdf/Orion-R5-Hand-Assembly-EN.pdf'
DATE = '2026-10-07'
INK = colors.HexColor('#173449')
BLUE = colors.HexColor('#126c92')
GOLD = colors.HexColor('#c58b27')
RED = colors.HexColor('#c63e36')
PALE = colors.HexColor('#edf4f7')
GRAY = colors.HexColor('#91a0a8')
W, H = landscape(A4)

# Derived from the two local procurement records, not the automatic PCBA BOM.
# references, purchased MPN, LCSC, hand-solder package, assembly note
GROUPS = [
 ('R2', '0603WAF1002T5E', 'C25804', '0603', '10 kOhm, 1%, 0.1 W'),
 ('R3 R4', '0603WAF330JT5E', 'C23140', '0603', '33 Ohm, 1%'),
 ('R20 R21', 'RNCP1206FTD150R', 'C4258541', '1206', '150 Ohm, 1%, 0.5 W each; both required'),
 ('C4 C5 C24 C26 C28 C30 C31', 'CC0603KRX7R9BB104', 'C14663', '0603', '100 nF, 50 V, X7R; non-polar ceramic'),
 ('C20 C21', 'CL32B106KBJNNNE', 'C138687', '1210', '10 uF, 50 V, X7R; non-polar ceramic'),
 ('C22 C23 C27 C32 C33', 'CL31A226KAHNNNE', 'C12891', '1206', '22 uF, 25 V, X5R; non-polar ceramic'),
 ('C25 C29 C34', 'CL21A106KAYNNNE', 'C15850', '0805', '10 uF, 25 V, X5R; non-polar ceramic'),
 ('F1', 'SF-1206S080-2', 'C3032873', '1206 fuse', '0.8 A slow-blow, 63 VDC; non-polar'),
 ('L2 L3', 'FNR4030S4R7MT', 'C167874', '4 x 4 mm', '4.7 uH; purchased replacement; two-terminal, non-polar'),
 ('D1', 'SMBJ18A', 'C152104', 'SMB', 'Unidirectional TVS: cathode stripe toward RIGHT'),
 ('D5', 'SS26', 'C14238', 'SMA', 'Schottky: cathode stripe toward RIGHT'),
 ('D3', 'PESD2CAN24T-QR', 'C28933048', 'SOT-23', 'Single lead LEFT; pin 1 lower-right, pin 2 upper-right'),
 ('U3 U4', 'AP63205WU-7', 'C2071056', 'TSOT-26', 'Pin 1 lower-left in board top view; fixed 5 V version'),
 ('U1', 'ISO1042DWVR', 'C2671714', 'SOIC-8 DWV', 'Pin 1 lower-right in board top view'),
 ('L1', 'PSCIAQ4532-510Z', 'C2932173', '4.5 x 3.2 mm', 'Purchased replacement; winding pairs 1-4 and 2-3'),
 ('U2', 'B0505S-3WR2', 'C7500927', 'SIP-4 THT', 'Pin row LEFT to RIGHT: 1, 2, 4, 6; body toward lower edge'),
 ('SW3', 'MK-12C02-G020', 'C963206', 'side SPDT', 'Actuator toward TOP board edge; verify RUN/SERVICE electrically'),
]
INFO = {ref: {'mpn': mpn, 'lcsc': code, 'package': package, 'note': note}
        for refs, mpn, code, package, note in GROUPS for ref in refs.split()}
INFO.update({
 'MCU1': {'mpn': 'ESP32-C3 SuperMini, ASIN B0FN4F6244', 'lcsc': '', 'package': 'castellated module', 'note': 'USB RIGHT, antenna LEFT; solder all 16 outer lands; no headers'},
 'J1': {'mpn': 'NMEA Micro-C pigtail, ASIN B0DTHSNSHS', 'lcsc': '', 'package': 'five wire holes', 'note': 'Cable termination; no discrete PCB connector'},
 'TP1': {'mpn': '', 'lcsc': '', 'package': 'bare copper pad', 'note': 'No purchased component; SHIELD access; do not bridge to either ground'},
})
LABELS = {
 'J1':(-3,16), 'TP1':(-3,27), 'D3':(3,24.4), 'L1':(9,27.7),
 'U1':(19.5,22.5), 'C4':(15,16.7), 'C5':(25.3,16.2),
 'R2':(25.5,33.8), 'R3':(29,33.8), 'R4':(32,35.5),
 'U3':(12,10.3), 'U4':(40.2,10.4), 'U2':(21,3),
 'L2':(7.5,9.2), 'L3':(36.25,7.45), 'C20':(18.2,10.5),
 'C21':(18.2,13.5), 'C22':(5.5,0.8), 'C23':(9.5,0.8),
 'C24':(8,12.3), 'C25':(12.2,5), 'C26':(18.8,8.5),
 'C27':(28.8,12.3), 'C28':(31,9.2), 'C29':(44,2),
 'C30':(48.6,4.7), 'C31':(40,12.3), 'C32':(33,5.5),
 'C33':(34.3,-1.3), 'R20':(23.6,9.4), 'R21':(23.6,16.4),
 'D1':(10.5,20.7), 'D5':(9.2,16.4), 'F1':(3.2,14),
 'C34':(48,10.1), 'SW3':(39,37.2), 'MCU1':(40,20),
}

def mm(s):
    if s.endswith('mil'):
        return float(s[:-3]) * .0254
    if s.endswith('mm'):
        return float(s[:-2])
    return float(s)

def key(ref):
    p = re.match(r'([A-Z]+)(\d+)', ref)
    return p[1], int(p[2])

def sha(data):
    return hashlib.sha256(data).hexdigest()

def vertices(record):
    return [(mm(record[f'VX{i}']), mm(record[f'VY{i}']))
            for i in range(10000) if f'VX{i}' in record]

def load_release():
    with ZipFile(RELEASE) as z:
        members = {n: z.read(n) for n in z.namelist() if not n.endswith('/')}
    ascii_name = 'Fabrication/ASCII/BatterySentinel-N2K-Orion-R5.PcbDoc'
    rs = [dict(s.split('=',1) for s in line.split('|') if '=' in s)
          for line in members[ascii_name].decode('utf-8-sig').splitlines()]
    comps = {r['SOURCEDESIGNATOR']: r for r in rs if r.get('RECORD') == 'Component'}
    ids = {r['ID']: ref for ref, r in comps.items()}
    nets = {r['ID']: r['NAME'] for r in rs if r.get('RECORD') == 'Net'}
    pads = []
    for r in rs:
        if r.get('RECORD') != 'Pad': continue
        ref = ids.get(r.get('COMPONENT'), '')
        pads.append({'ref': ref, 'pin': r.get('NAME',''),
                     'x': mm(r['X']), 'y': mm(r['Y']),
                     'sx': mm(r['XSIZE']), 'sy': mm(r['YSIZE']),
                     'angle': float(r['ROTATION']), 'hole': mm(r.get('HOLESIZE','0mil')),
                     'shape': r['SHAPE'], 'layer': r['LAYER'],
                     'net': nets.get(r.get('NET'), 'NC'), 'plated': r.get('PLATED','FALSE')})
    text = members['Assembly/Pick Place/Pick Place for BatterySentinel-N2K-Orion-R5.csv'].decode('utf-8-sig')
    text = text[text.index('"Center-X(mm)"'):]
    placements = {r['Designator']: r for r in csv.DictReader(io.StringIO(text))}
    book = openpyxl.load_workbook(io.BytesIO(members['Assembly/BOM/Bill of Materials-BatterySentinel-N2K-Orion-R5.xlsx']), data_only=True)
    bom = list(book.active.values)[1:]
    bom_refs = [ref.strip() for row in bom for ref in row[2].split(',')]
    checks = []
    def require(condition, description):
        if not condition: raise ValueError(description)
        checks.append(description)
    require(set(comps) == set(placements) == set(bom_refs) == set(INFO), 'All 37 references agree across release ASCII PCB, CPL, BOM and manual overlay')
    require(len(bom_refs) == len(set(bom_refs)) == 37, 'No duplicated or omitted release BOM references')
    require(sum(int(row[5]) for row in bom) == 37, 'Release BOM quantity total is 37 including J1/TP1/MCU1')
    require(sum(len(g[0].split()) for g in GROUPS) == 34, 'Procurement overlay contains exactly 34 carrier components in 17 groups')
    for ref, comp in comps.items():
        p = placements[ref]
        require(comp['LAYER'] == 'TOP' and p['Layer'] == 'TopLayer', f'{ref}: TOP-side placement confirmed')
        require(comp['PATTERN'] == p['Footprint'], f'{ref}: footprint agrees with CPL')
        require(abs(mm(comp['X']) - mm(p['Ref-X(mm)'])) < .001 and abs(mm(comp['Y']) - mm(p['Ref-Y(mm)'])) < .001, f'{ref}: component origin agrees with CPL reference coordinates within 0.001 mm')
        require(abs(float(comp['ROTATION']) - float(p['Rotation'])) < .001, f'{ref}: rotation agrees with CPL')
    design = json.loads((R5/'orion-r5-design.json').read_text(encoding='utf-8-sig'))
    dc = {c['ref']: c for c in design['components']}
    for pad in pads:
        if not pad['ref'] or not pad['pin']: continue
        pins = {p['number']: p['net'] or 'NC' for p in dc[pad['ref']]['pins']}
        require(pad['net'] == pins[pad['pin']], f"{pad['ref']}.{pad['pin']}: release net agrees with design connectivity")
    require(len(pads) == 120, 'Release contains 120 pads including six non-plated mechanical holes')
    require(sum(bool(p['ref'] and p['pin']) for p in pads) == 114, '114 numbered electrical pads accounted for')
    for g in GROUPS:
        for ref in g[0].split():
            require(g[2] in ((R5/'lcsc-order-2026-09-24.md').read_text(encoding='utf-8-sig') + (R5/'lcsc-preisvergleich-2026-09-23.md').read_text(encoding='utf-8-sig')), f'{ref}: purchased supplier code present in procurement records')
    return rs, comps, pads, placements, members, checks

def board_drawing(rs, comps, pads, selected=None, labels=True, pad_numbers=False):
    d = Drawing(68, 46)
    dx, dy = 8, 5
    active = set(comps) if selected is None else set(selected)
    board = next(r for r in rs if r.get('RECORD') == 'Board' and 'VX0' in r)
    v = vertices(board)
    d.add(Polygon([c for x,y in v for c in (x+dx,y+dy)], fillColor=colors.HexColor('#fafcfd'), strokeColor=INK, strokeWidth=.16))
    for r in rs:
        if r.get('RECORD')=='Region' and r.get('LAYER')=='KEEPOUT' and r.get('NAME')=='SuperMini antenna relief':
            d.add(Polygon([c for x,y in vertices(r) for c in (x+dx,y+dy)], fillColor=colors.white, strokeColor=INK, strokeWidth=.12))
    for ref,comp in comps.items():
        tracks = [r for r in rs if r.get('RECORD')=='Track' and r.get('LAYER')=='MECHANICAL13' and r.get('COMPONENT')==comp['ID']]
        if not tracks: continue
        xs = [mm(r[k]) for r in tracks for k in ['X1','X2']]
        ys = [mm(r[k]) for r in tracks for k in ['Y1','Y2']]
        col = colors.HexColor('#dceaf0') if ref in active else colors.HexColor('#f1f2f2')
        d.add(Rect(min(xs)+dx,min(ys)+dy,max(xs)-min(xs),max(ys)-min(ys), fillColor=col, strokeColor=GRAY, strokeWidth=.06))
    for r in rs:
        if r.get('RECORD')=='Track' and r.get('LAYER')=='MECHANICAL1':
            d.add(Line(mm(r['X1'])+dx,mm(r['Y1'])+dy,mm(r['X2'])+dx,mm(r['Y2'])+dy,strokeColor=INK,strokeWidth=.08))
    for p in pads:
        col = GOLD if p['ref'] in active else colors.HexColor('#d5d9db')
        sx, sy = p['sx'], p['sy']
        if int(round(p['angle']))%180 == 90: sx,sy = sy,sx
        x,y = p['x']+dx,p['y']+dy
        if p['shape']=='ROUND' and abs(sx-sy)<.001:
            d.add(Circle(x,y,sx/2,fillColor=col,strokeColor=None))
        else:
            d.add(Rect(x-sx/2,y-sy/2,sx,sy,fillColor=col,strokeColor=None))
        if p['hole']:
            d.add(Circle(x,y,p['hole']/2,fillColor=colors.white,strokeColor=GRAY,strokeWidth=.035))
        if p['ref'] in active and p['pin']=='1' and p['ref'] in ['D1','D3','D5','U1','U2','U3','U4','L1']:
            d.add(Circle(x,y,.18,fillColor=RED,strokeColor=None))
        if pad_numbers and p['pin'] and p['ref'] in active:
            d.add(String(x,y-.18,p['pin'],fontName='Helvetica-Bold',fontSize=.5,textAnchor='middle',fillColor=INK))
    for x,y in [(3,3),(3,33),(49,3),(49,33)]:
        d.add(Circle(x+dx,y+dy,1.1,fillColor=colors.white,strokeColor=INK,strokeWidth=.08))
    # Text is intentionally an annotation; geometry remains the release geometry.
    if labels:
        for ref in sorted(active,key=key):
            cx,cy = mm(comps[ref]['X']),mm(comps[ref]['Y'])
            lx,ly = LABELS[ref]
            fs=.85
            width=len(ref)*fs*.58+.45
            d.add(Line(cx+dx,cy+dy,lx+dx,ly+dy,strokeColor=BLUE,strokeWidth=.05))
            d.add(Rect(lx+dx-width/2,ly+dy-.27,width,1.05,fillColor=colors.white,strokeColor=None))
            d.add(String(lx+dx,ly+dy,ref,fontName='Helvetica-Bold',fontSize=fs,textAnchor='middle',fillColor=INK))
    for x in range(0,53,10):
        d.add(String(x+dx,dy-3.4,str(x),fontName='Helvetica',fontSize=.55,textAnchor='middle',fillColor=GRAY))
    d.add(Line(dx,dy-2.2,dx+52,dy-2.2,strokeColor=GRAY,strokeWidth=.06))
    d.add(String(dx+26,dy-4.6,'X (mm) - origin lower-left',fontSize=.62,textAnchor='middle',fillColor=GRAY))
    d.add(String(dx+49,dy+20,'USB >',fontName='Helvetica-Bold',fontSize=.85,fillColor=BLUE))
    d.add(String(dx+30.5,dy+20,'ANT',fontSize=.65,textAnchor='middle',fillColor=GRAY))
    return d

class Manual:
    def __init__(self):
        PDF.parent.mkdir(parents=True,exist_ok=True)
        self.c=canvas.Canvas(str(PDF),pagesize=(W,H))
        self.c.setTitle('Orion-R5 - release-bound hand assembly')
        self.c.setAuthor('BatterySentinel-N2K')
        self.page=0
    def start(self,title,subtitle):
        if self.page: self.c.showPage()
        self.page+=1
        c=self.c
        c.setFillColor(INK); c.rect(0,H-76,W,76,fill=1,stroke=0)
        c.setFillColor(colors.white); c.setFont('Helvetica-Bold',22); c.drawString(34,H-37,title)
        c.setFont('Helvetica',10); c.drawString(34,H-58,subtitle)
        c.setFillColor(GRAY); c.setFont('Helvetica',8)
        c.drawString(34,22,f'Orion-R5 | Release 2026-09-23 | Hand assembly {DATE} | All board diagrams: TOP VIEW')
        c.drawRightString(W-34,22,f'{self.page}')
    def para(self,text,x,y,width,size=10,color=INK):
        style=ParagraphStyle('body',fontName='Helvetica',fontSize=size,leading=size*1.35,textColor=color)
        p=Paragraph(text,style); _,height=p.wrap(width,1000); p.drawOn(self.c,x,y-height)
        return y-height
    def table(self,rows,x,y,widths,size=9):
        style=ParagraphStyle('cell',fontName='Helvetica',fontSize=size,leading=size*1.18,textColor=INK)
        data=[[Paragraph(escape(str(cell)).replace('\n','<br/>'),style) for cell in row] for row in rows]
        t=Table(data,colWidths=widths)
        t.setStyle(TableStyle([
          ('BACKGROUND',(0,0),(-1,0),PALE),('VALIGN',(0,0),(-1,-1),'TOP'),
          ('LINEBELOW',(0,0),(-1,0),.8,BLUE),('LINEBELOW',(0,1),(-1,-1),.25,colors.HexColor('#cedce2')),
          ('LEFTPADDING',(0,0),(-1,-1),5),('RIGHTPADDING',(0,0),(-1,-1),5),
          ('TOPPADDING',(0,0),(-1,-1),1 if size<7 else 2),('BOTTOMPADDING',(0,0),(-1,-1),1 if size<7 else 2),
        ]))
        _,height=t.wrap(1000,1000)
        if y-height<44: raise ValueError(f'Table does not fit page {self.page}: {height}')
        t.drawOn(self.c,x,y-height);return y-height
    def draw_board(self,d,x,y,scale):
        self.c.saveState();self.c.translate(x,y);self.c.scale(scale,scale);renderPDF.draw(d,self.c,0,0);self.c.restoreState()
    def check(self,text,x,y,width=730):
        self.c.setStrokeColor(BLUE);self.c.rect(x,y-9,8,8,fill=0,stroke=1)
        return self.para(text,x+16,y+1,width-16,10)-9
    def detail(self,ref,rs,comps,pads,x,y,width,height,footer):
        c=self.c
        c.setFillColor(PALE);c.roundRect(x,y,width,height,6,stroke=0,fill=1)
        c.setFillColor(INK);c.setFont('Helvetica-Bold',12);c.drawString(x+12,y+height-20,ref+' - '+INFO[ref]['mpn'])
        ps=[p for p in pads if p['ref']==ref and p['pin']]
        tracks=[r for r in rs if r.get('RECORD')=='Track' and r.get('LAYER')=='MECHANICAL13' and r.get('COMPONENT')==comps[ref]['ID']]
        bx=[mm(r[k]) for r in tracks for k in ['X1','X2']]
        by=[mm(r[k]) for r in tracks for k in ['Y1','Y2']]
        minx,maxx=min(bx),max(bx);miny,maxy=min(by),max(by)
        vx=[p['x'] for p in ps]+bx;vy=[p['y'] for p in ps]+by
        s=min((width-125)/(max(vx)-min(vx)+2),(height-110)/(max(vy)-min(vy)+2),26)
        ox=x+width/2-(max(vx)+min(vx))/2*s
        oy=y+height/2+8-(max(vy)+min(vy))/2*s
        c.setFillColor(colors.white);c.setStrokeColor(BLUE);c.rect(ox+minx*s,oy+miny*s,(maxx-minx)*s,(maxy-miny)*s,fill=1,stroke=1)
        midx=(max(vx)+min(vx))/2;midy=(max(vy)+min(vy))/2
        for p in ps:
            px,py=ox+p['x']*s,oy+p['y']*s
            sx,sy=p['sx'],p['sy']
            if int(round(p['angle']))%180==90:sx,sy=sy,sx
            c.setFillColor(RED if p['pin']=='1' else GOLD);c.setStrokeColor(GOLD)
            c.rect(px-sx*s/2,py-sy*s/2,sx*s,sy*s,fill=1,stroke=0)
            if p['hole']:
                c.setFillColor(colors.white);c.circle(px,py,p['hole']*s/2,fill=1,stroke=0)
            c.setFillColor(INK);c.setFont('Helvetica-Bold',9)
            # Short pin-only labels outside the lead row, preserving PCB axes.
            if ref in ['U2','SW3']:
                c.drawCentredString(px,py-19,p['pin'])
            elif ref in ['U3','U4']:
                c.drawCentredString(px,py+(14 if p['y']>midy else -22),p['pin'])
            else:
                c.drawString(px+sx*s/2+5,py-3,p['pin']) if p['x']>midx else c.drawRightString(px-sx*s/2-5,py-3,p['pin'])
        c.setStrokeColor(INK)
        if ref in ['D1','D5']:
            c.setLineWidth(3);c.line(ox+(maxx-.45)*s,oy+miny*s,ox+(maxx-.45)*s,oy+maxy*s)
            c.setLineWidth(1)
        self.para(footer,x+12,y+43,width-24,9)
    def save(self):self.c.save()

def build_pdf(rs,comps,pads,placements,members):
    m=Manual()
    m.start('Hand assembly - Orion-R5','Release geometry, purchased components and a bench checklist | English documentation')
    m.draw_board(board_drawing(rs,comps,pads),76,66,10)
    m.para('<b>Orientation:</b> component side facing you; cable pads LEFT, USB notch RIGHT, service switch at TOP. Red dot = PCB pad 1 for directional parts. No bottom-side components.',34,67,770,10)

    m.start('Purchased parts - 1 or 4 boards','17 carrier groups / 34 carrier components per board, plus one module and one cable')
    rows=[['References','Purchased MPN / LCSC','Package','1 / 4','Value and hand-assembly note']]
    for refs,mpn,code,package,note in GROUPS:
        n=len(refs.split()); rows.append([refs.replace(' ', ', '),mpn+'\n'+code,package,f'{n} / {n*4}',note])
    bottom=m.table(rows,34,H-92,[137,156,83,45,352],8)
    m.para('<b>Additional:</b> MCU1 = selected C3 SuperMini (1 / 4); J1 = NMEA cable (1 / 4); TP1 = bare copper, buy nothing. Quantities are exact board needs, with no loss/spare allowance. Package sizes 0603/0805/1206/1210 use imperial codes.',34,bottom-10,773,9)

    m.start('Per-reference placement and checklist','Mark the blank column after soldering and inspection; positions are CPL centres, in millimetres')
    rows=[['Done','Ref','Release value','Purchased code','Centre X / Y','Rot.','Handling']]
    for ref in sorted(comps,key=key):
        p=placements[ref]; i=INFO[ref]
        handle='Non-polar' if ref.startswith(('C','R')) or ref in ['L2','L3','F1'] else 'See orientation details'
        if ref=='J1':handle='Wire termination'
        if ref=='TP1':handle='Bare pad; no part'
        rows.append(['',ref,p['Comment'],i['lcsc'] or ('Amazon' if ref in ['MCU1','J1'] else '-'),f"{mm(p['Center-X(mm)']):.3f} / {mm(p['Center-Y(mm)']):.3f}",p['Rotation'],handle])
    m.table(rows,34,H-90,[30,42,170,92,122,37,280],6.9)
    m.para('Angles are the exported Altium rotations, not universal machine-rotation conventions. Use the top-view diagrams and labelled pads for manual orientation. The CSV also records component origins separately from geometric centres.',34,59,773,9)

    m.start('Step 1 - resistors and ceramic capacitors','Sort parts into labelled containers; solder low-profile parts before tall modules')
    refs=[r for r in comps if r.startswith(('C','R'))]
    m.draw_board(board_drawing(rs,comps,pads,refs),34,156,7.7)
    y=H-96
    for title,body in [
      ('Resistors','R2: 10 kOhm. R3/R4: 33 Ohm. R20/R21: 150 Ohm, 0.5 W EACH. Fit both preload resistors.'),
      ('100 nF / 0603','C4, C5, C24, C26, C28, C30, C31: 50 V X7R. All seven use the same purchased part.'),
      ('10 uF / 1210','C20, C21: 50 V X7R. Keep these apart from the smaller 25 V capacitors.'),
      ('22 uF / 1206','C22, C23, C27, C32, C33: 25 V X5R.'),
      ('10 uF / 0805','C25, C29, C34: 25 V X5R. C34 is behind the service switch.'),
    ]:
        y=m.para('<b>'+title+'</b><br/>'+body,590,y,217,10)-16
    m.para('All listed capacitors are non-polar MLCCs. Use package labels to identify unmarked capacitors. Tack one end on a lightly tinned pad, align, solder the other end, then inspect both joints. Avoid prolonged heating and mechanical stress on ceramic parts.',34,139,773,11)
    m.para('<b>Before the next step:</b> inspect for bridged pads and wrong values under magnification. The release has no C1-C3, C6-C19, R1, D2 or D4 carrier positions; do not add parts to nonexistent references.',34,84,773,10)

    m.start('Step 2 - diodes and buck regulators','TOP VIEW | Both diode cathode stripes point RIGHT, toward the module side')
    m.detail('D1',rs,comps,pads,34,297,240,205,'1 = K / BUS_PROT (RIGHT)<br/>2 = A / GND_BUS (LEFT)')
    m.detail('D5',rs,comps,pads,300,297,240,205,'1 = K / BUS_PROT (RIGHT)<br/>2 = A / FUSED_IN (LEFT)')
    m.detail('D3',rs,comps,pads,566,297,240,205,'1 = CANH_EXT, lower-right<br/>2 = CANL_EXT, upper-right<br/>3 = GND_BUS, single lead LEFT')
    m.detail('U3',rs,comps,pads,34,65,240,213,'1 FB / 2 EN / 3 VIN below<br/>6 BST / 5 SW / 4 GND above')
    m.detail('U4',rs,comps,pads,300,65,240,213,'Same pin orientation as U3.<br/>Use AP63205, fixed 5 V.')
    m.para('<b>Regulator joints</b><br/>Identify physical pin 1 from the component package marking. Match the numbered PCB pad; tack opposite corners, inspect alignment, then solder the remaining leads with flux.<br/><br/>Check all six leads for bridges. U3 uses GND_BUS; U4 uses GND_LOGIC. Preserve the isolation gap.',566,272,240,11)

    m.start('Step 3 - isolated CAN and inductors','TOP VIEW | Fit F1, L1, L2 and L3 after checking part identity and winding orientation')
    m.detail('U1',rs,comps,pads,34,206,362,296,'Pin 1 is LOWER-RIGHT. Locate the package pin-1 marker.<br/>Logic leads RIGHT; bus leads LEFT.')
    m.detail('L1',rs,comps,pads,430,206,376,296,'L1 replacement: PSCIAQ4532-510Z / C2932173.<br/>PCB winding paths must run bottom-to-top, not across.')
    rows=[['U1 lead','Function','PCB location'],['1 / 2 / 3 / 4','VCC1 / TXD / RXD / GND1','RIGHT, bottom to top'],['8 / 7 / 6 / 5','VCC2 / CANH / CANL / GND2','LEFT, bottom to top']]
    m.table(rows,34,190,[80,180,102],8.5)
    m.para('<b>L1:</b> pad 1 lower-left = CANH_EXT; 4 upper-left = CANH. Pad 2 lower-right = CANL_EXT; 3 upper-right = CANL. Before soldering, use continuity to identify the two separate windings (1-4 and 2-3). The replacement sheet does not provide a clear external pin-1 mark; do not infer one from this drawing.',430,190,376,10)
    m.para('<b>F1:</b> SF-1206S080-2, non-polar. <b>L2/L3:</b> FNR4030S4R7MT, 4.7 uH, non-polar two-terminal inductors. L1 has four terminals and is a different component. Replacement fit was reviewed digitally; check wetting of all four L1 terminals on the actual PCB.',34,79,773,10)

    m.start('Step 4 - converter and service switch','TOP VIEW | Install tall U2 after the nearby small components; keep switch travel clear')
    m.detail('U2',rs,comps,pads,34,244,440,258,'Four THT leads: 1, 2, 4, 6 LEFT to RIGHT.<br/>Row at Y=6.80 mm; body lies mainly BELOW that row.')
    m.detail('SW3',rs,comps,pads,508,244,298,258,'Contacts 1, 2, 3; shell pads 4-7.<br/>The two locating holes remain free of solder.')
    rows=[['U2 lead','Net','Role'],['1','5V_BUS','+ input'],['2','GND_BUS','Input ground'],['4','GND_LOGIC','Isolated 0 V'],['6','5V_ISO','Isolated + output']]
    m.table(rows,34,225,[60,130,250],10)
    m.para('<b>SW3 electrical check, power OFF</b><br/>RUN: contact 1 (5V_REG) connects to contact 2 (5V_MODULE). SERVICE: contact 2 connects to unconnected contact 3; 1-2 is open. Shell tabs 4-7 connect only to GND_LOGIC.<br/><br/>The release silkscreen is a location aid. Confirm actual lever positions by continuity; the supplier drawing does not establish left/right travel.',508,225,298,11)
    m.para('<b>USB sequence:</b> select SERVICE before plugging in USB. Remove USB before returning to RUN. Do not bridge SW3, and do not connect bus ground to logic ground.',34,68,773,11)

    m.start('Step 5 - ESP32-C3 SuperMini','Selected Amazon C3 module, ASIN B0FN4F6244 | USB RIGHT, antenna LEFT')
    m.draw_board(board_drawing(rs,comps,pads,['MCU1','SW3'],labels=True),34,208,7.2)
    m.para('<b>Dry fit before soldering</b><br/>Match all 16 castellations to their carrier pads. Remove any headers and solder protrusions. Check the USB underside over the right-edge notch and the antenna over the internal window.<br/><br/>Carrier pads are for direct perimeter soldering. Use no carrier headers, no paste under the module and no conductive adhesive. Tack opposing corners, recheck fit, then solder all 16 lands, including unused pins.',586,H-97,220,11)
    rows=[['X (mm)','Upper row Y=28.60','Lower row Y=11.40']]
    ups=sorted([p for p in pads if p['ref']=='MCU1' and p['y']>20],key=lambda p:p['x'])
    lows=sorted([p for p in pads if p['ref']=='MCU1' and p['y']<20],key=lambda p:p['x'])
    for up,low in zip(ups,lows):
        upper_note = 'CAN TX' if up['pin']=='6' else 'CAN RX' if up['pin']=='7' else 'unused'
        lower_name = 'GPIO'+low['pin'] if low['pin'].isdigit() else low['pin']
        rows.append([f"{up['x']:.3f}",'GPIO'+up['pin']+' / '+upper_note,lower_name+(' / '+low['net'] if low['net']!='NC' else ' / unused')])
    m.table(rows,34,201,[95,290,388],8.8)
    m.para('GPIO6 = CAN TX; GPIO7 = CAN RX. The module 3V3 pin is an OUTPUT to U1/C5. Verify the delivered C3 pin labels; reject a different pinout. Mechanical clone fit and radio operation remain physical acceptance checks.',34,61,773,10)

    m.start('Step 6 - cable termination and inspection','J1 is five solder holes, not a purchased board connector | Continuity-check the actual cable')
    rows=[['J1 pad','Y (mm)','Signal','Expected cable conductor','Connection'],
          ['5 (TOP)','22.00','CAN-L','Blue','CANL_EXT'],
          ['4','19.00','CAN-H','White','CANH_EXT'],
          ['3','16.00','NET-C','Black','GND_BUS'],
          ['2','13.00','NET-S','Red','Bus supply input'],
          ['1 (BOTTOM, square)','10.00','SHIELD','Bare drain / shield','SHIELD; also accessible at TP1']]
    m.table(rows,34,H-95,[112,80,95,244,242],11)
    m.para('All five hole centres are at X=2.50 mm. Wire colours are the purchased pigtail listing convention, not evidence for the delivered cable. Check connector-contact-to-wire continuity before soldering. This table is a PCB top view; do not use it as a Micro-C connector face view.',34,318,773,11)
    y=264
    for text in [
      'Thread the unsplit cable seal/cartridge and cable-entry parts onto the cable BEFORE soldering. Check stripped/tinned conductors fit the 1.3 mm holes without force.',
      'Keep shield strands from all other pads. SHIELD, GND_BUS and GND_LOGIC are separate nets; add no ground or shield jumpers.',
      'Provide enclosure strain relief; solder joints must not carry cable pull. Trim excess wire and THT lead ends so they do not short to the enclosure or adjacent copper.',
      'Inspect every joint, module land, U1 lead, U3/U4 lead and L1 terminal. Remove solder bridges and clean residues according to the flux instructions.',
      'With all power and USB disconnected: check input/rail shorts, polarity and RUN/SERVICE continuity. Capacitor charging can produce transient meter readings; investigate stable low resistance.'
    ]:y=m.check(text,34,y)

    m.start('First power-up - record the actual results','Use an isolated bench setup before connecting to the installed NMEA network')
    y=H-99
    for text in [
      'Begin with MCU1 not fitted if practical: after carrier completion, select SERVICE, leave USB disconnected and test the carrier supplies with a current-limited source at J1 NET-S/NET-C. Use the documented 9-16 V bus range; stop for excessive current, smoke or fast heating.',
      'Measure 5V_BUS relative to GND_BUS at U2 pin 1. Measure 5V_ISO relative to GND_LOGIC at U2 pin 6. Measure 5V_REG relative to GND_LOGIC at SW3 pin 1. Do not measure an isolated rail against bus ground.',
      'U2 is unregulated. Its output is not guaranteed to be exactly 5.00 V; compare measurements to the power review. U4 can enter dropout and cannot boost a low U2 output. Verify startup and unloading peaks before attaching the module.',
      'Remove bench power before fitting MCU1. For USB-only service, select SERVICE first; verify module boot and 3V3_LOGIC. Disconnect USB before switching to RUN and testing bus-powered operation.',
      'Verify no physical bridge connects GND_BUS to GND_LOGIC or SHIELD. Use a multimeter for accidental-short checks; do not apply a high-voltage insulation tester to the assembled electronics.',
      'When using an earth-referenced oscilloscope, do not attach grounded clips to both isolated ground domains. Use an appropriate differential/isolated measurement arrangement.',
      'Record bus current, all rails, switching transitions and temperatures. Validate BLE reception, service Wi-Fi, CAN/NMEA traffic and Garmin values separately. Local firmware counters do not establish receiver delivery.'
    ]:y=m.check(text,34,y)
    m.para('Board serial: __________________   Assembler: __________________   Date: __________________<br/><br/>Input V / A: __________________   5V_BUS: __________   5V_ISO: __________   5V_REG: __________<br/><br/>Module 5V / 3V3: __________________   Startup peak: __________   Thermal / communication result: __________________',34,y-4,773,11)

    m.start('Sources, substitutions and remaining checks','Release files remain unchanged; this package is an assembly aid, not new hardware qualification')
    m.para('<b>Release authority</b><br/>hardware/altium-r5/Project Outputs/BatterySentinel-N2K-Orion-R5.zip<br/>ASCII PCB and Pick Place export: 23 September 2026, 20:53. Placement, pad numbers, pad coordinates, footprint outlines and nets are read directly from that archive. The native BOM provides release values and reference coverage.',34,H-96,773,11)
    m.para('<b>Purchased replacements</b><br/>L1: PSCIAQ4532-510Z / C2932173 replaces the release ACT45B-510-2P-TL003. L2/L3: FNR4030S4R7MT / C167874 replace the planned Sunlord part; the SUNLORD_SWPA4030 footprint remains. These changes affect only the hand-assembly BOM. Local procurement records dated 23/24 September document the review; supplied parts still need identity and fit inspection.',34,418,773,11)
    m.para('<b>Local engineering references</b><br/>lcsc-order-2026-09-24.md; lcsc-preisvergleich-2026-09-23.md; power-review.md; module-selection.md.<br/>Datasheets retained in source-references: PROD L1, cjiang L2/L3, EVISUN converter, Diodes buck regulator, G-Switch. Original release schematic and assembly PDFs are included for cross-checking.',34,325,773,11)
    m.para('<b>Known documentation distinctions</b><br/>The release generic C4/C5 description mentions 16 V, but their release value and purchased CC0603KRX7R9BB104 are 100 nF / 50 V. Use the value and purchased MPN. CPL geometric centres differ from component origins for U2, SW3 and MCU1; both are labelled separately in the position CSV. All geometry comes from the final release, avoiding later development-file placement assumptions.',34,245,773,11)
    m.para('<b>Completed digital checks</b><br/>37 references agree across release BOM, CPL and ASCII PCB; 34 purchased carrier components plus module, cable and bare pad; all 114 numbered pad nets checked against design connectivity. The existing Altium DRC report is not a newly executed DRC.',34,150,773,11)
    m.para('<b>Open physical work:</b> component identity and fit, soldering, short/polarity checks, switch continuity, rail/startup/thermal measurements, RF/CAN/Garmin acceptance and enclosure retention/sealing.',34,77,773,10)
    m.save()
    return m.page

def write_csv(path,rows):
    with path.open('w',encoding='utf-8-sig',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)

def main():
    if hasattr(sys.stdout,'reconfigure'):sys.stdout.reconfigure(encoding='utf-8')
    rs,comps,pads,placements,members,checks=load_release()
    OUT.mkdir(parents=True,exist_ok=True)
    grouped=[]
    for refs,mpn,code,package,note in GROUPS:
        grouped.append({'References':refs.replace(' ',','),'Release value':placements[refs.split()[0]]['Comment'], 'Purchased MPN':mpn,'LCSC':code,'Package':package,'Quantity 1 board':len(refs.split()),'Quantity 4 boards':4*len(refs.split()),'Note':note})
    for ref,n in [('MCU1',1),('J1',1),('TP1',0)]:
        i=INFO[ref];grouped.append({'References':ref,'Release value':placements[ref]['Comment'],'Purchased MPN':i['mpn'],'LCSC':i['lcsc'],'Package':i['package'],'Quantity 1 board':n,'Quantity 4 boards':4*n,'Note':i['note']})
    write_csv(OUT/'BOM-Hand-Assembly.csv',grouped)
    positions=[]
    for ref in sorted(comps,key=key):
        p=placements[ref];comp=comps[ref];i=INFO[ref]
        positions.append({'Reference':ref,'Release value':p['Comment'],'Purchased MPN':i['mpn'],'Supplier code':i['lcsc'],'Package':i['package'],'Release footprint':comp['PATTERN'],'Side':'TOP','Centre X mm':f"{mm(p['Center-X(mm)']):.4f}",'Centre Y mm':f"{mm(p['Center-Y(mm)']):.4f}",'Origin X mm':f"{mm(comp['X']):.4f}",'Origin Y mm':f"{mm(comp['Y']):.4f}",'Altium rotation deg':p['Rotation'],'Mounting': 'bare pad' if ref=='TP1' else 'wire termination' if ref=='J1' else 'manual castellated module' if ref=='MCU1' else 'THT' if ref=='U2' else 'SMD','Orientation note':i['note'],'Soldered':'','Inspected':''})
    write_csv(OUT/'Placements-and-Checklist.csv',positions)
    write_csv(OUT/'Release-Pad-Netlist.csv',[{'Reference':p['ref'] or 'Board mounting','Pad':p['pin'] or 'Mechanical hole','Net':p['net'],'X mm':f"{p['x']:.4f}",'Y mm':f"{p['y']:.4f}",'Hole mm':f"{p['hole']:.4f}",'Layer':p['layer'],'Plated':p['plated']} for p in pads])
    renderSVG.drawToFile(board_drawing(rs,comps,pads),str(OUT/'Placement-TOP.svg'))
    page_count=build_pdf(rs,comps,pads,placements,members)
    (OUT/PDF.name).write_bytes(PDF.read_bytes())
    source=OUT/'source-references';source.mkdir(exist_ok=True)
    source_names=['Assembly/AssemblyDrawing.pdf','Assembly/Schematic Prints.PDF','Assembly/BOM/Bill of Materials-BatterySentinel-N2K-Orion-R5.xlsx','Assembly/Pick Place/Pick Place for BatterySentinel-N2K-Orion-R5.csv','Fabrication/ASCII/BatterySentinel-N2K-Orion-R5.PcbDoc']
    for name in source_names:(source/Path(name).name).write_bytes(members[name])
    for path in [R5/'references/EVISUN-B-S-3WR2-V1.0.pdf',R5/'references/Diodes-AP6320x-DS41326-Rev3-2.pdf',R5/'references/GSWITCH-MK-12C02-GXXX-X1.pdf',ROOT/'tmp/lcsc-comparison/C2932173.pdf',ROOT/'tmp/lcsc-comparison/C167874.pdf']:
        if not path.exists():raise FileNotFoundError(path)
        (source/path.name).write_bytes(path.read_bytes())
    for name in ['power-review.md','module-selection.md','lcsc-order-2026-09-24.md','lcsc-preisvergleich-2026-09-23.md']:
        (source/name).write_bytes((R5/name).read_bytes())
    report={'created':DATE,'release_sha256':sha(RELEASE.read_bytes()),'release_references':len(comps),'carrier_components':34,'additional_module':1,'cable_interface':1,'bare_test_pad':1,'numbered_electrical_pads':114,'total_release_pads':120,'top_components':37,'bottom_components':0,'pdf_pages':page_count,'checks':checks,'sources':{n:sha(members[n]) for n in source_names},'digital_validation_only':True,'physical_acceptance':'Not performed; see README and PDF checklist'}
    text='\n'.join(page.extract_text() for page in PdfReader(PDF).pages)
    for ref in comps:
        if not re.search(r'\b'+ref+r'\b',text):raise ValueError('Missing PDF reference '+ref)
    for mpn in ['PSCIAQ4532-510Z','FNR4030S4R7MT','AP63205WU-7','ISO1042DWVR']:
        if mpn not in text:raise ValueError('Missing purchased PDF MPN '+mpn)
    if len(PdfReader(PDF).pages)!=page_count:raise ValueError('PDF page count mismatch')
    report['pdf_reference_and_mpn_coverage']='passed'
    report['reference_copies_sha256']={p.name:sha(p.read_bytes()) for p in sorted(source.iterdir()) if p.is_file()}
    (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    readme=f'''# Orion-R5 hand assembly package

Generated {DATE} from the user's final Altium release archive. Documentation is in English. Start with [the illustrated PDF]({PDF.name}).

## Files

- `{PDF.name}`: 11 A4 landscape pages, overview, purchased BOM, per-reference checklist, passive placement, orientation details, module/cable assembly and first-power checks. Print at 100% for the stated enlargement; the diagrams are magnified bench aids, not 1:1 templates.
- `Placement-TOP.svg`: scalable top-side placement map. Cable pads left, USB notch right, service switch at top. Gold pads, blue body envelopes, red dots at PCB pad 1 for directional parts. The original footprint envelope is retained for replacements; it is not a drawing of the substitute body.
- `BOM-Hand-Assembly.csv`: grouped release values and purchased MPN/LCSC overlay, exact quantities for 1 and 4 boards. 34 carrier components + one separately purchased module + one cable per board; no purchased part at TP1. No assembly-loss/spare allowance.
- `Placements-and-Checklist.csv`: all 37 references, release values, purchased parts, side, geometric centres, component origins, Altium angles, orientation and blank solder/inspection fields.
- `Release-Pad-Netlist.csv`: all 120 release pads, including 114 numbered electrical pads and six non-plated mechanical holes. Module GPIO pad names are GPIO numbers, not sequential lead indices. `NC` means unconnected.
- `source-references/`: original release assembly/schematic PDFs, BOM, CPL and ASCII PCB, plus the reviewed supplier datasheets; copied unchanged for cross-checking.
- `validation.json`: release/source SHA-256 and digital consistency results. Visual PDF QA is recorded separately in `visual-qa.json` after rendering.

CSV files use comma separators and UTF-8 with BOM. If your spreadsheet opens a single column, import as comma-separated UTF-8. The position CSV is labelled for manual assembly and is not a machine-specific PCBA file.

## Release authority and substitutions

Source: `../BatterySentinel-N2K-Orion-R5.zip` (ASCII/CPL export 2026-09-23 20:53).
SHA-256: `{report['release_sha256']}`.

Placement, pad geometry/numbering and connectivity come directly from that release. The archive, Gerber files, native sources and original BOM are preserved. Do not regenerate the fabrication release from this package.

The local procurement records `../../lcsc-order-2026-09-24.md` and `../../lcsc-preisvergleich-2026-09-23.md` supply the purchased overlay:

- L1: **PSCIAQ4532-510Z / C2932173**, replacing release ACT45B-510-2P-TL003; keep winding paths 1-4 and 2-3. Verify the two windings and actual terminal wetting before acceptance. No external pin-1 marking is established by the replacement sheet. The digital land overlap review is not a physical soldering/EMC qualification.
- L2/L3: **FNR4030S4R7MT / C167874**, replacing the planned Sunlord part on the existing SUNLORD_SWPA4030 footprint. Non-polar two-terminal 4.7 uH inductors.
- C4/C5 generic descriptions still mention 16 V, while release values and purchased MPN specify **100 nF, 50 V, X7R**. Use the release value and purchased MPN.
- MCU1: selected C3 SuperMini **ASIN B0FN4F6244**, direct 16-land perimeter soldering; USB points right and antenna left. Confirm actual delivered module identity and fit.

## Assembly order

1. Inspect PCB and parts; dry-fit the module, U2 and switch. Sort capacitors by label/value/package.
2. Solder resistors and MLCCs, then small ICs/diodes with pin-1 and cathode checks.
3. Fit F1 and inductors. Verify L1 winding orientation before soldering.
4. Fit tall U2 and SW3. Confirm switch continuity: RUN = 1-2; SERVICE = 2-3, with 1-2 open.
5. Inspect shorts and check carrier supplies before adding the module where practical. Mount all 16 castellations without headers or under-module paste.
6. Thread the unsplit cable-entry parts before terminating J1. Verify actual wire/contact continuity rather than relying only on colours. Provide independent strain relief.
7. Complete the power-off inspection and staged bench measurements in the PDF, then firmware, radio, NMEA/Garmin and enclosure acceptance.

SERVICE before USB; disconnect USB before RUN. Keep SHIELD, GND_BUS and GND_LOGIC separate. Use each rail's own ground for measurements. Do not bridge isolation with oscilloscope ground clips.

## Progress, findings and open work

- [x] Release ASCII PCB/BOM/CPL parsed and all 37 references reconciled.
- [x] All components confirmed top-side; 34 carrier components in 17 supplier groups, plus module, cable and bare TP1.
- [x] All 114 numbered pad nets compared to the design connectivity; placement/origin/rotation compared to release CPL.
- [x] Purchased L1/L2/L3 substitutions separated from immutable fabrication data.
- [x] Illustrated PDF, vector map, CSV checklists and source copies generated; PDF text/reference/MPN coverage checked.
- [ ] Receive/identify parts; inspect actual fit and solder joints.
- [ ] Verify switch continuity, rail values/startup peaks, bus current and thermal behaviour.
- [ ] Verify installed module RF, CAN/NMEA/Garmin delivery, cable retention and enclosure sealing.

No physical board test or new Altium DRC was performed. See the existing power/module reviews for design assumptions and electrical limits. A multimeter short check is not a certified insulation test.

## Rebuild

From the repository root, run `python tools/build_r5_hand_assembly.py` using a Python environment containing reportlab, openpyxl and pypdf. The script stops on inconsistent release references, origins, rotations or pad nets. Render the resulting PDF with Poppler and inspect every page before delivery. Rerunning clears the previous visual sign-off because the PDF has been regenerated.
'''
    (OUT/'README.md').write_text(readme,encoding='utf-8')
    qa=OUT/'visual-qa.json'
    if qa.exists():qa.unlink()
    bundle=R5/'Project Outputs/Orion-R5-Hand-Assembly.zip'
    with ZipFile(bundle,'w',ZIP_DEFLATED) as z:
        for path in sorted(OUT.rglob('*')):
            if path.is_file():z.write(path,Path('Hand Assembly')/path.relative_to(OUT))
    print(json.dumps({'pdf':str(PDF),'package':str(OUT),'bundle':str(bundle),'pages':page_count,'release_sha256':report['release_sha256'],'checks':len(checks)},indent=2))

if __name__=='__main__':main()
