# BatterySentinel N2K

Dual-battery monitor for a 12 V boat electrical system with NMEA 2000 output to a Garmin chartplotter.

## V1 goals

- One **ESP32-C3-WROOM-02-N8 (8 MB)**, directly programmable through native USB-C and serviceable later through browser OTA.
- Two battery channels:
  - Battery 0: **System battery — Duracell Advanced DA80, 80 Ah, 700 A EN, flooded lead-acid** (`GTIN 9005753086036`).
  - Battery 1: **Bow-thruster battery — 90 Ah**, exact model/chemistry still to be confirmed.
- System negative and ignition negative are the same `GND_SYS` node; only the bow battery measurement domain is isolated from the system domain.
- NMEA 2000 remains galvanically isolated from `GND_SYS`.
- Bidirectional current and battery-voltage measurement through one shunt per bank.
- **2x 500 A / 50 mV high-side shunts**. The system path covers expected Mercury SeaPro 150 starting current around 150-225 A; the bow path covers approximately 200 A with reserve.
- Approximate SOC using coulomb counting + off-time/self-discharge estimate + OCV plausibility + full-charge synchronization and an internal confidence state.
- NMEA battery data for Battery Instance 0/1, plus user-visible NMEA alert PGNs and Garmin alert acknowledgement.
- UTC synchronization from NMEA network time data (primarily PGN 129029) for logs and ignition-off duration.
- Automatic secured Wi-Fi diagnostics portal for **5 minutes after every boot**; Wi-Fi shuts down if nobody connects.
- Browser dashboard, configuration, diagnostics, CSV log access and OTA firmware update.
- External **32 MB SPI NOR** circular logger: 2-5 day normal history plus 50 Hz event capture.
- I2C FRAM + supercap hold-up for robust power-loss state/log shutdown.
- Host-side simulation using the same battery-domain code as the firmware.
- TDD/unit tests for normal cases, threshold behavior and edge cases.

## Electrical domains

The project keeps three grounds separate where isolation is actually required:

1. `GND_SYS` — system battery negative = ignition negative = ESP32 = system INA238.
2. `GND_BOW` — bow battery negative and isolated bow INA238 domain.
3. `GND_N2K` — NMEA 2000 NET-C / ISO1042 bus side.

`GND_BOW` is isolated from the ESP32 via ISO1640 plus an isolated DC/DC supply. `GND_N2K` is isolated from the ESP32 via ISO1042 CAN isolation.

## High-side topology

High-side measurement is retained mainly to keep the common engine/electronics ground untouched and to avoid missing current through an alternate engine-block negative path.

```text
BATTERY + -> main fuse -> high-side shunt -> common positive node -> loads / starter / chargers
```

Sense orientation:

- `IN+` = load/charger side
- `IN-` = battery side
- positive current = charging
- negative current = discharging

At 225 A a 500 A / 50 mV (100 micro-ohm) shunt drops about 22.5 mV and dissipates about 5.1 W. Shunts remain outside the sealed electronics enclosure and require secure insulating covers and individually protected sense leads.

## NMEA 2000 mapping

One physical NMEA node publishes two logical battery instances:

- Battery Instance `0` = System battery, 80 Ah
- Battery Instance `1` = Bow-thruster battery, 90 Ah

V1 uses standard battery/status and alert PGNs. The project is a DIY node and is **not NMEA-certified**.

## Diagnostics and logging

On every boot a secured `BatterySentinel-XXXX` Wi-Fi AP starts automatically.

- no client within 5 min -> Wi-Fi off;
- connected client -> portal remains available while connected;
- dashboard + raw diagnostics + settings + logs + OTA;
- normal logging at 1 Hz to 32 MB SPI NOR;
- 50 Hz acquisition and 10 s pre-trigger / 30 s post-trigger event recording.

See `docs/diagnostics-logging.md`.

## Repository layout

- `docs/` architecture, SOC model, diagnostics/logging, hardware and test strategy
- `hardware/` BOM, pin map and schematic design notes
- `include/` firmware configuration
- `lib/BatteryCore/` platform-independent battery model and alert logic
- `src/` ESP32-C3 firmware
- `sim/` deterministic battery scenario simulator
- `test/` native TDD/unit tests
- `.github/workflows/` CI for native tests and firmware compilation

## Build

```bash
pio test -e native
pio run -e esp32c3
```

Simulator:

```bash
cmake -S sim -B build/sim
cmake --build build/sim
./build/sim/batterysentinel_sim
./build/sim/batterysentinel_sim faults
```

## Status

**V1 engineering prototype.** Hardware, firmware and tests are being frozen before PCB routing. See `docs/hardware.md` and the open GitHub issues for remaining implementation/commissioning items.
