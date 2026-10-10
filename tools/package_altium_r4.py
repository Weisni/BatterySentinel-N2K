"""Curated, hash-verified R4 release packaging; never changes design artifacts.

Default operation is a read-only plan. Actual packaging requires --native-final,
the caller's explicit final-release signal, successful current readback reports,
and a zero-violation native Altium DRC. It creates two download containers:
the complete editable Altium project and a separate JLCPCB PCBA upload bundle.
Extract the latter and upload its inner Panel-Gerber.zip, not the outer bundle.
"""
from __future__ import annotations

import argparse
from contextlib import ExitStack
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import tempfile
import zipfile

REPO=Path(__file__).resolve().parents[1]
SOURCE=REPO/'hardware/altium-r4'
OUTPUT=REPO/'output/releases'

ROOT_FILES=[
    'README.md','FIRMWARE.md','panel-ordering.md','electrical-review.md','jlcpcb-review.md',
    'Orion-Bridge-R4.PrjPcb','Orion-Bridge-R4.PcbDoc',
    'Orion-Bridge-R4-Power.SchDoc','Orion-Bridge-R4-Logic.SchDoc',
    'Orion-Bridge.SchLib','Orion-Bridge.PcbLib','Orion-Bridge.LibPkg',
    'Schaltplan-R4.pdf','Schaltplan-R4-Power.pdf','Schaltplan-R4-Logic.pdf',
    'Schaltplan-R4-Power.png','Schaltplan-R4-Logic.png',
    'orion-r4-design.json','orion-r4-routing.json','placement.json','layout-constraints.json',
    'logic-sourcing-overrides.json','power-components.json','model-overrides.json',
    'supplier-observations.json','jlcpcb-recommendations.json',
    'release-validation.json','independent-verification.json','native-gerber-review.json','native-binary-verification.json',
    'source-pcb-verification.json','mechanical-review.json',
    'schematic-render-validation.json','firmware-build-validation.json',
    'Design Rule Check - Orion-Bridge-R4.drc','Design Rule Check - Orion-Bridge-R4.html',
]
# No recursive directory glob: History, autosaves, proof variants and stale
# intermediate routing drawings cannot accidentally enter a customer release.
SUBDIRECTORIES={
    'source':{'.pcbdoc'},
    'models':{'.json','.step','.txt'},
    '3d-views':{'.json','.png'},
    'assembly':{'.json','.csv','.svg','.png'},
    'manufacturing':{'.json','.csv','.zip','.drl','.gtl','.gbl','.gts','.gbs','.gtp','.gbp','.gto','.gbo','.gko'},
    'JLCPCB-Panel':{'.json','.csv','.zip','.drl','.gtl','.gbl','.gts','.gbs','.gtp','.gbp','.gto','.gbo','.gko','.svg','.png'},
    # Deliberate 0.31-mm negative-control reports demonstrate rule enforcement;
    # their expected violations are not unresolved defects in the final PCB.
    'validation':{'.json','.drc','.html','.png'},
}
OPTIONAL_FINAL_REPORTS=[
    'native-drc-verification.json','native-drc-review.json','native-erc-verification.json',
    'native-erc-review.json','native-schematic-review.json','native-parameter-review.json',
    'native-library-review.json','native-ui-verification.json',
]
REQUIRED_PASSES=[
    'release-validation.json','independent-verification.json','native-gerber-review.json','native-binary-verification.json',
    'source-pcb-verification.json','mechanical-review.json',
    'manufacturing/manufacturing-verification.json',
    'JLCPCB-Panel/panel-preflight.json','JLCPCB-Panel/panel-readback.json',
    'JLCPCB-Panel/independent-panel-verification.json',
]
PCBA_FILES=[
    'panel-ordering.md','jlcpcb-review.md','release-validation.json',
    'JLCPCB-Panel/Orion-Bridge-R4-Panel-Gerber.zip',
    'JLCPCB-Panel/BOM-JLCPCB.csv','JLCPCB-Panel/CPL-JLCPCB.csv','JLCPCB-Panel/BOM-EXCLUDED.csv',
    'JLCPCB-Panel/Panel-70x70.svg','JLCPCB-Panel/Panel-70x70.png',
    'JLCPCB-Panel/manufacturing-manifest.json','JLCPCB-Panel/independent-panel-verification.json',
    'assembly/Bestueckung-R4.svg','assembly/Bestueckung-R4.png',
    'assembly/Bestueckung-R4-Orientierung.csv','assembly/Bestueckung-R4-validation.json',
]


