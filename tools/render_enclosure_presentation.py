"""Render actual enclosure CAD with illustrative purchased screws and cable."""
import math
import build_orion_enclosure_v2 as b
import vtk
from render_altium_r3 import mesh_actor

V=b.V

def screw():
    washer=b.cyl(0,0,3.5,0,.5).cut(b.cyl(0,0,1.6,-.1,.7))
    head=b.cyl(0,0,2.85,.5,1.65)
    head=head.makeFillet(.6,[e for e in head.Edges if abs(e.BoundBox.ZMin-2.15)<1e-7 and abs(e.BoundBox.ZMax-2.15)<1e-7])
    points=[(1.2*math.cos(i*math.pi/3),1.2*math.sin(i*math.pi/3)) for i in range(6)]
    head=head.cut(b.profile(points,1.3,1.4))
    return washer,head

def main():
    doc=b.App.openDocument(str(b.OUT/'Orion-Enclosure-V2.FCStd'))
    ren=vtk.vtkRenderer();ren.SetBackground(.94,.96,.98);ren.SetBackground2(1,1,1);ren.GradientBackgroundOn();ren.SetUseFXAA(True)
    def add(s,col,metal=False):
        a=mesh_actor(s,col,metal);p=a.GetProperty();p.SetAmbient(.18);p.SetDiffuse(.78);p.SetSpecular(.38 if metal else .28);p.SetSpecularPower(35)
        ren.AddActor(a)
    for n in ('base','lid_body','lid_markings','cable_pressure_cap','usb_cover','service_switch_cover'):
        add(doc.getObject(n).Shape,[240,243,238] if n=='lid_markings' else [38,66,82])
    for x,y in [(-26,-10),(62,-10),(-26,46),(62,46),(18,-11),(18,47)]:
        for part in screw():part.translate(V(x,y,33.2));add(part,[50,55,60],True)
    for x,y in [(0,10),(-11,-6),(11,-6)]:
        for part in screw():
            part.translate(V(x,y,5));add(b.face_mount(part,'X-',18,14,-30.4),[50,55,60],True)
    add(b.Part.makeCylinder(3.5,36,V(-30.4,18,14),V(-1,0,0)),[28,30,34])
    for position,intensity in [((-70,-100,150),.85),((100,-30,80),.35),((0,120,160),.6)]:
        light=vtk.vtkLight();light.SetLightTypeToSceneLight();light.SetPosition(*position);light.SetFocalPoint(18,18,15);light.SetIntensity(intensity);ren.AddLight(light)
    ren.AutomaticLightCreationOff()
    win=vtk.vtkRenderWindow();win.SetOffScreenRendering(1);win.SetSize(1800,1250);win.AddRenderer(ren)
    cam=ren.GetActiveCamera();cam.ParallelProjectionOn();cam.SetFocalPoint(9,18,17);cam.SetPosition(-115,-170,140);cam.SetViewUp(0,0,1);cam.SetParallelScale(68)
    ren.ResetCameraClippingRange();win.Render()
    capture=vtk.vtkWindowToImageFilter();capture.SetInput(win);capture.ReadFrontBufferOff();capture.Update()
    writer=vtk.vtkPNGWriter();writer.SetFileName(str(b.OUT/'preview-styled-presentation.png'));writer.SetInputConnection(capture.GetOutputPort());writer.Write();win.Finalize()
    print('Actual CAD presentation rendered; screws and cable are illustrative, not print parts.')
if __name__=='__main__':main()
