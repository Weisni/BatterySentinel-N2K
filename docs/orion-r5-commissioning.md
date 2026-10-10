# Orion-R5: first assembled-board commissioning

## Evidence and scope

On 2026-10-10 the user reported the first Orion-R5 assembled, with working USB, Wi-Fi and completed portal setup. All pairs of the boat-side power/CAN terminals were measured on the disconnected, unpowered board; several kiloohms were reported, but exact values were not retained. A supply with adjustable current limiting is available. These observations do not establish bus-side power, CAN signaling, isolation, thermal acceptance or compatibility with the boat network.

The pad mapping below was read from the ASCII PCB inside `hardware/altium-r5/Project Outputs/BatterySentinel-N2K-Orion-R5.zip`, the release authority. The power chain and test rationale also use `hardware/altium-r5/power-review.md`. Preserve the native design and unrelated work. This checklist is not certification or a measurement report.

### Follow-up: Wi-Fi heating accepted by the user

The user reported startup from 12 V with CAN and USB disconnected and SW3 in RUN. Module measurements were 5V = 4.94 V and 3V3 = 3.292 V; the supply display was poorly resolved below 60 mA. The ESP32 chip also became hot with the SuperMini standalone on USB.

The user's final assessment on 2026-10-10 attributes the observed heating to Wi-Fi and the lingering warmth after shutdown to slow cooling. The reduced-power trial made no noticeable difference; the user discarded it and accepts the standard firmware's behavior. This supersedes the earlier unresolved-fault interpretation and proposed radio-free diagnostic. See the [final thermal record](orion-r5-thermal-investigation.md).

No calibrated chip temperature, startup/ripple captures or closed-case thermal results were supplied. These remain ordinary commissioning checks; accepting this observation does not establish CAN signaling, isolation or final boat acceptance. Retain the existing firmware and power arrangement.

## Why several kiloohms are not a safety result

- A disconnected CAN transceiver without termination may measure high resistance. The Orion-R5 does not contain a 120-ohm bus terminator.
- A correctly terminated, fully unpowered backbone should measure approximately 60 ohms between CAN-H and CAN-L (two 120-ohm end terminators in parallel). This is a different measurement from the isolated board.
- Resistance in semiconductor/capacitor paths depends on meter polarity, test voltage and settling time. Reverse the leads and record both readings when interpreting such paths. Do not infer powered current as `12 V / measured resistance` for these nonlinear circuits.
- A wrong pin assignment can have high resistance while unpowered and still apply supply voltage to CAN when connected.
- Same-net cable/pad connections and the closed switch contact should show low resistance, after subtracting lead resistance. High resistance on every possible connection is not a universal pass condition.
- `5V_ISO` to `GND_LOGIC` deliberately includes R20 and R21, each 150 ohms, in parallel. Approximately 75 ohms is expected for that branch before other circuit effects. This is not a bus-to-logic isolation resistor.
- `GND_BUS` and `GND_LOGIC` must have no stable DC conductive bridge. A repeatable few-kiloohm path between them on the disconnected assembly requires investigation. A multimeter open-circuit reading finds gross bridges but does not qualify dielectric withstand or galvanic isolation. Do not apply a high-voltage insulation tester to the assembled electronics without a defined procedure and verified component limits.

## 1. Unpowered inspection and cable mapping

Disconnect the boat, USB, supply and scope. Verify zero voltage before resistance measurements. Use the release top-view drawing for component orientation. Inspect U1, U3/U4, D1/D3/D5, F1 and U2 for solder bridges, polarity and correct part numbers. Inspect all SuperMini lands and flux/contamination across the isolation gap.

| Micro-C / J1 pin | Release net | Intended connection |
| --- | --- | --- |
| 1 | SHIELD | Cable shield; TP1 only |
| 2 | NET_S | Positive NMEA supply; F1.1 |
| 3 | GND_BUS | NET-C return; U1.5 / U2.2 |
| 4 | CANH_EXT | CAN-H; D3.1, through L1 to U1.7 |
| 5 | CANL_EXT | CAN-L; D3.2, through L1 to U1.6 |

Verify pin numbers from the cable's manufacturer drawing and physical contact view. Mating-side and solder-side views can be mirrored. Colours alone are not a pinout verification. Keep SHIELD, GND_BUS and GND_LOGIC separate; do not add jumpers.

Verify SW3 electrically: RUN closes 1-2; SERVICE closes 2-3, with pin 3 unconnected to the supply. Pin 1 is `5V_REG`, pin 2 is `5V_MODULE`; metal shell anchors are `GND_LOGIC`. SERVICE disconnects module-positive supply, not logic ground or the entire bus-side circuit. Do not infer switch direction from its appearance.

Record all relevant pair measurements, lead polarity, settling behavior and switch position. Locate unexpected low resistance before energizing.

## 2. USB-only SERVICE check

Select SERVICE before USB. Leave J1 disconnected. Verify normal boot, service LED, portal login, saved settings and Orion reception. This tests the module and logic side; U1's bus-side supply and the DC/DC chain are not supplied by USB. A working portal does not establish CAN operation. The user already reports successful USB/Wi-Fi setup; repeat only as needed to document results or investigate a new fault.

