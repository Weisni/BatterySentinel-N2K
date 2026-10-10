# R5-Prüfstand – noch keine Fertigungsfreigabe

Stand 23.09.2026 nach dem letzten Neuaufbau mit C28 bei (29,1; 9,2). Die Arbeit wurde nach dem vom Nutzer ausgelösten Computer-Use-Stopp beendet; es wurden keine weiteren UI-Aktionen ausgeführt.

Der aktuelle **native Altium-ASCII-Entwurf** wurde unabhängig gelesen. Schaltplanverdrahtung, lokale SchLib/PcbLib, Bauteil-/Pin-Identitäten und Schaltplan-PCB-UIDs bestehen 6.195 Prüfungen. Die gesamte Quellenprüfung führte 10.885 Prüfungen aus. Die Geometrie hat keine Befunde: alle 23 Netze und alle 12 überprüften Hauptversorgungspfade sind verbunden; minimale Maskenstege sind jetzt 0,100 mm, BUS/LOGIC-Abstand 3,210 mm. Das manuell gelötete SuperMini ist trotz seines Ausschlusses aus automatischer Bestückung in den mechanischen Kollisionsprüfungen enthalten.

Der vollständige Prüfbericht `independent-verification.json` bleibt ausdrücklich **passed=false / release_checks_complete=false**, weil noch keine finalen BOM/CPL-Dateien vorliegen. Das aktuelle PcbDoc wurde noch nicht durch Altium geöffnet und als native Binärdatei gespeichert. **Ein nativer R5-Altium-DRC wurde nicht ausgeführt.** Die endgültige Schrift-/Logo-Geometrie aus dem gespeicherten Schriftcache, die tatsächliche Umwandlung des Ausschnitts in `ISBOARDCUTOUT` und die finale CAM-Ausgabe bleiben somit offen.

Die isolierten Prüfeinstiege `tools/verify_altium_r5.py` und `tools/verify_altium_binary_r5.py` sind vorbereitet. Sie verändern keine CAD-Dateien und keine R4-Prüfer. Sieben gezielte Mutationstests bestehen: vertauschte Modulpins, eine fälschliche Carrier-Bohrung, Modul-Pastenöffnung, gezeichneter statt realer Ausschnitt, Stroke- statt TrueType-Text und fehlerhafte Schaltplan-PCB-UID werden zurückgewiesen.

Die Quellen-/Bibliotheksprüfung lässt sich mit FreeCADs Python ausführen:

```
"C:\Program Files\FreeCAD 1.1\bin\python.exe" tools/verify_altium_r5.py --report hardware/altium-r5/independent-verification.json
```

Nach einem ausdrücklich wieder aufgenommenen UI-Arbeitsgang folgen Speichern im nativen Binärformat, frischer R5-DRC, Binär-/Schrift-/Cutout-Rücklesung und CAM/BOM/CPL-Prüfung. Die unter `validation` übernommene R4-Gegenprobe belegt ausschließlich Altiums Regelserialisierung; sie ersetzt keinen dieser R5-Schritte. Die tatsächliche Passprobe des gekauften SuperMini und seiner USB-Unterseite bleibt eine gesonderte physische Qualifikation.