def sha(raw):return hashlib.sha256(raw).hexdigest()
def read_json(path):return json.loads(path.read_text('utf-8-sig'))


def project_documents(root):
    result={}
    for name in ('Orion-Bridge-R4.PrjPcb','Orion-Bridge.LibPkg'):
        project=root/name
        documents=[]
        for value in re.findall(r'^DocumentPath=(.+)$',project.read_text('utf-8-sig'),re.MULTILINE):
            relative=Path(value.strip().strip('"').replace('\\','/'))
            if relative.is_absolute():
                raise ValueError('Project has a nonportable absolute DocumentPath: '+str(relative))
            resolved=(root/relative).resolve()
            if not resolved.is_relative_to(root.resolve()):
                raise ValueError('Project document reference leaves release root: '+str(relative))
            documents.append(resolved.relative_to(root.resolve()).as_posix())
        result[name]=documents
    return result


def collect(root):
    names=set(ROOT_FILES)
    # Altium may add its current DRC HTML as an explicit project document.
    # Preserve each actual relative reference, including Project Outputs/.
    for documents in project_documents(root).values():names.update(documents)
    for folder,extensions in SUBDIRECTORIES.items():
        path=root/folder
        if not path.is_dir():raise ValueError('Missing release folder: '+str(path))
        for item in path.iterdir():
            if item.is_file() and item.suffix.lower() in extensions:
                names.add(item.relative_to(root).as_posix())
    for name in OPTIONAL_FINAL_REPORTS:
        if (root/name).is_file() and read_json(root/name).get('passed') is True:
            names.add(name)
    for name in names:
        p=(root/name).resolve()
        if not p.is_relative_to(root.resolve()) or (root/name).is_symlink():
            raise ValueError('Release payload escapes source directory: '+name)
        if any(word in name.lower() for word in ('history','fixed-rout','prototype','failed','backup')):
            raise ValueError('Nonrelease artifact selected: '+name)
    return sorted(names)