Disconnect USB completely before selecting RUN.

## 3. Isolated bench supply in RUN

Use a floating/current-limited bench supply whose output/earth connections are understood. Boat disconnected, CAN-H/CAN-L insulated and unconnected, USB unplugged. With output disabled, connect supply positive only to J1.2 and negative only to J1.3. Verify actual polarity at the cable/board before enabling.

1. Set 12.0 V and an initial current limit around 0.10 A. Briefly enable to look for a gross short or unexpected heating. This is a cautious fault-screening setting, not a guaranteed safe current and not a normal boot acceptance test. Wi-Fi startup can exceed it; current limiting/brownout alone does not identify a fault. Disable promptly if the supply stays limited.
2. Check wiring and rail behavior before increasing the limit. A stalled/brownout boot may be an expected consequence of this low limit. Do not simply increase current to force an unexplained hot or shorted assembly to start.
3. With output off, set a functional-test limit up to 0.60 A, the current engineering bus budget. Restart at 12 V and record steady current, startup peaks and behavior during BLE reception/Wi-Fi activity. A supply entering current limit invalidates a voltage/startup acceptance result. Investigate before raising the provisional budget.
4. Measure the following rails using the indicated local return. Prefer accessible capacitor or module pads over probing adjacent IC pins.

| Rail | Accessible positive point | Return | Acceptance meaning |
| --- | --- | --- | --- |
| 5V_BUS | U2.1 / U1.8 | J1.3 / U2.2 | Target 5 V; ISO1042 VCC2 recommended 4.5-5.5 V |
| 5V_ISO | C27.1 / U2.6 | C27.2 / U2.4 | Unregulated isolated output; record startup and load changes, not a fixed 5-V guarantee |
| 5V_REG | SW3.1 | GND_LOGIC | U4 output; cannot boost low input voltage |
| 5V_MODULE | C34.1 / module 5V | C34.2 / module GND | Check module input range against actual module components, including startup overshoot and dropout |
| 3V3_LOGIC | Module 3V3 / U1.1 | Module GND / U1.4 | ESP32-C3 supply must remain within 3.0-3.6 V during operation; target 3.3 V |

5. Only after the 12-V test is satisfactory, repeat start/restart and radio load at 9 V and 16 V. The assembled product's intended input range is 9-16 V, not the buck IC's wider rating. Never test it by connecting directly to a 24-V boat supply.
6. Use the scope to observe startup, radio-load dips and load removal, referenced locally. Simultaneous dual-domain measurement requires an appropriate differential probe or genuinely isolated channels. Standard scope BNC grounds/ground clips are usually common and earth-referenced; they can short the isolation barrier. USB or an earth-referenced supply may introduce additional paths. Do not lift protective earth.
7. Record temperatures of U2, U3/U4, module LDO, R20/R21 and switch under representative sustained load, then in the closed enclosure. R20/R21 dissipate about 0.333 W total at 5 V by design. Warm preload resistors alone are not a defect. Review component derating and actual ambient; SW3's documented upper ambient rating is 70 °C and U2 derates above 71 °C. No qualified enclosure ambient range is claimed.

Stop on unexpected heating, smell, incorrect voltage, oscillation, resets or persistent current limiting. Never deliberately introduce shorts, reverse polarity or overvoltage as a first-board protection test.

## 4. Separate CAN test network

After power checks, use a small known-good test backbone with two 120-ohm end terminators, correct supply/fusing and a second active CAN/NMEA node. The second node must be capable of acknowledging valid frames; a listen-only analyzer does not provide ACK. The current firmware operates at 250 kbit/s and transmits; it is not a passive sniffer. Do not put a new terminator on the Orion-R5 drop.

- Fully unpowered CAN-H/CAN-L: approximately 60 ohms across the test backbone.
- Verify the bridge appears in the receiver's device list, existing traffic stays healthy and receive/send error counters remain stable.
- Verify Orion input/output values and distinct NMEA instances at the receiving device. Queue/send acceptance alone does not prove reception.
- A powered bridge alone with no ACK-capable second node may accumulate transmit errors or enter bus-off. This is not a valid completed CAN functional test.
- For waveform review, use CAN-H minus CAN-L with suitable probing; approximately 2 V differential in dominant state and near 0 V in recessive state are typical, not standalone compliance acceptance limits. Check bit timing, ringing and idle behavior rather than relying on a DC meter average.

## 5. Possible consequences of design or assembly errors

