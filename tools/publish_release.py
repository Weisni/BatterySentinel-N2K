"""Publish a verified CI package as a draft first, then stable or RC release.

Requires GH_TOKEN and gh. Published tags/assets are never overwritten. This is
an external write operation; run only for an explicitly authorized release.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from package_release import verify_package


def github(args):
    return subprocess.check_output(['gh',*args],text=True).strip()


def publish_release(folder,repo,tag,commit,run=github):
    manifest=verify_package(folder)
    if manifest['tag']!=tag or manifest['sourceCommit']!=commit:
        raise ValueError('Package does not match requested tag/commit')
    def remote_commit():
        return run(['api',f'repos/{repo}/commits/{tag}','--jq','.sha']).strip()
    if remote_commit()!=commit:raise ValueError('Remote tag does not match validated commit')
    def find_release():
        return next((r for r in json.loads(run(['api',f'repos/{repo}/releases?per_page=100']))
                     if r['tag_name']==tag),None)
    release=find_release()
    assets=sorted(folder.iterdir())
    rc=manifest['channel']=='rc'
    if release:
        if not release['draft']:raise ValueError('Published release already exists; refusing replacement')
        if release['target_commitish']!=commit or release['prerelease']!=rc:
            raise ValueError('Existing draft belongs to a different source/channel')
        run(['release','upload',tag,*map(str,assets),'--repo',repo,'--clobber'])
    else:
        title=f'Orion Bridge {manifest["version"]}'+(' (Release Candidate)' if rc else '')
        args=['release','create',tag,*map(str,assets),'--repo',repo,'--verify-tag',
              '--target',commit,'--title',title,'--notes-file',str(folder/'RELEASE-NOTES.md'),
              '--draft','--latest=false']
        if rc:args.append('--prerelease')
        run(args)
    release=find_release()
    if not release or not release['draft']:raise ValueError('Expected uploaded draft')
    expected={p.name:p for p in assets}
    if {a['name'] for a in release['assets']}!=set(expected):raise ValueError('Uploaded asset list mismatch')
    for asset in release['assets']:
        data=expected[asset['name']].read_bytes()
        if asset['size']!=len(data):raise ValueError('Uploaded asset size mismatch')
        if asset.get('digest') and asset['digest']!='sha256:'+hashlib.sha256(data).hexdigest():
            raise ValueError('Uploaded asset digest mismatch')
    with tempfile.TemporaryDirectory(prefix='orion-release-download-') as temporary:
        downloaded=Path(temporary)
        run(['release','download',tag,'--repo',repo,'--dir',str(downloaded)])
        verify_package(downloaded)
        for name,source in expected.items():
            if (downloaded/name).read_bytes()!=source.read_bytes():raise ValueError('Downloaded asset mismatch')
    if remote_commit()!=commit:raise ValueError('Tag changed before publication')
    run(['release','edit',tag,'--repo',repo,'--draft=false',
         '--prerelease='+str(rc).lower(),'--latest='+str(not rc).lower()])
    published=json.loads(run(['api',f'repos/{repo}/releases/{release["id"]}']))
    if published['draft'] or published['prerelease']!=rc or published['tag_name']!=tag:
        raise ValueError('Published channel metadata mismatch')
    if not rc:
        latest=json.loads(run(['api',f'repos/{repo}/releases/latest']))
        if latest['id']!=published['id']:raise ValueError('Stable release is not latest')
    return published


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--package',type=Path,required=True)
    parser.add_argument('--repo',required=True)
    parser.add_argument('--tag',required=True)
    parser.add_argument('--commit',required=True)
    args=parser.parse_args()
    release=publish_release(args.package,args.repo,args.tag,args.commit)
    print(json.dumps({'url':release['html_url'],'tag':release['tag_name'],
                      'prerelease':release['prerelease'],'draft':release['draft']}))


if __name__=='__main__':main()
