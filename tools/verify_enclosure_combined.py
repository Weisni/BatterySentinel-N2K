from pathlib import Path
import sys,json,zipfile,re,xml.etree.ElementTree as E,subprocess
sys.path.insert(0,'tools')
from verify_enclosure_v2_delivery import geometry_check
from package_enclosure_v2 import OUT,PR,SLICER
p=OUT/'Orion-V2-Complete-P2S.3mf';tmp=OUT/'combined-validation'
with zipfile.ZipFile(p) as z:
 s=E.fromstring(z.read('Metadata/model_settings.config'));names=[next(m.get('value') for m in o.findall('metadata') if m.get('key')=='name') for o in s.findall('object')]
 manifest=tmp/'geometry-manifest.json';manifest.write_text(json.dumps({'parts':[{'name':n,'path':str(Path('tmp/enclosure-v2-qa/combined-lid.stl').resolve() if n=='lid_body' else OUT/(n+'.stl'))} for n in names]}))
 report=json.loads((OUT/'combined-project-validation.json').read_text());report['geometry']=geometry_check(p,manifest)
 for row,temp,bed in zip(report['plates'],[255,245,235,255,235,245],[70,50,50,70,50,50]):
  code=z.read(f'Metadata/plate_{row["plate"]}.gcode').decode()
  assert re.search(r'^\s*M109 S'+str(temp)+r'\b',code,re.M)
  assert re.search(r'^\s*M190 S'+str(bed)+r'\b',code,re.M)
  used={int(f['id']) for f in row['filaments'] if f['used_for_object']=='true'}
  assert used==({1,2} if row['plate']==1 else {row['filament_slot']}),used
  row['verified_nozzle_C']=temp;row['verified_bed_C']=bed
  row['all_parts_sliced']=True
  assert all('; printing object '+n+' id:' in code for n in row['parts'])
 print('Exact mesh geometry, all object paths, temperatures and materials verified.',flush=True)
 (OUT/'combined-project-validation.json').write_text(json.dumps(report,indent=2))
cmd=[str(SLICER),str(p),'--allow-newer-file','--datadir',str(tmp/'data'),'--slice','0','--outputdir',str(tmp),'--export-3mf','roundtrip.3mf']
r=subprocess.run(cmd,capture_output=True,creationflags=subprocess.CREATE_NO_WINDOW,timeout=900)
(tmp/'roundtrip-log.txt').write_bytes(r.stdout+r.stderr)
assert r.returncode==0,r.returncode
with zipfile.ZipFile(tmp/'roundtrip.3mf') as z:
 for row in report['plates']:
  code=z.read(f'Metadata/plate_{row["plate"]}.gcode').decode()
  assert re.search(r'^\s*M109 S'+str(row['verified_nozzle_C'])+r'\b',code,re.M)
 report['reopened_without_external_profile_overrides']=True
 (OUT/'combined-project-validation.json').write_text(json.dumps(report,indent=2))
print('Reopened project and sliced all six plates using embedded profiles only.')
