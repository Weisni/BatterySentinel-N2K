# LCSC-Warenkorb fuer zwei Orion-R5-Platinen

Stand: 23.09.2026, live im LCSC-Gastwarenkorb zusammengestellt. Keine Bestellung ausgeloest.
Warenkorb: https://www.lcsc.com/cart (an die aktuelle Browser-Sitzung gebunden).
Ausgeschlossen: MCU1 (ESP32-C3 SuperMini), J1 (NMEA-Kabel/Stecker), TP1 (unbestuecktes Kupferpad).

## Bauteile und tatsaechliche Bestellmengen

Die Mengen wurden von LCSC auf Mindestbestellmengen angehoben. Zeilenpreise enthalten angezeigte Produktrabatte; Rundung auf Cent.

| Referenzen | LCSC | Herstellerteilenummer | Bedarf fuer 2 | Warenkorbmenge | EUR | Status |
|---|---|---|---:|---:|---:|---|
| U1 | C2671714 | ISO1042DWVR | 2 | 2 | 4.31 | Lagernd |
| U2 | C7500927 | B0505S-3WR2 | 2 | 2 | 2.39 | Lagernd |
| U3,U4 | C2071056 | AP63205WU-7 | 4 | 4 | 1.49 | Lagernd |
| D3 | C28933048 | PESD2CAN24T-QR | 2 | 5 | 0.49 | Lagernd |
| L1 | C76584 | ACT45B-510-2P-TL003 | 2 | 2 | 1.04 | Nachbestellung; Preis/Liefertermin zu bestaetigen |
| C22,C23,C27,C32,C33 | C12891 | CL31A226KAHNNNE | 10 | 20 | 3.16 | Lagernd |
| C20,C21 | C138687 | CL32B106KBJNNNE | 4 | 4 | 1.17 | Lagernd |
| D5 | C14238 | SS26 | 2 | 20 | 0.54 | Lagernd |
| C4,C5,C24,C26,C28,C30,C31 | C14663 | CC0603KRX7R9BB104 | 14 | 50 | 0.56 | Lagernd |
| D1 | C152104 | SMBJ18A | 2 | 10 | 0.56 | Lagernd |
| C25,C29,C34 | C15850 | CL21A106KAYNNNE | 6 | 20 | 1.42 | Lagernd |
| R3,R4 | C23140 | 0603WAF330JT5E | 4 | 100 | 0.23 | Lagernd |
| R2 | C25804 | 0603WAF1002T5E | 2 | 100 | 0.17 | Lagernd |
| F1 | C3032873 | SF-1206S080-2 | 2 | 5 | 0.80 | Lagernd |
| R20,R21 | C4258541 | RNCP1206FTD150R | 4 | 20 | 0.54 | Lagernd |
| SW3 | C963206 | MK-12C02-G020 | 2 | 5 | 0.53 | Lagernd |
| L2,L3 | C167874 | FNR4030S4R7MT | 4 | 10 | 0.70 | Lagernd; Ersatz fuer Sunlord C57269 |

## Direkter Preisvergleich

| Position | JLCPCB PCBA, 2 Stueck | Selbstbestueckung, 2 Stueck |
|---|---:|---:|
| Bauteile inklusive Mindestmengen, nach Rabatt | enthalten | 20,10 EUR |
| LCSC-Versand nach Deutschland, Global Direct Standard Line | entfaellt | 9,79 EUR |
| LCSC-Zwischensumme | entfaellt | 29,89 EUR |
| Unbestueckte Platinen inklusive deren Versand und Steuern | enthalten | Angebot noch offen |
| Einfuhrabgaben/Steuern und ggf. Abfertigung fuer LCSC | laut Nutzer enthalten | im Warenkorb nicht abschliessend ausgewiesen |
| Gesamt inklusive Steuern/Versand | 142,00 EUR laut Nutzer | noch kein verbindlicher Gesamtpreis |

Rein rechnerisches Szenario: 29,89 EUR plus 19 Prozent = 35,57 EUR. Das ist KEIN bestaetigter Endpreis und enthaelt keine etwaigen Zoll-/Abfertigungsgebuehren oder Leiterplatten. Die sichtbaren 3,49 EUR fuer fuenf Leiterplatten aus dem aelteren JLCPCB-Screenshot sind kein Endpreis inklusive Versand/Steuern. Eigene Arbeitszeit und Loetverbrauchsmaterial sind ebenfalls nicht enthalten.

## Beschaffung und Ersatzteilpruefung

- L1 C76584 liegt im Warenkorb als Backorder (0 auf Lager); Preis 1,04 EUR fuer 2 ist vorlaeufig. LCSC verlangt Anmeldung fuer die Nachbestellung/Anfrage. Keine Anfrage an Lieferanten wurde versendet.
- Sunlord SWPA4030S4R7MT / C57269 wurde weder in LCSC-Suche noch Warenkorb gefunden. Ersatz im Warenkorb: cjiang FNR4030S4R7MT / C167874.
- cjiang-Datenblatt: Abmessungen 4,0 x 4,0 mm, Hoehe max. 3,0 mm; empfohlenes Land Pattern Luecke 1,9 mm, Padbreite 1,1 mm, Padhoehe 3,7 mm. Dies entspricht dem vorhandenen SUNLORD_SWPA4030-Footprint.
- Elektrische Daten laut cjiang-Datenblatt Seite 10: 4,7 uH +/-20%, DCR max. 78 mOhm / typ. 60 mOhm, Isat 2,90 A / typ. 3,20 A, Irms 2,00 A / typ. 2,30 A. Uebereinstimmung mit den vorgesehenen Sunlord-Kenndaten. Datenblatt: https://www.lcsc.com/datasheet/C167874.pdf
- Die Altium-Dateien und die JLCPCB-BOM wurden nicht geaendert; Ersatz gilt fuer diesen LCSC-Warenkorb.

## Aktueller Altium-Nachweis

Vorhandener Bericht `Project Outputs/Design Rule Check - BatterySentinel-N2K-Orion-R5.drc`, 23.09.2026 20:41:53: 0 Violations Detected, 0 Waived Violations.
Aktueller ZIP-Export `Project Outputs/BatterySentinel-N2K-Orion-R5.zip` enthaelt Gerber, NC-Drill, BOM, Pick-and-Place, STEP, Schaltplan-PDF und DRC-Bericht. Export-Pick-and-Place ist vom 23.09.2026 20:53.
Dies ist eine Pruefung der vorliegenden Berichte und Exportinhalte, kein neu ausgefuehrter Altium-DRC.
