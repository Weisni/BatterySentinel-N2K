"""Check final native geometry, deposited seal heights and PDF page bounds."""
from pathlib import Path
import json, zipfile, re, struct, math, itertools, xml.etree.ElementTree as ET
from collections import defaultdict,Counter
from package_orion_enclosure import read_stl,verify_native_geometry
import pdfplumber

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'hardware/altium-r5/enclosure/sealed-v2'
TMP=ROOT/'tmp/enclosure-v2-qa';TMP.mkdir(parents=True,exist_ok=True)

def geometry_check(native,manifest):
    core='http://schemas.microsoft.com/3dmanufacturing/core/2015/02';prod='http://schemas.microsoft.com/3dmanufacturing/production/2015/06'
    q=lambda t:'{'+core+'}'+t
    sources={x['name']:Path(x['path']) for x in json.loads(manifest.read_text())['parts']}
    models={};tol=.00005
    with zipfile.ZipFile(native) as archive:
        def model(path):
            if path not in models:models[path]=ET.fromstring(archive.read(path))
            return models[path]
        def transform(points,value):
            m=list(map(float,value.split())) if value else [1,0,0,0,1,0,0,0,1,0,0,0]
            return [tuple(sum(p[j]*m[j*3+k] for j in range(3))+m[9+k] for k in range(3)) for p in points]
        def mesh(path,oid):
            obj=next(o for o in model(path).find(q('resources')) if o.get('id')==oid);m=obj.find(q('mesh'))
            if m is not None:
                return [tuple(float(v.get(k)) for k in 'xyz') for v in m.find(q('vertices'))],[tuple(int(t.get('v'+str(k))) for k in (1,2,3)) for t in m.find(q('triangles'))]
            points=[];faces=[]
            for c in obj.find(q('components')):
                p,f=mesh(c.get('{'+prod+'}path',path).lstrip('/'),c.get('objectid'));p=transform(p,c.get('transform'))
                faces.extend(tuple(i+len(points) for i in face) for face in f);points.extend(p)
            return points,faces
        settings=ET.fromstring(archive.read('Metadata/model_settings.config'))
        names={o.get('id'):next(m.get('value') for m in o.findall('metadata') if m.get('key')=='name') for o in settings.findall('object')}
        results=[]
        for item in model('3D/3dmodel.model').find(q('build')):
            name=names[item.get('objectid')];ep,ef=read_stl(sources[name]);ap,af=mesh('3D/3dmodel.model',item.get('objectid'));ap=transform(ap,item.get('transform'))
            def norm(points):
                lo=[min(p[i] for p in points) for i in range(3)];return [tuple(p[i]-lo[i] for i in range(3)) for p in points]
            ep,ap=norm(ep),norm(ap);assert len(ef)==len(af),(name,len(ef),len(af))
            grid=defaultdict(list)
            for i,p in enumerate(ep):grid[tuple(math.floor(v/tol) for v in p)].append(i)
            mapping=[];maxerr=0
            for p in ap:
                cell=tuple(math.floor(v/tol) for v in p);candidates=[]
                for delta in itertools.product((-1,0,1),repeat=3):
                    for i in grid[tuple(cell[k]+delta[k] for k in range(3))]:
                        error=max(abs(p[k]-ep[i][k]) for k in range(3))
                        if error<=tol:candidates.append((error,i))
                assert candidates,(name,p)
                error,index=min(candidates);mapping.append(index);maxerr=max(maxerr,error)
            def cyclic(f):return min(tuple(f),tuple(f[1:]+f[:1]),tuple(f[2:]+f[:2]))
            assert Counter(cyclic(list(f)) for f in ef)==Counter(cyclic([mapping[i] for i in f]) for f in af),name
            results.append(dict(name=name,triangles=len(ef),max_vertex_error_mm=maxerr,oriented_triangles_identical=True))
    return dict(passed=True,parts=results,duplicate_vertices_at_colour_boundaries_allowed=True)

