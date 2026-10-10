# Orion Bridge 1.1.3

Download the application image matching the hardware, save it on your phone,
then install through **Settings → Firmware update** with stable device power:

| Hardware | Image | Size |
| --- | --- | --- |
| ESP32-C3 SuperMini / Orion-R5 | [orion-dongle-1.1.3.bin](orion-dongle-1.1.3.bin) | 1,823,184 bytes |
| Orion-R4 WROOM board | [orion-r4-1.1.3.bin](orion-r4-1.1.3.bin) | 1,822,832 bytes |

These images are not for the original 8 MB battery-monitor board.
File hashes are in [SHA256SUMS.txt](SHA256SUMS.txt).

- Change the administrator password in Settings using the current password and
  two matching new entries.
- **Forgot password?** restores the documented recovery default after explicit
  confirmation while holding physical BOOT. It preserves all data/assignments.
  Both password operations end the existing session.
- The SuperMini blue LED starts off and follows AP-start, IP-address and HTTPS
  readiness. No fixed LED delay; the R4 does not drive this GPIO.

See [recovery instructions and default](../../../docs/erstverbindung.md#administrator-passwort-vergessen),
[update instructions](../../../docs/firmware-update.md), and
[verification/remaining hardware checks](../../../docs/password-recovery-and-wifi-2026-09-26.md).
Local builds and independent Python/C++ OTA image checks passed. These new
images have not been flashed or physically accepted during this task.

Passwords migrate to a single atomic credential record when changed. Older
firmware reads legacy credentials, so downgrading can reactivate the old
password. If the installed older firmware lacks recovery and its password is
lost, install the matching new firmware over USB without erasing NVS first.
