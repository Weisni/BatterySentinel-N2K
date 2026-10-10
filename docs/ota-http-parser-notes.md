> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](internal/README.md).

# OTA rejection test: send the beginning of the request body

During hardware acceptance on 2026-09-25, an unauthenticated HTTPS POST to
`/api/firmware` declared a firmware-sized `Content-Length` but sent only headers.
The connection closed without an HTTP response after approximately five seconds.
This request did not reach the Orion upload handler.

The [ESP-IDF 4.4.7 HTTP parser source](https://github.com/espressif/esp-idf/blob/v4.4.7/components/esp_http_server/src/httpd_parse.c)
explains the behavior:

- `cb_headers_complete()` changes the parser state to `PARSING_BODY` (line 365).
- For a nonempty body, `cb_on_body()` changes it to `PARSING_COMPLETE` after the
  first body bytes arrive (line 393).
- `httpd_parse_req()` waits for that state before invoking `httpd_uri()`
  (lines 603–605), which dispatches the application handler.

On the same connected board, otherwise equivalent unauthenticated requests
including one byte or 288 bytes of the body returned `401 Unauthorized` with
`{"ok":false,"error":"auth"}` immediately. These observations establish a test
harness issue, not a failure of the OTA authentication response.

Early rejection tests must send at least one body byte with their headers when
declaring a nonzero `Content-Length`. Sending the 288-byte application header and
descriptor prefix is suitable for tests using a real firmware image. Do not use
`Expect: 100-continue` in this harness. Normal browser firmware uploads send the
body and are unaffected by this particular test construction.

A temporary `TCP_NODELAY` change was investigated and removed after this result;
it did not resolve the header-only request behavior. This finding does not by
itself establish successful firmware installation or radio stability; those are
separate hardware acceptance results.
