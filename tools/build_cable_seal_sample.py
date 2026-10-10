"""Export and validate the explicitly dimensioned straight cable-seal sample."""
from collections import Counter, defaultdict
from pathlib import Path
import hashlib
import json
import math
import struct

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'output/Kabeldichtung_ID6p8_AD11p5_L9mm.stl'
REPORT = ROOT / 'hardware/altium-r5/enclosure/cable-seal-sample/validation.json'
INNER, OUTER, LENGTH = 6.8, 11.5, 9.0
SEGMENTS = 512


def subtract(a, b):
    return tuple(x-y for x, y in zip(a, b))


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


def dot(a, b):
    return sum(x*y for x, y in zip(a, b))


def main():
    vertices = [(radius*math.cos(2*math.pi*i/SEGMENTS),
                 radius*math.sin(2*math.pi*i/SEGMENTS), z)
                for radius, z in ((OUTER/2, 0), (OUTER/2, LENGTH),
                                  (INNER/2, 0), (INNER/2, LENGTH))
                for i in range(SEGMENTS)]
    faces = []
    for i in range(SEGMENTS):
        j = (i+1) % SEGMENTS
        ob, ot, ib, it = i, SEGMENTS+i, 2*SEGMENTS+i, 3*SEGMENTS+i
        nb, nt, ni, nu = j, SEGMENTS+j, 2*SEGMENTS+j, 3*SEGMENTS+j
        for a,b,c,d in ((ob,nb,nt,ot), (ib,it,nu,ni),
                        (ot,nt,nu,it), (ob,ib,ni,nb)):
            faces.extend(((a,b,c), (a,c,d)))
    DEST.parent.mkdir(parents=True, exist_ok=True)
    with DEST.open('wb') as stream:
        stream.write(b'Cable seal | mm | ID6.8 OD11.5 length9 | axis Z'.ljust(80,b'\0'))
        stream.write(struct.pack('<I', len(faces)))
        for indices in faces:
            a,b,c = (vertices[i] for i in indices)
            normal = cross(subtract(b,a), subtract(c,a))
            size = math.sqrt(dot(normal,normal))
            normal = tuple(x/size for x in normal)
            stream.write(struct.pack('<12fH', *normal, *a, *b, *c, 0))

    # Validate the actual exported float32 STL, including its seam and bore.
    raw = DEST.read_bytes()
    count, = struct.unpack_from('<I', raw, 80)
    assert len(raw) == 84+50*count
    points, indices, triangles = [], {}, []
    for offset in range(84, len(raw), 50):
        record = struct.unpack_from('<12fH', raw, offset)
        face = []
        for start in (3,6,9):
            point = record[start:start+3]
            if point not in indices:
                indices[point] = len(points)
                points.append(point)
            face.append(indices[point])
        triangles.append(face)
    edges, balance, neighbours = Counter(), Counter(), defaultdict(set)
    volume = 0.0
    for face in triangles:
        a,b,c = (points[i] for i in face)
        normal = cross(subtract(b,a), subtract(c,a))
        assert dot(normal,normal) > 1e-12
        volume += dot(a,cross(b,c))/6
        for u,v in zip(face,face[1:]+face[:1]):
            key = tuple(sorted((u,v)))
            edges[key] += 1
            balance[key] += 1 if u<v else -1
            neighbours[u].add(v); neighbours[v].add(u)
    assert all(n == 2 for n in edges.values()) and not any(balance.values())
    seen, todo = set(), [0]
    while todo:
        i = todo.pop()
        if i not in seen:
            seen.add(i); todo.extend(neighbours[i]-seen)
    assert len(seen) == len(points)
    lower = [min(p[i] for p in points) for i in range(3)]
    upper = [max(p[i] for p in points) for i in range(3)]
    bounds = [b-a for a,b in zip(lower,upper)]
    assert all(abs(a-b) < 1e-5 for a,b in zip(bounds,(OUTER,OUTER,LENGTH)))
    radii = [math.hypot(p[0],p[1]) for p in points]
    assert all(min(abs(r-INNER/2),abs(r-OUTER/2)) < 1e-5 for r in radii)
    expected = math.pi*(OUTER**2-INNER**2)*LENGTH/4
    assert volume > 0 and abs(volume-expected)/expected < 0.0001
    report = dict(passed=True, units='mm', geometry='Straight unsplit annular cylinder; flat ends; no beads or chamfers',
        inner_diameter_mm=INNER, outer_diameter_mm=OUTER, length_mm=LENGTH,
        radial_wall_mm=(OUTER-INNER)/2, print_axis='Z', bounds_mm=[lower,upper],
        radial_chord_error_limit_mm=(OUTER/2)*(1-math.cos(math.pi/SEGMENTS)),
        vertices=len(points), triangles=count, connected_components=1,
        closed_oriented_manifold=True, mesh_volume_mm3=volume,
        analytical_volume_mm3=expected, physical_fit_and_sealing='Not tested',
        sha256=hashlib.sha256(raw).hexdigest())
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report,indent=2))


if __name__ == '__main__':
    main()
