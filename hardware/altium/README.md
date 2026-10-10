> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](../../docs/internal/README.md).

# Orion Bridge R1 – Altium Designer

Öffne **[Orion-Bridge-R1.PrjPcb](Orion-Bridge-R1.PrjPcb)** in Altium Designer. Das lokale Projekt enthält einen elektrisch bearbeitbaren Schaltplan und ein **unverdrahtetes 80 × 60 mm großes PCB-Grundlayout**. Beide Dokumente liegen im nativen Altium-ASCII-Format vor; es ist kein Import aus einem anderen CAD-System erforderlich. In Altium können sie anschließend mit „Save As“ im aktuellen Binärformat gespeichert werden.

**Status: Entwicklungsentwurf, keine Fertigungsfreigabe.** Die Dateien wurden strukturell und anhand ihrer Netzzuordnungen geprüft. Öffnen/Speichern, ERC, ECO und DRC in Altium wurden noch nicht geprüft: Der Computer-Use-Zugriff auf die installierte Altium-Version 25 wurde in dieser Sitzung nicht freigegeben.

## Inhalt

| Datei | Zweck |
| --- | --- |
| `Orion-Bridge-R1.PrjPcb` | Projektdatei mit relativen Dokumentpfaden |
| `Orion-Bridge-R1.SchDoc` | Ein A2-Schaltplanblatt, 28 Bauteile, Pins, Leitungen und benannte Netze |
| `Orion-Bridge-R1.PcbDoc` | Platinenkontur, Bauteilplatzierung, Pads mit Netznamen und mechanische Hinweise; ohne Kupferrouting |
| `Orion-Bridge-R1.NET` | Zusätzliche Protel-Netzliste zum unabhängigen Abgleich |
| `orion-r1-design.json` | Elektrische Ausgangsdaten einschließlich Pinbelegung, Platzierung und Prüfstatus |
| `Schaltplan-Vorschau.png` | Aus den ASCII-Objekten erzeugte Sichtprüfung; keine Altium-Bildschirmaufnahme |
| `PCB-Vorschau.png` | Draufsicht auf die erzeugten Platzierungs- und Padobjekte, ohne Routing |

Die Schaltplansymbole sind einfache Funktionsblöcke mit sichtbaren Pinnamen und -nummern. Gleiche Netznamen auf diesem einen Blatt verbinden die zugehörigen Leitungen. Symbole und PCB-Geometrien sind in den Dokumenten enthalten. Es werden keine Cloud-Bibliotheken oder verwalteten Komponenten benötigt. Separate wiederverwendbare `.SchLib`/`.PcbLib`-Bibliotheken sind noch nicht Bestandteil dieses Entwurfs; diese lassen sich nach dem Öffnen und Prüfen aus den Dokumenten erstellen. Ein Bibliotheksupdate oder Austausch von Footprints ist deshalb noch nicht freigegeben.

## Vor dem Weiterlayouten

- **MCU1 besitzt absichtlich keine PCB-Pads.** Seine Umrissfläche reserviert Platz; die fünf logischen Schaltplananschlüsse ersetzen keine geprüfte Header-Pinfolge. Das konkrete ESP32-C3-SuperMini-Modul vermessen und dessen Footprint samt Pinzuordnung ergänzen.
- Die Footprints von **J1, F1, L2, C1 und C6** sind ausdrücklich vorläufig. Konkrete Bestellteile, Raster, Padmaße und Höhen festlegen. Auch JP1 und die übrigen Landpatterns anhand der bestellten Teile prüfen.
- **Keine Kupferbahnen und keine gegossenen Masseflächen:** Netzzuordnungen an Pads dienen als Ausgangspunkt für das Routing. Die Isolations- und Antennenbereiche sind zu beachten; sie ersetzen keinen DRC-Nachweis. Am R3M beträgt der innere Padabstand nur 3,8 mm.
- Bei **U3** Wärmeabfuhr und effektive Ausgangskapazität nachweisen. **U2** braucht mindestens 9 V nach Schutz- und Filterverlusten; 9 V am NMEA-Anschluss sind damit weiterhin nicht abgedeckt.
- **USB-Service:** JP1 zuerst öffnen, erst danach USB anschließen. Im NMEA-Betrieb JP1 schließen und USB abziehen. D2 ist keine vollständige automatische Quellenumschaltung.
- Zwei getrennte Massebereiche: `GND_BUS` = NET-C; `GND_LOGIC` = SuperMini/USB. Der Schirm bleibt auf `SHIELD`. Keine zusätzliche 120-Ohm-Terminierung auf dieser Drop-Platine.

`R3` entspricht `R_TX`, `R4` entspricht `R_RX` und `TP1` entspricht `TP_SH` in der [R1-Referenzzeichnung](../orion-pcb-r1.md). PCB-Koordinaten beziehen sich auf die linke untere Ecke. Das Grundlayout wurde für die tatsächlichen Footprint-Abmessungen aus der Platzierungsskizze weiterentwickelt; die Zeichnung stellt keine identische Bestückungsdatei dar.

## Reproduzieren und prüfen

Im Repository-Verzeichnis:

```text
python tools/build_altium_project.py
python tools/verify_altium_project.py
```

**Der Generator überschreibt die generierten Entwurfsdateien.** Änderungen aus Altium zuerst separat sichern oder in einen eigenen Projektordner übernehmen. Der Generator startet Altium nicht und erzeugt keine Fertigungsdaten.

Nach dem Öffnen: Dokumentdarstellung prüfen, Projekt validieren, Schaltplan und PCB über Component Links/ECO abgleichen, offene Footprints ersetzen, routen und anschließend ERC/DRC ausführen. Erst nach Abschluss der elektrischen, thermischen und mechanischen Prüfung Gerber- und Bohrdaten erzeugen.

## Format- und Hardwarequellen

- [Altium: natives ASCII-Schaltplanformat und Binärspeicherung](https://www.altium.com/documentation/knowledge-base/altium-designer/text-string-objects-cannot-be-selected-in-schematic-editor)
- [Altium: unterstützte Protel-/Altium-Dateiformate](https://www.altium.com/documentation/altium-designer/design-tools-interfacing/altium-design-software-import-export)
- [KiCad: Dokumentation des eigenen Altium-Importers](https://dev-docs.kicad.org/en/import-formats/altium/index.html)
- [GitHub Linguist: originale Altium-Dateiformatbeispiele](https://github.com/github-linguist/linguist/tree/main/samples/Altium%20Designer)
- [Novena: originales ASCII-PCB als Formatreferenz](https://github.com/novena-next/docs/blob/master/design_source/lidsense_board/ASCII-laptop-lidsense1.PcbDoc)
- [R1-Hardwarequellen und verbleibende Auslegung](../orion-pcb-r1.md)

Die Beispielprojekte wurden ausschließlich zur Prüfung der Dateistruktur herangezogen; ihre Schaltungen, Bauteile und Projektinhalte wurden nicht übernommen.

Prüfergebnis: **5.363 Struktur- und Verbindungsprüfungen bestanden** (28 Komponenten, 21 Netze, 76 PCB-Pads einschließlich der drei Bohrungen). Erfasst werden unter anderem die R1-Pinbelegung, tatsächlich gezeichnete Schaltplanverbindungen, Pad-Netzzuordnung, Padüberlappungen und Projektverweise. Das ist weiterhin kein Altium-ERC/DRC-Ergebnis.
