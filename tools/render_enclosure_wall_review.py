"""Render the real open base and a horizontal CAD section through its walls."""
import build_orion_enclosure_v2 as b
import vtk
from render_altium_r3 import mesh_actor

doc=b.App.openDocument(str(b.OUT/'Orion-Enclosure-V2.FCStd'))
base=doc.getObject('base').Shape
win=vtk.vtkRenderWindow();win.SetOffScreenRendering(1);win.SetSize(2000,1100)
for index in (0,1):
    ren=vtk.vtkRenderer();ren.SetViewport(index*.5,0,(index+1)*.5,1)
    ren.SetBackground(.95,.97,.98);ren.SetUseFXAA(True);win.AddRenderer(ren)
    shape=base if index==0 else base.common(b.Part.makeBox(200,200,16,b.V(-70,-60,0)))
    ren.AddActor(mesh_actor(shape,[51,91,110]))
    if index:
        cut=base.common(b.Part.makeBox(200,200,.04,b.V(-70,-60,15.96)))
        ren.AddActor(mesh_actor(cut,[220,149,50]))
        for a,c in [((5,-10,16.1),(5,-7,16.1)),((4.4,-10,16.1),(5.6,-10,16.1)),
                ((4.4,-7,16.1),(5.6,-7,16.1)),((5,-8.5,16.1),(0,-19,16.1))]:
            ren.AddActor(mesh_actor(b.Part.makeCylinder(.09,(b.V(*c)-b.V(*a)).Length,b.V(*a),b.V(*c)-b.V(*a)),[40,44,49]))
        label=vtk.vtkBillboardTextActor3D();label.SetInput('3 mm');label.SetPosition(-1,-23,16.2)
        label.GetTextProperty().SetFontSize(24);label.GetTextProperty().SetColor(.1,.15,.18);ren.AddActor(label)
    title=vtk.vtkTextActor();title.SetInput('V2.3 | Open base' if index==0 else 'CAD section | Z = 16 mm')
    title.GetPositionCoordinate().SetCoordinateSystemToNormalizedViewport();title.SetPosition(.06,.91)
    title.GetTextProperty().SetFontSize(28);title.GetTextProperty().SetBold(1);title.GetTextProperty().SetColor(.12,.22,.28);ren.AddActor2D(title)
    note=vtk.vtkTextActor();note.SetInput('Local sealing rim and connector pads' if index==0 else 'Amber: cut wall and screw-boss sections')
    note.GetPositionCoordinate().SetCoordinateSystemToNormalizedViewport();note.SetPosition(.06,.055)
    note.GetTextProperty().SetFontSize(21);note.GetTextProperty().SetColor(.25,.32,.37);ren.AddActor2D(note)
    cam=ren.GetActiveCamera();cam.ParallelProjectionOn();cam.SetFocalPoint(18,18,12)
    cam.SetPosition(-85,-130,165) if index==0 else cam.SetPosition(18,18,200)
    cam.SetViewUp(0,0,1) if index==0 else cam.SetViewUp(0,1,0)
    cam.SetParallelScale(68 if index==0 else 56)
    ren.ResetCameraClippingRange()
win.Render();f=vtk.vtkWindowToImageFilter();f.SetInput(win);f.ReadFrontBufferOff();f.Update()
w=vtk.vtkPNGWriter();w.SetFileName(str(b.OUT/'preview-thin-wall-sections.png'));w.SetInputConnection(f.GetOutputPort());w.Write();win.Finalize()
print('Actual open CAD and horizontal section rendered.')
