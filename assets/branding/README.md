# Battery Sentinel: PCB- und Gehäusemarkierung

Das einfarbige Zeichen verbindet eine Batterie mit einem Schutzschild und einer Messkurve. Es wurde aus einfachen Kurven eigens für dieses Projekt konstruiert; es verwendet keine fremde Logo- oder Icon-Vorlage. Die runden Enden und die geschlossene Außenform passen zur abgerundeten Beschriftung.

`battery-sentinel.svg` enthält die bearbeitbaren Bézierpfade. Die SVG-Farbe folgt `currentColor`. `battery-sentinel.paths.json` enthält dieselbe Form als gefüllte Millimeterpolygone mit Aussparungen: `shapes`/`regions`, `bounds`, Koordinaten nach oben positiv, Ursprung unten links. Die Zeichenfläche misst 8 × 9,4 mm. Bei 6 mm Zeichenbreite beträgt die Strichbreite noch 0,36 mm; empfohlen sind 7 mm auf der Platine und 14 mm auf dem Gehäuse. Die tatsächlichen Pfadgrenzen sind etwas kleiner als die Zeichenfläche.

Für den Gehäusedeckel sind 0,6 mm erhabene oder 0,5 mm vertiefte Markierungen vorgesehen. Das innere Kurvenstück ist eine separate Fläche; beim Prägen verbindet es sich mit der vorhandenen Deckelfläche. Vor dem Export sind Lage, Wanddicke und Freiraum zur Platine zu prüfen. Das Logo ist für ein- oder zweifarbige Ausführung geeignet.

`branding-preview.svg` und `.png` zeigen das Zeichen zusammen mit den exakt geschriebenen Texten **BatterySentinel-N2K** und **Orion-R5**. Alle Buchstaben der Vorschau sind Vektorflächen. `branding.paths.json` stellt die vollständige Anordnung auch ohne lokal installierte Schrift als Millimetergeometrie für Zeichnungen und Gehäuse bereit.

## Schrift und native PCB-Objekte

Die vorhandene Schrift ist **Arial Rounded MT Bold**, lokal `C:/Windows/Fonts/ARLRDBD.TTF`, Version 1.51. `font-metadata.json` dokumentiert Dateihash, Metriken und die im Font gespeicherten Urheber- und Einbettungsangaben. Die Fontdatei wird **nicht** mitgeliefert oder in Release-ZIPs kopiert. `BOLD=FALSE` ist richtig: Die ausgewählte Schrift enthält bereits den fetten Schnitt.

