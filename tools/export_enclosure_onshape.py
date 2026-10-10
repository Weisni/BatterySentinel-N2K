"""Export V2.3 native CAD solids to named STEP parts for Onshape editing.

Run with FreeCAD 1.1 Python. STL files are never used as geometry inputs.
"""
from pathlib import Path
from collections import Counter
import hashlib
import json
import math
import sys
import zipfile

import build_orion_enclosure_v2 as source
from build_profiled_cable_seal import build as build_latest_seal
import FreeCAD as App
import Part
import MeshPart
import Import
import vtk

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/Orion-Enclosure-V2.3-Onshape'
SOURCE = ROOT / 'hardware/altium-r5/enclosure/sealed-v2'
V = App.Vector


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def bounds(shape):
    bb = shape.optimalBoundingBox(False, False)
    return [bb.XMin, bb.YMin, bb.ZMin, bb.XMax, bb.YMax, bb.ZMax]


def translated(shape, delta):
    result = shape.copy()
    result.translate(V(*delta))
    return result


def mesh_data(shape):
    mesh = MeshPart.meshFromShape(Shape=shape, LinearDeflection=.02,
                                 AngularDeflection=math.radians(6), Relative=False)
    vertices, faces = mesh.Topology
    points, cells = vtk.vtkPoints(), vtk.vtkCellArray()
    for p in vertices:
        points.InsertNextPoint(p.x, p.y, p.z)
    for face in faces:
        cells.InsertNextCell(3)
        for i in face:
            cells.InsertCellPoint(i)
    poly = vtk.vtkPolyData()
    poly.SetPoints(points)
    poly.SetPolys(cells)
    return mesh, poly


def compare_geometry(expected, actual):
    assert actual.isValid() and actual.isClosed()
    assert len(expected.Solids) == len(actual.Solids)
    assert all(s.Volume > 0 and s.isClosed() for s in actual.Solids)
    a, ap = mesh_data(expected)
    b, bp = mesh_data(actual)
    relative_volume_error = abs(a.Volume - b.Volume) / abs(a.Volume)
    distances = []
    for points, surface in ((ap, bp), (bp, ap)):
        distance = vtk.vtkImplicitPolyDataDistance()
        distance.SetInput(surface)
        distances.append(max(abs(distance.EvaluateFunction(points.GetPoint(i)))
                             for i in range(points.GetNumberOfPoints())))
    assert relative_volume_error < .002, relative_volume_error
    assert max(distances) < .05, distances
    return dict(relative_mesh_volume_error=relative_volume_error,
                maximum_bidirectional_vertex_surface_distance_mm=max(distances),
                checked_vertices=[ap.GetNumberOfPoints(), bp.GetNumberOfPoints()])


