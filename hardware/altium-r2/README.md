> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](../../docs/internal/README.md).

# Orion Bridge R2 – Altium Designer

Öffne **[Orion-Bridge-R2.PrjPcb](Orion-Bridge-R2.PrjPcb)** in Altium Designer. R2 enthält einen gegliederten Schaltplan mit Bauteilsymbolen, lokale Symbol- und Footprintbibliotheken und ein **unverdrahtetes PCB-Grundlayout mit 80 × 60 mm**. Die Bibliotheken gehören zum Projekt; ein Altium-365-Workspace oder eine externe Komponentenbibliothek ist dafür nicht erforderlich.

**Stand: Entwicklungsentwurf, keine Fertigungsfreigabe.** Schaltplan, SchLib mit allen 24 Komponenten und die finale PcbLib wurden in Altium Designer 26.10.1 geöffnet; die Validierung des Schaltplan-zu-PCB-ECO meldete keine Fehler. Die SchLib zeigt verknüpfte Footprintvorschauen einschließlich des vollständigen 16-poligen SuperMini. Das Library Package wurde am 21.09.2026 um 20:15:41 Uhr erfolgreich zur mitgelieferten `.IntLib` kompiliert; Altium meldete „Compile successful, no errors found.“ Die unabhängige Dateiprüfung bestand 8.897 Prüfungen. Das bestätigt Dokumentverknüpfungen und Netzzuordnungen, ersetzt aber weder ERC/DRC noch die elektrische, thermische und mechanische Prüfung der Hardware.

## Dateien und Umfang

| Datei | Inhalt |
| --- | --- |
| [Orion-Bridge-R2.PrjPcb](Orion-Bridge-R2.PrjPcb) | PCB-Projekt mit relativen Verweisen auf Schaltplan, PCB und beide Bibliotheken |
| [Orion-Bridge-R2.SchDoc](Orion-Bridge-R2.SchDoc) | Ein gegliedertes Schaltplanblatt mit 28 Bauteilinstanzen und 21 Netzen |
| [Orion-Bridge-R2.PcbDoc](Orion-Bridge-R2.PcbDoc) | Platinenkontur, Platzierung und Netzzuordnungen; 92 Pad-/Bohrungsobjekte einschließlich drei Befestigungsbohrungen |
| [Orion-Bridge.SchLib](Orion-Bridge.SchLib) | Native binäre Altium-Bibliothek mit 24 wiederverwendbaren Bauteilen, Symbolen, Pins, Parametern und Footprintverweisen |
| [Orion-Bridge.PcbLib](Orion-Bridge.PcbLib) | Native binäre Altium-Bibliothek mit 20 Footprints |
| [Orion-Bridge.LibPkg](Orion-Bridge.LibPkg) | Optionales Library Package mit beiden Quelldateien zum Kompilieren einer `.IntLib` in Altium |
| [Orion-Bridge.IntLib](<Project Outputs/Orion-Bridge.IntLib>) | In Altium kompilierte integrierte Bibliothek zum direkten Weitergeben und Installieren |
| [orion-r2-design.json](orion-r2-design.json) | Erzeugtes Datenmodell mit Bauteilen, Pins, Netzen, Bibliothekskennungen und Platzierung |
| [supermini-nologo.json](supermini-nologo.json) | Hergeleitete 16-polige SuperMini-Belegung, Headergeometrie und Primärquellen |
| [Schaltplan-R2-Vorschau.pdf](Schaltplan-R2-Vorschau.pdf) / [PNG](Schaltplan-R2-Vorschau.png) | Vorschau aus den erzeugten Schaltplanobjekten; kein Altium-Export |
| [REFERENCES.md](REFERENCES.md) | Datenblätter, Quellen und Herkunft der Bibliotheksgeometrien |

Identische Bauteile teilen sich einen Bibliothekseintrag: beispielsweise R3/R4 mit 33 Ω und C4/C5/C7 mit 100 nF, 16 V, X7R. Dadurch ergeben 28 platzierte Bauteile 24 Bibliothekskomponenten. Die Funktionen von R3/R4 sind als Instanzparameter `Role` hinterlegt.

