# Orion Bridge R2 – Quellen und Herleitung

Quellenstand: 21. September 2026. Die lokalen Bibliotheken bilden den R2-Entwurf ab; sie sind keine von den Bauteilherstellern freigegebenen CAD-Bibliotheken. Herstellerdatenblätter liefern Pinbelegung und Gehäusemaße. Generische Bauteile bleiben bis zur Wahl konkreter Bestellteile als solche gekennzeichnet.

## Bauteile und Schnittstellen

| Bauteil / Thema | Primärquelle | Verwendung |
| --- | --- | --- |
| U1: Texas Instruments ISO1042DWV | [ISO1042-Datenblatt](https://www.ti.com/lit/ds/symlink/iso1042.pdf) | Isolierter CAN-Transceiver, Pinbelegung und DWV-Gehäuse |
| U2: RECOM R3M-2405S/SMD | [R3M-Datenblatt](https://recom-power.com/pdf/Econoline/R3M.pdf) | Isolierter DC/DC-Wandler, Versorgung, Pins und SMD-Gehäuse |
| U3: Texas Instruments TPS7B6950QDCYRQ1 | [TPS7B69-Q1-Datenblatt](https://www.ti.com/lit/ds/symlink/tps7b69-q1.pdf) | 5-V-LDO, Pin-/Tab-Belegung, DCY-Gehäuse und thermische Auslegung |
| Q1: Diodes Incorporated DMP6023LE | [DMP6023LE-Datenblatt](https://www.diodes.com/datasheet/download/DMP6023LE.pdf) | P-Kanal-MOSFET, Gate/Source/Drain und SOT-23 |
| L1: TDK ACT45B5102PTL003 | [ACT45B-Datenblatt](https://www.tdk-electronics.tdk.com/inf/30/ds/act45b.pdf) | CAN-Gleichtaktdrossel, Wicklungszuordnung und Anschlussgeometrie |
| D3: Nexperia PESD2CAN24T-QR | [PESD2CAN24T-Q-Datenblatt](https://assets.nexperia.com/documents/data-sheet/PESD2CAN24T-Q.pdf) | CAN-Schutz, Signal-/Masseanschlüsse und SOT23 |
| NMEA-2000-Anschluss | [Garmin: Field-installable Connector Wiring](https://static.garmin.com/pumac/N2k_Field-install_Connector_Wiring_ML.pdf) | Schirm, NET-S, NET-C, CAN-H und CAN-L |
| NMEA-2000-Netzaufbau | [Garmin: NMEA 2000 Network Fundamentals](https://www8.garmin.com/manuals/webhelp/GUID-1415AAD0-FE63-42A6-8F8D-DB713D616122/EN-US/GUID-9C47C97C-88A2-4EC6-9846-9B6937C3ACA7.html) | Backbone-/Drop-Aufbau und Terminierung |
| ESP32-C3 / RF-Layout | [Espressif: PCB Layout Design](https://docs.espressif.com/projects/esp-hardware-design-guidelines/en/latest/esp32c3/pcb-layout-design.html) | Allgemeine Layout- und Antennenhinweise; kein Nachweis für einen beliebigen SuperMini-Klon |

Die elektrische Ausgangsschaltung und verbleibenden Auslegungsfragen sind in der [R1-Hardwarebeschreibung](../orion-pcb-r1.md) dokumentiert. R2 übernimmt die Schaltung, ersetzt die Darstellung durch passende Symbole und ergänzt die lokalen Bibliotheken sowie den vollständigen Modulanschluss. R3/R4 entsprechen dort R_TX/R_RX, TP1 entspricht TP_SH.

## MCU1: Nologo ESP32-C3 SuperMini

Die Modulbelegung stammt aus dem [Hardware-Verzeichnis des Herstellers Nologo Tech](https://github.com/NologoTech/ESP32C3-Supermini/tree/main/Hardware). Herangezogen wurden:

- [Native Altium-PcbDoc des Moduls](https://raw.githubusercontent.com/NologoTech/ESP32C3-Supermini/main/Hardware/Super%20Mini-ESP32C3-%E5%A4%96%E5%BD%A2.PcbDoc): Headerpositionen und Padbezeichnungen.
- [Bemaßte Modulzeichnung](https://raw.githubusercontent.com/NologoTech/ESP32C3-Supermini/main/Hardware/ESP32-C3%E5%B0%BA%E5%AF%B8%E5%9B%BE.png): nominale Außenabmessungen und Anschlussanordnung.
- [Hersteller-Schaltbild](https://raw.githubusercontent.com/NologoTech/ESP32C3-Supermini/main/Hardware/%E7%94%B5%E8%B7%AF%E5%9B%BE.png): Signale und Versorgung.
- [Nologo-Produktseite](https://www.nologo.tech/product/esp32/esp32c3/esp32c3supermini/esp32C3SuperMini.html): Produktidentität und Modulbeschreibung.

SHA-256 der für die Herleitung verwendeten nativen PCB-Datei:

```text
2024b62b05af1480517c1491ca3c5df6724d70554ca090afc0967b2c56023116
```

In Draufsicht mit USB oben lautet die linke Anschlussreihe von oben nach unten `5, 6, 7, 8, 9, 10, 20, 21`; rechts `5V, GND, 3V3, 4, 3, 2, 1, 0`. Diese Signalbezeichnungen sind zugleich die Symbol- und Padbezeichnungen. GPIO6 führt TX, GPIO7 RX. Die vollständige Herleitung und die Netze stehen in [supermini-nologo.json](supermini-nologo.json).

Das R2-Landpattern beschreibt die **Trägerplatine für zwei 1×8-Header**: 15,24 mm Reihenabstand, 2,54 mm Raster, 1,8-mm-Pads und 1,0-mm-Bohrungen. Pad- und Bohrungsgrößen sind eine Trägerplatinen-Auswahl für übliche Header, keine unveränderte Kopie der Modulbohrungen. Die native Moduldatei enthält ungefähr 17,932 × 22,521 mm Außenmaß; als Platzierungsgrenze wird das vom Hersteller nominal angegebene Maß 18 × 22,5 mm verwendet. Header, USB-Überstand und reales Modul sind vor Fertigung abzugleichen.

## Dateiformate und lokale Bibliotheken

- [Altium: File-based Component Libraries](https://www.altium.com/documentation/altium-designer/components-libraries/file-based-libraries) beschreibt die Rollen von `.SchLib`, `.PcbLib`, `.LibPkg` und `.IntLib` sowie die Symbol-zu-Footprint-Zuordnung.
- [Altium: natives ASCII-Schaltplanformat und Speicherung](https://www.altium.com/documentation/knowledge-base/altium-designer/text-string-objects-cannot-be-selected-in-schematic-editor) erläutert das native ASCII-Schaltplanformat und die Konvertierung durch Speichern.
- [KiCad: Altium-Importer-Dokumentation](https://dev-docs.kicad.org/en/import-formats/altium/index.html) wurde als ergänzende Beschreibung der Compound-File- und Record-Struktur verwendet.
- [GitHub Linguist: Altium-Beispieldateien](https://github.com/github-linguist/linguist/tree/main/samples/Altium%20Designer) und [Novena: natives ASCII-PCB](https://github.com/novena-next/docs/blob/master/design_source/lidsense_board/ASCII-laptop-lidsense1.PcbDoc) dienten als Dateiformatreferenzen.

Für die nativen binären Bibliothekscontainer wurden zusätzlich die mit Altium Designer 25 installierten Beispielbibliotheken `Examples/Harness Demo MB/Libs/SCH.SCHLIB` und `PCB1.PcbLib` untersucht. Deren Schaltungen und Bauteile wurden nicht übernommen. Die erzeugten Symbol- und Footprintdaten stammen aus dem lokalen R2-Modell und den oben genannten Hardwarequellen.

Die vollständigen Editor- und Layerstack-Einstellungen der PcbLib stammen aus einer eigens in Altium Designer 26.10.1 erzeugten leeren Bibliothek. Die bereinigte Vorlage liegt in [pcb_library_header.json](../../tools/altium_defaults/pcb_library_header.json); sie enthält keine Bauteile oder Benutzerpfade. Diese globalen Einstellungen werden beim direkten Öffnen der Bibliothek benötigt, auch wenn einzelne Footprints bereits über die SchLib-Vorschau geladen werden können.

Die Implementierung liegt in [altium_libraries.py](../../tools/altium_libraries.py), die Symbolgeometrien in [altium_symbols.py](../../tools/altium_symbols.py) und die Footprintgeometrien in [altium_pcb.py](../../tools/altium_pcb.py). Die unabhängige Rückleseprüfung erfolgt durch [verify_altium_r2.py](../../tools/verify_altium_r2.py). Die Dateiprüfung bestätigt keine Herstellerfreigabe, elektromagnetische Verträglichkeit oder NMEA-Zertifizierung.
