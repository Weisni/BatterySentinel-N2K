# Simulation strategy

## V1 requirement

BatterySentinel N2K must be testable without physical boat hardware through at least one interactive graphical simulation environment.

The V1 simulation is split into two complementary layers:

### A. BatterySentinel Lab — browser system simulator

Primary deterministic system-level simulator.

Goals:
- Runs in a browser with no boat hardware.
- Reuses the production `BatteryCore` / `BatteryProfiles` logic through WebAssembly rather than duplicating SOC/alarm algorithms in JavaScript.
- Interactive controls for voltage, current, ignition, charger state, sensor availability, battery type/capacity and time jumps.
- Preset scenarios: rest, charge, crank, sustained load, brownout, overvoltage, sensor disconnect, external charge while powered off, power-loss/restart.
- Shows calculated SOC, confidence state, alarms, consumed Ah, remaining time, state transitions and simulated NMEA traffic.
- Virtual NMEA console decodes the PGNs BatterySentinel would publish and allows injection of relevant inbound messages such as time and alert acknowledgements.
- Timeline chart and event log.
- Scenario definitions must be reusable by automated tests where practical.

Target UI:

```text
+------------------------------------------------------------------+
| BatterySentinel Lab                                               |
+----------------------+----------------------+----------------------+
| INPUTS               | DEVICE STATE         | NMEA BUS             |
| Voltage   [12.60 V]  | SOC          82 %    | TX 127508 ...        |
| Current   [-4.2 A]   | Confidence   SYNCED  | TX 127506 ...        |
| Ignition  [ON]       | Alerts       NONE    | RX 129029 ...        |
| Charger   [OFF]      | INA238       OK      | Alert ACK ...        |
| Sensor    [OK]       | Wi-Fi        ACTIVE  |                      |
| Battery   [Flooded]  | Logger       ACTIVE  |                      |
+----------------------+----------------------+----------------------+
| Voltage / Current / SOC timeline                                  |
+------------------------------------------------------------------+
| Scenario: [Starter 225 A] [Charge] [Sensor fail] [Power loss] ... |
+------------------------------------------------------------------+
```

### B. Wokwi — firmware/peripheral simulator

Wokwi is the hardware-oriented simulation target for the real ESP32-C3 firmware.

Target virtual hardware:
- ESP32-C3-DevKitM-1 executing the production PlatformIO firmware.
- Custom INA238 I2C model with interactive voltage/current/fault controls.
- I2C FRAM model.
- SPI NOR/logger model where useful.
- ignition/power-loss input.
- status LED and logic analyzer.

Wokwi currently supports ESP32-C3 plus I2C, SPI, Wi-Fi and custom WebAssembly chips. TWAI/CAN support is partial, so Wokwi CAN behavior is useful for development but is not the final NMEA physical-layer acceptance test.

Wokwi also does not support multiple microcontrollers wired together in one project. Therefore NMEA peer behavior is validated primarily by the Browser Lab virtual NMEA bus and later by a real CAN/NMEA bench setup.

## Verification roles

| Test concern | Browser Lab | Wokwi | Real bench |
|---|---:|---:|---:|
| SOC / battery model | Primary | Secondary | Final plausibility |
| Alarm state machine | Primary | Yes | Final |
| Time jumps / off-time | Primary | Limited | Final |
| NMEA PGN encoding/decoding | Primary | Partial TWAI | Final |
| ESP32-C3 boot / scheduling | No | Primary | Final |
| INA238 I2C transactions | Virtual model | Primary | Final |
| Wi-Fi state machine | Logical | Primary | Final |
| SPI / FRAM drivers | Logical | Primary | Final |
| CAN electrical behavior | No | Partial | Primary |
| ISO1042 / signal integrity | No | No | Primary |

## Acceptance criteria for first interactive simulation milestone

1. Browser page can change system battery voltage/current while simulation is running.
2. Production BatteryCore code determines SOC and alarms.
3. Starter preset produces a 150-225 A discharge pulse and voltage sag without an unintended SOC reset.
4. Low-voltage, overvoltage, overcurrent and sensor-fault cases are visible in the UI.
5. Power-off/restart can advance simulated UTC and exercise off-time SOC handling.
6. NMEA console shows decoded Battery Status / DC Detailed Status values and relevant alarms.
7. Scenarios can be started manually and at least core scenarios are exercised automatically in CI.
8. Wokwi target runs the production ESP32-C3 image against a controllable INA238 model.

## Important limitation

Neither browser simulation nor Wokwi replaces the final physical NMEA 2000/CAN test. Wokwi documents TWAI as partially implemented, and its projects currently cannot wire multiple simulated MCUs together. Final verification therefore requires the actual ISO1042, 250 kbit/s CAN bus and either a CAN/NMEA analyzer or Garmin display.
