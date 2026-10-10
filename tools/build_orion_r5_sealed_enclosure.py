"""Build the print-ready, physically unqualified R5 gasketed enclosure.

Run with FreeCAD 1.1's bundled Python. The original dry-case scaffold and PCB
are preserved. CAD source, printable parts, fit coupon and measured checks are
written to hardware/altium-r5/enclosure/sealed-print. No IP rating is implied.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import sys
import faulthandler

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'hardware/altium-r5/enclosure/sealed-print'
FC = Path('C:/Program Files/FreeCAD 1.1')
sys.path.insert(0, str(FC / 'lib'))
_dll = os.add_dll_directory(str(FC / 'bin'))
# Isolate headless preferences from the user's GUI configuration.
OUT.mkdir(parents=True, exist_ok=True)
_profile=OUT/'freecad-profile'
(_profile/'v1-1').mkdir(parents=True,exist_ok=True)
os.environ['FREECAD_USER_HOME']=str(_profile)
for name in ('user.cfg', 'system.cfg'):
    p = _profile/'v1-1'/name
    if not p.exists():
        p.write_text('<?xml version="1.0" encoding="UTF-8"?><FCParameters><FCParamGroup Name="Root"/></FCParameters>')
import FreeCAD as App
import Part
import MeshPart
from build_orion_r5_enclosure import component_solids, enclosure_text_geometry, sync_design
V = App.Vector


def rounded(x, y, w, h, r, z, t):
    if r<=0:return Part.makeBox(w,h,t,V(x,y,z))
    pieces = [Part.makeBox(w-2*r, h, t, V(x+r, y, z)),
              Part.makeBox(w, h-2*r, t, V(x, y+r, z))]
    pieces += [Part.makeCylinder(r, t, V(cx, cy, z)) for cx, cy in
               ((x+r,y+r),(x+w-r,y+r),(x+w-r,y+h-r),(x+r,y+h-r))]
    return pieces[0].multiFuse(pieces[1:]).removeSplitter()


def ring(x, y, w, h, r, width, z, t):
    return rounded(x,y,w,h,r,z,t).cut(rounded(x+width,y+width,w-2*width,h-2*width,r-width,z-.1,t+.2))


def cyl(x, y, r, z, t):
    return Part.makeCylinder(r,t,V(x,y,z))


def face_mount(shape, side, along, height, surface):
    """Local X horizontal, Y up, +Z out of the case; preserve handedness."""
    s=shape.copy()
    s.rotate(V(),V(1,0,0),90)  # +Z -> -Y, +Y -> +Z
    if side=='X+': s.rotate(V(),V(0,0,1),90)
    elif side=='Y+': s.rotate(V(),V(0,0,1),180)
    elif side=='X-': s.rotate(V(),V(0,0,1),-90)
    else: raise ValueError(side)
    s.translate(V(surface,along,height) if side[0]=='X' else V(along,surface,height))
    return s


def profile(points,z,t):
    pts=[V(x,y,z) for x,y in points]
    if (pts[0]-pts[-1]).Length>1e-8: pts.append(pts[0])
    return Part.Face(Part.makePolygon(pts)).extrude(V(0,0,t))


def engraved_lid(lid, contract, top):
    from r5_branding import region_data
    branding=contract['branding']
    asset=json.loads((ROOT/branding['geometry_json']).read_text('utf8'))
    bounds=asset['bounds']; scale=min(branding['width']/(bounds[2]-bounds[0]),branding['height']/(bounds[3]-bounds[1]))
    def xy(p): return (branding['center'][0]+(p[0]-(bounds[0]+bounds[2])/2)*scale,
                       branding['center'][1]+(p[1]-(bounds[1]+bounds[3])/2)*scale)
    artwork=[dict(points=[xy(p) for p in a['points']],holes=[[xy(p) for p in h] for h in a.get('holes',[])]) for a in asset['shapes']]
    for txt in branding['texts']: artwork.extend(region_data(enclosure_text_geometry(txt)))
    cuts=[];depth=branding['depth']
    for a in artwork:
        cut=profile(a['points'],top-depth,depth+.1)
        for hole in a.get('holes',[]): cut=cut.cut(profile(hole,top-depth-.1,depth+.3))
        cuts.append(cut)
    return lid.cut(Part.makeCompound(cuts))


def build(c):
    b=c['board']; bw,bh=b['width'],b['height']
    if abs(bw-52)>1e-6 or abs(bh-36)>1e-6:
        raise ValueError('Review sealing flange and service covers for a changed board size')
    floor,pcb_z,seam,lid_t=3.,8.,30.,3.2
    d=dict(pcb_bottom=pcb_z,pcb_top=pcb_z+b['thickness'],seam_z=seam,outer_height=seam+lid_t)
    base=rounded(-12,-12,76,60,7,0,seam).cut(rounded(-4,-4,60,44,3,floor,seam))
    lid=rounded(-12,-12,76,60,7,seam,lid_t)
    screws=[(-10,-10),(62,-10),(-10,46),(62,46),(10,-11),(10,47)]
    for x,y in screws:
        base=base.fuse(cyl(x,y,4.4,0,seam)).cut(cyl(x,y,2.,seam-6.7,6.8))
        lid=lid.fuse(cyl(x,y,4.4,seam,lid_t)).cut(cyl(x,y,1.7,seam-.1,lid_t+.2))
    # Seal ring lies inside all six screw bores. The hard flange stops squeeze
    # at 1.0 / 1.2 mm (five vs six 0.2 mm layers). Groove clearance allows
    # lateral elastomer displacement; no fractional-layer sealing dimensions.
    groove=ring(-8.2,-8.2,68.4,52.4,6.2,3.4,seam-1.,1.1)
    base=base.cut(groove)
    gasket=ring(-8,-8,68,52,6,2.4,0,1.2)
    gasket_seated=ring(-8,-8,68,52,6,2.4,seam-1.,1.)
    # A short inside locating lip, without tall PCB-to-lid screw tubes.
    lid=lid.fuse(ring(-3.6,-3.6,59.2,43.2,2.6,1.2,seam-1.8,1.9))
    for x,y in b['holes']:
        base=base.fuse(cyl(x,y,2.7,floor-.01,pcb_z-floor+.01)).cut(cyl(x,y,1.6,pcb_z-4.6,4.7))
    mount_centers=[]
    for y in (-20,56):
        ear=rounded(2,y-5,16,12,3,0,4)
        # Join ears to the middle external screw towers and main wall.
        root=Part.makeBox(16,12,4,V(2,-20 if y<0 else 44,0))
        base=base.fuse(ear).fuse(root).cut(rounded(8.2,y-3,3.6,6,1.7,-.1,4.2))
        mount_centers.append([10,y])
    parts={}; assembled={}; seals={}; port_data={}; hardware=[]
    hardware += [dict(type='M3x8 lid screw',center=[x,y],engagement_mm=4.8,blind_tip_clearance_mm=1.9) for x,y in screws]
    for kind in ('usb','service_switch'):
        p=c[kind]; side=p['side']; along=p['center_along_edge']; z=d['pcb_top']+p['center_above_pcb']
        surface=64. if side=='X+' else 48.
        if kind=='usb': aw,ah,cw,ch,sx=18.,10.,43.,24.,18.
        else: aw,ah,cw,ch,sx=8.,5.,34.,19.6,13.
        # Rounded apertures bridge at most 18 mm; external support only if
        # calibration requires it, keeping every sealing land support-free.
        aperture=rounded(-aw/2,-ah/2,aw,ah,1.0,-9,10)
        base=base.cut(face_mount(aperture,side,along,z,surface))
        iw,ih=aw+2,ah+2; ow,oh=iw+6,ih+6
        cover=rounded(-cw/2,-ch/2,cw,ch,2.,0,3.2)
        cover_groove=ring(-ow/2-.2,-oh/2-.2,ow+.4,oh+.4,3.2,3.4,-.1,1.1)
        cover=cover.cut(cover_groove)
        seal=ring(-ow/2,-oh/2,ow,oh,3.,2.4,0,1.2)
        seated=ring(-ow/2,-oh/2,ow,oh,3.,2.4,0,1.)
        for x in (-sx,sx):
            cover=cover.cut(cyl(x,0,1.7,-.1,3.4))
            base=base.cut(face_mount(cyl(x,0,2.,-6.7,6.8),side,along,z,surface))
            hardware.append(dict(type='M3x8 '+kind+' cover screw',engagement_mm=4.8,blind_tip_clearance_mm=1.9))
        key=kind+'_cover'
        parts[key]=dict(shape=cover,material='PETG',flip=True)
        parts[kind+'_gasket']=dict(shape=seal,material='TPU')
        assembled[key]=face_mount(cover,side,along,z,surface)
        assembled[kind+'_gasket']=face_mount(seated,side,along,z,surface)
        seals[kind]=dict(free_height_mm=1.2,closed_height_mm=1.,nominal_squeeze_percent=100/6,
                         free_volume_mm3=seal.Volume,groove_volume_mm3=cover_groove.Volume/1.1)
        port_data[kind]=dict(side=side,along_mm=along,center_z_mm=z,opening_mm=[aw,ah],cover_mm=[cw,ch,3.2],
                             screw_spacing_mm=sx*2,blind_wall_remaining_mm=1.3)
    # Unsplit cable cartridge: feed bare end through before soldering. The
    # cylindrical cavity ends in a 2 mm shoulder; its only opening is the cable.
    cy,cz=18.,14.; surface=-12.; pocket_r=6.1; pocket_depth=6.
    base=base.cut(face_mount(cyl(0,0,3.8,-9,10), 'X-',cy,cz,surface))
    base=base.cut(face_mount(cyl(0,0,pocket_r,-pocket_depth,pocket_depth+.1),'X-',cy,cz,surface))
    cable_cap=rounded(-15,-9,30,18,3,0,3.2).cut(cyl(0,0,3.8,-.1,3.4))
    for x in (-11,11):
        cable_cap=cable_cap.cut(cyl(x,0,1.7,-.1,3.4))
        base=base.cut(face_mount(cyl(x,0,2.,-6.7,6.8),'X-',cy,cz,surface))
        hardware.append(dict(type='M3x8 cable pressure cap screw',engagement_mm=4.8,blind_tip_clearance_mm=1.9))
    parts['cable_pressure_cap']=dict(shape=cable_cap,material='PETG',flip=False)
    assembled['cable_pressure_cap']=face_mount(cable_cap,'X-',cy,cz,surface)
    sleeve_data={}
    for nominal in (0.,5.,5.5,6.,6.5,7.):
        bore=max(0.,nominal-.2); free_h=7.
        # 0.5% nominal volume overfill after closure, enough to establish
        # confinement in the ideal geometry; not a TPU constitutive model.
        target_volume=math.pi*(pocket_r**2-(nominal/2)**2)*pocket_depth
        r=math.sqrt(target_volume*1.005/(math.pi*free_h)+(bore/2)**2)
        sleeve=cyl(0,0,r,0,free_h)
        if bore: sleeve=sleeve.cut(cyl(0,0,bore/2,-.1,free_h+.2))
        name='cable_blank' if not nominal else 'cable_seal_'+str(nominal).replace('.','p')+'mm'
        parts[name]=dict(shape=sleeve,material='TPU',alternative_group='cable_cartridge')
        sleeve_data[name]=dict(cable_od_mm=nominal,free_bore_mm=bore,free_outer_diameter_mm=2*r,
                              free_length_mm=7,closed_length_mm=6,nominal_axial_squeeze_percent=100/7,
                              volume_fill_ratio=1.005,measured=False)
        if nominal==0:
            assembled[name]=face_mount(cyl(0,0,pocket_r,-6,6),'X-',cy,cz,surface)
    print('Building lid engraving',flush=True)
    lid=engraved_lid(lid,c,seam+lid_t)
    print('Building PCB and fit coupon',flush=True)
    base=base.removeSplitter();lid=lid.removeSplitter()
    parts['base']=dict(shape=base,material='PETG')
    parts['lid']=dict(shape=lid,material='PETG',flip=True)
    parts['lid_gasket']=dict(shape=gasket,material='TPU')
    assembled.update(base=base,lid=lid,lid_gasket=gasket_seated)
    pcb=profile(b['outline_points_mm'],pcb_z,b['thickness'])
    for cut in b.get('cutouts_mm',[]): pcb=pcb.cut(profile(cut['outline_points_mm'],pcb_z-.1,b['thickness']+.2))
    for x,y in b['holes']: pcb=pcb.cut(cyl(x,y,b['hole_diameter']/2,pcb_z-.1,b['thickness']+.2))
    # Fit coupon combines a cropped actual cable wall in its real horizontal
    # bore orientation with vertical insert pilots and a straight seal groove.
    coupon=rounded(0,0,42,25,3,0,9)
    coupon=coupon.cut(cyl(10,12.5,pocket_r,3,6.1)).cut(cyl(10,12.5,3.8,-.1,9.2))
    coupon=coupon.cut(cyl(24,7,2.,2.3,6.8)).cut(cyl(24,18,1.6,4.4,4.7))
    coupon=coupon.cut(Part.makeBox(3.4,15,1.1,V(33,5,8.0)))
    wall_sample=base.common(Part.makeBox(8.,30.,26.,V(-12,3,0)))
    wall_sample.translate(V(12,-3,0))
    coupon.translate(V(7.9,2.5,0))
    coupon=coupon.fuse(wall_sample).removeSplitter()
    parts['fit_coupon']=dict(shape=coupon,material='PETG',coupon=True)
    bb=Part.makeCompound(list(assembled.values())).BoundBox
    info=dict(**d,outer_body_mm=[76,60,33.2],overall_with_mounting_mm=[bb.XLength,bb.YLength,33.2],
              lid_screws=screws,mount_centers=mount_centers,ports=port_data,hardware=hardware,
              seals=seals,cable_seals=sleeve_data,lid_seal=dict(free_height_mm=1.2,closed_height_mm=1.,
              nominal_squeeze_percent=100/6,groove_width_mm=3.4,free_width_mm=2.4,
              free_volume_mm3=gasket.Volume,groove_volume_mm3=groove.Volume/1.1),
              cable_entry=dict(pocket_diameter_mm=12.2,pocket_depth_mm=6,feed_hole_mm=7.6,side='X-'))
    return parts,assembled,pcb,d,info


def validate(parts,assembly,pcb,components,d,info,c):
    errors=[]; clearances=[]
    def check(ok,msg):
        if not ok: errors.append(msg)
    for name,item in parts.items():
        s=item['shape'];check(s.isValid() and len(s.Solids)==1 and s.isClosed() and s.Volume>0,name+' invalid solid')
    keys=list(assembly)
    intersections=[]
    for i,a in enumerate(keys):
        for bn in keys[i+1:]:
            v=assembly[a].common(assembly[bn]).Volume
            check(v<1e-5,f'{a}/{bn} assembly collision {v:.6g} mm3')
            if v>1e-5: intersections.append([a,bn,v])
    for name in ('base','lid','usb_cover','service_switch_cover','cable_pressure_cap'):
        print('Checking component fit: '+name,flush=True)
        check(assembly[name].common(pcb).Volume<1e-5,name+' collides with PCB')
        for comp in components:
            a,b=assembly[name].BoundBox,comp['solid'].BoundBox
            lower_bound=math.sqrt(sum(max(0,getattr(a,axis+'Min')-getattr(b,axis+'Max'),getattr(b,axis+'Min')-getattr(a,axis+'Max'))**2 for axis in ('X','Y','Z')))
            vol=0 if lower_bound>.5 else assembly[name].common(comp['solid']).Volume
            gap=lower_bound if lower_bound>.5 else assembly[name].distToShape(comp['solid'])[0]
            check(vol<1e-5,comp['ref']+'/'+comp['name']+' intersects '+name)
            check(gap>=.5-1e-6,comp['ref']+'/'+comp['name']+' clearance to '+name+' below 0.5mm')
            clearances.append(dict(component=comp['ref'],body=comp['name'],case_part=name,gap_mm=gap,conservative_lower_bound=lower_bound>.5))
    # Independent probes verify that every bore outside a sealing ring is blind
    # and that the full sealing land exists behind the seated TPU face rings.
    land_checks={}
    lid_probe=ring(-8,-8,68,52,6,2.4,d['seam_z']-1.01,.01)
    land_checks['lid_base']=assembly['base'].common(lid_probe).Volume/lid_probe.Volume
    for kind in ('usb','service_switch'):
        p=info['ports'][kind];aw,ah=p['opening_mm'];ow,oh=aw+8,ah+8
        probe=ring(-ow/2,-oh/2,ow,oh,3,2.4,-.01,.01)
        probe=face_mount(probe,p['side'],p['along_mm'],p['center_z_mm'],64 if p['side']=='X+' else 48)
        land_checks[kind+'_base']=assembly['base'].common(probe).Volume/probe.Volume
    for name,ratio in land_checks.items():check(ratio>.999,name+' sealing land not continuous')
    lobe_clearances={}
    for name,box in [('usb_cover',Part.makeBox(20,100,40,V(64.001,-30,-1))),
                     ('service_switch_cover',Part.makeBox(100,25,40,V(-20,48.001,-1)))]:
        projection=assembly['base'].common(box)
        gap=projection.distToShape(assembly[name])[0]
        lobe_clearances[name]=gap
        check(gap>=.5,name+' too close to exterior mounting/lid bosses')
    for name,seal in dict(lid=info['lid_seal'],**info['seals']).items():
        check(seal['free_volume_mm3']<seal['groove_volume_mm3'],name+' gasket has no expansion volume')
    # All lid bores stay outside the gasket; no screw tube crosses the dry cavity.
    gasket_plan=ring(-8,-8,68,52,6,2.4,0,1)
    for x,y in info['lid_screws']:
        check(gasket_plan.common(cyl(x,y,2.,0,1)).Volume<1e-6,'Lid screw breaks seal loop')
    # PCB screw heads remain inside the reserved mounting courtyards.
    for x,y in c['board']['holes']:
        head=cyl(x,y,2.,d['pcb_top'],1.5)
        for comp in components:
            check(head.common(comp['solid']).Volume<1e-5,'PCB screw head collides with '+comp['ref'])
    check(d['pcb_top']-2.5-3>=1.,'PTH tails too close to floor')
    return dict(passed=not errors,errors=errors,component_body_count=len(components),
                minimum_component_clearance=min(clearances,key=lambda x:x['gap_mm']),
                assembly_intersections=intersections,sealing_land_coverage=land_checks,cover_lobe_clearance_mm=lobe_clearances,
                dimensions=info,physical_status='UNTESTED: prototype; no IP or waterproof rating',
                pcb_source=c['board']['source_design'],pcb_sha256=c['board']['source_sha256'])


def orient(s,flip=False):
    s=s.copy()
    if flip:s.rotate(V(),V(1,0,0),180)
    box=s.BoundBox;s.translate(V(-box.XMin,-box.YMin,-box.ZMin))
    return s


def export(parts,assembly,pcb,components,c,report):
    doc=App.newDocument('OrionR5SealedEnclosure')
    for name,s in list(assembly.items())+[('PCB',pcb)]+[(f"Component_{i}_{p['ref']}",p['solid']) for i,p in enumerate(components)]:
        obj=doc.addObject('PartDesign::Feature',name);obj.Label=name.replace('_',' ');obj.Shape=s
        obj.addProperty('App::PropertyString','Qualification');obj.Qualification='Prototype; physical fit, sealing and thermal tests pending'
    doc.recompute();doc.saveAs(str(OUT/'Orion-R5-sealed-enclosure.FCStd'))
    manifest=[];mesh_report={}
    for name,item in parts.items():
        s=orient(item['shape'],item.get('flip',False))
        mesh=MeshPart.meshFromShape(Shape=s,LinearDeflection=.025,AngularDeflection=math.radians(6),Relative=False)
        if not mesh.isSolid():raise ValueError(name+' mesh not closed')
        # Consistently outward signed volume, one shell, no degenerate edges.
        if mesh.Volume<0:mesh.flipNormals()
        verts,faces=mesh.Topology;edges={};directed={}
        for face in faces:
            for i in range(3):
                a,b=face[i],face[(i+1)%3];key=tuple(sorted((a,b)))
                edges[key]=edges.get(key,0)+1;directed[key]=directed.get(key,0)+(1 if a<b else -1)
        if any(n!=2 for n in edges.values()) or any(directed.values()):raise ValueError(name+' nonmanifold or inconsistent mesh')
        delta=abs(mesh.Volume-s.Volume)/s.Volume
        if delta>.002:raise ValueError(name+' exceeds 0.2% tessellation volume tolerance')
        path=OUT/(name+'.stl');mesh.write(str(path))
        entry=dict(name=name,material=item['material'],path=path.name)
        for key in ('alternative_group','coupon'):
            if key in item:entry[key]=item[key]
        manifest.append(entry)
        mesh_report[name]=dict(watertight=True,oriented_manifold=True,vertices=len(verts),triangles=len(faces),
            volume_mm3=s.Volume,mesh_volume_relative_error=delta,print_bounds_mm=[s.BoundBox.XLength,s.BoundBox.YLength,s.BoundBox.ZLength],min_z_mm=s.BoundBox.ZMin,
            sha256=hashlib.sha256(path.read_bytes()).hexdigest())
    step=OUT/'Orion-R5-sealed-assembly.step'
    Part.makeCompound(list(assembly.values())).exportStep(str(step))
    readback=Part.Shape();readback.read(str(step))
    if not readback.isValid() or len(readback.Solids)!=len(assembly):raise ValueError('STEP readback invalid')
    report['step_readback']=dict(valid=True,solid_count=len(readback.Solids))
    report['meshes']=mesh_report
    (OUT/'print-manifest.json').write_text(json.dumps(dict(printer='Bambu Lab P2S 0.4 nozzle',parts=manifest,
        notes=['Rigid and TPU parts must be printed on separate plates.','Cable cartridges are alternatives; use exactly one.','Cable OD is not measured; select by physical fit.','No tested IP rating.']),indent=2)+'\n')
    (OUT/'sealed-contract.json').write_text(json.dumps(c,indent=2)+'\n')
    (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')


def render(assembly,pcb,components):
    import vtk
    from render_altium_r3 import mesh_actor
    for view in ('assembled','exploded'):
        ren=vtk.vtkRenderer();ren.SetBackground(.94,.96,.97);ren.SetUseFXAA(True)
        for name,shape in assembly.items():
            s=shape.copy()
            if view=='exploded':
                if name=='lid':s.translate(V(0,0,24))
                elif name=='lid_gasket':s.translate(V(0,0,12))
                elif name.startswith('usb'):s.translate(V(12 if 'gasket' in name else 20,0,0))
                elif name.startswith('service'):s.translate(V(0,12 if 'gasket' in name else 20,0))
                elif name.startswith('cable'):s.translate(V(-12,0,0))
            col=[231,163,48] if ('gasket' in name or 'blank' in name) else [45,83,99]
            ren.AddActor(mesh_actor(s,col))
        if view=='exploded':
            ren.AddActor(mesh_actor(pcb,[26,110,74]))
            for p in components:ren.AddActor(mesh_actor(p['solid'],p['rgb']))
        label=vtk.vtkTextActor();label.SetInput('ORION R5 / gasketed enclosure\n'+('Seated seals shown; hardware omitted' if view=='assembled' else 'Actual R5 PCB bodies / TPU in amber')+'\nPhysical sealing tests pending')
        label.SetPosition(24,24);label.GetTextProperty().SetFontSize(23);label.GetTextProperty().SetColor(.12,.2,.24);ren.AddActor2D(label)
        win=vtk.vtkRenderWindow();win.SetOffScreenRendering(1);win.SetSize(1400,1050);win.AddRenderer(ren)
        cam=ren.GetActiveCamera();cam.ParallelProjectionOn();cam.SetFocalPoint(26,18,22);cam.SetPosition(140,135,125);cam.SetViewUp(0,0,1);cam.SetParallelScale(78 if view=='exploded' else 65)
        ren.ResetCameraClippingRange();win.Render()
        capture=vtk.vtkWindowToImageFilter();capture.SetInput(win);capture.ReadFrontBufferOff();capture.Update()
        writer=vtk.vtkPNGWriter();writer.SetFileName(str(OUT/('preview-'+view+'.png')));writer.SetInputConnection(capture.GetOutputPort());writer.Write();win.Finalize()


def main():
    if os.environ.get('ORION_DEBUG_STACK'):
        faulthandler.dump_traceback_later(180,repeat=True)
    c=json.loads((ROOT/'hardware/altium-r5/enclosure/mechanical-contract.json').read_text('utf8'))
    c=sync_design(c,ROOT/'hardware/altium-r5/orion-r5-design.json')
    c.update(revision='R5 sealed printable prototype v1',frozen=False,
        environmental_claim='Screw-fastened sealed design intent; no verified IP, saltwater, pressure or waterproof rating.',
        pending=['Measure HangTon B0DTHSNSHS cable OD and select sleeve','Print insert/cable coupon','Verify actual PCB/module/USB plug fit',
                 'Empty-case leak and cable pull tests','Powered thermal and RF acceptance in sealed case'])
    c['coordinate_system']='PCB lower-left XY; PCB underside at Z=8.0 mm; assembled case bottom at Z=0'
    c['branding']['depth']=.4
    c['case'].update(floor=3.0,lid=3.2,standoff_height=5.0,above_pcb_clearance=20.4,seam_gap=0.,
                     wall=8.0,pcb_side_clearance=4.0,corner_radius=7.,lid_fit_clearance=.4,lid_lip_depth=1.8,lid_lip_wall=1.2)
    c['case']['inner_corner_radius']=3.
    c['mounting']=dict(enabled=True,side='Y',hole_diameter=3.6,slot_extra_length=2.4,
        ear_width=16.,ear_thickness=4.,centers=[[10.,-20.],[10.,56.]],pitch_mm=76.,
        negative_y_projection_mm=13.,positive_y_projection_mm=15.,description='Exterior mounting ears; no penetration into sealed cavity')
    c['fasteners']=dict(method='Independent PCB screws; lid screws outside the continuous seal',
        lid=dict(count=6,screw='M3x8',clearance=3.4,insert='ruthex RX-M3x5.7',pilot=4.,pilot_depth=6.7,engagement=4.8),
        covers=dict(count=6,screw='M3x8',clearance=3.4,insert='ruthex RX-M3x5.7',pilot=4.,pilot_depth=6.7,engagement=4.8),
        pcb=dict(count=4,screw='M2x5',insert='ruthex RX-M2x4',pilot=3.2,pilot_depth=4.6,engagement=3.4,tip_clearance=1.2))
    c['cable']=dict(mode='unsplit_compression_cartridge',product='HangTon B0DTHSNSHS, male to bare wire, 1 m',
        url='https://www.amazon.de/dp/B0DTHSNSHS',outside_diameter_measured=False,nominal_options_mm=[5,5.5,6,6.5,7],side='X-',center_along_edge=18.,center_z=14.)
    c['printing'].update(printer='Bambu Lab P2S',nozzle=.4,layer_height=.2,perimeters=5,infill_percent=35,
        rigid='PETG',gaskets='TPU 95A, separate external-spool plate, 100% infill',lid_orientation='outside face on bed; gasket-contact plane upward',
        fit_note='Print fit_coupon first; inspect horizontal pilot/socket roofs on base too')
    print('Building enclosure geometry',flush=True)
    parts,assembly,pcb,d,info=build(c)
    c['sealed_design']=info
    components=component_solids(c,d)
    print('Validating solids and actual PCB bodies',flush=True)
    report=validate(parts,assembly,pcb,components,d,info,c)
    (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    if not report['passed']:
        print(json.dumps(report,indent=2));raise SystemExit(2)
    print('Exporting validated meshes and STEP',flush=True)
    export(parts,assembly,pcb,components,c,report);render(assembly,pcb,components)
    faulthandler.cancel_dump_traceback_later()
    print(json.dumps(dict(passed=True,parts=len(parts),component_bodies=len(components),closest=report['minimum_component_clearance'],output=str(OUT)),indent=2))


if __name__=='__main__':main()
