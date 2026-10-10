> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](../docs/internal/README.md).

# Orion Bridge: Schaltplan und Leiterplattenentwurf R1

Stand: 20.09.2026. R1 beschreibt eine **80 × 60 mm große, zweilagige Trägerplatine** für den ESP32-C3 SuperMini und die vorhandene Firmware `orion_dongle`. Die Unterlagen enthalten einen Schaltplan und ein Platzierungs-/Routingkonzept. Ergänzend liegt jetzt ein [bearbeitbarer Altium-Projektentwurf](altium/README.md) mit Schaltplan und unverdrahtetem PCB-Grundlayout vor. Es gibt noch keine Gerber-/Bohrdaten und keine ERC-/DRC-Freigabe. Die Unterlagen sind deshalb keine Fertigungsfreigabe.

R1 ersetzt die Versorgungs-, USB- und Terminierungsangaben des [historischen Erstentwurfs](orion-dongle-nmea2000.md).

## Zeichnungen öffnen

Die [interne PDF-Mappe mit vier A3-Seiten](../output/internal/engineering/orion-bridge-schaltplan-pcb-entwurf.pdf) enthält:

| Blatt | Inhalt | Einzelzeichnung |
| --- | --- | --- |
| 1 | Versorgung, Verpolschutz, isolierter Wandler, USB-Service-Trennung | [01-versorgung.svg](drawings/01-versorgung.svg) |
| 2 | CAN-Anschluss, Schutz, ISO1042 und Controller | [02-can-controller.svg](drawings/02-can-controller.svg) |
| 3 | Platzierung, Leitungsführung und getrennte Masseflächen | [03-pcb-layout.svg](drawings/03-pcb-layout.svg) |
| 4 | Bauteilauswahl, offene Auslegungsfragen und Quellen | [04-bauteile-hinweise.svg](drawings/04-bauteile-hinweise.svg) |

Die SVGs sind Vektorzeichnungen. Der gemeinsame Generator ist [tools/draw_orion_hardware.py](../tools/draw_orion_hardware.py); er erzeugt auch die PDF und verwendet ReportLab sowie die im Skript angegebenen Windows-Schriften.

## Elektrischer Aufbau

`NET-S → F1 → Q1 → BUS_PROT` versorgt zwei getrennte Zweige: U3 erzeugt `5V_BUS` für die CAN-Seite des ISO1042; U2 erzeugt die isolierte Logikversorgung für den SuperMini. `GND_BUS` entspricht NET-C. `GND_LOGIC` gehört zum SuperMini und seinem USB-Anschluss. Der Kabelschirm bleibt auf einem separaten Schirm-/Chassisanschluss.

Die CAN-Signale laufen über den Schutz D3 und die Gleichtaktdrossel L1 zum ISO1042. Auf der Logikseite bleiben **GPIO6 = CAN TX** und **GPIO7 = CAN RX** wie in der Firmware. Orion-Daten kommen über Bluetooth; Ladeleitungen und Shunts sind nicht Teil dieser Platine.

| Bereich | Festlegung in R1 |
| --- | --- |
| U3 | **TPS7B6950QDCYRQ1**, 5 V/150 mA, SOT-223. Pin 1 = IN, Pin 2 und Tab 4 = GND, Pin 3 = OUT. Ersetzt den LM2936 mit nur 50 mA, weil der ISO1042 busseitig bis 73,4 mA benötigen kann. |
| C3 an U3 | 10 µF/16 V X7R; effektiv mindestens 2,2 µF unter Spannung und Temperatur. Zulässiger Bereich: 2,2–100 µF, ESR 1 mΩ–2 Ω. |
| F1 | Träge **T0,8 A, mindestens 60 V**, gemäß der Stromempfehlung für den 24-V-R3M. Der frühere 0,5-A-/30-V-PPTC ist für R1 gestrichen. Konkrete Bestellnummer und Footprint bleiben bis zur Einschaltstrom-/Temperaturprüfung offen. |
| U2 | **R3M-2405S/SMD**, isolierte 5 V/600 mA. Pin 1 = +VIN, 2 = −VIN, 4 = CTRL offen, 5 = NC, 6 = −VOUT, 7 = +VOUT. Das herstellerspezifische Landpattern ist erforderlich. |
| U2-Eingangsfilter | C8/C9 jeweils 10 µF/50 V, L2 = 15 µH mit mindestens 1 A Sättigungsstrom; Gleichstromwiderstand und Spannungsverluste prüfen. |
| Kondensator über der Isolation | Der zusätzliche 470-pF-Kondensator aus RECOMs Class-B-Filtervorschlag ist **nicht bestückt oder eingezeichnet**. Aus dem Teilfilter folgt keine Class-B-EMV-Zusage. |
| D2 / JP1 | SS36 sperrt Rückstrom zum Wandler. JP1 trennt dessen Versorgung vom SuperMini für den USB-Service. Das ist keine automatische Quellenumschaltung. |
| Terminierung | **Kein RTERM und kein 120-Ω-Footprint auf dem Drop.** Die zwei Abschlüsse gehören an die Enden des NMEA-Backbones. |

