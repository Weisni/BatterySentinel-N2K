"""Render assembly-manual figures from the delivered R5 CAD and print meshes.

Run with FreeCAD 1.1/bin/python.exe. No enclosure geometry is rebuilt or edited.
Hardware heads and the neutral cable are explicitly illustrative. Cropped wall
figures are intersections of the delivered base, not replacement printable parts.
"""
from __future__ import annotations
import hashlib
import json
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'hardware/altium-r5/enclosure/sealed-print'
OUT = ROOT / 'docs/enclosure-manual-assets/cad'
FC = Path('C:/Program Files/FreeCAD 1.1')
sys.path.insert(0, str(FC / 'lib'))
_dll = os.add_dll_directory(str(FC / 'bin'))
os.environ['FREECAD_USER_HOME'] = str(SOURCE / 'freecad-profile')
import FreeCAD as App
import Part
import vtk

V = App.Vector
WIDTH, HEIGHT = 2000, 1400
NAVY = (64, 105, 129)
AMBER = (235, 163, 44)
METAL = (181, 192, 201)
GREEN = (34, 121, 89)
NOTES = {}
SHAPES = {}
MESHES = {}


def translated(shape, delta):
    s = shape.copy()
    s.translate(V(*delta))
    return s


def normalized(shape):
    b = shape.BoundBox
    return translated(shape, (-b.XMin, -b.YMin, -b.ZMin))


def polydata(shape):
    vertices, triangles = shape.tessellate(.025)
    points = vtk.vtkPoints()
    for p in vertices:
        points.InsertNextPoint(p.x, p.y, p.z)
    cells = vtk.vtkCellArray()
    for triangle in triangles:
        cells.InsertNextCell(3)
        for p in triangle:
            cells.InsertCellPoint(p)
    mesh = vtk.vtkPolyData()
    mesh.SetPoints(points)
    mesh.SetPolys(cells)
    return mesh


def mesh(name):
    if name not in MESHES:
        reader = vtk.vtkSTLReader()
        reader.SetFileName(str(SOURCE / (name + '.stl')))
        reader.Update()
        MESHES[name] = reader.GetOutput()
    return MESHES[name]


def actor(source, colour, metal=False):
    data = source if isinstance(source, vtk.vtkPolyData) else polydata(source)
    normal = vtk.vtkPolyDataNormals()
    normal.SetInputData(data)
    normal.SetFeatureAngle(35)
    normal.SplittingOn()
    normal.ConsistencyOn()
    normal.AutoOrientNormalsOn()
    mapper = vtk.vtkPolyDataMapper()
    mapper.SetInputConnection(normal.GetOutputPort())
    a = vtk.vtkActor()
    a.SetMapper(mapper)
    p = a.GetProperty()
    p.SetColor(*(c / 255 for c in colour))
    p.SetInterpolationToPhong()
    p.SetAmbient(.29)
    p.SetDiffuse(.71)
    p.SetSpecular(.38 if metal else .10)
    p.SetSpecularPower(35 if metal else 15)
    return a


def renderer(window, viewport=(0, 0, 1, 1)):
    r = vtk.vtkRenderer()
    r.SetViewport(*viewport)
    r.SetBackground(1, 1, 1)
    r.SetUseFXAA(True)
    r.SetUseSSAO(True)
    r.SetSSAORadius(1.8)
    r.SetSSAOBias(.025)
    r.SetSSAOKernelSize(64)
    r.SetSSAOBlur(True)
    window.AddRenderer(r)
    return r


def camera(r, direction, margin=1.1):
    r.ResetCamera()
    c = r.GetActiveCamera()
    focus = c.GetFocalPoint()
    c.ParallelProjectionOn()
    c.SetPosition(*(focus[i] + direction[i] * 300 for i in range(3)))
    c.SetViewUp(0, 0, 1)
    if direction[0] == direction[1] == 0:
        c.SetViewUp(0, 1, 0)
    r.ResetCamera()
    c.SetParallelScale(c.GetParallelScale() * margin)
    r.ResetCameraClippingRange()


