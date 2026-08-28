# V1 Hardware Design

## Design target

- 12 V marine/boat environment.
- One PCB in a protected but potentially humid battery compartment.
- Two independent battery banks less than 1 m apart.
- System battery GTIN `9005753086036`: **Duracell Advanced DA80, 80 Ah (K20), 700 A EN**, flooded/maintenance-free lead-acid. The earlier 70 Ah assumption was incorrect for this GTIN.
- Mercury SeaPro 150 starter fed from the system battery; expected real starting current approximately **150-225 A**.
- Bow battery: 90 Ah, separately charged; bow thruster about 1.6 kW / max operating current around 200 A.
- Two 500 A / 50 mV high-side shunts for V1. This gives one spare type and ample reserve for both banks.
- No local buzzer.
- Unit is powered from the switched ignition feed of the system battery. `GND_SYS` and ignition negative are identical.
- NMEA 2000 interface remains galvanically isolated.
- Only the bow measurement domain needs battery-domain isolation from `GND_SYS`.
- Direct ESP32-C3 native USB programming plus browser OTA.
- Automatic secured diagnostics Wi-Fi for five minutes after each boot.
- 2-5 day local data logging plus high-rate event capture.
- Power-loss detection and hold-up energy for clean state/log shutdown.

## Why high-side measurement remains preferred

High-side is not inherently more accurate than low-side. The advantage here is system integration.

A low-side system shunt would require **every** negative path of the Mercury starter, alternator, chargers and boat distribution to pass through the shunt. Any engine-block or auxiliary negative connection directly to battery negative would bypass the measurement. It would also intentionally insert the shunt into the boat ground reference.

With high-side measurement:

```text
SYSTEM BATTERY - = GND_SYS = ignition - = engine / electronics ground

SYSTEM BATTERY + -> main fuse -> 500 A / 50 mV shunt -> common positive node
                                                      |- starter / Mercury
                                                      |- alternator return path
                                                      |- boat loads
                                                      |- external charger
```

The ground system remains untouched and all counted charge/discharge paths are forced through one positive shunt. The tradeoff is that shunt and Kelvin terminals are live battery-positive nodes and require covers and individually fused sense wires.

At 225 A the 500 A / 50 mV shunt drops about 22.5 mV and dissipates about 5.1 W. A 700 A CCA rating does **not** mean the starter normally draws 700 A; it is a battery capability/test rating. Nevertheless the selected shunt's short-time overload curve must be checked before PCB release.

## Recommended enclosure

Use a ready-made polycarbonate IP66 enclosure around 120 x 80 x 55 mm rather than printing the electronics enclosure.

Target PCB outline: approximately **90 x 68 mm**, subject to real enclosure bosses and connector clearances.

Protection strategy:

1. IP66 enclosure, cable glands and sealed NMEA M12 connector.
2. Conformal coating after commissioning.
3. Do not fully pot V1 until USB, Wi-Fi, OTA, calibration and CAN behavior are proven.
4. Shunts stay outside the enclosure because of heat and heavy-cable mechanics.
5. Print only ventilated shunt touch-covers in ASA. Keep polymer away from the resistive element.

## Connector / cable concept

- `J1 IGN`: switched +12 V and GND_SYS, 1 A fuse near source.
- `J2 SYS_SENSE`: twisted Kelvin pair to system shunt plus optional fused VBUS pickup if routed separately.
- `J3 BOW_SENSE`: twisted Kelvin pair + BOW battery negative reference.
- `J4 NMEA`: 5-pin M12 A-coded / NMEA Micro-C compatible panel connector.
- `J5 USB-C`: internal, accessible after opening the IP66 lid; primarily recovery/development because normal service uses OTA.

### Critical sense-wire protection

Every small conductor attached to the positive high-current node must be protected for its own wire gauge. The main 500 A battery protection cannot protect a 0.25 mm2 sense wire.

Install **100 mA inline protection close to each positive sense pickup**. Do not rely on PCB traces to limit fault energy.

## Power domains

```text
SYSTEM / IGNITION DOMAIN (GND_SYS)

IGN +12 V --- external 1 A fuse --- reverse-polarity / surge protection --- AP63205 ---> 5V_SYS
                                                                                       |
                                                                                       +--> hold-up network --> 3V3_SYS
                                                                                       |                     |- ESP32-C3
                                                                                       |                     |- INA238 SYS
                                                                                       |                     |- FRAM
                                                                                       |
                                                                                       +--> RFMM-0505S --> 5V_BOW_ISO --> AP2112K --> 3V3_BOW
                                                                                                                               |- INA238 BOW
                                                                                                                               |- ISO1640 side B

USB VBUS is ORed into the service power path without back-feeding IGN.
```

