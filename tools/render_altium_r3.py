"""Render the real R3 package/board geometry with FreeCAD and offscreen VTK.

Run with the Python bundled with FreeCAD 1.1 (includes OCCT and VTK):
  python tools/render_altium_r3.py design.json --routing routing.json --output out
No AI artwork, stock models, screenshots, or imaginary components are used.
The generated package envelopes are the same geometry as Altium's 3D bodies.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

import FreeCAD as App
import Part
import vtk

from altium_3d import bodies_for
from altium_pcb import footprint, transform
from altium_3d_geometry import rounded_carrier, drill_solid, world_drill
from export_jlcpcb_r4 import silk_segments


def solid(body):
    vertices = [App.Vector(x, y, body.z0) for x, y in body.outline]
    return Part.Face(Part.makePolygon(vertices+[vertices[0]])).extrude(App.Vector(0, 0, body.z1-body.z0))


def mesh_actor(shape, rgb, metal=False):
    vertices, faces = shape.tessellate(.04)
    points = vtk.vtkPoints()
    for vertex in vertices:
        points.InsertNextPoint(vertex.x, vertex.y, vertex.z)
    cells = vtk.vtkCellArray()
    for face in faces:
        cells.InsertNextCell(3)
        for index in face:
            cells.InsertCellPoint(index)
    poly = vtk.vtkPolyData()
    poly.SetPoints(points)
    poly.SetPolys(cells)
    normals = vtk.vtkPolyDataNormals()
    normals.SetInputData(poly)
    normals.SetFeatureAngle(45)
    normals.ConsistencyOn()
    normals.AutoOrientNormalsOn()
    normals.SplittingOn()
    normals.Update()
    mapper = vtk.vtkPolyDataMapper()
    mapper.SetInputConnection(normals.GetOutputPort())
    actor = vtk.vtkActor()
    actor.SetMapper(mapper)
    prop = actor.GetProperty()
    prop.SetColor(*(channel/255 for channel in rgb))
    prop.SetInterpolationToPhong()
    prop.SetAmbient(.23)
    prop.SetDiffuse(.73)
    prop.SetSpecular(.55 if metal else .12)
    prop.SetSpecularPower(45 if metal else 18)
    return actor


def transformed(shape, part):
    shape.rotate(App.Vector(0, 0, 0), App.Vector(0, 0, 1), part['pcb'].get('rotation', 0))
    shape.translate(App.Vector(part['pcb']['x'], part['pcb']['y'], 0))
    return shape


def capsule(x1, y1, x2, y2, width, z, thickness):
    length = math.hypot(x2-x1, y2-y1)
    if length < 1e-6:
        return Part.makeCylinder(width/2, thickness, App.Vector(x1, y1, z))
    shape = Part.makeBox(length, width, thickness, App.Vector(0, -width/2, z))
    shape.rotate(App.Vector(0, 0, 0), App.Vector(0, 0, 1), math.degrees(math.atan2(y2-y1, x2-x1)))
    shape.translate(App.Vector(x1, y1, 0))
    return shape


def scene(data, routing=None):
    if data.get('panelization'):
        raise ValueError('Use the panel profile drawing; this product renderer models the single carrier')
    board = data['board']
    thickness = board.get('thickness_mm', 1.6)
    carrier = rounded_carrier(board)
    drills = []
    for part in data['components']:
        for pad in footprint(part).pads:
            if pad.drill:
                drills.append(world_drill(part, vars(pad)))
        for hole in part.get('pcb_footprint', {}).get('holes', []):
            drills.append(world_drill(part, hole))
    for hole in board.get('holes_mm', []):
        x,y,d=(hole['x'],hole['y'],hole['diameter_mm']) if isinstance(hole,dict) else (*hole,board.get('hole_diameter_mm',3.2))
        drills.append((x, y, d, 0, 0))
    for via in (routing or {}).get('vias', []):
        drills.append((via['x'], via['y'], via.get('drill', .3), 0, 0))
    for x, y, diameter, length, angle in drills:
        carrier = carrier.cut(drill_solid(x, y, diameter, -thickness, thickness, length, angle))
    actors = [mesh_actor(carrier, (28, 103, 71))]
    # The actual copper is covered by green solder mask; subtle relief depicts
    # traces without turning the assembled product into a red/blue CAD overlay.
    for region in (routing or {}).get('regions', []):
        z = .01 if region['layer'] == 'TOP' else -thickness-.026
        vertices = [App.Vector(x, y, z) for x, y in region['points']]
        if (vertices[0]-vertices[-1]).Length > 1e-9:
            vertices.append(vertices[0])
        shape = Part.Face(Part.makePolygon(vertices)).extrude(App.Vector(0, 0, .012))
        for hole in region.get('holes', []):
            points = [App.Vector(x, y, z) for x, y in hole]
            if (points[0]-points[-1]).Length > 1e-9:
                points.append(points[0])
            shape = shape.cut(Part.Face(Part.makePolygon(points)).extrude(App.Vector(0, 0, .012)))
        # Mask does not close a drilled mounting/pin/via hole.
        for x, y, diameter, length, angle in drills:
            bounds = shape.BoundBox
            radius = max(diameter, length)/2
            if (bounds.XMin-radius <= x <= bounds.XMax+radius and
                    bounds.YMin-radius <= y <= bounds.YMax+radius):
                shape = shape.cut(drill_solid(x, y, diameter, z, .014, length, angle))
        actors.append(mesh_actor(shape, (29, 107, 74)))
    for track in (routing or {}).get('tracks', []):
        z = .012 if track['layer'] == 'TOP' else -thickness-.028
        shape = capsule(track['x1'], track['y1'], track['x2'], track['y2'], track['width'], z, .016)
        actors.append(mesh_actor(shape, (31, 111, 76)))
    for part in data['components']:
        fp = footprint(part)
        for pad in fp.pads:
            for z in ([.025, -thickness-.05] if pad.drill else [.025]):
                if pad.shape == 'ROUND':
                    pad_shape = Part.makeCylinder(pad.sx/2, .035, App.Vector(pad.x, pad.y, z))
                else:
                    pad_shape = Part.makeBox(pad.sx, pad.sy, .035,
                                             App.Vector(pad.x-pad.sx/2, pad.y-pad.sy/2, z))
                if pad.drill:
                    pad_shape = pad_shape.cut(drill_solid(pad.x, pad.y, pad.drill, z, .04,
                                                       pad.drill_slot_length_mm, pad.drill_slot_angle_deg))
                actors.append(mesh_actor(transformed(pad_shape, part), (192, 158, 66), True))
        for body in bodies_for(part):
            metallic = body.rgb in {(179, 188, 198), (207, 163, 58)}
            actors.append(mesh_actor(transformed(solid(body), part), body.rgb, metallic))
    for via in (routing or {}).get('vias', []):
        radius = via.get('diameter', .65)/2
        for z in [.02, -thickness-.045]:
            pad = Part.makeCylinder(radius, .025, App.Vector(via['x'], via['y'], z))
            # Fabrication tents the vias on both sides; do not depict exposed
            # gold annuli that have no opening in the actual soldermask data.
            actors.append(mesh_actor(pad, (28, 103, 71)))
    # Render the same reviewed lettering strokes as the fabrication Gerber.
    # These marks are real board artwork, not a screen-space annotation.
    for layer in ('TOP','BOTTOM'):
        strokes=[]
        z=.038 if layer=='TOP' else -thickness-.05
        for item in board.get('silkscreen',[]):
            if item.get('layer','TOP')!=layer:continue
            for points,width in silk_segments(item):
                for a,b in zip(points,points[1:]):
                    strokes.append(capsule(*a,*b,width,z,.012))
        if strokes:actors.append(mesh_actor(Part.makeCompound(strokes),(229,238,225)))
    return actors


def render(data, output, routing=None, size=(2200, 1550), revision='R3'):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    board = data['board']
    w, h = board['width_mm'], board['height_mm']
    actors = scene(data, routing)
    renderer = vtk.vtkRenderer()
    renderer.SetBackground(.935, .946, .953)
    renderer.SetBackground2(.985, .988, .991)
    renderer.GradientBackgroundOn()
    renderer.SetUseFXAA(True)
    render_steps = vtk.vtkRenderStepsPass()
    occlusion = vtk.vtkSSAOPass()
    occlusion.SetDelegatePass(render_steps)
    occlusion.SetRadius(2.2)
    # Ignore sub-0.1 mm copper/mask relief for ambient occlusion: these steps
    # otherwise produce stippled self-shadow artefacts along very fine traces.
    occlusion.SetBias(.12)
    occlusion.SetKernelSize(128)
    occlusion.BlurOn()
    renderer.SetPass(occlusion)
    for actor in actors:
        renderer.AddActor(actor)
    renderer.AutomaticLightCreationOff()
    for position, intensity, colour in [((w*.1, -h, 80), .82, (1, .97, .91)),
                                        ((w*2, h, 50), .48, (.86, .92, 1)),
                                        ((-w, h*2, 25), .35, (1, 1, 1))]:
        light = vtk.vtkLight()
        light.SetPosition(*position)
        light.SetFocalPoint(w/2, h/2, 0)
        light.SetIntensity(intensity)
        light.SetColor(*colour)
        light.SetLightTypeToSceneLight()
        renderer.AddLight(light)
    window = vtk.vtkRenderWindow()
    window.SetOffScreenRendering(1)
    window.SetMultiSamples(8)
    window.SetSize(*size)
    window.AddRenderer(renderer)
    camera = renderer.GetActiveCamera()
    camera.ParallelProjectionOn()
    camera.SetFocalPoint(w/2, h/2, 2.1)
    camera.SetParallelScale(max(w/1.55, h*.88))
    # A real z-buffer renders all package interactions; no painter's-order
    # approximation can accidentally show through a package or board.
    views = {
        f'PCB-{revision}-3D-Oberseite.png': ((w/2-60, h/2-80, 82), (0, 0, 1)),
        f'PCB-{revision}-3D-Unterseite.png': ((w/2-50, h/2-80, -90), (0, 0, -1)),
        f'PCB-{revision}-3D-Draufsicht.png': ((w/2, h/2, 120), (0, 1, 0)),
    }
    saved = []
    for name, (position, up) in views.items():
        camera.SetPosition(*position)
        camera.SetViewUp(*up)
        renderer.ResetCameraClippingRange()
        if 'Unterseite' in name:
            for light in renderer.GetLights():
                x, y, z = light.GetPosition()
                light.SetPosition(x, y, -abs(z))
        else:
            for light in renderer.GetLights():
                x, y, z = light.GetPosition()
                light.SetPosition(x, y, abs(z))
        window.Render()
        capture = vtk.vtkWindowToImageFilter()
        capture.SetInput(window)
        capture.SetInputBufferTypeToRGB()
        capture.ReadFrontBufferOff()
        capture.Update()
        writer = vtk.vtkPNGWriter()
        writer.SetFileName(str(output/name))
        writer.SetInputConnection(capture.GetOutputPort())
        writer.Write()
        saved.append(str(output/name))
    window.Finalize()
    return {'images': saved, 'size_pixels': list(size), 'actors': len(actors),
            'renderer': 'FreeCAD 1.1 / OCCT exact solids tessellated into VTK 9.3 with an offscreen depth buffer',
            'interpretation': 'Approximate locally generated package models, not certified supplier STEP geometry; final placement and pads are used.',
            'board_mm': [w, h, board.get('thickness_mm', 1.6)],
            'model_components': len(data['components'])}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('design', type=Path)
    parser.add_argument('--routing', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    data = json.loads(args.design.read_text(encoding='utf-8'))
    routing = json.loads(args.routing.read_text(encoding='utf-8')) if args.routing else None
    result = render(data, args.output, routing)
    result['design_sha256'] = hashlib.sha256(args.design.read_bytes()).hexdigest()
    if args.routing:
        result['routing_sha256'] = hashlib.sha256(args.routing.read_bytes()).hexdigest()
    (args.output/'3D-render-validation.json').write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(result, indent=2))
