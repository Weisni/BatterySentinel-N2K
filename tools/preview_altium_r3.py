"""Geometry-based placement/routing preview and mechanical spacing audit."""
import argparse,json,sys,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tmp/pcb-python'))
from shapely.geometry import box,Point
from shapely import affinity
from altium_pcb import footprint,footprint_bounds,transform
from route_altium_r3 import extract_pads

def placed_rect(c,bounds):
    s=box(*bounds)
    return affinity.translate(affinity.rotate(s,c['pcb'].get('rotation',0),origin=(0,0)),c['pcb']['x'],c['pcb']['y'])

def mechanical_audit(data, body_gap=.5, pad_body_gap=.25):
    """Check real bodies and individual lands, rather than their empty bounding corners.

    MCU1 sits 3.1 mm above the carrier. Parts <=1.5 mm may occupy its underside,
    but the two 2.54 mm header housings and the RF reservation remain obstacles.
    The header and screw-head allowances are explicit engineering assumptions.
    """
    parts={c['ref']:c for c in data['components']}
    fps={ref:footprint(c) for ref,c in parts.items()}
    bodies={ref:placed_rect(c,(-fps[ref].body[0]/2,-fps[ref].body[1]/2,
                             fps[ref].body[0]/2,fps[ref].body[1]/2))
            for ref,c in parts.items() if not ref.startswith('TP')}
    pads=extract_pads(data)
    board=box(0,0,data['board']['width_mm'],data['board']['height_mm'])
    errors=[];under=set();minimum_body=math.inf;minimum_pad_body=math.inf
    headers=[]
    if 'MCU1' in parts:
        for side in (-1,1):
            headers.append(placed_rect(parts['MCU1'],(side*7.62-1.27,-8.0794-1.27,
                                                       side*7.62+1.27,9.7006+1.27)))
    for ref,body in bodies.items():
        if not board.buffer(1e-6).covers(body): errors.append(dict(kind='body_outside_board',ref=ref))
    for p in pads:
        if not board.buffer(1e-6).covers(p['geometry']):errors.append(dict(kind='pad_outside_board',ref=p['ref'],pin=p['number']))
    refs=list(bodies)
    for i,a in enumerate(refs):
        for b in refs[i+1:]:
            dist=bodies[a].distance(bodies[b])
            if 'MCU1' in (a,b):
                other=b if a=='MCU1' else a
                if fps[other].height<=1.5:
                    if bodies[other].intersects(bodies['MCU1']):under.add(other)
                    continue
            minimum_body=min(minimum_body,dist)
            if dist<body_gap-1e-6: errors.append(dict(kind='body_spacing',refs=[a,b],gap_mm=round(dist,4),required_mm=body_gap))
    for p in pads:
        for ref,body in bodies.items():
            if ref==p['ref'] or ref=='MCU1':continue
            dist=p['geometry'].distance(body)
            minimum_pad_body=min(minimum_pad_body,dist)
            if dist<pad_body_gap-1e-6: errors.append(dict(kind='pad_body_spacing',pad=f"{p['ref']}.{p['number']}",body=ref,gap_mm=round(dist,4),required_mm=pad_body_gap))
    for ref,body in bodies.items():
        if ref=='MCU1':continue
        for i,head in enumerate(headers):
            dist=body.distance(head)
            if dist<body_gap-1e-6:errors.append(dict(kind='module_header_body',ref=ref,header=i,gap_mm=round(dist,4)))
    for p in pads:
        if p['ref']=='MCU1':continue
        for i,head in enumerate(headers):
            dist=p['geometry'].distance(head)
            if dist<pad_body_gap-1e-6:errors.append(dict(kind='module_header_pad',pad=f"{p['ref']}.{p['number']}",header=i,gap_mm=round(dist,4)))
    # A declared service envelope, not a claim that every USB cable fits:
    # 12 mm wide, extending 14 mm beyond the module's USB edge. Low carrier
    # parts remain below the raised plug; cans and jumper must stay outside.
    if 'MCU1' in parts:
        usb=placed_rect(parts['MCU1'],(-6,11.25,6,25.25))
        for ref,body in bodies.items():
            if ref!='MCU1' and fps[ref].height>2.5 and body.distance(usb)<.25-1e-6:
                errors.append(dict(kind='usb_service_body',ref=ref,height_mm=fps[ref].height))
    for k in data['routing_constraints']['keepouts']:
        area=box(k['x1'],k['y1'],k['x2'],k['y2'])
        is_rf='antenna' in k['name'].lower()
        if is_rf:
            for ref,body in bodies.items():
                if ref!='MCU1' and body.intersection(area).area>1e-8:errors.append(dict(kind='antenna_body',ref=ref))
        for p in pads:
            if p['geometry'].intersection(area).area>1e-8:errors.append(dict(kind='pad_keepout',pad=f"{p['ref']}.{p['number']}",keepout=k['name']))
    for x,y in data['board'].get('holes_mm',[]):
        head=Point(x,y).buffer(2.4)
        for ref,body in bodies.items():
            if head.intersects(body):errors.append(dict(kind='screwhead_body',ref=ref,hole=[x,y]))
        for p in pads:
            if head.intersects(p['geometry']):errors.append(dict(kind='screwhead_pad',pad=f"{p['ref']}.{p['number']}",hole=[x,y]))
    return dict(passed=not errors,errors=errors,under_module=sorted(under),
                minimum_body_gap_mm=round(minimum_body,4),minimum_pad_body_gap_mm=round(minimum_pad_body,4),
                assumptions={'body_gap_mm':body_gap,'pad_to_foreign_body_gap_mm':pad_body_gap,
                             'module_underside_mm':3.1,'under_module_max_component_height_mm':1.5,
                             'header_housing_width_mm':2.54,'screw_head_diameter_mm':4.8,
                             'usb_service_width_mm':12,'usb_service_projection_mm':14,
                             'usb_service_minimum_bottom_z_mm':2.5},
                limitations=['Maximum body dimensions where available; remaining R2 generic packages retain their status.',
                             'USB service envelope is reserved; actual cable overmold, header seating tolerance, strain relief and enclosure fit still need physical verification.'])

