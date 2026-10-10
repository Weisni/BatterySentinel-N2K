"""R5 STEP and product renders from the final design and saved native PCB.

Run with C:/Program Files/FreeCAD 1.1/bin/python.exe. Release mode requires
--pcb and --routing, reads actual saved TrueType outlines without replacing
fonts, and rejects stale lettering. --geometry-check writes a temporary proof
of the current model only; it produces neither final renders nor release STEP.
Historical R3/R4 source and artifacts are never modified.
"""
from __future__ import annotations

import argparse
from dataclasses import asdict
import hashlib
import json
import math
import os
from pathlib import Path

# A renderer failure must return an error, never put an OS crash dialog above
# the user's active Altium window. This setting affects this process only.
if os.name == 'nt':
    import ctypes
    ctypes.windll.kernel32.SetErrorMode(0x0001 | 0x0002 | 0x8000)

import FreeCAD as App
import Part
import vtk
from shapely.geometry import Polygon
from shapely.ops import unary_union

from altium_3d import bodies_for
from altium_3d_geometry import drill_solid, world_drill
from altium_pcb import footprint
from export_jlcpcb_r5 import read_overlay_artwork, validate_text_declarations
from r5_branding import polygons, region_data
from r5_geometry import board_geometry
from render_altium_r3 import mesh_actor, solid, transformed

STEM = 'BatterySentinel-N2K-Orion-R5'
MASK = (28, 103, 71)
GOLD = (192, 158, 66)
INK = (229, 238, 225)


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def wire(coords, z):
    points = [App.Vector(x, y, z) for x, y in coords]
    if (points[0]-points[-1]).Length > 1e-10:
        points.append(points[0])
    return Part.makePolygon(points)


def extrusion(polygon, z, height):
    shape = Part.Face(wire(polygon.exterior.coords, z)).extrude(App.Vector(0, 0, height))
    for hole in polygon.interiors:
        shape = shape.cut(Part.Face(wire(hole.coords, z)).extrude(App.Vector(0, 0, height)))
    if not shape.isValid() or not shape.Solids:
        raise ValueError('Invalid extruded outline')
    return shape


def drills_for(data, routing):
    result=[]
    for c in data['components']:
        for p in footprint(c).pads:
            if p.drill:result.append(world_drill(c,vars(p)))
        for hole in c.get('pcb_footprint',{}).get('holes',[]):
            result.append(world_drill(c,hole))
    for h in data['board'].get('holes_mm',[]):
        x,y,d=(h['x'],h['y'],h['diameter_mm']) if isinstance(h,dict) else (*h,data['board'].get('hole_diameter_mm',3.2))
        result.append((x,y,d,0,0))
    for via in routing.get('vias',[]):
        result.append((via['x'],via['y'],via['drill'],0,0))
    return result


def make_carrier(data, routing):
    profile=board_geometry(data)
    if profile.geom_type!='Polygon':raise ValueError('Carrier must be one connected polygon')
    thickness=data['board'].get('thickness_mm',1.6)
    carrier=extrusion(profile,-thickness,thickness)
    drills=drills_for(data,routing)
    holes=[]
    for x,y,d,length,angle in drills:
        cutter=drill_solid(x,y,d,-thickness-.1,thickness+.2,length,angle)
        carrier=carrier.cut(cutter)
        # Use identical round-ended slot geometry for independent volume check.
        if length>d:
            from shapely.geometry import LineString
            a=math.radians(angle);span=(length-d)/2
            shape=LineString([(x-span*math.cos(a),y-span*math.sin(a)),
                              (x+span*math.cos(a),y+span*math.sin(a))]).buffer(d/2,quad_segs=128)
        else:
            from shapely.geometry import Point
            shape=Point(x,y).buffer(d/2,quad_segs=128)
        holes.append(shape)
    if not carrier.isValid() or len(carrier.Solids)!=1:
        raise ValueError('Invalid or disconnected drilled carrier')
    expected_area=profile.difference(unary_union(holes)).area
    volume_error=abs(carrier.Volume-expected_area*thickness)
    # Circular hole tessellation only affects this independent Shapely estimate;
    # the STEP carrier itself uses exact OCCT circular/slot holes.
    if volume_error>.003:
        raise ValueError(f'Carrier profile/drill volume differs by {volume_error:.6f}mm3')
    return carrier,drills,{'profile_area_mm2':profile.area,'internal_cutouts':len(profile.interiors),
        'drill_count':len(drills),'board_volume_mm3':carrier.Volume,
        'independent_profile_drill_volume_error_mm3':volume_error,
        'board_single_valid_solid':True}


