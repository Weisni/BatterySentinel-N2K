"""Regenerate the reviewed Orion carrier concept as vector SVG and A3 PDF.

Requires reportlab. Geometry is a placement/routing concept, not ECAD fabrication data.
All drawing coordinates are millimetres from the upper-left corner of an A3 sheet.
"""
from pathlib import Path
from html import escape
import json
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.colors import toColor as HexColor

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output' / 'internal' / 'engineering'
SVG = ROOT / 'hardware' / 'drawings'
OUT.mkdir(parents=True, exist_ok=True)
SVG.mkdir(parents=True, exist_ok=True)
MM = 72 / 25.4
W, H = 420, 297
INK, MUTED, LINE = '#182f41', '#526575', '#92a2ad'
BUS, LOGIC, CAN, RED = '#9a4e12', '#166a92', '#246f64', '#b43737'
pdfmetrics.registerFont(TTFont('Arial', 'C:/Windows/Fonts/arial.ttf'))
pdfmetrics.registerFont(TTFont('ArialBold', 'C:/Windows/Fonts/arialbd.ttf'))
PDF = OUT / 'orion-bridge-schaltplan-pcb-entwurf.pdf'
c = canvas.Canvas(str(PDF), pagesize=(W*MM, H*MM))
c.setTitle('Orion Bridge - Schaltplan und PCB-Layoutentwurf R1')
c.setAuthor('BatterySentinel N2K')

class Sheet:
    def __init__(self, name, title, subtitle, number):
        self.name, self.number = name, number
        self.parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}mm" height="{H}mm" viewBox="0 0 {W} {H}">', '<rect width="420" height="297" fill="white"/>']
        self.rect(0,0,W,29,fill=INK,stroke=None)
        self.text(14,12,title,6.2,bold=True,color='white')
        self.text(14,22,subtitle,3.1,color='#d8e5ec')
        self.line(14,279,406,279,color=LINE,width=.25)
        self.text(14,285,'BATTERY SENTINEL  |  ORION BRIDGE  |  R1  |  20.09.2026',2.8,bold=True)
        self.text(14,291,'ENTWURF - keine Fertigungsfreigabe / keine Gerberdaten. Maße vor Layoutfreigabe prüfen.',2.5,color=MUTED)
        self.text(405,286,f'{number} / 4',3.2,anchor='end',bold=True)

    def line(self,x1,y1,x2,y2,color=INK,width=.45,dash=None):
        self.poly([(x1,y1),(x2,y2)],color,width,dash)

    def poly(self,pts,color=INK,width=.45,dash=None,fill=None):
        attrs=f'fill="{fill or "none"}" stroke="{color}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"'
        if dash: attrs+=f' stroke-dasharray="{dash}"'
        self.parts.append(f'<polyline points="{" ".join(f"{x},{y}" for x,y in pts)}" {attrs}/>')
        c.setStrokeColor(HexColor(color)); c.setLineWidth(width*MM)
        c.setDash([float(v)*MM for v in dash.split()] if dash else [])
        p=c.beginPath(); p.moveTo(pts[0][0]*MM,(H-pts[0][1])*MM)
        for x,y in pts[1:]: p.lineTo(x*MM,(H-y)*MM)
        if fill: c.setFillColor(HexColor(fill))
        c.drawPath(p,stroke=1,fill=int(bool(fill)))

    def rect(self,x,y,w,h,fill=None,stroke=LINE,width=.3,dash=None,r=0):
        attrs=f'x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill or "none"}" stroke="{stroke or "none"}" stroke-width="{width}" rx="{r}"'
        if dash: attrs+=f' stroke-dasharray="{dash}"'
        self.parts.append(f'<rect {attrs}/>')
        if fill:c.setFillColor(HexColor(fill))
        if stroke:c.setStrokeColor(HexColor(stroke))
        c.setLineWidth(width*MM);c.setDash([float(v)*MM for v in dash.split()] if dash else [])
        if r:c.roundRect(x*MM,(H-y-h)*MM,w*MM,h*MM,r*MM,stroke=int(bool(stroke)),fill=int(bool(fill)))
        else:c.rect(x*MM,(H-y-h)*MM,w*MM,h*MM,stroke=int(bool(stroke)),fill=int(bool(fill)))

    def circle(self,x,y,r,fill=None,stroke=INK,width=.35):
        self.parts.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill or "none"}" stroke="{stroke or "none"}" stroke-width="{width}"/>')
        if fill:c.setFillColor(HexColor(fill))
        if stroke:c.setStrokeColor(HexColor(stroke))
        c.setLineWidth(width*MM);c.setDash([])
        c.circle(x*MM,(H-y)*MM,r*MM,stroke=int(bool(stroke)),fill=int(bool(fill)))

    def text(self,x,y,text,size=3.2,color=INK,bold=False,anchor='start'):
        text=str(text)
        self.parts.append(f'<text x="{x}" y="{y}" font-family="Arial, sans-serif" font-size="{size}" font-weight="{"700" if bold else "400"}" fill="{color}" text-anchor="{anchor}">{escape(text)}</text>')
        c.setFillColor(HexColor(color));c.setFont('ArialBold' if bold else 'Arial',size*MM)
        func={'start':c.drawString,'middle':c.drawCentredString,'end':c.drawRightString}[anchor]
        func(x*MM,(H-y)*MM,text)

    def lines(self,x,y,lines,size=3.1,leading=5,color=INK):
        for i,text in enumerate(lines): self.text(x,y+i*leading,text,size,color)

    def box(self,x,y,w,h,title,color=BUS):
        self.rect(x,y,w,h,fill='#fcfcfd',stroke='#d6dfe4',r=2)
        self.text(x+4,y+7,title,3.5,color,bold=True)

    def dot(self,x,y,color=INK):self.circle(x,y,.85,fill=color,stroke=None)
    def net(self,x,y,name,color=INK,anchor='start'):
        self.text(x,y-2,name,3.1,color,bold=True,anchor=anchor)

    def gnd(self,x,y,name='GND_BUS',color=BUS):
        self.line(x,y,x,y+2,color)
        for i,w in enumerate([5,3.4,1.8]):self.line(x-w/2,y+2+i*1.1,x+w/2,y+2+i*1.1,color,.4)
        self.text(x,y+8,name,2.7,color,anchor='middle')

    def cap(self,x,y,ref,value,ground='GND_BUS',color=BUS,ground_y=None):
        self.line(x,y,x,y+8,color)
        self.line(x-3,y+8,x+3,y+8,color,.65)
        self.line(x-3,y+10,x+3,y+10,color,.65)
        end=ground_y if ground_y is not None else y+20
        self.line(x,y+10,x,end,color)
        self.text(x+4,y+7,ref,2.8,bold=True)
        self.text(x+4,y+12,value,2.6)
        self.gnd(x,end,ground,color)

    def resistor(self,x1,y,x2,ref,value,color=INK):
        m=(x1+x2)/2
        self.line(x1,y,m-5,y,color);self.line(m+5,y,x2,y,color)
        self.rect(m-5,y-2,10,4,fill='white',stroke=color,width=.5)
        self.text(m,y-7,ref,2.8,bold=True,anchor='middle')
        self.text(m,y-3.5,value,2.7,anchor='middle')

    def diode(self,x1,y,x2,ref,value,color=INK):
        m=(x1+x2)/2
        self.line(x1,y,m-3,y,color);self.line(m+3,y,x2,y,color)
        self.poly([(m-3,y-3),(m+3,y),(m-3,y+3),(m-3,y-3)],color,.45)
        self.line(m+3,y-3,m+3,y+3,color,.65)
        self.text(m,y-8,ref,2.8,bold=True,anchor='middle')
        self.text(m,y-4.5,value,2.6,anchor='middle')
        self.text(m-4,y+6,'A',2.2);self.text(m+3,y+6,'K',2.2)

    def nc(self,x,y):
        self.line(x-1,y-1,x+1,y+1,width=.35);self.line(x-1,y+1,x+1,y-1,width=.35)

    def finish(self):
        self.parts.append('</svg>')
        (SVG/self.name).write_text('\n'.join(self.parts),encoding='utf-8')
        c.showPage()


