"""Malformed-image regression tests for the independent release artifact check."""

import hashlib
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest

from verify_ota_image import inspect_image


def image_fixture(target="orion-dongle", version="1.1.0"):
    header = bytearray(24)
    header[0:4] = bytes([0xE9, 1, 2, 0x20])
    struct.pack_into("<H", header, 12, 5)
    header[23] = 1
    descriptor = bytearray(256)
    struct.pack_into("<I", descriptor, 0, 0xABCD5432)
    descriptor[16:16 + len(version)] = version.encode("ascii")
    descriptor[48:48 + len(target)] = target.encode("ascii")
    body = header + struct.pack("<II", 0x3C000020, len(descriptor)) + descriptor
    checksum = 0xEF
    for value in descriptor:
        checksum ^= value
    body.extend(bytes(15 - len(body) % 16))
    body.append(checksum)
    return bytes(body) + hashlib.sha256(body).digest()


def rehash(image):
    return bytes(image[:-32]) + hashlib.sha256(image[:-32]).digest()


class OtaImageTests(unittest.TestCase):
    def test_both_hardware_targets(self):
        for target in ("orion-dongle", "orion-r4"):
            info = inspect_image(image_fixture(target), target, "1.1.0")
            self.assertEqual(info.target, target)
            self.assertEqual(info.version, "1.1.0")

    def test_wrong_hardware_target(self):
        with self.assertRaisesRegex(ValueError, "Wrong hardware target"):
            inspect_image(image_fixture("orion-r4"), "orion-dongle")

    def test_debug_oled_image_matches_its_own_target(self):
        info = inspect_image(image_fixture("orion-debug-oled"), "orion-debug-oled", "1.1.0")
        self.assertEqual(info.target, "orion-debug-oled")

    def test_debug_and_standard_targets_reject_each_other(self):
        targets = ("orion-dongle", "orion-r4", "orion-debug-oled")
        for actual in targets:
            for expected in targets:
                if actual == expected:
                    continue
                with self.subTest(actual=actual, expected=expected):
                    with self.assertRaisesRegex(ValueError, "Wrong hardware target"):
                        inspect_image(image_fixture(actual), expected)

    def test_debug_target_requires_exact_name(self):
        for actual in ("orion-debug", "orion-debug-oled-other", "orion-debug-oled "):
            with self.subTest(actual=actual):
                with self.assertRaisesRegex(ValueError, "Wrong hardware target"):
                    inspect_image(image_fixture(actual), "orion-debug-oled")

    def test_cli_accepts_debug_target_without_weakening_standard_check(self):
        with tempfile.TemporaryDirectory() as folder:
            image = Path(folder) / "debug.bin"
            image.write_bytes(image_fixture("orion-debug-oled"))
            command = [sys.executable, str(Path(__file__).with_name("verify_ota_image.py")),
                       str(image), "--target"]
            accepted = subprocess.run(command + ["orion-debug-oled"], capture_output=True,
                                      text=True, timeout=10)
            self.assertEqual(accepted.returncode, 0, accepted.stderr)
            rejected = subprocess.run(command + ["orion-dongle"], capture_output=True,
                                      text=True, timeout=10)
            self.assertEqual(rejected.returncode, 1, rejected.stdout)
            self.assertIn("Wrong hardware target", rejected.stderr)

    def test_generic_arduino_image(self):
        with self.assertRaisesRegex(ValueError, "Wrong hardware target"):
            inspect_image(image_fixture("arduino-lib-builder"), "orion-dongle")

    def test_wrong_release_version(self):
        with self.assertRaisesRegex(ValueError, "Wrong version"):
            inspect_image(image_fixture(), "orion-dongle", "1.0.0")

    def test_wrong_chip_and_flash_geometry(self):
        for offset, value, message in ((12, 9, "ESP32-C3"), (3, 0x30, "4 MB")):
            image = bytearray(image_fixture())
            image[offset] = value
            with self.assertRaisesRegex(ValueError, message):
                inspect_image(rehash(image), "orion-dongle")

    def test_missing_digest(self):
        image = bytearray(image_fixture())
        image[23] = 0
        with self.assertRaisesRegex(ValueError, "no appended SHA-256"):
            inspect_image(rehash(image), "orion-dongle")

    def test_body_and_digest_corruption(self):
        for offset, message in ((140, "checksum mismatch"), (-1, "SHA-256 mismatch")):
            image = bytearray(image_fixture())
            image[offset] ^= 1
            with self.assertRaisesRegex(ValueError, message):
                inspect_image(bytes(image), "orion-dongle")

    def test_hash_detects_checksum_preserving_corruption(self):
        image = bytearray(image_fixture())
        image[140] ^= 1
        image[141] ^= 1
        with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
            inspect_image(bytes(image), "orion-dongle")

    def test_malformed_segment_length(self):
        image = bytearray(image_fixture())
        struct.pack_into("<I", image, 28, 0xFFFFFFFC)
        with self.assertRaisesRegex(ValueError, "segment length"):
            inspect_image(rehash(image), "orion-dongle")

    def test_missing_descriptor(self):
        image = bytearray(image_fixture())
        image[32] = 0
        with self.assertRaisesRegex(ValueError, "descriptor magic"):
            inspect_image(rehash(image), "orion-dongle")

    def test_truncation_trailing_bytes_and_slot_size(self):
        image = image_fixture()
        for invalid in (image[:80], image[:-1], image + b"\0", b"\xFF" * 0x10000 + image):
            with self.assertRaises(ValueError):
                inspect_image(invalid, "orion-dongle")
        with self.assertRaisesRegex(ValueError, "OTA partition"):
            inspect_image(image, "orion-dongle", max_size=len(image) - 1)

    def test_empty_or_unterminated_version(self):
        with self.assertRaisesRegex(ValueError, "version"):
            inspect_image(image_fixture(version=""), "orion-dongle")
        with self.assertRaisesRegex(ValueError, "version"):
            inspect_image(image_fixture(version="x" * 32), "orion-dongle")


if __name__ == "__main__":
    unittest.main()
