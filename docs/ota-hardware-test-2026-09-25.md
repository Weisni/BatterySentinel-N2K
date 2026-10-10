> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](internal/README.md).

# Orion SuperMini OTA hardware acceptance, 2026-09-25

Status: physical HTTPS OTA round trip passed on the attached ESP32-C3 SuperMini.
The final firmware completed `app0 -> app1 -> app0`; both restarts were verified
by authenticated metadata, expected ELF hash and unchanged portal settings.
The user subsequently confirmed a successful phone OTA update. Recorded Android/iOS browser coverage and power-loss acceptance remain separate checks. The [1.1.1 follow-up](portal-performance-2026-09-25.md) records login measurements, file-picker coordination and saved-key improvements.

## Device and recovery preparation

- USB COM8 identifies an ESP32-C3 revision 0.4 with 4 MB flash.
- A complete 4 MB flash backup was captured in the user's local temporary folder.
  It contains private device settings and is deliberately outside the repository.
- The installed partition table matches `partitions_4mb_ota.csv`. USB flashing
  leaves the NVS range at `0x9000..0xDFFF` outside its erase/write ranges.
- Firmware 1.1.0 was built, its application image verified, and flashed over USB.
  The programmer confirmed the written-data hash. Serial boot identifies
  `orion-dongle`, version `1.1.0`, partition `app0`, address `0x10000`.
- Authenticated firmware metadata now includes running/boot/next partition,
  uptime and the running ELF SHA-256, read from flash. This makes a same-version
  OTA slot transition independently observable.

## Radio investigation

- The PC's Ethernet connection remains active; its separate WLAN adapter was
  initially disconnected and has an existing profile for this bridge.
- The firmware reports successful HTTPS/AP startup, but the PC does not find the
  SSID. The user also reports that the SSID is absent on a phone.
- A temporary diagnostic build initialized Wi-Fi before Bluetooth and delayed
  BLE scanning for 30 seconds. No SSID was detected either before or after BLE
  started. This does not support attributing the problem solely to BLE scanning.
- The diagnostic API readings were: AP mode, channel 1, visible SSID
  (`ssid_hidden=0`), 100 ms beacon interval, b/g/n protocol flags (`7`), and
  maximum transmit power `80` in the driver's quarter-dBm units.
- The temporary source change was restored exactly, the normal production
  firmware was flashed back, and the normal build artifact was regenerated.
- After the user unplugged/reconnected USB, discovery initially still failed.
  The user subsequently reported a visible SSID, and Windows confirmed the
  expected AP BSSID with 76% signal on channel 1. No transmit-power change was
  applied. The cause of the earlier absence remains unconfirmed.
- The previously saved Windows bridge profile was no longer present. The user
  was asked to reconnect the PC before HTTPS acceptance checks continue.
- The PC then connected at `192.168.4.2`. Certificate-verified administrator
  login, dashboard access and firmware metadata succeeded twice on the normal
  firmware. Windows subsequently reported a driver-initiated WLAN disconnect;
  neither TCP connection attempts nor ICMP probes could reach the device.
- A temporary build limited Wi-Fi transmit power to 8.5 dBm (driver value `34`).
  WLAN reconnected and sustained the rejection checks and firmware transfers.
- An initial OTA into the default-power firmware succeeded and booted `app1`,
  but AP discovery failed again. The final SuperMini build therefore applies
  the 8.5 dBm limit at every service-AP start and checks the driver's return code.
  R4 retains its existing radio configuration. The physical RF/power-supply
  cause and usable range in the finished enclosure remain unmeasured.

## Findings during the live OTA checks