def power_sheet():
    s=Sheet('01-versorgung.svg','Schaltplan 01 - Versorgung und Schutz','NMEA-gespeiste SuperMini-Trägerplatine | BUS und LOGIC galvanisch getrennt | Referenzschaltung',1)
    s.box(14,37,233,105,'A  NET-S / Verpolung / Transienten')
    s.net(21,84,'J1.2 NET-S',BUS);s.text(21,78,'rot / 9-16 V Netz',2.6)
    s.line(22,84,51,84,BUS)
    s.resistor(51,84,78,'F1','T0,8 A / >=60 V',BUS)
    s.text(51,96,'Sicherung, kein 0,5-A-PPTC',2.5)
    # Pin-labelled PMOS with an explicit intrinsic diode orientation.
    s.line(78,84,97,84,BUS)
    s.rect(97,72,39,25,fill='white',stroke=INK,width=.5)
    s.text(116.5,78,'Q1 DMP6023LE',2.8,bold=True,anchor='middle')
    s.text(99,89,'2 D',2.6);s.text(126,89,'3 S',2.6)
    s.line(105,84,110,84,BUS);s.poly([(110,81),(116,84),(110,87),(110,81)],BUS,.35);s.line(116,81,116,87,BUS);s.line(116,84,130,84,BUS)
    s.text(116.5,94,'1 G',2.6,anchor='middle');s.line(116.5,97,116.5,110,BUS)
    s.line(136,84,230,84,BUS);s.net(191,82,'BUS_PROT',BUS)
    # Gate clamp, shown with explicit terminals to remove diode ambiguity.
    s.dot(144,84,BUS);s.poly([(144,84),(144,110),(128,110)],BUS)
    s.rect(120,105,8,10,fill='white',stroke=BUS)
    s.text(124,108.5,'Z1',2.4,bold=True,anchor='middle');s.text(124,112,'12 V',2.2,anchor='middle')
    s.line(120,110,116.5,110,BUS);s.dot(116.5,110,BUS)
    s.text(146,107,'K an S',2.4);s.text(146,112,'A an G',2.4)
    s.rect(113.8,115,5.4,8,fill='white',stroke=BUS);s.line(116.5,110,116.5,115,BUS);s.line(116.5,123,116.5,127,BUS)
    s.text(103,119,'R1',2.5);s.text(99,124,'100 kΩ',2.5);s.gnd(116.5,127)
    s.text(22,116,'Q1: P-MOS; Tab = Drain 2.',2.7)
    s.text(22,122,'Bodydiode: D -> S.',2.7)
    s.text(22,128,'Z1: BZT52C12 / SOD-123.',2.7)
    # Supply TVS to ground, cathode at protected positive.
    s.dot(171,84,BUS);s.line(171,84,171,100,BUS)
    s.line(168,100,174,100,BUS,.65)
    s.poly([(168,106),(171,100),(174,106),(168,106)],BUS,.45)
    s.line(171,106,171,125,BUS);s.gnd(171,125)
    s.text(175,102,'D1',2.8,bold=True);s.text(175,107,'SMBJ20A',2.6);s.text(175,112,'K oben',2.4)
    s.dot(218,84,BUS);s.cap(218,84,'C1','47 µF / 50 V',ground_y=125)

    s.box(255,37,151,105,'B  Busseitige 5-V-Versorgung')
    s.net(262,79,'BUS_PROT',BUS);s.line(263,79,298,79,BUS)
    s.dot(274,79,BUS);s.cap(274,79,'C2','1 µF / 50 V',ground_y=118)
    s.rect(298,70,61,39,fill='white',stroke=INK,width=.5)
    s.text(328.5,77,'U3 TPS7B6950',3,bold=True,anchor='middle')
    s.text(328.5,83,'QDCYRQ1 / SOT-223',2.7,anchor='middle')
    s.text(300,94,'1 IN',2.7);s.text(344,94,'3 OUT',2.7)
    s.text(328.5,104,'2 + 4 (Tab) GND',2.7,anchor='middle')
    s.line(359,79,399,79,BUS);s.net(372,70,'5V_BUS',BUS)
    s.line(328,109,328,118,BUS);s.gnd(328,118)
    s.dot(376,79,BUS);s.cap(376,79,'C3','10 µF / 16 V',ground_y=118)
    s.lines(262,135,['150 mA; C3 effektiv >=2,2 µF; ESR <2 Ω.'],2.6)

    s.box(14,150,392,96,'C  Isolierter Wandler und USB-Service-Trennung',LOGIC)
    # Domain barrier appears only through the isolating device.
    s.rect(227,164,4,74,fill='#f1f3f5',stroke=None)
    s.line(229,164,229,238,LINE,.35,'2 2')
    s.text(188,168,'BUS / GND_BUS',2.8,BUS,bold=True)
    s.text(247,168,'LOGIC / GND_LOGIC',2.8,LOGIC,bold=True)
    s.net(21,194,'BUS_PROT',BUS);s.line(23,194,91,194,BUS)
    s.dot(61,194,BUS);s.cap(61,194,'C8','10 µF / 50 V',ground_y=224)
    s.resistor(91,194,119,'L2','15 µH / >=1 A',BUS)
    s.line(119,194,189,194,BUS);s.dot(143,194,BUS);s.cap(143,194,'C9','10 µF / 50 V',ground_y=224)
    s.text(22,239,'10 µF / 15 µH / 10 µF nach RECOM. Kein Kondensator über der Isolation; EMV muss geprüft werden.',2.6)
    s.rect(199,179,60,54,fill='white',stroke=INK,width=.5)
    s.line(229,179,229,233,LINE,.35,'2 2')
    s.text(229,176,'U2 R3M-2405S/SMD',3.1,bold=True,anchor='middle')
    for y,p in [(194,'1 +VIN'),(207,'2 -VIN'),(222,'4 CTRL')]:s.line(189,y,199,y,BUS);s.text(201,y-2,p,2.6)
    for y,p in [(194,'7 +VOUT'),(207,'6 -VOUT'),(222,'5 NC')]:s.line(259,y,269,y,LOGIC);s.text(257,y-2,p,2.6,anchor='end')
    s.poly([(189,207),(183,207),(183,224)],BUS);s.gnd(183,224)
    s.nc(189,222);s.text(163,217,'offen = EIN',2.2)
    s.nc(269,222)
    s.text(229,230,'5 V / 600 mA',2.7,anchor='middle')
    s.line(269,194,299,194,LOGIC);s.dot(276,194,LOGIC)
    s.cap(276,194,'C6 + C7','47 µF + 100 nF','GND_LOGIC',LOGIC,ground_y=231)
    s.poly([(269,207),(273,207),(273,231),(276,231)],LOGIC)
    s.diode(299,194,324,'D2','SS36',LOGIC)
    s.line(324,194,338,194,LOGIC);s.circle(338,194,1.2,fill='white',stroke=LOGIC)
    s.circle(350,194,1.2,fill='white',stroke=LOGIC);s.line(338,191,350,191,LOGIC,.7)
    s.text(344,179,'JP1',2.9,bold=True,anchor='middle');s.text(344,184,'RUN / SERVICE',2.6,anchor='middle')
    s.line(351,194,399,194,LOGIC);s.net(367,190,'5V_MODULE',LOGIC)
    s.lines(317,211,['RUN: JP1 gesteckt, USB abgezogen.', 'SERVICE: JP1 vor USB-Anschluss öffnen.', 'D2 schützt den Wandler, nicht USB-VBUS.'],2.7,5,RED)
    s.lines(16,256,['Korrektur R1: U3 ersetzt den 50-mA-LM2936. ISO1042 kann busseitig bis 73,4 mA benötigen.',
                    'U2 verlangt >=9 V an seinen Eingangspins. Betrieb bei 9 V NET-S nach Schutz-/Filterverlusten ist noch nicht abgedeckt.',
                    'GND_BUS und GND_LOGIC bleiben getrennt. U3-Wärmefläche, Einschaltstrom, Sicherung und 9-V-Grenzfall vor Freigabe prüfen.'],2.9,5)
    s.finish()


