> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](internal/README.md).

# Service Wi-Fi indicator and local address — 1.1.2

The SuperMini/R5 blue LED now lights continuously while the service access point
is open. It turns off when the existing five-minute timeout closes Wi-Fi after
the last client leaves. It does not indicate login status or Orion reception.
The normal BOOT-button reopening behavior remains unchanged.

The selected module's [C3 schematic](../hardware/altium-r5/references/amazon-B0FN4F6244-core-schematic.jpg)
connects the blue LED from 3V3 through a resistor to GPIO8: LOW turns it on.
Firmware initializes the output HIGH after normal boot, then drives it LOW only
after AP startup. Start failures that close Wi-Fi restore HIGH. The R4 WROOM
build excludes this GPIO operation because it has no SuperMini LED.

## Local HTTPS address

Connect directly to the bridge Wi-Fi and open **https://batterysentinel.local/**.
The device advertises its IPv4 address using the installed ESPmDNS responder
and publishes `_https._tcp` on port 443. Discovery starts with the service portal
and is freed before Wi-Fi shutdown, including partial-initialization cleanup.

**https://192.168.4.1/** remains available if the client cannot resolve `.local`.
This is mDNS on the local Wi-Fi link; it does not register a public internet
domain or change the computer's LAN DNS configuration. No captive portal or
wildcard DNS interception is added.

## Certificate migration

Certificate format V3 includes the DNS SAN `batterysentinel.local` and IP SAN
`192.168.4.1`. It remains a device-specific self-signed certificate, so an existing
browser exception may need confirmation again after the update. The certificate
now uses a random serial number and retains the previous valid EC-P256 key.

The new `tls3_key` and `tls3_cert` entries are staged separately; `tls_ver=3` is
written last. Legacy certificate/key entries remain available after an interrupted
V2 migration. A valid V3 certificate is reused: actual DNS/IP SANs, matching key,
leaf/server-auth/digital-signature extensions and its SHA256/ECDSA self-signature
are checked before use. Certificate validation is not replaced with a CN-only
or substring match.

Administrator credentials, Wi-Fi password, Orion identity/key and channel
configuration are not reset.

## Verification on 2026-09-25

- Both `orion_dongle` and `orion_r4` built and passed independent Python and
  production C++ image validation; both remain inside their 1,966,080-byte slots.
- All **79 native tests passed**, including 7 SAN tests and 5 certificate-store
  tests covering interrupted/short writes, retained legacy data and retry.
  Independent OpenSSL parsing also checked the generated SAN DER bytes.
- Portal UI, OTA and preview JavaScript suites passed. The bounded mDNS probe's
  offline parser tests cover compressed names, malformed/truncated responses,
  QU requests and goodbye TTLs; the probe is included in CI.
- The physical SuperMini accepted `1.1.2` via certificate-verified HTTPS OTA,
  moving from `app0` (`1.1.1`) to `app1`. Serial boot confirmed `1.1.2`, key reuse,
  HTTPS startup and the advertised local URL.
- Direct mDNS probes on the PC's WLAN returned `192.168.4.1` from the expected
  device on the first attempt: 63 ms initially and 328 ms after a restart.
- Windows system resolution of mixed-case `BatterySentinel.local` also returned
  `192.168.4.1` with LAN and WLAN active. The first system lookup took 12.156 s;
  direct device mDNS replies were much faster. Client resolver delay should not
  be confused with firmware page or login processing. Use the IP fallback if
  name resolution is slow on a particular client.
- The new public certificate was obtained independently through USB. A real
  HTTPS GET using the DNS name for SNI/Host and strict SAN verification returned
  HTTP 200. No certificate checks or OS trust settings were disabled.
- Administrator login, dashboard and authenticated firmware metadata also
  succeeded through `BatterySentinel.local` using the Windows resolver. The
  running/boot slot, expected ELF hash and pre-update settings fingerprint
  matched. Both IP and DNS-name TLS verification passed; an unrelated hostname
  was rejected.
- A USB NVS comparison validated record CRCs and confirmed the expected migration
  only: all prior application values retained, `tls_ver` advanced, and two new
  V3 entries. The new private key is byte-identical to the previous key. Raw
  readbacks/private keys remain outside the repository and are never logged.
- Following that USB readback and normal reset, startup did not reissue the
  certificate. The subsequent HTTPS connection presented the same fingerprint
  as the public certificate just read from flash.
- With the new service active, serial reported 87,732–90,088 bytes of free heap,
  compared with 95,840
  bytes in the earlier snapshot. Client counts/activity differ; this is not an
  isolated mDNS allocation benchmark.

- The user confirmed that the blue LED visibly lights with the new firmware
  while the service Wi-Fi is active.

The five-minute idle LED-off transition, BOOT reopening and phone-specific
`.local` behavior still require physical/user observation. No
BLE/NMEA/Garmin or enclosure RF acceptance is inferred from these checks.

## Release artifact

[`orion-dongle-1.1.2.bin`](../output/firmware/1.1.2/orion-dongle-1.1.2.bin),
1,804,992 bytes, for ESP32-C3 SuperMini/R5.

```text
File SHA-256: 1db128bc51b3b4618e80536fa53f0aa17adc7aeb643bdfc37645b8c0b04135cc
ELF SHA-256:  38b6545c4b2c7769afc7bd958d357b5992b8762db67fe1c8d84cbbae199383ae
```

Use `tools/test_portal_name.py --interface-ip <PC-WLAN-IP> --ca <trusted-cert.pem>`
for a bounded discovery/HTTPS check. `tools/check_portal_nvs.py` compares private
unencrypted NVS readbacks and can export only the public certificate, without
printing stored values.
