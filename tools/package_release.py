"""Create and verify public Orion release assets from a validated standard build."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import zipfile

from verify_ota_image import inspect_image

MANUAL = 'BatterySentinel-N2K-Orion-R5-Betriebs-und-Installationsanleitung-DE.pdf'
VERSION = re.compile(r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-rc\.[1-9][0-9]*)?')


def release_identity(version):
    if len(version.encode('utf8')) > 31 or not VERSION.fullmatch(version):
        raise ValueError('Expected X.Y.Z or X.Y.Z-rc.N release version')
    return 'v'+version, 'rc' if '-rc.' in version else 'stable'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def check_partitions(data):
    found = {}
    spans = []
    for position in range(0, len(data)-31, 32):
        magic,t,s,offset,size,label,flags = struct.unpack_from('<HBBII16sI',data,position)
        if magic in (0xFFFF,0xEBEB): break
        if magic != 0x50AA or not size or offset+size > 0x400000:
            raise ValueError('Invalid partition table')
        if (t,s) in found: raise ValueError('Duplicate partition subtype')
        found[t,s]=(offset,size)
        spans.append((offset,offset+size))
        if flags: raise ValueError('Unsupported partition flags')
    expected={(1,2):(0x9000,0x5000),(1,0):(0xE000,0x2000),
              (0,0x10):(0x10000,0x1E0000),(0,0x11):(0x1F0000,0x1E0000)}
    if any(found.get(key)!=value for key,value in expected.items()):
        raise ValueError('Unexpected standard OTA/NVS partition layout')
    spans.sort()
    if any(left[1]>right[0] for left,right in zip(spans,spans[1:])):
        raise ValueError('Overlapping partition layout')


def package_release(root, build, framework, out, commit, run_url):
    if not re.fullmatch(r'[0-9a-f]{40}',commit):
        raise ValueError('Release requires an exact source commit')
    if out.exists() and any(out.iterdir()): raise FileExistsError(out)
    app=(build/'firmware.bin').read_bytes()
    info=inspect_image(app,'orion-dongle')
    tag,channel=release_identity(info.version)
    app_name=f'orion-dongle-{info.version}.bin'
    boot=(build/'bootloader.bin').read_bytes()
    if len(boot)<24 or len(boot)>0x8000 or boot[0]!=0xE9 or struct.unpack_from('<H',boot,12)[0]!=5:
        raise ValueError('Invalid ESP32-C3 bootloader')
    partitions=(build/'partitions.bin').read_bytes()
    if len(partitions)>0x1000: raise ValueError('Partition image overlaps NVS')
    check_partitions(partitions)
    boot_app=(framework/'tools/partitions/boot_app0.bin').read_bytes()
    if len(boot_app)!=0x2000: raise ValueError('Invalid OTA initialization image')
    manual=(root/'output/pdf'/MANUAL).read_bytes()
    if not manual.startswith(b'%PDF-'): raise ValueError('Invalid release manual')
    notes=(root/f'docs/releases/{info.version}.md').read_bytes()
    pieces={app_name:app,'bootloader.bin':boot,'partitions.bin':partitions,'boot_app0.bin':boot_app}
    offsets={app_name:'0x10000','bootloader.bin':'0x0','partitions.bin':'0x8000','boot_app0.bin':'0xe000'}
    layout={'target':info.target,'version':info.version,'sourceCommit':commit,
            'nvsPreserved':True,'flashOffsets':offsets,
            'files':{name:{'bytes':len(data),'sha256':digest(data)} for name,data in pieces.items()}}
    instructions=f'''# Orion Bridge {info.version}: USB recovery / initial programming

Use SERVICE before connecting USB; disconnect the boat-side supply and CAN.
The application is for the 4 MB ESP32-C3 SuperMini on Orion-R5.
Install Espressif esptool, open a terminal in this extracted directory, and use
the board's USB port (replace PORT with the actual serial port):

    python -m esptool --chip esp32c3 --port PORT write_flash 0x0 bootloader.bin 0x8000 partitions.bin 0xe000 boot_app0.bin 0x10000 {app_name}

Do not erase the whole flash. The listed segments leave 0x9000-0xdfff (NVS)
untouched; OTA slot selection is initialized to app0. Saved settings still
require a physical preservation check. For normal phone OTA, upload only
{app_name}, never this ZIP or a bootloader/merged image. See the German manual.
'''
    out.mkdir(parents=True,exist_ok=True)
    (out/app_name).write_bytes(app)
    usb_name=f'orion-dongle-{info.version}-usb.zip'
    with zipfile.ZipFile(out/usb_name,'w',zipfile.ZIP_DEFLATED) as bundle:
        for name,data in pieces.items(): bundle.writestr(name,data)
        bundle.writestr('flash-layout.json',json.dumps(layout,indent=2)+'\n')
        bundle.writestr('README.md',instructions)
    (out/MANUAL).write_bytes(manual)
    (out/'RELEASE-NOTES.md').write_bytes(notes)
    names=[app_name,usb_name,MANUAL,'RELEASE-NOTES.md']
    manifest={'schema':1,'tag':tag,'channel':channel,'version':info.version,
              'target':info.target,'sourceCommit':commit,'validationRun':run_url,
              'applicationBytes':info.size,'otaSlotBytes':0x1E0000,
              'files':{name:{'bytes':(out/name).stat().st_size,
                             'sha256':digest((out/name).read_bytes())} for name in names}}
    (out/'release-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
    names.append('release-manifest.json')
    (out/'SHA256SUMS.txt').write_text(''.join(f'{digest((out/name).read_bytes())}  {name}\n'
                                           for name in names),encoding='ascii')
    verify_package(out)
    return manifest


def verify_package(folder):
    manifest=json.loads((folder/'release-manifest.json').read_text(encoding='utf8'))
    tag,channel=release_identity(manifest['version'])
    if (manifest['tag'],manifest['channel'],manifest['target'])!=(tag,channel,'orion-dongle'):
        raise ValueError('Release identity mismatch')
    if not re.fullmatch(r'[0-9a-f]{40}',manifest['sourceCommit']): raise ValueError('Invalid source commit')
    expected={f'orion-dongle-{manifest["version"]}.bin',f'orion-dongle-{manifest["version"]}-usb.zip',
              MANUAL,'RELEASE-NOTES.md'}
    if set(manifest['files'])!=expected: raise ValueError('Unexpected release asset list')
    all_names=expected|{'release-manifest.json','SHA256SUMS.txt'}
    if {p.name for p in folder.iterdir()}!=all_names: raise ValueError('Extra or missing release asset')
    for name,record in manifest['files'].items():
        data=(folder/name).read_bytes()
        if len(data)!=record['bytes'] or digest(data)!=record['sha256']: raise ValueError('Asset integrity mismatch: '+name)
    checks={}
    for row in (folder/'SHA256SUMS.txt').read_text(encoding='ascii').splitlines():
        value,name=row.split('  ',1)
        if name in checks: raise ValueError('Duplicate checksum')
        checks[name]=value
    if set(checks)!=all_names-{'SHA256SUMS.txt'}: raise ValueError('Checksum asset list mismatch')
    for name,value in checks.items():
        if digest((folder/name).read_bytes())!=value: raise ValueError('Checksum mismatch: '+name)
    app=(folder/f'orion-dongle-{manifest["version"]}.bin').read_bytes()
    info=inspect_image(app,'orion-dongle',manifest['version'])
    if info.size!=manifest['applicationBytes'] or manifest['otaSlotBytes']!=0x1E0000: raise ValueError('Image size mismatch')
    with zipfile.ZipFile(folder/f'orion-dongle-{manifest["version"]}-usb.zip') as bundle:
        if bundle.testzip(): raise ValueError('Corrupt USB ZIP')
        layout=json.loads(bundle.read('flash-layout.json'))
        expected_offsets={f'orion-dongle-{manifest["version"]}.bin':'0x10000',
                          'bootloader.bin':'0x0','partitions.bin':'0x8000','boot_app0.bin':'0xe000'}
        if layout['flashOffsets']!=expected_offsets or layout['sourceCommit']!=manifest['sourceCommit']:
            raise ValueError('USB layout mismatch')
        if layout['version']!=manifest['version'] or layout['target']!='orion-dongle': raise ValueError('USB identity mismatch')
        if set(bundle.namelist())!=set(expected_offsets)|{'flash-layout.json','README.md'}: raise ValueError('USB member mismatch')
        if bundle.read(f'orion-dongle-{manifest["version"]}.bin')!=app: raise ValueError('USB application mismatch')
        check_partitions(bundle.read('partitions.bin'))
        for name,offset in expected_offsets.items():
            data=bundle.read(name);record=layout['files'][name];start=int(offset,16)
            if digest(data)!=record['sha256'] or len(data)!=record['bytes']: raise ValueError('USB integrity mismatch')
            if not (start+len(data)<=0x9000 or start>=0xE000): raise ValueError('USB segment overlaps NVS')
    return manifest


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--commit',required=True)
    parser.add_argument('--run-url',default='')
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--framework',type=Path,default=Path.home()/'.platformio/packages/framework-arduinoespressif32')
    args=parser.parse_args();root=Path(__file__).resolve().parents[1]
    print(json.dumps(package_release(root,root/'.pio/build/orion_dongle',args.framework,args.output,args.commit,args.run_url)))


if __name__=='__main__': main()
