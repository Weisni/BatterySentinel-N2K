> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](../../docs/internal/README.md).

# R5: ursprüngliches ESP32-C3 SuperMini

Stand: 23.09.2026. Diese Prüfung bezieht sich auf das veröffentlichte **Nologo ESP32-C3 SuperMini**. Sie ersetzt weder die Identifikation des tatsächlich gekauften Moduls noch eine Passprobe. Es wurde kein anderer ESP32-Modultyp als Ersatz ausgewählt. Die maschinenlesbaren Koordinaten, Quellen-Hashes und offenen Maße stehen in [supermini-review.json](supermini-review.json).

## Montage und Pinbelegung

Die offiziellen Produktfotos zeigen **Randkastellierungen neben den geschlossenen inneren Kontaktbohrungen**. Eine direkte Lötmontage ist grundsätzlich möglich. Die Unterseite ist ohne SMD-Bauteile dargestellt; beim USB-Stecker sind jedoch Schirmbefestigungen und Lötstellen vorhanden. Deren Überstand nach unten ist nicht bemaßt. Der Hersteller beschreibt eine einseitig bestückte, für Oberflächenmontage geeignete Bauform. [Nologo-Produktseite](https://www.nologo.tech/product/esp32/esp32c3/esp32c3supermini/esp32C3SuperMini.html), [Produktfoto](https://www.nologo.tech/assets/img/esp32/esp32c3supermini/esp32c3.png), [Unterseitenansicht](https://www.nologo.tech/assets/img/esp32/esp32c3supermini/esp32c3foot1.png).

Die veröffentlichte Maßzeichnung nennt 18,00 × 22,50 mm, 15,24 mm Abstand der inneren Kontaktreihen und 2,54 mm Raster. Der Produkttext nennt abweichend 22,52 mm Länge. Die veröffentlichte native PcbDoc enthält nur zwei Header-Komponenten mit 16 inneren Bohrpads. Sie ist ein vereinfachtes Umriss-/Anschlussmodell, **kein vollständiger Produktionsdatensatz des Moduls**. Das Fehlen äußerer Pads darin widerlegt deshalb nicht die auf dem Produkt vorhandenen Kastellierungen. Im Herstellerverzeichnis liegen gegenwärtig eine PcbDoc und zwei PNGs, keine KiCad-Dateien. Die lokalen drei Quellen stimmen über ihre Git-Blob-Hashes mit dem frisch abgefragten Verzeichnis überein. [Herstellerdateien](https://github.com/NologoTech/ESP32C3-Supermini/tree/main/Hardware).

Koordinaten: Draufsicht, Ursprung in der nominalen Platinenmitte, USB in Richtung **+Y**, Antenne in Richtung **−Y**. Die inneren Lochreihen liegen bei X = ±7,62 mm. Y beginnt USB-seitig bei +9,7006 mm und sinkt je Reihe um 2,54 mm bis −8,0794 mm.

| Reihe ab USB | Links, X = −7,62 mm | Rechts, X = +7,62 mm |
|---|---|---|
| 1 | GPIO5 | 5V / USB-VBUS |
| 2 | GPIO6 / TX | GND_LOGIC |
| 3 | GPIO7 / RX | 3V3-Ausgang |
| 4 | GPIO8 | GPIO4 |
| 5 | GPIO9 | GPIO3 |
| 6 | GPIO10 | GPIO2 |
| 7 | GPIO20 | GPIO1 |
| 8 | GPIO21 | GPIO0 |

Die native Vorlage liefert für die inneren Modulbohrungen 0,9144 mm Durchmesser und 1,6-mm-Kupferpads. Die bisherigen Carrier-Pads mit 1,0-mm-Bohrung und 1,8-mm-Land waren eine separate Auslegung für Stiftleisten. Die **genauen Außenkontaktmaße** sind nicht Bestandteil des veröffentlichten Datensatzes.

Ein optionaler Kombinations-Footprint kann diese inneren PTH-Pads und zusätzliche Top-Lands von etwa 2,8 × 1,8 mm bei X = ±8,40 mm verwenden. Das ergibt nominal 0,8 mm sichtbare Lötkehle außerhalb der 18-mm-Modulkante. Diese Maße sind ein **Engineering-Vorschlag für eine Passprobe**, kein freigegebenes Nologo-Landpattern. Offene Carrier-Bohrungen können beim Reflow Lot aus den flachen Modulverbindungen abziehen. Für automatische Bestückung ist deshalb eine eigene SMD-Variante oder ein vom Bestücker bestätigter Prozess nötig; bei Handmontage ist der Kombinations-Footprint leichter beherrschbar.

Unter das direkt montierte Modul gehören keine Carrier-Bauteile. USB-Schirmstifte benötigen einen Ausschnitt oder einen nachgewiesenen Abstand. Die frühere Modellannahme mit 3,1 mm Abstand und 7,2 mm Gesamthöhe ist **kein Herstellermaß**. USB-Mittelhöhe, Platinenstärke und äußerer Steckerüberstand bleiben für das Gehäuse parametriert. Die Antennenseite sollte über einer offenen Trägerkante liegen; eine zahlenmäßig genaue Nologo-Antennenfreizone konnte nicht verifiziert werden.

## Versorgung mit unverändertem Modul

Im Originalschaltplan liegen USB-VBUS und der Modulanschluss „5V“ direkt auf demselben Netz. Erst danach führt die BAT60J-Diode zu VSYS und zum ME6211-Regler für 3,3 V. **Eine zusätzliche Diode vor dem Carrier-5V-Anschluss trennt somit nicht den USB-Anschluss vom gespeisten Modulnetz.** [Nologo-Schaltplan](https://raw.githubusercontent.com/NologoTech/ESP32C3-Supermini/main/Hardware/%E7%94%B5%E8%B7%AF%E5%9B%BE.png).

Der Hersteller nennt 3,3–6 V externe Versorgung am 5V-Pin, untersagt aber ausdrücklich den gleichzeitigen Anschluss externer Versorgung und USB. Der untere Eingangswert bedeutet wegen Diode und LDO-Dropout keine garantierten 3,3 V unter hoher Last. [Nologo-Versorgungsanleitung](https://www.nologo.tech/product/esp32/esp32c3/esp32c3supermini/esp32C3SuperMini.html).

Empfehlung für R5: **isolierte Versorgung → zugänglicher RUN/SERVICE-Schalter → Modul-5V**. Vor dem Einstecken von USB trennt SERVICE die externe positive Versorgung physisch. Der Modul-3V3-Ausgang versorgt die Logikseite des ISO1042 und deren Entkopplung. GND_LOGIC bleibt verbunden und gegenüber GND_BUS isoliert. Der Schalter muss bei geschlossenem Gehäuse erreichbar und entsprechend beschriftet sein. Eine USB-Serviceverbindung ist damit möglich, aber nicht automatisch fehlbedienungssicher.

Ein zweiter 3,3-V-Regler darf nicht parallel auf den Modulausgang arbeiten. Das ME6211-Datenblatt begrenzt VOUT absolut auf VIN + 0,3 V; eine Einspeisung in den Ausgang bei abgeschaltetem Eingang ist dadurch nicht freigegeben. Der SOT23-5-Typ wird mit 500 mA unter den angegebenen Bedingungen beschrieben, seine thermische Belastung bleibt aber relevant: Bei angenommenen 4,7 V am LDO und 250 mA entstehen 0,35 W. Der Datenblattwert 210 °C/W ergibt überschlägig 73,5 °C Erwärmung; dies ist keine Messung der Nologo-Platine. Funkbetrieb im Gehäuse muss deshalb auf Spannungseinbrüche und Temperatur geprüft werden. [Microne ME6211 V24, Herstellerdatenblatt über Distributor, S. 1/5/10](https://xonstorage.z8.web.core.windows.net/pdf/microone_me6211c33u4agn_sup12manufacturernocatlinknew.pdf).

Beim unregulierten B0505S darf „5 V“ nicht als exakter Ausgangswert vorausgesetzt werden. Vorlast, zulässige Ausgangsschwankung und Einschaltverhalten müssen auch bei SERVICE berücksichtigt werden. Vor der Freigabe ist nachzuweisen, dass die konkrete R5-Versorgung den Moduleingang innerhalb seiner Grenzen hält. Ein nötiger zusätzlicher Regler gehört **vor den 5V-Pin**, nicht auf den bereits geregelten 3V3-Ausgang.

## Ergänzende Prüfung des R4-Wandlers für R5

**Ergebnis:** Eine direkte Verbindung vom unregulierten B0505S zum Modul ist stationär plausibel, aber mit den veröffentlichten Angaben nicht über alle Betriebsfälle abgesichert. Für die Serienauslegung sollte eine überprüfte sekundäre Regelung erhalten bleiben. Es wurden keine Bauteile oder Schaltungsdateien geändert.

Der EVISUN-Ausgang liegt bei nominalem Eingang laut Kennlinienhülle zwischen 5,00 und 5,50 V bei 10 % Last sowie zwischen 4,625 und 5,125 V bei Volllast. R20/R21 ergeben 75 Ω und bei 5 V eine Vorlast von 66,7 mA beziehungsweise 0,333 W. Diese Widerstände müssen **vor dem SERVICE-Schalter** direkt am Roh-Ausgang verbleiben. Dann entsteht durch das Abtrennen des Moduls kein Leerlauf. [EVISUN-Datenblatt V1.0, S. 1–3/5](https://resources.ampheo.com/static/datasheets/evisun/20240927/b2405s-3wr2.pdf).

| Rechenfall | Oberer Wert | Aussage |
|---|---:|---|
| Nomineller Eingang, geringe Last | 5,500 V | Stationäre Kennlinienhülle |
| 5,05 V Primärspannung; Linienregelung berücksichtigt | 5,566 V | `5,5 × 1,012`, begrenzter Rechenfall |
| Zusätzlich volle 120 mV als positive Ripple-Reserve | 5,686 V | Noch unter 6 V |
| Zusätzlich typische Temperaturdrift über 65 °C | 5,758 V | **Keine garantierte Grenze** |
| Beliebiger zulässiger Wandlereingang bis 5,5 V | 6,160 V vor Ripple | Gesamter Wandler-Eingangsbereich alleine genügt nicht |

Die Temperaturangabe ist nur typisch und bei Volllast angegeben; eine maximale Einschalt- oder Lastabwurfspitze fehlt. Außerdem gelten die 4,95–5,05 V des vorgeschalteten AP63205 ausdrücklich für CCM. Die obige Rechnung darf daher nicht als Nachweis aller PFM-, Temperatur- und Einschaltfälle ausgegeben werden. Im SERVICE-Zustand schützt die **offene Verbindung** das USB-versorgte Modul; beim Zurückschalten auf RUN bleibt ein Lastsprung zu untersuchen.

Eine sekundäre Regelung um **4,5 V** wäre thermisch günstiger für den Modul-LDO. Dafür ist eine einstellbare Variante wie AP63200 mit geprüftem Teiler und überprüfter Induktivität nötig: Der bestehende AP63203 ist als feste 3,3-V-Version dokumentiert, der AP63200 schaltet zudem mit 500 kHz statt 1,1 MHz. Alternativ ist der bereits in R4 verwendete **AP63205 mit festen 5 V** eine zu prüfende Option mit passendem 4,7-µH-/2×22-µF-Herstellerbeispiel. Beide können bei zu niedrigem Eingang nur in den Dropoutbetrieb übergehen; die Sollspannung ist dann nicht garantiert. [Diodes-Datenblatt, S. 5/12–14](https://www.diodes.com/datasheet/download/AP63200-AP63201-AP63203-AP63205.pdf).

Das ist noch keine Bauteilauswahl. Die interne BAT60J und der Modul-LDO brauchen verbleibenden Spannungsspielraum. Eine zusätzliche Carrier-OR-Diode würde ihn weiter verkleinern; beim physisch trennenden SERVICE-Schalter ist sie für die beschriebene Quellenwahl nicht erforderlich. Auch das Leistungsbudget muss neu gerechnet werden: 4,5 V × 0,5 A bei pauschal 80 % Wirkungsgrad und 4,625 V Rohspannung ergeben einschließlich Vorlast etwa **0,670 A** und überschreiten die 0,600-A-Grenze. Reale Effizienz nahe Dropout, Funkstrom und Temperatur müssen zum konkreten Modul passen. Der alte R4-Nachweis für 3,3 V/500 mA lässt sich nicht unverändert übernehmen.

## Beschaffung und Freigabegrenze

Eine konkrete JLCPCB-/LCSC-Bestückungsnummer für das **originale Nologo ESP32-C3 SuperMini** konnte am Prüftag nicht verifiziert werden. Das gefundene ESP32-C6-SuperMini C9900170751 ist ein anderes Produkt und wird nicht verwendet. Ein EasyEDA-Symbol oder Community-Footprint ist kein Lager- oder Bestückungsnachweis.

Damit sind zwei ehrliche Wege möglich: JLCPCB bestückt den Carrier und das originale SuperMini wird anschließend separat montiert; oder der exakte Modultyp wird nach Bestätigung von Gehäuseform und Montageprozess an JLCPCB beigestellt. JLC verlangt, dass beigestellte Teile vor dem Auftrag tatsächlich eingelagert und in der Bauteilzuordnung ausgewählt sind. Eine vollständig bestückte Sofortbestellung darf ohne diese Klärung nicht zugesagt werden. [JLC-Beistellung](https://jlcpcb.com/help/article/how-to-consign-parts-to-jlcpcb-from-mainland-china), [JLC-Bauteilzuordnung](https://jlcpcb.com/help/article/component-matching-guidelines-for-pcba-orders).

Vor Produktionsfreigabe fehlen somit die genaue Modulvariante, eine Passprobe der Randpads und USB-Unterseite, die endgültige Montagehöhe sowie die Festlegung, wer das Originalmodul montiert. Die CAD-Arbeit kann mit offen gekennzeichneten Parametern weiterlaufen; ein beliebiges SuperMini eines anderen Lieferanten ist dadurch nicht automatisch qualifiziert.
