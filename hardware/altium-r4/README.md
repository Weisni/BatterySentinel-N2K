> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](../../docs/internal/README.md).

# Orion Bridge R4

**Historischer Stand – für diesen Auftrag zurückgezogen.** R4 verwendet ein WROOM-Modul statt des vom Nutzer geforderten ESP32-C3 SuperMini. Die folgenden Daten dokumentieren den bisherigen Arbeitsstand und sind für diesen Auftrag keine Bestellfreigabe. Die Korrektur erfolgt separat in [R5](../altium-r5/README.md); siehe [Release-Status](../../output/releases/RELEASE-STATUS.md).

Kompakte, galvanisch getrennte NMEA-2000/Bluetooth-Bridge mit direkt verlötetem **ESP32-C3-WROOM-02-N4**. Die Trägerplatine misst **48 × 32 mm**, die vier Ecken haben **2 mm Radius**. Gegenüber R3 mit 54 × 36 mm sinkt die Fläche um rund **21 %**. Die Modulantenne steht 6 mm über die Platinenkante. Einschließlich Antenne und USB-Gehäuse beträgt der bestückte Umriss laut STEP-Modell **48 × 38,485 mm**; die gesamte Modellhöhe einschließlich der Anschlüsse beträgt 12,83 mm. Es gibt keine ESP-Pinheader.

## Dateien öffnen und bestellen

- **Altium:** `Orion-Bridge-R4.PrjPcb` öffnen. Zwei Schaltplanseiten, geroutete native PCB-Datei und lokale `Orion-Bridge.SchLib`/`Orion-Bridge.PcbLib` gehören zusammen. Designatoren, eindeutige Komponenten-IDs, Footprints, Hersteller- und LCSC-Referenzen sind hinterlegt.
- **Schaltplan:** `Schaltplan-R4.pdf` enthält Versorgung/CAN und MCU/USB auf zwei Seiten.
- **Mechanik:** `models/Orion-Bridge-assembly.step` enthält die bestückte Platine. Die Modelle bilden lokale Gehäusehüllen und Anschlüsse ab; sie sind keine herstellerzertifizierten STEP-Modelle. Ansichten liegen in `3d-views`.
- **JLCPCB PCBA:** ausschließlich den zusammengehörigen Datensatz aus `JLCPCB-Panel` verwenden. Dort liegen Gerber-ZIP, BOM und CPL für einen **70 × 70 mm Fertigungsrahmen mit einer Platine**. Die Bestückungskoordinaten beziehen sich auf diesen Rahmen. Die genauen Einstellungen stehen in `panel-ordering.md`.
- **Firmware:** `FIRMWARE.md` beschreibt das gebaute PlatformIO-Profil `orion_r4`, USB-Erstprogrammierung und BOOT/RESET.

Der Ordner `manufacturing` enthält zusätzlich die Fertigungsdaten der Einzelplatine. Dessen CPL darf nicht mit Panel-Gerbern kombiniert werden. `source` enthält die reproduzierbare ASCII-Quelle der nativen PCB-Datei; das Projekt verwendet die anschließend in Altium gespeicherte Binärdatei.

## Aufbau und Bestückung

52 Komponentenpositionen, davon 50 zu bestücken. J1 ist der Lötanschluss für die fünf Busadern; TP1 ist eine Schirm-Kupferfläche. Beide sind absichtlich aus der Einkaufsstückliste ausgeschlossen. Ein Kabel beziehungsweise ein NMEA-Stecker wird anschließend manuell angeschlossen. Die Leiterplatte enthält keinen zusätzlichen Bus-Abschlusswiderstand.

NET_S ist die positive Busversorgung, vorgesehen für **9–16 V gegen GND_BUS**. Verpolschutz, TVS und 5-V-Schaltregler speisen den isolierten 5-V-Wandler; ein zweiter Regler erzeugt 3,3 V für ESP und die Logikseite des CAN-Isolators. USB und isolierte Versorgung sind mit Dioden entkoppelt. Die vorläufige NMEA-Leistungsreservierung beträgt LEN 12 (600 mA). Herleitung und Bauteilprüfung: `electrical-review.md`.

Für JLCPCB: zwei Lagen, FR-4, 1,6 mm, 1 oz, grüner Lötstopplack, ENIG und **Standard PCBA, Oberseite**. Der isolierte SIP-Wandler wird im THT-/manuellen Prozess bestückt. Der zentrale optionale ESP-GND-Pad erhält absichtlich keine Paste; die seitlichen Massekontakte werden verlötet. Das Reflowprofil muss zum WROOM-Modul passen. Das fertige Modul benötigt nach der Bestückung noch die Firmware.

## Layout und Prüfungen

Die Leiterplatte verwendet 0,15 mm Mindestabstand für Signalkupfer, 0,20 mm reguläre Signalleiterbahnen, 0,15 mm USB-Leiterbahnen, 0,60/0,30 mm Vias und mindestens 0,30 mm Kupferabstand zum gefrästen Rand. Bus- und Logik-Kupfer bleiben auf beiden Lagen mindestens 3,2 mm getrennt. Hauptversorgungen sind breiter geroutet; die USB-Datenleitungen liegen über durchgehender Logikmasse. Die Zweilagenplatine wird nicht als impedanzkontrolliertes 90-Ω-Design angeboten.

Native Altium-Regeln umfassen Leiterbahnbreiten, Kurzschluss/offene Netze, isolationsabhängige Abstände, Bohrungen und Restringe, Boardrand, Lötstopp/Paste, Bestückungsdruck und Bauteilabstand. Die zusätzlichen unabhängigen Prüfprogramme lesen die tatsächlich erzeugten Schaltplan-, Bibliotheks-, PCB-, Gerber- und Bohrdaten wieder ein; Stückliste und Koordinaten werden ebenfalls abgeglichen. Die abschließenden Ergebnisse und Dateihashes stehen in `release-validation.json`.

Die Fertigungsdaten sind für eine erste bestückte Revision vorgesehen. Elektrische Funktion, Temperatur bei Funkbetrieb und Lastwechseln sowie EMV wurden noch nicht an einer realen R4-Platine gemessen. Ein bestandener Layoutcheck ist keine NMEA-Zertifizierung. Bei der Bestellung sind verfügbare Bauteile und deren Orientierung in JLCPCBs Bestückungsvorschau mit dem mitgelieferten Bestückungsplan abzugleichen.

Es wurde keine Datei an JLCPCB übertragen und keine Bestellung ausgelöst.
