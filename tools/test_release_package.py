"""Release-channel, image, USB-layout and integrity regression checks."""
import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile

from test_verify_ota_image import image_fixture
from package_release import release_identity, package_release, verify_package


class ReleaseTests(unittest.TestCase):
    def test_channel_requires_explicit_supported_version(self):
        self.assertEqual(release_identity('1.2.0'), ('v1.2.0', 'stable'))
        self.assertEqual(release_identity('1.3.0-rc.2'), ('v1.3.0-rc.2', 'rc'))
        for version in ('01.2.0', '1.2', '1.2.0-debug.1', '1.2.0-wifi2dbm.1',
                        '1.2.0-rc.0', '1.2.0-rc.01', '1.2.0;echo secret'):
            with self.subTest(version=version), self.assertRaises(ValueError):
                release_identity(version)

    def fixture(self, folder, version='1.2.0', target='orion-dongle'):
        root = Path(folder)
        build = root/'build'; build.mkdir()
        framework = root/'framework'; (framework/'tools/partitions').mkdir(parents=True)
        (build/'firmware.bin').write_bytes(image_fixture(target, version))
        boot = bytearray(256); boot[0:4] = bytes([0xE9, 1, 2, 0x20])
        struct.pack_into('<H', boot, 12, 5)
        (build/'bootloader.bin').write_bytes(boot)
        entries = [('nvs',1,2,0x9000,0x5000),('otadata',1,0,0xE000,0x2000),
                   ('ota_0',0,0x10,0x10000,0x1E0000),('ota_1',0,0x11,0x1F0000,0x1E0000)]
        table = b''.join(struct.pack('<HBBII16sI',0x50AA,t,s,o,n,label.encode(),0)
                         for label,t,s,o,n in entries)
        (build/'partitions.bin').write_bytes(table+b'\xff'*32)
        (framework/'tools/partitions/boot_app0.bin').write_bytes(b'\xff'*8192)
        (root/'output/pdf').mkdir(parents=True)
        (root/'output/pdf/BatterySentinel-N2K-Orion-R5-Betriebs-und-Installationsanleitung-DE.pdf').write_bytes(b'%PDF-1.7\nfixture')
        (root/'docs/releases').mkdir(parents=True)
        (root/f'docs/releases/{version}.md').write_text('# Release notes\n',encoding='utf8')
        return root,build,framework,root/'release'

    def test_stable_assets_hashes_and_nvs_preserving_usb_layout(self):
        with tempfile.TemporaryDirectory() as folder:
            root,build,framework,out=self.fixture(folder)
            info=package_release(root,build,framework,out,'a'*40,'https://example.test/run/1')
            self.assertEqual(info['channel'],'stable')
            self.assertEqual(verify_package(out)['sourceCommit'],'a'*40)
            with zipfile.ZipFile(out/'orion-dongle-1.2.0-usb.zip') as bundle:
                self.assertIsNone(bundle.testzip())
                layout=json.loads(bundle.read('flash-layout.json'))
                self.assertEqual(layout['flashOffsets']['partitions.bin'], '0x8000')
                self.assertEqual(layout['flashOffsets']['boot_app0.bin'], '0xe000')
                for name,offset in layout['flashOffsets'].items():
                    start=int(offset,16);end=start+len(bundle.read(name))
                    self.assertTrue(end<=0x9000 or start>=0xE000, name)
                self.assertEqual(bundle.read('orion-dongle-1.2.0.bin'),(build/'firmware.bin').read_bytes())
            for row in (out/'SHA256SUMS.txt').read_text().splitlines():
                digest,name=row.split('  ',1)
                self.assertEqual(hashlib.sha256((out/name).read_bytes()).hexdigest(),digest)

    def test_rc_is_distinct_and_never_named_stable(self):
        with tempfile.TemporaryDirectory() as folder:
            root,build,framework,out=self.fixture(folder,'1.3.0-rc.1')
            info=package_release(root,build,framework,out,'b'*40,'https://example.test/run/2')
            self.assertEqual((info['tag'],info['channel']),('v1.3.0-rc.1','rc'))
            self.assertTrue((out/'orion-dongle-1.3.0-rc.1.bin').is_file())

    def test_rejects_wrong_product_and_partition_layout(self):
        with tempfile.TemporaryDirectory() as folder:
            root,build,framework,out=self.fixture(folder,target='orion-debug-oled')
            with self.assertRaises(ValueError): package_release(root,build,framework,out,'a'*40,'')
        with tempfile.TemporaryDirectory() as folder:
            root,build,framework,out=self.fixture(folder)
            data=bytearray((build/'partitions.bin').read_bytes())
            struct.pack_into('<I',data,4,0x8000)
            (build/'partitions.bin').write_bytes(data)
            with self.assertRaisesRegex(ValueError,'partition'): package_release(root,build,framework,out,'a'*40,'')

    def test_existing_package_is_not_overwritten_and_tampering_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root,build,framework,out=self.fixture(folder)
            package_release(root,build,framework,out,'a'*40,'')
            with self.assertRaises(FileExistsError): package_release(root,build,framework,out,'a'*40,'')
            (out/'orion-dongle-1.2.0.bin').write_bytes(b'corrupt')
            with self.assertRaises(ValueError): verify_package(out)

    def test_extra_asset_and_malformed_source_commit_are_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root,build,framework,out=self.fixture(folder)
            with self.assertRaises(ValueError): package_release(root,build,framework,out,'main','')
            package_release(root,build,framework,out,'a'*40,'')
            (out/'private-password.txt').write_text('not a release asset')
            with self.assertRaises(ValueError): verify_package(out)


if __name__=='__main__': unittest.main()
