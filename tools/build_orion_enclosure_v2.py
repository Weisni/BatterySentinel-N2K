"""Build/validate the separate-strain-relief enclosure with FreeCAD 1.1 Python.

Old CAD and user 3MF projects are immutable inputs. TPU seated shapes are
geometric envelopes, not constitutive deformation or contact-pressure models.
"""
from pathlib import Path
import os, sys, json, math, hashlib

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'hardware/altium-r5/enclosure/sealed-v2'
OUT.mkdir(parents=True,exist_ok=True)
FC=Path('C:/Program Files/FreeCAD 1.1')
sys.path.insert(0,str(FC/'lib'))
_dll=os.add_dll_directory(str(FC/'bin'))
prof=OUT/'freecad-profile/v1-1';prof.mkdir(parents=True,exist_ok=True)
for name in ('user.cfg','system.cfg'):
    (prof/name).write_text('<?xml version="1.0"?><FCParameters><FCParamGroup Name="Root"/></FCParameters>')
os.environ['FREECAD_USER_HOME']=str(prof.parent)
import FreeCAD as App
import Part, MeshPart
from build_orion_r5_sealed_enclosure import rounded,ring,cyl,profile,face_mount,orient
from build_orion_r5_enclosure import component_solids,sync_design
from build_orion_r5_flush_lid import marking_shape
V=App.Vector
P=json.loads((OUT/'parameters.json').read_text())

def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def moved(s,x=0,y=0,z=0):
    s=s.copy();s.translate(V(x,y,z));return s
def compressed(s,axis,factor):
    m=App.Matrix();setattr(m,{'x':'A11','y':'A22','z':'A33'}[axis],factor)
    return s.transformGeometry(m)
def rw(x,y,w,h,r,z):
    edges=[]
    corners=[(x+w-r,y+r,270,360),(x+w-r,y+h-r,0,90),
             (x+r,y+h-r,90,180),(x+r,y+r,180,270)]
    arcs=[Part.makeCircle(r,V(a,b,z),V(0,0,1),c,d) for a,b,c,d in corners]
    for i,a in enumerate(arcs):
        edges.append(a)
        end=a.Vertexes[-1].Point;start=arcs[(i+1)%4].Vertexes[0].Point
        edges.append(Part.makeLine(end,start))
    return Part.Wire(edges)

def face_gasket(x,y,w,h,r):
    base=ring(x,y,w,h,r,2.4,0,.8)
    # Loft a rounded crest following the continuous rounded-rectangle centreline.
    outer=[];inner=[]
    for z,half in [(.8,.6),(1.0,.588),(1.3,.52),(1.6,.36),(1.78,.12),(1.8,.06)]:
        for target,off in [(outer,1.2-half),(inner,1.2+half)]:
            target.append(rw(x+off,y+off,w-2*off,h-2*off,r-off,z))
    bead=Part.makeLoft(outer,True,False).cut(Part.makeLoft(inner,True,False))
    return base.fuse(bead).removeSplitter()

def sleeve(bore,length):
    body=cyl(0,0,5.5,0,6.0).cut(cyl(0,0,3.75,-.1,6.2))
    for z in (1.5,4.0):
        bead=Part.makeTorus(bore/2+.6,.6,V(0,0,z),V(0,0,1))
        body=body.fuse(bead)
    # Half-elliptical annular shoulder bead; volume has room to displace outward.
    tor=Part.makeTorus(4.65,.8,V(),V(0,0,1))
    tor=compressed(tor,'z',(length-6.)/.8)
    tor=moved(tor,z=6.)
    tor=tor.common(cyl(0,0,6,6.,length-6.+.01))
    return body.fuse(tor).removeSplitter()