`GND_SYS` and ignition negative are the same node. There is no extra isolation around the system battery sensor.

```text
NMEA DOMAIN (GND_N2K)

NET-S +12 V --- protection --- AP63205 ---> 5V_N2K ---> ISO1042 VCC2
NET-C -----------------------------------------------> ISO1042 GND2
3V3_SYS --------------------------------------------> ISO1042 VCC1
GND_SYS --------------------------------------------> ISO1042 GND1
```

The NMEA side is powered from the backbone, preserving the ISO1042 barrier without a separate isolated NMEA converter.

## Power-loss hold-up

Because the monitor is powered after the ignition switch, an ignition-off event removes its source. The board therefore separates normal 5 V from the hold-up rail.

```text
5V_SYS ---------------- D1 --------------------> V_HOLD ---> 3V3_SYS regulator
   |
   +---- 47R ----> 0.22 F / 5.5 V supercap
                         |
                         +---- D2 -------------> V_HOLD

protected IGN_RAW ---> divider/comparator ---> GPIO21 IGN_SENSE
```

- D1 powers the load normally.
- The 47 Ohm resistor limits supercap charging current.
- D2 lets the charged supercap power `V_HOLD` when `5V_SYS` collapses while preventing discharge back into the input path.
- Firmware disables Wi-Fi and unnecessary loads immediately on power loss.
- Target is **multiple seconds of margin**, even though the actual FRAM/log shutdown should take far less than one second.

Exact D1/D2, supercap ESR/leakage and regulator dropout are frozen only after a measured shutdown-current test.

## ESP32-C3 module

Use **ESP32-C3-WROOM-02-N8 (8 MB flash)** for V1 rather than H4/N4. The 8 MB variant gives comfortable A/B OTA partition space while the external NOR remains dedicated to logging.

### Pin allocation

| ESP32-C3 pin | V1 function |
|---|---|
| GPIO0 | logger SPI SCK |
| GPIO1 | logger SPI MOSI |
| GPIO3 | logger SPI MISO |
| GPIO4 | I2C SDA |
| GPIO5 | I2C SCL |
| GPIO6 | TWAI / CAN TX |
| GPIO7 | TWAI / CAN RX |
| GPIO10 | status LED |
| GPIO20 | logger SPI CS |
| GPIO21 | ignition / power-loss sense |
| GPIO18 | native USB D- |
| GPIO19 | native USB D+ |
| GPIO9 | BOOT strap / service button |
| EN | reset / enable |

Avoid loading ESP32-C3 boot-strapping pins GPIO2/8/9 with the logger or other uncontrolled startup circuitry.

### USB-C programming

- USB2-only USB-C receptacle.
- CC1/CC2 each 5.1 kOhm to GND_SYS.
- 22 Ohm series resistors in D+/D- close to ESP32-C3.
- Low-capacitance USB ESD suppression.
- EN pull-up/reset network per Espressif hardware guidance.
- GPIO9 BOOT pushbutton remains available internally.

## Diagnostics Wi-Fi / OTA

On every normal boot:

1. start secured WPA2 AP `BatterySentinel-XXXX`;
2. expose browser UI and OTA for 5 minutes;
3. if no station connects, turn Wi-Fi off completely at 5 minutes;
4. if a station connects, keep the portal alive while connected and shut it down after a short disconnect grace period.

The password is unique per device and printed inside the enclosure. OTA uses A/B firmware partitions and rollback: the old application is not discarded until the new image successfully boots and marks itself healthy.

See `docs/diagnostics-logging.md`.

## System battery INA238

Power: 3V3_SYS / GND_SYS. Address `0x40`.

```text
SYSTEM shunt LOAD side ---- 10R ---- INA238 IN+
                                  |
                                100 nF differential
                                  |
SYSTEM shunt BAT side  ---- 10R ---- INA238 IN-

INA238 VBUS ---------------------- load/common positive side
INA238 GND ----------------------- GND_SYS
INA238 VS ------------------------ 3V3_SYS
```

Use `ADCRANGE=0`: +/-163.84 mV, 5 uV/LSB. With the 100 uOhm shunt this is 50 mA/LSB and more than enough headroom for the expected 150-225 A starter event.

Acquisition runs at 50 Hz so starter current and voltage sag are captured rather than averaged away by a 100 ms loop.

## Bow battery INA238

Power: 3V3_BOW / GND_BOW. Address `0x41`.

Analog filter is the same 10 Ohm + 100 nF differential network.

Use `ADCRANGE=1`: +/-40.96 mV, 1.25 uV/LSB. With the same 100 uOhm / 500 A shunt this gives about **12.5 mA/LSB** and an electrical span of about +/-409.6 A, comfortably above the 200 A operating current.

