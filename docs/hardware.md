# V1 Hardware Design

## Design target

- 12 V marine/boat environment.
- One PCB in a protected but potentially humid battery compartment.
- Two electrically independent AGM banks less than 1 m apart.
- System AGM: 70 Ah.
- Bow-thruster AGM: 90 Ah; bow thruster approximately 1.6 kW / max operating current around 200 A.
- Two identical 500 A / 50 mV high-side shunts.
- No local buzzer.
- Unit is powered from ignition and does not need to monitor when ignition is off.
- NMEA 2000 interface is galvanically isolated.
- Bow measurement domain is galvanically isolated from the system battery domain.
- Direct ESP32-C3 native USB programming on the final PCB.

## Recommended enclosure

Use a ready-made polycarbonate IP66 enclosure around 120 x 80 x 55 mm rather than printing the electronics enclosure. For a one-off family build it is cheaper, more repeatable and more moisture-resistant.

Target PCB outline: approximately **90 x 68 mm**, subject to the selected enclosure's real internal bosses and clearances.

Protection strategy:

1. IP66 enclosure and cable glands / sealed NMEA M12 connector.
2. Conformal coating after successful commissioning.
3. Do not fully pot V1 until USB programming, sensor calibration and CAN behavior have been proven.
4. Shunts remain outside the enclosure because of heat and because the high-current studs need robust mechanical mounting.
5. Print only ventilated shunt touch-covers in ASA on the Bambu P2S. Keep the ASA away from the resistive element and allow convection.

## Connector / cable concept

- `J1 IGN`: 2-wire ignition supply + GND_SYS, 0.5 A fuse near source.
- `J2 SYS_SENSE`: 2-wire twisted Kelvin pair to system shunt.
- `J3 BOW_SENSE`: 3-wire cable: twisted Kelvin pair + BOW battery negative reference.
- `J4 NMEA`: 5-pin M12 A-coded / NMEA Micro-C compatible panel connector.
- `J5 USB-C`: internal, accessible after opening the IP66 lid. This avoids compromising enclosure ingress protection.

### Critical sense-wire protection

Every Kelvin wire connected to a battery-positive shunt terminal is a small wire attached to a source capable of hundreds of amps. The main 300/500 A battery fuse cannot protect a 0.25 mm² sense wire.

**Install a 100–250 mA inline fuse in each positive Kelvin lead close to each shunt terminal.**

That means four small sense-wire fuses total for the two high-side shunts. This is a safety requirement, not an optional measurement feature.

## Power tree

```text
SYSTEM / IGNITION DOMAIN (GND_SYS)

IGN +12 V --- external 0.5 A fuse --- SS34 reverse-polarity diode ---+--- AP63203 --- 3V3_SYS
                                                                    |
USB VBUS ------------------------- SS14 -----------------------------+
                                                                    |
                                                                    +--- TDN 1-2410WI --- 3V3_BOW

TVS SMBJ18A from protected IGN input to GND_SYS.

USB-only operation powers ESP32 + system-domain logic through AP63203.
The TDN 1-2410WI requires >=9 V, so the isolated bow domain is intentionally not powered from USB-only bench power. Provide 3V3_BOW/GND_BOW test pads for isolated-side bench testing.
```

Use **TDN 1-2410WI (9–36 V input, 3.3 V isolated output)** rather than the 4.5–18 V variant. The wider input range gives much better headroom in a 12 V charging environment.

```text
NMEA DOMAIN (GND_N2K)

NET-S +12 V --- AP63205 --- 5V_N2K --- ISO1042 VCC2
NET-C ------------------------------- ISO1042 GND2
3V3_SYS ----------------------------- ISO1042 VCC1
GND_SYS ----------------------------- ISO1042 GND1
```

The NMEA side is powered from the NMEA backbone itself; no isolated converter is required for that barrier.

## AP63203 / AP63205 external components

Both fixed-output 1.1 MHz buck converters use the manufacturer's simple external network as the layout starting point:

- L = 4.7 uH, shielded, current rating >=2.5 A.
- BST capacitor = 100 nF ceramic.
- Input = 10 uF / 50 V X7R + 100 nF close to VIN/GND.
- Output = 2 x 22 uF ceramic; use >=10 V rating for 3.3 V and >=16 V for 5 V.
- Keep VIN-SW-L-COUT high-current loop very short.
- Keep both switching regulators away from INA238 Kelvin input routing.

The exact inductor/ceramic package is frozen in `hardware/BOM.csv` only after checking availability at PCB ordering time.

## ESP32-C3-WROOM-02-H4

### Pin allocation

| ESP32-C3 pin | V1 function |
|---|---|
| GPIO4 | I2C SDA |
| GPIO5 | I2C SCL |
| GPIO6 | TWAI / CAN TX to ISO1042 |
| GPIO7 | TWAI / CAN RX from ISO1042 |
| GPIO10 | status LED |
| GPIO18 | native USB D- |
| GPIO19 | native USB D+ |
| GPIO9 | BOOT strap / button |
| EN | reset / enable |

### USB-C programming

- USB-C USB2-only receptacle.
- CC1 and CC2 each 5.1 kOhm to GND_SYS.
- 22 Ohm series resistors in D+ and D- close to ESP32-C3.
- Low-capacitance USB ESD suppressor at connector.
- USB VBUS is diode-ORed into the protected regulator input. It does not directly feed the 3.3 V rail and cannot back-feed the ignition wire through the ignition Schottky diode.
- EN: 10 kOhm pull-up to 3V3_SYS, 1 uF to GND_SYS, reset pushbutton to GND.
- GPIO9: 10 kOhm pull-up and BOOT pushbutton to GND.

