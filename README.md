# BatterySentinel N2K

Battery monitor for a 12 V boat electrical system with NMEA 2000 output to a Garmin chartplotter.

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
- `test/` native TDD/unit tests
- `.github/workflows/` CI

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

**V1 engineering prototype.** The ESP32-C3 firmware now builds with a native TWAI backend and the native TDD/simulator pipeline is active. Logging storage, FRAM power-loss integration, NMEA alarms/time sync and final PCB/BOM are the next integration steps.
