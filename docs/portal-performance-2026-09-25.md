> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](internal/README.md).

# Orion portal responsiveness and saved-key follow-up

Firmware: `1.1.1`, SuperMini target `orion-dongle`.

The user confirmed a successful phone OTA update with 1.1.0, but reported slow
sign-in and a long delay returning from the native file picker. The stored
Instant Readout key also had no visible presence indication.

## Measured password verification

The same attached ESP32-C3, existing administrator account and trusted device
certificate were used before and after the update. Ethernet remained active;
device traffic used the separate WLAN adapter. Requests were sequential. Each
measurement deliberately opened a fresh TLS connection, so total timings are
not a browser benchmark with connection reuse.

| Measurement | 1.1.0 | 1.1.1 |
| --- | ---: | ---: |
| Password derivation, device event | 10,247 / 10,140 ms | 5,615 / 5,699 ms |
| Login POST including new TLS connection | 11,860 / 11,797 ms | 7,187 / 7,203 ms |
| Login-page HTML | 70,230 bytes | 54,630 bytes |
| Dashboard GET including new TLS connection | 2,015 / 2,172 ms | 2,235 / 2,547 ms |

Password derivation improved by about 45%. The remaining roughly 5.7 seconds of
derivation and 1.4–1.6 seconds of TLS establishment are still noticeable. The
dashboard measurements do not demonstrate a general page-transfer speedup;
the changes there prevent competing connections rather than promise a faster
individual GET.

PBKDF2-HMAC-SHA256 still uses **120,000 iterations**, a 16-byte salt and a
32-byte result. The implementation prepares the inner/outer HMAC SHA states
once and clones them for subsequent rounds, avoiding repeated key-pad hashing.
It uses the SDK's mbedTLS SHA API. The credential format, existing NVS hashes,
full-byte comparison and password policy remain unchanged. Temporary hash
material is cleared. No password reset or credential migration is needed.

## File selection and HTTPS scheduling

The file-selection handler only inspects filename and size. It does not read
file contents, calculate hashes or send the image. The observed native picker
stall therefore has no proven firmware cause.

The portal now pauses and drains live polling when the picker opens. It displays
the local selection before resuming polling after 500 ms; cancellation and
focus/visibility fallback are covered. Hidden pages pause live requests, and
intentional pauses no longer show a false offline state. Picker return cannot
unlock an active or uncertain OTA operation.

Device API startup waits for `DOMContentLoaded`, then reads the complete
firmware-metadata response before starting live polling. Manual refresh,
visibility changes and metadata retries respect that coordination. This avoids
two requests competing for the deliberately single HTTPS connection slot.
The favicon is inline, and login/setup/message pages omit dashboard-only
controllers. No new cloud requests or external assets are introduced.

## Stored Readout key

The configured key field displays green placeholder stars, a green field and
the green message **Schlüssel vorhanden** (English: **Key present**). Its actual
input value stays empty; the device never renders the stored secret into HTML.

Saving an empty key is allowed only for the same normalized MAC with an already
stored key. Changing MAC requires a valid new 32-digit key. Literal stars are
invalid input. Clearing a newly typed key returns to retaining the existing key
only when the MAC still matches. Client and server enforce the same rules.

## Verification

- 67/67 PlatformIO native tests passed, including five new password-hash tests
  covering boundary lengths, production iteration count and crypto failure
  cleanup. The existing CI native-test job includes them automatically.
- 138 host outputs matched Python `hashlib.pbkdf2_hmac`, including 30 cases with
  120,000 iterations, binary/UTF-8 inputs, zero bytes, passwords crossing the
  64-byte HMAC boundary and the 128-byte limit. Eight invalid CLI inputs failed.
- Portal UI, OTA and preview suites passed, including deferred metadata bodies,
  refresh/visibility races, picker cancel/return and secret-free key retention.
- A local mobile-width browser check verified green stars/message, native form
  validity and an empty submitted `key` value. This is a synthetic preview,
  separate from the physical phone test.
- Both Orion variants built. The SuperMini image passed the independent Python
  checker and production C++ streaming validator before installation.
- Physical, certificate-verified OTA installed `1.1.1`: `app1 -> app0`, HTTP 200,
  restart, expected running ELF hash and unchanged dashboard configuration.
  The existing administrator password authenticated after reboot and in both
  timed comparisons. No USB firmware flash was used for this update.
- Four physical configuration rejection cases passed: changed MAC without key,
  literal stars, non-hexadecimal key and duplicate NMEA instance. Saving the same
  normalized MAC with an empty key returned HTTP 200 and retained configuration
  after restart. A wrong administrator password returned 401 without a session.
- A final USB readback compared the stored application values with the private
  pre-follow-up NVS readback. All 11 `orion-bridge` values were byte-identical,
  including the 16-byte Readout key, administrator credentials and certificate
  material. Page/entry/payload CRCs were checked while decoding. The complete
  raw NVS bytes differed; the comparison used live records according to the
  [ESP-IDF NVS format](https://docs.espressif.com/projects/esp-idf/en/v4.4.7/esp32c3/api-reference/storage/nvs_flash.html#internals).
  Neither readback nor any secret value was published. USB was used only to read,
  followed by the programmer's normal reset.

`tools/measure_portal_latency.py` reproduces the sequential timing measurements;
`tools/test_portal_settings_device.py` reproduces the physical configuration
checks. Both take credentials through stdin and use the supplied trusted device
certificate. The latter deliberately resaves the existing configuration and
restarts the device once.

The native phone file picker must be retested by the user to assess the perceived
delay. Phone OS/browser coverage, power-loss recovery, BLE/NMEA/Garmin output
and enclosure RF range remain separate acceptance work.

## Artifact

[`orion-dongle-1.1.1.bin`](../output/firmware/1.1.1/orion-dongle-1.1.1.bin),
1,773,216 bytes. Use this application image for SuperMini/R5 only.

```text
File SHA-256: 8ff55342b3527455e586c338b41baa7d8ab720cb11f0bdb1c1ce43f1e6752552
ELF SHA-256:  7ebf0cdd0ffa2c62bec8d726fc620e112dc5263a6be91d4defc575c10cf232cb
```
