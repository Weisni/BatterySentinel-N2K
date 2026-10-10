"""Small publishing regression, including real Windows ACL inheritance.

Creates only synthetic ZIPs in a uniquely named repository tmp/ directory.
Never reads, regenerates, or changes the hardware release archives.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import uuid

import package_altium_r4 as package


def windows_acl(path):
    literal=str(path).replace("'","''")
    script=("$ErrorActionPreference='Stop'; $a=Get-Acl -LiteralPath '"+literal+"'; "
        "@($a.Access | ForEach-Object { [PSCustomObject]@{ "
        "sid=$_.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value; "
        "rights=[long]$_.FileSystemRights; allow=($_.AccessControlType -eq 'Allow'); "
        "inherited=$_.IsInherited; inheritance=[int]$_.InheritanceFlags "
        "} }) | ConvertTo-Json -Compress")
    environment=os.environ.copy()
    # Do not pass a PowerShell 7 module search path into Windows PowerShell 5.
    environment.pop('PSModulePath',None)
    executable=shutil.which('pwsh.exe') or 'powershell.exe'
    result=subprocess.run([executable,'-NoProfile','-NonInteractive','-Command',script],
                          check=True,capture_output=True,text=True,env=environment)
    rules=json.loads(result.stdout)
    return rules if isinstance(rules,list) else [rules]


class PublishArchivesTest(unittest.TestCase):
    def setUp(self):
        self.base=package.REPO/'tmp'/('r4-package-regression-'+uuid.uuid4().hex)
        self.base.mkdir(parents=True)
        self.private=tempfile.TemporaryDirectory(prefix='private-',dir=self.base)
        self.staged=Path(self.private.name)
        self.reports=[package.make_archive(self.staged/name,'Synthetic',
            {'test.txt':name.encode()},'altium',[]) for name in ('first.zip','second.zip')]

    def tearDown(self):
        self.private.cleanup()
        resolved=self.base.resolve()
        safe_root=(package.REPO/'tmp').resolve()
        if resolved.parent!=safe_root or not resolved.name.startswith('r4-package-regression-'):
            raise ValueError('Unsafe regression cleanup target')
        shutil.rmtree(resolved)

    def publish(self):
        package.publish_archives(self.staged,self.base,self.reports)

    def assert_no_public_zip(self):
        self.assertFalse(any((self.base/r['name']).exists() for r in self.reports))

    def test_bytes_and_windows_parent_acl_are_preserved(self):
        self.publish()
        for report in self.reports:
            self.assertEqual((self.base/report['name']).read_bytes(),
                             (self.staged/report['name']).read_bytes())
        if os.name!='nt':
            return
        parent=windows_acl(self.base)
        private=windows_acl(self.staged/'first.zip')
        child=windows_acl(self.base/'first.zip')
        inherited=[r for r in parent if r['allow'] and r['inheritance']&1]
        # Require an actual user FullControl grant, not merely SYSTEM/admin.
        users=[r for r in inherited if r['sid'].startswith('S-1-5-21-')
               and r['rights']&2032127==2032127]
        self.assertTrue(users,'Test parent has no user FullControl grant')
        self.assertTrue(any(not any(p['allow'] and p['sid']==u['sid'] for p in private)
                            for u in users),'Staging did not reproduce the private-ACL failure')
        for rule in inherited:
            self.assertTrue(any(c['allow'] and c['inherited'] and c['sid']==rule['sid']
                and c['rights']&rule['rights']==rule['rights'] for c in child),rule)

    def test_existing_second_destination_is_never_overwritten(self):
        target=self.base/'second.zip'
        target.write_bytes(b'existing user file')
        with self.assertRaises(FileExistsError):
            self.publish()
        self.assertEqual(target.read_bytes(),b'existing user file')
        self.assertFalse((self.base/'first.zip').exists())

    def test_changed_staging_publishes_neither_archive(self):
        (self.staged/'second.zip').write_bytes(b'changed after validation')
        with self.assertRaisesRegex(ValueError,'Staged archive changed'):
            self.publish()
        self.assert_no_public_zip()

    def test_copy_failure_removes_both_new_destinations(self):
        real_copy=shutil.copyfileobj
        calls=[]
        def fail_second(source,destination):
            calls.append(source.name)
            if len(calls)==2:
                destination.write(b'partial')
                raise OSError('injected copy failure')
            real_copy(source,destination)
        with patch.object(package.shutil,'copyfileobj',side_effect=fail_second):
            with self.assertRaisesRegex(OSError,'injected copy failure'):
                self.publish()
        self.assert_no_public_zip()

    def test_bad_destination_readback_removes_both_new_destinations(self):
        def corrupt_copy(source,destination):
            destination.write(source.read()+b'corrupt')
        with patch.object(package.shutil,'copyfileobj',side_effect=corrupt_copy):
            with self.assertRaisesRegex(ValueError,'Published archive readback differs'):
                self.publish()
        self.assert_no_public_zip()


if __name__=='__main__':
    unittest.main(verbosity=2)