## Bibliotheken verwenden und bearbeiten

Alle Dateien im gemeinsamen Ordner belassen. Im PCB-Projekt sind beide Bibliotheken bereits aufgeführt. Die Symbole verweisen über ihre `LibReference` auf die SchLib und über ihr Footprintmodell auf den passenden Namen in `Orion-Bridge.PcbLib`. Pin- und Padbezeichnungen stimmen überein, einschließlich aller 16 Anschlüsse von MCU1. Die PCB-Komponenten tragen zugehörige Quellbibliotheksreferenzen und stabile Komponenten-IDs.

Die `.SchLib` zum Bearbeiten der Bauteile und die `.PcbLib` zum Bearbeiten der Footprints öffnen. Nach Änderungen die betroffenen platzierten Bauteile aus der Bibliothek aktualisieren und den Schaltplan-zu-PCB-ECO prüfen. Änderungen an Pin-/Padnummern oder Footprintnamen müssen auf beiden Seiten zusammenpassen. R3 und R4 verwenden denselben Bibliothekseintrag; instanzspezifische Angaben gehören deshalb in die platzierten Bauteile.

Der abschließende native ECO-Abgleich erkennt alle vorhandenen Komponenten und Netzzuordnungen. Er schlägt noch die Übernahme zusätzlicher Bauteilparameter wie Datenblatt und Hersteller in das PCB vor; diese Änderungen wurden erfolgreich validiert, aber nicht ausgeführt. Sie lassen sich bei Bedarf mit „Execute Changes“ übernehmen.

