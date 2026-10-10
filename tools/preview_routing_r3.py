"""Scale-accurate 2D copper review image from emitted routing geometry."""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tmp/pcb-python'))
import json
import argparse
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, Circle, Rectangle
from route_altium_r3 import extract_pads,_shape
from altium_pcb import footprint,transform

def render(data,routing,path):
    w,h=data['board']['width_mm'],data['board']['height_mm']
    fig,ax=plt.subplots(figsize=(13,10),facecolor='#111d24')
    ax.set_facecolor('#20382f')
    def shape(g,color,alpha=1,z=2):
        if g.geom_type=='MultiPolygon':
            for s in g.geoms:shape(s,color,alpha,z)
        else:ax.add_patch(Polygon(list(g.exterior.coords),facecolor=color,edgecolor='none',alpha=alpha,zorder=z))
    for k in routing.get('constraints',{}).get('keepouts',[]):
        ax.add_patch(Rectangle((k['x1'],k['y1']),k['x2']-k['x1'],k['y2']-k['y1'],facecolor='#49627a',alpha=.35,hatch='///',edgecolor='#8ca1b3',linewidth=.4))
    for layer,color in [('BOTTOM','#459ef0'),('TOP','#ff735c')]:
        for r in routing.get('regions',[]):
            if r['layer']==layer:
                ax.add_patch(Polygon(r['points'],facecolor=color,edgecolor='none',alpha=.14,zorder=1))
        for t in routing['tracks']:
            if t['layer']==layer:shape(_shape(t),color,.85)
    for p in extract_pads(data):
        shape(p['geometry'],'#edc976',1,3)
        if p['drill']:ax.add_patch(Circle((p['x'],p['y']),p['drill']/2,color='#10221c',zorder=4))
    for v in routing['vias']:
        shape(_shape(v),'#f2d493',1,3)
        ax.add_patch(Circle((v['x'],v['y']),v['drill']/2,color='#10221c',zorder=4))
    for c in data['components']:
        fp=footprint(c);bw,bh=fp.body
        pts=[transform(c,x,y) for x,y in [(-bw/2,-bh/2),(bw/2,-bh/2),(bw/2,bh/2),(-bw/2,bh/2)]]
        ax.add_patch(Polygon(pts,facecolor='none',edgecolor='#d6e5d9',linewidth=.6,zorder=5))
        ax.text(c['pcb']['x'],c['pcb']['y'],c['ref'],color='white',fontsize=7.5,weight='bold',ha='center',va='center',zorder=6,
                bbox=dict(boxstyle='round,pad=.11',facecolor='#20382f',edgecolor='none',alpha=.8))
    for x,y in data['board'].get('holes_mm',[]):
        ax.add_patch(Circle((x,y),data['board'].get('hole_diameter_mm',3.2)/2,color='#111d24',zorder=7))
    ax.set_xlim(-.1,w+.1);ax.set_ylim(-.1,h+.1);ax.set_aspect('equal')
    ax.tick_params(colors='#c3d4dd');ax.set_xlabel('mm',color='#c3d4dd');ax.set_ylabel('mm',color='#c3d4dd')
    ax.set_title(f'Orion Bridge R3 | {w:g} × {h:g} mm | Top: red · Bottom: blue',color='white',fontsize=15,pad=16)
    for s in ax.spines.values():s.set_color('#abc0cc')
    fig.tight_layout();fig.savefig(path,dpi=200,facecolor=fig.get_facecolor());plt.close(fig)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('design',type=Path);p.add_argument('routing',type=Path);p.add_argument('output',type=Path)
    a=p.parse_args();render(json.loads(a.design.read_text()),json.loads(a.routing.read_text()),a.output)
