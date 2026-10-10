# Project-internal enclosure development record

**Project-internal archive.** This retained design record is for engineering traceability. Use [the current enclosure instructions](sealed-print/README.md) for printing and assembly. Its historical dimensions, hardware and unfinished status do not describe the delivered print package.

# R5 enclosure

**Current print package:** [Bambu P2S gasketed enclosure, assembly and validation](sealed-print/README.md). This design uses the actual 52 x 36 mm R5 PCB, separate screw-fastened service covers, continuous TPU seals and a replaceable cable cartridge. Physical fit, cable diameter, leak, pull, thermal and RF acceptance remain open. No IP rating is claimed.

The following dry-case description and `PROVISIONAL-enclosure.FCStd` are historical. They describe the earlier 50 mm placeholder and do not define the current print package. Rebuild the current package with `tools/build_orion_r5_sealed_enclosure.py` and `tools/package_orion_enclosure.py`; retain the older generator and release protocol as scaffold history.

## Historical provisional enclosure

**Vorläufige Mechanik, keine freigegebenen Druckdaten.** Das vom Benutzer gewählte Meshnology-SuperMini-Modul (ASIN B0FN4F6244) steht fest; endgültige Leiterplattenbestückung und davon abhängige Gehäuseöffnung werden gerade integriert. Geschützter trockener Einbau ist die Arbeitsannahme. Die bisherige grüne Platte in der Explosionsansicht ist eine **unbestückte Platzhalterplatine** mit vorgeschlagenem Umriss und Schraublöchern. Nach der Layoutsynchronisierung zeigt der Generator die tatsächlichen R5-Bauteilkörper. Die [mechanische Anbindung und Abschlussprüfung](RELEASE-PROTOCOL.md) beschreibt diesen Übergang.

Der Entwurf besteht aus einer gerundeten Unterschale und einem abnehmbaren Deckel. Zwei äußere Laschen dienen zur Montage am Einbauort. Das Gehäuse übernimmt das gemeinsame Logo und dieselbe Schriftfamilie wie das PCB-Branding; die Deckelbeschriftung ist 0,5 mm vertieft. Die Schriftdatei wird nicht weitergegeben.

Die drei Vorschauen zeigen das geschlossene Gehäuse (`enclosure-closed.png`), den abgenommenen Deckel und die ausdrücklich unbestückte Planungsplatine (`enclosure-exploded.png`) sowie die vorläufigen USB-/RUN-SERVICE-Öffnungen auf der Rückseite (`enclosure-ports.png`).

## Vorgeschlagene Schnittstellen

| Merkmal | Vorläufiges Maß |
|---|---:|
| Leiterplatte | 50 × 36 × 1,6 mm, Ecken R2 |
| Vier PCB-Bohrungen | Ø2,2 mm bei (3,3), (3,33), (47,3), (47,33) |
| Bauteil-/Kupferfreiraum an Schrauben | Ø5,6 mm über die gesamte Bauhöhe |
| Grundkörper außen | 55,2 × 41,2 × 22,25 mm |
| Hüllmaß mit Laschen und Kabelklemme | 62,2 × 55,2 × 22,25 mm |
| Wand/Boden/Deckel | jeweils 2,0 mm |
| PCB-Randspiel | 0,6 mm je Seite |
| Freiraum unter der Platine | 4,5 mm bis zur Bodenoberseite |
| Freiraum über der Platine | 12,0 mm bis zur Deckelunterseite |
| Befestigungslaschen | zwei M3-Langlöcher, Ø3,4 × 5,4 mm |
| Laschen-Lochabstand | 48,2 mm, mittig in X |
| Kabeldurchmesser | 6 mm Startwert, einstellbar 5–7 mm |

Alle Maße liegen in `mechanical-contract.json`. Sie sind Generatorparameter. Änderungen der Platine oder des Moduls werden dort übernommen; der Generator berechnet Schale, Deckel, Einstecklippe, Distanzsäulen und Durchbrüche neu. Die FCStd-Datei enthält überprüfbare OCCT-Volumenkörper; die parametrische Quelle ist die JSON-Datei zusammen mit dem Python-Generator.

## Verschraubung und Zusammenbau

Vier M2-Schrauben verbinden Deckel und Unterschale. Sie laufen durch hohle Deckel-Distanzsäulen und die PCB-Bohrungen in M2-Gewindeeinsätze in den unteren Platinenauflagen. Damit benötigt der Deckel keine zusätzlichen breiten Schraubtürme neben der Platine. Die Platine hat nominal 0,15 mm axiales Spiel; die finale Höhenpassung muss mit gedruckten Probestücken geprüft werden. Für vibrationsbelasteten Einbau ist eine dünne elastische Auflage beziehungsweise angepasste Distanzsäulenhöhe vorzusehen, ohne die Leiterplatte zu verspannen.