def make_components(data):
    result=[]
    for c in data['components']:
        if not c.get('bodies_3d'):
            raise ValueError('R5 requires explicit native body geometry; missing '+c['ref'])
        local=[];world=[]
        for body in bodies_for(c):
            shape=solid(body)
            if not shape.isValid() or len(shape.Solids)!=1:
                raise ValueError('Invalid component solid '+c['ref']+'/'+body.name)
            local.append((body,shape))
            world.append((body,transformed(shape.copy(),c)))
        result.append({'part':c,'local':local,'world':world})
    m=next(c for c in data['components'] if c['ref']=='MCU1')
    if any('header insulator' in b.name.lower() or b.name.lower().startswith('header ') for b in bodies_for(m)):
        raise ValueError('Original R5 SuperMini must have direct-solder bodies, no header substitution')
    return result


def capsule(x1,y1,x2,y2,width,z,height):
    length=math.hypot(x2-x1,y2-y1)
    return drill_solid((x1+x2)/2,(y1+y2)/2,width,z,height,length+width,
                       math.degrees(math.atan2(y2-y1,x2-x1)))


def cut_drills(shape,drills,z,height):
    for x,y,d,length,angle in drills:
        b=shape.BoundBox;r=max(d,length)/2
        if b.XMin-r<=x<=b.XMax+r and b.YMin-r<=y<=b.YMax+r:
            shape=shape.cut(drill_solid(x,y,d,z-.01,height+.02,length,angle))
    return shape


def pad_solids(data):
    thickness=data['board'].get('thickness_mm',1.6);result=[]
    for c in data['components']:
        for p in footprint(c).pads:
            for z in ([.025,-thickness-.060] if p.drill else [.025]):
                if p.shape=='ROUND' and abs(p.sx-p.sy)<1e-8:
                    shape=Part.makeCylinder(p.sx/2,.035,App.Vector(p.x,p.y,z))
                elif p.shape in ('ROUND','OVAL'):
                    # Oblong pads are capsules in their major axis.
                    shape=drill_solid(p.x,p.y,min(p.sx,p.sy),z,.035,max(p.sx,p.sy),0 if p.sx>=p.sy else 90)
                else:
                    shape=Part.makeBox(p.sx,p.sy,.035,App.Vector(p.x-p.sx/2,p.y-p.sy/2,z))
                if p.drill:
                    shape=shape.cut(drill_solid(p.x,p.y,p.drill,z-.01,.055,p.drill_slot_length_mm,p.drill_slot_angle_deg))
                result.append(transformed(shape,c))
    return result


def overlay_solids(data,native_pcb):
    overlay,evidence=read_overlay_artwork(native_pcb)
    validate_text_declarations(data,evidence)
    thickness=data['board'].get('thickness_mm',1.6)
    shapes={}
    for ext,g in overlay.items():
        z=.050 if ext=='GTO' else -thickness-.064
        shapes[ext]=[extrusion(p,z,.012) for p in polygons(g)]
    evidence['font_substitution']=False
    return shapes,evidence


def scene(data,routing,carrier,drills,components,pads,overlays):
    t=data['board'].get('thickness_mm',1.6)
    actors=[mesh_actor(carrier,MASK)]
    for r in routing.get('regions',[]):
        z=.010 if r['layer']=='TOP' else -t-.026
        shape=extrusion(Polygon(r['points'],r.get('holes',[])),z,.012)
        shape=cut_drills(shape,drills,z,.012)
        if not shape.isNull() and shape.Faces:actors.append(mesh_actor(shape,(29,107,74)))
    for track in routing.get('tracks',[]):
        z=.012 if track['layer']=='TOP' else -t-.028
        shape=capsule(track['x1'],track['y1'],track['x2'],track['y2'],track['width'],z,.016)
        shape=cut_drills(shape,drills,z,.016)
        if not shape.isNull() and shape.Faces:actors.append(mesh_actor(shape,(31,111,76)))
    for shape in pads:actors.append(mesh_actor(shape,GOLD,True))
    for c in components:
        for body,shape in c['world']:
            metal=max(body.rgb)-min(body.rgb)<30 and sum(body.rgb)>400 or body.rgb in ((207,163,58),GOLD)
            actors.append(mesh_actor(shape,body.rgb,metal))
    for via in routing.get('vias',[]):
        for z in [.020,-t-.045]:
            # Tented mask closes the visible via opening, while the mechanical
            # STEP retains its drill. This matches the actual fabrication mask.
            actors.append(mesh_actor(Part.makeCylinder(via['diameter']/2,.025,App.Vector(via['x'],via['y'],z)),MASK))
    for shapes in overlays.values():
        if shapes:actors.append(mesh_actor(Part.makeCompound(shapes),INK))
    return actors


