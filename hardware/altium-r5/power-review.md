> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](../../docs/internal/README.md).

# R5: Versorgung des unveränderten ESP32-C3 SuperMini

Prüfstand: 23.09.2026. Diese Prüfung legt die Schaltung und die lokalen Bauteildaten fest. Sie ist kein Messprotokoll eines bestückten Prototyps. Das vom Nutzer ausgewählte SuperMini-Modul bleibt erhalten; Referenz zur konkreten Bestellung: Amazon ASIN **B0FN4F6244**. Die Modulprüfung mit den Anbieter-Schaltplanbildern erfolgt separat in `module-selection.json`.

## Festgelegte Schaltung

```text
NET_S → F1 → D5 → U3/AP63205 → 5V_BUS → U1.VCC2
                                  └→ U2/EVISUN B0505S-3WR2
                                      ║ galvanische Trennung
                                      └→ 5V_ISO → U4/AP63205 → 5V_REG
                                            │                   │
                                        R20 || R21           SW3 RUN
                                            │                   │
                                        GND_LOGIC            5V_MODULE → SuperMini.5V
                                                                         │
                                                            Modul-LDO → 3V3_LOGIC → U1.VCC1
```

U4 wird gegenüber R4 von AP63203 auf **AP63205WU-7 / C2071056** geändert. Seine Festspannung beträgt 5 V, FB liegt direkt an `5V_REG`. L3 = 4,7 µH, C32/C33 = je 22 µF, C29 = 10 µF und C31 = 100 nF zwischen BST/SW entsprechen dem 5-V-Herstellerbeispiel. C30 ergänzt lokale 100-nF-Eingangsentkopplung. Die Pinfolge bleibt 1=FB, 2=EN, 3=VIN, 4=GND, 5=SW, 6=BST. Bei geringem Eingangsspannungsüberschuss geht der Regler in einen Betriebszustand mit annähernd 100 % Tastgrad über. Er kann die Ausgangsspannung dabei nicht erhöhen. [Diodes AP6320x, Rev.3-2, S.2/5/13](https://www.diodes.com/datasheet/download/AP63200-AP63201-AP63203-AP63205.pdf).

D2/D4 und der externe Carrier-USB-Anschluss entfallen. Somit entsteht kein zusätzlicher Schottky-Spannungsabfall zwischen U2 und U4. C34 = 10 µF liegt hinter SW3 direkt an der Modulversorgung. Der Carrier speist **nicht** in den 3,3-V-Ausgang des Moduls ein. C5/C11/C12 und U1.VCC1 werden aus diesem Ausgang versorgt.

## RUN und SERVICE

Der Anbieter-Schaltplan der ausgewählten C3-Ausführung zeigt Modul-5V und USB-VBUS als dasselbe Netz, danach BAT60J und ME6211. Daher reicht ein Abschalten von U4 per EN nicht als zugesicherte Rückspeisesperre. SW3 trennt die externe Quelle physisch. Diese Eigenschaft entspricht auch der ausdrücklichen USB-/Externversorgungs-Anweisung der ursprünglichen SuperMini-Referenz. [Nologo-Anleitung](https://www.nologo.tech/product/esp32/esp32c3/esp32c3supermini/esp32C3SuperMini.html); Anbieterbelege: `references/amazon-B0FN4F6244-schematic.jpg` und `references/amazon-B0FN4F6244-core-schematic.jpg`.

- **RUN:** SW3 verbindet Pin 1 (`5V_REG`) mit Pin 2 (`5V_MODULE`). USB bleibt abgezogen.
- **SERVICE:** SW3 verbindet Pin 2 mit dem unbeschalteten Pin 3. Erst danach USB anschließen. Das Modul speist über seinen LDO weiterhin die isolierte Logikseite.
- Für die Rückkehr USB abziehen, dann RUN wählen. `GND_LOGIC` wird nie geschaltet. Die Bus-Masse bleibt galvanisch getrennt.

**SW3 = G-Switch MK-12C02-G020 / C963206.** Das Herstellerblatt beschreibt seitliche Betätigung, SPDT, 1 A bei 6 V, höchstens 100 mΩ Kontaktwiderstand und −20…70 °C. Gehäuse 6,6 × 2,7 × 1,4 mm, Betätigerlänge G020 = 2,0 mm, Weg 1,5 mm. Die übernommenen sieben Lötflächen umfassen drei Kontakte und vier separat nummerierte Gehäuseanker. Zwei nichtmetallisierte 1,0-mm-Bohrungen bei x=±1,5 mm sind die explizite Engineering-Zugabe für die 0,70±0,05-mm-Positionierzapfen; der Hersteller nennt keinen Bohrdurchmesser. [Herstellerzeichnung MK-12C02-GXXX X1, über Distributor](https://static.chipdip.ru/lib/011/DOC043011829.pdf), [JLC-Bauteil](https://jlcpcb.com/partdetail/gswitch-MK_12C02G020/C963206).

Die Zeichnung ordnet Strompfad A dem linken Kontakt/Common und B dem Common/rechten Kontakt zu, aber nicht eindeutig einer Bewegungsrichtung des Hebels. Darum ist die elektrische Belegung festgelegt, eine linke/rechte Gehäusepfeil-Beschriftung jedoch erst nach Durchgangsprüfung des gelieferten Schalters freizugeben. Das 3D-Modell stellt eine Schaltposition dar; der Gehäuseausschnitt berücksichtigt den ganzen Weg. Die aktuelle JLC-Seite meldete am Prüftag `InStock`, SMT und Economic/Standard; dies ist keine Reservierung.

## Warum die sekundäre Regelung bleibt

Der EVISUN-Wandler ist unreguliert: Bei nominalem Eingang reicht die veröffentlichte Ausgangshülle von 5,00…5,50 V bei 10 % Last bis 4,625…5,125 V bei Volllast. Mindestlast 60 mA, Maximalstrom 600 mA. Die Vorlast R20/R21 bleibt deshalb **vor U4 und SW3** angeschlossen, auch in SERVICE. 150 Ω parallel zu 150 Ω ergeben 75 Ω beziehungsweise 66,7 mA/0,333 W bei 5 V. Bei 4,625 V und +1 % Widerstand bleiben 61,1 mA. Die 0,5-W-Widerstände sind einzeln ausreichend dimensioniert; ihre Wärme ist trotzdem abzuleiten. [EVISUN B_S-3WR2 V1.0, S.1–3](https://resources.ampheo.com/static/datasheets/evisun/20240927/b2405s-3wr2.pdf).

Die Regelstufe hält die Rohspannung im stationär geregelten Zustand vom Modul fern. Aus Ausgangshülle, Line-Regulation und typischem Temperaturkoeffizienten lässt sich keine garantierte maximale Einschaltspitze ableiten. Deshalb ist „U4 vorhanden“ kein Ersatz für die Einschalt-/Lastabwurfmessung am Modul-5V-Pin. Ebenso ist im Dropout kein durchgehend geregelter 5-V-Ausgang garantiert.

## Leistungsreserve und Grenzen

Als Design-Rechenfall werden **400 mA an der Modul-5V-Zuführung** angesetzt. Espressif nennt im RF-Datenblatt beispielsweise 335 mA für 802.11b bei 21 dBm; das ist ein veröffentlichter Messwert unter definierten Bedingungen, kein absoluter Maximalstrom aller Zustände. Die Differenz von 65 mA dient im Rechenfall als Reserve für Modulverbrauch und zusätzliche ISO-Logik. Es wird kein erfundener BLE-Maximalstrom angesetzt. [ESP32-C3-Datenblatt v2.4, S.56, Tabelle RF-Stromaufnahme](https://www.espressif.com/sites/default/files/documentation/esp32-c3_datasheet_en.pdf).

| Rechengröße | Ansatz / Ergebnis |
|---|---:|
| Modul-Zuführung | 5 V × 0,400 A = 2,000 W |
| U4-Wirkungsgrad, Engineering-Annahme | 85 % |
| Niedrige Rohspannung im Rechenfall | 4,625 V |
| U4-Eingangsstrom | 2 / 0,85 / 4,625 = 0,509 A |
| Vorlast bei −1 % Widerstand | 4,625 / 74,25 = 0,0623 A |
| U2-Ausgangsstrom gesamt | **0,571 A < 0,600 A** |
| U2-Ausgangsleistung | 2,641 W < 3 W |
| Erforderlicher U4-Wirkungsgrad für diesen Fall | mindestens 80,42 % |
| Primärstrom bei 9 V, 82 % U2, 80 % U3, 0,7 V D5 und CAN 73,4 mA | etwa 0,540 A vor kleinen F1-/Leiterbahnverlusten |

Der Ansatz mit geregelten 5 V bei 4,625 V Eingang ist für die Leistungsverbrauchsrechnung absichtlich konservativ; real sinkt dort die Ausgangsspannung im Dropout. Die verwendeten Wirkungsgrade sind keine zugesicherten Mindestwerte dieser gesamten Betriebskombination. LEN 12 reserviert vorläufig 600 mA am Bus und ist durch die Messung über 9…16 V zu bestätigen. CAN-73,4-mA-Ansatz: [TI ISO1042, Versorgungsstrom](https://www.ti.com/lit/ds/symlink/iso1042.pdf).

Espressif empfiehlt eine 3,3-V-Quelle mit mindestens 500 mA Versorgungsfähigkeit. Der R4-Nachweis für 3,3 V/500 mA darf nicht auf den zusätzlichen Modul-LDO übertragen werden. **Dauerhaft garantierte 5 V/500 mA werden für R5 mit diesem Wandler nicht behauptet.** In der Nähe des Dropouts ist dieser Strom typischerweise günstiger als eine pauschale Wirkungsgradrechnung vermuten lässt; die Datenblätter sichern die Gesamtreserve und die Wärme des konkreten SuperMini jedoch nicht ab. [Espressif Hardware Guidelines](https://docs.espressif.com/projects/esp-hardware-design-guidelines/en/latest/esp32c3/schematic-checklist.html).

Spannungsreserve als reine Abschätzung bei 400 mA: Angenommene 0,25 Ω für den warmen High-Side-Schalter, 0,078 Ω Induktivität, 0,05 Ω Leiterbahnen und maximal 0,10 Ω SW3 ergeben 0,191 V Abfall. Aus 4,625 V würden am Modul etwa 4,434 V. Die 0,25 Ω sind bewusst das Doppelte des typischen 125-mΩ-Wertes, **kein garantierter Höchstwert**. Nach der Moduldiode muss der ME6211 noch genügend Reserve für 3,3 V behalten. Der reale Regler und die thermische Ausführung des gelieferten Moduls sind daher messrelevant.

## Layout und Prototypprüfung

- Primär-/Sekundär-Kupferabstand auf beiden Lagen mindestens 3,2 mm. R20/R21 außerhalb des Moduls und frei von Gehäusekontakt platzieren.
- Haupt-Versorgungspfade bevorzugt 0,5 mm, mindestens 0,4 mm breit führen. FB wird separat am ruhigen Ausgang C32/C33 abgegriffen; die dünne Sense-Leitung darf nicht die Modul-Hauptversorgung sein.
- C29/C30 an U4 VIN/GND, C31 an BST/SW, L3 und C32/C33 eng zusammen. C34 an Modul-5V/GND, C5 an U1 VCC1/GND1.
- Erster Prototyp: Start, Wiederanlauf und Lastabwurf bei 9/12/16 V; gleichzeitig `5V_ISO`, `5V_MODULE` und `3V3_LOGIC` messen. Keine Modul-Eingangsspitzen über den zulässigen Bereich und keine 3,3-V-Einbrüche außerhalb des ESP-Betriebsbereichs akzeptieren.
- BLE-Empfang, WLAN-Portal und höchste erlaubte TX-Leistung prüfen; 400-mA-Lastsprünge und zusätzliche 500-mA-Transienten messen, um die verbleibende reale Reserve festzustellen. Dabei keine ungeprüfte Dauerlastangabe ableiten.
- Geschlossenes Gehäuse thermisch prüfen: Modul-LDO, U2, U3/U4 und Vorlast. Die Bauteilgrenze des Schalters ist 70 °C; der Wandler muss oberhalb 71 °C zusätzlich abgeregelt werden. Daraus folgt keine automatisch qualifizierte maximale Gehäuseumgebungstemperatur.
- SERVICE zunächst stromlos per Ohmmeter prüfen: Pin 1 ist vom Modul-5V getrennt, Masse bleibt verbunden. Anschließend USB-only und USB+Bus in SERVICE auf Rückspeisung prüfen. RUN niemals mit angeschlossenem USB testen.

Maschinenlesbare Daten: `power-components.json`, `power-review.json`. Reproduzierbarer Generator: `tools/r5_power.py`. Die abschließende Altium-/Gerber-Prüfung gehört zum integrierten R5-Stand und wird separat dokumentiert.