## System battery INA238

Power: 3V3_SYS / GND_SYS.

I2C address: `0x40` by tying A1=GND and A0=GND.

Analog input:

```text
SYSTEM shunt LOAD side ---- 10R ---- INA238 IN+
                                  |
                                100 nF differential
                                  |
SYSTEM shunt BAT side  ---- 10R ---- INA238 IN-

INA238 VBUS ---------------------- LOAD side after the small sense fuse
INA238 GND ----------------------- GND_SYS / system battery minus
INA238 VS ------------------------ 3V3_SYS
```

- 100 nF VS decoupling directly at the device.
- 4.7 kOhm I2C pull-ups exist on the system side of ISO1640.
- The INA238 datasheet limits the input filter resistors to <=100 Ohm; 10 Ohm is intentionally conservative.

## Bow battery INA238

Power: 3V3_BOW / GND_BOW from TDN 1-2410WI.

I2C address: `0x41`: A1=GND_BOW, A0=3V3_BOW.

Analog input is the same 10 Ohm + 100 nF differential filter as the system channel.

`GND_BOW` must connect to bow battery negative solely as the measurement reference. It must not be joined to GND_SYS elsewhere on the PCB.

## ISO1640 isolated I2C

- VCC1 = 3V3_SYS, GND1 = GND_SYS.
- VCC2 = 3V3_BOW, GND2 = GND_BOW.
- 100 nF decoupling at each VCC within a few millimeters.
- 4.7 kOhm pull-up on SDA and SCL on **both** sides.
- Firmware initially uses 100 kHz I2C for margin.
- Add a physical PCB isolation slot under/across the isolation barrier; no copper pour crossing the barrier.

## ISO1042 NMEA 2000 interface

- VCC1 = 3V3_SYS.
- VCC2 = 5V_N2K.
- GND1 = GND_SYS.
- GND2 = GND_N2K / NET-C.
- TXD = GPIO6.
- RXD = GPIO7.
- 100 nF at VCC1 and VCC2; add 1 uF local bulk on 5V_N2K.
- CAN-H/CAN-L get a CAN-rated ESD TVS near the M12 connector.
- Optional common-mode choke footprint between transceiver and connector; fit if EMC/noise testing shows it is useful.
- **No 120 Ohm bus termination** on this PCB because BatterySentinel is a normal NMEA drop node.

### NMEA Micro-C / M12 pinout

| Pin | Signal |
|---:|---|
| 1 | Shield / drain |
| 2 | NET-S +12 V |
| 3 | NET-C 0 V |
| 4 | NET-H / CAN-H |
| 5 | NET-L / CAN-L |

Shield is not tied to GND_SYS. In the plastic V1 enclosure it is left isolated on a dedicated shield pad unless a later EMC test proves a defined chassis coupling is useful.

## PCB layout zoning

```text
+------------------------------------------------------------------+
| USB-C       ESP32-C3 antenna keepout             NMEA M12         |
|   |            +------------------+              |                |
| AP63203        | ESP32-C3         |       ISO1042 |  CAN ESD      |
| SYS power      +------------------+       ||||||| |                |
|                                   isolation slot  |                |
| INA238 SYS --- I2C ---- ISO1640 |||||| isolation  |                |
|    ^                        ||||||               AP63205 N2K      |
|    | SYS Kelvin             ||||||                                |
|                             ||||||        TDN 1-2410WI            |
| BOW Kelvin ---> INA238 BOW  ||||||        isolated power          |
+------------------------------------------------------------------+
```

Rules:

- No ground/copper under ESP32 antenna.
- Kelvin traces routed as a matched, close pair away from SW nodes and CAN.
- No copper crossing ISO1640 or ISO1042 isolation slots.
- Put the INA238 devices and their 10 Ohm/100 nF filters directly at the sensor cable terminals.
- TVS parts go at connectors, not deep inside the PCB.
- Keep USB and NMEA connector ESD return currents out of INA238 measurement ground paths.

## Open hardware edge cases before PCB release

1. **Starter path:** confirm whether the engine starter current flows through the system-battery shunt. 500 A / 50 mV is substantially safer than 300 A, but a measured/known cranking peak is still required before final release.
2. **Shunt mechanical rating:** verify the selected 500 A shunt's short-time overload rating, not only its nominal 500 A / 50 mV calibration.
3. **Charging while ignition is off:** the firmware will not coulomb-count it. SOC recovers by OCV at next start, but a just-charged battery can show surface charge and will intentionally not be immediately trusted as OCV.
4. **Bow charger topology:** ensure charger positive is connected to the load/charger side of the bow shunt; otherwise charging current will be invisible.
5. **System charger topology:** same requirement for alternator/shore/DC-DC charging of the system battery.
6. **High-current voltage sag:** low-voltage warning uses a separate loaded threshold so a normal 180–200 A thruster pulse does not create a false 'battery empty' alarm.
7. **Sensor wire open/short:** software flags invalid sensor data; the small physical sense-wire fuses limit fault energy.
8. **NMEA bus absent while USB/ignition is present:** ISO1042 bus side is unpowered/high impedance; firmware must continue without blocking.
9. **Condensation:** conformal coat the PCB, but do not coat connector contacts, USB contacts, BOOT/RESET buttons or pressure-sensitive labels.
10. **Shunt cover temperature:** ASA cover must not touch the resistive element; validate temperature during a repeated bow-thruster test.
