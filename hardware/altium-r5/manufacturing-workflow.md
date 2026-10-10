> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](../../docs/internal/README.md).

# R5-Fertigungsableitung

Die R5-Adapter übernehmen Kupfer, Lötstopp, Paste, Bohrungen sowie BOM/CPL aus der geprüften Geometrie. Der Bestückungsdruck stammt ausschließlich aus dem **abschließend in Altium gespeicherten nativen PCB**: echte `LettersGeometry`-/`Texts6`-Konturen, Logo-Regions und Overlay-Tracks. Eine nachträglich installierte Ersatzschrift oder das Skalieren der Entwicklungs-Schriftprobe wird nicht für die Fertigung verwendet.

```powershell
python tools/export_jlcpcb_r5.py --design hardware/altium-r5/orion-r5-design.json --routing hardware/altium-r5/orion-r5-routing.json --pcb hardware/altium-r5/BatterySentinel-N2K-Orion-R5.PcbDoc --out hardware/altium-r5/manufacturing
python tools/verify_jlcpcb_r5.py --design hardware/altium-r5/orion-r5-design.json --routing hardware/altium-r5/orion-r5-routing.json --pcb hardware/altium-r5/BatterySentinel-N2K-Orion-R5.PcbDoc --manufacturing hardware/altium-r5/manufacturing --out hardware/altium-r5/manufacturing-review.json
python tools/verify_native_gerber_r5.py
```

Die Werkzeuge benötigen die vorhandene Python-/Shapely-Laufzeit des PCB-Projekts. Die FreeCAD-Laufzeit für Gehäuse und STEP ist davon unabhängig.

`board.native_texts` deklariert die gewünschten Textobjekte mit Wortlaut, Lage, Schrifthöhe, Drehung und Seite. Diese Angaben werden gegen die gespeicherten nativen Objekte geprüft. `board.native_logos` wird ebenfalls mit den nativen Regions abgeglichen. `native-typography-readback.json` enthält die tatsächlich gelesenen Konturen und den Hash des nativen PCB.

Die äußere Kontur enthält die USB-Randkerbe. Das Antennenfenster ist eine getrennte, geschlossene Fräskontur. Beide stammen aus `board.outline_points_mm` beziehungsweise `board.cutouts_mm[].outline_points_mm`; Prüfer vergleichen Kupfer-, Bohr- und Legendengeometrie gegen das verbleibende Platinenmaterial. Alle Ebenen verwenden dieselben Millimeterkoordinaten in Draufsicht, ohne künstliche Spiegelung der Bottom-Datei.

`BOM-JLCPCB.csv`/`CPL-JLCPCB.csv` enthalten nur belegte Lieferantencodes. Das gewählte, selbst bereitgestellte SuperMini-Modul wird nach der Träger-PCBA an den Castellated-Pads montiert und ausdrücklich separat ausgewiesen. Eine vollständige Träger-BOM bedeutet deshalb keine vollständig montierte Gesamtbaugruppe.

Die Adapter-Prüfung `manufacturing-adapter-self-test.json` verwendet die echte gespeicherte Schriftprobe und eine künstliche Testplatine mit Randkerbe und Fräsfenster. Sie prüft auch absichtlich verschobene Text-/Logo-Deklarationen und geänderte Gerberdaten. Sie ist **keine Freigabe des späteren fertigen R5-Layouts**. Dafür müssen dessen Quell-/Netz-/Geometrieprüfung, der direkte native Vergleich und der abschließende native Altium-DRC ebenfalls bestehen.
