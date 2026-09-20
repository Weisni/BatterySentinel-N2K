# Orion Dongle: ESP32-C3 SuperMini to isolated NMEA 2000

Status: prototype reference design, 2026-09-20. This is not an NMEA 2000 certified product and is not a substitute for EMC, environmental, isolation and onboard acceptance testing.

## Design goal

This carrier connects the existing `orion_dongle` firmware to a powered NMEA 2000 Micro-C drop. NMEA 2000 uses the CAN physical layer at 250 kbit/s. The design:

- powers the ESP32-C3 SuperMini from the 9-16 V NMEA 2000 network;
- keeps the ESP32/USB side galvanically isolated from NET-C and the CAN pair;
- uses the firmware pin assignment `GPIO6 = CAN TX` and `GPIO7 = CAN RX`;
- includes reverse-polarity, over-current, supply-transient and CAN ESD protection;
- does **not** add a normal 120 ohm termination resistor, because a drop node is not a backbone terminator.

Garmin documents 9-16 V operation, 1 LEN = 50 mA, two 120 ohm backbone terminators and a maximum 6 m drop cable: [Garmin NMEA 2000 glossary](https://www8.garmin.com/manuals/webhelp/GUID-1415AAD0-FE63-42A6-8F8D-DB713D616122/EN-US/GUID-9C47C97C-88A2-4EC6-9846-9B6937C3ACA7.html).

## Electrical domains

| Domain | Reference | Contents |
| --- | --- | --- |
| `BUS` | `GND2 = NET-C` | Micro-C, protection, LM2936, ISO1042 bus side |
| `LOGIC` | `GND1` | isolated 5 V, SuperMini, USB, ISO1042 logic side |
| `SHIELD` | cable drain/chassis | enclosure/chassis pad only; never connect directly to `GND1` |

Maintain the isolation barrier between `BUS` and `LOGIC`: no copper, mounting hardware, shield or programming adapter may bridge `GND1` and `GND2`.

## Simplified schematic

The printable drawing is in [`orion-dongle-nmea2000-schematic.svg`](orion-dongle-nmea2000-schematic.svg).

```text
NMEA 2000 Micro-C male

 pin 1 SHIELD (bare) ------------------------------ CHASSIS PAD ONLY

 pin 2 NET-S (red, 9..16 V)
      |
     F1 0.5 A PPTC
      |
     Q1 P-MOS reverse-polarity protection
      |--------------------+------------------------------- BUS_12V
     D1 SMBJ24A            |                                  |
      |                     |                                  |
 pin 3 NET-C ---------------+---------------- GND2             |
                                                             |
                         U3 LM2936-5.0                  U2 R3M-2405S/SMD
                         IN | OUT                      IN+ |  OUT+  isolated
                         12V| 5V_BUS                       |    +5V_ISO
                            |                               |       |
                         GND2                              GND2    D2 Schottky
                                                                    |
                                                               ESP32 5V pin
                                                               ESP32 GND = GND1
                                                               ESP32 3V3
                                                                    |
             LOGIC / isolated side          || isolation ||          BUS side
                                             ||           ||
 ESP GPIO6 (TX) -- 33R -- TXD pin 2   U1 ISO1042DWV      pin 7 CANH -- L1a -- pin 4 white
 ESP GPIO7 (RX) -- 33R -- RXD pin 3                      pin 6 CANL -- L1b -- pin 5 blue
 ESP 3V3 --------------- VCC1 pin 1                      pin 8 VCC2 ---- 5V_BUS
 GND1 ------------------- GND1 pin 4                      pin 5 GND2 ---- NET-C
          C5 100 nF at VCC1                                  C6 100 nF at VCC2

 After L1, D3 is a two-line CAN TVS from CANH/CANL to GND2, placed at the connector.
 RTERM/DNP: optional 120 ohm footprint across CANH/CANL; never populate for a normal NMEA drop.
```

The ISO1042 pinout and supply ranges come from the [Texas Instruments ISO1042 data sheet](https://www.ti.com/lit/ds/symlink/iso1042.pdf). TI specifies 120 ohm termination only at both ends of the bus and recommends short unterminated stubs.

## Exact connections

### ESP32-C3 SuperMini

| SuperMini pin | Connect to | Note |
| --- | --- | --- |
| `5V` | D2 cathode, isolated 5 V supply | D2 prevents USB 5 V from feeding back into U2 |
| `GND` | `GND1` | never connect to NET-C/GND2 |
| `3V3` | ISO1042 VCC1 pin 1 | logic-side supply |
| `GPIO6` | 33 ohm then ISO1042 TXD pin 2 | matches current firmware |
| `GPIO7` | 33 ohm then ISO1042 RXD pin 3 | matches current firmware |
| USB-C | service/programming | remains on isolated side |

SuperMini boards are not fully standardized. Verify the actual board pin labels, 4 MB flash and GPIO6/GPIO7 availability before assembly. Do not use GPIO9 for CAN; it is the BOOT input used by the portal recovery flow.

### ISO1042DWV

| Pin | Net |
| ---: | --- |
| 1 VCC1 | ESP `3V3` |
| 2 TXD | ESP GPIO6 through 33 ohm |
| 3 RXD | ESP GPIO7 through 33 ohm |
| 4 GND1 | isolated logic ground |
| 5 GND2 | NET-C |
| 6 CANL | common-mode choke, then Micro-C pin 5 |
| 7 CANH | common-mode choke, then Micro-C pin 4 |
| 8 VCC2 | regulated `5V_BUS` |

Place one 100 nF X7R capacitor directly between pins 1/4 and another directly between pins 8/5.

### Micro-C pinout

| Pin | Wire | Signal | Carrier connection |
| ---: | --- | --- | --- |
| 1 | bare | Shield | chassis/shield pad only |
| 2 | red | NET-S, +12 V nominal | F1 input |
| 3 | black | NET-C | GND2 only |
| 4 | white | CAN-H | protected CANH |
| 5 | blue | CAN-L | protected CANL |

Pin and wire assignments: [Garmin field-install connector](https://static.garmin.com/pumac/N2k_Field-install_Connector_Wiring_ML.pdf) and [Garmin troubleshooting reference](https://support.garmin.com/en-HK/?faq=656KiuIo733b27xQgmLBy7).

## Supply and protection details

1. `F1`: 0.5 A hold-current PPTC, at least 30 V.
2. `Q1`: DMP6023LE, -60 V P-channel MOSFET. Use it as a high-side reverse-polarity element. Add `R1 = 100 kohm` gate to NET-C and a 12 V gate-source Zener. Confirm source/drain against the selected footprint before PCB production.
3. `D1`: SMBJ20A from protected BUS_12V to NET-C, cathode at BUS_12V. Its 20 V standoff remains above the 16 V operating ceiling while clamping well below U2's 50 V one-second surge rating. Keep the loop to F1 and NET-C short.
4. `U2`: R3M-2405S/SMD, 9-36 V input, isolated regulated 5 V/600 mA output. Add 47 uF + 100 nF on its isolated output and the input/EMI parts recommended in its data sheet.
5. `D2`: SS14/SS24-class Schottky between U2 output and the SuperMini 5 V pin. This provides simple power ORing with USB. Do not connect an unisolated serial adapter ground to GND2.
6. `U3`: LM2936M-5.0 supplies only ISO1042 VCC2. Fit the input and output capacitors required by its data sheet; a 10 uF output capacitor plus 100 nF local bypass is the starting point.
7. `L1`: ACT45B-510-2P-TL003 common-mode choke. Place between ISO1042 and connector protection.
8. `D3`: automotive two-line CAN TVS such as PESD2CAN24T-QR or ESD2CAN24-Q1, directly at the connector on the connector side of L1.
9. `RTERM`: DNP. Populate 120 ohm only for a separate two-node bench CAN cable when this board is physically one of its two ends. Never enable it merely because the dongle is connected through an NMEA T-piece.

The R3M is an industrial/ITE converter, not a marine-certified power supply. A final vessel product still needs load-dump, conducted/radiated EMC, salt/humidity, vibration, temperature and enclosure validation.

## Power calculation

Conservative design case:

| Load | Assumption | Power |
| --- | ---: | ---: |
| SuperMini including radio peaks | 5 V x 0.50 A | 2.50 W |
| logic side and margin | included in 3 W converter rating | up to 0.50 W |
| ISO1042 bus side + LM2936 losses | approximately 10-15 mA from NET-S | approximately 0.12-0.24 W |

U2 is rated for 3 W output. At 80% efficiency its full-load input is about `3 W / 0.80 = 3.75 W`.

- At 12 V: `3.75 W / 12 V + 0.015 A = 0.328 A`.
- At 9 V: `3.75 W / 9 V + 0.015 A = 0.432 A`.
- A 0.5 A PPTC therefore covers normal full-load operation while limiting a persistent fault.
- Since 1 LEN equals 50 mA, the conservative worst-case declaration is **LEN 9**. Measure the finished hardware over 9-16 V and revise this only from measured worst-case input current.

In normal BLE-only operation with the Wi-Fi portal closed, consumption should be materially below the converter maximum, but the NMEA power budget must not rely on an unmeasured typical value.

## Prototype BOM and order links

Prices are indicative single-unit prices observed on 2026-09-20. Distributor prices may exclude VAT and shipping; marine-retail prices normally include VAT. See the machine-readable [`orion-dongle-bom.csv`](orion-dongle-bom.csv).

| Ref | Qty | Part | Approx. EUR | Link |
| --- | ---: | --- | ---: | --- |
| MCU1 | 1 | ESP32-C3 SuperMini, 4 MB | 6.90 | [Blinkyparts](https://shop.blinkyparts.com/de/ESP32-C3-SuperMini-Kompaktes-WiFi-Bluetooth-5.0-Modul-mit-USB-C/blink23158) |
| U1 | 1 | TI ISO1042DWVR isolated CAN transceiver | 5.48 | [Mouser](https://www.mouser.de/de/ProductDetail/Texas-Instruments/ISO1042DWV?qs=qSfuJ%252Bfl%2Fd6fIgLDsh3Gaw%3D%3D) |
| U2 | 1 | RECOM R3M-2405S/SMD, 3 W isolated DC/DC | 21.80 | [Mouser](https://www.mouser.de/ProductDetail/RECOM-Power/R3M-2405S-SMD?qs=Y0Uzf4wQF3mS4GIsVxMAhQ%3D%3D) |
| U3 | 1 | TI LM2936M-5.0/NOPB | 2.24 | [Mouser](https://www.mouser.de/de/ProductDetail/Texas-Instruments/LM2936M-5.0-NOPB?qs=X1J7HmVL2ZEDOmZYs3zrWw%3D%3D) |
| Q1 | 1 | DMP6023LE-13, -60 V P-MOSF | 1.40 | [DigiKey](https://www.digikey.de/de/products/detail/diodes-incorporated/DMP6023LE-13/5080330) |
| F1 | 1 | 1812L050/30PR, 0.5 A PPTC | 0.89 | [Mouser](https://www.mouser.de/ProductDetail/Littelfuse/1812L050-30PR?qs=fp%2Fo%2FcJ74om2njanDLCOLA%3D%3D) |
| D1 | 1 | SMBJ20A supply TVS | 0.33 | [Mouser](https://www.mouser.de/ProductDetail/Taiwan-Semiconductor/SMBJ20A?qs=tHU%2FlV7kTySE5VtVjpxJkw%3D%3D) |
| D2 | 1 | SS36 or smaller 60 V Schottky | 0.82 | [Mouser](https://eu.mouser.com/ProductDetail/Vishay-Semiconductors/SS36-E3-57T?qs=x2jpVgRnAtNdHfPfldPWaQ%3D%3D) |
| L1 | 1 | TDK ACT45B-510-2P-TL003 | 1.32 | [Mouser](https://www.mouser.de/ProductDetail/TDK/ACT45B-510-2P-TL003?qs=U1cgCdF9Le9LCroNYLqljw%3D%3D) |
| D3 | 1 | PESD2CAN24T-QR, two-line CAN TVS | 0.60 | [Mouser](https://www.mouser.de/de/ProductDetail/Nexperia/PESD2CAN24T-QR?qs=mELouGlnn3fH5Bc5JzfhVg%3D%3D) |
| J1 | 1 | certified Micro-C male field connector | 31.95 | [SVB](https://www.svb.de/de/nmea2000-nmea2000-stecker-maennlich-micro-c.html) |
| passives | 1 set | capacitors, 33 ohm, 100 kohm, 12 V Zener, DNP 120 ohm | 3.50 | generic |
| PCB | 1 | two-layer carrier PCB, prototype allocation | 8.00 | estimate |
| enclosure | 1 | IP65/IP67 plastic enclosure + cable gland | 10.00 | estimate |

Indicative totals, excluding shipping and assembly:

- Electronics and carrier PCB without Micro-C connector/enclosure: **about EUR 53.28**.
- Complete prototype including field connector and enclosure: **about EUR 95.23**.
- Practical one-off order including split distributor shipping: budget **EUR 110-130**.
- A raw bench-CAN version using a screw terminal instead of Micro-C and without marine enclosure is approximately **EUR 55-65**.

The isolated DC/DC converter and certified Micro-C connector dominate the one-off cost. Omitting either makes the prototype cheaper but removes the properties that make it appropriate for an NMEA 2000 drop.

## Assembly and acceptance checklist

1. Confirm there is no continuity between GND1 and GND2/NET-C with the board unpowered.
2. Power the carrier from a current-limited 12 V bench supply before connecting CAN; verify 5V_BUS, isolated 5 V and 3.3 V.
3. Test supply polarity protection and input current at 9, 12 and 16 V.
4. With power off, an already terminated NMEA backbone should measure approximately 60 ohm between CAN-H and CAN-L. The dongle must not materially change that resistance.
5. First CAN test with a current-limited bench network and analyzer; verify 250 kbit/s, address claim and PGNs 127506/127507/127508.
6. Compare Orion voltages/currents against VictronConnect before trusting Garmin values.
7. Test BLE + CAN continuously, then open Wi-Fi/HTTPS and verify heap, resets and current peaks.
8. Only then install in a sealed enclosure, with strain relief, short drop cable and adequate distance from ignition/starter wiring.

## Important limitations

- NMEA 2000 certification and a registered manufacturer code are not included.
- The firmware currently uses manufacturer code 2046 as an unregistered placeholder.
- The isolated power module has basic 1.6 kVDC/1 minute isolation and an ITE rating; suitability for the final marine installation must be established separately.
- Do not connect CAN-H/CAN-L directly to ESP32 pins or use an unisolated SN65HVD230 breakout for permanent vessel installation.
- Never connect NET-S directly to the SuperMini 5 V pin.
