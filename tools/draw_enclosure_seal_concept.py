"""Draw the reviewed enclosure concept; no production geometry is generated."""
from pathlib import Path
import html
import math
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'hardware/altium-r5/enclosure/seal-redesign'
W, H = 2200, 1820
BG, INK, MUTED = '#f8fafc', '#173246', '#546c7d'
PETG, EDGE, TPU, CABLE, PCB = '#dbe7ef', '#597b92', '#f3bd57', '#495562', '#c4e5d8'
im = Image.new('RGB', (W, H), BG)
d = ImageDraw.Draw(im)
svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
       '<title>Orion Bridge enclosure seal revision concept</title>',
       '<desc>Four views: extended cable bay, separate sealing and clamping, three-screw cap, and raised face-seal bead. Cable diameter 7 mm. Proposal, not validated manufacturing geometry.</desc>',
       f'<rect width="{W}" height="{H}" fill="{BG}"/>']

def text(x, y, s, size=26, color=INK, bold=False):
    f = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf' if bold else 'C:/Windows/Fonts/arial.ttf', size)
    d.text((x, y), s, font=f, fill=color)
    svg.append(f'<text x="{x}" y="{y + size * .92}" font-family="Arial, sans-serif" font-size="{size}" font-weight="{700 if bold else 400}" fill="{color}">{html.escape(s)}</text>')

def line(points, color=EDGE, width=3, dash=False):
    if dash:
        for a,b in zip(points, points[1:]):
            length=math.dist(a,b)
            for k in range(0, int(length), 15):
                t,u=k/length,min(k+8,length)/length
                d.line([(a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t),
                        (a[0]+(b[0]-a[0])*u,a[1]+(b[1]-a[1])*u)],fill=color,width=width)
    else:
        d.line(points, fill=color, width=width, joint='curve')
    coords=' '.join(f'{x},{y}' for x,y in points)
    attr=' stroke-dasharray="8 7"' if dash else ''
    svg.append(f'<polyline points="{coords}" fill="none" stroke="{color}" stroke-width="{width}"{attr}/>')

def rect(x,y,w,h,fill=PETG,stroke=EDGE,r=0,width=3):
    d.rounded_rectangle((x,y,x+w,y+h), radius=r, fill=fill, outline=stroke, width=width)
    svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>')

def poly(points,fill=PETG,stroke=EDGE,width=3):
    d.polygon(points,fill=fill)
    d.line(points+[points[0]],fill=stroke,width=width,joint='curve')
    svg.append(f'<polygon points="{" ".join(f"{x},{y}" for x,y in points)}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>')

def circle(x,y,r,fill=BG,stroke=EDGE,width=3):
    d.ellipse((x-r,y-r,x+r,y+r),fill=fill,outline=stroke,width=width)
    svg.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>')

def arrow(a,b,color=INK,width=3,both=False):
    line([a,b],color,width)
    def head(tail,tip):
        dx,dy=tip[0]-tail[0],tip[1]-tail[1]
        z=math.hypot(dx,dy); ux,uy=dx/z,dy/z
        poly([tip,(tip[0]-ux*13-uy*5,tip[1]-uy*13+ux*5),
              (tip[0]-ux*13+uy*5,tip[1]-uy*13-ux*5)],color,color,1)
    head(a,b)
    if both:head(b,a)

def panel(x,y,num,title,subtitle):
    text(x,y,num,28,'#bc7b16',True)
    text(x+48,y,title,32,INK,True)
    text(x,y+47,subtitle,23,MUTED)

text(60,40,'ORION BRIDGE  /  SEAL REVISION',47,INK,True)
text(62,105,'7 mm cable  ·  Separate strain relief  ·  Controlled seal compression',29,MUTED)
text(62,151,'DESIGN PROPOSAL — 27 SEP 2026 — dimensions in mm; detail sections schematic',23,MUTED)
line([(60,198),(2140,198)],'#c4d1db',2)
panel(60,225,'01','Make room for the clamp','Top view, lid removed · PCB and service ports retain their positions')
panel(1140,225,'02','Seal and strain relief have separate jobs','Cable-axis section · details exaggerated for clarity')

