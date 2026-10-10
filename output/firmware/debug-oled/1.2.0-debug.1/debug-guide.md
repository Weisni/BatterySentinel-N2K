# Orion Bridge OLED debug guide

This engineering guide covers the separate `orion_debug_oled` build for the ESP32-C3 board with an integrated monochrome OLED sold under Amazon ASIN **B0FP81HMYB**. Firmware identity: **`orion-debug-oled`**, version **`1.2.0-debug.1`**. Its connectivity bar stays above seven diagnostic pages, which advance every 2 seconds during normal operation.

Use the [debug firmware package and installation files](README.md). This build has its own artifacts and board wiring; it does not replace the production Orion Bridge download. The OLED board is **not a plug-in replacement for the Orion carrier board**.

## Board evidence and display assumption

The exact [Amazon listing and seller diagrams](https://www.amazon.de/dp/B0FP81HMYB) identify the ESP32-C3 board with 4 MB flash, OLED SDA on GPIO5, OLED SCL on GPIO6, an active-low blue LED on GPIO8 and BOOT on GPIO9. Check the delivered board against the listing before wiring it; marketplace variants can change.

The firmware assumes an **SSD1306-compatible 72 x 40 display at I2C address `0x3C`**. The exact listing does not explicitly establish the controller, resolution or address. A [vendor listing for the matching board family](https://www.hestore.eu/en/prod_10049016.html) documents those display details and the same SDA/SCL pins. This supports the selected profile but does not prove that the delivered Amazon unit uses it.

The build uses U8g2 `2.36.5` and `U8G2_SSD1306_72X40_ER_F_HW_I2C`. Its native [72 x 40 driver](https://raw.githubusercontent.com/olikraus/u8g2/master/csrc/u8x8_d_ssd1306_72x40.c) handles the controller's column offset. Do not add a second offset from a generic 128 x 64 example. Confirm the complete startup border and all text on the actual display before accepting the profile.

## Wiring and power

Start with the module powered through a USB data cable and no CAN network attached. GPIO4 replaces the production CAN transmit pin because GPIO6 is already connected to the OLED.

| OLED debug board | Connection or purpose |
| --- | --- |
| GPIO4 | CAN controller TX to the external transceiver's **TXD input** |
| GPIO7 | CAN controller RX from the external transceiver's **RXD output** |
| GND | Logic-side ground of the external CAN interface |
| GPIO5 / GPIO6 | Built-in OLED SDA / SCL; reserve these pins |
| GPIO8 | Built-in blue service Wi-Fi LED; reserve this pin |
| GPIO9 / BOOT | Built-in BOOT button; reserve this pin |

**The GPIO signals are 3.3 V logic, not CAN bus wires.** An external CAN transceiver with compatible logic levels is required. Use an appropriately powered, protected and isolated NMEA 2000 interface for connection to the vessel network; follow that interface's supply and isolation requirements. CAN-H and CAN-L connect to its bus side, never directly to GPIO4/GPIO7. Never connect NMEA network 12 V directly to GPIO, 3V3 or USB. Do not bridge the interface's isolation barrier with an extra ground wire.

The firmware operates at 250 kbit/s. A working USB/OLED module alone is not an electrically complete NMEA 2000 node. Verify wiring, supply, polarity and network termination before connecting it to an operating network. Espressif describes the controller/transceiver distinction and error states in its [ESP32-C3 TWAI documentation](https://docs.espressif.com/projects/esp-idf/en/v4.4.7/esp32c3/api-reference/peripherals/twai.html).

## Build and first USB installation

Run these commands from the project directory with PlatformIO installed:

```powershell
pio run -e orion_debug_oled
pio device list
pio run -e orion_debug_oled -t upload --upload-port COMx
```

Replace `COMx` with this module's actual USB port. If the uploader cannot enter download mode, hold BOOT while connecting USB or resetting the module, then release BOOT and retry using the enumerated port. After upload, reset normally with BOOT released. Holding BOOT across reset enters download mode; it is different from the service-Wi-Fi button action after startup.

**Do not erase the flash.** This target keeps the existing 4 MB partition layout, including settings storage; a normal update retains saved settings and assignments. A new module has its own empty settings and does not inherit another Bridge's credentials or Orion configuration.

Open its serial monitor to verify the installed target/version and obtain first-setup information:

```powershell
pio device monitor -b 115200 --port COMx
```

The boot identity must report `target=orion-debug-oled version=1.2.0-debug.1`. Complete ordinary portal setup on the new board: connect to `OrionBridge-XXXXXX` using its individual service password, open `https://192.168.4.1/`, create the administrator while holding BOOT until the response, then configure the Orion MAC, Instant Readout key and distinct input/output instances. The local HTTPS certificate requires the usual browser exception for the directly connected Bridge.

NMEA is intentionally not started until an Orion is configured, so **`N- O- T-` is expected on a new board**. Wi-Fi closes after five minutes without a client. After a normal boot, holding BOOT for more than two seconds opens it again and prints the service password locally. The `docs/erstverbindung.md` in the source checkout describes credentials and configuration; its carrier-board SERVICE/RUN instructions do not apply to this separately wired USB debug jig.

Later portal OTA updates must use an application image with the matching `orion-debug-oled` identity. The distinct target prevents normal production images and OLED debug images from being exchanged through OTA. Use the package README for the exact supplied filenames and USB/OTA distinction.

## Startup and status bar

Startup shows `Orion debug`, the current stage (`USB / boot`, `Settings`, `BLE start`, `WiFi / HTTPS`) and `72x40 OLED`, surrounded by a border. These are progress stages, not a guarantee that each service succeeded. During normal operation the fixed top row resembles `W+ N? O+ T-`.

| Indicator | Meaning |
| --- | --- |
| `W+` | Service access point has started, has an IP address and the HTTPS service is ready. A phone need not be connected. |
| `W-` | Service Wi-Fi/HTTPS is not ready or the service window is closed. |
| `N+` | CAN controller is running, transmit/receive error counters are below 128, and a valid extended data frame was received within the last 5 seconds. |
| `N?` | CAN controller is running without qualifying recent reception. |
| `N-` | CAN controller is not running, including unconfigured or unavailable NMEA. |
| `N!` | Bus-off, recovery state, or a transmit/receive error counter of at least 128. |
| `O+` | A record from the configured Orion was accepted within the last 10 seconds. |
| `O?` | Orion is configured, but data has not arrived or is older than 10 seconds. |
| `O-` | No Orion is configured. |
| `T+` | UTC is synchronized to validated NMEA network time. |
| `T~` | UTC continues from the last trusted time anchor; no accepted fresh time for more than 30 seconds (holdover). |
| `T!` | A time discontinuity is quarantined; the displayed clock continues from its last trusted anchor. |
| `T-` | Time is unknown or still acquiring consistent observations. |

`N+` establishes recent CAN activity, not reception of a particular PGN, Garmin acknowledgement or successful display on a plotter. Accepted local send requests alone never turn it on. `O+` concerns accepted Instant Readout records, not a persistent Bluetooth connection. UTC is not local civil time and is unavailable until a valid source has been acquired during this boot.

## Diagnostic pages

The first normal frame is the input page. The main loop advances one page whenever at least 2 seconds have elapsed, then repeats after page seven. There is no 2 seconds page sleep. A busy loop advances once when it resumes rather than showing a rapid burst of missed pages.

| Page | Rows | Interpretation |
| --- | --- | --- |
| Input | `IN 12.34V`, `IN 5.6A`, `IN 69.1W` | Orion input voltage/current and their calculated product. |
| Output | `OUT 13.50V`, `OUT -2.0A`, `OUT -27.0W` | Orion output voltage/current and their calculated product. |
| Orion reception | `BLE -67dBm`, `Age 1s`, `R42 E0` | Last accepted record's signal strength and age; accepted records and receiver errors. Errors include rejected records, queue drops and startup failures. |
| CAN controller | `RX 4567`, `TXF 8`, `E0/0` | Valid extended received frames; driver failed-transmission count; current transmit/receive error counters, in that order. |
| Time | `UTC 12:34:56`, `Up 20s`, `T age 1s` | UTC time of day, monotonic uptime, age of the last accepted time anchor. |
| Resources | `Heap 100KiB`, `Min 50KiB`, `W1 H1` | Free and minimum free heap; connected Wi-Fi clients and current HTTPS clients. |
| Notifications | `Alerts 2` or `Alerts off`, `Unacked 1`, `St3 Err0` | Local active and unacknowledged notifications; raw Orion charger state/error codes. These counts do not confirm remote alert delivery. |

Examples illustrate formatting, not measurements from a tested device. `--` means unavailable, invalid or stale. Electrical values, BLE signal strength and charger state/error stop being shown as current after ten seconds without an accepted Orion record. Reception age and accumulated counters remain useful historical information. Power is voltage multiplied by current for the corresponding Orion channel; it is not total battery power. The display does not calculate battery SOC or remaining life.

Counters cover the current boot. The `E` transmit/receive controller counters can decrease again after successful bus activity; `TXF` is a driver failure count, not the application's queue-submission count. Fields that exceed the available numeric width are capped with a trailing `+` (for example `999+`). Use the portal monitor and diagnostics for fuller detail.

## Missing display and faults

OLED access uses 400 kHz I2C with a 20 ms Wire timeout. A failed address probe or initialization leaves the OLED unavailable while bridge startup continues. On the first later I2C transfer failure, the remaining frame transactions are skipped and the display is disabled until the next boot. Normal page-rendering failures are reported over serial; there are no repeated recovery attempts in the bridge loop.

A failed display may remain blank or retain its last pixels. **A frozen status bar is not live status.** Check the portal/serial output, correct the display fault and reboot. A shifted, cropped or incomplete startup border requires checking the actual controller/geometry rather than accepting the assumed profile.

The CAN backend currently has **no automatic bus-off recovery**. For `N!`, inspect the electrical interface, wiring, network power and termination. After correcting the fault, reboot to restart the controller. Do not use repeated restarts as a substitute for fixing an electrical fault.

## Hardware acceptance record

These checks are still physical acceptance tasks. Builds, native tests and generated artifacts cannot establish compatibility with the delivered display or verify operation on a vessel network. Record the board variant, firmware identity, test conditions and result for each check.

- [ ] Boot on USB with no CAN attached. Confirm all four border edges, unclipped text, readable orientation and progression through startup stages.
- [ ] Complete first portal setup. Confirm Wi-Fi/HTTPS readiness against `W`, then close/reopen the service window and observe the status/blue LED.
- [ ] Leave Orion unconfigured: expect `O-`, `N-`, `T-` and unavailable electrical values. Configure Orion but with its radio unavailable: expect `O?`, not false fresh values.
- [ ] Receive real Orion data, compare voltage/current with the portal, then remove reception. After more than ten seconds expect `O?` and `--` for stale live fields; reception counters must not masquerade as current data.
- [ ] With a correctly wired CAN interface, receive real extended frames and compare `RX`/`N+`. Stop external traffic: after more than five seconds expect `N?` if the controller remains running and healthy. Verify the intended PGNs separately on the actual plotter.
- [ ] On an isolated test setup, exercise unavailable CAN and controlled error/bus-off conditions. Confirm the error counters and `N!`; repair the electrical fault before testing restart recovery. Never induce faults on an operating vessel network.
- [ ] Acquire network UTC and compare it with the trusted source. Disconnect that source: confirm increasing `T age` and transition to `T~` after more than 30 seconds. Reboot without a source: UTC must be unavailable, not a fabricated timestamp. Test a time jump only with a controlled simulator and confirm quarantine.
- [ ] Exercise an absent/unresponsive OLED on a safe bench setup or suitable fault fixture. Confirm bounded failure, serial reporting and continued bridge operation; reconnecting the display alone must not imply recovery before reboot.
- [ ] Observe repeated seven-page cycles while BLE, CAN and HTTPS are active. Check readability, page timing, resource values, and that no row or unit is clipped.
- [ ] Reflash/update without erasing flash, then power-cycle. Confirm retained administrator, Orion key, aliases and instance assignments; verify that an incompatible OTA target is rejected.

The current implementation and open validation work are tracked in the source checkout's `README.md` and `docs/internal/oled-debug-plan.md`.
