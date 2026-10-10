# R4 – JLCPCB-Fertigung und Bauteilbeschaffung

Stand: 23.09.2026. Diese Prüfung dokumentiert Bauteilauswahl und Fertigungsvorgaben. Sie ersetzt keine Freigabe der konkreten Gerber- und Bestückungsvorschau oder den elektrischen Prototypentest.

## Bestellprozess

Empfohlen: **Standard PCBA, einseitige Bestückung**, FR-4, 1,6 mm, 1 oz, grüner Lötstopplack, ENIG. Das kleine Einzelboard bleibt klein; für Standard PCBA wird ein Fertigungsnutzen mit abtrennbaren Rändern benötigt. JLCPCB nennt mindestens 70 × 70 mm für Board beziehungsweise Nutzen und verlangt Ränder und Fiducials. Gemischte SMD/THT-Bestückung wird angeboten; der isolierte Wandler ist bei JLCPCB als manuell zu lötendes Bauteil hinterlegt. [JLCPCB PCBA-Fähigkeiten](https://jlcpcb.com/capabilities/pcb-assembly-capabilities), [EVISUN C7500927](https://jlcpcb.com/partdetail/C7500927).

Der konkrete Upload-Weg mit dem erzeugten 70×70-mm-Kundenpanel steht in `panel-ordering.md`. Panel-Gerber und Panel-CPL gehören zusammen; der Rahmen wird nach der Bestückung entfernt. Die Altium-Einzelplatine bleibt 48×32 mm groß.

Der Grund für Standard ist insbesondere das Temperaturprofil: JLCPCB nennt 255 ± 5 °C für Economic, unveränderlich, und 240 ± 5 °C für Standard. Espressif erlaubt beim WROOM-02 einen Reflowdurchlauf mit 235–250 °C Spitze. Daher das Profil mit der Fertigung auf die bestückten Bauteile abstimmen. Ein bereits castelliertes Modul auf normalen SMD-Lands bedeutet **keine castellierten Bohrungen im neu gefertigten Trägerboard**. [JLCPCB](https://jlcpcb.com/capabilities/pcb-assembly-capabilities), [Espressif-Datenblatt](https://documentation.espressif.com/esp32-c3-wroom-02_datasheet_en.pdf).

## Verifizierte Stückliste

Hersteller, MPN, JLC-Nummer und die aktuelle öffentliche `InStock`-Metadatenangabe wurden direkt auf den verlinkten JLCPCB-Seiten geprüft. Diese Angabe reserviert keinen Lagerbestand und garantiert keine bestimmte Stückzahl zum Bestellzeitpunkt. Öffentliche Bestandzahlen und Suchmaschinen-Snapshots dürfen nicht mit im eigenen Account reservierten Beständen gleichgesetzt werden.

| Position/Funktion | Hersteller und MPN | JLCPCB |
|---|---|---|
| MCU1 | Espressif ESP32-C3-WROOM-02-N4 | [C2934560](https://jlcpcb.com/partdetail/C2934560) |
| U1 | TI ISO1042DWVR | [C2671714](https://jlcpcb.com/partdetail/C2671714) |
| U2 | EVISUN B0505S-3WR2, 3 W, SIP | [C7500927](https://jlcpcb.com/partdetail/C7500927) |
| U3 | Diodes AP63205WU-7, 5 V | [C2071056](https://jlcpcb.com/partdetail/C2071056) |
| U4 | Diodes AP63203WU-7, 3,3 V | [C780769](https://jlcpcb.com/partdetail/C780769) |
| L1 | TDK ACT45B-510-2P-TL003 | [C76584](https://jlcpcb.com/partdetail/C76584) |
| L2/L3 | Sunlord SWPA4030S4R7MT, 4,7 µH | [C57269](https://jlcpcb.com/partdetail/C57269) |
| F1 | Bourns SF-1206S080-2, 0,8 A/63 V | [C3032873](https://jlcpcb.com/partdetail/C3032873) |
| D1 | BORN SMBJ18A | [C152104](https://jlcpcb.com/partdetail/C152104) |
| D2/D4 | MDD SS14, 1 A/40 V | [C2480](https://jlcpcb.com/partdetail/C2480) |
| D5 | MDD SS26, 2 A/60 V | [C14238](https://jlcpcb.com/partdetail/C14238) |
| D3 | Nexperia PESD2CAN24T-QR | [C28933048](https://jlcpcb.com/partdetail/C28933048) |
| D6 | ST USBLC6-2SC6 | [C7519](https://jlcpcb.com/partdetail/C7519) |
| J2 | HRO TYPE-C-31-M-12, USB2.0 | [C165948](https://jlcpcb.com/partdetail/C165948) |
| SW1/SW2 | XUNPU TS-1088-AR02016, 2-polig | [C720477](https://jlcpcb.com/partdetail/C720477) |
| 10 kΩ/0603 | UNI-ROYAL 0603WAF1002T5E | [C25804](https://jlcpcb.com/partdetail/C25804) |
| 5,1 kΩ/0603 | UNI-ROYAL 0603WAF5101T5E | [C23186](https://jlcpcb.com/partdetail/C23186) |
| 22 Ω/0603 | UNI-ROYAL 0603WAF220JT5E | [C23345](https://jlcpcb.com/partdetail/C23345) |
| 33 Ω/0603 | UNI-ROYAL 0603WAF330JT5E | [C23140](https://jlcpcb.com/partdetail/C23140) |
| R20/R21, 150 Ω/0,5 W/1206 | Stackpole RNCP1206FTD150R | [C4258541](https://jlcpcb.com/partdetail/C4258541) |
| 100 nF/50 V/X7R/0603 | Yageo CC0603KRX7R9BB104 | [C14663](https://jlcpcb.com/partdetail/C14663) |
| 1 µF/50 V/X5R/0603 | Samsung CL10A105KB8NNNC | [C15849](https://jlcpcb.com/partdetail/C15849) |
| 10 µF/25 V/X5R/0805 | Samsung CL21A106KAYNNNE | [C15850](https://jlcpcb.com/partdetail/C15850) |
| 22 µF/25 V/X5R/1206 | Samsung CL31A226KAHNNNE | [C12891](https://jlcpcb.com/partdetail/C12891) |
| 10 µF/50 V/X7R/1210 | Samsung CL32B106KBJNNNE | [C138687](https://jlcpcb.com/partdetail/C138687) |

J1 ist der beschriftete Lötanschluss für das externe NMEA-Kabel; TP1 ist eine Leiterplattenfläche. Beide sind keine fiktiv bestellbaren SMD-Komponenten und gehören nicht als Bauteil in die PCBA-BOM. Das Kabel bleibt ein separates mechanisches Teil.

Der 3-W-EVISUN ist wegen der belegbaren Beschaffbarkeit gewählt. Ein SN6505B-Transformatoraufbau wurde betrachtet, aber der passende Wurth 750315371 war bei JLCPCB nicht aus Lagerbestand bestellbar. Gleichnamige B0505S-3WR2 anderer Hersteller sind ohne eigenen Pinout-/Maßabgleich kein automatischer Ersatz. [Transformator C5184247](https://jlcpcb.com/partdetail/C5184247).

## Geprüfte Geometrie und Regeln

Die JSON-Dateien enthalten Datenblattlinks, Hersteller- und Bestückungsnummern sowie die überprüften Geometrien. USB-C: aktuelle HRO-Zeichnung vom 08.12.2020; vier metallisierte Langlöcher und zwei 0,6-mm-NPTH. Das ältere KiCad-Library-Modell verwendet abweichende Maße. Die Kupferränder der Shield-Langlöcher wurden gegenüber der Herstellerempfehlung um 0,05 mm verbreitert, damit mindestens 0,20 mm Restring verbleiben. SW1/SW2: zwei Lands 1,05 × 2,00 mm bei 4,45 mm Mittenabstand. L2/L3: 1,10 × 3,70 mm Lands bei 3,00 mm Mittenabstand. D6: ST-Lands 0,60 × 1,20 mm, Reihenabstand 2,30 mm.

Empfohlene Designmargen: 0,20 mm Signalbreite und -abstand, Vias 0,60/0,30 mm, Kupfer mindestens 0,30 mm von gefräster Außenkante, 0,20 mm PTH-Restring, 0,15 mm Siebdruckstrich und Abstand zu offenen Pads, 1,0 mm Beschriftungshöhe. Lokale USB-Fanouts können bei Bedarf schmaler werden; die Datenblattlands bestimmen den Padabstand. JLCPCB veröffentlicht für zweilagig/1 oz 0,10 mm Leiterbahn/Abstand, 0,18 mm absoluten PTH-Restring, 0,50 mm minimale PTH-Schlitzbreite und 0,50 mm minimale NPTH-Bohrung. Die 0,60-mm-USB-Schlitze erfüllen die Mindestbreite und das Verhältnis Länge ≥ 2×Breite. [JLCPCB PCB-Fähigkeiten](https://jlcpcb.com/capabilities/pcb-capabilities).

Die 0,18-mm-Grenze betrifft den gesondert aufgeführten Bauteil-PTH-Restring. Für Vias führt JLCPCB eigene Regeln auf: Durchmesser mindestens 0,10 mm größer als Bohrung, bevorzugt 0,15 mm größer. Die gewählten 0,60/0,30-mm-Vias haben 0,30 mm diametrale Differenz beziehungsweise 0,15 mm radialen Restring und erfüllen diese Via-Regel. Bauteilbohrungen verwenden die strengere PTH-Regel. [JLCPCB, Abschnitte Drilling und Traces](https://jlcpcb.com/capabilities/pcb-capabilities).

Der 3,2-mm-Abstand der isolierten Domänen ist eine projektspezifische funktionale Isolationsregel, keine durch JLCPCB zugesagte Sicherheitszulassung. Antennenfreiraum und Überhang müssen auch im Fertigungsnutzen und Gehäuse berücksichtigt werden. Modelle sind lokal erstellte Gehäusehüllen, keine zertifizierten Lieferanten-STEP-Modelle.

## Übergabe an die Fertigung

- Gerber-ZIP: Kupfer, Lötstopp, Paste, Bestückungsdruck, geschlossene gerundete Außenkontur; PTH/NPTH-Excellon mit USB-Langlöchern.
- BOM: `Comment,Designator,Footprint,LCSC Part #`; Designatoren entsprechen exakt dem Layout. [JLCPCB-BOM](https://jlcpcb.com/help/article/bill-of-materials-for-pcb-assembly).
- CPL: `Designator,Mid X,Mid Y,Layer,Rotation`; Millimeter, geometrische Bauteilmitte, positive Winkel gegen den Uhrzeigersinn. [JLCPCB-CPL](https://jlcpcb.com/help/article/pick-place-file-for-pcb-assembly).
- Nach Upload die konkrete Bauteilverfügbarkeit, Pin-1-/Diodenorientierung, Modulantenne und USB-Anschluss in der JLCPCB-Bestückungsvorschau abgleichen. Die Nullwerte in `rotation_offset_deg` sind keine behauptete Verifikation der JLC-Bibliotheksorientierung.
- WROOM nur einmal reflowlöten; EPAD-Land ohne Paste ist die explizit zulässige unverlötete EPAD-Variante. Die Rand-GND-Pins bleiben elektrisch verbunden.

Eine Bestellung oder Übertragung von Projektdateien an JLCPCB wurde durch diese Recherche nicht ausgelöst.
