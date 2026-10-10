"""Fill the delivered lid engraving with flush, separately coloured PETG.

Run with FreeCAD 1.1/bin/python.exe. The delivered enclosure and user-edited
3MF are read-only inputs. Both exported meshes share the original lid's print
coordinate frame; import them together as parts of one multicolour object.
"""
from __future__ import annotations
import hashlib
import json
import math
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'hardware/altium-r5/enclosure/sealed-print'
OUT = SOURCE / 'flush-colour'
FC = Path('C:/Program Files/FreeCAD 1.1')
sys.path.insert(0, str(FC / 'lib'))
_dll = os.add_dll_directory(str(FC / 'bin'))
os.environ['FREECAD_USER_HOME'] = str(SOURCE / 'freecad-profile')
import FreeCAD as App
import Part
import MeshPart
from build_orion_r5_sealed_enclosure import profile
from build_orion_r5_enclosure import enclosure_text_geometry
from r5_branding import region_data

V = App.Vector


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def marking_shape(contract, top):
    branding = contract['branding']
    asset = json.loads((ROOT / branding['geometry_json']).read_text('utf8'))
    bounds = asset['bounds']
    scale = min(branding['width'] / (bounds[2] - bounds[0]),
                branding['height'] / (bounds[3] - bounds[1]))
    def xy(p):
        return (branding['center'][0] + (p[0] - (bounds[0] + bounds[2]) / 2) * scale,
                branding['center'][1] + (p[1] - (bounds[1] + bounds[3]) / 2) * scale)
    artwork = [dict(points=[xy(p) for p in a['points']],
                    holes=[[xy(p) for p in h] for h in a.get('holes', [])])
               for a in asset['shapes']]
    for item in branding['texts']:
        artwork.extend(region_data(enclosure_text_geometry(item)))
    depth = branding['depth']
    solids = []
    for region in artwork:
        solid = profile(region['points'], top - depth, depth)
        for hole in region.get('holes', []):
            solid = solid.cut(profile(hole, top - depth - .1, depth + .2))
        solids.extend(solid.Solids)
    return Part.makeCompound(solids), artwork


def export_mesh(shape, name):
    mesh = MeshPart.meshFromShape(Shape=shape, LinearDeflection=.025,
                                  AngularDeflection=math.radians(6), Relative=False)
    if mesh.Volume < 0:
        mesh.flipNormals()
    assert mesh.isSolid(), name + ': open mesh'
    verts, faces = mesh.Topology
    edges, directions = {}, {}
    for face in faces:
        a, b, c = [verts[i] for i in face]
        assert (b - a).cross(c - a).Length > 1e-10, name + ': degenerate triangle'
        for i in range(3):
            a, b = face[i], face[(i + 1) % 3]
            key = tuple(sorted((a, b)))
            edges[key] = edges.get(key, 0) + 1
            directions[key] = directions.get(key, 0) + (1 if a < b else -1)
    assert all(n == 2 for n in edges.values()) and not any(directions.values()), name + ': manifold/orientation failure'
    assert abs(mesh.Volume - shape.Volume) / shape.Volume < .002
    path = OUT / (name + '.stl')
    mesh.write(str(path))
    bb = shape.BoundBox
    return dict(path=path.name, sha256=sha(path), vertices=len(verts), triangles=len(faces),
                volume_mm3=shape.Volume, solids=len(shape.Solids),
                bounds_mm=[[bb.XMin, bb.YMin, bb.ZMin], [bb.XMax, bb.YMax, bb.ZMax]],
                closed_oriented_manifold=True)


