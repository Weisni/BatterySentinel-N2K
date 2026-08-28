# Diagnostics, Logging, Time Sync and Power-Loss Strategy

## Startup diagnostics Wi-Fi

BatterySentinel starts a secured local Wi-Fi access point on every boot because the installed unit may be physically hard to reach.

Default behavior:

1. Boot device.
2. Start WPA2 access point `BatterySentinel-XXXX` where `XXXX` is derived from the device ID.
3. Start local HTTP service and mDNS name `batterysentinel.local`.
4. Keep the access point available for **5 minutes**.
5. If no station has associated during that window, stop Wi-Fi completely.
6. If a station connects during the window, keep diagnostics active while at least one station remains connected.
7. After the last station disconnects, wait 60 seconds and stop Wi-Fi unless another station reconnects.

The AP password is unique per device and printed on the internal enclosure label. Do not ship V1 with an open AP or a universal default password.

## Browser UI

The local browser UI contains:

### Dashboard

- System battery voltage, current, power and SOC.
- Bow battery voltage, current, power and SOC.
- SOC confidence/status (`SYNCED`, `ESTIMATED`, `WAITING_FOR_REST`, `UNKNOWN`).
- Current NMEA source state and most recent network UTC time.
- Active warnings and their age.

### Configuration

Per battery:

- Battery capacity in Ah.
- Shunt resistance / calibration factor.
- Low and critical SOC thresholds.
- Idle undervoltage threshold and delay.
- High-load undervoltage threshold and delay.
- Overvoltage threshold and delay.
- Overcurrent threshold and delay.
- Full-charge voltage, tail-current percentage and full-detect delay.
- OCV correction enable / weighting.
- Friendly battery name and NMEA battery instance.

Settings are range-checked before being committed. A factory-default configuration remains available in firmware.

### Diagnostics

- INA238 raw shunt register and calculated microvolts.
- INA238 raw bus-voltage register.
- I2C communication errors/recovery count.
- CAN/NMEA TX/RX counters and bus errors.
- Latest received UTC source and age.
- Firmware version, reset reason, uptime and supply state.
- External SPI NOR status and free log capacity.
- FRAM CRC/status and last clean/unclean shutdown flag.

### Logger

- Recent normal-history plot.
- Event list (starter, bow thruster, undervoltage, overcurrent, sensor fault, reset, power loss).
- View an event with high-rate pre/post-trigger data.
- CSV export.
- Delete log / reset ring buffer.

### Firmware update

- OTA firmware upload from the local browser.
- Verify image header, target, version and SHA-256 before selecting it for boot.
- Keep the previous application partition until the new image successfully boots and marks itself healthy.
- Firmware update is available only while the secured diagnostics AP is active.

For OTA margin use **ESP32-C3-WROOM-02-N8 (8 MB flash)** instead of H4/N4 in the production BOM.

## Logging architecture

Use one external **32 MB SPI NOR flash** as a circular logger. Recommended class: W25Q256-compatible 256-Mbit NOR.

### Long-term data

Normal recording rate: **1 sample/s**.

Use a compact fixed-size binary record rather than JSON. Target record size <= 24 bytes, for example:

- Unix UTC seconds / relative time: 4 bytes.
- System voltage: 2 bytes fixed-point.
- System current: 2 bytes fixed-point.
- System SOC: 1 byte.
- Bow voltage: 2 bytes.
- Bow current: 2 bytes.
- Bow SOC: 1 byte.
- Alert/status flags: 2 bytes.
- Record sequence / source flags / reserved.
- CRC16.

At 24 bytes/s this is approximately 2.07 MB/day, so five days use about 10.4 MB. A 32 MB device therefore leaves comfortable space for event logs and filesystem/ring overhead.

### Event capture

The acquisition loop runs at **50 Hz** (20 ms). Keep the latest 10 seconds of raw samples in a RAM circular pre-trigger buffer.

Trigger event capture on:

- starter current above configured starter-event threshold;
- bow-thruster current above configured threshold;
- low voltage;
- overvoltage;
- overcurrent;
- sensor fault;
- reset/reboot;
- power-loss interrupt.

