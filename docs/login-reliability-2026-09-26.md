> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](internal/README.md).

# Login navigation and HTTPS cleanup — 1.1.4

## User observation

After installing 1.1.3, the user reported that the service Wi-Fi became available
earlier. Immediately after login, `/login` was briefly unavailable; reloading
resolved it. The user subsequently identified the browser error as
`ERR_SOCKET_NOT_CONNECTED`. This confirms the reported improvement in discovery
timing, not measured LED timing. The socket error is consistent with a transport
failure during navigation; a physical reproduction is not yet available.

## Confirmed implementation gaps

- Firmware registered GET `/login` but never handled it. An unauthenticated
  request fell through to 401; an authenticated request fell through to 404.
  The local preview served a login page directly and concealed this difference.
- Replies advertised `Connection: close`, but successful handlers returned
  `ESP_OK`. In the matching ESP-IDF 4.4.7 implementation, successful handlers
  leave the socket alive. With one TLS slot, the next handshake then depends on
  peer shutdown or asynchronous LRU cleanup.

These are concrete defects, but neither proves the cause of the user's one-off
browser failure. The relevant Espressif implementation is
[session processing](https://github.com/espressif/esp-idf/blob/v4.4.7/components/esp_http_server/src/httpd_sess.c)
and [server connection handling](https://github.com/espressif/esp-idf/blob/v4.4.7/components/esp_http_server/src/httpd_main.c).

## Changes

GET `/login` now redirects to the canonical `/` page, which chooses first setup,
sign-in or dashboard using the account/session state. POST login retains its
password verification, secure cookie and 303 redirect.

After a handler has finished sending its response, dispatch returns `ESP_FAIL`
to request immediate transport cleanup by IDF. This is the server's socket-close
signal, not an HTTP error response. It frees the TLS connection before the next
accept, while preserving the authenticated application session. It also covers
redirects, streamed pages, APIs and completed/failed OTA requests. The one-slot
memory limit and existing sequential browser requests are retained; there is no
added wait, blind retry or repeated password submission.

The login form suppresses duplicate submission and restores its controls when
the browser returns to a cached login page. This does not override the browser's
native error-page behavior: explicitly reloading a failed POST can resubmit it.
Opening the portal root or GET `/login` instead does not resend credentials.

## Verification

- All 94 native tests passed; both `orion_dongle` and `orion_r4` 1.1.4 builds
  succeeded. Independent Python and production C++ validators accepted both
  packaged OTA images inside their application slots.
- Portal UI, OTA and HTTP preview suites passed, including duplicate login
  submission prevention, persisted-page restoration and canonical GET `/login`.
- The bounded `verify_portal_login_browser.cjs` suite passed in desktop Edge
  with German and English UI: native POST/303/GET, delayed response, duplicate
  suppression, successful-login reload without POST replay, real Back and
  persisted-page restoration. An aborted POST triggered no automatic retry;
  explicit browser reload resubmitted once, while explicit GET `/login`
  recovered without resubmission. This uses a synthetic HTTP server.
- `python tools/verify_portal_http.py --check-regressions` passed 69 assertions
  against complete handler definitions extracted unchanged from the firmware,
  including cookie/303 preservation, account-state routing, completed page sends,
  errors and send-failure cleanup. Restoring either original defect separately
  made the intended regression check fail. CI runs the normal handler suite.
  These tests simulate transport writes and IDF's documented closure contract;
  they do not emulate a radio or TLS handshake.
- The German manual was refreshed to edition 1.2 for firmware 1.1.4; all 24 pages,
  15 interactive fields, text bounds and source hashes passed validation.
- [Installable images and hashes](../output/firmware/1.1.4/README.md) are ready.

Repeated login/redirect tests on the physical phone, following the update, are
still required. No device flashing, credential reset or physical acceptance is
implied by the local checks.
