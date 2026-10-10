# Project-internal development snapshot

This preserved text records engineering concepts and previous documentation, not existing or released product variants. Unbuilt hardware and the measurement concept are project-internal. Use the current project README and user manuals for the Orion Bridge.

---

# BatterySentinel N2K

Battery monitor for a 12 V boat electrical system with NMEA 2000 output to a Garmin chartplotter.

## Current Orion-R5 project status (2026-09-25)

The user confirms that all parts have been ordered and PCB manufacture has been commissioned. The project is waiting for delivery, followed by assembly and first commissioning of the complete R5 hardware. This supersedes earlier open-order and pre-fabrication planning statements below; physical hardware acceptance remains open.

- [x] Order components and commission PCB manufacture (user confirmed).
- [ ] Receive and inspect the PCB and parts; verify delivered module, cable, insert and fastener dimensions against the assembly requirements.
- [ ] Assemble the board and enclosure using the [current enclosure guide](../../hardware/altium-r5/enclosure/sealed-print/README.md) and [illustrated assembly manual](../../output/pdf/Orion-R5-Enclosure-Assembly-Manual-EN.pdf).
- [ ] Complete first power-up, Orion reception and NMEA/Garmin checks using the [German operating and installation manual](../../output/pdf/BatterySentinel-N2K-Orion-R5-Betriebs-und-Installationsanleitung-DE.pdf), and record the physical results.

## Orion-R5 enclosure for Bambu P2S

The [filament colour shortlist](../enclosure-filament-colours.md) (2026-09-25) maps the portal palette to purchasable navy, mint and white PETG with manufacturer RAL references and displayed prices. Navy with mint flush markings is the recommended theme combination. Physical colour matching, opacity and adhesion checks remain open; the print project is unchanged.

[Awesome AI process presets at 0.20 and 0.12 mm](../../hardware/altium-r5/enclosure/sealed-print/awesome-ai-profiles/README.md) combine the user's Smooth Surface top finish with the enclosure's walls, infill and conservative motion settings. Both presets passed native QuackSlicer coupon slicing and exported-setting checks; physical comparison of the merged finish remains open. Original presets and the four-plate project are preserved.

The [current P2S 3MF with flush-colour lid](../../hardware/altium-r5/enclosure/sealed-print/Orion-R5-P2S-flush-colour.3mf) preserves the user's four plates, including the PETG and TPU test plates. White PETG lettering and logo are printed level with the dark lid surface. [Colour and test-plate instructions](../../hardware/altium-r5/enclosure/sealed-print/flush-colour/README.md). The [assembly and printing guide](../../hardware/altium-r5/enclosure/sealed-print/README.md) explains the screw-fastened service covers, continuous TPU face seals, and unsplit replaceable cable cartridge. It follows the current 52 x 36 mm R5 PCB, with independent PCB retention and lid screws outside the seal. Sources: [sealed-enclosure generator](../../tools/build_orion_r5_sealed_enclosure.py) and [flush-lid revision](../../tools/build_orion_r5_flush_lid.py). Earlier files are retained for comparison.

The [illustrated enclosure assembly manual (English PDF)](../../output/pdf/Orion-R5-Enclosure-Assembly-Manual-EN.pdf) covers part identification, inserts, cable threading, seal operation, empty-case tests, PCB installation, lid tightening, mounting and service. It has 11 pages, a generated cover, nine CAD-derived illustrations and a printable acceptance record. [Manual sources, rebuild and QA notes](../enclosure-manual-production.md).

The 24 September PDF remains the mechanical assembly reference. Its cover shows the earlier engraved lid; follow the current colour instructions for the flush finish. Its instruction to create two test plates is already completed in the four-plate project. The 6.0 mm test sleeve is still provisional until the delivered cable is measured.

Colour revision progress (2026-09-25): CAD/mesh and four-plate native slicing checks passed; original meshes, object placement and both test plates are preserved. Toolpaths use contrasting PETG only in the first two layers. The validation slicer reports inherited bed-temperature/profile warnings; check actual filament specifications. New insert dimensions, real fit, colour adhesion and empty-case sealing remain physical checks.

Manual progress (2026-09-24): all 11 pages rendered and visually reviewed; PDF text, bounds, outlines, external links, source hashes and raster checks passed. Assembly instructions require the cable jacket to stay intact through the full sleeve and wet tests to finish before electronics are installed.