On trigger, store:

- 10 seconds before event;
- event itself;
- 30 seconds after event;
- event reason and max/min statistics.

At a 24-byte combined record, a 40-second 50-Hz event is about 48 kB. This is small compared with the 32 MB logger.

The NOR flash uses a sequential circular sector scheme with sequence numbers and per-record/per-sector CRC. Do not rewrite a single metadata sector on every sample.

## FRAM state store

Add a small I2C FRAM on the **GND_SYS** side, e.g. 32 kB class.

FRAM stores small state/checkpoint data only, not the multi-day log:

- system SOC / consumed Ah;
- bow SOC / consumed Ah;
- last valid network UTC;
- last shutdown UTC;
- last clean-shutdown flag;
- configuration copy / version / CRC;
- log write pointer / sequence checkpoint;
- last event counters.

Checkpoint the dynamic SOC state approximately once per second. This makes the power-loss shutdown routine very short and avoids relying on frequent internal ESP flash writes.

## Network time

Garmin GPSMAP 7x3 supports PGN 129029 GNSS Position Data as transmit/receive traffic, while PGN 126992 System Time is listed as receive-only on the Garmin. BatterySentinel therefore listens primarily for a valid UTC date/time in **PGN 129029** from any NMEA source.

Behavior:

- Once a valid UTC sample is received, maintain software time from `millis()` between NMEA updates.
- Save current UTC in FRAM during clean power-down.
- At next boot, wait for current network UTC and calculate the off duration from the stored shutdown time.
- If no valid NMEA UTC becomes available, logs remain ordered by monotonic boot-relative time but the off duration is marked unknown.

No dedicated battery-backed RTC is required for V1.

## SOC behavior while ignition is off

The monitor is not powered continuously, so it cannot coulomb-count while ignition is off.

For the system battery, the exact supplied GTIN 9005753086036 resolves to Duracell Advanced DA80, 80 Ah / 700 A EN. The manufacturer datasheet specifies about **3 % self-discharge per month**, or roughly 0.1 %/day as an engineering estimate.

Since there are no permanent loads with ignition off:

1. Persist SOC and UTC at shutdown.
2. At next valid network time, apply only the very small self-discharge estimate based on off-time.
3. Do **not** assume there was no external charger.
4. If voltage/current indicates active charging, suspend OCV correction and let coulomb counting/full-charge synchronization take over.
5. If the battery is at rest, use a slow OCV plausibility correction.
6. If a previous external charge is suspected from a voltage/SOC mismatch, lower SOC confidence until either a true resting condition or a full-charge synchronization is observed.

The displayed SOC therefore remains an estimate, with an internal confidence state rather than pretending to be exact.

## Power-loss hold-up

Because BatterySentinel is powered from the switched ignition feed of the system battery, switching ignition off removes its input supply. Detect this before the logic rail collapses.

Recommended topology:

```text
IGN 12 V
   |
input protection
   |
AP63205 5 V
   +-------------------> D1 ---> V_HOLD ---> 3V3 regulator ---> ESP32 + FRAM
   |
   +-- RCHG 47R ---> 0.22 F / 5.5 V supercap
                       |
                       +-------> D2 ---> V_HOLD

IGN_RAW / protected input ---> divider/comparator ---> GPIO IGN_SENSE
```

D1 supplies the logic normally. RCHG limits supercap inrush. When 5 V disappears, D2 lets the supercap hold V_HOLD without discharging back into the buck/input circuit.

On `IGN_SENSE` falling edge:

1. stop accepting new OTA/config writes;
2. disable Wi-Fi immediately;
3. stop isolated bow power if hardware provides an enable;
4. finalize current event/log sector;
5. write latest state, UTC, clean-shutdown marker and CRC to FRAM;
6. flush only essential logger metadata;
7. enter low-consumption loop until power collapses.

With Wi-Fi off, the required shutdown should normally finish in far below one second. The 0.22 F hold-up target intentionally provides multiple seconds of margin rather than depending on a precise two-second value.
