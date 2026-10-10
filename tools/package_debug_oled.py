"""Package the validated OLED debug application and segmented USB images.

Run after `pio run -e orion_debug_oled`. Does not access or flash a device.
The segmented layout deliberately excludes the saved-settings/NVS partition.
"""
import hashlib
import json
from pathlib import Path
import shutil
import struct
import zipfile

from verify_ota_image import inspect_image, OTA_SLOT_SIZE

ROOT = Path(__file__).resolve().parents[1]
VERSION = "1.2.0-debug.1"
TARGET = "orion-debug-oled"
BUILD = ROOT / ".pio/build/orion_debug_oled"
OUT = ROOT / "output/firmware/debug-oled" / VERSION


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    app = (BUILD / "firmware.bin").read_bytes()
    info = inspect_image(app, TARGET, VERSION)
    partitions = (BUILD / "partitions.bin").read_bytes()
    entries = {}
    for offset in range(0, len(partitions), 32):
        magic, kind, subtype, address, size, label, flags = struct.unpack_from("<HBBII16sI", partitions, offset)
        if magic != 0x50AA:
            break
        entries[label.rstrip(b"\0").decode()] = (address, size)
    assert entries["nvs"] == (0x9000, 0x5000)
    assert entries["otadata"] == (0xE000, 0x2000)
    assert entries["app0"] == (0x10000, OTA_SLOT_SIZE)
    assert entries["app1"] == (0x1F0000, OTA_SLOT_SIZE)
    OUT.mkdir(parents=True, exist_ok=True)
    app_name = f"{TARGET}-{VERSION}.bin"
    (OUT / app_name).write_bytes(app)
    framework = Path.home() / ".platformio/packages/framework-arduinoespressif32"
    pieces = {
        "bootloader.bin": (BUILD / "bootloader.bin", 0),
        "partitions.bin": (BUILD / "partitions.bin", 0x8000),
        "boot_app0.bin": (framework / "tools/partitions/boot_app0.bin", 0xE000),
    }
    layout = {app_name: "0x10000"}
    for name, (source, offset) in pieces.items():
        data = source.read_bytes()
        assert offset + len(data) <= 0x9000 or offset >= 0xE000, "USB image overlaps NVS"
        assert offset + len(data) <= (0x8000 if offset == 0 else 0x10000)
        (OUT / name).write_bytes(data)
        layout[name] = hex(offset)
    guide = (ROOT / "docs/internal/oled-debug.md").read_text(encoding="utf-8")
    guide = guide.replace("../../output/firmware/debug-oled/1.2.0-debug.1/README.md", "README.md")
    guide = guide.replace("[portal setup reference](../erstverbindung.md)", "`docs/erstverbindung.md` in the source checkout")
    guide = guide.replace("[project README](../../README.md)", "source checkout's `README.md`")
    guide = guide.replace("[implementation plan](oled-debug-plan.md)", "`docs/internal/oled-debug-plan.md`")
    (OUT / "debug-guide.md").write_text(guide, encoding="utf-8")
    shutil.copyfile(ROOT / ".pio/libdeps/orion_debug_oled/U8g2/LICENSE", OUT / "U8g2-LICENSE.txt")
    readme = f"""# Orion OLED debug firmware {VERSION}

For the requested Meshnology ESP32-C3 OLED debug board, Amazon B0FP81HMYB.
Target: `{TARGET}`. Application: {info.size:,} bytes; {OTA_SLOT_SIZE - info.size:,} bytes remain in each OTA slot.

## Wiring and first installation

OLED uses SDA GPIO5 / SCL GPIO6. **CAN TX is GPIO4 and RX is GPIO7.**
Use a separately wired 3.3 V-compatible CAN transceiver / isolated NMEA interface.
Do not insert this module into the normal carrier or connect CAN/12 V directly to GPIO.
See [debug-guide.md](debug-guide.md) for the pin evidence, status legend and hardware checks.

Extract the ZIP, open a terminal in this directory and replace COM5 with the actual USB port.
With the project's esptool 4.5.1 available, install all four images:

```powershell
python -m esptool --chip esp32c3 --port COM5 --baud 460800 write_flash --flash_mode keep --flash_freq keep --flash_size 4MB 0x0 bootloader.bin 0x8000 partitions.bin 0xe000 boot_app0.bin 0x10000 {app_name}
```

Alternatively use `pio run -e orion_debug_oled -t upload --upload-port COM5` from the source checkout.
If the board does not enter download mode, hold BOOT while pressing RESET or connecting USB, then release BOOT.
These segmented writes leave NVS (0x9000–0xDFFF) untouched; do not run an erase-flash command.
Use the documented partition layout. A different pre-existing application may use a different settings format.

## Later updates through the portal

Upload **only `{app_name}`** in Settings on a device already running this OLED debug target.
Other hardware targets are rejected in both directions; initial conversion to the OLED target requires USB.
The bootloader, partition file and ZIP are not OTA files.

## Verification and limits

The application is checked for target/version, 4 MB ESP32-C3 header, OTA size, checksum and appended SHA-256.
`manifest.json` records whole-file SHA-256 values, flash addresses and source hashes.
The display profile is SSD1306-compatible 72 x 40 at 0x3C; exact geometry remains a physical check.
OLED boot border, readability, bus wiring, BLE/Wi-Fi coexistence and Garmin reception need the actual hardware.
No board has been flashed by the packaging tool.
"""
    (OUT / "README.md").write_text(readme, encoding="utf-8")
    names = [app_name, *pieces, "README.md", "debug-guide.md", "U8g2-LICENSE.txt"]
    names += [p.name for p in sorted(OUT.glob("oled-preview.*"))]
    sources = [ROOT / "platformio.ini", ROOT / "partitions_4mb_ota.csv"]
    for folder in ("src", "include", "lib"):
        sources += [p for p in (ROOT / folder).rglob("*") if p.suffix in (".h", ".cpp", ".c")]
    manifest = {
        "target": TARGET, "version": VERSION, "otaSlotBytes": OTA_SLOT_SIZE,
        "applicationBytes": info.size, "nvsPreservedByUsbLayout": True,
        "flashOffsets": layout, "dependencies": {"U8g2": "2.36.5"},
        "files": {name: {"bytes": (OUT / name).stat().st_size,
                          "sha256": sha((OUT / name).read_bytes())} for name in names},
        "sources": {str(p.relative_to(ROOT)).replace("\\", "/"): sha(p.read_bytes()) for p in sorted(sources)},
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    names.append("manifest.json")
    (OUT / "SHA256SUMS.txt").write_text("".join(f"{sha((OUT / n).read_bytes())}  {n}\n" for n in names), encoding="ascii")
    names.append("SHA256SUMS.txt")
    archive = OUT / f"{TARGET}-{VERSION}-usb.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as bundle:
        for name in names:
            bundle.write(OUT / name, name)
    with zipfile.ZipFile(archive) as bundle:
        assert bundle.testzip() is None
        for name in names:
            assert bundle.read(name) == (OUT / name).read_bytes()
    print(json.dumps({"application": str(OUT / app_name), "bytes": info.size,
                      "sha256": sha(app), "usbPackage": str(archive)}, indent=2))


if __name__ == "__main__":
    main()