Im PCB bleiben die Beschriftungen echte, editierbare `Text`-Objekte mit `USETTFONTS=TRUE`, `FONTNAME=Arial Rounded MT Bold`, `ITALIC=FALSE` und `INVERTED=FALSE`. Altium dokumentiert diese Eigenschaften und `TTTextOutline` in seiner [PCB-API-Referenz](https://www.altium.com/documentation/altium-dxp-developer/pcb-api-design-objects-interfaces-reference). In aktuellen Versionen kann die Textgeometrie im Dokument gespeichert werden; die maßgebliche Einstellung ist `PCB.Text.TTFontSaving`. Siehe [TrueType-Unterstützung in Altium](https://www.altium.com/documentation/altium-designer/pcb/placement-editing-techniques).

Die native Prüfung ist abgeschlossen. Der unveränderte, in Altium 26.10.1 gespeicherte Coupon liegt unter `hardware/altium-r5/typography/R5-Beschriftungsprobe.PcbDoc`; sein SHA256 beginnt mit `d0f616a14110336d`. Aus `LettersGeometry` wurden alle 23 Glyphen mit ihren Konturen, Aussparungen und Zeichenabständen gelesen. Bei sämtlichen fünf Textobjekten stimmen die daraus berechneten Breiten und Höhen **exakt** mit den gespeicherten `Texts6`-Werten überein. Der 90°-Text und der gespiegelte Unterseitentext stimmen ebenfalls mit ihren gespeicherten Referenzpunkten überein. X bezeichnet die linke sichtbare Zeichenkante, Y die Grundlinie. Die natürliche linke Glyphenreserve muss deshalb vor dem Platzieren entfernt werden.

Altium verwendet quantisierte Schriftgeometrie. Eine Skalierung der Rohschrift mit 2048 Einheiten pro Höhe würde hier sichtbar größere Buchstaben erzeugen. Bei nominal 2 mm Texthöhe hat `Orion-R5` im nativen Coupon eine sichtbare Breite von 7,373828 mm und Höhe von 1,277280 mm; Buchstaben mit Unterlänge reichen weiter unter die Grundlinie. `altium-native-font.json` enthält die tatsächlich gespeicherten Glyphenumrisse, nicht die Fontdatei. Der Standardhelfer verwendet diese Konturen auch für Zeichnungen und Gehäuse. Skalierung auf andere Höhen ist für Vorschauen möglich; die endgültigen Gerber werden aus dem Cache der **tatsächlich gespeicherten finalen Platine** erzeugt, damit deren jeweilige Quantisierung erhalten bleibt.

`native-typography-verification.json` dokumentiert den Vergleich und die separat eingelesenen Gerber auf Ober- und Unterseite: Flächendifferenz jeweils 0,0 mm². Diese Prüfung bestätigt die Beschriftung des Coupons, nicht eine fertige oder elektrisch geprüfte R5-Platine. Die vorhandene native Altium-Datei enthält außerdem einen `EmbeddedFonts6`-Stream aus dem normalen Altium-Speichervorgang; eine eigenständige TTF-Datei wird nicht kopiert.

## Python-Schnittstelle

`tools/r5_branding.py` benötigt `fontTools` und `Shapely`; für PNGs zusätzlich `PySide6`. Diese Pakete sind im vorhandenen FreeCAD-Python enthalten.

```python
from r5_branding import actual_text_record, text_regions, logo_regions

label = dict(text='Orion-R5', x=12, y=3, height=2, rotation=0, layer='TOP')
native_ascii = actual_text_record(label)  # echter Altium Text
gerber_regions = text_regions(label)     # gefüllte Glyphen mit Löchern
logo = logo_regions(dict(width=7, x=2, y=2, rotation=0, layer='TOP'))
```

`emit_gerber_regions(gerber, regions)` schreibt die Polygone mit Aussparungen über den bestehenden RS-274X-Exporter. `native_logo_records(item)` gibt drei native gefüllte Regionen für das Zeichen zurück; deren Vereinigungsfläche entspricht dem Logo. Bottom-Layer werden um den lokalen Ursprung gespiegelt und danach gedreht/verschoben. Groß- und Kleinschreibung bleiben erhalten. Kurven werden mit höchstens 0,001 mm Abweichung polygonisiert; die tatsächlichen Gerberregionen werden separat eingelesen und verglichen.

Für exakte Produktionskonturen nach dem Speichern in Altium:

```python
from r5_native_typography import read_native_text_artwork

artwork, native_cache_groups = read_native_text_artwork(saved_pcb_path)
for text in artwork['texts']:
    # text['layer'], text['text'], text['bounds'], text['regions']
    pass
```

Dieser Leser benötigt keine installierte Schrift. Er verwendet ausschließlich die im PCB gespeicherten Glyphen und prüft Größe, Grundlinie, Drehung und Spiegelung gegen die unabhängigen Text-Metadaten. Fehlende Glyphen/Caches, unbekannte Datensätze, nicht unterstützte Stroke-Texte auf den Drucklagen und abweichende Metriken werden als Fehler gemeldet. Es gibt keine stille Ersatzschrift. Der Vorschaurechner kennt aktuell die 23 Zeichen des Coupons; weitere PCB-Texte benötigen die Konturen aus ihrem eigenen gespeicherten PCB-Cache.

Neu erzeugen:

```powershell
& 'C:/Program Files/FreeCAD 1.1/bin/python.exe' tools/r5_branding.py --build
```

Der zusätzliche Schalter `--native-probe` erstellt ausschließlich den Prüf-Coupon unter `tmp/r5-typography-probe`. Nicht erneut ausführen, während Altium diesen Coupon geöffnet hat oder dessen gespeicherte Binärdatei geprüft wird. Der Coupon enthält fünf echte TrueType-Texte einschließlich 90°-Drehung und gespiegelter Unterseitenbeschriftung sowie das Logo; keine elektrischen Bauteile oder Leiterbahnen.