**USB-Betriebsarten:** Im RUN-Betrieb ist JP1 gesteckt und USB abgezogen. Für SERVICE zuerst JP1 öffnen, dann USB anschließen. D2 schützt nur den DC/DC-Wandler vor Rückspeisung; sie verhindert keine Rückspeisung in den PC bei gleichzeitig gestecktem JP1 und angeschlossenem USB. Eine automatische Lösung müsste den USB-VBUS-Pfad des konkreten SuperMini separat führen.

## Platzierung und verbleibende Auslegung

Die Layoutzeichnung zeigt Bauteilreservierungen und Leitungsverläufe auf 80 × 60 mm. Headerfolge, USB-Überstand, Antennenposition und Abmessungen des tatsächlich verwendeten SuperMini sind noch nicht vermessen. Die gezeichneten Modulanschlüsse sind Signalnamen; sie ersetzen keinen geprüften Modulfootprint. Die vorgeschlagenen Befestigungsbohrungen und der Antennenfreiraum müssen zum Gehäuse passen.

Eine globale **6-mm-Kupfersperre** trennt die Massebereiche. Am R3M-Landpattern beträgt der Abstand zwischen den inneren Padkanten jedoch nur **3,8 mm**. Die lokale Geometrie begrenzt die tatsächlich erreichbaren Abstände; die 6-mm-Markierung ist keine normativ nachgewiesene Isolationsstrecke. U1 und U2 sind die vorgesehenen Übergänge zwischen den Bereichen.

Vor einer Fertigungsfreigabe sind drei Punkte zu schließen:

- **Mechanik und ECAD:** Das konkrete Modul sowie F1, J1 und JP1 festlegen; Original-Landpatterns übernehmen und anschließend ERC, DRC und Kollisionen prüfen. Erst daraus lassen sich Fertigungsdaten ableiten.
- **Versorgung:** U2 benötigt mindestens 9 V **an seinen Eingangspins nach F1/Q1/Filter**. Betrieb bei 9 V an NET-S ist mit diesem Entwurf nicht garantiert. Einschaltstrom, Filterverluste, Sicherung und maximale Stromaufnahme einschließlich LEN sind am Aufbau zu bestimmen.
- **Thermik und EMV:** U3 setzt bei 16 V und 73,4 mA rechnerisch etwa **0,81 W** um. Die 20 × 20 mm große Wärmefläche auf der BUS-Seite ist ein Ausgangspunkt, kein Nachweis. Temperatur und EMV müssen mit dem realen Aufbau geprüft werden.

Die [alte CSV-Stückliste](orion-dongle-bom.csv) und ihre Preise wurden **nicht auf R1 aktualisiert**. Sie ist keine Bestellliste für diese Revision. Blatt 4 zeigt den aktuellen Auswahlstand einschließlich der noch offenen Bestellteile.

## Primärquellen der Zeichnung

- [TI ISO1042](https://www.ti.com/lit/ds/symlink/iso1042.pdf): Pinbelegung, DWV-Gehäuse und Versorgungsstrom.
- [TI TPS7B69-Q1](https://www.ti.com/lit/ds/symlink/tps7b69-q1.pdf): U3, Kondensatoren und thermische Randbedingungen.
- [RECOM R3M](https://recom-power.com/pdf/Econoline/R3M.pdf): U2, Filter, Eingangsspannung, Sicherung und Landpattern.
- [Diodes DMP6023LE](https://www.diodes.com/datasheet/download/DMP6023LE.pdf): Q1 und Anschlussbelegung.
- [Nexperia PESD2CAN24T-Q](https://assets.nexperia.com/documents/data-sheet/PESD2CAN24T-Q.pdf): CAN-Schutz D3.
- [TDK ACT45B](https://www.tdk-electronics.tdk.com/inf/30/ds/act45b.pdf): Gleichtaktdrossel L1.
- [Garmin Micro-C-Anschluss](https://static.garmin.com/pumac/N2k_Field-install_Connector_Wiring_ML.pdf): Pinnummern und Aderfarben.
- [Nologo SuperMini](https://www.nologo.tech/product/esp32/esp32c3/esp32c3supermini/esp32C3SuperMini.html): Modulreferenz; die konkrete Boardvariante ist abzugleichen.
- [Espressif RF-Layout](https://docs.espressif.com/projects/esp-hardware-design-guidelines/en/latest/esp32c3/pcb-layout-design.html): Antennenfreiraum und Leiterplattenlayout.
