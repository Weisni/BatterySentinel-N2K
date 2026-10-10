"""Exercise publication with a fake GitHub boundary; no external writes."""
import hashlib
import json
from pathlib import Path
import shutil
import tempfile
import unittest

import test_release_package as package_tests
from package_release import package_release
from publish_release import publish_release


class FakeGithub:
    def __init__(self, folder, manifest):
        self.folder=folder;self.manifest=manifest;self.calls=[];self.release=None
        self.remote_commit=manifest['sourceCommit'];self.corrupt=False

    def __call__(self,args):
        self.calls.append(args)
        if args[0]=='api':
            path=args[1]
            if '/commits/' in path:return self.remote_commit
            if path.endswith('/releases?per_page=100'):return json.dumps([self.release] if self.release else [])
            if '/releases/' in path:return json.dumps(self.release)
        if args[:2]==['release','create']:
            self.release={'id':42,'tag_name':self.manifest['tag'],'target_commitish':self.remote_commit,
                          'draft':True,'prerelease':'--prerelease' in args,
                          'html_url':'https://example.test/release','assets':[]}
            self.release['assets']=[{'name':p.name,'size':p.stat().st_size,
                                    'digest':'sha256:'+hashlib.sha256(p.read_bytes()).hexdigest()}
                                   for p in self.folder.iterdir()]
        if args[:2]==['release','download']:
            destination=Path(args[args.index('--dir')+1])
            for p in self.folder.iterdir():shutil.copyfile(p,destination/p.name)
            if self.corrupt:(destination/'RELEASE-NOTES.md').write_text('corrupt')
        if args[:2]==['release','edit']:
            self.release['draft']=False;self.release['prerelease']='--prerelease=true' in args
        return ''


class PublishTests(unittest.TestCase):
    def fixture(self,folder,version='1.2.0'):
        root,build,framework,out=package_tests.ReleaseTests().fixture(folder,version)
        manifest=package_release(root,build,framework,out,'a'*40,'https://example.test/ci')
        return out,manifest,FakeGithub(out,manifest)

    def test_stable_is_published_only_after_download_verification(self):
        with tempfile.TemporaryDirectory() as folder:
            out,m,gh=self.fixture(folder)
            result=publish_release(out,'owner/repo',m['tag'],m['sourceCommit'],gh)
            edit=next(c for c in gh.calls if c[:2]==['release','edit'])
            self.assertIn('--latest=true',edit);self.assertIn('--prerelease=false',edit)
            download=next(c for c in gh.calls if c[:2]==['release','download'])
            self.assertLess(gh.calls.index(download),gh.calls.index(edit))
            self.assertFalse(result['draft'])

    def test_rc_is_prerelease_and_never_latest(self):
        with tempfile.TemporaryDirectory() as folder:
            out,m,gh=self.fixture(folder,'1.3.0-rc.1')
            publish_release(out,'owner/repo',m['tag'],m['sourceCommit'],gh)
            edit=next(c for c in gh.calls if c[:2]==['release','edit'])
            self.assertIn('--latest=false',edit);self.assertIn('--prerelease=true',edit)

    def test_wrong_tag_or_commit_cannot_create_release(self):
        with tempfile.TemporaryDirectory() as folder:
            out,m,gh=self.fixture(folder)
            with self.assertRaises(ValueError):publish_release(out,'owner/repo','v1.2.1',m['sourceCommit'],gh)
            gh.remote_commit='b'*40
            with self.assertRaises(ValueError):publish_release(out,'owner/repo',m['tag'],m['sourceCommit'],gh)
            self.assertFalse(any(c[:2]==['release','create'] for c in gh.calls))

    def test_corrupt_uploaded_asset_never_publishes(self):
        with tempfile.TemporaryDirectory() as folder:
            out,m,gh=self.fixture(folder);gh.corrupt=True
            with self.assertRaises(ValueError):publish_release(out,'owner/repo',m['tag'],m['sourceCommit'],gh)
            self.assertTrue(gh.release['draft'])
            self.assertFalse(any(c[:2]==['release','edit'] for c in gh.calls))

    def test_existing_published_release_is_not_modified(self):
        with tempfile.TemporaryDirectory() as folder:
            out,m,gh=self.fixture(folder)
            gh.release={'tag_name':m['tag'],'draft':False}
            with self.assertRaises(ValueError):publish_release(out,'owner/repo',m['tag'],m['sourceCommit'],gh)
            self.assertTrue(all(c[0]=='api' for c in gh.calls))


if __name__=='__main__':unittest.main()