Progress (2026-09-24): native Altium outline, mounting holes, component placements and 224 component bodies match the geometry source. CAD fit/seal-land checks, 15 closed oriented meshes, nine-solid STEP readback, 16 independent blind-hole checks, and native Bambu Studio slice/reopen/re-slice passed. The enclosure package includes a blank cable closure, five cable-seal sizes and an actual-orientation fit coupon. Open: measured HangTon cable diameter, printed fit/insert tests, empty-case leak and pull tests, and powered thermal/RF checks. No verified IP or waterproof rating is claimed; see the package's validation records for digital results.

## German Orion-R5 operating and installation manual

[Download the German PDF manual](../../output/pdf/BatterySentinel-N2K-Orion-R5-Betriebs-und-Installationsanleitung-DE.pdf) - 24 pages covering safe installation, RUN/SERVICE and USB, first connection, administrator access, Orion provisioning, portal operation, firmware updates, Garmin acceptance and troubleshooting. Includes an interactive handover form and the portal's navy/teal styling with a battery-shield/lightning mark.

Progress (2026-09-24): generated and visually reviewed all 24 pages; verified PDF page bounds, navigation outlines and all 15 form fields/widgets. Screenshots use the actual firmware portal with explicitly synthetic data. [Build, sources and QA notes](../german-manual-production.md).

Findings and open tasks: the current R5 power/module records supersede earlier USB supply notes. The manual includes the phone-file OTA interface and USB fallback for older firmware; a physical SuperMini HTTPS OTA round trip passed on 2026-09-25, while phone-browser and power-loss acceptance remain open. Physical R5 power/thermal, enclosure/radio and Garmin acceptance checks remain open. Hardware planning reserves 12 LEN, while the current generic `orion_dongle` branch in `include/config.h` still uses the library-default value `0xff`; reconcile the advertised load with the measured R5 hardware before release. Revalidate this manual when firmware behavior or the finished hardware changes.

## Actual procurement costs (2026-09-25)

Costs reported by the user; payment status is recorded where confirmed. These amounts supersede the earlier estimates.

| Supplier / item | Recorded cost | Status |
|---|---:|---|
| JLC | EUR 40.20 | Paid |
| LCSC | EUR 58.22 | Paid |
| Amazon: NMEA 2000 T-piece, 1 unit | EUR 18.14 | Ordered; payment not separately confirmed |
| Amazon: ESP32-C3 SuperMini, 1 pack of 4 (without OLED) | EUR 18.99 | Ordered; payment not separately confirmed |
| Amazon: NMEA 2000 male-to-bare-wire drop cable, 1 m, 1 unit | EUR 16.26 | Ordered; payment not separately confirmed |
| Amazon: Habwea insert assortment + WZHUIDA M2 fastener assortment, one combined order | EUR 20.98 | Ordered 2026-09-25; payment not separately confirmed |
| **Total paid** | **EUR 98.42** | |
| **Amazon subtotal** | **EUR 74.37** | Ordered; payment not separately confirmed |
| **Total recorded costs** | **EUR 172.79** | Confirmed paid plus payment-unconfirmed amounts |

Amazon prices and quantities are from the user's cart screenshot. The T-piece is counted once. The ESP32 with OLED is excluded. The displayed 5% ESP32 coupon is not deducted until the final checkout amount is confirmed. Only one NMEA cable is included in this purchase list.

The order screenshot dated 2026-09-25 adds one Habwea 308-piece brass heat-set insert assortment (M2/M2.5/M3/M4/M5/M6, with soldering-iron insertion aid per the title) and one WZHUIDA 660-piece M2 stainless button-head hex-socket screw/nut/washer assortment. EUR 20.98 is the combined order total, counted once; individual prices are not shown.

All purchases are now reported as ordered; final Amazon checkout amounts and payments have not been separately confirmed. Open: receive and inspect the deliveries. Verify the purchased insert dimensions and screw lengths against the [current enclosure hardware requirements](../../hardware/altium-r5/enclosure/sealed-print/README.md); compatibility with the specified ruthex inserts and M2 x 5 screws is not established. The M2 assortment does not establish availability of the required M3 x 8 screws. [Four-board component list and procurement notes](../../hardware/altium-r5/lcsc-order-2026-09-24.md).

