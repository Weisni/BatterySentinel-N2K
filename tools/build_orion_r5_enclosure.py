"""Parametric R5 enclosure scaffold; run with FreeCAD 1.1 bundled Python.

The provisional mechanical contract is reviewable before the carrier is frozen.
--check builds and verifies OCCT solids, writes a JSON review and preview FCStd.
--export also writes print-oriented STL and assembly STEP, but requires an
explicitly frozen contract with matched final PCB geometry and USB placement.
No environmental/IP rating is implied by a printed housing.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'hardware/altium-r5/enclosure'
CONTRACT=OUT/'mechanical-contract.json'
FREECAD=Path('C:/Program Files/FreeCAD 1.1')
if FREECAD.exists():
    sys.path.insert(0,str(FREECAD/'lib'))
    _dll=os.add_dll_directory(str(FREECAD/'bin'))


def default_contract():
    return {
        'revision':'R5 mechanical proposal v1','frozen':False,
        'pending':['Selected SuperMini dimensional assumptions retained until physical fit check',
                   'Carrier outline, hole coordinates and component volumes frozen',
                   'Actual USB connector mouth position/height verified',
                   'Protected dry installation assumed; no environmental protection claim',
                   'Actual cable outer diameter measured; clamp coupon pull test',
                   'Insert-fit coupon on selected printer/material'],
        'units':'mm','coordinate_system':'PCB lower-left XY; carrier underside becomes Z=6.5 in assembled enclosure',
        'board':{'width':50.0,'height':36.0,'radius':2.0,'thickness':1.6,
                 'holes':[[3,3],[3,33],[47,3],[47,33]],'hole_diameter':2.2,
                 'screw_courtyard_diameter':5.6,'source_design':None,'source_sha256':None},
        'case':{'pcb_side_clearance':.6,'wall':2.0,'floor':2.0,'lid':2.0,
                'standoff_height':4.5,'above_pcb_clearance':12.0,'lid_fit_clearance':.25,
                'lid_lip_depth':.6,'lid_lip_wall':1.2,'seam_gap':.15,'corner_radius':4.6,
                'material':'PETG or ASA, selected for the actual service temperature',
                'base_rgb':[42,65,74],'lid_rgb':[57,91,103]},
        'fasteners':{'method':'Four shared M2 lid screws pass through clearance spacers and PCB holes into base heat-set inserts',
                      'thread':'M2','screw_length':18.0,'screw_clearance':2.4,'head_diameter':4.2,'head_recess':1.0,
                      'insert':'ruthex RX-M2x4','insert_length_nominal':4.0,'insert_pilot_diameter':3.2,
                      'insert_depth':4.25,'insert_boss_diameter':6.4,'lid_spacer_diameter':5.2,
                      'pcb_axial_clearance':.15,'insert_fit_provisional':True,
                      'insert_source':'https://www.ruthex.de/en/products/ruthex-gewindeeinsatz-m2-70-stuck-rx-m2x4-messing-gewindebuchsen',
                      'insert_step_source':'https://cdn.shopify.com/s/files/1/0567/7019/9760/files/ruthex_RX-M2x4.step?v=1621264078',
                      'pilot_note':'3.2 mm pilot is a provisional printing starting point; validate a coupon against actual insert and material.'},
        'mounting':{'enabled':True,'side':'Y','hole_diameter':3.4,'slot_extra_length':2.0,
                    'ear_width':12.0,'ear_projection':7.0,'ear_thickness':3.0,'root_overlap':2.0,
                    'description':'Two integral exterior mounting ears, M3 clearance slots; fixing screws selected for substrate'},
        'usb':{'confirmed':False,'side':'Y+','center_along_edge':37.0,'center_above_pcb':5.5,
               'opening_width':12.0,'opening_height':7.0,'corner_radius':1.5,
               'note':'Provisional plug-overmould clearance, not a verified SuperMini connector position'},
        'service_switch':{'enabled':True,'confirmed':False,'side':'Y+','center_along_edge':16.0,
                          'center_above_pcb':2.0,'opening_width':6.5,'opening_height':3.5,'corner_radius':.75,
                          'note':'RUN/SERVICE power-disconnect actuator aperture; exact switch/placement pending'},
        'cable':{'mode':'captured_clamp','side':'X-','center_along_edge':18.0,'center_above_pcb':5.0,
                 'diameter':6.0,'supported_diameter_range':[5.0,7.0],'entry_clearance':.4,
                 'jacket_compression_diameter':.2,'clamp_length':7.0,'clamp_wall':2.0,
                 'gland_panel_hole_diameter':12.2,'gland_confirmed':False,
                 'note':'Default dry-case jacket clamp captured by the removable lid. No sealing or pull-force claim; choose cable OD and validate. Optional gland mode requires an exact selected gland.'},
        'branding':{'geometry_json':'assets/branding/battery-sentinel.paths.json','center':[25.0,24.0],'width':12.215,'height':15.802368,
                    'depth':.5,'operation':'deboss','rotation':0,
                    'texts':[{'text':'BatterySentinel-N2K','height':4.6,'center':[25.0,11.0],'letter_spacing_mm':.38,'print_outline_offset_mm':.04,'dot_lift_mm':.23},
                             {'text':'Orion-R5','height':4.6,'center':[25.0,4.9],'letter_spacing_mm':.38,'print_outline_offset_mm':.04,'dot_lift_mm':.23}],
                    'note':'Same outline polygons as smooth PCB logo/TTF; no substitute artwork generated'},
        'electronics':{'maximum_height_above_pcb':10.4,'minimum_lid_clearance':1.0,'minimum_component_to_case_mm':.5,
                       'maximum_tail_below_pcb':2.5,'minimum_floor_clearance':1.0,
                       'reserved_mount_cylinders':'Four diameter5.6 cylinders at PCB holes, full component height',
                       'antenna_clearance':'Use exact module antenna keepout; no metal inserts or screws inside that region'},
        'printing':{'nozzle':.4,'layer_height':.2,'perimeters':5,'infill_percent':30,
                     'base_orientation':'outside bottom on bed','lid_orientation':'outside face on bed; spacers point upward',
                     'fit_note':'Dimensions are starting tolerances, not printer calibration. Check sleeve, insert and cable coupons before full print.',
                     'reference':'https://help.prusa3d.com/article/modeling-with-3d-printing-in-mind_164135'},
        'environmental_claim':'No tested IP rating; USB opening, split jacket clamp, lid seam and FDM porosity remain unsealed.'}


def dimensions(c):
    b,k=c['board'],c['case'];margin=k['pcb_side_clearance']+k['wall']
    bottom=k['floor']+k['standoff_height'];top=bottom+b['thickness']
    seam=top+k['above_pcb_clearance']
    return dict(xmin=-margin,ymin=-margin,width=b['width']+2*margin,height=b['height']+2*margin,
                pcb_bottom=bottom,pcb_top=top,seam_z=seam,outer_height=seam+k['lid']+k['seam_gap'])


def sync_design(c,path):
    """Adopt reviewed physical placement without silently freezing a release.

    Mechanical interface points are component-local, with Z relative to carrier
    TOP. Confirmed means linked to the selected final layout; vendor versus
    assumed dimensions remain explicit in the stored interface provenance.
    """
    path=Path(path).resolve();data=json.loads(path.read_text('utf8'));board=data['board']
    old_width=c['board']['width'];new_width=board['width_mm']
    c['frozen']=False
    c['board'].update(width=new_width,height=board['height_mm'],radius=board.get('corner_radius_mm',0),
                      thickness=board.get('thickness_mm',1.6),holes=board.get('holes_mm',[]),
                      hole_diameter=board.get('hole_diameter_mm',2.2),source_design=str(path),
                      source_sha256=hashlib.sha256(path.read_bytes()).hexdigest())
    c['board']['cutouts_mm']=board.get('cutouts_mm',[])
    c['board']['outline_points_mm']=board.get('outline_points_mm',[])
    c['branding']['center'][0]+=(new_width-old_width)/2
    for t in c['branding'].get('texts',[]):t['center'][0]+=(new_width-old_width)/2
    for component in data['components']:
        for kind,spec in component.get('mechanical_interfaces',{}).items():
            if kind not in ('usb','service_switch'):continue
            x,y,z=spec['mouth_center_local_mm'];a=math.radians(component['pcb'].get('rotation',0))
            wx=component['pcb']['x']+x*math.cos(a)-y*math.sin(a)
            wy=component['pcb']['y']+x*math.sin(a)+y*math.cos(a)
            dx,dy=spec['outward_local_xy'];dx,dy=dx*math.cos(a)-dy*math.sin(a),dx*math.sin(a)+dy*math.cos(a)
            if max(abs(dx),abs(dy))<.999:raise ValueError('Service interface must face an orthogonal enclosure wall')
            side=('X+' if dx>0 else 'X-') if abs(dx)>abs(dy) else ('Y+' if dy>0 else 'Y-')
            entry=c.setdefault(kind,{})
            entry.update(enabled=True,confirmed=True,side=side,center_along_edge=wy if side[0]=='X' else wx,
                         center_above_pcb=z,opening_width=spec['opening_width_mm'],opening_height=spec['opening_height_mm'],
                         source_component=component['ref'],mouth_center_board_mm=[wx,wy,z],provenance=spec,
                         note='Linked to selected module and final PCB placement; tolerance assumptions remain explicit in provenance.')
    return c


def component_solids(c,d):
    """The exact local body model used by the PCB, transformed into the case."""
    source=c['board'].get('source_design')
    if not source:return []
    path=Path(source)
    if not path.is_file():raise ValueError('Configured PCB model does not exist')
    if hashlib.sha256(path.read_bytes()).hexdigest()!=c['board']['source_sha256']:
        raise ValueError('PCB geometry changed; sync the mechanical contract before generating previews or exports')
    import FreeCAD as App
    import Part
    from altium_3d import bodies_for
    parts=[]
    for component in json.loads(path.read_text('utf8'))['components']:
        for body in bodies_for(component):
            points=[App.Vector(x,y,body.z0) for x,y in body.outline]
            solid=Part.Face(Part.makePolygon(points+[points[0]])).extrude(App.Vector(0,0,body.z1-body.z0))
            solid.rotate(App.Vector(0,0,0),App.Vector(0,0,1),component['pcb'].get('rotation',0))
            solid.translate(App.Vector(component['pcb']['x'],component['pcb']['y'],d['pcb_top']))
            parts.append(dict(ref=component['ref'],name=body.name,solid=solid,rgb=body.rgb))
    return parts


def enclosure_text_geometry(item):
    """Same rounded font, with explicit FDM spacing/outline allowances only.

    Do not use these mechanical allowances for the native PCB typography.
    Letter proportions are preserved; no horizontal condensing is applied.
    """
    from r5_branding import text_geometry,load_font,FONT_PATH,polygons
    from shapely import affinity
    from shapely.ops import unary_union
    font=load_font(str(FONT_PATH));cmap=font.getBestCmap();scale=item['height']/font['head'].unitsPerEm
    cursor=0;parts=[]
    for char in item['text']:
        glyph=text_geometry(dict(text=char,height=item['height'],font_geometry='fonttools',height_units=font['head'].unitsPerEm))
        if char in 'ij' and item.get('dot_lift_mm',0):
            pieces=polygons(glyph);dot=max(pieces,key=lambda g:g.bounds[1]);pieces.remove(dot)
            glyph=unary_union(pieces+[affinity.translate(dot,yoff=item['dot_lift_mm'])])
        parts.append(affinity.translate(glyph,xoff=cursor))
        cursor+=font['hmtx'].metrics[cmap[ord(char)]][0]*scale+item.get('letter_spacing_mm',0)
    g=unary_union(parts)
    if item.get('print_outline_offset_mm',0):g=g.buffer(item['print_outline_offset_mm'],quad_segs=16)
    bounds=g.bounds
    return affinity.translate(g,item['center'][0]-(bounds[0]+bounds[2])/2,item['center'][1]-(bounds[1]+bounds[3])/2)


def build(c):
    import FreeCAD as App
    import Part
    V=App.Vector;b,k,f=c['board'],c['case'],c['fasteners'];d=dimensions(c)
    def rounded(x,y,w,h,r,z,t):
        if r<=0:return Part.makeBox(w,h,t,V(x,y,z))
        r=min(r,w/2,h/2)
        pieces=[]
        if w>2*r+1e-7:pieces.append(Part.makeBox(w-2*r,h,t,V(x+r,y,z)))
        if h>2*r+1e-7:pieces.append(Part.makeBox(w,h-2*r,t,V(x,y+r,z)))
        for cx,cy in [(x+r,y+r),(x+w-r,y+r),(x+w-r,y+h-r),(x+r,y+h-r)]:pieces.append(Part.makeCylinder(r,t,V(cx,cy,z)))
        s=pieces[0]
        for piece in pieces[1:]:s=s.fuse(piece)
        return s.removeSplitter()
    def cylinder(x,y,r,z,t):return Part.makeCylinder(r,t,V(x,y,z))
    def wall_cut(side,center,z,width,height,radius):
        # Rounded rectangle in local XY, extruded through the selected wall.
        shape=rounded(-width/2,-height/2,width,height,radius,0,k['wall']+4)
        if side.startswith('Y'):
            shape.rotate(V(0,0,0),V(1,0,0),90)
            shape.translate(V(center,d['ymin']+2 if side=='Y-' else d['ymin']+d['height']+2,z))
        else:
            shape.rotate(V(0,0,0),V(1,0,0),90);shape.rotate(V(0,0,0),V(0,0,1),90)
            shape.translate(V(d['xmin']-2 if side=='X-' else d['xmin']+d['width']-2,center,z))
        return shape
    inner=dict(x=-k['pcb_side_clearance'],y=-k['pcb_side_clearance'],w=b['width']+2*k['pcb_side_clearance'],h=b['height']+2*k['pcb_side_clearance'],r=b['radius']+k['pcb_side_clearance'])
    base=rounded(d['xmin'],d['ymin'],d['width'],d['height'],k['corner_radius'],0,d['seam_z'])
    base=base.cut(rounded(inner['x'],inner['y'],inner['w'],inner['h'],inner['r'],k['floor'],d['seam_z']))
    lid=rounded(d['xmin'],d['ymin'],d['width'],d['height'],k['corner_radius'],d['seam_z']+k['seam_gap'],k['lid'])
    fit=k['lid_fit_clearance'];lip=k['lid_lip_wall'];lz=d['seam_z']-k['lid_lip_depth']
    outer=rounded(inner['x']+fit,inner['y']+fit,inner['w']-2*fit,inner['h']-2*fit,max(.1,inner['r']-fit),lz,k['lid_lip_depth']+k['seam_gap']+.01)
    hole=rounded(inner['x']+fit+lip,inner['y']+fit+lip,inner['w']-2*(fit+lip),inner['h']-2*(fit+lip),max(.1,inner['r']-fit-lip),lz-.1,k['lid_lip_depth']+k['seam_gap']+.3)
    lid=lid.fuse(outer.cut(hole))
    for x,y in b['holes']:
        boss=cylinder(x,y,f['insert_boss_diameter']/2,k['floor']-.01,k['standoff_height']+.01)
        pilot=cylinder(x,y,f['insert_pilot_diameter']/2,d['pcb_bottom']-f['insert_depth'],f['insert_depth']+.1)
        base=base.fuse(boss).cut(pilot)
        spacer_z=d['pcb_top']+f['pcb_axial_clearance']
        spacer=cylinder(x,y,f['lid_spacer_diameter']/2,spacer_z,d['seam_z']+k['seam_gap']-spacer_z+.02)
        lid=lid.fuse(spacer).cut(cylinder(x,y,f['screw_clearance']/2,spacer_z-.1,d['outer_height']-spacer_z+.2))
        lid=lid.cut(cylinder(x,y,f['head_diameter']/2,d['outer_height']-f['head_recess'],f['head_recess']+.1))
    mounting=c['mounting'];mount_centers=[]
    if mounting['enabled']:
        for sign in (-1,1):
            edge=d['ymin'] if sign<0 else d['ymin']+d['height'];depth=mounting['ear_projection']+mounting['root_overlap']
            y=edge-mounting['ear_projection'] if sign<0 else edge-mounting['root_overlap'];x=b['width']/2-mounting['ear_width']/2
            ear=rounded(x,y,mounting['ear_width'],depth,3,0,mounting['ear_thickness'])
            cy=edge+sign*mounting['ear_projection']/2;cx=b['width']/2;mount_centers.append([cx,cy])
            slot=rounded(cx-mounting['hole_diameter']/2,cy-(mounting['hole_diameter']+mounting['slot_extra_length'])/2,mounting['hole_diameter'],mounting['hole_diameter']+mounting['slot_extra_length'],mounting['hole_diameter']/2, -.1,mounting['ear_thickness']+.2)
            base=base.fuse(ear).cut(slot)
    usb=c['usb'];cut=wall_cut(usb['side'],usb['center_along_edge'],d['pcb_top']+usb['center_above_pcb'],usb['opening_width'],usb['opening_height'],usb['corner_radius'])
    base=base.cut(cut);lid=lid.cut(cut)
    switch=c.get('service_switch',{})
    if switch.get('enabled'):
        cut=wall_cut(switch['side'],switch['center_along_edge'],d['pcb_top']+switch['center_above_pcb'],switch['opening_width'],switch['opening_height'],switch['corner_radius'])
        base=base.cut(cut);lid=lid.cut(cut)
    cable=c['cable'];clamp_info={}
    if cable['side']!='X-':raise ValueError('Current cable scaffold supports left/X- entry; freeze can select another side after integration')
    cy=cable['center_along_edge'];cz=d['pcb_top']+cable['center_above_pcb']
    if cable['mode']=='captured_clamp':
        length=cable['clamp_length'];cw=cable['diameter']+2*cable['clamp_wall'];cx=d['xmin']-length
        block=rounded(cx,cy-cw/2,length+k['wall'],cw,1.5,k['floor'],d['seam_z']-k['floor'])
        base=base.fuse(block)
        # Open-top cable saddle permits assembly without threading electronics.
        r=(cable['diameter']+cable['entry_clearance'])/2
        bore=Part.makeCylinder(r,length+k['wall']+2,V(cx-1,cy,cz),V(1,0,0))
        slot=Part.makeBox(length+k['wall']+2,2*r,d['seam_z']-cz+1,V(cx-1,cy-r,cz))
        base=base.cut(bore.fuse(slot))
        # Lid tongue is captured by the saddle, and two shallow rounded ribs
        # compress the jacket. The actual cable fit remains a printed-coupon test.
        tongue=Part.makeBox(length+k['wall']-.5,2*r-.5,d['seam_z']+k['seam_gap']-cz+.05,V(cx+.25,cy-r+.25,cz))
        tongue=tongue.cut(bore)
        cap=rounded(cx,cy-cw/2,length+k['wall'],cw,1.5,d['seam_z']+k['seam_gap'],k['lid'])
        lid=lid.fuse(cap).fuse(tongue)
        cr=(cable['diameter']-cable['jacket_compression_diameter'])/2
        for rx in (cx+1.5,cx+length-1.5):
            ring=Part.makeCylinder(r,.6,V(rx,cy,cz),V(1,0,0)).cut(Part.makeCylinder(cr,.8,V(rx-.1,cy,cz),V(1,0,0)))
            lower=ring.common(Part.makeBox(length+4,cw,cz-k['floor'],V(cx-1,cy-cw/2,k['floor'])))
            upper=ring.common(Part.makeBox(length+4,cw,d['seam_z']-cz,V(cx-1,cy-cw/2,cz)))
            base=base.fuse(lower);lid=lid.fuse(upper)
        clamp_info=dict(cable_center=[cx,cy,cz],nominal_diameter=cable['diameter'],minimum_clamp_bore=2*cr)
    elif cable['mode']=='gland':
        cut=Part.makeCylinder(cable['gland_panel_hole_diameter']/2,k['wall']+4,V(d['xmin']-2,cy,cz),V(1,0,0));base=base.cut(cut);lid=lid.cut(cut)
    else:raise ValueError('Unknown cable entry mode')
    branding=c['branding']
    if branding.get('geometry_json'):
        asset=json.loads(Path(branding['geometry_json']).read_text('utf8'));bounds=asset['bounds'];aw,ah=bounds[2]-bounds[0],bounds[3]-bounds[1]
        scale=min(branding['width']/aw,branding['height']/ah);angle=math.radians(branding['rotation'])
        def xy(p):
            x=(p[0]-(bounds[0]+bounds[2])/2)*scale;y=(p[1]-(bounds[1]+bounds[3])/2)*scale
            return (branding['center'][0]+x*math.cos(angle)-y*math.sin(angle),branding['center'][1]+x*math.sin(angle)+y*math.cos(angle))
        artwork=[]
        for item in asset['shapes']:
            artwork.append(dict(points=[xy(p) for p in item['points']],holes=[[xy(p) for p in h] for h in item.get('holes',[])]))
        from r5_branding import region_data
        for text in branding.get('texts',[]):
            artwork.extend(region_data(enclosure_text_geometry(text)))
        for item in artwork:
            pts=[V(*p,0) for p in item['points']];shape=Part.Face(Part.makePolygon(pts+[pts[0]]))
            for h in item.get('holes',[]):
                hp=[V(*p,0) for p in h];shape=shape.cut(Part.Face(Part.makePolygon(hp+[hp[0]])))
            solid=shape.extrude(V(0,0,branding['depth']+.01));solid.translate(V(0,0,d['outer_height']-branding['depth'] if branding['operation']=='deboss' else d['outer_height']-.01))
            lid=lid.cut(solid) if branding['operation']=='deboss' else lid.fuse(solid)
    base=base.removeSplitter();lid=lid.removeSplitter()
    def pcb_profile(points):
        vertices=[V(x,y,d['pcb_bottom']) for x,y in points]
        if (vertices[-1]-vertices[0]).Length>1e-9:vertices.append(vertices[0])
        return Part.Face(Part.makePolygon(vertices)).extrude(V(0,0,b['thickness']))
    pcb=pcb_profile(b['outline_points_mm']) if b.get('outline_points_mm') else rounded(0,0,b['width'],b['height'],b['radius'],d['pcb_bottom'],b['thickness'])
    for cut in b.get('cutouts_mm',[]):pcb=pcb.cut(pcb_profile(cut['outline_points_mm']))
    for x,y in b['holes']:pcb=pcb.cut(cylinder(x,y,b['hole_diameter']/2,d['pcb_bottom']-.1,b['thickness']+.2))
    return dict(base=base,lid=lid,pcb=pcb),dict(**d,mount_centers=mount_centers,clamp=clamp_info)


def validate(c,shapes,d):
    b,k,f,e=c['board'],c['case'],c['fasteners'],c['electronics'];errors=[]
    def check(ok,msg):
        if not ok:errors.append(msg)
    for name,s in shapes.items():check(s.isValid() and len(s.Solids)==1 and s.Volume>0,name+' must be one valid closed solid')
    for a,bn in [('base','lid'),('base','pcb'),('lid','pcb')]:check(shapes[a].common(shapes[bn]).Volume<1e-6,a+'/'+bn+' collision')
    check(k['standoff_height']-e['maximum_tail_below_pcb']>=e['minimum_floor_clearance'],'PTH tail to floor clearance')
    check(k['above_pcb_clearance']-e['maximum_height_above_pcb']>=e['minimum_lid_clearance'],'Electronics to lid clearance')
    check(k['floor']+k['standoff_height']-f['insert_depth']>=1.5,'Insert pilot leaves sufficient blind floor')
    screw_tip=d['outer_height']-f['head_recess']-f['screw_length'];engagement=d['pcb_bottom']-max(screw_tip,d['pcb_bottom']-f['insert_length_nominal'])
    check(engagement>=2.0 and screw_tip>=d['pcb_bottom']-f['insert_depth']+.2,'M2 screw engagement/tip clearance')
    component_clearance=None;closest_pair=None;components=component_solids(c,d)
    if components:
        component_clearance=math.inf
        for part in components:
            for name in ('base','lid'):
                check(part['solid'].common(shapes[name]).Volume<1e-5,part['ref']+' / '+part['name']+' intersects '+name)
                gap=part['solid'].distToShape(shapes[name])[0]
                check(gap+1e-6>=e.get('minimum_component_to_case_mm',.5),part['ref']+' / '+part['name']+' has insufficient clearance to '+name)
                if gap<component_clearance:
                    component_clearance=gap;closest_pair=dict(component=part['ref'],body=part['name'],case_part=name)
    return dict(passed=not errors,errors=errors,dimensions=d,screw_engagement=engagement,minimum_component_case_clearance=component_clearance,closest_component_case_pair=closest_pair,
                component_body_count=len(components),solid_volumes_mm3={n:s.Volume for n,s in shapes.items()},status='frozen' if c['frozen'] else 'PROVISIONAL - final PCB placement and service geometry not frozen',
                limitations=c['pending'] if not c['frozen'] else [],environmental_claim=c['environmental_claim'])


def render_preview(c,shapes,d,out):
    import FreeCAD as App
    import vtk
    from render_altium_r3 import mesh_actor
    components=component_solids(c,d)
    for view in ('closed','exploded','ports'):
        exploded=view=='exploded'
        renderer=vtk.vtkRenderer();renderer.SetBackground(.94,.96,.97);renderer.SetUseFXAA(True)
        # Real geometric occlusion reveals the blind grooves without adding
        # painted lettering or changing the physical engraving geometry.
        renderer.SetUseSSAO(True);renderer.SetSSAORadius(2.0);renderer.SetSSAOBias(.02);renderer.SetSSAOKernelSize(128);renderer.SetSSAOBlur(True)
        renderer.AutomaticLightCreationOff()
        for pos,power,col in [((-30,-50,100),1.05,(1,.97,.92)),((90,10,75),.65,(.87,.93,1)),((20,90,45),.5,(1,1,1))]:
            light=vtk.vtkLight();light.SetLightTypeToSceneLight();light.SetPosition(*pos);light.SetFocalPoint(25,18,10);light.SetIntensity(power);light.SetColor(*col);renderer.AddLight(light)
        for name in ('base','pcb','lid'):
            if name=='pcb' and not exploded:continue
            s=shapes[name].copy()
            if exploded and name=='lid':s.translate(App.Vector(0,0,15))
            rgb=c['case'][name+'_rgb'] if name!='pcb' else [26,110,74]
            renderer.AddActor(mesh_actor(s,rgb))
        if exploded:
            for part in components:renderer.AddActor(mesh_actor(part['solid'],part['rgb']))
        caption='PROVISIONAL R5 / enclosure geometry'
        if exploded:caption+='\nActual PCB component body model' if components else '\nEmpty planning PCB - final layout and module height pending'
        if view=='ports':caption+='\nUSB and RUN/SERVICE apertures - final positions pending'
        label=vtk.vtkTextActor();label.SetInput(caption if not c['frozen'] else 'ORION BRIDGE R5')
        label.GetTextProperty().SetFontSize(22);label.GetTextProperty().SetColor(.12,.2,.24);label.SetPosition(26,26);renderer.AddActor2D(label)
        window=vtk.vtkRenderWindow();window.SetOffScreenRendering(1);window.SetSize(1400,1050);window.AddRenderer(renderer)
        cam=renderer.GetActiveCamera();cam.ParallelProjectionOn();cam.SetFocalPoint(c['board']['width']/2,c['board']['height']/2,15 if exploded else 10)
        cam.SetPosition(*((-50,100,64) if view=='ports' else (-50,-65,92 if exploded else 80)));cam.SetViewUp(0,0,1);cam.SetParallelScale(48 if exploded else 40);renderer.ResetCameraClippingRange();window.Render()
        capture=vtk.vtkWindowToImageFilter();capture.SetInput(window);capture.ReadFrontBufferOff();capture.Update()
        writer=vtk.vtkPNGWriter();writer.SetFileName(str(out/f'enclosure-{view}.png'));writer.SetInputConnection(capture.GetOutputPort());writer.Write();window.Finalize()


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--contract',type=Path,default=CONTRACT);p.add_argument('--out',type=Path,default=OUT)
    p.add_argument('--init',action='store_true');p.add_argument('--check',action='store_true');p.add_argument('--export',action='store_true');p.add_argument('--sync-design',type=Path);args=p.parse_args();args.out.mkdir(parents=True,exist_ok=True)
    if args.init:
        if args.contract.exists():raise ValueError('Contract already exists; edit the reviewable JSON explicitly')
        args.contract.write_text(json.dumps(default_contract(),indent=2)+'\n',encoding='utf8');print(args.contract);return
    c=json.loads(args.contract.read_text('utf8'))
    if args.sync_design:
        c=sync_design(c,args.sync_design);args.contract.write_text(json.dumps(c,indent=2)+'\n',encoding='utf8')
        if not args.check and not args.export:print('Mechanical interfaces synchronized; release remains unfrozen');return
    if args.export:
        if not c['frozen'] or not c['usb']['confirmed'] or not c['board']['source_design']:raise ValueError('Final STL/STEP export requires frozen PCB/module/USB contract')
        if c.get('service_switch',{}).get('enabled') and not c['service_switch'].get('confirmed'):raise ValueError('Service switch geometry is not frozen')
        path=Path(c['board']['source_design']);data=json.loads(path.read_text('utf8'))
        if hashlib.sha256(path.read_bytes()).hexdigest()!=c['board']['source_sha256']:raise ValueError('Frozen PCB source hash changed')
        for field,other in [('width','width_mm'),('height','height_mm'),('radius','corner_radius_mm')]:
            if abs(c['board'][field]-data['board'][other])>1e-6:raise ValueError('Board outline differs from frozen contract')
        if sorted(c['board']['holes'])!=sorted(data['board']['holes_mm']):raise ValueError('Board mounting holes differ from frozen contract')
        for field in ('outline_points_mm','cutouts_mm'):
            if c['board'].get(field,[])!=data['board'].get(field,[]):raise ValueError('Board notch/window profile differs from frozen contract')
        if c['cable']['mode']=='gland' and not c['cable']['gland_confirmed']:raise ValueError('An exact gland must be selected before a gland-mode export')
    shapes,d=build(c);report=validate(c,shapes,d);report['contract_sha256']=hashlib.sha256(args.contract.read_bytes()).hexdigest()
    (args.out/'enclosure-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
    print(json.dumps(report,indent=2))
    if not report['passed']:raise SystemExit(2)
    import FreeCAD as App
    doc=App.newDocument('OrionR5Enclosure')
    for name,s in shapes.items():
        obj=doc.addObject('PartDesign::Feature',name.title());obj.Label=name.title();obj.Shape=s
        obj.addProperty('App::PropertyString','ContractStatus');obj.ContractStatus=report['status']
    for index,part in enumerate(component_solids(c,d)):
        obj=doc.addObject('PartDesign::Feature',f'Component{index}');obj.Label=part['ref']+' / '+part['name'];obj.Shape=part['solid']
    doc.recompute();doc.saveAs(str(args.out/('Orion-R5-enclosure.FCStd' if c['frozen'] else 'PROVISIONAL-enclosure.FCStd')))
    render_preview(c,shapes,d,args.out)
    if args.export:
        import MeshPart,Part
        print_report={}
        for name in ('base','lid'):
            s=shapes[name].copy()
            if name=='lid':s.rotate(App.Vector(0,0,0),App.Vector(1,0,0),180)
            s.translate(App.Vector(-s.BoundBox.XMin,-s.BoundBox.YMin,-s.BoundBox.ZMin))
            mesh=MeshPart.meshFromShape(Shape=s,LinearDeflection=.03,AngularDeflection=math.radians(5),Relative=False)
            volume_error=abs(mesh.Volume-s.Volume)/s.Volume
            if not mesh.isSolid() or volume_error>.002:raise ValueError(name+' STL is not watertight or exceeds0.2% volume deviation')
            mesh.write(str(args.out/f'Orion-R5-{name}-print.stl'))
            print_report[name]=dict(watertight=mesh.isSolid(),cad_volume_mm3=s.Volume,mesh_volume_mm3=mesh.Volume,
                                    relative_volume_error=volume_error,minimum_z_mm=mesh.BoundBox.ZMin)
        Part.makeCompound([shapes['base'],shapes['lid']]).exportStep(str(args.out/'Orion-R5-case-assembled.step'))
        Part.makeCompound([shapes['base'],shapes['lid'],shapes['pcb']]+[p['solid'] for p in component_solids(c,d)]).exportStep(str(args.out/'Orion-R5-complete-assembly.step'))
        (args.out/'print-mesh-validation.json').write_text(json.dumps(dict(passed=True,parts=print_report,contract_sha256=report['contract_sha256']),indent=2)+'\n',encoding='utf8')


if __name__=='__main__':main()