Der Startentwurf verwendet vier **ruthex RX-M2x4** und vier **M2 × 18 mm** Schrauben. Der Generator prüft den geometrischen Schraubeneingriff und die freie Schraubenspitze; im aktuellen Modell ergeben sich 3,25 mm Eingriff. Der Schraubenkopf muss in die modellierte Ø4,2-mm-Aufnahme passen. Die 3,2-mm-Einsatzbohrung ist ein **vorläufiger Druck-/Prozessparameter**, keine zugesicherte Passung. Einen kleinen Einpressversuch mit dem konkreten Filament, Drucker und Einsatz durchführen. Herstellerquelle und Original-STEP sind dokumentiert; die Nennlänge von 4 mm stammt vom [Hersteller](https://www.ruthex.de/en/products/ruthex-gewindeeinsatz-m2-70-stuck-rx-m2x4-messing-gewindebuchsen).

Vorgesehene Reihenfolge: Gewindeeinsätze in die leere Schale einsetzen, Kabel vorbereiten, Platine samt angeschlossenen Adern auflegen, Kabelmantel in die offene Klemmsattelaufnahme legen und Deckel mit vier Schrauben gleichmäßig schließen. Die äußeren M3-Befestigungsschrauben richten sich nach dem Montageuntergrund.

## Anschlüsse und Kabelhalterung

USB und RUN/SERVICE-Schalter besitzen getrennte, parametrierbare Öffnungen. Position, Breite, Höhe und Eckradius sind vorläufig. Insbesondere die USB-Z-Höhe ist in den Herstellerunterlagen nicht bemaßt; deshalb wird keine scheinpräzise endgültige Anschlussposition behauptet. Das Originalmodul und seine unteren USB-Lötmerkmale sind in `../supermini-review.json` beschrieben.

Die Standard-Kabelhalterung ist eine in beide Gehäusehälften integrierte, gerundete Mantelklemme. Beim 6-mm-Beispiel beträgt der Eingangsfreiraum Ø6,4 mm; zwei flache Klemmrippen verengen lokal auf Ø5,8 mm. Das ist ein Ausgangspunkt für eine reale Zug-/Biegeprüfung am verwendeten Kabelmantel. Sie soll Kräfte vom Kabelmantel in das Gehäuse ableiten und nicht die einzelnen Adern an ihren Lötstellen festhalten.

Optional ist ein Modus für eine durchgesteckte Kabelverschraubung vorgesehen. Die vorläufige Ø12,2-mm-Bohrung darf erst nach Auswahl einer konkreten Verschraubung samt Mutter, Wanddicke und Kabelbereich freigegeben werden. Ein Wechsel zur nassen Einbausituation erfordert zusätzlich eine passende USB-Abdeckung, eine Dichtungskonstruktion und reale Prüfungen.

**Keine geprüfte IP-Schutzart:** offene USB-Buchse, Deckelfuge, geteilte Kabelklemme und FDM-Porosität sind nicht als wasserdicht ausgelegt oder geprüft.

## Druck und Prüfung

Startwerte: 0,4-mm-Düse, 0,2-mm-Schicht, fünf Außenwände und etwa 30 % Füllung. Unterschale mit der äußeren Bodenfläche, Deckel mit der äußeren Deckelfläche auf das Druckbett legen. Die langen Deckel-Distanzsäulen zeigen dann nach oben. PETG oder ASA abhängig von realer Einbautemperatur und Drucker wählen. Drucktoleranzen und Einpresspassungen müssen am eigenen Prozess geprüft werden; dazu empfiehlt auch [Prusa](https://help.prusa3d.com/article/modeling-with-3d-printing-in-mind_164135) passende Toleranzen und praktische Iteration.

Das Logo steht groß oberhalb des vollständigen Namens **BatterySentinel-N2K**, darunter **Orion-R5**. Die unveränderten Logo-Pfade werden auf 14 mm nominale Zeichenfläche skaliert; ihre Strichbreite beträgt 0,84 mm. Schild und Pulslinie sind jeweils durchgehend. Die Vertiefung reicht genau 0,5 mm in die Deckeloberfläche und lässt darunter 1,5 mm Deckelstärke stehen.

Die Schrift verwendet Arial Rounded MT Bold mit 4,6 mm em-Höhe. Nur für das Gehäuse kommen 0,38 mm zusätzliche Zeichenabstände, 0,04 mm Konturerweiterung und 0,23 mm Abstandserweiterung an den i-Punkten hinzu. Die Buchstaben werden nicht horizontal gestaucht. Diese ausdrücklich mechanischen Druckzugaben verändern keine nativen PCB-Texte; der Generator fixiert seine FontTools-Geometrie unabhängig von der Altium-Schriftkalibrierung.

Die geometrische Prüfung in `branding-printability-review.json` misst mindestens 0,435 mm zwischen getrennten Schriftkonturen. Bei einer Prüfung mit einer Kreisscheibe von 0,4 mm Durchmesser entfallen weniger als 0,025 % Schriftfläche auf schmalere lokale Details; die ungefähre untere 5-%-Strichbreite liegt beim langen Namen bei 0,424 mm. An Rundungen/Endpunkten ergibt die abgetastete Mittellinie kleinere lokale Werte bis etwa 0,342 mm. Deshalb ist dies eine geometrische Vorprüfung, keine Zusage für jede Slicer-Einstellung: Vor dem kompletten Druck die tatsächlichen Bahnen und eine Beschriftungsprobe einschließlich erster Schicht prüfen. Die ursprüngliche horizontal verkleinerte Gesamtbeschriftung wurde wegen zu dünner Details verworfen.

Der Kopflose Prüflauf verwendet FreeCAD 1.1:

```powershell
& 'C:/Program Files/FreeCAD 1.1/bin/python.exe' tools/build_orion_r5_enclosure.py --check
```

Er prüft gültige, einzelne geschlossene Volumenkörper, Kollisionen zwischen Gehäusehälften und PCB, geometrische Bauhöhen und Schraubeneingriff. Sobald eine echte R5-Designdatei eingetragen ist, prüft er auch die darin vorhandenen Bauteilkörper gegen Schale und Deckel. Aktuell ist dieser Bauteil-Fitcheck ausdrücklich noch nicht möglich.

`--export` erzeugt später druckorientierte STL und zusammengebaute STEP-Geometrie. Der Export ist bis zur eingefrorenen PCB-/Modul-/USB-/Schalterschnittstelle gesperrt und prüft danach zusätzlich den Hash, Umriss und die Bohrungen der zugehörigen Designdatei. Bis dahin werden nur klar gekennzeichnete FCStd- und Bildvorschauen erzeugt.
