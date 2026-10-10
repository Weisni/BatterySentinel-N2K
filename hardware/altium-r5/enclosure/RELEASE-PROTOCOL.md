# R5 – mechanische Anbindung und Abschlussprüfung

**Project-internal engineering and production record.** This file records development evidence; the assembly PDF and current print-package README provide the user instructions.

Das ausgewählte Modul ist das vom Benutzer verlinkte **Meshnology ESP32-C3 SuperMini, ASIN B0FN4F6244**. Die Variante ist geklärt. Der Entwurf geht von einem geschützten, trockenen Einbau aus. Die ausgewählten Module besitzen keine veröffentlichte vollständige mechanische USB-Zeichnung; die verbleibenden Z-/Steckertoleranzen stehen deshalb als technische Annahmen im Modell.

## Schnittstelle zum finalen PCB

Der Generator liest die Leiterplattengeometrie und die vorhandenen `bodies_3d` direkt aus dem R5-Design. Kein Ersatzmodul und keine unabhängig verschobene Darstellung werden eingesetzt. Lokale Körper-Z-Werte beziehen sich auf die Oberseite der Trägerplatine; Lage und Drehung stammen aus `component.pcb`.

`component.mechanical_interfaces.usb` beziehungsweise `.service_switch` enthält:

```json
{
  "mouth_center_local_mm": [0, 12.65, 2.75],
  "outward_local_xy": [0, 1],
  "opening_width_mm": 12,
  "opening_height_mm": 7,
  "position_tolerance_mm": [0.5, 0.65, 0.4],
  "assumed": true
}
```

Die Werte im Beispiel sind der konservative USB-Ausgangspunkt des ausgewählten SuperMini-Modells, keine zugesicherte Herstellerbemaßung. Der Generator transformiert die lokale Position und Ausrichtung mit der echten Bauteillage. Bei 270° Moduldrehung zeigt USB nach +X. `confirmed` im Gehäusevertrag bedeutet, dass diese Schnittstelle mit der gewählten finalen Layoutlage verknüpft ist; die separate Herkunftskennzeichnung `assumed` bleibt erhalten.

```powershell
& 'C:/Program Files/FreeCAD 1.1/bin/python.exe' tools/build_orion_r5_enclosure.py --sync-design hardware/altium-r5/orion-r5-design.json
& 'C:/Program Files/FreeCAD 1.1/bin/python.exe' tools/build_orion_r5_enclosure.py --check
```

Die Synchronisierung übernimmt Umriss, Dicke, vier Schraublöcher, Quellen-Hash und Steckerpositionen. Sie verschiebt die Deckelbeschriftung bei geänderter PCB-Breite mittig und hebt eine frühere Freigabe auf. Der USB-Unterseitenfreischnitt muss zwischen nativer Platine, Fertigungsprofil und Gehäuse-Platinenkörper übereinstimmen. Nicht unterstützte Ausschnitte brechen die Erzeugung ausdrücklich ab.

## Geometrischer Abschluss

1. Die endgültige R5-Quelle synchronisieren und die endgültigen Anschlussöffnungen, Kabeldurchmesser, Schraubenlänge und Beschriftung in `mechanical-contract.json` festlegen.
2. Mit `--check` die OCCT-Körper, gegenseitige Gehäuse-/PCB-Kollisionen und **alle tatsächlichen Bauteilkörper** gegen beide Gehäusehälften prüfen. Der Bericht nennt den kleinsten Bauteilabstand. Die Explosionsansicht zeigt ab diesem Zeitpunkt die realen Modellkörper, keine bestückte Phantasieplatine.
3. USB-Steckerkorridor, RUN/SERVICE-Betätigung, Kabelbiegeraum und Einsetzrichtung visuell prüfen. Die konservative USB-Öffnung ersetzt keine Vermessung eines konkreten Steckers mit angespritztem Griff.
4. Die akzeptierte Geometrie mit `frozen: true` kennzeichnen und `--export` ausführen. Der Export vergleicht Quellen-Hash, Umriss und Bohrungen erneut. Eine spätere PCB-Änderung verlangt eine erneute Synchronisierung.
5. `Orion-R5-base-print.stl` und `Orion-R5-lid-print.stl` sind auf ihre Druckfläche orientiert. Der Export prüft geschlossene STL-Netze und weniger als 0,2 % Volumenabweichung zum CAD-Körper. `Orion-R5-case-assembled.step` enthält die Gehäusehälften in Montageposition; `Orion-R5-complete-assembly.step` und FCStd enthalten zusätzlich die Platine mit den zugehörigen Bauteilkörpern zur Einbauprüfung.

Die druckbaren Geometrien stellen den konstruierten Stand dar. Gewindeeinsatzpassung, Kabelklemmung, genaue USB-Höhe und Gravur sind am gewählten Drucker/Filament beziehungsweise konkreten Modul zu erproben. Eine IP-Schutzart wird nicht behauptet.
