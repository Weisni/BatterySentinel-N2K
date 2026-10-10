# Elektrische Prüfung und R4-Versorgung

Prüfdatum: 23. September 2026. Diese Prüfung betrifft die Schaltungsarchitektur und die angegebenen Bauteile. Die endgültige Gerber-/Netzlistenprüfung und die Prüfung der integrierten R4-Dateien sind separate Nachweise. Bauteilverfügbarkeit wird im Beschaffungsnachweis geführt.

## Konkrete Befunde zu R3

- **Start bei 9 V nicht abgesichert:** Der R3M-2405S/SMD benötigt mindestens 9 V an seinen Pins. Sicherung, Verpolschutz und Eingangsfilter liegen davor. Ein Anschluss mit genau 9 V unterschreitet daher seinen spezifizierten Eingangsbereich. [RECOM R3M](https://recom-power.com/pdf/Econoline/R3M.pdf).
- **Unnötiger Wärmeeintrag:** Der lineare 5-V-Regler trägt bei 16 V Eingang und 73,4 mA maximalem dominanten ISO1042-Versorgungsstrom etwa `(16−5) × 0,0734 = 0,807 W` Verlustleistung. Diese Abschätzung war in R3 bekannt; ein DRC prüft sie nicht. [TI ISO1042](https://www.ti.com/lit/ds/symlink/iso1042.pdf).
- **SuperMini-Footprint nicht als Serienmodul qualifiziert:** Das alte Modul setzt konkrete Headerhöhe und eine ungesicherte Modulrevision voraus. Bauteile unter dem Modul sind bei flacher Castellated-Montage im Weg. R4 verwendet ein dokumentiertes, beschaffbares Espressif-Modul samt Hersteller-Landpattern und eigener USB-/Reset-Beschaltung.
- **Manueller USB-Jumper:** JP1 kann beim Service vergessen werden. Zwei Entkopplungsdioden übernehmen diese Funktion in R4 automatisch.
- **Fertigungsdaten benötigen konkrete Bauteile:** Generische Kondensatoren, Dioden, Widerstände sowie ein nicht als JLC-Bauteil identifizierter DC/DC-Wandler reichen für eine direkte Bestückungszuordnung nicht aus.

## Gewählte Versorgung

`NET_S → F1 → D5 → BUS_PROT → U3/AP63205 → 5V_BUS`

`5V_BUS → U2/B0505S-3WR2 → 5V_ISO → D2 → 5V_SYS`

`USB_VBUS → D4 → 5V_SYS → U4/AP63203 → 3V3_LOGIC`

`GND_BUS` und `GND_LOGIC` bleiben galvanisch getrennt. U1 erhält seine CAN-Versorgung aus `5V_BUS` und seine Logikversorgung aus `3V3_LOGIC`. USB-Masse gehört ausschließlich zur Logikseite. D2 und D4 führen an ihren Kathoden zusammen. Die Entkopplung verhindert eine direkte Rückspeisung der Versorgungsquellen; der Sperrstrom realer Dioden ist nicht null.

**U3/U4:** Hersteller-Pins 1=FB, 2=EN, 3=VIN, 4=GND, 5=SW, 6=BST. Die Festspannungsvarianten benötigen eine direkte FB-Verbindung zum Ausgang, keinen Spannungsteiler. Bootstrap jeweils 100 nF zwischen BST und SW. Hersteller-Vorschlag für 5 V: 4,7 µH und zweimal 22 µF. Die 3,3-V-Stufe verwendet ebenfalls 4,7 µH statt 3,9 µH als dokumentierte Engineering-Auslegung für ihren niedrigen Eingangsspannungsbereich; bei 5,5 V beträgt die berechnete Stromwelligkeit etwa 0,28 A. [Diodes AP6320x, Schaltung und Landpattern](https://www.diodes.com/assets/Datasheets/AP63200-AP63201-AP63203-AP63205.pdf).

**U2:** EVISUN B0505S-3WR2, JLC C7500927, nominell 5 V hinein und 5 V/600 mA heraus. Dieses Bauteil hat **Pin 1=VIN, 2=GND, 4=0V, 6=+VO**. Das unregulierte Ausgangssignal wird anschließend durch U4 geregelt. R20/R21 bilden eine ständige Last von insgesamt 75 Ω, auch wenn USB die Logik versorgt. Bei 5 V: 66,7 mA und 0,333 W insgesamt, also 0,167 W je 0,5-W-Widerstand. Keine herstellerübergreifende Substitution anhand des Kurznamens vornehmen. [EVISUN-Herstellerdatenblatt, distributor-hosted](https://resources.ampheo.com/static/datasheets/evisun/20240927/b2405s-3wr2.pdf), [JLC-Bestückungsbauteil](https://jlcpcb.com/partdetail/EVISUN-B0505S_3WR2/C7500927).

**D5/D1:** Der 60-V-Schottky-Verpolschutz spart den großen MOSFET und dessen Gatebeschaltung. Der folgende Buck hat genügend Spielraum für den Diodenabfall bei 9 V Busspannung. SMBJ18A hat 18 V Sperrarbeitsspannung und einen spezifizierten Klemmwert von 29,2 V am angegebenen Prüfstrom; dies passt erheblich besser zum 32-V-Betriebsbereich des AP63205 als die frühere SMBJ20A. Die TVS-Schleife muss direkt und kurz zum Bus-Masseanschluss führen. Das ist eine Bauteilabstimmung, kein Nachweis einer bestandenen System-Surgeprüfung. [SMBJ-Herstellerdatenblatt](https://m.littelfuse.com/~/media/electronics/datasheets/tvs_diodes/littelfuse_tvs_diode_smbj_datasheet.pdf.pdf).

## Leistungsbudget

Die Auslegung zielt auf mindestens 500 mA für den ESP an 3,3 V; dies entspricht der Espressif-Empfehlung. Der zusätzliche ISO1042-Logikbedarf ist mit 3,5 mA im Rechenfall berücksichtigt. [Espressif Hardware Design Guidelines](https://docs.espressif.com/projects/esp-hardware-design-guidelines/en/latest/esp32c3/schematic-checklist.html).

Konservativer Engineering-Rechenfall, kein gemessener Wirkungsgradnachweis:

| Größe | Ansatz |
|---|---:|
| Logikleistung | 3,3 V × 0,5035 A = 1,662 W |
| U4-Wirkungsgrad | 80 % angenommen |
| Isolierte Spannung für den Rechenfall | 4,625 V |
| D2-Spannungsabfall | 0,55 V, SS14-Herstellermaximum bei 1 A |
| U4-Eingangsstrom | 1,662 W / 0,8 / 4,075 V = 0,510 A |
| Vorlaststrom bei 4,625 V | 0,0617 A |
| U2-Ausgangsstrom insgesamt | rund 0,572 A < 0,600 A |
| U2-Ausgangsleistung | rund 2,644 W < 3 W |
| U2-Wirkungsgrad | 82 % Ansatz entsprechend Hersteller-Mindestwert bei Nennbedingungen |
| Zusätzliche CAN-Busseite | 5 V × 73,4 mA = 0,367 W |
| U3-Wirkungsgrad | 80 % angenommen |
| Busstrom bei 9 V einschließlich D5/F1-Verlusten | etwa 0,54–0,55 A |

Für D2/D4 ist die ausgewählte MDD SS14 maßgeblich: maximal 0,55 V Vorwärtsspannung bei 1 A laut aktuellem Herstellerdatenblatt, nicht der frühere 0,50-V-Ansatz. Der obige Rechenfall lässt 0,275 V bis zur 3,8-V-Mindestbetriebsspannung von U4. Selbst bei nur 4,5 V vor D2 bleiben rechnerisch 3,95 V, also 0,15 V Reserve vor Leiterbahnverlusten; diese Verbindungen müssen kurz und breit bleiben. [MDD SS14](https://www.lcsc.com/datasheet/lcsc_datasheet_2407101109_MDD-Microdiode-Semiconductor-SS14_C2480.pdf).

Die Modul-Deratingkurve begrenzt die volle 3-W-Leistung oberhalb 71 °C. R4 darf deshalb nicht allein aus den Einzelbauteil-Grenzwerten als 85-°C-Vollastgerät bezeichnet werden. Die realen Temperatur-, Start- und Lastsprungtests bleiben Teil der Inbetriebnahme.

Für die vorläufige Netzplanung **LEN 12 = 600 mA** reservieren. Der frühere Textwert LEN 9 gilt für die geänderte Versorgung nicht. Das neue Firmwareprofil `orion_r4` übergibt LEN 12 und Modellrevision R4 explizit an `SetProductInformation`; die übrigen Firmwareprofile behalten ihre bisherigen Vorgaben. Die tatsächliche maximale Aufnahme ist später über 9–16 V einschließlich Funkbetrieb zu messen.

## Verbindliche Layoutpunkte

- Beide Schaltregler als zusammenhängende Funktionszellen platzieren: Eingangskondensator an VIN/GND, Bootstrap direkt an BST/SW, Induktivität neben SW, Ausgangskondensatoren neben der Induktivität. Kleine SW-Fläche, keine Signale darunter; FB am ruhigen Ausgang abgreifen.
- Mehrere kurze Masseverbindungen statt einer langen gemeinsamen Rückleitung; Funk- und USB-Bereich vom Schaltknoten und von der DC/DC-Magnetik trennen.
- R20/R21 frei platzieren, nicht unter dem Funkmodul; ausreichend Kupferfläche zum Verteilen ihrer zusammen etwa 0,33 W Wärme.
- Den 3,2-mm-Abstand zwischen Bus- und Logik-Kupfer auf **allen Kupferlagen** erhalten. Der SIP-Footprint hat bei 1,6-mm-Pads 3,48 mm Kupferabstand zwischen Pin 2 und 4. Die Isolator-Bauteilprüfung ist keine Hochspannungs-Freigabe der Gesamtplatine.
- C4 direkt an U1 VCC2/GND2 und C5 direkt an U1 VCC1/GND1. TXD-Pull-up beibehalten, damit Reset oder ein hochohmiger MCU-Pin den Bus nicht dominant hält.
- CANH/CANL kurz, zusammen und ohne unnötige Stichleitungen führen. Der Drop erhält keinen eigenen 120-Ω-Abschluss. TVS nahe Anschluss und gemeinsame Drossel nahe Transceiver; Bus-Masse und Schirm nicht unabsichtlich über Montagebohrungen verbinden.
- Die Funkmodul-Antenne über die Trägerkante setzen und den Hersteller-Freiraum ohne Kupfer, Leiterbahnen, Bauteile oder Gehäusemetall erhalten. Eine runde Leiterplattenecke darf diese Freiraumdefinition nicht verkleinern.
- USB-D+/D− zusammen über durchgehender Logikmasse führen, ESD-Schutz an die Buchse und Serienwiderstände an den ESP. Vorsehen von BOOT und RESET ermöglicht die Erstprogrammierung der leer gelieferten Module.

Die bevorzugten 0,5-mm-Versorgungsleiterbahnen sind keine Mindestbreite für jeden Ast desselben Netzes: Feedback, Pull-ups und lokale Entkopplung dürfen schmaler angebunden sein. Der unabhängige Prüfer verfolgt deshalb zusätzlich die tatsächlichen Lastpfade zwischen Anschluss, Sicherung, Dioden, Reglern, Induktivitäten und ESP. Die Hauptpfade erhalten mindestens 0,4 mm; die USB-Zuführung wird separat mit mindestens 0,2 mm geprüft. Insbesondere muss L3/C32 den ESP über einen eigenen Lastpfad versorgen. Die ruhige 0,2-mm-Feedback-Verbindung zum Regler darf nicht den Hauptstrom des Funkmoduls führen.

**USB-ESD-Durchführung:** Beim ausgewählten ST USBLC6-2SC6 sind Pin 1↔6 und Pin 3↔4 intern direkt verbunden. Das Hersteller-Funktionsdiagramm wurde dafür separat geprüft. Die Buchse führt `USB_DM_IN` an Pin 1 und `USB_DP_IN` an Pin 3; Pin 6 führt als `USB_DM` zu R11, Pin 4 als `USB_DP` zu R12. Damit verläuft der Signalweg durch das Schutzbauteil. Die unterschiedlichen Netznamen vor und hinter D6 bezeichnen die äußeren Leiterbahnabschnitte; die interne Durchleitung erfolgt im bestückten IC. [ST USBLC6-2, Funktionsdiagramm S. 1 und Layout S. 6](https://www.st.com/resource/en/datasheet/usblc6-2.pdf).

## Einordnung der ERC-Meldungen zu Eingangstreibern

Altium verfolgt eine Treiberfunktion nicht automatisch durch passive Widerstände oder die interne Bootstrap-Schaltung eines Reglers. Deshalb können die folgenden konkret abgegrenzten Netze als „no driving source“ erscheinen, obwohl die Schaltung eine definierte Funktion hat:

- `BST_BUS` und `BST_LOGIC`: jeweils der Bootstrap-Anschluss des AP6320x und sein 100-nF-Kondensator zum Schaltknoten. Die Ladung und Ansteuerung entstehen intern im Regler.
- `ESP_EN`: R5 zieht den Eingang auf 3,3 V, C10 bildet die Einschaltverzögerung und SW2 zieht ihn für Reset auf Masse.
- `TXD`: GPIO6 treibt den ISO1042-Eingang über den Serienwiderstand R3; R2 hält den Ruhezustand während Reset.
- `GPIO7`: der ISO1042-Ausgang RXD treibt den MCU-Eingang über R4. Bei korrekter Einstufung des MCU-Pins als Eingang kann hier dieselbe Einschränkung des ERC-Modells auftreten.

Diese Begründungen gelten nur für die genannten Netze mit den geprüften Verbindungen. Die allgemeine ERC-Prüfung wird nicht abgeschaltet. GPIO6 ist im Schaltplansymbol als Ausgang, GPIO7 als Eingang, die übrigen GPIO-/USB-Pins als bidirektional und EN als Eingang zu deklarieren. Die endgültige Anzahl der Altium-Meldungen steht im separaten nativen Prüfprotokoll.

## Abschließende Prüfung des erzeugten R4-Standes

Die native Altium-Projektprüfung am 23.09.2026 um 12:13:30 wurde ohne Fehler abgeschlossen. Es blieben genau die fünf oben begründeten Hinweise zu `BST_BUS`, `BST_LOGIC`, `ESP_EN`, `GPIO7` und `TXD`. Die anschließende native DRC auf der erneut geöffneten Platine meldete um 12:25:32 **keine Verletzungen und keine freigestellten Verletzungen**.

Der unabhängige Abgleich prüft beide Schaltplanblätter, 52 lokale Symbolkomponenten, 21 Footprints und die gespeicherte native PCB6-Datei. Alle 35 Netze sind verbunden. Die 13 separat geprüften Versorgungspfade bestehen ebenfalls; die ESP-Hauptversorgung verläuft über die ergänzte breite Zuleitung. Quelle, nativer Leiterplattenstand und die Bestückungslisten stimmen überein. Nachweise: [Gesamtprüfung](independent-verification.json), [native PCB-Prüfung](native-binary-verification.json) und [unabhängige Panelprüfung](JLCPCB-Panel/independent-panel-verification.json).

**Verhalten der Altium-Kantenregel:** Altium speichert eine einheitliche Kantenfreiheit als `GENERICCLEARANCE`; das Feld `OBJECTCLEARANCES` kann dabei leer bleiben. Außerdem zeigt die alte Zusammenfassungszeile des DRC-Berichts irreführend `Gap=0mil`. Deshalb wurde die Funktion separat geprüft: Die vorübergehende Verschärfung auf 0,31 mm erzeugte 51 konkrete Kantenverletzungen, beispielsweise 12,008 mil Abstand bei 12,205 mil Mindestabstand. Nach Rückkehr auf 0,30 mm, Speichern und erneutem Öffnen bestanden alle Prüfungen. Der Prüfer akzeptiert diese Darstellung nur zusammen mit dem archivierten [nativen Negativtest](validation/BoardEdge-negative-0_31mm.drc), den [gespeicherten Regelwerten](validation/BoardEdge-negative-0_31mm-rule.json) und dem jüngeren fehlerfreien Abschlusslauf. Der absichtlich fehlgeschlagene Negativtest ist kein Fehler des ausgelieferten Layouts.

## Umfang der Fertigungsfreigabe

Nach Integration sind Netz-/Pinabgleich, DRC, tatsächliche Gerber-Geometrie, Leiterplattenkontur, Lötstopp/Paste, THT-Bohrungen sowie BOM/CPL-Koordinaten unabhängig zu prüfen. Das kann ein bestellbares PCBA-Paket ergeben. Eine bestandene DRC und eine bestellbare Stückliste ersetzen keinen elektrischen Funktionstest, keine NMEA-Zertifizierung und keine Messung der EMV oder Gehäusetemperatur am bestückten Gerät.