# Top view, real relative body/PCB coordinates; s = 8 px/mm.
s=8; x0,y0=145,351
px=lambda x:x0+(x+28)*s
py=lambda y:y0+(y+12)*s
rect(px(-28),py(-12),92*s,60*s,r=40)
rect(px(-20),py(-4),76*s,44*s,fill=BG,r=22)
rect(px(0),py(0),52*s,36*s,fill=PCB,stroke='#558b77',r=12)
text(px(12),py(10),'PCB',32,INK,True)
text(px(9),py(17),'52 × 36',25)
line([(px(-12),py(-12)),(px(-12),py(48))],MUTED,2,True)
text(72,850,'Dashed line: previous outer wall',23,MUTED)
rect(px(-38),py(14.5),44*s,7*s,fill=CABLE,stroke=CABLE,r=8)
rect(px(-28)-40,py(12),40,12*s,fill=PETG,r=5)
rect(px(-28),py(12.5),6*s,11*s,fill=TPU,stroke='#b48427',r=4)
rect(px(-18),py(6),12*s,24*s,fill=PETG,r=8)
rect(px(-18),py(14.5),12*s,7*s,fill=CABLE,stroke=CABLE)
for cx,cy in [(-12,9),(-12,27)]:circle(px(cx),py(cy),9)
for x in [-16,-12,-8]:line([(px(x),py(14.5)),(px(x),py(21.5))],TPU,5)
text(95,321,'New cable bay',23,INK,True)
arrow((225,347),(px(-12),py(7)))
text(450,765,'Internal clamp: 12 mm contact',23)
line([(450,755),(405,720),(px(-12),py(30))])
arrow((px(-28),809),(px(-12),809),both=True)
text(159,775,'+16',22)
arrow((px(-28),912),(px(64),912),both=True)
text(320,925,'Body: 92 × 60 × 33.2  (was 76 × 60 × 33.2)',23)
text(470,842,'6 mm to PCB outline',23,MUTED)
line([(470,837),(420,791),(px(-3),py(18))],MUTED,2)

# Axial section: cap, wall pocket with continuous shoulder bead, inner clamp.
sx,sy=1140,340
text(sx+15,sy,'OUTSIDE',22,MUTED,True)
text(sx+360,sy,'INSIDE',22,MUTED,True)
rect(sx+170,sy+85,130,380,fill=PETG)
# White pocket channel and cable clearance through the shoulder.
rect(sx+168,sy+196,98,158,fill=BG,stroke=BG,width=0)
rect(sx+260,sy+226,42,98,fill=BG,stroke=BG,width=0)
# Solid continuous sleeve carrier above and below jacket, face bead at right.
poly([(sx+170,sy+211),(sx+247,sy+211),(sx+267,sy+217),(sx+267,sy+237),
      (sx+237,sy+237),(sx+227,sy+246),(sx+217,sy+237),
      (sx+195,sy+237),(sx+184,sy+246),(sx+170,sy+237)],TPU,'#b48427')
poly([(sx+170,sy+339),(sx+247,sy+339),(sx+267,sy+333),(sx+267,sy+313),
      (sx+237,sy+313),(sx+227,sy+304),(sx+217,sy+313),
      (sx+195,sy+313),(sx+184,sy+304),(sx+170,sy+313)],TPU,'#b48427')
# Cap section pressure faces + screw outside wet path.
rect(sx+90,sy+120,80,126,fill=PETG)
rect(sx+90,sy+304,80,126,fill=PETG)
rect(sx+75,sy+138,200,18,fill=EDGE,stroke=EDGE,r=5)
rect(sx+245,sy+132,30,30,fill='#c5a26a',stroke=EDGE)
rect(sx+15,sy+246,885,58,fill=CABLE,stroke=CABLE,r=5)
text(sx+25,sy+257,'Ø 7',24,'#ffffff',True)
# Clamp section, fully within internal bay.
rect(sx+378,sy+187,240,59,fill=PETG,r=12)
rect(sx+378,sy+304,240,59,fill=PETG,r=12)
rect(sx+378,sy+363,240,102,fill=PETG)
for x in [sx+420,sx+490,sx+560]:
    circle(x,sy+247,9,fill=PETG)
    circle(x,sy+303,9,fill=PETG)
rect(sx+300,sy+465,630,36,fill=PETG)
rect(sx+760,sy+344,170,15,fill=PCB,stroke='#558b77')
text(sx+771,sy+375,'PCB',24)
text(sx+356,sy+103,'Rigid upper half-shell',24,INK,True)
line([(sx+508,sy+135),(sx+508,sy+187)])
text(sx+370,sy+524,'Saddle transfers pull into the base',24)
line([(sx+511,sy+515),(sx+511,sy+423)])
text(sx+45,sy+574,'TPU: jacket beads + continuous shoulder seal',24)
line([(sx+207,sy+565),(sx+207,sy+410),(sx+235,sy+337)],'#b48427')
text(sx+550,sy+155,'Wire slack after clamp',23,MUTED)
line([(sx+774,sy+183),(sx+801,sy+244)],MUTED,2)
arrow((sx+860,sy+63),(sx+691,sy+63),both=False)
text(sx+566,sy+15,'Cable load → clamp → case',24)

