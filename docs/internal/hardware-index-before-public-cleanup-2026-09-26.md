# Project-internal development snapshot

This preserved text records engineering concepts and previous documentation, not existing or released product variants. Unbuilt hardware and the measurement concept are project-internal. Use the current project README and user manuals for the Orion Bridge.

---

# BatterySentinel-N2K · Orion-R5

## Current procurement status - 2026-09-25

The user confirms that all parts have been ordered and PCB manufacture has been commissioned. Delivery, assembly and first commissioning of the complete R5 hardware are pending. [The procurement report](../../hardware/altium-r5/lcsc-order-2026-09-24.md) records the four-board component quantities, costs and remaining physical checks. Ordering does not complete the module-fit, power, thermal, enclosure or NMEA/Garmin acceptance checks.

The user has completed the native Altium design. The existing exported DRC report records zero violations and zero waived violations; the manufacturing ZIP was exported on 2026-09-23. This records the supplied reports, not a newly executed DRC. The older planning notes below are historical.

Next: inspect the delivered parts, verify the [selected SuperMini](../../hardware/altium-r5/module-selection.md) against the actual module, follow the [current sealed-enclosure assembly guide](../../hardware/altium-r5/enclosure/sealed-print/README.md), and record commissioning results using the [German operating and installation manual](../../output/pdf/BatterySentinel-N2K-Orion-R5-Betriebs-und-Installationsanleitung-DE.pdf).

## Historical procurement and planning notes (superseded)

The following notes preserve earlier design and cart checks. Their open-order and pre-fabrication statements are superseded by the current status above; use the current assembly references for the delivered hardware.

The [LCSC procurement check](../../hardware/altium-r5/lcsc-order-2026-09-24.md) documents a cart with 17 in-stock component types for two boards, including the L1 substitution, quantity limits, and remaining checkout/physical assembly checks. Cart total including estimated shipping is EUR 30.35; PCB plus stencil is EUR 45.75 according to the user. No order was placed and no Altium file was modified during this procurement check.

In Arbeit: Korrektur auf den vom Nutzer vorgegebenen ESP32-C3 SuperMini und gemeinsames Design von Leiterplatte und 3D-Druckgehäuse. **Noch keine Fertigungsfreigabe.**

## Verbindliche Anforderungen

- ESP32-C3 SuperMini beibehalten; kein Ersatz durch ein WROOM-Modul ohne ausdrückliche Abstimmung.
- Die mechanische Schnittstelle muss zur tatsächlichen SuperMini-Variante passen. Die bisherige vereinfachte Nologo-CAD-Datei beschreibt die inneren Durchkontaktierungen; zusätzliche äußere Kontakte sind in Produktdarstellungen sichtbar. Ein genauer Footprint für direkte Verlötung ist daraus noch zu verifizieren.
- Leiterplatte platzsparend mit gerundeten Ecken, definierten Befestigungspunkten und Freiräumen für Schrauben und Gehäusestützen.
- Native, bearbeitbare TrueType-Beschriftung statt aus kantigen Strichen zusammengesetzter Schrift. Fertigungsdaten müssen dieselbe sichtbare Schrift wiedergeben.
- Sichtbare Projektkennzeichnung: `BatterySentinel-N2K` und `Orion-R5`.
- Ein gemeinsames, originales Battery-Sentinel-Logo für Leiterplatte und Gehäuse.
- Druckbares, verschraubtes Gehäuse mit zugänglichem USB-Anschluss, Kabelzugentlastung und Gehäusebefestigung. Keine unbelegte Schutzartangabe.
- Schaltplan, PCB, Stückliste, Bestückungsdaten, 3D-Baugruppe und Gehäuse gemeinsam prüfen.

Die bisherigen R4-Bestellpakete wurden für diesen Auftrag zurückgezogen, weil sie die falsche Modulvariante enthalten. Sie bleiben als historische Daten erhalten.

## Vorliegende Entwürfe

- [Logo und abgerundete Projektbeschriftung](../../assets/branding/branding-preview.png): eigenes Batterie-/Schutzschild-Zeichen, `BatterySentinel-N2K` und `Orion-R5`. [Vektordaten und native Altium-Textanbindung](../../assets/branding/README.md) verwenden dieselben Formen für PCB und Gehäuse.
- [Native Altium-Beschriftungsprobe](../../hardware/altium-r5/typography/R5-Beschriftungsprobe.PcbDoc): echte editierbare TrueType-Texte, in Altium geöffnet, visuell geprüft und nativ gespeichert. Das ist ein separater Typografie-Test, keine fertige Leiterplatte.
- [Gehäuse geschlossen](../../hardware/altium-r5/enclosure/enclosure-closed.png) und [Explosionsansicht](../../hardware/altium-r5/enclosure/enclosure-exploded.png): parametrierter mechanischer Entwurf mit verschraubtem Deckel, vier gemeinsamen Platinen-/Deckelbefestigungen, Montagelaschen und Kabelklemmung. Die grüne Fläche ist eine unbestückte Planungsplatine, kein fertiges R5-Layout. [CAD und Maßannahmen](../../hardware/altium-r5/enclosure/README.md).
- [SuperMini-Prüfung](../../hardware/altium-r5/supermini-review.md): belegte Anschlusspositionen, Versorgung und Montagebedingungen sowie die noch fehlenden Maße für direkte Lötmontage. Der Name SuperMini allein legt diese mechanische Schnittstelle nicht eindeutig fest.

## Noch offen

Benötigt wird die genaue Ausführung des tatsächlich verwendeten ESP32-C3 SuperMini, idealerweise über den Produktlink. Daraus folgen Randpad-Geometrie, USB-Ausschnitt, Montagehöhe und Antennenfreiraum. Der Gehäuseentwurf nimmt bisher einen trockenen, geschützten Einbau an.

Erst auf dieser Grundlage folgen der überarbeitete verknüpfte Schaltplan, die endgültige Platzierung und Verdrahtung sowie neue ERC-/DRC- und mechanische Prüfungen. Die R4-Prüfberichte gelten nicht für R5. Es gibt hier noch keinen fertig gerouteten R5-Stand und keine R5-Bestelldaten.
