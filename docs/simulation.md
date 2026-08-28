# Simulation strategy

## V1 requirement

BatterySentinel N2K must be testable without physical boat hardware through at least one interactive graphical simulation environment.

The simulation is split into two complementary layers.

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

The current browser MVP intentionally models the production rules semantically in JavaScript so it is immediately usable without a build chain. **It is not yet the source of truth for BatteryCore.** The next simulator revision should compile the platform-independent production `BatteryCore` / `BatteryProfiles` code to WebAssembly and replace duplicated algorithm code. Native TDD remains authoritative until that migration is complete.

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

`.github/workflows/simulator-pages.yml` deploys `sim/web/` through GitHub Pages. GitHub Pages must be enabled for the repository with **GitHub Actions** as the publishing source. Because the main repository is private, the account/plan must support Pages from private repositories. Otherwise the same static simulator can be published from a separate public simulator repository without exposing the main firmware repository.

## B. Wokwi — planned firmware/peripheral simulator

Wokwi is the hardware-oriented second simulation target for the real ESP32-C3 firmware.

Target virtual hardware:

- ESP32-C3-DevKitM-1 executing the production PlatformIO firmware;
- custom INA238 I2C model at address 0x40 with interactive controls for VBUS, shunt current and sensor fault;
- I2C FRAM model;
- SPI NOR/logger model where useful;
- ignition/power-loss input;
- status LED and logic analyzer.

Wokwi supports the ESP32-C3 and custom I2C/SPI WebAssembly chips, making the INA238/FRAM/NOR portions practical to model. ESP32 TWAI/CAN is currently documented as partially implemented, so Wokwi is useful for firmware/peripheral integration but is not the final NMEA physical-layer acceptance test.

Wokwi CI can later run automated firmware-in-the-loop scenarios, but it requires a `WOKWI_CLI_TOKEN` repository secret. GitHub Issue #6 tracks this work.

## Verification roles

| Test concern | Browser Lab | Wokwi | Real bench |
|---|---:|---:|---:|
| Interactive battery scenarios | Primary | Yes | Final |
| SOC / battery model | Visual MVP; TDD authoritative | Secondary | Final plausibility |
| Alarm state machine | Primary visual | Yes | Final |
| Time jumps / off-time | Primary | Limited | Final |
| NMEA semantic PGN view | Primary | Partial TWAI | Final |
| ESP32-C3 boot / scheduling | No | Primary | Final |
| INA238 I2C transactions | Semantic | Primary | Final |
| Wi-Fi state machine | Logical | Primary | Final |
| SPI / FRAM drivers | Logical | Primary | Final |
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
