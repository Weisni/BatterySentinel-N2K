# Orion Bridge hardware

The current Orion-R5 board uses an ESP32-C3 SuperMini, isolated NMEA 2000 interface and a serviceable printed enclosure. The enclosure follows the 52 × 36 mm PCB and includes independent board retention, a flush-colour lid, screw-fastened service covers, TPU seals and a replaceable cable cartridge.

## Project status

The user confirmed the first Orion-R5 assembled on 2026-10-10. USB, service Wi-Fi and portal setup work according to the user. Measurements on the unpowered standalone boat-side terminals showed several kiloohms; exact pair readings were not retained. Bus-side power, isolation, CAN, thermal and final boat acceptance remain pending. Follow the [commissioning checklist](../../docs/orion-r5-commissioning.md).

The user completed the native Altium design. The supplied DRC report records zero violations and zero waived violations; this records the existing report, not a newly executed check. Ordering does not complete module-fit, power, thermal, radio, enclosure or NMEA/Garmin acceptance.

## Assembly references

- [Release-bound PCB hand-assembly package](Project%20Outputs/Hand%20Assembly/README.md), with purchased BOM, top-side placement map, polarity/pin details and bench checklists. [Download all files](Project%20Outputs/Orion-R5-Hand-Assembly.zip).
- [PCB customs payment evidence and cost reconciliation](procurement/README.md).

- [Printing, hardware and assembly guide](enclosure/sealed-print/README.md).
- [Bambu P2S four-plate project](enclosure/sealed-print/Orion-R5-P2S-flush-colour.3mf).
- [Plate and filament setup](enclosure/sealed-print/flush-colour/README.md).
- [Illustrated enclosure assembly manual — English](../../output/pdf/Orion-R5-Enclosure-Assembly-Manual-EN.pdf).
- [Operating and installation manual — German](../../output/pdf/BatterySentinel-N2K-Orion-R5-Betriebs-und-Installationsanleitung-DE.pdf).
- [First connection](../../docs/erstverbindung.md).

Verify the delivered SuperMini's physical fit, cable diameter, inserts and screw lengths against the assembly requirements before soldering. Thread the unsplit cable cartridge onto the cable before terminating it. Complete cable-retention and empty-case wet tests before fitting electronics. No verified IP rating is claimed.

For USB service, select **SERVICE before connecting USB** and **disconnect USB before selecting RUN**. Follow the operating manual for first power-up and network commissioning.

## Open work

- Completed on 2026-10-07: hand-assembly data derived from the supplied release ZIP, with the documented purchased L1/L2/L3 replacements; digital source reconciliation is recorded in the package. Physical assembly and commissioning remain open.
- First board assembly is user-reported complete; record inspection findings and the actual module/cable mapping.
- Verify enclosure fit, retention and seals separately; completed PCB assembly does not establish enclosure acceptance.
- Record supply switching, closed-case temperature, radio reception and enclosure test results.
- Verify Orion values, NMEA assignments and Garmin operation in the final installation.

Engineering source records and design history are listed in the [project-internal documentation](../../docs/internal/README.md).