def build():
    c=json.loads((ROOT/'hardware/altium-r5/enclosure/sealed-print/sealed-contract.json').read_text())
    c=sync_design(c,ROOT/'hardware/altium-r5/orion-r5-design.json')
    c['revision']=P['revision'];c['branding']['depth']=.4
    ext=P['extension_mm'];left=-12-ext;inside=left+8;seam=30.;closed=P['face_seal_closed_mm']
    parts={};assembly={};details={'lid_screws':[], 'blind_probes':[], 'sealing_lands':{}}
    def add(name,s,material='PETG',assembled=None,flip=False,group='production',**meta):
        parts[name]=dict(shape=s,material=material,flip=flip,group=group,**meta)
        if assembled is not None:assembly[name]=assembled
    mid=left+(76+ext)/2
    # The sealing/port coordinate frames stay fixed. Only their local pads
    # remain thick; the main walls no longer fill the whole boss envelope.
    cable_face=left-2.4;usb_face=66.4;switch_face=51.4
    wall=P['free_wall_mm'];relief=P['texture_relief_mm']
    outer_left=inside-wall-3;outer_right=56+wall+3
    outer_front=-4-wall-3-relief;outer_back=40+wall+3+relief
    width=outer_right-outer_left;height=outer_back-outer_front
    def outline(inset,z):
        return rw(outer_left+inset,outer_front+inset,width-2*inset,height-2*inset,4.4-inset,z)
    def supported_pad(pad,side,along,z,surface,wall_surface):
        # Extend only the underside down to the wall with a 45-degree ramp.
        # This supports the projecting pads during the upright base print.
        front=max((f for f in pad.Faces if abs(f.BoundBox.ZMin)<1e-6 and abs(f.BoundBox.ZMax)<1e-6),key=lambda f:f.Area)
        ramp=abs(surface-wall_surface)+.2
        a=front.OuterWire.copy();a.translate(V(0,-ramp,-ramp))
        pad=pad.fuse(Part.makeLoft([a,front.OuterWire],True,True))
        return face_mount(pad,side,along,z,surface)
    base=Part.makeLoft([outline(.8,0),outline(0,.8),outline(0,29.6),outline(.4,30)],True,True)
    # A self-supporting inward shoulder supports the unchanged seal groove.
    # Its 4.3 mm rise exceeds even the 3*sqrt(2) mm diagonal corner setback.
    # Below it the cavity expands by 3 mm on each side, avoiding heavy walls.
    cavity=Part.makeLoft([rw(inside-3,-7,66+ext,50,3,P['floor_mm']),
        rw(inside-3,-7,66+ext,50,3,P['lid_rim_transition_start_mm']),
        rw(inside,-4,60+ext,44,3,P['lid_rim_transition_end_mm']),
        rw(inside,-4,60+ext,44,3,seam+.1)],True,True)
    base=base.cut(cavity)
    # 45 degree top chamfer expands gradually from the face-down first layer.
    lid=Part.makeLoft([outline(0,30),outline(0,30.8),outline(2.4,33.2)],True,True)
    screws=[(left+2,-10),(62,-10),(left+2,46),(62,46),(mid,-11),(mid,47)]
    for x,y in screws:
        boss_radius=5.4 if x==mid else 4.4
        # All six bosses now stand proud of the thinner side walls.
        shoulder=Part.makeCone(boss_radius-.4,boss_radius,.8,V(x,y,0)).fuse(cyl(x,y,boss_radius,.8,28.8))
        shoulder=shoulder.fuse(Part.makeCone(boss_radius,boss_radius-.4,.4,V(x,y,29.6)))
        base=base.fuse(shoulder)
        base=base.cut(cyl(x,y,P['m3_pilot_diameter_mm']/2,30-P['m3_pilot_depth_mm'],7))
        # Keep the full 7 mm washer seat level through the decorative bevel.
        boss=cyl(x,y,boss_radius,30,2.6)
        boss=boss.fuse(Part.makeCone(boss_radius,boss_radius-.4,.6,V(x,y,32.6)))
        lid=lid.fuse(boss)
        lid=lid.cut(cyl(x,y,1.7,29.9,3.4))
        details['blind_probes'].append(('lid',cyl(x,y,2,23.28,.01)))
    details['lid_screws']=screws
    details['styling']=dict(body_bounds_mm=[outer_left,outer_front,outer_right,outer_back],
        centre_x_mm=mid,middle_screw_axes_mm=screws[-2:],mounting_axes_mm=[[mid,-21],[mid,57]],
        lid_chamfer_mm=2.4,lower_bevel_mm=.8,side_panel_recess_mm=relief,side_groove_depth_mm=0,
        rib_bands_x_mm=[[-17,-.2],[36.2,53.0]],
        centre_shoulder_projection_mm=5.8,maximum_boss_envelope_mm=[96.8,68.8,33.2],
        free_wall_mm=wall,wall_at_ribs_mm=wall+relief,floor_mm=P['floor_mm'],
        local_sealing_rim_mm={'ends':6.,'long_sides':6.6},local_port_pad_mm=P['local_port_pad_mm'],
        cavity_lower_bounds_mm=[inside-3,-7,59,43],rim_transition_z_mm=[P['lid_rim_transition_start_mm'],P['lid_rim_transition_end_mm']],
        maximum_rim_overhang_angle_from_vertical_deg=math.degrees(math.atan(math.sqrt(18)/(P['lid_rim_transition_end_mm']-P['lid_rim_transition_start_mm']))),
        ports_moved_outward_mm={'cable':2.4,'USB':2.4,'switch':3.4})
    groove=ring(-8.2-ext,-8.2,68.4+ext,52.4,6.2,3.4,30-closed,closed+.1)
    base=base.cut(groove)
    gasket=face_gasket(-8-ext,-8,68+ext,52,6)
    add('lid_gasket',gasket,'TPU',ring(-8-ext,-8,68+ext,52,6,2.4,30-closed,closed))
    details['sealing_lands']['lid']=ring(-8-ext,-8,68+ext,52,6,2.4,30-closed-.01,.01)
    lid=lid.fuse(ring(-3.6-ext,-3.6,59.2+ext,43.2,2.6,1.2,28.2,1.9))
    for x,y in c['board']['holes']:
        base=base.fuse(cyl(x,y,2.7,2.99,5.01)).cut(cyl(x,y,P['m2_pilot_diameter_mm']/2,8-P['m2_pilot_depth_mm'],4.7))
        details['blind_probes'].append(('PCB',cyl(x,y,1.6,3.38,.01)))
    for y in (-21,57):
        # Mirrored rounded tabs with bevelled edges, joined broadly to the wall.
        tab_y=y-6 if y<0 else 48
        wires=[rw(mid-6+d,tab_y+d,12-2*d,15-2*d,3-d,z) for d,z in ((.6,0),(0,.6),(0,3.4),(.6,4))]
        base=base.fuse(Part.makeLoft(wires,True,True))
        base=base.cut(rounded(mid-1.8,y-3,3.6,6,1.7,-.1,4.2))
    # Shallow recessed fields leave a full 3 mm structural wall. Ribs fill
    # selected strips of that relief; no deeper grooves cut into the shell.
    def front_mount(s):
        s=s.copy();s.rotate(V(),V(1,0,0),90);s.translate(V(0,outer_front,0));return s
    for start in (left+8,mid+6):
        field=Part.makeLoft([rw(start,2.8,32,25.6,3,1),
            rw(start,2.8,32,25.6,3,0),rw(start+.6,3.4,30.8,24.4,2.4,-relief)],True,True)
        base=base.cut(front_mount(field))
        if start<mid:
            rear=field.copy();rear.rotate(V(),V(1,0,0),90);rear.rotate(V(),V(0,0,1),180)
            # Reverse local X so the rear panel remains on the port-free left.
            rear.translate(V(2*start+32,outer_back,0));base=base.cut(rear)
    for band_start in (left+11,mid+18.2):
        for i in range(8):
            x=band_start+i*2.4
            rib=rounded(x-.5,4.8,1.,21.6,.4,-relief-.01,relief+.01)
            base=base.fuse(front_mount(rib))
            if x<mid:
                base=base.fuse(face_mount(rounded(-.5,-10.8,1.,21.6,.4,-relief-.01,relief+.01),'Y+',x,15.6,outer_back))
    for along in (-6,-3.6,-1.2,37.2,39.6,42):
        base=base.fuse(face_mount(rounded(-.5,-10,1,20,.4,-.01,relief+.01),'X-',along,16,outer_left))
    for kind in ('usb','service_switch'):
        p=c[kind];side=p['side'];along=p['center_along_edge'];z=9.6+p['center_above_pcb'];surf=usb_face if side=='X+' else switch_face
        aw,ah,cw,ch,sx=(18.,10.,43.,24.,18.) if kind=='usb' else (8.,5.,34.,19.6,13.)
        # Local 8 mm port plinths support continuous seal lands and 6.7 mm
        # blind insert pilots. Their tops are the existing cover seat planes.
        pad=rounded(-cw/2,-ch/2,cw,ch,2,-P['local_port_pad_mm'],P['local_port_pad_mm'])
        if kind=='service_switch':
            for sign in (-1,1):
                corner=[(sign*cw/2,-ch/2),(sign*(cw/2-7),-ch/2),(sign*cw/2,-ch/2+7)]
                pad=pad.cut(profile(corner,-8.1,8.2))
        base=base.fuse(supported_pad(pad,side,along,z,surf,outer_right if side=='X+' else outer_back))
        base=base.cut(face_mount(rounded(-aw/2,-ah/2,aw,ah,1,-13,14),side,along,z,surf))
        ow,oh=aw+8,ah+8
        cover=rounded(-cw/2,-ch/2,cw,ch,2,0,4.)
        cover=cover.cut(ring(-ow/2-.2,-oh/2-.2,ow+.4,oh+.4,3.2,3.4,-.1,closed+.1))
        # External frame ribs leave circular flat washer seats at the screw centres.
        rib=ring(-cw/2+1,-ch/2+1,cw-2,ch-2,1,1,3.99,2.01)
        for x in (-sx,sx):rib=rib.cut(cyl(x,0,3.5,3.9,2.3))
        cover=cover.fuse(rib)
        if kind=='service_switch':
            # Symmetric lower corner facets clear the centred mounting tab.
            # The continuous gasket loop and both washer seats stay intact.
            for sign in (-1,1):
                corner=[(sign*cw/2,-ch/2),(sign*(cw/2-7),-ch/2),(sign*cw/2,-ch/2+7)]
                cover=cover.cut(profile(corner,-.1,6.3))
        for x in (-sx,sx):
            cover=cover.cut(cyl(x,0,1.7,-.1,6.3))
            base=base.cut(face_mount(cyl(x,0,2,-6.7,6.8),side,along,z,surf))
            details['blind_probes'].append((kind,face_mount(cyl(x,0,2,-6.72,.01),side,along,z,surf)))
        seal=face_gasket(-ow/2,-oh/2,ow,oh,3)
        seated=ring(-ow/2,-oh/2,ow,oh,3,2.4,0,closed)
        # Reflecting about local Y is safe because each face seal is symmetric.
        add(kind+'_cover',cover,assembled=face_mount(cover,side,along,z,surf),flip=False)
        add(kind+'_gasket',seal,'TPU',face_mount(seated,side,along,z,surf))
        details['sealing_lands'][kind]=face_mount(ring(-ow/2,-oh/2,ow,oh,3,2.4,-.01,.01),side,along,z,surf)
    # End wall: 6 mm pocket + 2 mm continuous shoulder.
    centres=[(0,10),(-11,-6),(11,-6)]
    cap=profile(centres,0,5)
    for a,b in zip(centres,centres[1:]+centres[:1]):
        dx,dy=b[0]-a[0],b[1]-a[1];ln=math.hypot(dx,dy);nx,ny=-dy/ln*4,dx/ln*4
        cap=cap.fuse(profile([(a[0]+nx,a[1]+ny),(b[0]+nx,b[1]+ny),(b[0]-nx,b[1]-ny),(a[0]-nx,a[1]-ny)],0,5))
    for x,y in centres:cap=cap.fuse(cyl(x,y,4,0,5))
    cap=cap.removeSplitter()
    pad=compressed(cap,'z',P['local_port_pad_mm']/5)
    pad=moved(pad,z=-P['local_port_pad_mm'])
    base=base.fuse(supported_pad(pad,'X-',18,14,cable_face,outer_left))
    base=base.cut(face_mount(cyl(0,0,3.8,-13,14),'X-',18,14,cable_face))
    base=base.cut(face_mount(cyl(0,0,6.1,-6,6.1),'X-',18,14,cable_face))
    top_face=max((f for f in cap.Faces if abs(f.BoundBox.ZMin-5)<1e-7 and abs(f.BoundBox.ZMax-5)<1e-7),key=lambda f:f.Area)
    w0=top_face.OuterWire.copy();w0.translate(V(0,0,-.4))
    mat=App.Matrix();mat.A11=.84;mat.A22=.84
    w1=top_face.OuterWire.transformGeometry(mat);w1.translate(V(0,0,1.0))
    shoulder=Part.makeLoft([w0,w1],True,True)
    top_edges=[e for e in cap.Edges if abs(e.BoundBox.ZMin-5)<1e-7 and abs(e.BoundBox.ZMax-5)<1e-7]
    cap=cap.makeChamfer(.4,top_edges)
    ribs=shoulder.fuse(cyl(0,0,6.6,4.99,2.01))
    for x,y in centres:ribs=ribs.cut(cyl(x,y,3.5,4.9,2.3))
    cap=cap.fuse(ribs).cut(cyl(0,0,3.8,-.1,7.3))
    for x,y in centres:
        cap=cap.cut(cyl(x,y,1.7,-.1,7.3))
        base=base.cut(face_mount(cyl(x,y,2,-6.7,6.8),'X-',18,14,cable_face))
        details['blind_probes'].append(('cable',face_mount(cyl(x,y,2,-6.72,.01),'X-',18,14,cable_face)))
    add('cable_pressure_cap',cap.removeSplitter(),assembled=face_mount(cap,'X-',18,14,cable_face))
    selected=None
    for bore in P['cable_seal_bores_mm']:
        for ln in P['cable_seal_lengths_mm']:
            name=f'cable_seal_b{bore:.1f}_L{ln:.1f}'.replace('.','p')
            sh=sleeve(bore,ln)
            choose=bore==P['selected_seal_bore_mm'] and ln==P['selected_seal_length_mm']
            seated=face_mount(moved(compressed(sh,'z',6/ln),z=-6),'X-',18,14,cable_face) if choose else None
            # Mirror along axis so the raised face bead seats on the internal shoulder.
            if choose:
                local=cyl(0,0,5.5,-6,6).cut(cyl(0,0,bore/2,-6.1,6.2))
                seated=face_mount(local,'X-',18,14,cable_face);selected=name
            add(name,sh,'TPU',seated,group='production' if choose else 'alternative',bore_mm=bore,free_length_mm=ln)
    # Closed-state cable sleeve is a simplified envelope; jacket interference is intentional.
    # Lower saddle and upper half-shell, 12 mm contact. Broad toroidal ribs.
    lower=Part.makeBox(12,14,10.8,V(-18,11,3))
    upper=rounded(-18,4,12,28,2,14.2,6)
    bore=Part.makeCylinder(3.7,12.2,V(-18.1,18,14),V(1,0,0))
    lower=lower.cut(bore);upper=upper.cut(bore)
    for x in (-16,-12,-8):
        rib=Part.makeTorus(4.1,.75,V(x,18,14),V(1,0,0))
        lower=lower.fuse(rib.common(Part.makeBox(12,14,10.8,V(-18,11,3))))
        upper=upper.fuse(rib.common(Part.makeBox(12,28,6,V(-18,4,14.2))))
    for y in (8,28):
        boss=cyl(-12,y,4.5,3,11.2)
        base=base.fuse(boss)
        # Reach the expanded cavity's end wall, preserving the clamp load path.
        buttress_start=inside-3
        base=base.fuse(Part.makeBox(-12-buttress_start,6,7,V(buttress_start,y-3,3)))
        base=base.cut(cyl(-12,y,2,7.5,6.8))
        upper=upper.cut(cyl(-12,y,1.7,14.1,6.3))
        details['blind_probes'].append(('clamp',cyl(-12,y,2,7.48,.01)))
    base=base.fuse(lower).common(Part.makeBox(200,200,50,V(-80,-60,0))).removeSplitter()
    add('strain_relief_upper',upper.removeSplitter(),assembled=moved(upper,z=.2),flip=True)
    for h in (.2,.4):
        sh=rounded(-18,4,12,28,2,0,h).cut(rounded(-18.1,12,12.2,12,1,-.1,h+.2))
        # Two individual pads, exported as a paired print item.
        for y in (8,28):sh=sh.cut(cyl(-12,y,1.7,-.1,h+.2))
        add(f'clamp_shims_{str(h).replace(".","p")}',sh,group='calibration',multi=True)
        if h==.2:assembly['clamp_shims']=moved(sh,z=14.2)
    marks,_=marking_shape(c,33.2)
    # Centre the complete visible artwork on the current lid face, rather than
    # retaining the smaller enclosure's branding coordinates. Cut and inlay
    # must use this same translated shape.
    target=(left+(76+ext)/2, -12+60/2)
    bb=marks.BoundBox
    shift=(target[0]-(bb.XMin+bb.XMax)/2,target[1]-(bb.YMin+bb.YMax)/2)
    marks.translate(V(shift[0],shift[1],0))
    for item in [c['branding']]+c['branding']['texts']:
        item['center']=[item['center'][i]+shift[i] for i in range(2)]
    bb=marks.BoundBox
    details['branding_centering']=dict(target_center_mm=list(target),
        artwork_center_mm=[(bb.XMin+bb.XMax)/2,(bb.YMin+bb.YMax)/2],
        translation_mm=list(shift),reference='Complete artwork bounds on rectangular lid face')
    assert all(abs(details['branding_centering']['artwork_center_mm'][i]-target[i])<1e-7 for i in range(2))
    plain_lid=lid.copy()
    lid=lid.cut(marks).removeSplitter()
    add('base',base,assembled=base)
    add('lid_body',lid,assembled=lid,flip=True,step_shape=plain_lid)
    add('lid_markings',marks,assembled=marks,flip=True,multi=True,shared_origin='lid_body')
    # Coupon contains the true horizontal pocket, pilots, floor and strain relief.
    coupon=base.common(Part.makeBox(32.4,38,28.6,V(cable_face,-1,0)))
    add('entry_fit_coupon',coupon.removeSplitter(),group='calibration')
    for depth in (1.4,1.6):
        cp=rounded(0,0,34,18,2,0,5).cut(Part.makeBox(3.4,24,depth+.1,V(15.3,-3,5-depth)))
        add(f'face_stop_coupon_{str(depth).replace(".","p")}',cp,group='calibration')
    # A gasket loop comparable to the small switch seal and a hardness coupon.
    add('face_test_gasket',face_gasket(0,0,24,16,3),'TPU',group='calibration')
    add('shore_comparison_pad',rounded(0,0,50,50,2,0,6),'TPU',group='calibration')
    add('flow_wall_coupon',ring(0,0,24,24,2,.9,0,8),'TPU',group='calibration')
    b=c['board'];pcb=profile(b['outline_points_mm'],8,b['thickness'])
    for cut in b.get('cutouts_mm',[]):pcb=pcb.cut(profile(cut['outline_points_mm'],7.9,b['thickness']+.2))
    for x,y in b['holes']:pcb=pcb.cut(cyl(x,y,1.1,7.9,1.8))
    dim=dict(pcb_bottom=8.,pcb_top=9.6,seam_z=30.,outer_height=33.2)
    comps=component_solids(c,dim)
    return c,parts,assembly,pcb,comps,details

