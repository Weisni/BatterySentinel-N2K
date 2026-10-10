"""Combine V2 production and optional test plates into one native project."""
from package_enclosure_v2 import *
import math, shutil
TMP=OUT/'combined-validation';TMP.mkdir(exist_ok=True)

def main():
    parts=loadparts()
    machine=json.loads((PR/'p2s-machine.json').read_text());proc=json.loads((PR/'petg-process.json').read_text());tp=json.loads((PR/'tpu-air-process.json').read_text())
    filnames=['petg-body.json','petg-contrast.json','tpu-air-235.json','tpu-air-245.json']
    fils=[json.loads((PR/n).read_text()) for n in filnames]
    rigid=[n for n,p in parts.items() if p['material']=='PETG' and p['group']=='production' and n!='lid_markings']
    seals=['usb_gasket','service_switch_gasket','cable_seal_b6p8_L6p8']
    coupons=[n for n,p in parts.items() if p['material']=='PETG' and p['group']=='calibration']+['cable_pressure_cap','strain_relief_upper']
    optional=[n for n,p in parts.items() if p['material']=='TPU' and n not in seals+['lid_gasket']]
    groups=[('01 PETG enclosure - two colours',rigid,1),('02 TPU lid - 245C trial',['lid_gasket'],4),('03 TPU cable and service seals - 235C trial',seals,3),('04 OPTIONAL PETG fit coupons',coupons,1),('05 OPTIONAL TPU variants and calibration - 235C',optional,3),('06 OPTIONAL TPU calibration - 245C',['shore_comparison_pad','flow_wall_coupon','face_test_gasket'],4)]
    model=None;settings=E.Element('config');offset=0;layouts=[]
    for index,(title,names,slot) in enumerate(groups):
        src=TMP/f'input-{index}.3mf';row=project(src,names,parts,machine,proc,fils)
        assert row['plates']==1
        with zipfile.ZipFile(src) as z:
            m=E.fromstring(z.read('3D/3dmodel.model'));s=E.fromstring(z.read('Metadata/model_settings.config'))
            if model is None:
                model=copy.deepcopy(m);model.find(q('resources')).clear();model.find(q('build')).clear();config=json.loads(z.read('Metadata/project_settings.config'))
        maxid=max(int(o.get('id')) for o in m.find(q('resources')))
        for obj in m.find(q('resources')):
            obj.set('id',str(int(obj.get('id'))+offset))
            for c in obj.findall('.//'+q('component')):c.set('objectid',str(int(c.get('objectid'))+offset))
            model.find(q('resources')).append(obj)
        for item in m.find(q('build')):
            item.set('objectid',str(int(item.get('objectid'))+offset));tr=item.get('transform').split();tr[9]=str(float(tr[9])+(index%3)*307.2);tr[10]=str(float(tr[10])-(index//3)*307.2);item.set('transform',' '.join(tr));model.find(q('build')).append(item)
        for obj in s.findall('object'):
            obj.set('id',str(int(obj.get('id'))+offset))
            for p in obj.findall('part'):p.set('id',str(int(p.get('id'))+offset))
            for meta in obj.findall('.//metadata'):
                if meta.get('key')=='extruder' and slot>2:meta.set('value',str(slot))
            if slot>2:
                for key,val in tp.items():
                    if key not in ('name','type','from','instantiation','enable_prime_tower','wipe_tower_x','wipe_tower_y') and proc.get(key)!=val:
                        md(obj,**{key:','.join(val) if isinstance(val,list) else val})
            settings.append(obj)
        pl=s.find('plate')
        for meta in pl.findall('metadata'):
            if meta.get('key')=='plater_id':meta.set('value',str(index+1))
            if meta.get('key')=='plater_name':meta.set('value',title)
        md(pl,enable_prime_tower='1' if index==0 else '0')
        for meta in pl.findall('.//model_instance/metadata'):
            if meta.get('key') in ('object_id','identify_id'):meta.set('value',str(int(meta.get('value'))+offset))
        settings.append(pl);offset+=maxid
        layouts.append(dict(plate=index+1,name=title,filament_slot=slot,parts=names))
    E.SubElement(settings,'assemble')
    for meta in model.findall(q('metadata')):
        if meta.get('name')=='Title': meta.text='Orion V2.3 thin-wall enclosure - six plates'
    config.update(print_settings_id='Orion V2 complete - PETG with TPU object overrides',wipe_tower_x=['205']*6,wipe_tower_y=['210']*6,flush_volumes_matrix=['0' if i==j else '300' for i in range(4) for j in range(4)],flush_volumes_vector=['140']*8)
    seed=TMP/'combined-input.3mf'
    with zipfile.ZipFile(TMP/'input-0.3mf') as z:entries={n:z.read(n) for n in z.namelist()}
    entries['3D/3dmodel.model']=E.tostring(model,encoding='utf-8',xml_declaration=True);entries['Metadata/model_settings.config']=E.tostring(settings,encoding='utf-8',xml_declaration=True);entries['Metadata/project_settings.config']=json.dumps(config).encode()
    with zipfile.ZipFile(seed,'w',zipfile.ZIP_DEFLATED) as z:
        for n,b in entries.items():z.writestr(n,b)
    command=[str(SLICER),str(seed),'--allow-newer-file','--datadir',str(TMP/'data'),'--debug','2','--slice','0','--outputdir',str(TMP),'--export-3mf','Orion-V2-Complete-P2S.3mf','--load-settings',str(PR/'p2s-machine.json')+';'+str(PR/'petg-process.json'),'--load-filaments',';'.join(str(PR/n) for n in filnames)]
    print('Native slicing all six plates',flush=True)
    r=subprocess.run(command,capture_output=True,creationflags=subprocess.CREATE_NO_WINDOW,timeout=900)
    write(TMP/'invocation.json',dict(command=command,returncode=r.returncode,stdout=r.stdout.decode(errors='replace'),stderr=r.stderr.decode(errors='replace')))
    assert r.returncode==0,'See combined-validation/invocation.json'
    final=TMP/'Orion-V2-Complete-P2S.3mf'
    with zipfile.ZipFile(final) as z:
        assert z.testzip() is None
        si=E.fromstring(z.read('Metadata/slice_info.config'));assert len(si.findall('plate'))==6
        ms=E.fromstring(z.read('Metadata/model_settings.config'))
        for stat in ms.findall('.//mesh_stat'):
            assert all(int(stat.get(k,'0'))==0 for k in ('edges_fixed','degenerate_facets','facets_removed','facets_reversed','backwards_edges'))
        for row,p in zip(layouts,si.findall('plate')):
            data={m.get('key'):m.get('value') for m in p.findall('metadata')};assert data.get('outside')=='false',data
            code=z.read(f'Metadata/plate_{row["plate"]}.gcode').decode();assert 'G1 ' in code
            row['toolpath_bytes']=len(code);row['filaments']=[f.attrib for f in p.findall('filament')]
            row['temperature_commands']=sorted(set(__import__('re').findall(r'^M(?:104|109|140|190).*$',code,__import__('re').M)))
            if f'Metadata/plate_{row["plate"]}.png' in z.namelist(): (TMP/f'plate-{row["plate"]}.png').write_bytes(z.read(f'Metadata/plate_{row["plate"]}.png'))
        cfg=json.loads(z.read('Metadata/project_settings.config'))
        write(TMP/'effective-settings.json',cfg)
    shutil.copy2(final,OUT/final.name)
    write(OUT/'combined-project-validation.json',dict(passed=True,plates=layouts,filament_profiles=cfg['filament_settings_id'],native_slicer=str(SLICER),sha256=sha(final),physical_calibration_pending=True))
    print('Six plates sliced and native project saved.',flush=True)
if __name__=='__main__':main()

