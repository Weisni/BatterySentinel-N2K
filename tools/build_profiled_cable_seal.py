"""Restore the original sleeve features at the user's standalone dimensions.

Run with FreeCAD 1.1 Python. The enclosure's existing pocket is not changed.
The 6.8 mm bore is measured at the two inward toroidal sealing bead crests.
"""
from pathlib import Path
from collections import Counter, defaultdict
import hashlib,json,math,os,sys

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'hardware/altium-r5/enclosure/cable-seal-sample'
DEST=ROOT/'output/Kabeltuelle_ID6p8_AD11p5_L9mm_Profiliert.stl'
FC=Path('C:/Program Files/FreeCAD 1.1')
sys.path.insert(0,str(FC/'lib'));_dll=os.add_dll_directory(str(FC/'bin'))
prefs=OUT/'freecad-profile/v1-1';prefs.mkdir(parents=True,exist_ok=True)
for name in ('user.cfg','system.cfg'):
    (prefs/name).write_text('<?xml version="1.0"?><FCParameters><FCParamGroup Name="Root"/></FCParameters>')
os.environ['FREECAD_USER_HOME']=str(prefs.parent)
import FreeCAD as App
import Part,Mesh,MeshPart
V=App.Vector
INNER,OUTER,LENGTH=6.8,11.5,9.0
RELIEF_BORE=7.5
END_BEAD=.8
BODY=LENGTH-END_BEAD
BEAD_Z=(BODY*.25,BODY*2/3)


def build():
    outer=Part.makeCylinder(OUTER/2,BODY)
    inner=Part.makeCylinder(RELIEF_BORE/2,BODY+.2,V(0,0,-.1))
    body=outer.cut(inner)
    for height,radius in ((0,.35),(BODY,.2)):
        edges=[e for e in body.Edges if hasattr(e.Curve,'Radius')
            and abs(e.Curve.Radius-OUTER/2)<1e-6
            and abs(e.BoundBox.ZMin-height)<1e-6 and abs(e.BoundBox.ZMax-height)<1e-6]
        assert len(edges)==1
        body=body.makeFillet(radius,edges)
    # Preserve the original 0.6 mm circular bead section and 6.8 mm throat.
    for z in BEAD_Z:
        bead=Part.makeTorus(INNER/2+.6,.6,V(0,0,z),V(0,0,1))
        body=body.fuse(bead)
    # Raised rounded axial contact lip: included in the overall 9 mm length.
    end=Part.makeTorus((OUTER+RELIEF_BORE)/4,END_BEAD,V(0,0,BODY),V(0,0,1))
    end=end.common(Part.makeCylinder(OUTER/2,END_BEAD+.01,V(0,0,BODY)))
    return body.fuse(end).removeSplitter()


def main():
    shape=build()
    assert shape.isValid() and shape.isClosed() and len(shape.Solids)==1
    # The conservative OCCT box overestimates trimmed fillet surfaces.
    # Use the exact extrema and independently measure the exported mesh.
    bb=shape.optimalBoundingBox(False,False)
    assert all(abs(a-b)<1e-6 for a,b in zip((bb.XLength,bb.YLength,bb.ZLength),(OUTER,OUTER,LENGTH)))
    assert abs(bb.ZMin)<1e-7
    # Independently measure radial sections at crests, relief and rounded edges.
    sections=[]
    for z,expected_inner,expected_outer in [(BEAD_Z[0],3.4,5.75),
            (BEAD_Z[1],3.4,5.75),((BEAD_Z[0]+BEAD_Z[1])/2,3.75,5.75),
            (.0001,3.75,None),(BODY-.0001,3.75,None)]:
        section=shape.common(Part.makeLine(V(0,0,z),V(6,0,z)))
        ri=min(v.Point.x for v in section.Vertexes)
        ro=max(v.Point.x for v in section.Vertexes)
        assert abs(ri-expected_inner)<1e-6
        if expected_outer is not None:assert abs(ro-expected_outer)<1e-6
        else:assert ro<5.6
        sections.append(dict(z_mm=z,bore_diameter_mm=2*ri,outer_diameter_mm=2*ro))
    lip=shape.common(Part.makeLine(V(4.75,0,8),V(4.75,0,9.1)))
    assert abs(max(v.Point.z for v in lip.Vertexes)-LENGTH)<1e-6

    mesh=MeshPart.meshFromShape(Shape=shape,LinearDeflection=.006,AngularDeflection=math.radians(3),Relative=False)
    if mesh.Volume<0:mesh.flipNormals()
    DEST.parent.mkdir(parents=True,exist_ok=True);mesh.write(str(DEST))
    actual=Mesh.Mesh(str(DEST));verts,faces=actual.Topology
    edges,balance=Counter(),Counter();adj=defaultdict(set)
    for face in faces:
        a,b,c=(verts[i] for i in face)
        assert (b-a).cross(c-a).Length>1e-10
        for u,v in zip(face,face[1:]+face[:1]):
            key=tuple(sorted((u,v)));edges[key]+=1;balance[key]+=1 if u<v else -1
            adj[u].add(v);adj[v].add(u)
    assert actual.isSolid() and actual.Volume>0
    assert all(n==2 for n in edges.values()) and not any(balance.values())
    seen=set();todo=[0]
    while todo:
        n=todo.pop()
        if n not in seen:seen.add(n);todo.extend(adj[n]-seen)
    assert len(seen)==len(verts)
    assert abs(actual.Volume-shape.Volume)/shape.Volume<.001
    measured=[actual.BoundBox.XLength,actual.BoundBox.YLength,actual.BoundBox.ZLength]
    assert all(abs(a-b)<.005 for a,b in zip(measured,(OUTER,OUTER,LENGTH)))
    min_bore=2*min(math.hypot(v.x,v.y) for v in verts)
    assert abs(min_bore-INNER)<.005
    report=dict(passed=True,units='mm',minimum_bore_at_bead_crests_mm=INNER,
        relief_bore_mm=RELIEF_BORE,maximum_outer_diameter_mm=OUTER,overall_length_mm=LENGTH,
        body_length_mm=BODY,inner_beads=dict(count=2,section_radius_mm=.6,centres_z_mm=BEAD_Z),
        outer_edge_rounding_mm=dict(bottom=.35,top=.2),end_bead_height_mm=END_BEAD,
        radial_sections=sections,exported_bounds_mm=measured,exported_minimum_vertex_bore_mm=min_bore,
        closed_oriented_manifold=True,connected_components=1,triangles=len(faces),
        volume_mm3=actual.Volume,stl_sha256=hashlib.sha256(DEST.read_bytes()).hexdigest(),
        physical_status='Unqualified standalone trial; existing 6 mm enclosure pocket is not resized')
    (OUT/'validation.json').write_text(json.dumps(report,indent=2))
    print(json.dumps(report,indent=2))


if __name__=='__main__':main()