def main():
    report=json.loads((OUT/'package-validation.json').read_text())
    pts=[];faces=[]
    for name in ('lid_body','lid_markings'):
        p,f=read_stl(OUT/(name+'.stl'));faces.extend(tuple(i+len(pts) for i in face) for face in f);pts.extend(p)
    combined=TMP/'combined-lid.stl'
    with combined.open('wb') as stream:
        stream.write(b'Combined colour reference'.ljust(80,b'\0'));stream.write(struct.pack('<I',len(faces)))
        for face in faces:stream.write(struct.pack('<12fH',0,0,0,*(x for i in face for x in pts[i]),0))
    for project in report['projects']:
        print('Independent geometry and paths: '+project['path'],flush=True)
        names=[o['name'] for pl in project['layout'] for o in pl]
        mp=TMP/'manifest.json'
        mp.write_text(json.dumps(dict(parts=[dict(name=n,path=str(combined if n=='lid_body' else OUT/(n+'.stl'))) for n in names])))
        native=OUT/'native-validation'/Path(project['path']).stem/'verified.3mf'
        project['native_geometry_vs_STL']=geometry_check(native,mp)
        with zipfile.ZipFile(native) as z:
            heights=defaultdict(set);current=None;layer=None;tool=0;colours=defaultdict(set)
            for path in [n for n in z.namelist() if n.endswith('.gcode')]:
                for line in z.read(path).decode(errors='replace').splitlines():
                    if line.startswith('; Z_HEIGHT:'):layer=float(line.split(':',1)[1])
                    if re.fullmatch(r'T\d+',line.strip()):tool=int(line.strip()[1:])
                    if line.startswith('; printing object '):current=line.split('; printing object ',1)[1].split(' id:')[0]
                    elif line.startswith('; stop printing object '):current=None
                    if current and layer and re.match(r'G[123] ',line) and re.search(r'\b[XY][-+.\d]',line):
                        extrusion=re.search(r'\bE([-+.\d]+)',line)
                        if extrusion and float(extrusion[1])>0:heights[current].add(layer);colours[(current,tool)].add(layer)
            if 'TPU' in project['path']:
                for n in ('lid_gasket','usb_gasket','service_switch_gasket','face_test_gasket'):
                    assert abs(max(heights[n])-1.8)<.001,(n,heights[n])
                for n in names:
                    if n.startswith('cable_seal'):
                        expected=float(n.split('_L')[1].replace('p','.'));assert abs(max(heights[n])-expected)<.001,(n,heights[n])
                project['deposited_seal_heights_mm']={n:max(heights[n]) for n in names if 'gasket' in n or n.startswith('cable_seal')}
            if 'lid_body' in names:
                assert colours[('lid_body',1)]=={.2,.4},colours
                project['contrasting_lid_deposition_layers_mm']=sorted(colours[('lid_body',1)])
            project['all_expected_objects_have_deposition']=all(heights[n] for n in names)
            assert project['all_expected_objects_have_deposition'], [n for n in names if not heights[n]]
    pdfs=[]
    for name in ('Orion-Enclosure-V2-Assembly-EN.pdf','Orion-Enclosure-V2-Manufacturing-EN.pdf'):
        with pdfplumber.open(ROOT/'output/pdf'/name) as pdf:
            assert len(pdf.pages)==8
            count=0
            for i,page in enumerate(pdf.pages,1):
                assert page.extract_text().strip(),(name,i)
                for c in page.chars:
                    assert c['x0']>=0 and c['x1']<=page.width+.2 and c['top']>=0 and c['bottom']<=page.height+.2,(name,i,c)
                    assert c['text']!='\ufffd'
                count+=len(page.extract_text().split())
            pdfs.append(dict(file=name,pages=8,words=count,text_inside_page=True,replacement_glyphs=0))
    report['pdf_checks']=pdfs;report['passed']=True
    (OUT/'package-validation.json').write_text(json.dumps(report,indent=2))
    print('Geometry, bead toolpath heights, lid colours and PDF bounds passed.')

if __name__=='__main__':main()