def signal_sheet():
    s=Sheet('02-can-controller.svg','Schaltplan 02 - CAN und Controller','Pin-genaue Verbindung des ISO1042DWV | GPIO6 = TX, GPIO7 = RX | keine zusätzliche Drop-Terminierung',2)
    s.rect(14,38,207,153,fill='#fff9f2',stroke='#e6cdb3',r=2)
    s.rect(230,38,176,153,fill='#f2f9fd',stroke='#c8dfeb',r=2)
    s.text(19,46,'BUS / GND_BUS = NET-C',3.5,BUS,bold=True)
    s.text(237,46,'LOGIC / GND_LOGIC = SuperMini-GND',3.5,LOGIC,bold=True)
    s.rect(221,38,9,153,fill='#f0f2f4',stroke=None)
    s.line(225.5,38,225.5,191,LINE,.4,'2 2')
    # Connector: logical connector pin listing, no mirrored face-view ambiguity.
    s.rect(23,62,52,84,fill='white',stroke=INK,width=.5)
    s.text(49,58,'J1 Micro-C-Pigtail',3.2,bold=True,anchor='middle')
    rows=[(72,'1 SHIELD','SHIELD'),(86,'2 NET-S','BUS_INPUT'),(100,'3 NET-C','GND_BUS'),(114,'4 CAN-H','CANH_EXT'),(128,'5 CAN-L','CANL_EXT')]
    for y,label,_ in rows:s.text(26,y+1,label,3);s.line(75,y,83,y,BUS)
    s.net(86,72,'SHIELD',BUS);s.line(83,72,102,72,BUS);s.circle(104,72,2,stroke=BUS)
    s.text(82,65,'TP_SH / Schirm-Pad',2.5)
    s.net(85,86,'NET-S -> Blatt 1',BUS)
    s.gnd(83,100)
    s.text(25,157,'Farben: blank / rot / schwarz / weiß / blau.',2.7)
    s.text(25,163,'Pin-Nummern, keine Steckergesicht-Ansicht.',2.7)
    s.text(25,169,'Schirm nicht mit Logikmasse verbinden.',2.7)
    s.text(25,175,'Kabel: verdrilltes CAN-Paar; Drop <=6 m.',2.7)

    s.line(83,114,153,114,CAN);s.poly([(83,128),(145,128),(145,130),(153,130)],CAN)
    # Two-line TVS attaches with a stub, not in series.
    s.dot(101,114,CAN);s.dot(120,128,CAN)
    s.poly([(101,114),(101,139),(104,139),(104,145)],CAN)
    s.poly([(120,128),(120,145)],CAN)
    s.rect(96,145,32,24,fill='white',stroke=BUS)
    s.text(104,150,'1 K1',2.3,anchor='middle');s.text(119,150,'2 K2',2.3,anchor='middle')
    s.text(112,156,'D3',2.7,bold=True,anchor='middle');s.text(112,161,'PESD2CAN24T-Q',2.3,anchor='middle')
    s.text(112,166,'3 CC',2.3,anchor='middle');s.line(112,169,112,176,BUS);s.gnd(112,176)
    s.rect(153,104,26,36,fill='white',stroke=INK,width=.45)
    s.text(166,100,'L1 ACT45B-510',2.8,bold=True,anchor='middle')
    s.text(155,111,'1',2.4);s.text(175,111,'4',2.4)
    s.text(155,137,'2',2.4);s.text(175,137,'3',2.4)
    s.poly([(153,114),(159,114),(161,112),(163,116),(165,112),(167,116),(169,112),(171,114),(179,114)],CAN)
    s.poly([(153,130),(159,130),(161,128),(163,132),(165,128),(167,132),(169,128),(171,130),(179,130)],CAN)
    s.line(158,121,174,121,LINE,.35);s.line(158,123,174,123,LINE,.35)
    s.line(179,114,207,114,CAN);s.line(179,130,207,130,CAN)
    # Iso device drawn with BUS left / LOGIC right (pin numbers govern connectivity).
    s.rect(207,72,37,88,fill='white',stroke=INK,width=.55)
    s.line(225.5,72,225.5,160,LINE,.4,'2 2')
    s.text(225.5,65,'U1 ISO1042DWV',3.1,bold=True,anchor='middle')
    for y,label in [(83,'8 VCC2'),(114,'7 CANH'),(130,'6 CANL'),(150,'5 GND2')]:s.text(209,y-2,label,2.5)
    for y,label in [(83,'1 VCC1'),(114,'2 TXD'),(130,'3 RXD'),(150,'4 GND1')]:s.text(242,y-2,label,2.5,anchor='end')
    s.line(193,83,207,83,BUS);s.net(193,80,'5V_BUS',BUS,anchor='end')
    s.poly([(207,150),(193,150),(193,176)],BUS);s.gnd(193,176)
    s.line(244,83,270,83,LOGIC);s.net(259,79,'3V3_LOGIC',LOGIC)
    s.poly([(244,150),(258,150),(258,175)],LOGIC);s.gnd(258,175,'GND_LOGIC',LOGIC)
    s.line(244,114,264,114,LOGIC);s.resistor(264,114,296,'R_TX','33 Ω',LOGIC);s.line(296,114,326,114,LOGIC)
    s.line(244,130,289,130,LOGIC);s.resistor(289,130,319,'R_RX','33 Ω',LOGIC);s.line(319,130,326,130,LOGIC)
    # Discrete pull-up holds TX recessive during reset.
    s.dot(253,114,LOGIC);s.poly([(253,114),(253,98),(280,98)],LOGIC)
    s.rect(280,96,9,4,fill='white',stroke=LOGIC);s.line(289,98,305,98,LOGIC);s.net(306,98,'3V3_LOGIC',LOGIC)
    s.text(284.5,94,'R2 10 kΩ',2.3,anchor='middle')
    s.rect(326,72,70,93,fill='white',stroke=INK,width=.5)
    s.text(361,82,'MCU1',4,bold=True,anchor='middle')
    s.text(361,88,'ESP32-C3 SuperMini',3,anchor='middle')
    s.text(328,112,'GPIO6 / CAN TX',3);s.text(328,128,'GPIO7 / CAN RX',3)
    s.text(361,143,'5V <- 5V_MODULE (Blatt 1)',2.7,anchor='middle')
    s.text(361,149,'3V3 -> 3V3_LOGIC',2.7,anchor='middle')
    s.text(361,155,'GND -> GND_LOGIC',2.7,anchor='middle')
    s.text(361,161,'USB / BOOT am Modul frei halten',2.5,anchor='middle')
    s.text(331,176,'Betriebsversorgung und USB nur alternativ!',2.8,RED,bold=True)
    s.box(14,199,128,72,'D  Abblockung direkt am ISO1042',LOGIC)
    s.net(40,225,'5V_BUS',BUS,anchor='middle');s.cap(40,225,'C4','100 nF',ground_y=253)
    s.net(93,225,'3V3_LOGIC',LOGIC,anchor='middle');s.cap(93,225,'C5','100 nF','GND_LOGIC',LOGIC,ground_y=253)
    s.box(150,199,122,72,'E  Terminierung')
    s.lines(157,216,['Kein 120-Ω-Widerstand auf diesem Drop.', 'Zwei 120-Ω-Abschlüsse gehören an die', 'beiden Enden des NMEA-Backbones.', '', 'RTERM-Footprint entfällt in R1.', 'CAN-H und CAN-L bleiben ein kurzes Paar.'],3.1,8)
    s.box(280,199,126,72,'F  Anschlussprüfung')
    s.lines(287,216,['Schaltplan verwendet Signalnamen am Modul.', 'Die SuperMini-Headerfolge ist vor Fertigung', 'am konkreten Exemplar abzugleichen.', '', 'Keine Shunts und keine Ladeleitungen:', 'Orion-Messwerte gelangen per BLE zum ESP32.'],3.0,8)
    s.finish()


