"""Render the corrected standalone STLs and an exact CAD section for review."""
from pathlib import Path
import vtk
from build_profiled_cable_seal import build, Part, V, ROOT


def actor(poly, color):
    normals = vtk.vtkPolyDataNormals()
    normals.SetInputData(poly)
    normals.SetFeatureAngle(40)
    normals.ConsistencyOn()
    normals.AutoOrientNormalsOn()
    mapper = vtk.vtkPolyDataMapper()
    mapper.SetInputConnection(normals.GetOutputPort())
    obj = vtk.vtkActor()
    obj.SetMapper(mapper)
    prop = obj.GetProperty()
    prop.SetColor(*color)
    prop.SetInterpolationToPhong()
    prop.SetAmbient(.28)
    prop.SetDiffuse(.72)
    prop.SetSpecular(.18)
    prop.SetSpecularPower(24)
    return obj


def stl(name):
    reader = vtk.vtkSTLReader()
    reader.SetFileName(str(ROOT / 'output' / name))
    reader.Update()
    return reader.GetOutput()


def section():
    shape = build().common(Part.makeBox(20, 10, 12, V(-10, -10, -1)))
    vertices, faces = shape.tessellate(.008)
    points = vtk.vtkPoints()
    for p in vertices:
        points.InsertNextPoint(p.x, p.y, p.z)
    cells = vtk.vtkCellArray()
    for face in faces:
        cells.InsertNextCell(3)
        for i in face:
            cells.InsertCellPoint(i)
    poly = vtk.vtkPolyData()
    poly.SetPoints(points)
    poly.SetPolys(cells)
    return poly


def label(renderer, message, x, y, size, bold=False):
    text = vtk.vtkTextActor()
    text.SetInput(message)
    text.GetPositionCoordinate().SetCoordinateSystemToNormalizedViewport()
    text.SetPosition(x, y)
    prop = text.GetTextProperty()
    prop.SetFontFamilyToArial()
    prop.SetFontSize(size)
    prop.SetColor(.12, .19, .24)
    prop.SetBold(bold)
    renderer.AddActor2D(text)


window = vtk.vtkRenderWindow()
window.SetOffScreenRendering(1)
window.SetSize(1800, 720)
window.SetMultiSamples(8)
panels = [
    (stl('Kabeltuelle_ID6p8_AD11p5_L9mm_Profiliert.stl'), (.82, .48, .13),
     (18, -26, 24), (0, 0, 4.5), 9.8,
     'PROFILED CABLE SEAL', 'OD 11.5 mm / total length 9.0 mm\nRounded outer edges and end lip'),
    (section(), (.82, .48, .13),
     (10, 32, 17), (0, 0, 4.5), 9.8,
     'SECTION THROUGH THE BORE', 'Two internal rounded sealing beads\nMinimum ID 6.8 mm / relief bore 7.5 mm'),
    (stl('strain_relief_upper_5mm.stl'), (.12, .37, .45),
     (42, -23, 43), (6, 14, 2.5), 18,
     'UPPER CLAMP / 5.0 mm', '12 x 28 x 5 mm / screw spacing 20 mm\nCable saddle shown facing upward'),
]
for i, (poly, color, position, focus, scale, title, detail) in enumerate(panels):
    renderer = vtk.vtkRenderer()
    renderer.SetViewport(i / 3, 0, (i + 1) / 3, 1)
    renderer.SetBackground(.95, .96, .975)
    renderer.SetBackground2(.995, .995, .999)
    renderer.GradientBackgroundOn()
    renderer.SetUseFXAA(True)
    renderer.AddActor(actor(poly, color))
    label(renderer, title, .06, .92, 23, True)
    label(renderer, detail, .06, .07, 19)
    camera = renderer.GetActiveCamera()
    camera.SetPosition(*position)
    camera.SetFocalPoint(*focus)
    camera.SetViewUp(0, 0, 1)
    camera.ParallelProjectionOn()
    camera.SetParallelScale(scale)
    renderer.ResetCameraClippingRange()
    window.AddRenderer(renderer)

window.Render()
capture = vtk.vtkWindowToImageFilter()
capture.SetInput(window)
capture.ReadFrontBufferOff()
capture.Update()
dest = ROOT / 'output' / 'Kabeltuelle_und_Klemmoberteil_Korrigiert.png'
writer = vtk.vtkPNGWriter()
writer.SetFileName(str(dest))
writer.SetInputConnection(capture.GetOutputPort())
writer.Write()
window.Finalize()
print(dest)