**Historical hardware procurement check (2026-09-24):** The user completed the native Orion-R5 Altium design; the supplied DRC report records zero violations. The earlier two-board cart and PCB/stencil estimates are retained in the [procurement report](../../hardware/altium-r5/lcsc-order-2026-09-24.md). The current order status and recorded costs above supersede those estimates.

**Orion Bridge: [Erstverbindung – Anleitung vor dem Verbinden öffnen, speichern oder ausdrucken](../erstverbindung.md).** WLAN-Zugang, individuelles Passwort über USB, BOOT-Taste und erste Anmeldung sind dort ohne Zugriff auf das Gerät beschrieben.

**Ohne Hardware: [Orion-Weboberfläche lokal öffnen und debuggen](../web-preview.md).** `node tools/preview_portal.mjs` startet die echte Portaloberfläche mit simulierten Daten und auswählbaren Fehlerzuständen.

**Orion hardware: [R5 with ESP32-C3 SuperMini](../../hardware/altium-r5/README.md).** All parts are ordered and PCB manufacture is commissioned; delivery, assembly and first commissioning are pending. Verify the delivered SuperMini's physical fit before soldering. **The R4 order packages remain withdrawn for this order** because they used a WROOM module instead of the requested SuperMini; see [release status](../../output/releases/RELEASE-STATUS.md). Historical versions: [R3](../../hardware/altium-r3/README.md), [R1 drawings](../../hardware/orion-pcb-r1.md) and [R2 library draft](../../hardware/altium-r2/README.md).

## V1 focus

V1 is deliberately brought up and tested first as a **single system-battery monitor**. The hardware keeps the second isolated measurement channel as an option, but it is disabled by default in firmware until its battery type/capacity are configured.

- ESP32-C3-WROOM-02-N8 (8 MB), native USB-C plus browser OTA.
- System battery default profile: **Duracell Advanced DA80, 80 Ah, 700 A EN, flooded lead-acid** (`GTIN 9005753086036`).
- System negative = ignition negative = `GND_SYS`.
- 500 A / 50 mV high-side system shunt; expected Mercury SeaPro 150 start current ~150–225 A.
- Optional second channel: `Unknown`, 0 Ah and disabled by default. It can later be enabled/configured without recompiling.
- Runtime battery types: Unknown, Flooded Lead Acid, AGM, GEL, EFB, LiFePO4 and Custom.
- Unknown battery type disables SOC but never fabricates a chemistry assumption.
- LiFePO4 does not use the generic lead-acid OCV correction path.
- Hybrid SOC: coulomb counting, chemistry-dependent charge efficiency, lead-acid OCV plausibility, full-charge synchronization and later off-time correction.
- NMEA 2000 live battery data using PGN 127508 and 127506.
- Native ESP32-C3 TWAI backend at 250 kbit/s; no legacy `NMEA2000_esp32` driver.
- ISO1042 galvanic isolation between ESP32/system domain and NMEA 2000.
- Automatic diagnostics Wi-Fi AP on every boot: 5-minute connection window, then radio off if unused.
- Browser configuration, live diagnostics and OTA firmware upload.
- External 32 MB SPI NOR design target for 1 Hz history plus 50 Hz event capture.
- Dual-slot I2C FRAM state store with CRC/sequence protection for power-loss-safe checkpoints.
- Host simulator and native TDD use the same core algorithms as firmware.

## System architecture

```text
SYSTEM BATTERY +
      |
   main fuse
      |
500 A / 50 mV high-side shunt
      |
      +---- Mercury starter / system loads / chargers
      |
   INA238
      |
     I2C
      |
ESP32-C3-WROOM-02-N8
  |       |        |
  |       |        +---- Wi-Fi AP -> browser config / diagnostics / OTA
  |       +------------- FRAM + external SPI NOR logger
  |
  +---- native TWAI ---- ISO1042 ---- NMEA 2000 ---- Garmin

GND_SYS = system battery negative = ignition negative

Optional future second bank:
second shunt -> INA238 -> ISO1640 -> ESP32
second battery ground remains isolated from GND_SYS
```

## High-side sign convention

