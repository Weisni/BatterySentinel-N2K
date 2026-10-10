"""Inspect a standard Orion ESP32-C3 application image without modifying it.

The appended image SHA-256 detects corruption; it is not a publisher signature.
Only app firmware.bin files are accepted, never merged flash/bootloader images.
"""

import argparse
from dataclasses import dataclass
import hashlib
from pathlib import Path
import struct
import subprocess


OTA_SLOT_SIZE = 0x1E0000
TARGETS = ("orion-dongle", "orion-r4", "orion-debug-oled")


@dataclass(frozen=True)
class ImageInfo:
    target: str
    version: str
    size: int
    segments: int
    sha256: str


def _description_string(image: bytes, offset: int, label: str) -> str:
    field = image[offset:offset + 32]
    end = field.find(b"\0")
    if end <= 0 or any(value < 0x20 or value > 0x7E for value in field[:end]):
        raise ValueError(f"Invalid application {label}")
    return field[:end].decode("ascii")


def inspect_image(image: bytes, target: str, version: str | None = None,
                  max_size: int = OTA_SLOT_SIZE) -> ImageInfo:
    """Validate header, app identity, boundaries, checksum and appended digest."""
    if target not in TARGETS:
        raise ValueError("Unknown Orion hardware target")
    if not 24 + 8 + 256 + 1 + 32 <= len(image) <= max_size:
        raise ValueError("Image is truncated or exceeds the OTA partition")
    if image[0] != 0xE9:
        raise ValueError("Not an ESP application image")
    segment_count = image[1]
    if not 1 <= segment_count <= 16:
        raise ValueError("Invalid segment count")
    if struct.unpack_from("<H", image, 12)[0] != 5:
        raise ValueError("Image is not built for ESP32-C3")
    if image[3] >> 4 != 2:
        raise ValueError("Image is not built for 4 MB flash")
    if image[23] != 1:
        raise ValueError("Image has no appended SHA-256")

    cursor = 24
    checksum = 0xEF
    for index in range(segment_count):
        if cursor + 8 > len(image) - 33:
            raise ValueError("Truncated segment header")
        address, length = struct.unpack_from("<II", image, cursor)
        cursor += 8
        if length % 4 or length > len(image) - cursor - 33:
            raise ValueError("Invalid segment length")
        if index == 0:
            if not 0x3C000000 <= address < 0x3C800000 or length < 256:
                raise ValueError("Missing application descriptor segment")
            if struct.unpack_from("<I", image, cursor)[0] != 0xABCD5432:
                raise ValueError("Missing application descriptor magic")
        for value in image[cursor:cursor + length]:
            checksum ^= value
        cursor += length

    # Espressif's checksum is the final byte in the next 16-byte block.
    checksum_offset = cursor + (15 - cursor % 16)
    if checksum_offset + 1 + 32 != len(image):
        raise ValueError("Truncated image or unexpected trailing data")
    if any(image[cursor:checksum_offset]):
        raise ValueError("Invalid image checksum padding")
    if image[checksum_offset] != checksum:
        raise ValueError("Image checksum mismatch")
    digest = hashlib.sha256(image[:-32]).digest()
    if image[-32:] != digest:
        raise ValueError("Image SHA-256 mismatch")

    actual_target = _description_string(image, 32 + 48, "target")
    actual_version = _description_string(image, 32 + 16, "version")
    if actual_target != target:
        raise ValueError(f"Wrong hardware target: expected {target}, got {actual_target}")
    if version is not None and actual_version != version:
        raise ValueError(f"Wrong version: expected {version}, got {actual_version}")
    return ImageInfo(actual_target, actual_version, len(image), segment_count, digest.hex())


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("image", type=Path)
    parser.add_argument("--target", choices=TARGETS, required=True)
    parser.add_argument("--version")
    parser.add_argument("--runtime-checker", type=Path,
                        help="Also validate using the compiled tools/check_ota_image.cpp")
    parser.add_argument("--max-size", type=lambda value: int(value, 0), default=OTA_SLOT_SIZE)
    args = parser.parse_args()
    try:
        info = inspect_image(args.image.read_bytes(), args.target, args.version, args.max_size)
    except (OSError, ValueError) as error:
        parser.exit(1, f"OTA image rejected: {error}\n")
    if args.runtime_checker:
        try:
            subprocess.run([str(args.runtime_checker.resolve()), str(args.image),
                            args.target, info.sha256], check=True)
        except (OSError, subprocess.CalledProcessError) as error:
            parser.exit(1, f"Runtime OTA validator rejected image: {error}\n")
    print(f"Verified {info.target} {info.version}: {info.size} bytes, "
          f"{info.segments} segments, SHA-256 {info.sha256}")


if __name__ == "__main__":
    main()