def window():
    w = vtk.vtkRenderWindow()
    w.SetOffScreenRendering(1)
    w.SetSize(WIDTH, HEIGHT)
    w.SetMultiSamples(0)
    return w


def save(w, name):
    w.Render()
    cap = vtk.vtkWindowToImageFilter()
    cap.SetInput(w)
    cap.ReadFrontBufferOff()
    cap.Update()
    writer = vtk.vtkPNGWriter()
    writer.SetFileName(str(OUT / (name + '.png')))
    writer.SetInputConnection(cap.GetOutputPort())
    writer.Write()
    print(name, flush=True)


def pixel(r, p):
    r.SetWorldPoint(*p, 1)
    r.WorldToDisplay()
    x, y, _ = r.GetDisplayPoint()
    return [round(x), round(HEIGHT-y)]


def finish(w, r, name, description, points=None, extra=None):
    save(w, name)
    NOTES[name] = {'file': name+'.png', 'description': description,
                   'pixel_coordinates': 'origin top-left; image 2000 by 1400 pixels',
                   'annotations': {k: pixel(r, p) for k, p in (points or {}).items()}}
    if extra:
        NOTES[name].update(extra)
    w.Finalize()


def kit(name, names, material, cols, rows):
    # Compose independently rendered CAD viewports. The VTK SSAO pass does not
    # support neighbouring viewports reliably on this runtime.
    from PIL import Image
    sheet = Image.new('RGB',(WIDTH,HEIGHT),'white')
    (OUT/'parts').mkdir(exist_ok=True)
    panels = []
    for i, part in enumerate(names):
        col, row = i % cols, i // cols
        w = window()
        left,top=round(col*WIDTH/cols),round(row*HEIGHT/rows)
        tile_width=round((col+1)*WIDTH/cols)-left
        tile_height=round((row+1)*HEIGHT/rows)-top
        w.SetSize(tile_width,tile_height)
        r = renderer(w)
        if part == 'lid':
            a = actor(SHAPES[part], material)
        else:
            a = actor(mesh(part), material)
        r.AddActor(a)
        direction = (.1,-.20,1) if part=='base' else ((-.65,-.6,1) if part=='fit_coupon' else (0,-.52,1))
        camera(r, direction, margin=1.14)
        save(w,'parts/'+part)
        with Image.open(OUT/'parts'/(part+'.png')) as tile:
            sheet.paste(tile,(left,top))
        w.Finalize()
        panels.append({'part': part, 'centre_px': [round((col+.5)*WIDTH/cols), round((row+.5)*HEIGHT/rows)],
                       'caption_px': [round((col+.5)*WIDTH/cols), round((row+.90)*HEIGHT/rows)],
                       'viewport_px': [round(col*WIDTH/cols), round(row*HEIGHT/rows),
                                       round((col+1)*WIDTH/cols), round((row+1)*HEIGHT/rows)]})
    sheet.save(OUT/(name+'.png'))
    NOTES[name] = {'file': name+'.png', 'description': 'Actual delivered parts; panels are individually scaled for clarity.',
                   'panels': panels, 'printed_part_count': len(names)}


def pcb_actors(r, screws=True):
    r.AddActor(actor(SHAPES['PCB'], GREEN))
    from altium_3d import bodies_for
    design_path = ROOT / 'hardware/altium-r5/orion-r5-design.json'
    if hashlib.sha256(design_path.read_bytes()).hexdigest() != CONTRACT['board']['source_sha256']:
        raise ValueError('Current PCB differs from the delivered enclosure contract')
    design = json.loads(design_path.read_text('utf8'))
    index = 0
    for component in design['components']:
        for body in bodies_for(component):
            key = f'Component_{index}_{component["ref"]}'
            if key not in SHAPES:
                raise ValueError('CAD component naming differs from final PCB body source')
            r.AddActor(actor(SHAPES[key], body.rgb))
            index += 1
    if screws:
        for x, y in CONTRACT['board']['holes']:
            head = Part.makeCylinder(1.9, 1.4, V(x,y,9.6))
            # Recess is illustrative; head diameter is within the specified <=4 mm envelope.
            cut = Part.makeBox(2.3,.55,.6,V(x-1.15,y-.275,10.5))
            cut2 = Part.makeBox(.55,2.3,.6,V(x-.275,y-1.15,10.5))
            r.AddActor(actor(head.cut(cut.fuse(cut2)), METAL, True))