| Error | Possible consequence | Existing protection and its limit |
| --- | --- | --- |
| Supply short / overload | Network fuse opens, voltage collapse, hot traces/components; in severe faults cable/fire risk | F1 is a release 0.8-A slow-blow fuse; current limiting and correctly fused network remain necessary |
| Reversed supply | Failure to start or component damage | D5 is series reverse-polarity protection; wrong assembly, bypass paths or other incorrect pins can defeat it |
| Supply on CAN / mirrored pinout | Bus outage or damage to bridge and other network transceivers | U1's ±70-V bus fault protection applies under datasheet conditions; D3 and all other connected devices are not thereby protected as a system |
| Wrong/missing/extra termination, swapped CAN lines, defective active driver | Communication failure, bus-off, loss of network-dependent navigation/engine/alarm displays | U1 dominant timeout limits a specific stuck-TXD condition; it cannot fix every physical bus fault |
| Excess current, poor supply reserve, converter dropout | Resets and intermittent or stale data; disturbance to existing devices | 12 LEN / 600 mA is a provisional planning reserve requiring measurement |
| USB in RUN or external ground bridge | Backfeed, lost isolation, noise/ground currents, possible USB-host damage | SW3 only protects the positive source path when SERVICE is correctly verified and selected |
| Wrong regulator, overheating, inadequate transient behavior | Module overvoltage, brownouts, reduced life or damage | U4/TVS presence does not qualify startup or marine surge behavior |
| Duplicate data instances, stale values, unverified receiver alerts | Wrong source association, missing or persistent warnings | Software counters/portal status do not replace receiver-side acceptance |

The bridge reads Orion telemetry; it does not directly command the charger. Its failure can nevertheless impair the shared NMEA bus and displays/alerts depending on that bus.

## 6. First boat connection

Do this only after bench tests, at a berth/safe standstill, without navigation or engine safety depending on the tested network. Record the existing network device list and expected values first.

1. Turn off all NMEA network feeds and ensure zero voltage before measuring CAN-H/CAN-L resistance. Confirm two end terminators, approximately 60 ohms, and a free proper drop connection.
2. Verify actual supply polarity and 9-16 V at the intended drop using a voltage measurement after re-energizing the otherwise unchanged network. Check network power reserve and the added voltage drop. Turn it off again before connection.
3. Connect only the verified bridge drop; no USB, no added supply injection and no new termination. Use RUN.
4. Energize, compare network behavior before/after, rail/current results, existing devices, bridge discovery and data assignment.
5. If new faults occur, switch off and disconnect the bridge, restore the prior setup and compare. Do not continue a sea trial with unexplained loss of data.
6. Test missing Orion data, recovery, restart, final enclosure RF/thermal behavior and experimental receiver warnings separately. Complete the PDF's handover record with measured evidence.

## Open engineering finding

`include/config.h` reserves LEN 12 only for the internal WROOM profile. The current `orion_dongle` SuperMini branch uses `N2K_LOAD_EQUIVALENCY = 0xff` and model version `V1`. Confirm the actual reported product/configuration information with the test receiver and reconcile it with the measured R5 power budget before release. This documentation task does not change firmware or flash the device. Supply planning must not rely on that unverified declaration.

## Measurement record

| Test | Actual result / equipment / switch position | Pass / unresolved |
| --- | --- | --- |
| Cable mapping; shield and ground separation | | |
| SW3 continuity in RUN and SERVICE | | |
| USB/Wi-Fi/portal | User reports working; exact firmware and measurements still to record | Partial |
| 12-V input current; startup/radio peaks | Startup works; display poorly resolved below 60 mA. User accepts Wi-Fi heating and slow cooling | Peak current and final power budget pending |
| 5V_BUS min/max | | |
| 5V_ISO / 5V_REG / 5V_MODULE min/max | | |
| 3V3_LOGIC min/max; startup/load captures | User reports 3.292 V DC at the module; 5V input 4.94 V | Startup/load captures pending |
| 9-V / 16-V start and sustained radio load | | |
| Open/closed-case temperatures and ambient | | |
| Test-bus resistance, receiver discovery and CAN errors | | |
| Existing network unchanged; Orion values and instances | | |
| Receiver data-loss/recovery and restart | | |

## Sources checked on 2026-10-10

- [Garmin NMEA 2000 troubleshooting](https://support.garmin.com/en-HK/?faq=656KiuIo733b27xQgmLBy7): unpowered network resistance close to 60 ohms.
- [Garmin network termination](https://www8.garmin.com/manuals/webhelp/GUID-1415AAD0-FE63-42A6-8F8D-DB713D616122/EN-US/GUID-FABDEBBC-4930-4460-BC64-232E160406E3.html) and [glossary](https://www8.garmin.com/manuals/webhelp/GUID-1415AAD0-FE63-42A6-8F8D-DB713D616122/EN-US/GUID-9C47C97C-88A2-4EC6-9846-9B6937C3ACA7.html): two end terminations and 9-16 V supply.
- [TI ISO1042 datasheet](https://www.ti.com/lit/ds/symlink/iso1042.pdf), Rev. F: supplies, isolation, unpowered impedance and protection conditions.
- [Espressif ESP32-C3 supply guidance](https://docs.espressif.com/projects/esp-techpedia/en/latest/esp-friends/get-started/try-firmware/try-firmware-hardware/esp32c3.html): 3.0-3.6 V operating supply.
- [Diodes AP6320x datasheet](https://www.diodes.com/datasheet/download/AP63200-AP63201-AP63203-AP63205.pdf): regulator pinout and operating behavior.
- Local R5 release archive, `power-review.md`, `module-selection.md` and the hand-assembly package: assembly-specific connectivity and unverified power/thermal limits.

No deliberate boat fault injection, hardware changes or physical acceptance were performed during documentation work.
