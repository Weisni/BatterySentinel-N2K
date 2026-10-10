> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](internal/README.md).

# Simulation strategy

## Current scope — 2026-10-10

The released Orion Bridge uses BLE charger data and has no INA238, external
FRAM/NOR, ignition sensor or complete-battery SOC measurement. The battery Lab
and Wokwi target below belong to the unbuilt measurement concept. Their simulated
SOC, logger and shutdown indicators are not implemented bridge capabilities.

For current Orion UI work, use [the portal preview](web-preview.md), which serves
the actual embedded UI with synthetic data. Native tests cover observation,
notification, UTC and alert-delivery cores; extracted HTTP and browser checks
exercise portal behavior. These do not emulate radio or the electrical bus.
See [the issue status record](internal/backlog-status-2026-10-10.md).

The historical concept required an interactive graphical simulation without
boat hardware. Its two internal layers remain available as described below.

## A. BatterySentinel Lab — implemented browser system simulator

`sim/web/` contains the first interactive simulator milestone. It is a dependency-free static HTML/CSS/JavaScript application and can be opened in any browser or hosted as a static website.

Implemented MVP controls and behavior:

- interactive system battery voltage and bidirectional current;
- ignition on/off;
- INA238 present/disconnected state;
- configurable chemistry and capacity;
- simulation speed 1x / 10x / 60x / 600x;
- scenarios for rest, Mercury starter pulse (~225 A), sustained load, charging, undervoltage, overvoltage, INA238 failure and a 24 h power-off interval;
- calculated SOC, consumed Ah, estimated runtime and confidence indication;
- alarm state machine visualization;
- virtual NMEA bus view with PGN 127508 and 127506 traffic;
- injection of PGN 129029 UTC and PGN 126984 alert acknowledgement;
- voltage/current/SOC timeline and event log.

The current browser MVP models battery rules in JavaScript. **It is not the
source of truth for BatteryCore**, and no production-core WASM binding exists.
`BatteryCore` / `BatteryProfiles` belong to the internal measurement target,
not the released Orion Bridge. [Issue #7](https://github.com/Weisni/BatterySentinel-N2K/issues/7)
now records an optional proposal to use the actual Orion observation/time/alert
cores in a browser harness. That proposal is not an implemented simulator or a
commitment to change the existing Lab. Native TDD remains authoritative for
the tested C++ cores.

Target UI:

```text
+------------------------------------------------------------------+
| BatterySentinel Lab                                               |
+----------------------+----------------------+----------------------+
| VIRTUAL PERIPHERALS  | DEVICE STATE         | NMEA BUS             |
| Voltage   [12.60 V]  | SOC          82 %    | TX 127508 ...        |
| Current   [-4.2 A]   | Confidence ESTIMATED | TX 127506 ...        |
| Ignition  [ON]       | Alerts       NONE    | RX 129029 ...        |
| INA238    [OK]       | Runtime      ...     | RX 126984 ACK        |
| Battery   [Flooded]  |                      |                      |
+----------------------+----------------------+----------------------+
| Voltage / Current / SOC timeline                                  |
+------------------------------------------------------------------+
| Scenario: [Starter] [Charge] [Sensor fail] [Power loss] ...       |
+------------------------------------------------------------------+
```

### Online hosting

`.github/workflows/simulator-pages.yml` runs JavaScript syntax checks only. The simulator remains project-internal and is opened locally. It is not published by the project workflow.

## B. Wokwi — implemented legacy setup, incomplete automation

Root `wokwi.toml` points to `.pio/build/esp32c3/firmware.bin` and its ELF.
`diagram.json` is already present for the internal 8 MB ESP32-C3-DevKitM-1
measurement target; it does not run the public `orion_dongle` target.

Existing virtual hardware and tooling:

- ESP32-C3-DevKitM-1 configured for the internal PlatformIO firmware;
- custom INA238 I2C model at address 0x40 with voltage/current/fault controls;
- tracked custom-chip WASM and a chip compile/circuit-lint CI workflow;
- ignition switch, status LED and logic analyzer on SDA/SCL/IGN.

Missing: scripted firmware scenarios, FRAM/NOR models and SPI/TWAI analyzer
wiring. The legacy firmware does not act on the ignition switch. Chip compilation
and lint passed in [the historical workflow run](https://github.com/Weisni/BatterySentinel-N2K/actions/runs/33204456947);
that does not establish complete firmware execution or shutdown behavior.

[Wokwi's support matrix](https://docs.wokwi.com/guides/esp32#simulation-features)
lists Bluetooth as unsupported and TWAI as partially implemented. An Orion
simulation would require synthetic BLE inputs/adapters, while real BLE/CAN
acceptance remains physical. Automated Wokwi cloud scenarios additionally need
the appropriate CLI authorization/token. [Issue #8](https://github.com/Weisni/BatterySentinel-N2K/issues/8)
tracks remaining internal automation; #6 is consolidated into it.

## Verification roles

The following table concerns the internal measurement concept, not complete
Orion Bridge acceptance. Entries distinguish present facilities from proposed ones.

| Test concern | Browser Lab | Wokwi | Real bench |
|---|---:|---:|---:|
| Interactive battery scenarios | Primary | Yes | Final |
| SOC / battery model | Visual MVP; TDD authoritative | Secondary | Final plausibility |
| Alarm state machine | Primary visual | Yes | Final |
| Time jumps / off-time | Synthetic | Firmware shutdown not integrated | Final |
| NMEA semantic PGN view | Primary | Partial TWAI | Final |
| ESP32-C3 boot / scheduling | No | Primary | Final |
| INA238 I2C transactions | Semantic | Primary | Final |
| Wi-Fi state machine | Logical | Primary | Final |
| SPI / FRAM drivers | Synthetic UI only | Models not implemented | Final |
| CAN electrical behavior | No | Partial | Primary |
| ISO1042 / signal integrity | No | No | Primary |

## First interactive simulation acceptance criteria

The current Browser Lab meets the minimum interactive milestone when:

1. battery voltage/current can be changed while the simulation runs;
2. a starter scenario produces an approximately 225 A discharge pulse and voltage sag;
3. low-voltage, overvoltage, overcurrent and sensor-fault conditions are visible;
4. ignition off/on can be simulated;
5. virtual NMEA traffic for battery data is shown;
6. UTC and alert acknowledgement can be injected from a virtual NMEA/Garmin peer;
7. history is visible on a live timeline.

## Important limitation

Neither Browser Lab nor Wokwi replaces the final physical NMEA 2000/CAN test. Final acceptance requires the actual ISO1042, 250 kbit/s CAN bus and a CAN/NMEA analyzer and/or Garmin chartplotter.
