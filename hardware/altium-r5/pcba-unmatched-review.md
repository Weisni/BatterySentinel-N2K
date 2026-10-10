# JLCPCB-Zuordnung F1, R20 und R21

Geprüft am 23.09.2026. Recherche und Stücklisten-Zuordnung; keine Schaltungs-, PCB- oder Bauteiländerung.

**Zunächst die vorhandenen Bestellnummern manuell zuordnen.** Die drei Positionen sind mit konkreten Herstellerteilen im R5-Modell vorhanden. „Unmatched“ allein belegt keinen elektrischen Fehler und keine notwendige Substitution.

| Position | Herstellerteil | JLC/LCSC-Code | Beurteilung |
|---|---|---|---|
| F1 | Bourns SF-1206S080-2 | [C3032873](https://jlcpcb.com/partdetail/C3032873) | Vorhandenes Bauteil beibehalten; träge 0,8-A-Einmalsicherung, 63 VDC, 1206. |
| R20, R21 | Stackpole RNCP1206FTD150R | [C4258541](https://jlcpcb.com/partdetail/C4258541) | Vorhandenes Bauteil beibehalten; 150 Ω, ±1 %, 0,5 W, 1206. |

Die frisch abgerufenen öffentlichen JLC-Seiten bestätigen für beide Nummern SMT-Bestückung sowie Economic/Standard-PCBA, ohne zusätzliche Fixture- oder Audit-Markierung. **Ein sofort verfügbarer interner PCBA-Lagerbestand wurde nicht verlässlich nachgewiesen.** Insbesondere enthält der F1-Datensatz 73 Stück im Feld `overseasStockCount` und eine Mindest-Vorbestellmenge von 52 Stück. Diese Werte sind keine Zusicherung sofort verfügbarer Hausbestände oder der Lieferbarkeit für eine konkrete Bestellmenge. Das allgemeine JSON-LD-Merkmal `InStock` wird hier ausdrücklich nicht als Lagerreservierung interpretiert.

Die F1-Landflächen im R5-Modell entsprechen dem Bourns-Vorschlag: Außenabstand 4,7 mm, Innenabstand 2,2 mm, Breite 1,65 mm; daraus zwei Flächen von 1,25 × 1,65 mm. Die Sicherung ist nicht polarisiert. Trotz teilweise missverständlicher Katalogkategorisierung ist SF-1206S080-2 eine einmalige Schmelzsicherung und kein rückstellender PTC. [Bourns-Herstellerdatenblatt SF-1206S](https://www.bourns.com/docs/product-datasheets/sf-1206s.pdf).

RNCP1206FTD150R ist bereits der ausgewählte 0,5-W-Typ und benötigt daher weder neue Pads noch eine geänderte Leiterplatte. Ein gewöhnlicher 1206-Widerstand mit nur 0,25 W ist kein gleichwertiger Ersatz für die festgelegte Vorlast. [Stackpole-Herstellerdatenblatt, über LCSC](https://wmsc.lcsc.com/wmsc/upload/file/pdf/v2/lcsc/2404111532_SEI-Stackpole-Elec-RNCP1206FTD150R_C4258541.pdf).

Als weitere JLC-Katalogkandidaten wurden TE **CRGP1206F150R / C2074442** und Yageo **AC1206FR-7W150RL / C7066059** mit 150 Ω, ±1 %, 0,5 W, 1206 sowie SMT Economic/Standard identifiziert. Sie werden hier weder als aktuell lagernde Ersatzteile freigegeben noch ohne zusätzlichen Hersteller-Landpatternvergleich ausgetauscht. Die konkrete Zuordnung der vorhandenen Nummer C4258541 ist der bevorzugte erste Schritt.

Im JLC-Matching nach der **C-Nummer** suchen; die frei gewählten Footprintnamen `BOURNS_SF1206S` und `R1206` beziehungsweise die Werte `T0.8A 63VDC` und `150R 1% 0.5W` sind keine Hersteller-Bestellnummern. Die abschließende Verfügbarkeit und gegebenenfalls Vorbestellung zeigt die konkrete PCBA-Bestellung.
