"""Render generated SchDoc records for geometry QA (not an Altium screenshot)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT/'hardware'/'altium'
SCALE = 1.5
W, H = 2230, 1570


def render():
    rows = []
    for line in (FOLDER/'Orion-Bridge-R1.SchDoc').read_text('ascii').splitlines()[1:]:
        rows.append({k.upper(): v for field in line.split('|') if '=' in field for k,v in [field.split('=',1)]})
    im = Image.new('RGB', (int(W*SCALE), int(H*SCALE)), '#fffdf5')
    d = ImageDraw.Draw(im)
    def p(x,y): return float(x)*SCALE, (H-float(y))*SCALE
    fonts = {i: ImageFont.truetype('C:/Windows/Fonts/'+('arialbd.ttf' if i==2 else 'arial.ttf'), round(size/0.72*SCALE))
             for i,size in [(1,9),(2,12),(3,7)]}
    def txt(x,y,text,font=1,color='#16354a',anchor='ls'):
        d.text(p(x,y),text,font=fonts[font],fill=color,anchor=anchor)
    for r in rows:
        kind = r['RECORD']
        if kind=='14':
            a=p(r['LOCATION.X'],r['CORNER.Y']); b=p(r['CORNER.X'],r['LOCATION.Y'])
            d.rectangle([a,b],fill='#fff5d1',outline='#7c3030',width=2)
        elif kind=='27':
            d.line([p(r['X1'],r['Y1']),p(r['X2'],r['Y2'])],fill='#28538e',width=2)
        elif kind=='2':
            x,y=float(r['LOCATION.X']),float(r['LOCATION.Y'])
            ori=int(r['PINCONGLOMERATE'])&3
            direction=-1 if ori==2 else 1
            d.line([p(x,y),p(x+direction*int(r['PINLENGTH']),y)],fill='#713535',width=2)
            txt(x+5 if direction==-1 else x-5,y,r['NAME'],3,anchor='lm' if direction==-1 else 'rm')
            txt(x+direction*10,y+4,r['DESIGNATOR'],3,anchor='ms')
        elif kind=='22':
            x,y=float(r['LOCATION.X']),float(r['LOCATION.Y'])
            d.line([p(x-4,y-4),p(x+4,y+4)],fill='red',width=2)
            d.line([p(x-4,y+4),p(x+4,y-4)],fill='red',width=2)
        elif kind in ('4','25','34','41') and r.get('ISHIDDEN')!='T' and 'LOCATION.X' in r:
            txt(r['LOCATION.X'],r['LOCATION.Y'],r.get('TEXT',''),int(r.get('FONTID',1)),
                '#a32121' if r.get('COLOR')=='255' else '#16354a')
    out=FOLDER/'Schaltplan-Vorschau.png'
    im.save(out)
    print(out)


def render_pcb():
    import math
    records = []
    for line in (FOLDER/'Orion-Bridge-R1.PcbDoc').read_text('cp1252').splitlines():
        records.append({k.upper(): v for field in line.split('|') if '=' in field for k,v in [field.split('=',1)]})
    def mm(value): return float(value.removesuffix('mil'))*0.0254
    scale=18
    im=Image.new('RGB',(1620,1404),'#f5f6f4')
    d=ImageDraw.Draw(im)
    def p(x,y): return (x+5)*scale,(65-y)*scale
    d.rectangle([p(0,60),p(80,0)],fill='#183e38',outline='black',width=3)
    colors={'MECHANICAL13':'#8eb9ac','MECHANICAL15':'#42675f',
            'MECHANICAL2':'#f0c968','MECHANICAL1':'#171e1c','KEEPOUT':'#606066'}
    for layer in ['KEEPOUT','MECHANICAL15','MECHANICAL13','MECHANICAL2','MECHANICAL1']:
        for r in records:
            if r.get('RECORD')=='Track' and r.get('LAYER')==layer:
                d.line([p(mm(r['X1']),mm(r['Y1'])),p(mm(r['X2']),mm(r['Y2']))],
                       fill=colors[layer],width=max(1,round(mm(r['WIDTH'])*scale)))
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',15)
    for r in records:
        if r.get('RECORD')!='Pad': continue
        x,y,sx,sy=map(mm,[r['X'],r['Y'],r['XSIZE'],r['YSIZE']])
        angle=math.radians(float(r['ROTATION']))
        pts=[p(x+dx*math.cos(angle)-dy*math.sin(angle),y+dx*math.sin(angle)+dy*math.cos(angle))
             for dx,dy in [(-sx/2,-sy/2),(sx/2,-sy/2),(sx/2,sy/2),(-sx/2,sy/2)]]
        color='#e7b868' if r.get('NET') is not None else '#9aa7a4'
        if r['SHAPE']=='ROUND': d.ellipse([p(x-sx/2,y+sy/2),p(x+sx/2,y-sy/2)],fill=color)
        else: d.polygon(pts,fill=color)
        drill=mm(r['HOLESIZE'])
        if drill: d.ellipse([p(x-drill/2,y+drill/2),p(x+drill/2,y-drill/2)],fill='#f5f6f4')
        if not drill and r.get('NAME'): d.text(p(x,y),r['NAME'],fill='#14231d',font=font,anchor='mm')
    for r in records:
        if r.get('RECORD')=='Text' and r.get('LAYER') in ['TOPOVERLAY','MECHANICAL2','MECHANICAL3']:
            h=max(12,round(mm(r['HEIGHT'])*scale))
            f=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',h)
            d.text(p(mm(r['X']),mm(r['Y'])),r['TEXT'],font=f,fill='#ecf0dd' if r['LAYER']=='TOPOVERLAY' else '#bb8e26',anchor='ls')
    d.text((90,30),'80 x 60 mm | TOP | Native ASCII geometry preview - not an Altium rendering',font=font,fill='#16354a')
    out=FOLDER/'PCB-Vorschau.png'
    im.save(out)
    print(out)


if __name__=='__main__':
    render()
    render_pcb()