def base_figures():
    for name, with_pcb in [('base-inserts', False), ('pcb-installation', True)]:
        w = window()
        r = renderer(w)
        r.AddActor(actor(SHAPES['base'],NAVY))
        if with_pcb:
            pcb_actors(r)
        camera(r, (.11,-.20,1),margin=1.02)
        points = {f'lid_pilot_{i+1}': (x,y,30) for i,(x,y) in enumerate(CONTRACT['sealed_design']['lid_screws'])}
        points.update({f'pcb_mount_{i+1}': (x,y,11 if with_pcb else 8) for i,(x,y) in enumerate(CONTRACT['board']['holes'])})
        points['lid_seal_groove']=(42,-6.4,29)
        desc = ('Final base and actual R5 PCB/component bodies, with four illustrative 3.8 mm M2 screw heads.' if with_pcb else
                'Final base viewed almost from above: six lid insert pilots and four independent PCB insert pilots.')
        finish(w,r,name,desc,points,{'hardware_illustrative': with_pcb})


def lid_figure():
    w = window()
    r = renderer(w)
    r.AddActor(actor(SHAPES['base'],NAVY))
    pcb_actors(r)
    gasket = translated(SHAPES['lid_gasket'], (0,0,40))
    lid = translated(SHAPES['lid'], (0,0,88))
    r.AddActor(actor(gasket,AMBER))
    r.AddActor(actor(lid,NAVY))
    camera(r,(.75,-1,1),margin=1.01)
    finish(w,r,'lid-exploded','Final base, PCB, lid seal and lid separated vertically; service covers omitted for clarity.',
           {'base':(26,18,15),'pcb':(26,18,12),'gasket':(26,-6.8,69.5),'lid':(26,18,119),
            'gasket_corner':(-6,-6,69.5),'lid_pilot_1':(-10,-10,30)},
           {'exploded_offsets_mm':{'lid':[0,0,88],'lid_gasket':[0,0,40]},'hardware_illustrative':True})


def cover_figure(kind):
    # Delivered cover STLs have the grooved mating face upward.
    w = window()
    r = renderer(w)
    cover_mesh = mesh(kind+'_cover')
    cover = actor(cover_mesh,NAVY)
    r.AddActor(cover)
    b = cover_mesh.GetBounds()
    cx, cy = (b[0]+b[1])/2, (b[2]+b[3])/2
    gm = mesh(kind+'_gasket')
    gb = gm.GetBounds()
    seal = actor(gm,AMBER)
    seal.SetPosition(cx-(gb[0]+gb[1])/2,cy-(gb[2]+gb[3])/2,9)
    r.AddActor(seal)
    camera(r,(.35,-.65,1),margin=1.01)
    finish(w,r,kind+'-gasket','Actual cover groove and matching free-height 1.2 mm TPU gasket, separated for visibility. Mating face upward.',
           {'cover':(cx,cy,2),'gasket':(cx,cy-(gb[3]-gb[2])/2+1.2,10.2),'groove':(cx,cy-(gb[3]-gb[2])/2+1,3.1)},
           {'parts':[kind+'_cover',kind+'_gasket'],'exploded_not_print_orientation':True})