NMEA 2000 PGN 127508 uses positive battery current for charging and negative for discharging. BatterySentinel therefore intentionally senses the high-side shunt as:

- INA238 `IN+` = load/charger side
- INA238 `IN-` = battery side
- positive current = charging
- negative current = discharging

The INA238 supports bipolar differential measurement, so this reversed sense polarity is intentional. The common-mode battery voltage remains within the device's high-side range.

At 225 A, a 500 A / 50 mV shunt (100 micro-ohm) drops ~22.5 mV and dissipates ~5.1 W.

## Runtime configuration

The boot web portal stores settings in ESP32 NVS. Changing chemistry or capacity invalidates a previously stored SOC unless the stored profile identity still matches.

The optional second channel remains silent on NMEA and does not generate sensor alarms while disabled.

## Diagnostics

On each boot:

```text
Power on
   |
   +--> WPA2 AP BatterySentinel-XXXX
           |
           +-- no client for 5 min --> Wi-Fi OFF
           |
           +-- client connected --> portal stays active
                                  --> 60 s after disconnect --> Wi-Fi OFF
```

Portal functions currently include live system data, battery type/capacity, alarm thresholds, optional second-channel enable and browser OTA.

## Logging / power-loss foundation

- Main sample rate: 50 Hz.
- Long-term target: 1 record/s.
- Log record: fixed 32-byte binary record with CRC8.
- 1 Hz storage requirement: 2,764,800 bytes/day, so 32 MB comfortably covers 5 days plus event reserve.
- Event target: 10 s pre-trigger + 30 s post-trigger at 50 Hz.
- Persistent state: two alternating 64-byte FRAM records with CRC32 and wrap-safe sequence numbers; a partially written record is ignored after reboot.

## Repository layout

- `docs/` architecture, SOC model, diagnostics/logging, hardware and test strategy
- `hardware/` BOM and schematic design notes
- `include/` firmware configuration
- `lib/BatteryCore/` platform-independent SOC/alarm logic
- `lib/BatteryProfiles/` chemistry/runtime profile model
- `lib/LogCore/` deterministic binary log record format
- `lib/StateCore/` power-loss-safe persistent state format
- `src/` ESP32-C3 firmware, diagnostics portal, INA238, TWAI and FRAM drivers
- `sim/` deterministic desktop simulator
- `sim/web/` public browser simulator deployed with GitHub Pages
- `sim/wokwi/` Wokwi custom-chip source and documentation
- `test/` native TDD/unit tests
- `.github/workflows/` CI and simulator deployment

## Build

```bash
pio test -e native
pio run -e esp32c3
```

Desktop simulator:

```bash
cmake -S sim -B build/sim
cmake --build build/sim
./build/sim/batterysentinel_sim
./build/sim/batterysentinel_sim faults
```

## Simulation

There are two complementary interactive simulation paths.

### GitHub Pages browser simulator

Public simulator:

**https://weisni.github.io/BatterySentinel-N2K/**

No installation is required. Open the page in a current browser and use the controls to change battery voltage, current and simulated fault states. The page is intended for fast functional testing and demonstrations of the BatterySentinel state/alarm behavior without local development tools.

The simulator source is in `sim/web/`. Changes to that directory on `main` are deployed automatically by `.github/workflows/simulator-pages.yml`.

### Wokwi ESP32-C3 simulation

Wokwi runs the **real ESP32-C3 firmware** against a simulated INA238 instead of reimplementing the firmware logic in JavaScript.

Prerequisites:

1. VS Code
2. PlatformIO extension
3. Wokwi extension for VS Code

Start the simulation from the repository root:

```bash
pio run -e esp32c3
```

Then:

1. Open `diagram.json` in VS Code.
2. Run **Wokwi: Start Simulator** from the command palette.
3. Watch the USB Serial/JTAG terminal for firmware output.
4. Select the simulated INA238 in the diagram to modify its attributes.

Simulated hardware:

- ESP32-C3 DevKitM-1 with 8 MB flash
- INA238 at I2C address `0x40`
- SDA GPIO4 / SCL GPIO5
- status/alarm LED GPIO10
- ignition switch on GPIO21 (`TX` pin alias in the Wokwi DevKitM-1 model)
- logic analyzer for SCL, SDA and IGN

INA238 attributes:

