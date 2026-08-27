# BatterySentinel N2K

Dual-battery monitor for a 12 V boat electrical system with NMEA 2000 output to a Garmin chartplotter.

## V1 goals

- One ESP32-C3-WROOM-02-H4, directly programmable on the final PCB through native USB-C.
- Two electrically isolated AGM battery channels:
  - Battery 0: **System battery, 70 Ah AGM**
  - Battery 1: **Bow-thruster battery, 90 Ah AGM**
- Bidirectional current and battery-voltage measurement through one shunt per bank.
- **2x identical 500 A / 50 mV high-side shunts**. This provides ample reserve for the ~200 A bow thruster and avoids a second shunt type for the system/starter path.
- Approximate SOC using coulomb counting + open-circuit-voltage correction + full-charge synchronization.
- NMEA 2000 transmission of battery data using Battery Instance 0 and 1 (PGN 127508 and 127506 in V1).
- Unit only needs to operate when ignition/NMEA 2000 are active; sleep-current optimization is not a V1 requirement.
- Host-side simulation using the same battery-domain code as the firmware.
- TDD/unit tests for normal cases, threshold behavior and edge cases.

## Electrical domains

The project intentionally keeps three grounds separate:

1. `GND_SYS` — system battery / ESP32 domain.
2. `GND_BOW` — bow-thruster battery measurement domain.
3. `GND_N2K` — NMEA 2000 NET-C domain.

`GND_BOW` is isolated from the ESP32 via ISO1640 (I2C) plus an isolated DC/DC supply. `GND_N2K` is isolated from the ESP32 via ISO1042 CAN isolation.

## Important shunt topology

V1 uses **high-side shunts** so the INA238 can measure both shunt current and actual battery bus voltage without joining the two battery negatives. Put each shunt after the battery-positive fuse and before the common load/charger node. The charger and every load that shall be counted must be connected to the load side of the shunt.

The intended orientation is:

`BAT+ -> fuse -> IN- / battery side of shunt -> IN+ / load+charger side -> distribution`

With this orientation the internal firmware convention is:

- positive current = charging the battery
- negative current = discharging the battery

A 500 A / 50 mV shunt is 100 micro-ohm. At 200 A it dissipates about 4 W. The exposed high-current positive shunts require mechanically secure, ventilated insulating covers.

## NMEA 2000 mapping

One physical NMEA 2000 node publishes two logical battery instances:

- Battery Instance `0` = System battery, 70 Ah
- Battery Instance `1` = Bow-thruster battery, 90 Ah

The product is a DIY NMEA 2000 node and is **not NMEA-certified**. V1 uses standard battery PGNs supported by the open-source NMEA2000 stack.

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
./build/sim/batterysentinel_sim faults
```

## Status

**V1 engineering prototype.** Hardware values, firmware interfaces and tests are being frozen before PCB routing. See `docs/hardware.md` for remaining commissioning/open items.
