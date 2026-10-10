"""Native Altium ASCII export of the verified R3 copper and component bodies.

The source schematic UIDs, footprint pads and library references remain intact.
Legacy placement-draft annotations are deliberately replaced by R3 geometry.
"""
from pathlib import Path
from collections import Counter
import tempfile
from altium_pcb import build_pcb, record, base, mil, footprint, transform
from altium_3d import pcb_3d_records
from build_altium_project import uid


def fields(line):
    return dict(p.split('=',1) for p in line.split('|') if '=' in p)


def contour_record(kind, points, **kwargs):
    points=list(points)
    if points[-1]==points[0]:points=points[:-1]
    args=dict(kwargs,ISSHAPEBASED=True,KIND=0,SUBPOLYINDEX=-1,
              MAINCONTOURVERTEXCOUNT=len(points),HOLECOUNT=0,ARCRESOLUTION='0.5mil')
    for i,(x,y) in enumerate(points):
        args.update({f'KIND{i}':0,f'VX{i}':mil(x),f'VY{i}':mil(y),f'CX{i}':'0mil',
                     f'CY{i}':'0mil',f'SA{i}':0,f'EA{i}':0,f'R{i}':'0mil'})
    return record(kind,**args)


def build_routed_pcb(data,path,routing):
    path=Path(path)
    with tempfile.TemporaryDirectory() as tmp:
        initial=Path(tmp)/path.name
        summary=build_pcb(data,initial)
        original=[fields(r) for r in initial.read_text('cp1252').splitlines()]
    rows=[]
    components=data['components']
    w,h=data['board']['width_mm'],data['board']['height_mm']
    net_ids={r['NAME']:int(r['ID']) for r in original if r['RECORD']=='Net'}
    for r in original:
        kind=r.pop('RECORD')
        # Recreate all standalone graphics, text, mounting holes and rules.
        if kind in ('Track','Text','Pad') and 'COMPONENT' not in r:continue
        if kind=='Rule':continue
        if kind=='Text':
            c=components[int(r['COMPONENT'])]
            if r.get('DESIGNATOR')=='TRUE':
                # Assembly references are kept on the assembly layer, centered
                # over each body. This avoids crowded/illegible silkscreen.
                r.update(LAYER='MECHANICAL13',X=mil(c['pcb']['x']-.65),
                         Y=mil(c['pcb']['y']-.3),HEIGHT=mil(.8),WIDTH=mil(.12))
            elif r.get('COMMENT')=='TRUE':
                # Altium stores the component value in this primitive even
                # when COMMENTON is false. Removing it breaks ECO parity.
                r.update(LAYER='MECHANICAL13',X=mil(c['pcb']['x']),
                         Y=mil(c['pcb']['y']),HEIGHT=mil(.6),WIDTH=mil(.1))
        rows.append(record(kind,**r))
    for i,(x,y) in enumerate(data['board']['holes_mm']):
        d=data['board']['hole_diameter_mm']
        rows.append(record('Pad',**base('MULTILAYER'),INDEXFORSAVE=89+i,NAME='',X=mil(x),Y=mil(y),
                           XSIZE=mil(d),YSIZE=mil(d),SHAPE='ROUND',HOLESIZE=mil(d),ROTATION=0,PLATED=False,
                           SOLDERMASKEXPANSIONMODE='Manual',SOLDERMASKEXPANSION_MANUAL=mil(.1),
                           PASTEMASKEXPANSIONMODE='None',PADMODE=0,DRILLTYPE=0,HOLETYPE=0))
    for t in routing['tracks']:
        rows.append(record('Track',**base(t['layer']),NET=net_ids[t['net']],
                           X1=mil(t['x1']),Y1=mil(t['y1']),X2=mil(t['x2']),Y2=mil(t['y2']),
                           WIDTH=mil(t['width']),SUBPOLYINDEX=0,
                           SOLDERMASKEXPANSIONMODE='None',PASTEMASKEXPANSIONMODE='None'))
    for v in routing['vias']:
        rows.append(record('Via',**base('MULTILAYER'),NET=net_ids[v['net']],X=mil(v['x']),Y=mil(v['y']),
                           DIAMETER=mil(v['diameter']),HOLESIZE=mil(v['drill']),
                           STARTLAYER='TOP',ENDLAYER='BOTTOM',PLATED=True,
                           SOLDERMASKEXPANSIONMODE='Manual',SOLDERMASKEXPANSION_MANUAL=mil(-.3),
                           CSEV=2,CSE=mil(-.3),
                           TENTING=True,TENTINGTOP=True,TENTINGBOTTOM=True))
    for region in routing.get('regions',[]):
        if region.get('holes'):raise ValueError('Export expects hole-free region decomposition')
        rows.append(contour_record('Region',region.get('points',region.get('exterior')),
                                   **base(region['layer']),NET=net_ids[region['net']],
                                   NAME='',KEEPOUT=False))
    # Physical outline and actual isolation/RF limits are visible on mech layers.
    def line(a,b,layer,width=.1):
        rows.append(record('Track',**base(layer),X1=mil(a[0]),Y1=mil(a[1]),X2=mil(b[0]),Y2=mil(b[1]),WIDTH=mil(width)))
    def rectangle(x1,y1,x2,y2,layer):
        p=[(x1,y1),(x2,y1),(x2,y2),(x1,y2)]
        for a,b in zip(p,p[1:]+p[:1]):line(a,b,layer)
    rectangle(0,0,w,h,'MECHANICAL1')
    for k in data['routing_constraints']['keepouts']:
        rectangle(k['x1'],k['y1'],k['x2'],k['y2'],'MECHANICAL2')
        # The native clearance rule adds the final .2 mm. Inset the keepout so
        # manufacturer lands exactly tangent to the physical barrier remain legal.
        g=data['routing_constraints']['clearance']
        pts=[(k['x1']+g,k['y1']+g),(k['x2']-g,k['y1']+g),
             (k['x2']-g,k['y2']-g),(k['x1']+g,k['y2']-g)]
        rows.append(contour_record('Region',pts,**base('KEEPOUT'),KEEPOUT=True,NAME=k['name']))
    def text(x,y,caption,layer='MECHANICAL3',height=.9):
        rows.append(record('Text',**base(layer),X=mil(x),Y=mil(y),HEIGHT=mil(height),WIDTH=mil(.12),
                           FONT='DEFAULT',TEXT=caption,ROTATION=0,MIRROR=False,USETTFONTS=False))
    text(1,-2,'ORION BRIDGE R3 / 54 x 36 mm / 2 layers, FR4 1.6 mm, copper 35 um')
    text(1,-4,'GND_BUS / GND_LOGIC isolated, 3.8 mm minimum; antenna zone copper free.')
    text(1,-6,'Open JP1 BEFORE USB. Prototype: thermal and actual module qualification pending.')
    # Sparse functional silkscreen, placed in the free lower board strip.
    text(18,.8,'ORION R3','TOPOVERLAY',.85)
    text(42,.8,'JP1: USB OPEN','TOPOVERLAY',.65)
    for i,(kind,extra) in enumerate([
        ('Clearance',{'NETSCOPE':'DifferentNets','GAP':mil(data['routing_constraints']['clearance'])}),
        ('Width',{'MINLIMIT':mil(.25),'MAXLIMIT':mil(2),'PREFEREDWIDTH':mil(.3)}),
        ('ShortCircuit',{'ALLOWED':False}),('UnRoutedNet',{}),
        ('SolderMaskExpansion',{'NAME':'TentedVias','SCOPE1EXPRESSION':'IsVia',
                               'EXPANSION':mil(-.3),'ISTENTINGTOP':True,'ISTENTINGBOTTOM':True}),
        ('SolderMaskExpansion',{'NAME':'PadSolderMask','PRIORITY':2,'EXPANSION':mil(.075)}),
        ('MinimumSolderMaskSliver',{'MINSOLDERMASKWIDTH':mil(.1)}),
        ('RoutingVias',{'HOLEWIDTH':mil(.3),'WIDTH':mil(.6),'VIASTYLE':'Through Hole',
                        'MINHOLEWIDTH':mil(.3),'MAXHOLEWIDTH':mil(.3),
                        'MINWIDTH':mil(.6),'MAXWIDTH':mil(.6)}),
        ('ComponentClearance',{'GAP':mil(.25),'COLLISIONCHECKMODE':3,'VERTICALGAP':mil(.25),'SHOWDISTANCES':False}),
    ]):
        args=dict(INDEXFORSAVE=i,RULEKIND=kind,NETSCOPE='AnyNet',LAYERKIND='SameLayer',
                  SCOPE1COUNT=1,SCOPE1_0_KIND='Board',SCOPE1_0_VALUE='Board',
                  SCOPE2COUNT=1,SCOPE2_0_KIND='Board',SCOPE2_0_VALUE='Board',
                  NAME=kind,ENABLED=True,COMMENTLENGTH=0,COMMENT='')
        args.update(extra)
        # Modern Altium uses the DXP rule stream. A legacy Rule alone causes
        # the loader to substitute default 10 mil constraints silently.
        dxp={k:v for k,v in args.items() if not k.startswith('SCOPE') and k!='COMMENTLENGTH'}
        dxp.update(SCOPE1EXPRESSION='All',SCOPE2EXPRESSION='All',PRIORITY=1,
                   UNIQUEID=uid('R3-rule-'+args['NAME']),DEFINEDBYLOGICALDOCUMENT=False)
        for key in ('SCOPE1EXPRESSION','PRIORITY'):
            if key in extra:dxp[key]=extra[key]
        if kind=='Clearance':dxp['GENERICCLEARANCE']=extra['GAP']
        rows.append(record('DXPRule',**base(),**dxp))
        rows.append(record('Rule',**base(),**args))
    rows.extend(pcb_3d_records(data))
    # Renumber each primitive class after filtering/rebuilding legacy records.
    count=Counter();renumbered=[]
    for row in rows:
        r=fields(row);kind=r.pop('RECORD')
        if kind not in ('Board','Rule','DXPRule'):
            r['INDEXFORSAVE']=count[kind];count[kind]+=1
        renumbered.append(record(kind,**r))
    path.write_bytes(('\r\n'.join(renumbered)+'\r\n').encode('cp1252'))
    summary.update(path=str(path),copper_tracks=len(routing['tracks']),vias=len(routing['vias']),
                   regions=len(routing.get('regions',[])),bodies_3d=count['ComponentBody'],
                   pads=count['Pad'],primitive_counts=dict(count))
    return summary