def render_images(data,actors,out,size):
    w,h=data['board']['width_mm'],data['board']['height_mm']
    renderer=vtk.vtkRenderer();renderer.SetBackground(.935,.946,.953)
    renderer.SetBackground2(.985,.988,.991);renderer.GradientBackgroundOn();renderer.SetUseFXAA(True)
    render_steps=vtk.vtkRenderStepsPass();ao=vtk.vtkSSAOPass();ao.SetDelegatePass(render_steps)
    ao.SetRadius(2.2);ao.SetBias(.12);ao.SetKernelSize(128);ao.BlurOn();renderer.SetPass(ao)
    for actor in actors:renderer.AddActor(actor)
    renderer.AutomaticLightCreationOff()
    for position,intensity,color in [((w*.1,-h,80),.82,(1,.97,.91)),((w*2,h,50),.48,(.86,.92,1)),((-w,h*2,25),.35,(1,1,1))]:
        light=vtk.vtkLight();light.SetPosition(*position);light.SetFocalPoint(w/2,h/2,0)
        light.SetIntensity(intensity);light.SetColor(*color);light.SetLightTypeToSceneLight();renderer.AddLight(light)
    window=vtk.vtkRenderWindow();window.SetOffScreenRendering(1);window.SetMultiSamples(8)
    window.SetSize(*size);window.AddRenderer(renderer)
    camera=renderer.GetActiveCamera();camera.ParallelProjectionOn();camera.SetFocalPoint(w/2,h/2,2.1)
    camera.SetParallelScale(max(w/1.55,h*.88))
    views={
        'PCB-R5-3D-Isometrisch.png':((w/2-60,h/2-80,82),(0,0,1)),
        'PCB-R5-3D-Oberseite.png':((w/2,h/2,120),(0,1,0)),
        'PCB-R5-3D-Unterseite.png':((w/2,h/2,-120),(0,1,0)),
        'PCB-R5-3D-Unterseite-Isometrisch.png':((w/2-50,h/2-80,-90),(0,0,-1)),
    }
    saved=[]
    for name,(position,up) in views.items():
        camera.SetPosition(*position);camera.SetViewUp(*up);renderer.ResetCameraClippingRange()
        for light in renderer.GetLights():
            x,y,z=light.GetPosition();light.SetPosition(x,y,-abs(z) if position[2]<0 else abs(z))
        window.Render();capture=vtk.vtkWindowToImageFilter();capture.SetInput(window)
        capture.SetInputBufferTypeToRGB();capture.ReadFrontBufferOff();capture.Update()
        writer=vtk.vtkPNGWriter();writer.SetFileName(str(out/name));writer.SetInputConnection(capture.GetOutputPort());writer.Write()
        saved.append(name)
    window.Finalize()
    return {'images':saved,'size_pixels':list(size),'actors':len(actors),
            'renderer':'FreeCAD/OCCT solids and VTK offscreen depth-buffer rendering'}


