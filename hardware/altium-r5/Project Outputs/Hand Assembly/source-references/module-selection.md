> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](../../docs/internal/README.md).

# R5: ausgewähltes ESP32-C3 SuperMini

Ausgewählt ist **Meshnology, Variante „4 x C3“, Amazon-ASIN B0FN4F6244**. Es wird kein anderes ESP-Modul eingesetzt. Das Bauteil `MCU1` besitzt ein vollständiges 16-poliges Schaltplansymbol, einen dazu identisch nummerierten SMD-Footprint und ein lokales 3D-Modell. Der Generator ist `tools/r5_supermini.py`; Quellen-Hashes, Maße und Bauteildaten stehen in `module-selection.json`.

[Vom Nutzer ausgewähltes Produkt](https://www.amazon.de/4PCS-Supermini-ESP32-C3-Entwicklungsboard/dp/B0FN4F6244). Abruf: 23.09.2026.

## Was belegt ist

Die ausgewählte C3-Variante wird mit **18 × 22,52 mm**, ESP32C3FN4, 4 MB Flash und einseitiger SMD-Bestückung beschrieben. Das Hauptfoto zeigt die typischen C3-Bauteile, USB-C, BOOT/RESET sowie äußere Randkastellierungen neben den inneren geschlossenen Headerbohrungen. Die im Foto eingesetzten Stiftleisten gehören nicht zum R5-Montagekonzept. Das exakte OEM-Hersteller-Bestellkennzeichen und eine tolerierte mechanische Zeichnung werden nicht veröffentlicht.

Die A+-Bilder der Angebotsseite mischen Varianten: Ein Pinout zeigt einen **S3 mit GPIO48**. Dieses Bild wurde ausdrücklich verworfen und wird nur als dokumentierte Gegenprüfung aufbewahrt. Die beiden C3-Schaltplanbilder zeigen dagegen die C3-Pins und die Verbindung `USB-VBUS = 5V-Anschluss → BAT60J → VSYS → ME6211 → 3V3`. Sie sind keine mechanischen Maßzeichnungen. Die Quelldateien sind entsprechend benannt.

Die ursprüngliche [Nologo-Maßzeichnung und PcbDoc](https://github.com/NologoTech/ESP32C3-Supermini/tree/main/Hardware) liefern das **2,54-mm-Raster**, den 15,24-mm-Abstand der inneren Lochreihen und ihre Y-Positionen. Diese Referenz wurde gegen das ausgewählte C3-Foto und dessen Schaltplan verglichen. Sie wird nicht als Nachweis ausgegeben, dass Meshnology exakt derselbe Hersteller oder jede Charge identisch ist.

## Direkte Montage auf den Randpads

Koordinaten sind in mm, Draufsicht, Ursprung in der Modulmitte; USB zeigt nach **+Y**, Antenne nach **−Y**.

| Reihe ab USB | Y | Links | Rechts |
|---|---:|---|---|
| 1 | 9,7006 | GPIO5 | 5V |
| 2 | 7,1606 | GPIO6 / Carrier-TX | GND |
| 3 | 4,6206 | GPIO7 / Carrier-RX | 3V3 |
| 4 | 2,0806 | GPIO8 | GPIO4 |
| 5 | −0,4594 | GPIO9 | GPIO3 |
| 6 | −2,9994 | GPIO10 | GPIO2 |
| 7 | −5,5394 | GPIO20 | GPIO1 |
| 8 | −8,0794 | GPIO21 | GPIO0 |

Die **Carrier-Lands** liegen bei X = ±8,60 mm und sind 2,80 × 1,80 mm groß. Sie reichen nominal 1 mm über die seitliche Modulkante hinaus; zwischen Nachbarpads bleiben 0,74 mm. Das sind bewusst entworfene, großzügige Lötflächen für Handmontage, kein veröffentlichtes Hersteller-Landpattern. Alle 16 Kontakte werden gelötet, auch die elektrisch unbenutzten. Der Carrier hat dort **keine offenen Bohrungen und keine Pastenöffnungen**.

Gelieferte Stiftleisten müssen vor der Montage vollständig entfernt werden. Alte Lötüberstände werden abgenommen, damit die Unterseite plan sitzt. Das Modul wird nach der normalen Carrier-PCBA von außen an den Randpads verlötet. `assembly.populate=false` schließt es aus automatischer BOM/CPL-Bestückung aus; das fertig montierte Altium-/3D-Modell enthält es trotzdem. Eine automatische JLC-Bestückungsnummer für diese konkrete Amazon-Variante ist nicht bestätigt. Beistellung wäre ein gesondert mit dem Bestücker abzustimmender Prozess.

## Mechanische Auslegung und Freistellungen

| Maß | Modellwert | Nachweisstatus |
|---|---:|---|
| Modulgrundfläche | 18,00 × 22,52 mm | Ausgewähltes Angebot |
| Raster | 2,54 mm | Nologo-Referenz, mit C3-Foto/Pins abgeglichen |
| SMD-Land | 2,80 × 1,80 mm | Carrier-Auslegung |
| Lötspalt über Carrier | 0,10 mm | Nominale Montageannahme |
| Modulplatinenstärke | 1,00 ± 0,20 mm | Bewusst angenommene Hülle |
| USB-Mündung lokal | X=0; Y=12,65; Z=2,75 mm | Foto-/Referenzbasierte Hülle |
| USB-Lagetoleranz XYZ | ±0,50 / ±0,65 / ±0,40 mm | Auslegungsreserve, keine Lieferantentoleranz |
| USB-Hülle | 9,20 × 8,00 mm, bis Z=4,40 mm | Illustrative Hülle |
| Gehäuseöffnung | 12 × 7 mm | Stecker- und Fertigungsfreiraum |

Z=0 bezeichnet die **Oberseite der Carrier-Platine**. Das 3D-Modell besitzt keine Header und keine Abstandshalter. USB-Zungen, Schirm, Tasten, QFN und Keramikantenne sind erkennbare lokale Extrusionskörper; Farben und Detailgeometrie sind illustrativ. Das Modell ist kein zertifiziertes Hersteller-STEP.

Unter der USB-Buchse ist ein echter Carrier-Ausschnitt erforderlich. Der lokale Mindestbereich ist X=−5,3…+5,3 und Y=4,9…13,4 mm, mit mindestens 0,3 mm Kupferabstand. Er berücksichtigt unbekannte nach unten ragende Schirmbefestigungen und Lötstellen. Der R5-Layoutbereich darf größer sein und zur rechten Außenkante offen auslaufen. Unter dem übrigen Modul sitzen keine Carrier-Bauteile und keine offenliegenden Testpads oder Vias; nicht zur Antennenfreizone gehörende Leiterbahnen dürfen nur unter intaktem Lötstopp verlaufen.

Die Keramikantenne erhält ein Luftfenster durch den Carrier bei lokal X=−5…+5, Y=−11,26…−7,50 mm. Zusätzlich bleibt X=−6…+6, Y=−13,76…−5,50 mm auf **allen Kupferlagen sowie von Metall und Bauteilen frei**. Das ist eine konservative technische Reservation, keine veröffentlichte RF-Freizone des Verkäufers. Ein montiertes Modul und Gehäuse müssen im Funkbetrieb geprüft werden.

Bei Carrierposition **(40,20), Rotation 270°** zeigt USB nach rechts. Die nominale Buchsenmündung liegt dann bei **(52,65; 20; 2,75)**. `mechanical_interfaces.usb` liefert genau diese lokal transformierbaren Daten an den Gehäusegenerator.

## Versorgung und Aussagegrenze

Die ausgewählte Produktseite und die [Nologo-Anleitung](https://www.nologo.tech/product/esp32/esp32c3/esp32c3supermini/esp32C3SuperMini.html) schließen gleichzeitige USB- und externe Versorgung ausdrücklich aus. Deshalb trennt der Carrier-Schalter in **SERVICE** die externe positive Versorgung vom 5V-Modulanschluss, bevor USB verbunden wird. Die modulseitigen 3,3 V bleiben der Ausgang des eingebauten Reglers; dort wird kein zweiter Regler parallel angeschlossen.

Die Produktidentität und die CAD-Auslegung sind geklärt. **Ein reales Exemplar wurde nicht vermessen und die Clone-Passform ist nicht serienqualifiziert.** Die Dateien unterscheiden daher belegte Angebotsdaten, Nologo-Referenzen und eigene mechanische Reserven. Eine Passprobe der direkt gelöteten Randpads, USB-Unterseite und Gehäuseöffnung ist die verbleibende physische Prüfung; sie darf nicht durch einen erfolgreichen digitalen DRC ersetzt werden.
