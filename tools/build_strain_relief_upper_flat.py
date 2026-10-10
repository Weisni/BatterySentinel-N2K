"""Create a shallower standalone upper clamp from the released V2.3 CAD.

Lower the cable contact surface without thinning its roof. Trim only the
upper part's feet back to the original seating plane; the base is read-only.
"""
from pathlib import Path
from collections import Counter, defaultdict
import hashlib
import json
import math
import os
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT/'hardware/altium-r5/enclosure/sealed-v2'
OUT = ROOT/'hardware/altium-r5/enclosure/strain-relief-upper-flat'
DEST = ROOT/'output/strain_relief_upper_5mm.stl'
HEIGHT = 5.0
DROP = 6.0-HEIGHT
SEAT = 14.2
FC = Path('C:/Program Files/FreeCAD 1.1')
sys.path.insert(0,str(FC/'lib'))
_dll = os.add_dll_directory(str(FC/'bin'))
OUT.mkdir(parents=True,exist_ok=True)
prefs = OUT/'freecad-profile/v1-1'
prefs.mkdir(parents=True,exist_ok=True)
for name in ('user.cfg','system.cfg'):
    (prefs/name).write_text('<?xml version="1.0"?><FCParameters><FCParamGroup Name="Root"/></FCParameters>')
os.environ['FREECAD_USER_HOME'] = str(prefs.parent)
import FreeCAD as App
import Part
import Mesh
import MeshPart
V = App.Vector


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def shifted(shape,dz):
    result=shape.copy();result.translate(V(0,0,dz));return result


def limits(shape,axis):
    # OCCT's cached box includes untrimmed torus extrema on this saved part.
    # Its external planar faces and corner arcs have vertices at all envelope
    # extrema; exported STL dimensions are independently checked below.
    values=[getattr(v.Point,axis) for v in shape.Vertexes]
    return min(values),max(values)


