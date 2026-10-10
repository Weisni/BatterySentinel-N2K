"""Produce reusable approximate component envelopes for the R4 library.

This writes only model-overrides.json; it does not mutate the shared design.
Colours, formed lead profiles and antenna artwork are illustrative. Envelope
dimensions and lead centres are read from the reviewed R4 component model.
"""
import argparse
import json
import math
from pathlib import Path

SILVER=[179,188,198];GOLD=[207,163,58];DARK=[40,43,47]
GREEN=[27,91,77];CERAMIC=[180,146,100]

def rect(name,x,y,w,d,z0,z1,rgb):
    return {'name':name,'outline':[[x-w/2,y-d/2],[x+w/2,y-d/2],[x+w/2,y+d/2],[x-w/2,y+d/2]],'z0':z0,'z1':z1,'rgb':rgb}

def circle(name,x,y,r,z0,z1,rgb):
    return {'name':name,'outline':[[x+r*math.cos(a*math.pi/16),y+r*math.sin(a*math.pi/16)] for a in range(32)],'z0':z0,'z1':z1,'rgb':rgb}

def models(part):
    ref=part['ref'];fp=part['pcb_footprint'];w,d=fp['body'];h=max(.2,fp['height']);pads=fp['pads']
    if ref=='MCU1':
        # Espressif WROOM-02 datasheet v1.7 p35 Fig10-1: shield15.7x12.37,
        # 1.15mm side margins and0.70mm setback from module bottom. PCB18x20.
        # The former illustrative17x13.7 shield incorrectly crossed the PCB.
        b=[rect('WROOM module PCB direct solder mounting',0,0,18,20,.08,.95,GREEN),
           rect('RF shield metal enclosure',0,-3.115,15.7,12.37,.95,3.2,SILVER),
           rect('RF shield top',0,-3.115,15.7,12.37,3.2,3.35,SILVER)]
        for p in pads:
            if str(p['number'])=='19':continue
            x=math.copysign(8.78,p['x'])
            b.append(rect('castellated gold contact '+str(p['number']),x,p['y'],.44,.72,.06,.98,GOLD))
        # An indicative PCB antenna makes its RF keepout visually recognisable.
        for y in [5.2,7.0,8.8]:b.append(rect('illustrative antenna trace',0,y,12.0,.22,.95,.972,GOLD))
        for x,y in [(6,6.1),(-6,7.9)]:b.append(rect('illustrative antenna bend',x,y,.22,1.8,.95,.972,GOLD))
        return b
    if ref=='J2':
        b=[rect('USB-C shell bottom',0,0,w,d,.08,.27,SILVER),
           rect('USB-C shell top',0,0,w,d,3.05,3.26,SILVER),
           rect('USB-C shell left',-w/2+.1,0,.2,d,.27,3.05,SILVER),
           rect('USB-C shell right',w/2-.1,0,.2,d,.27,3.05,SILVER),
           rect('USB-C rear insulator',0,d/2-.4,w-.4,.8,.28,3.03,DARK),
           rect('USB-C centre tongue',0,-.75,6.69,4.7,1.40,1.76,DARK)]
        for i in range(12):b.append(rect('USB-C visible contact '+str(i+1),-2.75+i*.5,-1.15,.22,2.8,1.76,1.78,GOLD))
        for p in pads:
            if p.get('drill'):
                b.append(rect('USB-C shell through tab '+str(p['number']),p['x'],p['y'],.25,min(1.0,p['drill_slot_length_mm']-.25),-1.3,.5,SILVER))
            else:b.append(rect('USB-C SMT terminal '+str(p['number']),p['x'],p['y'],min(.35,p['sx']*.7),.95,.025,.22,SILVER))
        return b
    if ref.startswith('SW'):
        return [rect('switch insulating base',0,0,3.9,3.0,.12,1.20,DARK),
                rect('switch steel top',0,0,3.8,2.9,1.2,1.5,SILVER),
                circle('switch actuator',0,0,.9,1.5,2.0,DARK)]+[
                    rect('switch lead '+str(p['number']),p['x'],0,.9,1.3,.03,.2,SILVER) for p in pads]
    if ref=='U2':
        return [rect('isolated converter SIP housing',0,0,19.65,7.0,.15,10.31,DARK),
                rect('converter label area',0,0,16.4,5.1,10.31,10.33,[68,73,79])]+[
                    rect('SIP through lead '+str(p['number']),p['x'],p['y'],.5,.5,-2.5,.45,SILVER) for p in pads]
    if ref=='J1':
        # This is a bare wire solder interface, not a purchased header housing.
        b=[]
        for p in pads:
            x,y=p['x'],p['y'];sx,sy=p['sx'],p['sy'];rim=.18
            b.extend([rect('bare wire-pad copper edge',x,y+sign*(sy-rim)/2,sx,rim,.025,.06,GOLD) for sign in [-1,1]])
            b.extend([rect('bare wire-pad copper edge',x+sign*(sx-rim)/2,y,rim,sy-2*rim,.025,.06,GOLD) for sign in [-1,1]])
        return b
    if ref.startswith('TP'):
        return [circle('exposed test point copper',0,0,pads[0]['sx']/2,.025,.06,GOLD)]
    color=CERAMIC if ref.startswith('C') else DARK
    b=[rect('selected package envelope',0,0,w,d,.08,h,color)]
    if ref.startswith(('R','C','F')) and len(pads)==2:
        for sign in [-1,1]:b.append(rect('metal end cap',sign*(w/2-min(.38,w*.18)/2),0,min(.38,w*.18),d+.015,.025,h+.015,SILVER))
        return b
    if ref in ('L2','L3'):
        b=[rect('power inductor ferrite',0,0,4,4,.1,3,[68,65,62]),circle('power inductor top',0,0,1.6,3,3.015,[78,74,70])]
    for p in pads:
        x,y=p['x'],p['y']
        if ref.startswith('D') and len(pads)==2:
            b.append(rect('diode end terminal '+str(p['number']),x,0,min(1.15,p['sx']),min(2.1,p['sy']),.025,.2,SILVER))
        elif abs(x)>w/2:
            b.append(rect('gull wing terminal '+str(p['number']),(x+math.copysign(w/2-.05,x))/2,y,abs(x)-w/2+.55,min(.48,p['sy']*.8),.025,.22,SILVER))
        elif abs(y)>d/2:
            b.append(rect('gull wing terminal '+str(p['number']),x,(y+math.copysign(d/2-.05,y))/2,min(.45,p['sx']*.8),abs(y)-d/2+.55,.025,.22,SILVER))
        else:b.append(rect('terminal '+str(p['number']),x,y,p['sx']*.8,p['sy']*.8,.025,.18,SILVER))
    if ref.startswith('D') and len(pads)==2:
        b.append(rect('cathode band',-w*.31,0,.25,d*.98,h,h+.015,[186,190,193]))
    if ref.startswith(('U','D')) and len(pads)>2:
        p1=next(p for p in pads if str(p['number'])=='1')
        b.append(circle('pin 1 indicator',math.copysign(w*.3,p1['x']),math.copysign(d*.3,p1['y']),.13,h,h+.015,[145,150,155]))
    return b

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('design',type=Path);p.add_argument('--output',type=Path,required=True);args=p.parse_args()
    data=json.loads(args.design.read_text(encoding='utf-8'));parts={}
    for c in data['components']:
        b=models(c)
        if b:parts[c['ref']]={'bodies_3d':b}
    result={'model_class':'Locally generated approximate package models; not manufacturer-certified STEP geometry. Direct-solder WROOM, no pin headers.','components':parts}
    args.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'components':len(parts),'bodies':sum(len(p['bodies_3d']) for p in parts.values()),'output':str(args.output)}))