def dim(s,x1,y1,x2,y2,label):
    s.line(x1,y1,x2,y2,MUTED,.25)
    if y1==y2:
        for x in (x1,x2):s.line(x,y1-2,x,y1+2,MUTED,.25)
        s.text((x1+x2)/2,y1-2,label,2.6,MUTED,anchor='middle')
    else:
        for y in (y1,y2):s.line(x1-2,y,x1+2,y,MUTED,.25)
        s.text(x1-3,(y1+y2)/2,label,2.6,MUTED,anchor='end')


def layout_sheet():
    s=Sheet('03-pcb-layout.svg','PCB-Layoutzeichnung - 80 x 60 mm','Zweilagiger Platzierungs- und Routingentwurf | Draufsicht + Massekonzept | Bauteilkonturen sind Reservierungsflächen',3)
    scale=2.35; ox,oy=27,60
    X=lambda x:ox+x*scale;Y=lambda y:oy+y*scale
    def rect(x,y,w,h,fill=None,stroke=LINE,width=.3,dash=None):s.rect(X(x),Y(y),w*scale,h*scale,fill,stroke,width,dash)
    def route(pts,color=RED,width=.9,dash=None):s.poly([(X(x),Y(y)) for x,y in pts],color,width,dash)
    def part(ref,x,y,w,h,desc='',color=INK):
        rect(x,y,w,h,'white',color,.4)
        s.text(X(x+w/2),Y(y+h/2)+.7,ref,3.2,color,True,'middle')
        if desc:s.text(X(x+w/2),Y(y+h)+3.5,desc,2.5,color,anchor='middle')
    s.text(27,43,'TOP - PLATZIERUNG UND VERBINDUNGSKORRIDORE',3.3,bold=True)
    s.rect(X(0),Y(0),80*scale,60*scale,fill='#f6faf8',stroke=INK,width=.7)
    rect(.6,.6,36.4,58.8,'#fff5e9',None)
    rect(43,.6,36.4,58.8,'#eef8fe',None)
    rect(37,0,6,60,'#e9edf0',LINE,.25,'1.5 1.5')
    rect(37,42,1.1,11,'#fff5e9',None)
    rect(41.9,42,1.1,11,'#eef8fe',None)
    s.text(X(40),Y(58),'ISO',2.5,MUTED,True,'middle')
    # Mechanical holes: three, avoiding the antenna corner.
    for x,y in [(4,4),(4,56),(76,56)]:
        s.circle(X(x),Y(y),3.2*scale,fill='white',stroke=LINE,width=.3)
        s.circle(X(x),Y(y),1.6*scale,fill='white',stroke=INK,width=.5)
    dim(s,X(0),Y(-5),X(80),Y(-5),'80,0 mm')
    dim(s,X(-5),Y(0),X(-5),Y(60),'60,0')
    # Copper keepout around the proposed antenna overhang.
    rect(56,0,24,17,'#fff4cf','#b88619',.35,'2 1')
    s.text(X(68),Y(4),'ANTENNENFREIRAUM',2.6,'#886015',True,'middle')
    s.text(X(68),Y(8),'auf allen Lagen',2.6,'#886015',anchor='middle')
    s.text(X(68),Y(13),'keine Leiterbahnen / Masse',2.3,'#886015',anchor='middle')
    # Routes are deliberate corridors, never pad-level manufactured copper.
    route([(10,20),(15,20),(15,25),(28,25),(28,24),(34.2,24)],CAN,1)
    route([(10,23),(13,23),(13,29),(30,29),(30,27),(34.2,27)],CAN,1)
    route([(10,32),(13,32),(13,43),(25,43),(25,47),(32,47)],RED,1.4)
    route([(25,43),(29,43),(29,38)],RED,1.1)
    route([(29,35),(32,35),(32,21),(34.2,21)],RED,.75)
    route([(47,25),(54,25),(54,32),(67,32)],LOGIC,.65)
    route([(47,27),(52,27),(52,34),(67,34)],LOGIC,.65)
    route([(48,47),(53,47),(53,42),(60,42),(60,37),(67,37)],RED,1.2)
    part('J1',1,15,9,25,'5-pol. Kabelklemme')
    part('D3',14,24,4,4)
    part('L1',23,24,5,5)
    part('U1',34.2,19,11.6,9,'ISO1042DWV')
    part('C4',30,18,3,2)
    part('C5',47,18,3,2)
    part('R_TX/R_RX',50,29,9,3)
    part('R2',50,35,5,2)
    part('F1',11,41,9,6)
    part('Q1',22,41,7,7)
    part('D1',14,49,6,4)
    part('C1',24,52,6,5)
    part('U3',23,33,7,6,'5V_BUS')
    part('C2',19,33,3,2)
    part('C3',31,33,4,3)
    part('R1/Z1',22,48,7,3)
    part('C8/L2/C9',24,56,11,3)
    # Converter spans the same isolation boundary; exact pad orientation from datasheet.
    part('U2',32,42,16,11,'R3M-2405S/SMD')
    part('C6/C7',51,48,8,4)
    part('D2',51,41,5,3)
    part('JP1',59,40,7,4,'USB: öffnen')
    rect(61,14,18,24,'#dcebf3',LOGIC,.4,'1.2 1.2')
    s.text(X(70.5),Y(21),'MCU1',3.1,LOGIC,True,'middle')
    s.text(X(70.5),Y(25),'SuperMini',2.7,LOGIC,anchor='middle')
    s.text(X(70.5),Y(29),'Headerposition',2.2,LOGIC,anchor='middle')
    s.text(X(70.5),Y(32),'noch zu messen',2.2,LOGIC,anchor='middle')
    rect(67,35,8,4,'#c4ced5',INK)
    s.text(X(71),Y(38),'USB',2.4,INK,True,'middle')
    rect(66,40,12,13,None,LOGIC,.25,'1.5 1.5')
    s.text(X(72),Y(48),'Service-',2.5,LOGIC,anchor='middle');s.text(X(72),Y(51),'zugang',2.5,LOGIC,anchor='middle')
    s.text(27,211,'Maßstab der Platinenkontur 2,35:1 bei A3 / 100 % Druck. Keine Kupfer-Fertigungszeichnung.',2.8,MUTED)

    bx,by,bs=251,69,1.65
    s.text(245,43,'BOTTOM - MASSEFLÄCHEN',3.3,bold=True)
    s.text(245,49,'Von oben betrachtet / durchscheinend, nicht gespiegelt',2.8,MUTED)
    s.rect(bx,by,80*bs,60*bs,fill='white',stroke=INK,width=.6)
    s.rect(bx+1,by+1,36*bs,58*bs,fill='#f7e1c9',stroke=None)
    s.rect(bx+43*bs,by+1,36*bs,58*bs,fill='#cbe3f1',stroke=None)
    s.rect(bx+37*bs,by,6*bs,60*bs,fill='#e9edf0',stroke=LINE,dash='1.5 1.5')
    s.rect(bx+37*bs,by+42*bs,1.1*bs,11*bs,fill='#f7e1c9',stroke=None)
    s.rect(bx+41.9*bs,by+42*bs,1.1*bs,11*bs,fill='#cbe3f1',stroke=None)
    s.rect(bx+56*bs,by,24*bs,17*bs,fill='#fff4cf',stroke='#b88619',dash='1.5 1.5')
    s.text(bx+18*bs,by+25*bs,'GND_BUS',3.3,BUS,True,'middle')
    s.text(bx+61*bs,by+32*bs,'GND_LOGIC',3.3,LOGIC,True,'middle')
    # Thermal copper must stay within the BUS region.
    s.rect(bx+15*bs,by+29*bs,20*bs,20*bs,fill='#efc18f',stroke=BUS,dash='1 1')
    s.text(bx+25*bs,by+36*bs,'U3 Wärmefläche',2.7,BUS,True,'middle')
    s.text(bx+25*bs,by+41*bs,'20 x 20 mm Ziel',2.5,BUS,anchor='middle')
    for x,y in [(4,4),(4,56),(76,56)]:
        s.circle(bx+x*bs,by+y*bs,3.2*bs,fill='white',stroke=LINE,width=.3)
        s.circle(bx+x*bs,by+y*bs,1.6*bs,fill='white',stroke=INK,width=.4)
    s.lines(245,183,['6-mm-Kupfersperre; lokal am U2-Landpattern nur 3,8 mm.', 'Nur U1 und U2 dürfen die Domain-Grenze überbrücken.', 'Keine Masse-Vias, Schirmleitungen oder Schrauben darin.', 'U2-Padabstände und tatsächliche Luft-/Kriechstrecken', 'im ECAD-Footprint prüfen; keine Isolationsfreigabe.'],2.8,5)
    s.box(14,224,192,47,'Mechanik und Funk',LOGIC)
    s.lines(20,238,['3 x Ø3,2 mm NPTH bei (4/4), (4/56), (76/56) mm.', 'Ursprung links oben; Lochpositionen sind Gehäuse-Vorschlag.', 'Antenne möglichst über den Rand; >=15 mm Freiraum im', 'Gehäuse als Planungsziel. Tatsächlichen Modulaufbau prüfen.'],2.9,6)
    s.box(214,224,192,47,'Leiterführung - Startwerte, nicht Impedanzberechnung')
    s.lines(220,238,['Versorgung >=0,8 mm; Logik 0,25 mm; CAN-Paar 0,30 mm.', 'CAN-H/L eng gemeinsam führen; Abstand im Stackup festlegen.', 'TVS nahe J1, C4/C5 direkt an U1; U3 thermisch vermessen.', 'Unverbundene Flächen entfernen. ERC/DRC vor Gerberfreigabe.'],2.9,6)
    s.finish()


