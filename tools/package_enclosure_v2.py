"""Prepare independent V2 material projects and verify native Quack slicing."""
from pathlib import Path
import json, copy, zipfile, subprocess, time, hashlib, xml.etree.ElementTree as E
from package_orion_enclosure import read_stl,mesh_check

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'hardware/altium-r5/enclosure/sealed-v2'
PR=OUT/'profiles';PR.mkdir(exist_ok=True)
OLD=ROOT/'hardware/altium-r5/enclosure/sealed-print'
SLICER=Path('C:/Program Files/QuackSlicer/quack-slicer.exe')
CORE='http://schemas.microsoft.com/3dmanufacturing/core/2015/02'
E.register_namespace('',CORE)
def q(s):return '{'+CORE+'}'+s
def write(p,data):p.write_text(json.dumps(data,indent=2),encoding='utf8')
def md(el,**data):
    for k,v in data.items():E.SubElement(el,'metadata',key=k,value=str(v))
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()

def profiles():
    # New conservative V2 presets. Old saved files and user account are not edited.
    machine=json.loads((OLD/'profiles/p2s-machine.json').read_text())
    process=json.loads((OLD/'profiles/enclosure-process.json').read_text())
    process.update(name='Orion V2 PETG prototype 0.20 P2S',wall_loops='6',
                   tree_support_wall_count='0',raft_first_layer_expansion='0',
                   enable_prime_tower='1',wipe_tower_x=['205'],wipe_tower_y=['210'],
                   prime_tower_width='35',prime_volume='25')
    petg=json.loads((OLD/'profiles/petg-filament.json').read_text())
    petg.update(name='Orion V2 PETG - calibrate actual spool',filament_max_volumetric_speed=['12','12'],filament_colour=['#395F75'])
    contrast=copy.deepcopy(petg);contrast.update(name='Orion V2 contrasting PETG',filament_colour=['#F5F5ED'])
    tpu=json.loads((OLD/'profiles/tpu-filament.json').read_text())
    tpu.update(filament_type=['TPU'],filament_max_volumetric_speed=['2','2'],
               filament_flow_ratio=['1','1'],fan_min_speed=['30'],fan_max_speed=['30'],
               additional_cooling_fan_speed=['0'],slow_down_for_layer_cooling=['0'],
               close_fan_the_first_x_layers=['2'],fan_cooling_layer_time=['0'],
               filament_retraction_length=['0.4','0.4'],filament_retraction_speed=['20','20'],
               filament_colour=['#EEB03F'],enable_pressure_advance=['0'])
    for key in ('hot_plate_temp','hot_plate_temp_initial_layer','textured_plate_temp','textured_plate_temp_initial_layer'):
        tpu[key]=['50']
    tprocess=copy.deepcopy(process)
    tprocess.update(name='Orion V2 TPU Air calibration 0.20 P2S',wall_loops='3',
        top_shell_layers='5',bottom_shell_layers='5',sparse_infill_density='100%',sparse_infill_pattern='rectilinear',
        enable_prime_tower='0',initial_layer_speed=['15','15'],initial_layer_infill_speed=['15','15'],
        outer_wall_speed=['20','20'],inner_wall_speed=['20','20'],internal_solid_infill_speed=['20','20'],
        top_surface_speed=['20','20'],sparse_infill_speed=['20','20'],small_perimeter_speed=['20','20'],
        line_width='0.42',outer_wall_line_width='0.42',inner_wall_line_width='0.42',
        initial_layer_line_width='0.42',top_surface_line_width='0.42',
        internal_solid_infill_line_width='0.42',enable_overhang_speed='0',
        default_acceleration=['1000','1000'],outer_wall_acceleration=['500','500'])
    write(PR/'p2s-machine.json',machine);write(PR/'petg-process.json',process);write(PR/'tpu-air-process.json',tprocess)
    write(PR/'petg-body.json',petg);write(PR/'petg-contrast.json',contrast)
    for temp in (235,245,255):
        f=copy.deepcopy(tpu);f.update(name=f'SainSmart TPU Air {temp}C - UNCALIBRATED FLOW',
                                     nozzle_temperature=[str(temp),str(temp)],nozzle_temperature_initial_layer=[str(temp),str(temp)])
        write(PR/f'tpu-air-{temp}.json',f)
    return machine,process,petg,contrast,tprocess

def loadparts():
    data=json.loads((OUT/'print-manifest.json').read_text())['parts'];parts={}
    for p in data:
        pts,faces=read_stl(OUT/p['path']);check=mesh_check(pts,faces);assert check['passed'],p['name']
        parts[p['name']]=dict(p,points=pts,faces=faces,check=check)
    return parts