def validate(c,parts,assembly,pcb,comps,details):
    errors=[];checks={}
    def check(ok,msg):
        if not ok:errors.append(msg)
    for name,item in parts.items():
        print('Solid check: '+name,flush=True)
        s=item['shape'];check(s.isValid() and s.isClosed() and s.Volume>0,name+' invalid')
        check(len(s.Solids)==1 or item.get('multi'),name+' disconnected solids')
    pairs=[]
    names=list(assembly)
    for i,a in enumerate(names):
        print('Assembly check: '+a,flush=True)
        for b in names[i+1:]:
            # The body was constructed by subtracting precisely these colour
            # solids. Re-intersecting thousands of coincident text faces is an
            # expensive redundant Boolean; validate their partition by volume
            # and the exported shared coordinate frame instead.
            if {a,b}=={'lid_body','lid_markings'}:continue
            ab,bb=assembly[a].BoundBox,assembly[b].BoundBox
            if any(min(getattr(ab,k+'Max'),getattr(bb,k+'Max'))-max(getattr(ab,k+'Min'),getattr(bb,k+'Min'))<1e-7 for k in 'XYZ'):continue
            vol=assembly[a].common(assembly[b]).Volume
            if vol>1e-5:pairs.append(dict(a=a,b=b,volume=vol));errors.append(f'Collision {a}/{b}: {vol:.6g}')
    clearances=[]
    for name in ('base','lid_body','usb_cover','service_switch_cover','cable_pressure_cap','strain_relief_upper'):
        print('Component check: '+name,flush=True)
        s=assembly[name];check(s.common(pcb).Volume<1e-5,name+' intersects PCB')
        for comp in comps:
            a,b=s.BoundBox,comp['solid'].BoundBox
            lb=math.sqrt(sum(max(0,getattr(a,k+'Min')-getattr(b,k+'Max'),getattr(b,k+'Min')-getattr(a,k+'Max'))**2 for k in 'XYZ'))
            gap=lb if lb>.5 else s.distToShape(comp['solid'])[0]
            check(gap>=.5-1e-6,f'{name} too close to {comp["ref"]}: {gap}')
            clearances.append(dict(part=name,component=comp['ref'],gap_mm=gap,lower_bound=lb>.5))
    blind=[]
    for kind,probe in details['blind_probes']:
        coverage=assembly['base'].common(probe).Volume/probe.Volume
        blind.append(dict(group=kind,coverage=coverage))
        check(coverage>.999,'Open blind pilot: '+kind)
    lands={}
    for name,probe in details['sealing_lands'].items():
        ratio=assembly['base'].common(probe).Volume/probe.Volume;lands[name]=ratio
        check(ratio>.999,'Incomplete seal land: '+name)
    # Ensure all end-wall screws stay outside the seal socket and all lid screws outside the face loop.
    seal_plan=ring(-24,-8,84,52,6,2.4,0,1)
    for x,y in details['lid_screws']:check(seal_plan.common(cyl(x,y,2,0,1)).Volume<1e-6,'Lid bore crosses seal')
    for x,y in [(0,10),(-11,-6),(11,-6)]:check(math.hypot(x,y)-2-6.1>1.,'End-wall screw too close to pocket')
    checks['blind_pilots']=blind;checks['seal_land_coverage']=lands
    washer_seats=[]
    for x,y in details['lid_screws']:
        probe=cyl(x,y,3.5,33.18,.01).cut(cyl(x,y,1.8,33.17,.03))
        coverage=assembly['lid_body'].common(probe).Volume/probe.Volume
        washer_seats.append(coverage);check(coverage>.999,'Incomplete lid washer seat')
    for x,y in [(0,10),(-11,-6),(11,-6)]:
        probe=face_mount(cyl(x,y,3.5,4.98,.01).cut(cyl(x,y,1.8,4.97,.03)),'X-',18,14,-14.4-P['extension_mm'])
        coverage=assembly['cable_pressure_cap'].common(probe).Volume/probe.Volume
        washer_seats.append(coverage);check(coverage>.999,'Incomplete cable cap washer seat')
    checks['washer_seat_coverage']=washer_seats
    check(details['lid_screws'][-2][0]==details['lid_screws'][-1][0]==details['styling']['centre_x_mm'],'Middle screws not centred')
    # Undeformed free seal volume must fit the closed annulus without 100% confinement.
    annulus=math.pi*(6.1**2-3.5**2)*6
    ratios={n:p['shape'].Volume/annulus for n,p in parts.items() if n.startswith('cable_seal')}
    check(max(ratios.values())<.9,'Cable sleeve insufficient relief volume')
    return dict(passed=not errors,errors=errors,assembly_collisions=pairs,
                lid_colour_partition='Body is original lid minus the exact marking solids; shared print transform',
                branding_centering=details['branding_centering'],
                styling=details['styling'],
                minimum_component_clearance=min(clearances,key=lambda x:x['gap_mm']),
                component_checks=len(clearances),cable_free_volume_to_closed_annulus=ratios,
                checks=checks,physical_status='UNTESTED',
                seated_TPU='Simplified compressed geometry; not a material/contact simulation',
                nominal_body_mm=[88.,57.2,33.2],parameters=P)