def main():
    inputs=[SOURCE/'Orion-Enclosure-V2.FCStd', SOURCE/'base.stl', SOURCE/'strain_relief_upper.stl']
    before={str(p.relative_to(ROOT)):sha(p) for p in inputs}
    doc=App.openDocument(str(inputs[0]))
    base=doc.getObject('base').Shape
    source=doc.getObject('strain_relief_upper').Shape
    old=shifted(source,SEAT-limits(source,'z')[0])
    assert abs(limits(old,'z')[1]-limits(old,'z')[0]-6)<1e-7
    new=shifted(old,-DROP).common(Part.makeBox(30,40,15,V(-25,0,SEAT))).removeSplitter()
    assert new.isValid() and new.isClosed() and len(new.Solids)==1
    assert abs(limits(new,'z')[0]-SEAT)<1e-7
    assert all(abs(limits(new,k)[1]-limits(new,k)[0]-expected)<1e-7 for k,expected in zip('xyz',(12,28,HEIGHT)))

    # Measure old/new throat at the real rib crests and between ribs.
    sections=[]
    for x in (-16,-14,-12,-10,-8):
        ray=Part.makeLine(V(x,18,9),V(x,18,22))
        bottom=max(v.Point.z for v in base.common(ray).Vertexes)
        roof_old=min(v.Point.z for v in old.common(ray).Vertexes)
        roof_new=min(v.Point.z for v in new.common(ray).Vertexes)
        assert abs((roof_old-roof_new)-DROP)<1e-6
        assert abs((limits(old,'z')[1]-roof_old)-(limits(new,'z')[1]-roof_new))<1e-6
        sections.append(dict(x_mm=x,old_gap_no_shim_mm=roof_old-bottom,
            new_gap_no_shim_mm=roof_new-bottom,roof_thickness_mm=limits(new,'z')[1]-roof_new))
    assert all(abs(row['new_gap_no_shim_mm']-(6.7-DROP))<1e-6 for row in sections if row['x_mm'] in (-16,-12,-8))
    assert all(abs(row['new_gap_no_shim_mm']-(7.4-DROP))<1e-6 for row in sections if row['x_mm'] in (-14,-10))

    washer=[]
    for y in (8,28):
        hole=Part.makeCylinder(1.699,7,V(-12,y,14))
        assert new.common(hole).Volume<1e-7
        top=SEAT+HEIGHT
        annulus=Part.makeCylinder(3.5,.01,V(-12,y,top-.02)).cut(Part.makeCylinder(1.8,.03,V(-12,y,top-.03)))
        coverage=new.common(annulus).Volume/annulus.Volume
        assert coverage>.999
        washer.append(dict(axis_mm=[-12,y],coverage=coverage))

    collisions=[]
    for shim in (0,.2,.4):
        installed=shifted(new,shim)
        for obj in doc.Objects:
            if obj.Name in ('strain_relief_upper','clamp_shims') or not hasattr(obj,'Shape'):continue
            other=obj.Shape
            if other.isNull():continue
            a,b=installed.BoundBox,other.BoundBox
            if any(min(getattr(a,k+'Max'),getattr(b,k+'Max'))-max(getattr(a,k+'Min'),getattr(b,k+'Min'))<1e-7 for k in 'XYZ'):continue
            volume=installed.common(other).Volume
            assert volume<1e-6,(shim,obj.Name,volume)
            collisions.append(dict(shim_mm=shim,part=obj.Name,intersection_mm3=volume))

    printable=new.copy();printable.rotate(V(),V(1,0,0),180)
    printable.translate(V(*[-limits(printable,k)[0] for k in 'xyz']))
    mesh=MeshPart.meshFromShape(Shape=printable,LinearDeflection=.01,AngularDeflection=math.radians(4),Relative=False)
    if mesh.Volume<0:mesh.flipNormals()
    DEST.parent.mkdir(parents=True,exist_ok=True);mesh.write(str(DEST))
    actual=Mesh.Mesh(str(DEST));vertices,faces=actual.Topology
    edges,balance=Counter(),Counter();neighbours=defaultdict(set)
    for face in faces:
        a,b,c=(vertices[i] for i in face)
        assert (b-a).cross(c-a).Length>1e-10
        for u,v in zip(face,face[1:]+face[:1]):
            key=tuple(sorted((u,v)));edges[key]+=1;balance[key]+=1 if u<v else -1
            neighbours[u].add(v);neighbours[v].add(u)
    assert actual.isSolid() and actual.Volume>0
    assert all(n==2 for n in edges.values()) and not any(balance.values())
    seen=set();todo=[0]
    while todo:
        i=todo.pop()
        if i not in seen:seen.add(i);todo.extend(neighbours[i]-seen)
    assert len(seen)==len(vertices)
    assert abs(actual.Volume-new.Volume)/new.Volume<.001
    bb=actual.BoundBox
    assert all(abs(a-b)<1e-5 for a,b in zip((bb.XLength,bb.YLength,bb.ZLength),(12,28,HEIGHT)))
    assert abs(bb.ZMin)<1e-6
    assert before=={str(p.relative_to(ROOT)):sha(p) for p in inputs}
    report=dict(passed=True,drop_mm=DROP,dimensions_mm=[12,28,HEIGHT],source_height_mm=6,
        print_orientation='Flat outer top face on bed; saddle opens upward',
        sections=sections,washer_seats=washer,assembly_intersections=collisions,
        shim_throat_gaps_mm={f'{s:.1f}':round(6.7-DROP+s,2) for s in (0,.2,.4)},
        screw_holes=dict(diameter_mm=3.4,spacing_mm=20),
        m3x10_engagement_with_0p5_washer_mm={f'{s:.1f}':round(10-HEIGHT-.5-s,2) for s in (0,.2,.4)},
        closed_oriented_manifold=True,connected_components=1,triangles=len(faces),
        mesh_volume_mm3=actual.Volume,unchanged_source_sha256=before,stl_sha256=sha(DEST),
        physical_status='Cable compression, pull force and creep not tested')
    (OUT/'validation.json').write_text(json.dumps(report,indent=2))
    print(json.dumps(report,indent=2))


if __name__=='__main__':main()