def guard_current_reports(root):
    results=[]
    for project,documents in project_documents(root).items():
        missing=[name for name in documents if not (root/name).is_file()]
        if missing:raise ValueError('Missing '+project+' DocumentPath targets: '+', '.join(missing))
        results.append(dict(file=project,passed=True,document_paths=documents))
    for name in REQUIRED_PASSES:
        report=read_json(root/name)
        if report.get('passed') is not True or report.get('errors'):
            raise ValueError('Required final report is not passed: '+name)
        count=report.get('checks')
        if isinstance(count,(list,dict)):count=len(count)
        results.append(dict(file=name,passed=True,checks=count))
    independent=read_json(root/'independent-verification.json')
    if independent.get('final_binary_checked') is not True or independent.get('release_checks_complete') is not True:
        raise ValueError('Final native binary has not completed independent release checks')
    for name,digest in independent.get('input_sha256',{}).items():
        relative=Path(name.replace('\\','/'))
        path=(root/relative).resolve()
        if not path.is_relative_to(root.resolve()) or sha(path.read_bytes())!=digest:
            raise ValueError('Independent native report has stale input: '+name)
    native_hash=sha((root/'Orion-Bridge-R4.PcbDoc').read_bytes())
    if read_json(root/'native-gerber-review.json').get('native_sha256')!=native_hash:
        raise ValueError('Native/Gerber comparison is from a different saved PCB')
    binary_report=read_json(root/'native-binary-verification.json')
    if binary_report.get('binary_sha256')!=native_hash:
        raise ValueError('Native binary verification is not from the final saved PCB')
    control=binary_report.get('board_edge_negative_control',{})
    if control.get('passed') is not True or not control.get('violations',0):
        raise ValueError('Native board-edge negative control has not proven rule enforcement')
    control_file=root/'validation/BoardEdge-negative-0_31mm.drc'
    if sha(control_file.read_bytes())!=control.get('report_sha256'):
        raise ValueError('Native board-edge behavioral proof has a stale report hash')
    source_pcb=root/'source/Orion-Bridge-R4.PcbDoc'
    if read_json(root/'source-pcb-verification.json').get('source_sha256')!=sha(source_pcb.read_bytes()):
        raise ValueError('ASCII source-PCB comparison is from a different source file')
    for item in read_json(root/'schematic-render-validation.json'):
        source=Path(item['source'])
        if not source.is_absolute():source=REPO/source
        if sha(source.read_bytes())!=item['source_sha256']:
            raise ValueError('Schematic PDF/PNG preview is not from current SchDoc: '+str(source))
    drc=(root/'Design Rule Check - Orion-Bridge-R4.drc').read_text(encoding='utf-8-sig',errors='replace')
    counts=re.findall(r'(?:Violations Detected|Waived Violations)\s*:\s*(\d+)',drc)
    if len(counts)!=2 or any(int(n) for n in counts):
        raise ValueError('Native DRC must explicitly show zero detected and zero waived violations')
    if any(int(n) for n in re.findall(r'Rule Violations\s*:\s*(\d+)',drc)):
        raise ValueError('Native DRC contains a failing rule')
    design_hash=sha((root/'orion-r4-design.json').read_bytes())
    route_hash=sha((root/'orion-r4-routing.json').read_bytes())
    render=read_json(root/'3d-views/3D-render-validation.json')
    if render.get('design_sha256')!=design_hash or render.get('routing_sha256')!=route_hash:
        raise ValueError('Rendered views do not match the frozen design/routing snapshot')
    if read_json(root/'assembly/Bestueckung-R4-validation.json').get('source_sha256')!=design_hash:
        raise ValueError('Assembly orientation drawing is not from the frozen design')
    for folder in ('manufacturing','JLCPCB-Panel'):
        manifest=read_json(root/folder/'manufacturing-manifest.json')
        for source in manifest['sources']:
            path=Path(source['path'].replace('\\','/'))
            if not path.is_absolute():path=REPO/path
            if sha(path.read_bytes())!=source['sha256']:
                raise ValueError(folder+' has stale source hash: '+str(path))
        for name,digest in manifest['files'].items():
            if sha((root/folder/name).read_bytes())!=digest:
                raise ValueError(folder+' has stale output hash: '+name)
        if manifest.get('pcba_bom_complete') is not True:
            raise ValueError(folder+' does not have a complete sourced BOM')
        if folder=='JLCPCB-Panel' and (manifest.get('prototype_only') or not manifest.get('source_unit_routing_verified')):
            raise ValueError('Panel is a prototype export or has unverified unit routing')
        archive=root/folder/(manifest['name']+'-Gerber.zip')
        with zipfile.ZipFile(archive) as z:
            if z.testzip() is not None or set(z.namelist())!=set(manifest['files']):
                raise ValueError('Gerber ZIP CRC or entry-list mismatch: '+str(archive))
            for name in z.namelist():
                if sha(z.read(name))!=manifest['files'][name]:
                    raise ValueError('Gerber ZIP differs from checked data: '+name)
    return results


FULL_README='''Orion Bridge R4 – vollständiges Altium-Projekt

1. Das komplette Verzeichnis zusammenhängend entpacken.
2. Orion-Bridge-R4.PrjPcb in Altium öffnen; lokale SchLib/PcbLib sind enthalten.
3. README.md beschreibt Aufbau, Prüfungen und Dateien.
4. Für die Fertigung panel-ordering.md lesen und nur die zusammengehörigen
   Panel-Gerber, Panel-BOM und Panel-CPL aus JLCPCB-Panel verwenden.

Die source/-PCB ist die ASCII-Quelle; das Projekt verwendet die native Binär-PCB
im Hauptverzeichnis. Einzeldaten in manufacturing/ nicht mit Panel-CPL mischen.
3D-Modelle sind lokale Gehäusemodelle, keine zertifizierten Hersteller-STEPs.
PACKAGE-MANIFEST.json und SHA256SUMS.txt dokumentieren den Paketinhalt.
'''
PCBA_README='''Orion Bridge R4 – JLCPCB-PCBA-Dateien

Dieses ZIP ist ein Download-Paket. Nicht das ganze Paket als Gerber hochladen!
Zuerst entpacken, dann zusammengehörig verwenden:

Gerber: JLCPCB-Panel/Orion-Bridge-R4-Panel-Gerber.zip
BOM:    JLCPCB-Panel/BOM-JLCPCB.csv
CPL:    JLCPCB-Panel/CPL-JLCPCB.csv

70×70-mm-Kundenpanel mit genau einer 48×32-mm-Platine, Oberseitenbestückung,
Standard PCBA. Keine zusätzliche V-Cut-Panellierung ergänzen.
Alle Einstellungen und Bestellbemerkungen stehen in panel-ordering.md.
Die konkrete JLC-Bauteilverfügbarkeit und Orientierung anhand der Prüfzeichnung
assembly/Bestueckung-R4.svg beziehungsweise .png abgleichen.

Eine JLC-Bestellung wurde nicht ausgelöst; Hardware-Funktion und EMV sind noch
nicht an einer realen R4-Platine gemessen. J1-Kabel und Firmware separat ergänzen.
PACKAGE-MANIFEST.json und SHA256SUMS.txt dokumentieren den Paketinhalt.
'''