def preview(body, markings):
    import vtk
    from render_altium_r3 import mesh_actor
    ren = vtk.vtkRenderer()
    ren.SetBackground(.94, .96, .97)
    ren.SetUseFXAA(True)
    ren.AddActor(mesh_actor(body, [38, 51, 62]))
    ren.AddActor(mesh_actor(markings, [246, 246, 242]))
    win = vtk.vtkRenderWindow()
    win.SetOffScreenRendering(1)
    win.SetSize(1600, 1200)
    win.AddRenderer(ren)
    cam = ren.GetActiveCamera()
    cam.ParallelProjectionOn()
    cam.SetFocalPoint(26, 18, 31)
    cam.SetPosition(62, -92, 160)
    cam.SetViewUp(0, 1, 0)
    cam.SetParallelScale(47)
    ren.ResetCameraClippingRange()
    win.Render()
    capture = vtk.vtkWindowToImageFilter()
    capture.SetInput(win)
    capture.ReadFrontBufferOff()
    capture.Update()
    writer = vtk.vtkPNGWriter()
    writer.SetFileName(str(OUT / 'lid-flush-preview.png'))
    writer.SetInputConnection(capture.GetOutputPort())
    writer.Write()
    win.Finalize()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    source_cad = SOURCE / 'Orion-R5-sealed-enclosure.FCStd'
    source_stl = SOURCE / 'lid.stl'
    before = {p.name: sha(p) for p in (source_cad, source_stl, SOURCE / 'Orion-R5-P2S-complete.3mf')}
    contract = json.loads((SOURCE / 'sealed-contract.json').read_text('utf8'))
    doc = App.openDocument(str(source_cad))
    body = doc.getObject('lid').Shape.copy()
    top = body.BoundBox.ZMax
    markings, artwork = marking_shape(contract, top)
    assert body.isValid() and markings.isValid()
    overlap = body.common(markings).Volume
    assert overlap < 1e-6, f'Body/marking overlap: {overlap}'
    print('Fusing the colour regions for exterior validation', flush=True)
    united = body.multiFuse(list(markings.Solids)).removeSplitter()
    assert united.isValid() and len(united.Solids) == 1
    assert abs(united.Volume - body.Volume - markings.Volume) < 1e-5
    bb = markings.BoundBox
    slab = Part.makeBox(bb.XLength, bb.YLength, .01, V(bb.XMin, bb.YMin, top - .01))
    surface_void = slab.cut(united).Volume
    assert surface_void < 1e-6, f'Branding surface is not flush: {surface_void}'
    assert abs(body.BoundBox.ZMax - markings.BoundBox.ZMax) < 1e-9

    # Apply the same transform to both parts. Independent centring loses the artwork registration.
    rotated_body = body.copy()
    rotated_body.rotate(V(), V(1, 0, 0), 180)
    lo = rotated_body.BoundBox
    offset = V(-lo.XMin, -lo.YMin, -lo.ZMin)
    prints = {}
    for name, shape in [('lid_body', body), ('lid_markings', markings)]:
        item = shape.copy()
        item.rotate(V(), V(1, 0, 0), 180)
        item.translate(offset)
        prints[name] = export_mesh(item, name)
    # Read back STEP, including all disconnected letter islands, without implying separate assembly pieces.
    step = OUT / 'Orion-R5-flush-lid.step'
    Part.makeCompound([body, markings]).exportStep(str(step))
    check = Part.Shape()
    check.read(str(step))
    assert check.isValid() and len(check.Solids) == 1 + len(markings.Solids)
    # Preserve the delivered full assembly and add its flush marking material.
    mark_obj = doc.addObject('PartDesign::Feature', 'lid_markings')
    mark_obj.Label = 'Lid markings - flush contrasting PETG'
    mark_obj.Shape = markings
    mark_obj.addProperty('App::PropertyString', 'ManufacturingNote')
    mark_obj.ManufacturingNote = 'Co-print with lid body; shared face-down coordinates. No protrusion or recess.'
    doc.recompute()
    doc.saveAs(str(OUT / 'Orion-R5-flush-enclosure.FCStd'))
    preview(body, markings)
    after = {p.name: sha(p) for p in (source_cad, source_stl, SOURCE / 'Orion-R5-P2S-complete.3mf')}
    assert before == after, 'An original input changed during export'
    report = dict(passed=True, source_sha256=before,
                  branding=dict(mode='flush co-printed colour', material='PETG',
                                assembled_top_z_mm=top, depth_mm=contract['branding']['depth'],
                                nominal_layers_at_0p2mm=contract['branding']['depth'] / .2,
                                letter_and_logo_solids=len(markings.Solids),
                                raised_height_mm=0, recessed_height_mm=0),
                  body_markings_overlap_mm3=overlap, exterior_surface_void_mm3=surface_void,
                  fused_solid_count=len(united.Solids), step_valid=True,
                  step_solid_count=len(check.Solids), meshes=prints,
                  note='Two material parts of one lid, not a separate glued or press-fit insert. Original body, screw bores, seal lip and all other enclosure geometry preserved.',
                  physical_status='Colour opacity, adhesion, fit and sealing remain untested')
    (OUT / 'flush-lid-validation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
