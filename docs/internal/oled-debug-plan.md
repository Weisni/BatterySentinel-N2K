# OLED debug build implementation plan

Goal: provide the requested dedicated ESP32-C3/OLED debug firmware with a fixed connectivity bar and diagnostic pages advancing every 500 ms.

Architecture: keep the current bridge and settings, add a compile-time board profile, a pure bounded text/page model and a small display adapter. Read connectivity from service readiness, TWAI receive/state counters and accepted Orion records. The model does not drive bridge behavior.

## Constraints and evidence

- Amazon B0FP81HMYB vendor diagrams confirm SDA5/SCL6, active-low LED8 and 4 MB flash. CAN uses TX4/RX7 on a separately wired debug jig.
- Display profile: SSD1306-compatible 72 x 40 at 0x3C, U8g2 2.36.5. Exact controller/geometry still require a physical border test; the seller does not specify them explicitly.
- Keep the current default build, retained data and assignments. Give the debug image its own `orion-debug-oled` identity to reject cross-board OTA.
- Use English text, fixed buffers and monotonic scheduling. Never label send-queue acceptance as network connectivity.

## Tasks and verification

1. Add pure `DebugDisplayModel.h` and native Unity cases before its implementation: startup, 499/500 ms boundary, delayed loops, rollover, stale/invalid/nonfinite values, bounded rows, inactive/faulted/quiet CAN, and unknown time.
2. Add read-only TWAI diagnostics to `NmeaPublisher::busStatus()`, including current driver state, valid extended RX age/count and hardware error counters. Keep access on the main loop.
3. Add the board profile, distinct image identity and exact-target validation tests. Integrate OLED startup, bounded I2C failure and page rendering without a 500 ms sleep.
4. Build debug and default targets, run native and image-validator tests, inspect the actual image identities/partition fit, and produce a USB installation package plus an application-only OTA file.
5. Record pin wiring, display symbols/pages, verified checks and pending physical checks in the debug guide and project README. Independently review integration for false readiness, stale values, unavailable hardware and boot behavior.

## Review focus

Missing OLED must not prevent BLE, Wi-Fi or CAN startup. A bus with only local queued sends must remain waiting. Old Orion data must disappear from measurements. The frame must fit 72 x 40 without a hidden row. Firmware for the debug jig must not be accepted by the normal carrier image, or vice versa. Physical readability, exact display geometry and real bus/phone behavior remain device acceptance checks.

## Implementation result — 2026-09-28

All implementation tasks are complete. The full native suite passes 165 cases, including 17 display-model cases and the debug-image identity case. Nine host-side OLED lifecycle/fault scenarios pass. Sixteen Python OTA-validator tests and the portal OTA behavior suite pass. The debug target and every pre-existing configured firmware target compile successfully. Independent Python and production C++ image checks accept the final debug application: 1,939,552 bytes, with 26,528 bytes left in the OTA slot. Code review found a missing serial report on boot-frame failure; it was fixed and the fault test now passes. No hardware was flashed; the debug guide lists the remaining physical checks.

Nine additional TWAI host-boundary scenarios pass against the real backend source. A native U8g2 2.36.5 raster preview covers 16 example/fault/format-limit frames and checks that actual font pixels stay within the 72 x 40 display bands. The seven-page GIF uses 500 ms frames. The package contains segmented USB images, the OTA application, instructions, source/file hashes, the U8g2 license and the synthetic previews. ZIP contents were reopened and compared byte for byte. These checks do not verify the delivered physical panel or network.
