# BatterySentinel N2K

Dual-battery monitor for a 12 V boat electrical system with NMEA 2000 output to a Garmin chartplotter.

## V1 goals

- One ESP32-C3-WROOM-02-H4, directly programmable on the final PCB.
- Two electrically isolated AGM battery channels:
  - Battery 0: **System battery, 70 Ah AGM**
  - Battery 1: **Bow-thruster battery, 90 Ah AGM**
- Bidirectional current and battery-voltage measurement through one shunt per bank.
- Design target: bow-thruster current up to 200 A continuous/operating pulse with reserve; default shunt design 300 A / 50 mV.
- Approximate SOC using coulomb counting + open-circuit-voltage correction + full-charge synchronization.
- NMEA 2000 transmission of battery data (PGN 127508 and 127506 planned for V1).
- Unit only needs to operate when ignition/NMEA 2000 are active; sleep-current optimization is not a V1 requirement.
- Host-side simulation using the same battery-domain code as the firmware.
- TDD/unit tests for normal cases, threshold behavior and edge cases.

## Electrical domains

The project intentionally keeps three grounds separate:

1. `GND_SYS` — system battery / ESP32 domain.
2. `GND_BOW` — bow-thruster battery measurement domain.
3. `GND_N2K` — NMEA 2000 NET-C domain.

`GND_BOW` is isolated from the ESP32 via ISO1640 (I2C) and an isolated 5 V DC/DC converter. `GND_N2K` is isolated from the ESP32 via ISO1042 CAN isolation.

## Important shunt topology

V1 uses **high-side shunts** so the INA238 can measure both shunt current and actual battery bus voltage. Put each shunt after the battery-positive fuse and before the common load/charger node. The charger and every load that shall be counted must be connected to the load side of the shunt.

The intended orientation is:

`BAT+ -> fuse -> IN- / battery side of shunt -> IN+ / load+charger side -> distribution`

With this orientation the internal firmware convention is:

- positive current = charging the battery
- negative current = discharging the battery

The exposed high-current positive shunts require a mechanically secure insulating cover.

## Repository layout

- `docs/` architecture, SOC model, hardware and test strategy
- `hardware/` BOM, pin map and schematic design notes
- `include/` firmware configuration
- `lib/BatteryCore/` platform-independent battery model and alert logic
- `src/` ESP32-C3 firmware
- `sim/` deterministic battery scenario simulator
- `test/` native TDD/unit tests
- `.github/workflows/` CI for native tests and firmware compilation

## Build

This project uses PlatformIO.

```bash
pio test -e native
pio run -e esp32c3
```

The simulator can additionally be built with CMake:

```bash
cmake -S sim -B build/sim
cmake --build build/sim
./build/sim/batterysentinel_sim
```

## Status

**V1 scaffold**. Hardware values and firmware interfaces are intentionally documented before PCB routing. Do not manufacture the PCB until the open hardware questions in `docs/hardware.md` are closed.
