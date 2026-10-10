# Orion Bridge 1.1.1 for ESP32-C3 SuperMini / Orion-R5

Use `orion-dongle-1.1.1.bin` in **Settings → Firmware update**. Save the file
locally on the phone before joining the bridge Wi-Fi. Keep power connected
throughout installation. This is an application image, not a full USB flash dump.

This release speeds up the existing password verification, coordinates portal
requests around file selection and startup, and displays a stored Readout key
using green placeholder stars and **Schlüssel vorhanden**. Existing passwords
and configuration remain compatible. It includes the 1.1.0 radio/TLS fixes.

The image was validated and installed on the attached SuperMini using HTTPS OTA;
the restart, expected hash, existing login and configuration were verified.
See [measurements and test scope](../../../docs/portal-performance-2026-09-25.md)
and [update instructions](../../../docs/firmware-update.md).

Size: 1,773,216 bytes. File SHA-256:

```text
8ff55342b3527455e586c338b41baa7d8ab720cb11f0bdb1c1ce43f1e6752552
```

Do not install on Orion-R4 or the original 8 MB BatterySentinel monitor.