line([(60,1008),(2140,1008)],'#c4d1db',2)
panel(60,1040,'03','Stiff three-screw pressure plate','Outside view · rounded outline, central collar, ribs and hard stops')
panel(1140,1040,'04','Raised bead instead of a flat gasket','Lid + USB + switch · new groove required; section exaggerated')

# Triangular plate around actual hole centres; enlarged detail only.
cx,cz=310,1400; k=13
p=lambda yy,zz:(cx+(yy-18)*k,cz-(zz-14)*k)
A,B,C=p(18,24),p(7,8),p(29,8)
poly([(cx,cz-190),(cx+38,cz-168),(cx+193,cz+60),(cx+193,cz+103),
      (cx+168,cz+130),(cx-168,cz+130),(cx-193,cz+103),(cx-193,cz+60),(cx-38,cz-168)],PETG)
for hole in [A,B,C]:
    line([hole,(cx,cz)],EDGE,25)
circle(cx,cz,89,fill=PETG,stroke=EDGE,width=5)
circle(cx,cz,51,fill=TPU,stroke='#b48427')
circle(cx,cz,45,fill=CABLE,stroke=CABLE)
for hole in [A,B,C]:
    circle(*hole,32,fill=PETG)
    circle(*hole,22,fill=BG)
    line([(hole[0]-10,hole[1]),(hole[0]+10,hole[1])],MUTED,2)
text(560,1200,'3 × M3 in blind pockets',26,INK,True)
text(560,1255,'5 mm plate + 2 mm ribs',26)
text(560,1310,'Ring collar loads the sleeve',25)
text(560,1365,'Stops limit seal compression',25)
text(560,1420,'Approx. 30 × 24 mm outline',25)
text(560,1475,'Tighten evenly to the stops',25)
text(560,1530,'Seal does not retain the cable',24,MUTED)
text(100,1595,'Sleeve test bores for Ø 7 jacket: 6.9 / 6.8 / 6.7',26,INK,True)

# Gasket profile, carrier and rounded bead / clearance both sides.
gx,gy=1190,1230
rect(gx,gy+138,680,187,fill=PETG)
rect(gx+130,gy+100,420,175,fill=BG,stroke=BG,width=0)
rect(gx+170,gy+215,340,60,fill=TPU,stroke='#b48427')
# Rounded dome with flat bottom (poly sampled semicircle/ellipse).
pts=[(gx+257,gy+216)]
pts += [(gx+340+83*math.cos(a),gy+216-116*math.sin(a)) for a in [math.pi-i*math.pi/40 for i in range(41)]]
pts += [(gx+423,gy+216)]
poly(pts,TPU,'#b48427')
rect(gx,gy+20,680,50,fill=PETG)
line([(gx,gy+138),(gx+680,gy+138)],MUTED,2,True)
arrow((gx+715,gy+72),(gx+715,gy+138),both=False)
text(gx+490,gy+78,'Closing',23,MUTED)
text(gx+22,gy-35,'Rigid lid / cover',25,INK,True)
text(gx+150,gy+343,'Carrier 0.8 + bead 1.0 = 1.8 free',25)
text(gx+150,gy+385,'Hard stop: 1.4 closed  →  22% squeeze',25)
text(gx+150,gy+427,'3.4 wide groove leaves relief space',25)
text(gx+145,gy+475,'Not compatible with old 1.0-deep groove',24,'#975d0d',True)
line([(gx+92,gy+170),(gx+148,gy+242)],MUTED,2)
text(gx-4,gy+176,'Relief',23,MUTED)

text(60,1780,'PETG structure',22,EDGE,True)
rect(252,1781,25,22,fill=PETG)
text(316,1780,'TPU seal',22,'#946915',True)
rect(435,1781,25,22,fill=TPU,stroke='#b48427')
text(550,1780,'Concept only: CAD fit, print calibration, pull and leak tests remain open.',22,MUTED)
svg.append('</svg>')
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'seal-redesign.svg').write_text('\n'.join(svg),encoding='utf8')
im.save(OUT/'seal-redesign.png')
print(f'Wrote concept drawing: {W} x {H}; cable OD 7 mm; body length 92 mm.')