- A header-only POST with a nonzero Content-Length did not reach the handler:
  ESP-IDF 4.4.7 waits for the first body byte before dispatch. Sending 1 or 288
  bytes immediately produced the expected `401/auth` response. The test client
  now sends a 288-byte prefix for the header rejection cases. The temporary
  TCP_NODELAY change made during investigation was withdrawn; no firmware
  response defect was established. See the [SDK parser implementation](https://raw.githubusercontent.com/espressif/esp-idf/v4.4.7/components/esp_http_server/src/httpd_parse.c).
- Live rejection results: missing authentication `401/auth`, wrong CSRF
  `403/csrf`, wrong content type `415/content_type`, oversized length `413/size`,
  genuine R4 firmware `400/target`, corrupt XOR checksum `400/checksum`, and a
  corrupted appended SHA-256 `400/hash`, a one-byte truncation `400/image`, and
  a transfer stalled after 64 KiB `408/receive`. The running and selected boot slots
  remained `app0`. The automated cases also checked that portal settings stayed
  unchanged; the isolated size check verified its status and boot selection.
- Occasional HTTPS transport failures occurred between successful requests.
  The final three cases passed with a one-second gap between connections.
  The user subsequently confirmed that a PC browser had still had the device
  IP open and closed it before the valid update test. Competing HTTPS activity
  may have contributed; its role has not been isolated from radio behavior.

## HTTPS memory correction

After a successful OTA restart, one idle TLS session kept about 44 KiB occupied.
New handshakes repeatedly failed with `mbedtls_ssl_setup returned -0x7F00` while
the device still reported one session. The configured limit of three sessions
did not trigger least-recently-used cleanup at this point.

The final portal permits one TLS session with LRU cleanup enabled. ESP-IDF closes
the occupied slot before accepting a replacement and allocating its TLS state.
This was verified on hardware by deliberately holding a TLS connection open
without an HTTP request, then successfully logging in through a new connection;
the idle connection was closed. No certificate checks were disabled.
See the [SDK accept/LRU order](https://github.com/espressif/esp-idf/blob/v4.4.7/components/esp_http_server/src/httpd_main.c#L23-L59).

## Final installation and retained settings

- The final artifact contains the SuperMini radio limit and the TLS-session fix.
  USB was used to install that correction in `app0` before the final round trip.
- Both final transfers used the physical HTTPS `/api/firmware` endpoint over
  the PC's WLAN, with certificate verification, administrator login and CSRF.
  Ethernet remained connected. There were no USB writes between these transfers.
- `app0` (`0x10000`) -> `app1` (`0x1F0000`): HTTP 200 with `rebooting: true`,
  restart, running/selected boot-slot match, expected ELF hash and settings PASS.
- `app1` -> `app0`: the same checks PASS. The device was left running the final
  production firmware in `app0`, with the same final image in both slots.
- The test's post-reboot verification window was increased from 45 to 120
  seconds to accommodate Windows reconnection and password derivation. Only
  read/re-login operations are retried; firmware uploads are never retried
  automatically.
- A USB readback after the earlier OTA transitions also confirmed that all 11
  decoded `orion-bridge` NVS values (12 records including the namespace declaration)
  were byte-identical to the original backup,
  including the credentials, Orion settings and certificate material. The entire
  raw NVS partition was not byte-identical; application values were compared
  independently of NVS layout/system records. No private values were logged.

Final SuperMini artifact: [`orion-dongle-1.1.0.bin`](../output/firmware/1.1.0/orion-dongle-1.1.0.bin),
1,768,416 bytes, target `orion-dongle`, version `1.1.0`.

```text
File SHA-256: bd076a146cf98d6f0851fad0ee62fd6c4aa47f4bf6652cbbfb0eb98cb3d6e003
ELF SHA-256:  f7b0784e8a2757c27eea74462c36b3e898012739115f9f7bef57b0783d74226e
```

The nine rejection checks above used the temporary low-power diagnostic build
with the same image-validation code. The final round trip and idle-TLS recovery
used the complete final artifact. Both Orion targets also built successfully.
The package is byte-identical to the verified SuperMini build output.

## Remaining checks

- Recorded Android/iOS coverage, native file-picker responsiveness and the real desktop browser UI. A phone upload succeeded according to the user; OS/browser was not recorded.
  The available in-app browser rejected the self-signed certificate with
  `ERR_CERT_AUTHORITY_INVALID`; browser automation did not complete. The HTTPS
  test client instead trusted the exact certificate obtained through USB.
- Actual power removal during upload and during activation, followed by recovery.
- BLE reception, NMEA/Garmin output, long-term RF behavior and finished-enclosure
  range. These are not inferred from successful OTA, startup or heap messages.

No credentials, private keys, raw NVS contents or flash backup are published in
this report. A successful USB flash is not recorded as a successful OTA update.
