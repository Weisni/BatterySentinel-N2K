# Orion OLED debug firmware 1.2.0-debug.1

For the requested Meshnology ESP32-C3 OLED debug board, Amazon B0FP81HMYB.
Target: `orion-debug-oled`. Application: 1,939,552 bytes; 26,528 bytes remain in each OTA slot.

## Wiring and first installation

OLED uses SDA GPIO5 / SCL GPIO6. **CAN TX is GPIO4 and RX is GPIO7.**
Use a separately wired 3.3 V-compatible CAN transceiver / isolated NMEA interface.
Do not insert this module into the normal carrier or connect CAN/12 V directly to GPIO.
See [debug-guide.md](debug-guide.md) for the pin evidence, status legend and hardware checks.

Extract the ZIP, open a terminal in this directory and replace COM5 with the actual USB port.
With the project's esptool 4.5.1 available, install all four images:

```powershell
python -m esptool --chip esp32c3 --port COM5 --baud 460800 write_flash --flash_mode keep --flash_freq keep --flash_size 4MB 0x0 bootloader.bin 0x8000 partitions.bin 0xe000 boot_app0.bin 0x10000 orion-debug-oled-1.2.0-debug.1.bin
```

Alternatively use `pio run -e orion_debug_oled -t upload --upload-port COM5` from the source checkout.
If the board does not enter download mode, hold BOOT while pressing RESET or connecting USB, then release BOOT.
These segmented writes leave NVS (0x9000–0xDFFF) untouched; do not run an erase-flash command.
Use the documented partition layout. A different pre-existing application may use a different settings format.

## Later updates through the portal

Upload **only `orion-debug-oled-1.2.0-debug.1.bin`** in Settings on a device already running this OLED debug target.
Other hardware targets are rejected in both directions; initial conversion to the OLED target requires USB.
The bootloader, partition file and ZIP are not OTA files.

## Verification and limits

The application is checked for target/version, 4 MB ESP32-C3 header, OTA size, checksum and appended SHA-256.
`manifest.json` records whole-file SHA-256 values, flash addresses and source hashes.
The display profile is SSD1306-compatible 72 x 40 at 0x3C; exact geometry remains a physical check.
OLED boot border, readability, bus wiring, BLE/Wi-Fi coexistence and Garmin reception need the actual hardware.
No board has been flashed by the packaging tool.