SOURCES=[
    ('TI ISO1042', 'DWV-Pins, Icc2 und Gehäuse', 'https://www.ti.com/lit/ds/symlink/iso1042.pdf'),
    ('TI TPS7B69-Q1', 'U3 SOT-223, 150 mA, COUT', 'https://www.ti.com/lit/ds/symlink/tps7b69-q1.pdf'),
    ('RECOM R3M', 'Wandlerpins, Filter, Sicherung', 'https://recom-power.com/pdf/Econoline/R3M.pdf'),
    ('Diodes DMP6023LE', 'G1 / D2+Tab / S3', 'https://www.diodes.com/datasheet/download/DMP6023LE.pdf'),
    ('Nexperia PESD2CAN24T-Q', 'TVS-Pins und SOT-23', 'https://assets.nexperia.com/documents/data-sheet/PESD2CAN24T-Q.pdf'),
    ('TDK ACT45B', 'CAN-Gleichtaktdrossel', 'https://www.tdk-electronics.tdk.com/inf/30/ds/act45b.pdf'),
    ('Garmin Micro-C', 'Pin-Nummern und Aderfarben', 'https://static.garmin.com/pumac/N2k_Field-install_Connector_Wiring_ML.pdf'),
    ('Nologo SuperMini', 'Modul und USB-Versorgung', 'https://www.nologo.tech/product/esp32/esp32c3/esp32c3supermini/esp32C3SuperMini.html'),
    ('Espressif RF-Layout', 'Antennenfreiraum', 'https://docs.espressif.com/projects/esp-hardware-design-guidelines/en/latest/esp32c3/pcb-layout-design.html'),
]