def cable_figure():
    w=window()
    r=renderer(w)
    # A real section of the cable-entry wall, preserving socket shoulder and both pilots.
    wall=SHAPES['base'].common(Part.makeBox(8,38,28,V(-12,-1,0)))
    r.AddActor(actor(wall,NAVY))
    cap=translated(SHAPES['cable_pressure_cap'],(-35,0,0))
    r.AddActor(actor(cap,NAVY))
    from build_orion_r5_sealed_enclosure import face_mount
    sleeve_data=CONTRACT['sealed_design']['cable_seals']['cable_seal_6p0mm']
    sleeve=Part.makeCylinder(sleeve_data['free_outer_diameter_mm']/2,7)
    sleeve=sleeve.cut(Part.makeCylinder(sleeve_data['free_bore_mm']/2,7))
    sleeve=face_mount(sleeve,'X-',18,14,-26)
    r.AddActor(actor(sleeve,AMBER))
    # Neutral straight cable reference: smaller than the free sleeve bore so no
    # rendered interference pretends to model compressed TPU. No connector/wiring.
    cable=Part.makeCylinder(2.5,64,V(-64,18,14),V(1,0,0))
    r.AddActor(actor(cable,(126,135,140)))
    camera(r,(-.72,-1,.90),margin=1.01)
    finish(w,r,'cable-exploded','Cropped actual cable-entry wall with its socket shoulder, actual pressure cap and nominal 6 mm option sleeve; neutral unconnected 5 mm cable reference. Expanded spacing; no deformation simulation.',
           {'pressure_cap':(-48,13,14),'sleeve':(-29,18,19.5),'socket_shoulder':(-6,18,18.8),
            'neutral_cable':(-59,18,14),'pilot_1':(-12,7,14),'pilot_2':(-12,29,14)},
           {'cutaway':True,'cable_illustrative':True,'cable_diameter_not_product_measurement':True,
            'sleeve_geometry':'6.0 mm label; 5.8 mm free bore; actual product cable OD remains unknown'})


def assembled_figure():
    w=window()
    r=renderer(w)
    parts=['base','lid','lid_gasket','usb_cover','usb_gasket',
           'service_switch_cover','service_switch_gasket','cable_pressure_cap','cable_blank']
    for name in parts:
        colour=AMBER if ('gasket' in name or 'blank' in name) else ((91,140,166) if name=='lid' else (75,118,145))
        r.AddActor(actor(SHAPES[name],colour))
    camera(r,(1,.40,1.80),margin=1.03)
    finish(w,r,'assembled','All nine delivered assembly solids in their original seated CAD positions. USB and switch covers fitted; solid cable blank installed. Fasteners and electronics omitted. Seated gaskets are concealed by the rigid parts.',
           {'lid':(26,18,33.2),'usb_cover':(67.2,20,12.35),'service_switch_cover':(39,51.2,10.3),
            'mount_ear_positive_y':(10,56,4),'mount_ear_negative_y':(10,-20,4)},
           {'assembly_solid_count':len(parts),'parts':parts,'hardware_omitted':True})


def main():
    global CONTRACT
    OUT.mkdir(parents=True,exist_ok=True)
    CONTRACT=json.loads((SOURCE/'sealed-contract.json').read_text('utf8'))
    source=SOURCE/'Orion-R5-sealed-enclosure.FCStd'
    doc=App.openDocument(str(source))
    SHAPES.update({obj.Name:obj.Shape.copy() for obj in doc.Objects})
    kit('rigid-kit',['base','lid','usb_cover','service_switch_cover','cable_pressure_cap','fit_coupon'],NAVY,3,2)
    kit('flexible-kit',['lid_gasket','usb_gasket','service_switch_gasket','cable_blank','cable_seal_5p0mm','cable_seal_5p5mm','cable_seal_6p0mm','cable_seal_6p5mm','cable_seal_7p0mm'],AMBER,3,3)
    base_figures()
    lid_figure()
    cover_figure('usb')
    cover_figure('service_switch')
    cable_figure()
    assembled_figure()
    (OUT/'image-notes.json').write_text(json.dumps({'source_cad':str(source.relative_to(ROOT)),
        'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'images':NOTES},indent=2)+'\n',encoding='utf8')
    App.closeDocument(doc.Name)


if __name__=='__main__':
    main()
