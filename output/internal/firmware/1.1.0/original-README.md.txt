# Orion Bridge 1.1.0 - SuperMini / R5

`orion-dongle-1.1.0.bin` is an application-only OTA image for the 4 MB ESP32-C3
SuperMini and Orion-R5. It is not for Orion-R4 or the original 8 MB battery
monitor. Install the first OTA-capable firmware and matching partition layout
over USB; later application updates can use the portal.

Save the file on the phone, connect to the bridge Wi-Fi, sign in, and open
**Settings > Firmware update**. Keep power connected throughout the update.
See the [full update instructions](../../../docs/firmware-update.md).

The final image passed a physical HTTPS OTA round trip through both application
slots on 2026-09-25. Firmware hashes and retained settings matched after both
restarts. The [test record](../../../docs/ota-hardware-test-2026-09-25.md) separates
these results from outstanding phone-browser, power-loss and BLE/NMEA checks.

`SHA256SUMS.txt` records the complete-file SHA-256. The device also checks its
embedded target, ESP image structure, checksum and appended SHA-256 before
activation. These integrity checks are not a firmware-publisher signature.