- `busVoltage`: simulated battery voltage
- `currentA`: simulated battery current; positive = charging, negative = discharge
- `sensorPresent`: `1` = sensor present, `0` = simulated sensor fault

Useful test cases:

| Scenario | Voltage | Current / setting |
| --- | ---: | ---: |
| Resting battery | 12.7 V | 0 A |
| Mercury engine crank | 9.5–11 V | -150…-225 A |
| Alternator charging | 14.2–14.7 V | positive current |
| Low-voltage under load | e.g. 10.5 V | negative current |
| INA238 failure | any | `sensorPresent=0` |

The precompiled INA238 custom-chip WASM is stored at `sim/wokwi/chips/ina238.chip.wasm`. Its source is rebuilt and the Wokwi circuit is lint-validated automatically by `.github/workflows/wokwi-chip.yml`.

Wokwi only partially simulates ESP32-C3 TWAI. Therefore the Wokwi setup validates firmware execution, INA238/I2C behavior, state handling, diagnostics/Wi-Fi startup and GPIO behavior. Final NMEA 2000 electrical and bus acceptance still requires a real CAN transceiver and NMEA 2000 network/test fixture.

More Wokwi-specific details are available in `sim/wokwi/README.md`.

## Status

**V1 engineering prototype.** The ESP32-C3 firmware now builds with a native TWAI backend and the native TDD/simulator pipeline is active. Logging storage, FRAM power-loss integration, NMEA alarms/time sync and final PCB/BOM are the next integration steps.

### Orion XS bridge investigation

![Battery Sentinel Orion Bridge logo](../../assets/battery-sentinel-orion-logo.svg)

The separate `orion_dongle` build receives Victron Orion XS 1400 Bluetooth Instant Readout and translates it to NMEA 2000 for the Garmin GPSMAP 723xsv, with phone-based HTTPS commissioning, a local administrator account, a guided first-installation flow and live diagnostics. It has no BatterySentinel alarms or SOC estimation. Build with `pio run -e orion_dongle`. The firmware fits a 4 MB ESP32-C3 SuperMini partition layout. On 2026-09-20, the user reported successful operation on the first attempt after entering the MAC address and key, identifying the tested charger as **Orion XC1400**. This is a user-reported Orion reception result; a recorded comparison of values with VictronConnect, Garmin interoperability and the isolated NMEA 2000 installation still require physical validation.

The default PlatformIO environment is now `orion_dongle` for the SuperMini. Select `esp32c3` explicitly to build the original 8 MB battery-monitor firmware; `native` runs host tests.

The dongle portal defaults to German. Use the language selector on any page to switch to English; the browser remembers your choice. Run `node tools/verify_portal_ui.mjs` to check translation coverage and portal behavior without device hardware.

**Login reliability follow-up (1.1.4):** After installing 1.1.3, the user reported earlier Wi-Fi availability and a transient login-page failure resolved by reload. The follow-up fixes GET `/login` navigation and releases the single HTTPS connection after every complete response; login also prevents duplicate submission and restores its button on browser Back. These code gaps are confirmed, but the original phone error has not been reproduced. Both Orion builds and 94 native tests pass; [SuperMini/R5 firmware 1.1.4](../../output/firmware/1.1.4/orion-dongle-1.1.4.bin) and [both board variants with hashes](../../output/firmware/1.1.4/README.md) are ready. The new image has not been flashed in this task. See the [implementation and verification record](../login-reliability-2026-09-26.md).