def notes_sheet():
    s=Sheet('04-bauteile-hinweise.svg','Bauteile, Prüfstellen und Quellen','Umsetzungsstand R1 | pin-genaue Referenzschaltung + mechanischer Layoutentwurf | keine Fertigungsdaten',4)
    s.text(15,41,'BAUTEILAUSWAHL',3.6,BUS,True)
    rows=[
        ('U1','ISO1042DWVR','SOIC-8 DWV; kein schmales SOIC-8'),
        ('U2','R3M-2405S/SMD','Original-Landpattern verwenden; CTRL offen'),
        ('U3','TPS7B6950QDCYRQ1','SOT-223; ersetzt LM2936 / 5 V, 150 mA'),
        ('MCU1','ESP32-C3 SuperMini / 4 MB','ca. 23 x 18 mm; Header noch abzugleichen'),
        ('Q1 / Z1','DMP6023LE / BZT52C12','SOT-223 / SOD-123; Zener K an Source'),
        ('F1','T0,8 A, >=60 V','MPN/Footprint nach Inrush-/Thermikprüfung'),
        ('D1 / D2','SMBJ20A / SS36','SMB / SMC; Orientierung siehe Blatt 1'),
        ('D3','PESD2CAN24T-QR','SOT-23; 1 CANH, 2 CANL, 3 GND_BUS'),
        ('L1','ACT45B-510-2P-TL003','1-4 und 2-3; 4,5 x 3,2 mm Gehäuse'),
        ('R1 / R2','100 kΩ / 10 kΩ','0805 / 1 %'),
        ('R_TX / R_RX','je 33 Ω','0805; nahe am jeweiligen Treiberausgang'),
        ('C1 / C2 / C3','47 µF50V / 1 µF50V / 10 µF16V','C3 X7R; effektive Kapazität >=2,2 µF'),
        ('C4 / C5','je 100 nF X7R / 16 V','direkt an U1 VCC2/GND2 bzw. VCC1/GND1'),
        ('C6 / C7','47 µF10V / 100 nF16V','U2-Ausgang; Lastkapazität gesamt prüfen'),
        ('C8 / L2 / C9','10 µF50V / 15 µH>=1A / 10 µF50V','X7R; L2 verlustarm, Isat >=1 A, DCR prüfen'),
        ('J1 / JP1','5-pol. Pigtailklemme / 2-pol. Jumper','Raster und MPN noch festzulegen'),
    ]
    yy=51
    for i,(ref,value,note) in enumerate(rows):
        if i%2==0:s.rect(14,yy-4,239,11,fill='#f3f6f8',stroke=None)
        s.text(17,yy,ref,2.9,bold=True);s.text(47,yy,value,2.85);s.text(47,yy+4.4,note,2.55,MUTED)
        yy+=11
    s.box(264,37,142,62,'Vor einer Platinenbestellung')
    s.lines(270,51,['1. SuperMini-Pinfolge, USB-Überstand und Header messen.', '2. U1/U2-Landpatterns aus Originaldaten übernehmen.', '3. F1, J1 und JP1 als konkrete Bestellteile festlegen.', '4. ERC, DRC und 3D-Kollisionstest im ECAD durchführen.', '5. Erst danach Gerber, Bohr- und Bestückungsdaten.'],2.75,8)
    s.box(264,105,142,69,'Elektrische Auslegung noch zu verifizieren')
    s.lines(270,119,['U2: mindestens 9 V hinter F1/Q1/Filter erforderlich.', '9-V-NET-S-Betrieb ist damit nicht garantiert.', 'RECOM-Class-B-Filter enthält zusätzlich 470 pF', 'über der Isolation; hier weggelassen, keine Class-B-Zusage.', 'U3: (16 V - 5 V) x 73,4 mA = ca. 0,81 W.', 'Wärmefläche aus Blatt 3 ist Startwert, keine Thermikfreigabe.', 'LEN aus gemessenem Maximalstrom bestimmen.'],2.65,7)
    s.box(264,180,142,45,'Erstinbetriebnahme')
    s.lines(270,194,['Strombegrenztes Labornetzteil; zunächst ohne CAN.', '5V_BUS, 5V_MODULE und 3V3_LOGIC messen.', 'Trennung beider Massen und USB-Jumper prüfen.', 'Danach CAN mit korrekt terminiertem Prüfnetz testen.'],2.8,7)
    s.text(15,240,'PRIMÄRQUELLEN - anklickbar im PDF; vollständige Links in der Projekt-Dokumentation',3.0,bold=True)
    for i,(title,desc,url) in enumerate(SOURCES):
        col=i%3; row=i//3; x=16+col*133; y=249+row*8
        s.text(x,y,title,2.9,LOGIC,bold=True)
        s.text(x,y+3.5,desc,2.45,MUTED)
        c.linkURL(url,(x*MM,(H-y-4)*MM,(x+124)*MM,(H-y+3)*MM),relative=0,thickness=0)
    s.finish()


if __name__=='__main__':
    power_sheet();signal_sheet();layout_sheet();notes_sheet()
    c.save()
    (SVG/'sources.json').write_text(json.dumps(SOURCES,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(PDF)
    print('4 vector SVG sheets: '+str(SVG))