def export_step(entries, path, compare=True, groups=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    expected = Part.makeCompound([s for _, s in entries])
    # FreeCAD's named STEP exporter drops a translated compound's parent
    # placement. Rebuild its identity-positioned root from the located solids.
    # This preserves analytic surfaces and was reproduced with two cylinders.
    normalized = [(n, Part.makeCompound(s.Solids) if s.ShapeType == 'Compound' else s)
                  for n, s in entries]
    reuse = False
    comparison = None
    if '--resume' in sys.argv and path.exists():
        previous = Part.Shape()
        previous.read(str(path))
        try:
            comparison = compare_geometry(expected, previous)
            reuse = True
        except AssertionError:
            print('Replacing failed prior STEP: ' + path.name, flush=True)
    document = App.newDocument('StepExport')
    root = document.addObject('App::Part', 'Orion_Enclosure_V2_3') if groups else None
    parents = {}
    if root:
        root.Label = 'Orion Enclosure V2.3 - assembled with alternatives'
        for label in dict.fromkeys(groups.values()):
            group = document.addObject('App::Part', label)
            group.Label = label
            root.addObject(group)
            parents[label] = group
    objects = []
    for name, shape in normalized:
        assert shape.isValid() and shape.isClosed(), name
        obj = document.addObject('Part::Feature', name)
        obj.Label = name
        obj.Shape = shape
        if groups:
            parents[groups[name]].addObject(obj)
        objects.append(obj)
    document.recompute()
    if not reuse:
        Import.export([root] if root else objects, str(path))
    App.closeDocument(document.Name)
    text = path.read_text(errors='replace')
    assert 'MANIFOLD_SOLID_BREP' in text
    assert not any(item in text for item in ('FACETED_BREP', 'TRIANGULATED_FACE_SET', 'TESSELLATED_SHELL'))
    for name, _ in entries:
        assert name in text, ('Missing part name', name)
    if groups:
        assert all(group in text for group in groups.values())
        assert 'NEXT_ASSEMBLY_USAGE_OCCURRENCE' in text
    readback = Part.Shape()
    readback.read(str(path))
    assert readback.isValid() and readback.isClosed()
    assert len(readback.Solids) == len(expected.Solids)
    surfaces = Counter(type(f.Surface).__name__ for f in readback.Faces)
    report = dict(file=path.relative_to(OUT).as_posix(), sha256=sha(path),
                  part_names=[n for n, _ in entries], solids=len(readback.Solids),
                  faces=len(readback.Faces), native_surface_types=dict(surfaces),
                  bounds_mm=bounds(readback), valid_closed_solids=True,
                  mesh_entities=False)
    if groups:
        report['assembly_groups'] = list(dict.fromkeys(groups.values()))
        report['named_assembly_relations'] = text.count('NEXT_ASSEMBLY_USAGE_OCCURRENCE')
    if compare:
        report['geometry_comparison'] = comparison if reuse else compare_geometry(expected, readback)
    return report


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    protected = [SOURCE / n for n in ('Orion-Enclosure-V2.FCStd', 'parameters.json',
                 'Orion-Enclosure-V2-assembly.step', 'base.stl', 'lid_body.stl')]
    before = {str(p.relative_to(ROOT)): sha(p) for p in protected}
    assert 'V2.3' in source.P['revision']
    print('Building original V2.3 CAD; no mesh conversion', flush=True)
    _, parts, assembly, _, _, _ = source.build()
    print('CAD ready; validating against released document', flush=True)
    released = App.openDocument(str(SOURCE / 'Orion-Enclosure-V2.FCStd'))
    source_checks = {}
    for name in ('base', 'lid_body', 'lid_markings'):
        source_checks[name] = compare_geometry(released.getObject(name).Shape, parts[name]['shape'])

    # The released assembly retained the pre-refinement cap/clamp compounds.
    # Their manufactured counterparts have the same surface but valid refined
    # topology. Install those exact native CAD parts in the original frames.
    installed_refinements = {
        'cable_pressure_cap': source.face_mount(parts['cable_pressure_cap']['shape'],
                                                'X-', 18, 14, -14.4-source.P['extension_mm']),
        'strain_relief_upper': source.moved(parts['strain_relief_upper']['shape'], z=.2),
    }
    refinement_checks = {}
    for name, refined in installed_refinements.items():
        refinement_checks[name] = compare_geometry(assembly[name], refined)
        assembly[name] = refined
    for name, shape in assembly.items():
        assert shape.isValid() and shape.isClosed(), ('Assembly topology', name)

    App.ParamGet('User parameter:BaseApp/Preferences/Mod/Part/STEP').SetString('Scheme', 'AP214IS')
    files = []
    for name, item in parts.items():
        print('STEP export and surface check: ' + name, flush=True)
        report = export_step([(name, item['shape'])], OUT / 'parts' / (name + '.step'))
        report.update(material=item['material'], group=item['group'], state='Free manufactured geometry')
        files.append(report)

    # Keep original V2.3 release and subsequent standalone changes distinct.
    original = released.getObject('strain_relief_upper').Shape.copy()
    seat = min(v.Point.z for v in original.Vertexes)
    original.translate(V(0, 0, 14.2 - seat - 1.0))
    upper = original.common(Part.makeBox(30, 40, 15, V(-25, 0, 14.2))).removeSplitter()
    b = bounds(upper)
    assert abs(b[5] - b[2] - 5) < 1e-6
    latest = [('strain_relief_upper_5mm', upper),
              ('cable_seal_ID6p8_OD11p5_L9mm_profiled', build_latest_seal())]
    for name, shape in latest:
        print('Latest standalone variant: ' + name, flush=True)
        files.append(export_step([(name, shape)], OUT / 'latest-variants' / (name + '.step')))
    App.closeDocument(released.Name)

    # The actual released closed assembly stays at its native coordinates.
    # Optional, mutually exclusive variants are parked outside its envelope.
    # STEP has no portable Onshape configuration/visibility mechanism: grouping
    # avoids overlapping different sleeves in the same installed pocket.
    combined = []
    groups = {}
    for name, shape in assembly.items():
        label = name
        if name == 'strain_relief_upper':
            label += '__H6mm_INSTALLED'
        elif name == 'clamp_shims':
            label += '__H0p2mm_PAIR_INSTALLED'
        elif name.startswith('cable_seal_'):
            label += '__OD11mm_SEATED_L6mm_ENVELOPE'
        elif name.endswith('_gasket'):
            label += '__SEATED_H1p4mm_ENVELOPE'
        combined.append((label, shape))
        groups[label] = '01_Assembled_V2_3'
    x, y, row_height = 150., 0., 0.
    def park(name, shape, group):
        nonlocal x, y, row_height
        b = bounds(shape)
        width, height = b[3] - b[0], b[4] - b[1]
        if x + width > 350 and x > 150:
            x, y, row_height = 150, y + row_height + 15, 0
        combined.append((name, translated(shape, (x-b[0], y-b[1], -b[2]))))
        groups[name] = group
        x += width + 15
        row_height = max(row_height, height)
    for name, item in parts.items():
        if name.startswith('cable_seal_'):
            park(name + '__OD11mm_FREE', item['shape'], '02_Cable_seal_variants_FREE')
        elif name == 'strain_relief_upper':
            park(name + '__H6mm_ORIGINAL', item['shape'], '03_Upper_clamp_variants')
        elif name.startswith('clamp_shims_'):
            park(name + '__PAIR', item['shape'], '04_Clamp_shim_variants')
        elif name.endswith('_gasket') and item['group'] == 'production':
            park(name + '__FREE_H1p8mm', item['shape'], '05_Face_gaskets_FREE')
        elif item['group'] == 'calibration':
            park(name, item['shape'], '06_Optional_calibration_parts')
    for name, shape in latest:
        group = '03_Upper_clamp_variants' if name.startswith('strain') else '02_Cable_seal_variants_FREE'
        park(name + '__LATEST_FREE', shape, group)
    print('Exporting assembled enclosure with named variant groups', flush=True)
    main_path = OUT / 'Orion-Enclosure-V2.3-Assembled-All-Variants.step'
    files.append(export_step(combined, main_path, groups=groups))
    assert before == {str(p.relative_to(ROOT)): sha(p) for p in protected}
    report = dict(passed=True, format='STEP AP214 boundary representation', units='mm',
                  source_revision=source.P['revision'], source_preservation=before,
                  geometry_inputs='Native CAD solids only; no imported STL/3MF',
                  combined_main_file=main_path.name,
                  combined_component_groups=groups,
                  combined_layout='Closed V2.3 assembly at native coordinates; free variants parked to its right',
                  regenerated_source_comparison=source_checks, files=files,
                  installed_topology_refinement_checks=refinement_checks,
                  local_readback='Passed exact-solid, topology and tessellated-surface comparison',
                  onshape_account_import='Not performed',
                  parametric_feature_history='Not transferable through STEP',
                  solid_definition_count=sum(f['solids'] for f in files))
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2), encoding='utf8')
    # README is maintained beside the generator and packaged as user guidance.
    readme = ROOT / 'hardware/altium-r5/enclosure/onshape-export/README.md'
    (OUT / 'README.md').write_text(readme.read_text(encoding='utf8'), encoding='utf8')
    archive = OUT.parent / (OUT.name + '.zip')
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for path in sorted(OUT.rglob('*')):
            if path.is_file():
                z.write(path, path.relative_to(OUT).as_posix())
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        for row in files:
            assert hashlib.sha256(z.read(row['file'])).hexdigest() == row['sha256']
    print(json.dumps(dict(passed=True, step_files=len(files), combined_components=len(combined),
                          archive=str(archive), archive_sha256=sha(archive)), indent=2), flush=True)


if __name__ == '__main__':
    main()