**Password management and Wi-Fi readiness (1.1.3):** Settings now offers an administrator password change with current-password verification. **Forgot password?** on the login page resets only that password after an explicit form confirmation while holding BOOT. The randomly generated recovery default and instructions are in the [offline guide](../erstverbindung.md#administrator-passwort-vergessen); username, Orion keys, channel assignments, Wi-Fi and other settings are retained. Both operations end the existing session. The SuperMini blue LED initializes off immediately and lights only after AP_START, a usable AP address and HTTPS readiness, without a fixed delay. All 94 native tests, all three firmware builds, OTA-image checks and portal/browser checks pass. Download the [SuperMini/R5 firmware 1.1.3](../../output/firmware/1.1.3/orion-dongle-1.1.3.bin) or see [both board variants and hashes](../../output/firmware/1.1.3/README.md). The [implementation record](../password-recovery-and-wifi-2026-09-26.md) separates these checks from physical reset/power-cycle and LED timing acceptance, which remain open. The new images have not been flashed in this task.

**OTA update progress:** The Orion Settings page accepts a local `.bin` file from a phone, shows upload progress, and restarts after successful verification. The authenticated HTTPS endpoint checks the exact board target, ESP32-C3 image structure, size, checksum and SHA-256 before activating the inactive OTA slot. SuperMini/R5 and R4 firmware carry distinct identities. See [firmware update instructions, validation details and limitations](../firmware-update.md). Older installations need the first OTA-capable build over USB. A phone OTA upload was confirmed by the user on 2026-09-25. Open acceptance tasks: recorded Android/iOS browser coverage and file-picker responsiveness, power-loss recovery and BLE/NMEA verification after reboot. Integrity checks do not authenticate the firmware publisher or detect runtime software faults.

**Hardware OTA checks passed (2026-09-25):** The attached 4 MB SuperMini completed `app0 -> app1 -> app0` through HTTPS OTA, with matching firmware hashes and retained settings after both restarts. Nine rejection/transfer-interruption cases passed. Hardware testing also identified fixes now included in the firmware: an 8.5 dBm service-AP transmit limit for SuperMini only, and one TLS session with LRU replacement to prevent stale connections from exhausting the heap. Deliberate idle-TLS recovery passed. Download the [tested SuperMini/R5 firmware](../../output/firmware/1.1.2/orion-dongle-1.1.2.bin); see the [test record, hashes and remaining checks](../ota-hardware-test-2026-09-25.md). The user subsequently confirmed a successful phone OTA update; OS/browser coverage was not recorded. The hardware test client verifies the device certificate obtained through USB.

**Portal responsiveness and saved key (1.1.1):** Physical OTA installed the new firmware and retained the existing login/configuration. Password verification decreased from about 10.2 to 5.7 seconds without changing the 120,000-round PBKDF2 format. File selection pauses live polling, startup requests run sequentially after the HTML loads, and the Readout field shows green placeholder stars plus **Schlüssel vorhanden** without exposing the key. An empty key preserves it only for the same normalized MAC; changing devices requires a new key. All 67 native tests, 138 password-reference vectors and the portal/OTA/preview suites passed. The native phone picker delay still needs a user retest; see [measurements, firmware and verification scope](../portal-performance-2026-09-25.md).

**Service Wi-Fi indicator and local address (1.1.2, historical validation):** The SuperMini/R5 blue LED now follows the open service WLAN; the user confirmed that it visibly lights. The portal is available at `https://batterysentinel.local/` through mDNS, with `https://192.168.4.1/` retained as fallback. Certificate V3 covers both names and preserves the existing key and all credentials/settings. Both board variants built, 79 native tests passed, and physical OTA, mDNS, authenticated access by hostname, strict TLS SAN checks and certificate reuse after restart passed. Idle LED-off/BOOT reopening and phone-specific discovery remain to be observed; see [the test record and firmware](../service-wifi-2026-09-25.md).

The Monitor page provides the available Orion parameters, NMEA output fields and separate Orion/NMEA diagnostics. MAC separators are added automatically. Measurements use three decimal places, while the Bluetooth source resolution remains 0.01 V and 0.1 A; displayed power is calculated from voltage and current. See [monitor parameters and counter meanings](../orion-xs-bridge.md#monitor-parameters-precision-and-counters).

The living [Orion XS bridge investigation](../orion-xs-bridge.md) records verified interfaces, Garmin display limits, credential provisioning, VE.Direct/GX alternatives, the proposed architecture, and open implementation gates.

The isolated ESP32-C3 SuperMini to NMEA 2000 reference hardware is documented as:

- [design notes, wiring, power/LEN calculation and order links](../../hardware/orion-dongle-nmea2000.md)
- [printable schematic (SVG)](../../hardware/orion-dongle-nmea2000-schematic.svg) and [rendered preview (PNG)](../../hardware/orion-dongle-nmea2000-schematic.png)
- [machine-readable prototype BOM (CSV)](../../hardware/orion-dongle-bom.csv)

This is a prototype carrier design, not a certified NMEA 2000 product.