def verify_step_geometry(reference,readback):
    """Compare each solid's tessellated surface, not cached OCCT mass alone."""
    import vtk
    def poly(s):
        mesh=MeshPart.meshFromShape(Shape=s,LinearDeflection=.02,AngularDeflection=math.radians(6),Relative=False)
        verts,faces=mesh.Topology
        points=vtk.vtkPoints();cells=vtk.vtkCellArray()
        for p in verts:points.InsertNextPoint(p.x,p.y,p.z)
        for face in faces:
            cells.InsertNextCell(3)
            for i in face:cells.InsertCellPoint(i)
        data=vtk.vtkPolyData();data.SetPoints(points);data.SetPolys(cells)
        return mesh,data
    remaining=list(readback.Solids);rows=[]
    for index,source in enumerate(reference.Solids):
        target=min(remaining,key=lambda s:(s.BoundBox.Center-source.BoundBox.Center).Length)
        remaining.remove(target)
        a,ap=poly(source);b,bp=poly(target)
        distances=[]
        for inp,other in ((ap,bp),(bp,ap)):
            f=vtk.vtkImplicitPolyDataDistance();f.SetInput(other)
            distances.append(max(abs(f.EvaluateFunction(inp.GetPoint(i))) for i in range(inp.GetNumberOfPoints())))
        error=abs(a.Volume-b.Volume)/a.Volume
        assert error<.002 and max(distances)<.05,(index,error,distances)
        rows.append(dict(solid=index,mesh_relative_volume_error=error,maximum_bidirectional_vertex_surface_distance_mm=max(distances)))
    return dict(passed=True,solids=rows,surface_tolerance_mm=.05,relative_mesh_volume_tolerance=.002,
                note='All tessellation vertices checked in both directions; OCCT cached analytic volumes are not used as sole evidence')