`GND_BOW` connects to bow battery negative as the measurement reference and must not be joined to `GND_SYS` elsewhere.

## ISO1640 isolated I2C

- VCC1 = 3V3_SYS / GND1 = GND_SYS.
- VCC2 = 3V3_BOW / GND2 = GND_BOW.
- 100 nF decoupling on both sides.
- 4.7 kOhm SDA/SCL pull-ups on both sides.
- Start at 100 kHz I2C.
- Physical isolation slot and no copper crossing barrier.

## ISO1042 NMEA 2000 interface

- VCC1 = 3V3_SYS / GND1 = GND_SYS.
- VCC2 = 5V_N2K / GND2 = GND_N2K / NET-C.
- TXD = GPIO6, RXD = GPIO7.
- CAN-rated ESD TVS at connector.
- Optional common-mode choke footprint.
- **No 120 Ohm termination** on the node.

### NMEA Micro-C / M12 pinout

| Pin | Signal |
|---:|---|
| 1 | Shield / drain |
| 2 | NET-S +12 V |
| 3 | NET-C 0 V |
| 4 | NET-H / CAN-H |
| 5 | NET-L / CAN-L |

Shield is not tied directly to GND_SYS in the plastic V1 enclosure.

## Local nonvolatile storage

### FRAM

Add a small I2C FRAM on the system side for frequently updated state:

- both SOC values / consumed Ah;
- configuration + CRC/version;
- last valid network UTC and shutdown UTC;
- clean-shutdown marker;
- ring-log write pointer/checkpoint.

Dynamic state may be checkpointed around once per second without internal ESP flash wear.

### 32 MB SPI NOR

Add 256-Mbit / 32 MB external SPI NOR for the logger.

- Normal history: 1 combined record/s.
- Target record <=24 bytes -> about 2.07 MB/day.
- Five days -> about 10.4 MB.
- Remaining capacity is used for sector overhead and high-rate event captures.
- Event capture: 50 Hz, 10 s pre-trigger + 30 s post-trigger.

Use a circular sequential sector format with sequence counters and CRC rather than repeatedly rewriting one metadata sector.

## PCB layout zoning

```text
+-----------------------------------------------------------------------+
| USB-C      ESP32-C3-N8 antenna keepout             NMEA M12            |
|                +--------------------+                    |             |
| SYS power ---> | ESP32-C3-WROOM-02  | ---> ISO1042 || CAN ESD          |
| hold-up / cap  +--------------------+              ||                   |
| FRAM + NOR       | I2C       | SPI                  || isolation        |
| INA238 SYS ------+           |                                          |
|                              +---- external NOR                          |
|                                                                           |
| SYS/BOW barrier: ISO1640 |||| RFMM-0505S                                  |
| BOW Kelvin ---> INA238 BOW ||||                                           |
+-----------------------------------------------------------------------+
```

Rules:

- No copper under ESP32 antenna.
- Kelvin traces as close matched pairs, away from SW nodes, RFMM transformer and CAN.
- No copper across ISO1640, ISO1042 or isolated-power barriers.
- INA238 + filter parts directly at sensor terminals.
- TVS parts at connectors.
- Hold-up capacitor/current loops kept away from INA sense routing.
- USB/NMEA ESD return paths kept out of measurement ground paths.

## Remaining hardware edge cases before PCB release

1. Verify the actual installed system battery label matches GTIN `9005753086036` (DA80 / 80 Ah / 700 A EN). If the physical battery is different, firmware capacity and lead-acid model must follow the label, not the GTIN assumption.
2. Identify the **exact 90 Ah bow battery type/model/chemistry**. SOC OCV and full-charge parameters must not blindly reuse the system flooded-battery values if the bow bank is AGM.
3. Confirm the selected 500 A shunt's short-time overload specification for starter service; expected 150-225 A is comfortable electrically, but mechanical/data-sheet rating still matters.
4. Ensure starter/alternator/shore charger positive connections are all on the load/common side of the system shunt.
5. Ensure the independent bow charger positive connection is on the load/charger side of the bow shunt.
6. External charging while ignition is off cannot be coulomb-counted. Firmware must treat SOC confidence appropriately and resynchronize using resting voltage or full-charge criteria after power returns.
7. Validate 0.22 F hold-up time with actual Wi-Fi-off shutdown current over temperature and supercap tolerance.
8. Validate automatic Wi-Fi shutdown/restart and OTA rollback before sealing the enclosure.
9. Validate log retention and NOR wear by accelerated ring-buffer testing.
10. Conformal coat only after all RF, CAN, USB, calibration and thermal validation is complete.