def export_models(data,carrier,components,pads,overlays,out):
    models=out/'models';models.mkdir(parents=True,exist_ok=True)
    objects=[carrier];manifest=[]
    for entry in components:
        c=entry['part'];ref=c['ref'];local=Part.makeCompound([shape for _,shape in entry['local']])
        local.exportStep(str(models/(ref+'.step')))
        bodies=[asdict(body) for body,_ in entry['local']]
        (models/(ref+'.model.json')).write_text(json.dumps({'ref':ref,'units':'mm','placement':c['pcb'],
            'model_class':'same local approximate envelopes as native Altium bodies','bodies':bodies},indent=2)+'\n',encoding='utf8')
        objects.extend(shape for _,shape in entry['world'])
        manifest.append({'ref':ref,'body_count':len(bodies),'file':ref+'.step','source':c.get('datasheet'),
                         'local_geometry_sha256':sha(models/(ref+'.model.json'))})
    carrier.exportStep(str(models/(STEM+'-carrier.step')))
    objects.extend(pads)
    for shapes in overlays.values():objects.extend(shapes)
    assembly=Part.makeCompound(objects);path=models/(STEM+'-assembly.step');assembly.exportStep(str(path))
    back=Part.read(str(path))
    volume_error=abs(back.Volume-assembly.Volume)
    if not back.isValid() or len(back.Solids)!=len(assembly.Solids) or volume_error>max(.001,assembly.Volume*1e-8):
        raise ValueError('Assembly STEP round-trip shape/solid-count/volume validation failed')
    result={'assembly':str(path.relative_to(out)),'carrier':str((models/(STEM+'-carrier.step')).relative_to(out)),
        'components':manifest,'body_count':sum(c['body_count'] for c in manifest),
        'step_readback_valid':True,'step_readback_solids':len(back.Solids),'step_volume_error_mm3':volume_error,
        'assembly_envelope_mm':[back.BoundBox.XLength,back.BoundBox.YLength,back.BoundBox.ZLength],
        'color':'PNG/nativeAltium bodies retain colors; portable STEP contains neutral solids.',
        'mechanical_origin':'Carrier top z=0, board lower face z=-thickness; component STEP files use footprint-local coordinates',
        'interpretation':'Geometry follows final design bodies exactly. Supplier-certified models/physical sample tolerances are not implied.'}
    (models/'manifest.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
    return result


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('design',type=Path);p.add_argument('--routing',type=Path);p.add_argument('--pcb',type=Path)
    p.add_argument('--output',type=Path,required=True);p.add_argument('--geometry-check',action='store_true')
    p.add_argument('--skip-images',action='store_true');p.add_argument('--size',type=int,nargs=2,default=[2200,1550])
    args=p.parse_args()
    if not args.geometry_check and (not args.routing or not args.pcb):p.error('Release output requires --routing and saved native --pcb')
    data=json.loads(args.design.read_text('utf8'));routing=json.loads(args.routing.read_text('utf8')) if args.routing else {}
    if data.get('panelization'):raise ValueError('R5 renderer models one product board, not a manufacturing panel')
    out=args.output;out.mkdir(parents=True,exist_ok=True)
    inputs={'design':str(args.design.resolve()),'design_sha256':sha(args.design)}
    if args.routing:inputs.update(routing=str(args.routing.resolve()),routing_sha256=sha(args.routing))
    if args.pcb:inputs.update(native_pcb=str(args.pcb.resolve()),native_pcb_sha256=sha(args.pcb))
    carrier,drills,geometry=make_carrier(data,routing);components=make_components(data)
    result={'revision':'R5','inputs':inputs,'geometry':geometry,'component_count':len(components),
            'component_body_count':sum(len(c['local']) for c in components),'geometry_only':args.geometry_check}
    if args.geometry_check:
        result['passed']=True
        (out/'geometry-check.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
    else:
        overlays,evidence=overlay_solids(data,args.pcb);pads=pad_solids(data)
        result['native_typography']={k:evidence[k] for k in ('source_sha256','text_count','cache_groups','overlay_primitive_counts','font_substitution','scope')}
        result['step']=export_models(data,carrier,components,pads,overlays,out)
        if not args.skip_images:result['render']=render_images(data,scene(data,routing,carrier,drills,components,pads,overlays),out,args.size)
        # All artifacts in this batch must refer to the same frozen input bytes.
        for key,path in [('design',args.design),('routing',args.routing),('native_pcb',args.pcb)]:
            if sha(path)!=inputs[key+'_sha256']:raise ValueError('Input changed during rendering: '+key)
        result['passed']=True
        result['output_sha256']={str(f.relative_to(out)):sha(f) for f in out.rglob('*') if f.is_file() and f.suffix in ('.png','.step')}
        (out/'native-artwork-readback.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf8')
        (out/'3D-render-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
    print(json.dumps(result,indent=2))


if __name__=='__main__':main()