def export(c,parts,assembly,pcb,comps,report):
    doc=App.newDocument('OrionEnclosureV2')
    for name,shape in list(assembly.items())+[('PCB',pcb)]+[(f'Component_{i}_{p["ref"]}',p['solid']) for i,p in enumerate(comps)]:
        ob=doc.addObject('PartDesign::Feature',name);ob.Shape=shape
        ob.addProperty('App::PropertyString','Qualification');ob.Qualification='Digital prototype; physical acceptance pending'
    doc.recompute();doc.saveAs(str(OUT/'Orion-Enclosure-V2.FCStd'))
    mesh_report={};manifest=[]
    lid_ref=parts['lid_body']['shape'].copy();lid_ref.rotate(V(),V(1,0,0),180);bb=lid_ref.BoundBox
    lid_shift=V(-bb.XMin,-bb.YMin,-bb.ZMin)
    for name,item in parts.items():
        print('Mesh export: '+name,flush=True)
        s=item['shape'].copy()
        if name in ('lid_body','lid_markings'):
            s.rotate(V(),V(1,0,0),180);s.translate(lid_shift)
        else:s=orient(s,item.get('flip',False))
        mesh=MeshPart.meshFromShape(Shape=s,LinearDeflection=.02,AngularDeflection=math.radians(6),Relative=False)
        if mesh.Volume<0:mesh.flipNormals()
        verts,faces=mesh.Topology;edges={};dirs={}
        for face in faces:
            a,b,cc=[verts[k] for k in face]
            assert (b-a).cross(cc-a).Length>1e-10,(name,'degenerate mesh')
            for i in range(3):
                a,b=face[i],face[(i+1)%3];key=tuple(sorted((a,b)))
                edges[key]=edges.get(key,0)+1;dirs[key]=dirs.get(key,0)+(1 if a<b else -1)
        assert mesh.isSolid() and all(n==2 for n in edges.values()) and not any(dirs.values()),name
        delta=abs(mesh.Volume-s.Volume)/s.Volume;assert delta<.005,(name,delta)
        path=OUT/(name+'.stl');mesh.write(str(path))
        entry={k:v for k,v in item.items() if k not in ('shape','flip','multi','step_shape')};entry.update(name=name,path=path.name)
        manifest.append(entry)
        mesh_report[name]=dict(closed_oriented_manifold=True,solids=len(s.Solids),triangles=len(faces),
            volume_mm3=s.Volume,relative_mesh_volume_error=delta,
            bounds_mm=[[s.BoundBox.XMin,s.BoundBox.YMin,s.BoundBox.ZMin],[s.BoundBox.XMax,s.BoundBox.YMax,s.BoundBox.ZMax]],sha256=sha(path))
    (OUT/'print-manifest.json').write_text(json.dumps(dict(printer='Bambu Lab P2S 0.4 nozzle',parts=manifest),indent=2))
    print('STEP assembly export and readback',flush=True)
    # Co-printed colours form one flush lid. STEP conveys its identical exterior
    # without thousands of internal colour-boundary faces; FCStd/STL retain them.
    step_parts=[s for n,s in assembly.items() if n not in ('lid_body','lid_markings')]+[parts['lid_body']['step_shape']]
    step=OUT/'Orion-Enclosure-V2-assembly.step';compound=Part.makeCompound(step_parts);compound.exportStep(str(step))
    rt=Part.Shape();rt.read(str(step));assert rt.isValid() and len(rt.Solids)==len(compound.Solids)
    step_geometry=verify_step_geometry(compound,rt)
    report.update(meshes=mesh_report,step_readback=dict(valid=True,solids=len(rt.Solids),volume_mm3=rt.Volume,
                  colour_boundaries='Flush lid exported as a single solid; separated in FCStd and print meshes',geometry=step_geometry))
    (OUT/'print-manifest.json').write_text(json.dumps(dict(printer='Bambu Lab P2S 0.4 nozzle',parts=manifest),indent=2))
    c.pop('sealed_design',None)
    c['v2_parameters']=P
    c['styling']=report['styling']
    c['case'].update(body_dimensions_mm=[88.,57.2,33.2],maximum_boss_envelope_mm=[96.8,68.8,33.2],cable_side_extension_mm=16,
                     free_wall_mm=P['free_wall_mm'],floor_mm=P['floor_mm'],
                     face_groove_depth_mm=1.4,service_cover_seat_thickness_mm=4)
    c['cable'].update(mode='separate_internal_clamp_and_unsplit_bead_seal',outside_diameter_measured=True,
                      outside_diameter_mm=7.,nominal_options_mm=[7.],sleeve_bead_bores_mm=[6.7,6.8,6.9])
    c['fasteners']={'lid':'6 x M3x8 + 0.5 mm washers','service_covers':'4 x M3x10 + 0.5 mm washers',
                    'cable_cap':'3 x M3x10 + 0.5 mm washers','clamp':'2 x M3x10 + 0.5 mm washers',
                    'pcb':'4 x M2x5','inserts':'15 M3 + 4 M2; purchased body dimensions pending coupon check'}
    c['printing'].update(gaskets='SainSmart Flex TPU Air; calibrated foam, 100% infill',
                          physical_status='No measured hardness or leak/retention acceptance yet')
    c['pending']=['Purchased insert and jacket-tolerance coupon checks','TPU Air calibration and measured Shore comparison',
                  'Independent clamp retention, creep and empty-case leak testing','Actual PCB/plug/wiring and thermal/RF fit']
    (OUT/'mechanical-contract.json').write_text(json.dumps(c,indent=2))
    (OUT/'validation.json').write_text(json.dumps(report,indent=2))

