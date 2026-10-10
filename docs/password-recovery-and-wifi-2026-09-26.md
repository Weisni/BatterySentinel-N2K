> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](internal/README.md).

# Password management and service Wi-Fi readiness — 1.1.3

The portal supports changing the administrator password in Settings and a
Forgot password flow on the login page. The
[offline first-connection guide](erstverbindung.md) contains the recovery steps
and the fixed default `X8T6W4BDABQMZCYH6V`, generated once using the operating
system cryptographic RNG. It is public documentation, not a reset authorization
secret. Recovery requires a fresh form token, explicit confirmation and physical
BOOT held while the request is submitted to the running device.

Password changes require the authenticated session, its CSRF token, the current
password and matching new values of 12–128 UTF-8 bytes. Recovery requires an
existing administrator. Both flows clear the old session and CSRF tokens only
after successful persistence. Neither restarts the device or changes username,
Wi-Fi credentials, Orion identity/key, NMEA instances, channel aliases or TLS
credentials. Holding BOOT alone retains the existing Wi-Fi service behavior.

The new password salt and PBKDF2 hash share a single versioned NVS blob. Legacy
credentials continue to work until changed. A corrupt new credential record
cannot fall back to an obsolete legacy password; physical recovery repairs it.
Older firmware does not read the new credential record: downgrading after a
password change can reactivate the older legacy password. Use current firmware
for password recovery and avoid credential downgrades.

The active-low blue LED initializes off before serial/BLE/settings work. It
lights only when the driver reports AP_START, the AP has a usable IP address and
the HTTPS server task is ready. It turns off on AP_STOP, startup failure or
service shutdown, including during OTA handling. This uses live status without
a fixed startup delay. It does not depend on a connected client. R4 does not
drive GPIO8. Phone scan-list refresh latency and ROM/bootloader behavior before
application startup are outside this indication.

## Verification and remaining acceptance

Follow-up user report: after installing 1.1.3, Wi-Fi was available earlier. A
temporary `/login` failure (`ERR_SOCKET_NOT_CONNECTED`) disappeared after reload; see the
[1.1.4 login follow-up](login-reliability-2026-09-26.md). This is not a measured
LED timing or physical password-recovery result.

- All 94 native tests passed, including atomic credential persistence, legacy
  migration, failed writes, simulated interruption, corruption handling, guarded
  password changes and physical recovery policy.
- `orion_dongle`, `orion_r4` and the original `esp32c3` firmware build succeeded.
- Independent Python and production C++ image validation accepted both Orion
  1.1.3 images within their 1,966,080-byte application slots.
- Portal UI, OTA and local HTTP preview suites passed, including UTF-8 byte
  limits, confirmation, whitespace preservation, translation, live-request
  draining, OTA exclusion, reset confirmation and preserved assignments.
- Headless Edge rendered the new forms and success pages at 1280 px (English),
  360 px (German) and 320 px (English), without horizontal overflow or JavaScript
  errors. Preview password-change and simulated BOOT-recovery flows passed.
- The German manual was updated to edition 1.1 (24 pages) with the exact
  recovery default checked against firmware, retained interactive fields and
  rendered layout review.
- [Installable images and hashes](../output/firmware/1.1.3/README.md) are available.

Physical acceptance remains open: cold boot/SSID/LED timing, idle closure and
BOOT reopening; correct/incorrect current password, reset rejected without BOOT,
successful reset with BOOT, old-session rejection, and credential/configuration
persistence after a power cycle. No physical flashing or data reset is part of
this implementation task.