def project(path,names,parts,machine,process,filaments):
    model=E.Element(q('model'),unit='millimeter')
    E.SubElement(model,q('metadata'),name='Application').text='BambuStudio-02.07.01.57'
    E.SubElement(model,q('metadata'),name='BambuStudio:3mfVersion').text='1'
    E.SubElement(model,q('metadata'),name='Title').text=path.stem
    res=E.SubElement(model,q('resources'));build=E.SubElement(model,q('build'));settings=E.Element('config')
    objects=[];uid=0
    for name in names:
        components=['lid_body','lid_markings'] if name=='lid_body' else [name]
        mesh_ids=[]
        bounds=parts[components[0]]['check']['bounds_mm'];origin=bounds[0]
        for comp in components:
            uid+=1;mesh_ids.append(uid)
            ob=E.SubElement(res,q('object'),id=str(uid),type='model',name=comp)
            mesh=E.SubElement(ob,q('mesh'));vs=E.SubElement(mesh,q('vertices'));fs=E.SubElement(mesh,q('triangles'))
            for pt in parts[comp]['points']:E.SubElement(vs,q('vertex'),**{k:f'{pt[i]-origin[i]:.8g}' for i,k in enumerate('xyz')})
            for f in parts[comp]['faces']:E.SubElement(fs,q('triangle'),**{f'v{i+1}':str(k) for i,k in enumerate(f)})
        uid+=1;parent=E.SubElement(res,q('object'),id=str(uid),type='model',name=name)
        cc=E.SubElement(parent,q('components'))
        for child in mesh_ids:E.SubElement(cc,q('component'),objectid=str(child))
        setting=E.SubElement(settings,'object',id=str(uid));md(setting,name=name,extruder=1)
        if name in ('cable_pressure_cap','strain_relief_upper'):md(setting,sparse_infill_density='100%')
        for child,comp in zip(mesh_ids,components):
            item=E.SubElement(setting,'part',id=str(child),subtype='normal_part');md(item,name=comp,extruder=2 if comp=='lid_markings' else 1,source_file=comp+'.stl')
            E.SubElement(item,'mesh_stat',face_count=str(len(parts[comp]['faces'])),edges_fixed='0',degenerate_facets='0',facets_removed='0',facets_reversed='0',backwards_edges='0')
        objects.append(dict(name=name,id=uid,width=bounds[1][0]-bounds[0][0],height=bounds[1][1]-bounds[0][1],components=components))
    plates=[];x=y=15.;row=0.;current=[]
    for ob in sorted(objects,key=lambda a:(-a['height'],-a['width'])):
        w,h=ob['width'],ob['height']
        if x+w>240:x=15;y+=row+10;row=0
        if y+h>195:plates.append(current);current=[];x=y=15;row=0
        ob['xy']=[x,y];current.append(ob);x+=w+10;row=max(row,h)
    if current:plates.append(current)
    for i,plate in enumerate(plates,1):
        ox=((i-1)%2)*307.2;oy=-((i-1)//2)*307.2
        pe=E.SubElement(settings,'plate');md(pe,plater_id=i,plater_name=f'{path.stem} / {i}',locked='false')
        for ob in plate:
            x,y=ob['xy'];E.SubElement(build,q('item'),objectid=str(ob['id']),transform=f'1 0 0 0 1 0 0 0 1 {x+ox} {y+oy} 0',printable='1')
            inst=E.SubElement(pe,'model_instance');md(inst,object_id=ob['id'],instance_id=0,identify_id=ob['id'])
    E.SubElement(settings,'assemble')
    ignored={'name','type','from','instantiation','setting_id','description','version','compatible_printers','filament_id','inherits','include'}
    config={k:v for source in [machine,process] for k,v in source.items() if k not in ignored}
    for key in set().union(*(f.keys() for f in filaments)):
        if key in ignored:continue
        if all(isinstance(f.get(key),list) for f in filaments):config[key]=sum((f[key] for f in filaments),[])
    config.update(printer_settings_id=machine['name'],print_settings_id=process['name'],
        filament_settings_id=[f['name'] for f in filaments],filament_ids=[f.get('filament_id','GFTPU') for f in filaments],
        curr_bed_type='Textured PEI Plate',filament_map=['1']*len(filaments),
        filament_volume_map=['0']*len(filaments),inherits_group=['']*(len(filaments)+2),
        different_settings_to_system=['']*(len(filaments)+2))
    if len(filaments)==2:config.update(flush_volumes_matrix=['0','300','300','0'],flush_volumes_vector=['140','140','140','140'])
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml','<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/><Default Extension="config" ContentType="application/xml"/></Types>')
        z.writestr('_rels/.rels','<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/></Relationships>')
        z.writestr('3D/3dmodel.model',E.tostring(model,encoding='utf-8',xml_declaration=True))
        z.writestr('Metadata/model_settings.config',E.tostring(settings,encoding='utf-8',xml_declaration=True))
        z.writestr('Metadata/project_settings.config',json.dumps(config,indent=2))
    return dict(path=path.name,plates=len(plates),objects=len(objects),layout=plates)

def slice_project(row,process,filaments):
    folder=OUT/'native-validation'/Path(row['path']).stem;folder.mkdir(parents=True,exist_ok=True)
    command=[str(SLICER),str(OUT/row['path']),'--allow-newer-file','--datadir',str(folder/'data'),'--debug','2',
             '--curr-bed-type','Textured PEI Plate','--slice','0','--outputdir',str(folder),'--export-3mf','verified.3mf',
             '--load-settings',str(PR/'p2s-machine.json')+';'+str(PR/process),
             '--load-filaments',';'.join(str(PR/f) for f in filaments)]
    start=time.time();r=subprocess.run(command,capture_output=True,creationflags=subprocess.CREATE_NO_WINDOW,timeout=900)
    invocation=dict(command=command,returncode=r.returncode,seconds=time.time()-start,
                    stdout=r.stdout.decode(errors='replace'),stderr=r.stderr.decode(errors='replace'))
    write(folder/'invocation.json',invocation)
    if r.returncode:raise RuntimeError(f'{row["path"]}: native slicing failed ({r.returncode}); {folder}')
    with zipfile.ZipFile(folder/'verified.3mf') as z:
        assert z.testzip() is None
        codes=[n for n in z.namelist() if n.endswith('.gcode')];assert len(codes)==row['plates'],codes
        cfg=json.loads(z.read('Metadata/project_settings.config'));ms=E.fromstring(z.read('Metadata/model_settings.config'))
        for stat in ms.findall('.//mesh_stat'):
            assert all(int(stat.get(k,'0'))==0 for k in ('edges_fixed','degenerate_facets','facets_removed','facets_reversed','backwards_edges'))
        si=E.fromstring(z.read('Metadata/slice_info.config'));summ=[]
        for i,p in enumerate(si.findall('plate'),1):
            data={m.get('key'):m.get('value') for m in p.findall('metadata')}
            assert data.get('outside')=='false',data
            code=z.read(f'Metadata/plate_{i}.gcode').decode(errors='replace');assert len(code)>1000 and 'G1 ' in code
            summ.append(dict(plate=i,toolpath_bytes=len(code),metadata=data,filaments=[f.attrib for f in p.findall('filament')]))
        row.update(native_passed=True,no_mesh_repair=True,sliced_plates=summ,actual_settings={k:cfg.get(k) for k in
            ('printer_settings_id','nozzle_diameter','filament_type','nozzle_temperature','filament_flow_ratio','filament_max_volumetric_speed','wall_loops','layer_height','outer_wall_speed','sparse_infill_density')})
    return row

def main():
    machine,process,petg,contrast,tp=profiles();parts=loadparts();report=[]
    rigid=[n for n,p in parts.items() if p['material']=='PETG' and p['group']=='production' and n!='lid_markings']
    cal=[n for n,p in parts.items() if p['material']=='PETG' and p['group']=='calibration']+['cable_pressure_cap','strain_relief_upper']
    flex=[n for n,p in parts.items() if p['material']=='TPU']
    jobs=[('Orion-V2-PETG.3mf',rigid,process,[petg,contrast],'petg-process.json',['petg-body.json','petg-contrast.json']),
          ('Orion-V2-PETG-Coupons.3mf',cal,{**process,'enable_prime_tower':'0'},[petg],'petg-process.json',['petg-body.json'])]
    for temp in (235,245,255):
        fil=json.loads((PR/f'tpu-air-{temp}.json').read_text())
        jobs.append((f'Orion-V2-TPU-Air-{temp}C.3mf',flex,tp,[fil],'tpu-air-process.json',[f'tpu-air-{temp}.json']))
    for name,names,proc,fil,procpath,filpaths in jobs:
        print('Preparing '+name,flush=True);row=project(OUT/name,names,parts,machine,proc,fil)
        print('Native slicing '+name,flush=True);row=slice_project(row,procpath,filpaths);report.append(row)
        write(OUT/'package-validation.json',dict(passed=len(report)==len(jobs),slicer=str(SLICER),projects=report,
            previous_project_unchanged=True,flow_status='Seed 1.00; physical calibration required',cached_gcode_in_deliverables=False))
    print('All five material projects passed native slicing and plate/mesh checks.',flush=True)

if __name__=='__main__':main()