def make_archive(path,prefix,payload,kind,gates):
    files=dict(payload)
    files['START-HERE.txt']=(FULL_README if kind=='altium' else PCBA_README).encode('utf8')
    manifest=dict(format='Orion R4 release package v1',package_kind=kind,
        created_utc=datetime.now(timezone.utc).isoformat(),
        source_root='hardware/altium-r4',gates=gates,
        qualification='File integrity and completed recorded checks; see project release-validation and hardware limitations.',
        checksum_scope='files lists payload excluding PACKAGE-MANIFEST.json and SHA256SUMS.txt. SHA256SUMS additionally hashes PACKAGE-MANIFEST.json.',
        files={name:dict(bytes=len(raw),sha256=sha(raw)) for name,raw in sorted(files.items())})
    files['PACKAGE-MANIFEST.json']=(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n').encode('utf8')
    files['SHA256SUMS.txt']=''.join(f'{sha(raw)}  {name}\n' for name,raw in sorted(files.items())).encode('utf8')
    with zipfile.ZipFile(path,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for name,raw in sorted(files.items()):
            posix=PurePosixPath(prefix)/name
            if posix.is_absolute() or '..' in posix.parts:raise ValueError('Unsafe ZIP member')
            item=zipfile.ZipInfo(str(posix),date_time=(1980,1,1,0,0,0))
            item.compress_type=zipfile.ZIP_DEFLATED
            item.external_attr=0o100644<<16
            z.writestr(item,raw,compress_type=zipfile.ZIP_DEFLATED,compresslevel=9)
    with zipfile.ZipFile(path) as z:
        if z.testzip() is not None:raise ValueError('ZIP CRC readback failed')
        if len(z.infolist())!=len(files) or len(set(z.namelist()))!=len(files):
            raise ValueError('ZIP entry count or duplicate entries')
        if set(z.namelist())!={prefix+'/'+n for n in files}:raise ValueError('ZIP entry-list mismatch')
        for name,raw in files.items():
            if z.read(prefix+'/'+name)!=raw:raise ValueError('ZIP payload readback differs: '+name)
    return dict(name=path.name,sha256=sha(path.read_bytes()),bytes=path.stat().st_size,
                files=len(files),zip_crc_passed=True,all_payload_bytes_read_back=True,
                internal_sha256_manifest=True,prefix=prefix)


def publish_archives(staged,out,reports):
    """Copy verified ZIPs into exclusively created, parent-ACL-inheriting files.

    Moving files out of TemporaryDirectory on Windows preserves its private
    ACL, which can leave Explorer unable to read a release. Copy only bytes;
    do not copy metadata or replace an existing destination. If either copy
    fails, roll back only the destination files created by this call.
    """
    staged=staged.resolve();out=out.resolve()
    if not out.is_relative_to(REPO) or not staged.is_relative_to(out):
        raise ValueError('Unsafe release publishing paths')
    names=[report['name'] for report in reports]
    if len(set(names))!=len(names) or any(Path(name).name!=name for name in names):
        raise ValueError('Unsafe or duplicate release archive name')
    # Both archives must still match their completed ZIP/payload checks before
    # any destination is created. A later competing writer is caught by xb.
    for report in reports:
        raw=(staged/report['name']).read_bytes()
        if len(raw)!=report['bytes'] or sha(raw)!=report['sha256']:
            raise ValueError('Staged archive changed after validation: '+report['name'])
    created=[]
    try:
        with ExitStack() as handles:
            destinations=[]
            # Acquire every name before copying, so a pre-existing second ZIP
            # is never overwritten and the first new file is rolled back.
            for report in reports:
                target=out/report['name']
                destination=handles.enter_context(target.open('xb'))
                identity=os.fstat(destination.fileno())
                created.append((target,(identity.st_dev,identity.st_ino)))
                destinations.append((report,destination))
            for report,destination in destinations:
                with (staged/report['name']).open('rb') as source:
                    shutil.copyfileobj(source,destination)
                destination.flush()
                os.fsync(destination.fileno())
        # Verify the actual public files, not only the private staging copies.
        for report in reports:
            raw=(out/report['name']).read_bytes()
            if len(raw)!=report['bytes'] or sha(raw)!=report['sha256']:
                raise ValueError('Published archive readback differs: '+report['name'])
    except BaseException as error:
        for target,identity in reversed(created):
            try:
                current=target.lstat()
                if (current.st_dev,current.st_ino)==identity:
                    target.unlink()
                else:
                    error.add_note('Rollback left a replaced destination untouched: '+str(target))
            except FileNotFoundError:
                pass
            except OSError as cleanup_error:
                error.add_note('Could not remove new destination '+str(target)+': '+str(cleanup_error))
        raise


def package(root,out,native_final=False):
    root=root.resolve();out=out.resolve()
    if not root.is_relative_to(REPO) or not out.is_relative_to(REPO):
        raise ValueError('Release paths must stay in this repository workspace')
    names=collect(root)
    missing=[name for name in names if not (root/name).is_file()]
    plan=dict(source=str(root),output=str(out),full_payload_files=len(names),
        archives=['Orion-Bridge-R4-Altium.zip','Orion-Bridge-R4-JLCPCB-PCBA.zip'],
        missing_required_files=missing,action='read-only plan; --native-final required to create archives')
    if not native_final:return plan
    if missing:raise ValueError('Missing final release files: '+', '.join(missing))
    gates=guard_current_reports(root)
    out.mkdir(parents=True,exist_ok=True)
    targets=[out/name for name in plan['archives']]
    if any(p.exists() for p in targets):raise ValueError('Release archive already exists; refusing implicit overwrite')
    snapshot={name:(root/name).read_bytes() for name in names}
    pcba={name:snapshot[name] for name in PCBA_FILES}
    with tempfile.TemporaryDirectory(prefix='r4-package-',dir=out) as staging:
        # The staging directory is created underneath the verified output path;
        # no cleanup can reach another checkout or an arbitrary user directory.
        staged=Path(staging).resolve()
        if not staged.is_relative_to(out):raise ValueError('Unsafe staging path')
        reports=[]
        reports.append(make_archive(staged/targets[0].name,'Orion-Bridge-R4',snapshot,'altium',gates))
        reports.append(make_archive(staged/targets[1].name,'Orion-Bridge-R4-PCBA',pcba,'jlcpcb-pcba',gates))
        # Publish neither container if the native app or another builder changed
        # any selected source while the snapshot was being packaged.
        changed=[name for name,raw in snapshot.items() if (root/name).read_bytes()!=raw]
        if changed:raise ValueError('Release inputs changed during packaging: '+', '.join(changed))
        publish_archives(staged,out,reports)
    report=dict(passed=True,source_snapshot_stable=True,packages=reports,
        excluded=['History','autosaves','PrjPcbStructure cache','fixed routing intermediates','temporary or failed proof artifacts'])
    (out/'release-package-verification.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    (out/'SHA256SUMS.txt').write_text(''.join(f'{r["sha256"]}  {r["name"]}\n' for r in reports),encoding='ascii')
    return report


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source',type=Path,default=SOURCE)
    p.add_argument('--out',type=Path,default=OUTPUT)
    p.add_argument('--native-final',action='store_true',help='Run only after explicit final native-check signal; enforces all release gates')
    args=p.parse_args()
    print(json.dumps(package(args.source,args.out,args.native_final),indent=2,ensure_ascii=False))
