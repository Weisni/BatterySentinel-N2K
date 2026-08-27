# V1 Test Plan

The V1 strategy uses four layers. A hardware fault must not be the first place where SOC/alert logic is tested.

## Layer 1 — Pure unit tests

Run on the host with PlatformIO `native` and Unity.

Current coverage includes:

- one-hour discharge integration
- charging efficiency
- invalid/NaN sensor data
- scheduler/data gap rejection
- startup OCV initialization
- charger/surface-charge voltage not treated as OCV
- full-charge tail-current synchronization
- normal 180 A bow-thruster sag without false alarm
- delayed >250 A bow overcurrent
- transient idle undervoltage rejection
- sustained undervoltage + recovery hysteresis
- low/critical SOC thresholds
- OCV endpoint clamping
- INA238 wide/narrow range scaling
- positive/negative 200 A current conversion
- VBUS ADC scaling

Command:

```bash
pio test -e native
```

## Layer 2 — Deterministic desktop simulation

The simulator links the exact same `BatteryCore.cpp` as the ESP32 firmware.

Normal scenario:

```bash
cmake -S sim -B build/sim
cmake --build build/sim
./build/sim/batterysentinel_sim
```

Fault scenario:

```bash
./build/sim/batterysentinel_sim faults
```

### Normal scenario

System:

1. rest/start
2. normal electronics discharge
3. charger bulk/absorption
4. tail current and SOC=100 % synchronization

Bow:

1. rested battery
2. idle
3. 180 A thruster pulse with voltage sag
4. voltage recovery
5. current-limited charging
6. tail current and SOC=100 % synchronization

Expected: no overcurrent or low-voltage false alarm from the normal thruster pulse.

### Fault scenario

- system overvoltage >15 V long enough to trip
- recovery below hysteresis threshold
- INA/sensor disconnected
- sensor recovered
- bow 270 A overcurrent long enough to trip
- bow deep voltage sag below loaded threshold

The simulator prints the resulting alert flags and SOC transitions so a scenario can be reviewed without hardware.

## Layer 3 — Hardware-in-the-loop bench test

### Required bench equipment

- isolated/bench 12–15 V supply for system domain
- second isolated supply for bow battery domain where useful
- USB-C host
- oscilloscope
- DMM
- NMEA 2000 powered test backbone or CAN analyzer
- programmable electronic load / current source for low-current tests
- shunt millivolt injection source or precision millivolt calibrator for high-current-equivalent tests

Do **not** start validation by drawing hundreds of amps. Simulate shunt voltage first.

### INA238 calibration tests

For each channel inject differential shunt voltages corresponding to:

| Shunt voltage | 500A/50mV equivalent |
|---:|---:|
| -25 mV | -250 A |
| -20 mV | -200 A |
| -5 mV | -50 A |
| 0 mV | 0 A |
| +5 mV | +50 A |
| +20 mV | +200 A |
| +25 mV | +250 A |

Verify:

- sign convention
- current scaling
- zero offset
- channel isolation
- no cross-channel corruption when one sensor domain is unpowered

Bow narrow-range saturation is expected near ±40.96 mV (~±409.6 A with 100 micro-ohm shunt). System wide range should not saturate at that point.

### Power sequencing

Test all combinations:

1. USB only — ESP/system logic boots; bow domain may be absent; no crash.
2. ignition only, NMEA off — sensors work; NMEA calls do not block.
3. ignition + NMEA — full operation.
4. NMEA on, ignition off — main node remains off and must not parasitically power through ISO1042.
5. bow isolated converter disconnected — system channel continues and sensor fault is reported only for bow.
6. system INA disconnected — bow channel and NMEA stack continue.

### Isolation tests

With all power off, verify high DC resistance / no continuity between:

- GND_SYS and GND_BOW
- GND_SYS and GND_N2K
- GND_BOW and GND_N2K

Then power each domain and verify no unintended ground equalization current.

## Layer 4 — Boat commissioning

### Static tests

- compare both battery voltages to a calibrated DMM
- verify 0 A offset after rest
- verify charger current direction is positive
- verify load current direction is negative
- verify Battery Instance 0 and 1 appear separately on Garmin

### System battery dynamic test

Measure actual maximum current that passes through the system shunt during:

- engine start if starter is on this bank
- largest auxiliary load
- highest expected charge current

If the observed peak approaches the selected shunt's mechanical overload limit, reroute the starter path or change shunt rating before permanent use.

### Bow-thruster dynamic test

Record at least:

- rested voltage
- minimum voltage during 1 s, 3 s and 8 s thruster operation
- peak current
- current after release
- recovery voltage after 10 s and 60 s

Use these measurements to tune `lowVoltageLoadedV`, loaded delay and overcurrent threshold. Do not tune alarms from generic AGM tables alone.

### Charger test

Because the bow bank has its own current-limited charger:

- confirm charge current is positive
- log the current-limit phase
- log transition to absorption/high voltage
- verify SOC=100 % sync only when current has tapered below ~1.8 A for the configured time

For the 70 Ah system battery the default C/50 tail threshold is ~1.4 A.

## Regression rule

Every field bug that can be reproduced without physical hardware must first become a failing native test or simulator scenario, then be fixed. This keeps the project TDD-oriented instead of accumulating one-off firmware conditionals.

## Release gate for V1 PCB

Do not call the design 'V1 hardware frozen' until:

- GitHub CI is green
- direct USB programming is verified on a prototype/dev arrangement
- INA238 sign/scaling is verified with injected millivolts
- NMEA Battery Instance 0/1 is visible on Garmin or a validated NMEA analyzer
- starter-path edge case is resolved
- chosen shunts' overload/mechanical mounting is confirmed
- enclosure cable-entry plan fits the real box