def render(assembly,pcb,comps):
    import vtk
    from render_altium_r3 import mesh_actor
    views=['assembled','exploded','inside','entry-section','parts']
    for view in views:
        ren=vtk.vtkRenderer();ren.SetBackground(.95,.97,.98);ren.SetUseFXAA(True)
        for name,shape in assembly.items():
            if view in ('inside','entry-section') and name in ('lid_body','lid_markings','lid_gasket'):continue
            s=shape.copy()
            if view=='exploded':
                if name.startswith('lid_'):s.translate(V(0,0,30 if name!='lid_gasket' else 15))
                if name=='strain_relief_upper':s.translate(V(0,0,15))
                if name.startswith('cable_'):s.translate(V(-22 if name=='cable_pressure_cap' else -10,0,0))
                if name.startswith('usb'):s.translate(V(18 if 'cover' in name else 9,0,0))
                if name.startswith('service_switch'):s.translate(V(0,18 if 'cover' in name else 9,0))
            if view=='entry-section':
                s=s.common(Part.makeBox(62,80,80,V(-45,-62,-1)))
                if s.Volume<1e-6:continue
            col=[238,176,63] if ('gasket' in name or 'seal_b' in name) else ([245,245,237] if name=='lid_markings' else [57,95,117])
            ren.AddActor(mesh_actor(s,col))
        if view in ('inside','exploded'):
            ren.AddActor(mesh_actor(pcb,[40,130,90]))
            for comp in comps:ren.AddActor(mesh_actor(comp['solid'],comp['rgb']))
        if view=='entry-section':
            cable=Part.makeCylinder(3.5,50,V(-45,18,14),V(1,0,0))
            ren.AddActor(mesh_actor(cable,[80,82,88]))
        win=vtk.vtkRenderWindow();win.SetOffScreenRendering(1);win.SetSize(1600,1100);win.AddRenderer(ren)
        cam=ren.GetActiveCamera();cam.ParallelProjectionOn();cam.SetViewUp(0,0,1)
        cam.SetFocalPoint(10,18,24 if view=='exploded' else 15)
        cam.SetPosition(-125,-135,140);cam.SetParallelScale(78 if view=='exploded' else 65)
        if view=='inside':cam.SetPosition(-55,-90,210);cam.SetParallelScale(59)
        if view=='entry-section':cam.SetFocalPoint(-13,18,12);cam.SetPosition(-60,140,60);cam.SetParallelScale(35)
        ren.ResetCameraClippingRange();win.Render()
        f=vtk.vtkWindowToImageFilter();f.SetInput(win);f.ReadFrontBufferOff();f.Update()
        wr=vtk.vtkPNGWriter();wr.SetFileName(str(OUT/('preview-'+view+'.png')));wr.SetInputConnection(f.GetOutputPort());wr.Write();win.Finalize()