Das zusätzliche [Orion-Bridge.LibPkg](Orion-Bridge.LibPkg) bündelt dieselben beiden Quelldateien. Es kann separat geöffnet und über die Kompilierfunktion des Library-Package-Projekts als `.IntLib` gebaut werden. Die erfolgreich kompilierte [Orion-Bridge.IntLib](<Project Outputs/Orion-Bridge.IntLib>) liegt bereits bei und kann direkt weitergegeben beziehungsweise in Altium als dateibasierte Bibliothek installiert werden. Die SchLib und PcbLib bleiben die bearbeitbaren Quellen; nach deren Änderung die IntLib neu kompilieren. Zum Weiterarbeiten am PCB-Projekt ist dieser zusätzliche Verpackungsschritt nicht erforderlich. [Altium beschreibt dieses Zusammenspiel von SchLib, PcbLib und LibPkg](https://www.altium.com/documentation/altium-designer/components-libraries/file-based-libraries).

## Hersteller- und Lieferantendaten

Die Bibliothekskomponenten enthalten die Parameter `Manufacturer`, `MPN`, `Manufacturer Part Number`, `Description`, `Datasheet` und `Footprint Status`. Bekannte Herstellerteile wie ISO1042, R3M, TPS7B69 und DMP6023LE sind mit ihren Herstellerangaben und Datenblättern versehen. Bei generischen Bauteilen bleiben Hersteller, Bestellnummer und Datenblatt leer, bis ein konkretes Teil ausgewählt ist. Eine Gehäusebezeichnung oder ein Nennwert ist noch keine vollständige Beschaffungsspezifikation.

**`Supplier 1` und `Supplier Part Number 1` sind bewusst leer.** Diese Felder können nach eigener Lieferantenauswahl in der SchLib und anschließend in den platzierten Bauteilen gepflegt werden. Es werden keine Lieferantenverknüpfungen oder Preise vorausgesetzt.

## SuperMini und offene Auslegung

MCU1 besitzt einen vollständigen Footprint für das **Nologo ESP32-C3 SuperMini mit zwei 1×8-Stift- oder Buchsenleisten**. Die Referenz hat 15,24 mm Reihenabstand und 2,54 mm Raster. Die Trägerplatine verwendet 1,8-mm-Pads mit 1,0-mm-Bohrung als Ausgangspunkt für übliche 0,64-mm-Vierkantstifte. Dies ist kein Footprint zum direkten Auflöten kastellierter Modulränder. Alle 16 Modulanschlüsse sind vorhanden; die elf ungenutzten GPIOs haben kein Netz und eine entsprechende Schaltplan-Direktive.

Vor dem Routing und der Fertigung sind folgende Punkte zu klären:

- **Tatsächliches Modul prüfen:** SuperMini-Klone können abweichende Belegung oder Mechanik haben. Ausgewähltes Modul, Stift-/Buchsenleisten, Einbauhöhe, USB-Überstand und Gehäusefreiraum mit der dokumentierten Nologo-Referenz abgleichen. Den Antennenbereich beim Routing freihalten und am realen Modul prüfen.
- **Bestellteile festlegen:** Besonders J1, F1, L2, C1 und C6 besitzen vorläufige Geometrien. Konkrete Teile auswählen und deren Landpatterns, Bohrungen, Toleranzen, Nennwerte und Bauhöhen abgleichen. Das gilt auch für JP1 und die übrigen generischen Bauteile. `TBD` im Footprintnamen kennzeichnet einen offenen Entwurf.
- **Versorgung nachweisen:** U2 benötigt mindestens 9 V nach Schutz- und Filterverlusten. Ein Betrieb bei genau 9 V am NMEA-Anschluss ist damit nicht zugesichert. Bei U3 Wärmeabfuhr und wirksame Ausgangskapazität unter Betriebsspannung prüfen.
- **Routing abschließen:** Es gibt noch keine Kupferverdrahtung und keine gegossenen Masseflächen. Isolationsabstände, Antennenfreiraum, Versorgung, CAN-Leitungsführung und Wärmeabfuhr müssen im fertigen Layout geprüft werden. Am R3M beträgt der innere Padabstand nur 3,8 mm. Anschließend ERC/DRC, Hardwaretests und die Prüfung der Fertigungsdaten durchführen.

Die Massebereiche bleiben getrennt: `GND_BUS` ist NET-C, `GND_LOGIC` gehört zu SuperMini/USB. U1 und U2 übertragen Signal beziehungsweise Energie über die Isolationsgrenze. `SHIELD` bleibt separat. Auf dieser NMEA-Drop-Platine ist kein zusätzlicher 120-Ω-Abschluss vorgesehen.

**USB-Service:** Im NMEA-Betrieb JP1 schließen und USB abziehen. Zum Service zuerst JP1 öffnen, danach USB anschließen. D2 ersetzt keine automatische Umschaltung zwischen USB- und Busversorgung.

## Reproduzieren und prüfen

Im Repository-Verzeichnis ausführen:

```text
python tools/build_altium_r2.py
python tools/verify_altium_r2.py
```

Der Generator benötigt Python, PowerShell 7 (`pwsh`) und die mit Altium installierte `OpenMCDF.dll` zum Schreiben der nativen binären Bibliothekscontainer. Standardpfad: `C:/Program Files/Altium/AD25/System/OpenMCDF.dll`; ein anderer Pfad kann mit der Umgebungsvariablen `ALTIUM_OPENMCDF_DLL` gesetzt werden. Dabei wird Altium nicht gestartet.

**Eine erneute Generierung überschreibt die R2-Entwurfsdateien einschließlich Bibliotheken und Datenmodell.** Manuelle Änderungen aus Altium und ergänzte Lieferantendaten vorher sichern oder in einen eigenen Projektordner übernehmen. Änderungen nur an der erzeugten JSON-Datei bleiben beim nächsten vollständigen Build nicht erhalten. R1 wird durch diesen Generator nicht überschrieben.

Der Verifier liest Schaltplanverbindungen, Stromversorgungsobjekte, Pin-/Padzuordnungen, eindeutige IDs, Projektverweise und native Bibliotheksdaten unabhängig zurück. Er prüft auch die SuperMini-Geometrie gegen die dokumentierte Herstellerquelle. Die Prüfung ist für die erzeugten ASCII-SchDoc/PcbDoc-Dateien vorgesehen; nach einer Altium-Konvertierung ins Binärformat ist die erneute Prüfung in Altium maßgeblich. Die bestandenen 8.897 Prüfungen beziehen sich auf den erzeugten R2-Ausgangsstand. Eine Regenerierung der Quellen baut die IntLib nicht automatisch neu; dafür das Library Package wieder in Altium kompilieren.
