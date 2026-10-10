# Private service Wi-Fi access pages

The owner can complete setup without a serial console when the installer supplies a device-specific Wi-Fi QR code. Firmware 1.2.0 already stores a randomly generated individual AP password in NVS (`ap_pass`) and advertises `OrionBridge-XXXXXX`. This workflow does not change firmware or provision a new password. It uses the actual credentials of the assembled device.

## Create a device manual

Double-click [`tools/create_service_wifi_manual.cmd`](../tools/create_service_wifi_manual.cmd). Enter the exact SSID and stored Wi-Fi password in the local window. The script creates:

- `output/private/service-wifi/OrionBridge-XXXXXX-Anleitung-DE.pdf`: the complete German manual plus the private access page.
- `output/private/service-wifi/OrionBridge-XXXXXX-Zugangsseite-DE.pdf`: the standalone access page for printing.

The page contains a Wi-Fi connection QR code, a separate portal QR code, and the SSID/password in readable form. The portal QR opens `https://192.168.4.1/`; it cannot join Wi-Fi itself. The general manual contains only the portal QR and instructions for using the private access page.

The launcher uses the Codex bundled Python runtime on this computer. Elsewhere, run `python tools/create_service_wifi_manual.py` in an environment with `reportlab`, `pypdf` and Tkinter. The PDF layout uses Windows Segoe UI fonts. No network connection is needed.

## Inject credentials from a local file

Create `output/private/device.service-wifi.json` locally, using the device's real values:

```json
{
  "ssid": "OrionBridge-A1B2C3",
  "password": "REPLACE_WITH_ACTUAL_STORED_PASSWORD"
}
```

These are placeholders, not functional device credentials. From the repository root:

```powershell
.\tools\create_service_wifi_manual.cmd --credentials .\output\private\device.service-wifi.json
```

Optional arguments:

- `--output-dir PATH`: choose a different private output folder.
- `--template PATH`: choose the source German manual.
- `--force`: replace existing device PDFs after checking the device identity and credentials.

Never supply passwords as command-line arguments. The script does not print passwords or QR payloads. It does not save GUI inputs as JSON. Credentials and codes are necessarily recoverable from the generated private PDFs. `output/private/` and `*.service-wifi.json` are ignored by Git; explicitly choosing another folder requires keeping that folder private as well. Ignore rules do not restrict filesystem access or encrypt PDFs.

## Installer handover

1. Read the actual SSID and existing password once, or use the installer's already verified record. The owner does not need to do this. The existing USB procedure remains in manual page 8: SERVICE before USB; BOOT after normal startup; 115200 baud.
2. Generate the two private PDFs, verify the displayed SSID against the actual device, and print/save the access page.
3. Forget the test phone's saved network. Scan the Wi-Fi QR, confirm connection, and stay connected when the phone reports no internet.
4. Scan the portal QR, check the expected local address, and follow the local certificate exception instructions. Confirm account creation with physical BOOT, or sign in to the already configured device.
5. Repeat after reopening the service Wi-Fi. Hand over only the intended owner's PDF. Do not publish a private PDF in a public release.

Changing the administrator password does not change the Wi-Fi QR. If AP credentials change or the entire NVS/flash is erased, regenerate the access page from the newly stored values. Do not erase NVS to make a QR code.

The Wi-Fi code uses the [ZXing Wi-Fi format](https://github.com/zxing/zxing/wiki/Barcode-Contents): `WIFI:T:WPA;S:...;P:...;;`, with reserved characters escaped, medium QR error correction and a four-module quiet zone. QR decoding in local QA validates the encoded data; actual phone connection and portal access still require the handover test.

## Status

- [x] General manual describes setup using a supplied device Wi-Fi QR.
- [x] Offline GUI and file-based generation preserve the source manual's interactive handover fields.
- [x] Synthetic end-to-end verification: 31-page device manual, 15 preserved fields, three independently decoded QR codes including reserved-character escaping, safe overwrite refusal and private ignore rules. Rendered generic/private pages visually reviewed. See `tmp/service-wifi-qa/qa.json`; no real device credentials were used.
- [ ] Generate and scan the private access page for the first physical Orion-R5 using its actual credentials.
- [ ] Record the owner's phone model, QR connection and portal handover results.

For repeatable QA, use the bundled Python runtime to run `tools/check_service_wifi_manual.py --decoder-dir tmp/qr-qa`. The decoder is a local test dependency (`zxing-cpp`), not a generator dependency. Regenerate the generic manual after changing manifest-listed scripts or documentation, then render with Poppler and run `tools/check_german_manual.py`.