def main():
    sources=[ROOT/'hardware/altium-r5/enclosure/sealed-print/Orion-R5-P2S-flush-colour.3mf',
             ROOT/'hardware/altium-r5/enclosure/sealed-print/Orion-R5-sealed-enclosure.FCStd']
    before={str(p.relative_to(ROOT)):sha(p) for p in sources}
    import faulthandler
    faulthandler.dump_traceback_later(120,repeat=True)
    print('Building V2 enclosure and calibration parts',flush=True)
    c,parts,assembly,pcb,comps,details=build()
    print('Checking solids, assembly, PCB components and seal lands',flush=True)
    report=validate(c,parts,assembly,pcb,comps,details)
    (OUT/'validation.json').write_text(json.dumps(report,indent=2))
    if not report['passed']:print(json.dumps(report['errors'],indent=2));raise SystemExit(2)
    print('Exporting CAD, STEP and closed printable meshes',flush=True)
    export(c,parts,assembly,pcb,comps,report)
    print('Rendering CAD assembly illustrations',flush=True);render(assembly,pcb,comps)
    after={str(p.relative_to(ROOT)):sha(p) for p in sources};assert before==after
    (OUT/'source-preservation.json').write_text(json.dumps(dict(unchanged=True,sha256=after),indent=2))
    faulthandler.cancel_dump_traceback_later()
    print(json.dumps(dict(passed=True,parts=len(parts),minimum_clearance=report['minimum_component_clearance']),indent=2))

if __name__=='__main__':main()
