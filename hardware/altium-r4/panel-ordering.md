# R4: JLCPCB-Bestellung mit dem vorbereiteten Kundenpanel

Die Platine bleibt **48 × 32 mm mit R2-Ecken**. Für die Bestückung enthält `JLCPCB-Panel` einen separaten **70 × 70 mm Fertigungsrahmen mit genau einer Platine**. Die Fräskonturen, Haltestege, Werkzeugbohrungen und Fiducials sind bereits echte Fertigungsdaten. Nach dem Trennen verbleibt die kompakte Einzelplatine. Die Altium-Dateien beschreiben weiterhin diese Einzelplatine.

## Zusammengehörige Upload-Dateien

Aus demselben Ordner `JLCPCB-Panel` verwenden:

- `Orion-Bridge-R4-Panel-Gerber.zip`: Panel-Geometrie mit vier tatsächlich freigefrästen Bereichen, PTH-/NPTH-Bohrdateien und USB-Schlitzen.
- `BOM-JLCPCB.csv`: die Bauteile **einer** Platine, einschließlich bestätigter JLC-Bauteilnummern.
- `CPL-JLCPCB.csv`: Bestückungskoordinaten im **Panel-Koordinatensystem**. Alle Positionen sind gegenüber der Einzelplatine um +11 mm / +16 mm versetzt; Rotation und Designatoren bleiben unverändert.

`Panel-70x70.svg` zeigt den Nutzen. `manufacturing-manifest.json`, `panel-preflight.json` und `panel-readback.json` dokumentieren die Quellstände und Prüfungen. Die Freigabe der Einzelplatine gehört zusätzlich dazu. Ein Panel-Check allein bestätigt weder elektrische Funktion noch ein bestandenes Hardware-Muster.

Für den Orientierungsabgleich liegt unter `assembly/Bestueckung-R4.svg` ein separater Bestückungsplan mit allen 50 bestückten Referenzen, den konkreten Referenzpads und den vier Diodenkathoden. `Bestueckung-R4-Orientierung.csv` nennt je Teil CPL-Winkel, lokale Hersteller-Padkoordinaten, Position im Einzelboard und Quellenlink. Die lokalen Koordinaten dienen der Orientierung; die eigentliche Panel-CPL stammt weiterhin aus `JLCPCB-Panel`.

**Keine Einzelplatinen-CPL mit Panel-Gerbern kombinieren.** Der Datensatz enthält genau eine Platine pro Nutzen.

## Bestellparameter

1. Fertigungsart **kundenseitig angelegter Nutzen / Panel by Customer** wählen, ein unterschiedliches Design und eine Platine je Nutzen. Abmessungen **70 × 70 mm** prüfen. Weitere Panellierung oder zusätzliche Ränder sind nicht erforderlich. Falls der Bestellablauf einen 1×1-Nutzen nur als Einzel-PCB akzeptiert, die bereits vorhandene 70×70-Geometrie unverändert verwenden; keine automatische V-Cut-Panellierung ergänzen.
2. **Zwei Lagen, FR-4, 1,6 mm, 1 oz, grüner Lötstopplack, ENIG**, Standard-Umrisstoleranz. Das Trägerboard hat keine castellierten Bohrungen; die Castellations sind bereits Teil des Espressif-Moduls. Die vier metallisierten USB-Langlöcher sind in der PTH-Datei enthalten.
3. **Standard PCBA, nur Oberseite**, BOM und CPL aus `JLCPCB-Panel` laden. Die Anzahl bestückter Nutzen entspricht der Anzahl benötigter Platinen. U2 wird als katalogisiertes THT-/manuell gelötetes Bauteil bestückt. J1 ist ein Kabel-Lötanschluss und TP1 eine Kupferfläche; dafür gibt es keine einzukaufende Komponente.
4. In der Bestückungsvorschau die Herstellerteile, tatsächliche Verfügbarkeit und Orientierung anhand des bereitgestellten Bestückungsplans abgleichen, besonders MCU1, U1–U4, D1–D6, J2 und U2. Die CPL-Winkel beschreiben das Layout; sie ersetzen nicht den Abgleich mit JLCPCBs Bauteilbibliothek.
5. Das WROOM-Modul darf nur einmal reflowgelötet werden; das Profil muss dessen Datenblatt erfüllen. Standard PCBA nennt 240 ± 5 °C. Der unbedruckte zentrale EPAD ist absichtlich ohne Paste; die Modul-GND-Randpads werden normal verlötet. Die Daten sind nicht für einen weiteren Reflowdurchlauf nach Vorbestückung gedacht.

Der Standard-Prozess fordert mindestens 70 × 70 mm und unterstützt gemischte SMT-/THT-Bestückung. Die Panelisierung verwendet die veröffentlichten Werte für Fertigungsränder, Fiducials und Mauslochstege. Maßgeblich bleibt die konkrete Bestellvorschau; Bauteilbestände wurden nicht reserviert. [JLCPCB Bestückung](https://jlcpcb.com/capabilities/pcb-assembly-capabilities), [JLCPCB Platinenfertigung](https://jlcpcb.com/capabilities/pcb-capabilities), [Mausloch-Panelisierung](https://jlcpcb.com/blog/mouse-bite-panelization-guide), [Espressif Datenblatt](https://documentation.espressif.com/esp32-c3-wroom-02_datasheet_en.pdf).

## Mechanik und Bestellbemerkung

Die vier Haltestege sind 5,1 mm breit und haben jeweils sechs 0,60-mm-NPTH bei 0,90-mm-Raster. Die 2-mm-Fräskanäle enthalten größere Freiräume unter der um 6 mm überstehenden Antenne und am USB-Stecker. Drei Fiducials und vier 2-mm-Werkzeugbohrungen liegen auf dem Rahmen; die äußeren 5-mm-Transportbereiche bleiben frei von Bauteilen. Es sind keine V-Cuts vorgesehen.

Nach der Bestückung die Platine abstützen, die perforierten Stege schneiden und Reste bündig nacharbeiten. Nicht am WROOM-Modul oder Wandler ziehen und nicht die ganze Platine biegen. Falls JLCPCB getrennte Lieferung anbietet, diese Entpanelisierung bei der Bestellung auswählen beziehungsweise bestätigen lassen; ohne vereinbarte Entpanelisierung kann der Nutzen geliefert werden.

Für das Kommentarfeld der Bestellung:

> This is a customer-designed 70 × 70 mm, 1-up routed panel with a 48 × 32 mm R2 carrier. Use the supplied profile cutouts and NPTH mouse bites. Do not add V-cuts or fill the cavities. The WROOM antenna overhangs the unit by 6 mm; its complete overhang and the USB-C front must remain clear of panel material. Assemble one copy using the panel BOM/CPL. Top-side SMT plus the catalogued EVISUN B0505S-3WR2 THT/manual solder process. ESP32-C3-WROOM-02 requires a single compatible reflow cycle; its optional central EPAD intentionally has no paste. Please preserve the specified cavity geometry and review component orientations against the assembly drawing. If depanelization is included, support the carrier, cut the perforated tabs and remove tab remnants flush; otherwise deliver the assembled panel.

Es wurde keine Bestellung ausgelöst und keine Datei an JLCPCB übertragen.