def preview(data,path,routing=None):
    w,h=data['board']['width_mm'],data['board']['height_mm']
    scale=22; margin=30
    sx=lambda x:margin+x*scale
    sy=lambda y:margin+(h-y)*scale
    from html import escape
    rows=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{w*scale+2*margin}" height="{h*scale+2*margin+40}" viewBox="0 0 {w*scale+2*margin} {h*scale+2*margin+40}">',
          '<rect width="100%" height="100%" fill="#111b25"/>',
          f'<rect x="{margin}" y="{margin}" width="{w*scale}" height="{h*scale}" rx="4" fill="#133e32" stroke="#8bd7bd" stroke-width="2"/>']
    def rect(b,fill,stroke,width=1):
        x1,y1,x2,y2=b
        rows.append(f'<rect x="{sx(x1)}" y="{sy(y2)}" width="{(x2-x1)*scale}" height="{(y2-y1)*scale}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>')
    def label(x,y,s,size=11,color='#edf5ef'):
        rows.append(f'<text x="{sx(x)}" y="{sy(y)}" font-family="Arial" font-size="{size}" fill="{color}" text-anchor="middle">{escape(s)}</text>')
    for k in data['routing_constraints']['keepouts']:
        rect((k['x1'],k['y1'],k['x2'],k['y2']),'#544727','#9c8150')
    if routing:
        for layer,color in [('BOTTOM','#5890f2'),('TOP','#f17869')]:
            for t in routing['tracks']:
                if t['layer']!=layer:continue
                rows.append(f'<path d="M {sx(t["x1"])} {sy(t["y1"])} L {sx(t["x2"])} {sy(t["y2"])}" stroke="{color}" stroke-width="{t["width"]*scale}" stroke-linecap="round"/>')
        for v in routing['vias']:
            rows.append(f'<circle cx="{sx(v["x"])}" cy="{sy(v["y"])}" r="{v["diameter"]*scale/2}" fill="#d4b578"/><circle cx="{sx(v["x"])}" cy="{sy(v["y"])}" r="{v["drill"]*scale/2}" fill="#14242b"/>')
    envelopes={}; bodies={};audit=mechanical_audit(data);errors=audit['errors']
    for c in data['components']:
        fp=footprint(c)
        body=placed_rect(c,(-fp.body[0]/2,-fp.body[1]/2,fp.body[0]/2,fp.body[1]/2));bodies[c['ref']]=body
        env=placed_rect(c,footprint_bounds(fp));envelopes[c['ref']]=env
        rect(env.bounds,'none','#447862',.7)
        rect(body.bounds,'#17282999','#c1ddc7',1)
        label(c['pcb']['x'],c['pcb']['y'],c['ref'],12)
    for p in extract_pads(data):
        pts=' '.join(f'{sx(x)},{sy(y)}' for x,y in p['geometry'].exterior.coords)
        rows.append(f'<polygon points="{pts}" fill="#dfc282" stroke="#f9eac8" stroke-width="0.5"/>')
        if p['drill']:
            rows.append(f'<circle cx="{sx(p["x"])}" cy="{sy(p["y"])}" r="{p["drill"]*scale/2}" fill="#17232c"/>')
        label(p['x'],p['y']-.15,p['number'],8,'#202624')
    for x,y in data['board'].get('holes_mm',[]):
        rr=data['board'].get('hole_diameter_mm',2.2)/2
        rows.append(f'<circle cx="{sx(x)}" cy="{sy(y)}" r="{rr*scale}" fill="#111b25" stroke="#dfc282" stroke-width="2"/>')
    label(w/2,-2.2,f'Orion Bridge R3 | {w} x {h} mm | TOP red / BOTTOM blue | {len(errors)} assembly findings',13)
    rows.append('</svg>')
    Path(path).write_text('\n'.join(rows),encoding='utf8')
    return audit

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('data');p.add_argument('output');p.add_argument('--routing');a=p.parse_args()
    d=json.loads(Path(a.data).read_text());r=json.loads(Path(a.routing).read_text()) if a.routing else None
    print(json.dumps(preview(d,a.output,r),indent=2))
