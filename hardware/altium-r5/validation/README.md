# Nachweis der Altium-Regelserialisierung

Die drei Dateien `BoardEdge-negative-0_31mm.*` sind die unveränderte, absichtlich fehlschlagende R4-Gegenprobe: Altium prüft eine uniforme 0,31-mm-Board-Edge-Regel tatsächlich, auch wenn sein DRC-Kopf `Gap=0mil` anzeigt und die Matrix leer serialisiert wird. Sie sind ausschließlich ein Format-/Engine-Nachweis. Sie sind **kein R5-Layout oder R5-DRC-Nachweis**.

R5 muss zusätzlich seine gespeicherte tatsächliche `GENERICCLEARANCE=0,30 mm`, seine aktuelle Geometrie und einen neu ausgeführten fehlerfreien R5-DRC nachweisen. Herkunft und unveränderte SHA256-Werte stehen in `BoardEdge-serializer-evidence.json`.
