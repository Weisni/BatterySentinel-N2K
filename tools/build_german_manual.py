"""Build the German Orion-R5 user manual with ReportLab; no hardware changes.

Run with the bundled Python runtime. Screenshots come from capture_manual_portal.cjs.
Each chapter is deliberately one page; overflow fails instead of clipping content.
"""
from pathlib import Path
import json
import hashlib
from xml.sax.saxutils import escape
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor, Color, white
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph, Table, TableStyle, Image, Spacer, Flowable
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase.pdfdoc import PDFString
from PIL import Image as PILImage
from reportlab.graphics.barcode.qr import QrCodeWidget
from reportlab.graphics.shapes import Drawing

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/pdf/BatterySentinel-N2K-Orion-R5-Betriebs-und-Installationsanleitung-DE.pdf'
ASSETS = ROOT / 'docs/manual-assets'
NAVY = HexColor('#071521')
SURFACE = HexColor('#102437')
TEAL = HexColor('#68e3d1')
BLUE = HexColor('#8abffd')
INK = HexColor('#142e40')
MUTED = HexColor('#486274')
PALE = HexColor('#eef6f7')
LINE = HexColor('#ccdce3')
GOLD = HexColor('#f4ca84')
RED = HexColor('#ff9c9b')
W, H = 595.276, 841.89
M, CW = 43, 509.276

for name, filename in [('Body','segoeui.ttf'),('Bold','segoeuib.ttf'),('Light','segoeuil.ttf')]:
    pdfmetrics.registerFont(TTFont(name, 'C:/Windows/Fonts/' + filename))
pdfmetrics.registerFontFamily('Body', normal='Body', bold='Bold', italic='Body', boldItalic='Bold')
ST = {
    'p': ParagraphStyle('body', fontName='Body', fontSize=10.5, leading=15.4, textColor=INK, spaceAfter=9),
    'h': ParagraphStyle('subhead', fontName='Bold', fontSize=13.5, leading=18, textColor=INK, spaceBefore=8, spaceAfter=7),
    'small': ParagraphStyle('small', fontName='Body', fontSize=8.6, leading=12, textColor=MUTED),
    'cell': ParagraphStyle('cell', fontName='Body', fontSize=9.6, leading=13.5, textColor=INK),
    'cellhead': ParagraphStyle('cellhead', fontName='Bold', fontSize=9.6, leading=13, textColor=white),
}
PAGES = []
def page(title, subtitle, *blocks): PAGES.append((title, subtitle, blocks))
def p(text): return ('p', text)
def h(text): return ('h', text)
def note(title, text, kind='info'): return ('note', title, text, kind)
def steps(*items): return ('steps', items)
def table(headers, rows, widths=None): return ('table', headers, rows, widths)
def pic(name, height, caption): return ('pic', name, height, caption)
def diagram(kind): return ('diagram', kind)

page('So nutzen Sie diese Anleitung', 'ORIENTIERUNG',
 p('Diese Anleitung begleitet Sie vom Einbau bis zum täglichen Betrieb der <b>BatterySentinel-N2K Orion-R5 / Orion-Bridge</b>. Ausgabe vom <b>10. Oktober 2026</b> für Firmware <b>1.2.0</b> mit der Kennung <b>orion_dongle</b> auf einem ESP32-C3 SuperMini mit 4 MB Speicher.'),
 note('Vor der ersten Verbindung speichern', 'Speichern Sie diese PDF auf dem Handy oder drucken Sie sie aus. Das Geräte-WLAN stellt kein Internet bereit. Zugangsdaten und diese Anleitung sollten schon vorher verfügbar sein.'),
 table(['Ihr nächster Schritt', 'Seiten'], [
 ['Sicherheit und Funktionsprinzip verstehen', '3-4'],
 ['Einbau vorbereiten, Netzwerk und Anschlüsse prüfen', '5-7'],
 ['USB-Service, WLAN und Administratorkonto', '8-10'],
 ['Orion verbinden und Kanäle zuordnen', '11-12'],
 ['Webinterface und Diagnose verstehen', '13-15'],
 ['Garmin und gesamte Installation prüfen', '16'],
 ['Alltag, Wartung, Updates und Wiederherstellung', '17-18'],
 ['Fehlerhilfe: Zugang / Orion / NMEA 2000', '19-21'],
 ['Übergabe, Daten, Quellen; Auswertung und Meldungen', '22-27'],
 ['QR-Ersteinrichtung, Tischprüfung und Fehlerfolgen', '28-30']], [0.82,0.18]),
 h('Bedienung und Einbau haben unterschiedliche Voraussetzungen'),
 p('Die Einrichtung im Browser können Sie selbst durchführen. Für offene Kabelenden, die Montage einer unbestückten Platine, elektrische Messungen und Änderungen am Bordnetz benötigen Sie eine mit Bootselektrik vertraute Fachperson. Diese Anleitung setzt eine fachgerecht fertiggestellte und geprüfte R5-Baugruppe voraus.'),
 note('Gültigkeit', 'Diese Anleitung beschreibt die Orion-Bridge mit ESP32-C3 SuperMini und der R5-Baugruppe. Prüfen Sie die Gerätekennzeichnung und die installierte Firmware. Für Anschluss und Versorgung gelten die beschriebenen RUN-/SERVICE-Schritte.', 'warn'))

page('Sicher einbauen und betreiben', 'ZUERST LESEN',
 note('WARNUNG · Kurzschluss und Brandgefahr', 'Arbeiten an Kabeln und offenen Anschlüssen nur bei abgeschalteter und gegen Wiedereinschalten gesicherter Versorgung. Eine Bootsbatterie kann bei Kurzschluss sehr hohe Ströme liefern. Keine losen Drähte, Werkzeuge oder offene Platinen im eingeschalteten Bordnetz verwenden.', 'danger'),
 h('Die fünf wichtigsten Regeln'),
 steps(('USB nur in SERVICE', 'Vor dem Einstecken eines USB-Kabels auf SERVICE schalten. USB zuerst abziehen, bevor Sie wieder RUN wählen. RUN und USB dürfen nicht gleichzeitig verwendet werden.'),
 ('Nur die vorgesehene Versorgung', 'Die fertige Bridge wird am NMEA-2000-Netz mit 9-16 V Gleichspannung betrieben. Niemals 12 V direkt an USB, den 5V-Pin oder einen anderen Anschluss des SuperMini anlegen.'),
 ('Trocken und geschützt montieren', 'Nicht in Bilge, Spritzwasserbereich oder ungeschützt im Freien installieren. Für das Projektgehäuse sind keine geprüfte IP-Schutzart und keine freigegebene Umgebungstemperatur dokumentiert.'),
 ('Trennung und Busaufbau erhalten', 'Die isolierte USB-/Logikmasse nicht mit der Busmasse verbinden. Keine zusätzlichen Abschlusswiderstände an die Bridge setzen. Anschlüsse nur nach dem aktuellen R5-Schaltplan ausführen.'),
 ('Anzeigen richtig einordnen', 'Die Bridge ersetzt keine Batterieüberwachung, Ladegeräteschutzfunktion oder vorgeschriebene Sicherheitseinrichtung. Bei fehlenden Daten und vor wichtigen Entscheidungen am Ladegerät bzw. mit geeigneter Messtechnik gegenprüfen.')),
 h('Sofort abschalten bei auffälligem Verhalten'),
 p('Bei Rauch, verschmortem Geruch, Feuchtigkeit im Gehäuse, beschädigten Leitungen oder ungewöhnlich starker Erwärmung die betroffene Versorgung sicher abschalten. Gerät nicht wieder einschalten, bis eine Fachperson die Ursache behoben hat.'),
 note('Projektstatus', 'Orion-R5 ist ein Eigenbau-Prototyp. Der dokumentierte elektrische Entwurf und eine fehlerfreie CAD-Regelprüfung sind kein Nachweis einer NMEA-2000-Zertifizierung oder einer abgeschlossenen Bordabnahme. Die Prüfungen auf Seite 16 bleiben erforderlich.', 'warn'))

page('Was die Orion-Bridge macht', 'FUNKTION VERSTEHEN',
 p('Die Bridge empfängt die verschlüsselten Bluetooth-Messdaten Ihres Orion-Ladegeräts und übersetzt sie für das NMEA-2000-Netz. Ein kompatibler Kartenplotter kann diese Daten anzeigen. Das Handy dient der lokalen Einrichtung und Diagnose.'),
 diagram('flow'),
 table(['Das erhalten Sie', 'Das bedeutet es'],[
 ['Eingangs- und Ausgangsspannung in V', 'Spannungen, die der Orion an seinen Anschlüssen meldet.'],
 ['Eingangs- und Ausgangsstrom in A', 'Stromfluss durch den Orion; weitere Verbraucher und Ladequellen werden nicht mitgemessen.'],
 ['Leistung in W im Webinterface', 'Aus Spannung × Strom berechnet, keine eigene Leistungsmessung.'],
 ['Ladegerätstatus, Fehler und Abschaltgrund', 'Informationen des Orion; ein ausgeschaltetes Ladegerät kann ein normaler Betriebszustand sein.'],
 ['Empfangs- und Sendediagnose', 'Hilft, Funkprobleme von Netzwerkproblemen zu unterscheiden.']],[0.4,0.6]),
 note('Keine Ladeanzeige in Prozent', 'Die Bridge berechnet weder Ladezustand (SOC), Restlaufzeit noch Batteriegesundheit und steuert den Orion nicht. Konfigurierbare Warnungen und beobachtete Orion-Ladung/Energie sind auf Seiten 25-27 erklärt. Fehlende Temperatur- oder SOC-Werte sind erwartbar.'),
 p('Nach abgeschlossener Einrichtung arbeitet die Bridge ohne Handy weiter. Ein geschlossenes Service-WLAN beendet die lokale Bedienung, nicht die Übersetzung der Orion-Daten. Ein Ausfall der Bridge soll die Orion-Ladefunktion selbst nicht verändern.'))

page('Vorbereitung und Lieferumfang prüfen', 'INSTALLATION · 1 VON 3',
 h('Das sollte vorliegen'),
 table(['Benötigt', 'Prüfung vor dem Start'],[
 ['Fertige Orion-R5-Baugruppe', 'SuperMini-C3 mit passender Firmware, isolierte CAN-Anbindung, geprüfter RUN/SERVICE-Schalter und geeignetes Gehäuse.'],
 ['Orion-Ladegerät', 'Exakte Modellbezeichnung und Firmware notieren. Instant Readout muss verfügbar sein und zum unterstützten Datenformat passen.'],
 ['NMEA-2000-Netz', 'Betriebsfähiger, abgesicherter Backbone mit zwei Endabschlüssen, freiem T-Stück und ausreichender Stromreserve.'],
 ['Passendes Anschlusskabel', 'Micro-C-Dropkabel, für die konkrete Installation passend. Offene Kabelenden nur durch eine Fachperson anschließen.'],
 ['Handy oder Computer', 'WLAN und aktueller Browser. VictronConnect zur Vorbereitung der Orion-Zugangsdaten.'],
 ['USB-Service bei Bedarf', 'Computer, USB-Datenkabel und serieller Monitor mit 115200 Baud. Ein reines Ladekabel reicht nicht.']],[0.32,0.68]),
 h('Kompatibilität zuerst klären'),
 p('Die Firmware ist auf das implementierte Orion-XS-Instant-Readout-Format ausgelegt. Nicht jedes Victron-Gerät mit Bluetooth oder Instant Readout ist kompatibel. Im Projekt liegt ein erfolgreicher Empfangsbericht mit der vom Nutzer genannten Bezeichnung „Orion XC1400“ vor; daraus folgt keine Freigabe sämtlicher Orion-Modelle. Prüfen Sie Ihr konkretes Gerät wie auf Seite 16 beschrieben.'),
 h('Einbauort auswählen'),
 p('Wählen Sie einen trockenen, mechanisch geschützten Platz in Funkreichweite des Orion. Vermeiden Sie ein Metallgehäuse oder Metallflächen direkt vor der Antenne. BOOT, RESET, USB und RUN/SERVICE müssen für Service erreichbar bleiben. Kabel dürfen nicht scheuern oder unter Zug stehen.'),
 note('Keine feste Funkreichweite zugesichert', 'Probieren Sie den Empfang am geplanten Einbauort mit geschlossenem Gehäuse aus, bevor Sie die Bridge endgültig befestigen. Metall, Einbauten und Abstand beeinflussen den Empfang.'))

page('In das Bordnetz einbinden', 'INSTALLATION · 2 VON 3',
 diagram('bus'),
 steps(('Netz spannungsfrei schalten', 'NMEA-2000-Versorgung abschalten. Vorhandenen Aufbau dokumentieren. Der Backbone ist die durchgehende Hauptleitung; die Bridge kommt an einen Geräteabzweig.'),
 ('T-Stück und Dropkabel anschließen', 'Die geraden Anschlüsse des T-Stücks gehören zur Hauptleitung, der Geräteanschluss zum Abzweig. Das Dropkabel zur Bridge führen; ein einzelner Abzweig darf höchstens 6 m lang sein. [H1]'),
 ('Abschlüsse beibehalten', 'An jedem Ende der Hauptleitung sitzt ein 120-Ohm-Abschluss. Die Bridge erhält keinen zusätzlichen Abschlusswiderstand. Zusätzliche Widerstände stören den Bus. [H2]'),
 ('Montage abschließen', 'Gehäuse sicher befestigen, Kabel zugentlasten, Stecker nach Herstellerangabe schließen. RUN wählen und sicherstellen, dass kein USB-Kabel eingesteckt ist.'),
 ('Versorgung einschalten', 'Erst nach Anschlusskontrolle einschalten. Innerhalb des WLAN-Zeitfensters verbinden oder später BOOT länger als zwei Sekunden drücken.')),
 note('Strombedarf einplanen', 'Für R5 sind vorläufig 12 LEN reserviert, entsprechend 600 mA Netzbudget. Das ist eine Planungsreserve und kein gemessener Dauerverbrauch. Die Fachperson prüft Versorgung und Spannungsabfall für das gesamte Netzwerk. [P3, H1]', 'warn'),
 p('Keine zusätzliche Netzeinspeisung improvisieren. Bei bereits versorgtem NMEA-Netz muss die vorhandene Stromversorgung zum erweiterten Aufbau passen. Eine USB-Verbindung allein versorgt nicht automatisch die Busseite der R5-Bridge.'))

page('Anschlüsse und Schalter erkennen', 'INSTALLATION · 3 VON 3',
 p('Diese Übersicht dient der Zuordnung und der Übergabe an die installierende Fachperson. Sie ist keine Aufforderung, einen unbekannten Stecker nach Ansicht oder Kabelfarbe zu verdrahten.'),
 table(['J1 / Micro-C-Pin', 'Signal', 'Übliche Ader / Funktion'],[
 ['1','Schirm','Blank / Abschirmung, nach R5-Schirmkonzept'],
 ['2','NET-S','Rot / positive NMEA-Versorgung, 9-16 V DC'],
 ['3','NET-C','Schwarz / Rückleiter der Busversorgung'],
 ['4','CAN-H','Weiß / Datenleitung High'],
 ['5','CAN-L','Blau / Datenleitung Low']],[0.24,0.2,0.56]),
 note('Steckerseite beachten', 'Die Ansicht auf Steckkontakte und die Ansicht auf Lötanschlüsse können spiegelbildlich sein. Nummerierung, Durchgang und Kabeldaten prüfen; Farben allein sind kein sicherer Anschlussnachweis. Schirm, Busmasse und USB-/Logikmasse nicht beliebig verbinden.', 'warn'),
 table(['Bedienelement', 'Verwendung'],[
 ['RUN / SERVICE (SW3)', 'RUN: Versorgung aus dem Bordnetz. SERVICE: externe positive Modulversorgung getrennt, USB-Service möglich.'],
 ['BOOT am SuperMini', 'Nach dem Start länger als 2 Sekunden: WLAN öffnen und WLAN-Passwort über USB anzeigen. Bei Kontoanlage oder Passwort-Wiederherstellung vom Absenden bis zur Antwort halten.'],
 ['RESET am SuperMini', 'Startet das Modul neu. Gespeicherte Einstellungen werden dabei nicht absichtlich gelöscht.'],
 ['USB-C am SuperMini', 'Lokale Diagnose und Firmwareübertragung; vorher SERVICE wählen.']],[0.32,0.68]),
 h('Keine Links-/Rechtsregel für den Schalter'),
 p('RUN ist elektrisch die Verbindung SW3 Pin 1-2, SERVICE die Verbindung Pin 2-3. Die mechanische Schieberichtung muss am tatsächlich bestückten Schalter geprüft und beschriftet sein. Falls die Stellung unklar ist: kein USB anschließen und die Fachperson die Zuordnung prüfen lassen.'),
 p('Die blaue LED am gewählten SuperMini bleibt beim Start aus. Sie leuchtet erst, wenn WLAN-Zugangspunkt, IP-Adresse und Webdienst bereit sind; beim Abschalten erlischt sie. Sie zeigt keine Bluetooth- oder NMEA-Daten an.'))

page('USB-Service und WLAN-Passwort', 'ERSTER ZUGANG · 1 VON 3',
 p('Mit einem Geräte-WLAN-QR-Code von der installierenden Person geht die Einrichtung <b>ohne Konsole</b>: weiter auf Seite 9 und 28. Ohne QR-Code oder individuelles Passwort ist einmaliges Auslesen nötig. Es gibt <b>kein gemeinsames Standardpasswort</b>.'),
 note('Reihenfolge verbindlich', '<b>SERVICE wählen → USB anschließen.</b><br/>Nach dem Service: <b>USB abziehen → RUN wählen.</b> Lassen Sie die Stellung zuvor prüfen, falls sie nicht eindeutig markiert ist.', 'danger'),
 steps(('Computer vorbereiten', 'Verwenden Sie einen seriellen Monitor, zum Beispiel den PlatformIO Device Monitor in einer eingerichteten Projektumgebung. Wenn Ihnen diese Werkzeuge fehlen, lassen Sie sich das Passwort von der installierenden Person auslesen und übergeben.'),
 ('USB-Datenkabel verbinden', 'Stellen Sie SERVICE ein und verbinden Sie die USB-C-Buchse des SuperMini mit dem Computer. Ein neu erscheinender serieller Anschluss gehört normalerweise zum Gerät. Bei mehreren Anschlüssen durch Abziehen und erneutes Einstecken zuordnen.'),
 ('Seriellen Monitor öffnen', 'Wählen Sie den passenden Anschluss und 115200 Baud. In einer vorbereiteten PlatformIO-Umgebung lautet der Befehl: <b>pio device monitor -b 115200</b>. Schließen Sie andere Programme, die denselben Anschluss belegen.'),
 ('Passwort anzeigen lassen', 'Warten Sie den normalen Start ab. Halten Sie dann BOOT länger als zwei Sekunden gedrückt und lassen Sie los. Lesen Sie die Zeile <b>Service AP password:</b>. Das funktioniert auch bei bereits geöffnetem WLAN.'),
 ('Privat sichern und zurückkehren', 'Bewahren Sie das Passwort sicher auf. Trennen Sie USB, wählen Sie RUN und versorgen Sie das NMEA-Netz. Verbinden Sie das Handy innerhalb von fünf Minuten.')),
 note('BOOT nicht beim Einschalten halten', 'BOOT während RESET oder Einschalten kann den Programmiermodus aktivieren. Für die normale WLAN-Öffnung BOOT erst nach dem Start drücken. Ist versehentlich der Programmiermodus aktiv, BOOT loslassen und normal neu starten.', 'warn'),
 p('USB-only in SERVICE eignet sich für Portal und Bluetooth. Für eine Prüfung der NMEA-Ausgabe muss auch die Busseite versorgt und die Installation dafür geprüft sein. Ein fehlendes Garmin-Signal im reinen USB-Test beweist keinen Firmwarefehler.'))

page('Mit dem Service-WLAN verbinden', 'ERSTER ZUGANG · 2 VON 3',
 steps(('Bridge normal starten', 'Schalten Sie die geprüfte Installation ein. Die Bridge öffnet nach jedem normalen Start ihr Service-WLAN. Die blaue LED leuchtet bei Bereitschaft; es wird keine feste Wartezeit als Anzeige verwendet.'),
 ('Geräte-QR-Code scannen', 'Scannen Sie den mitgelieferten <b>WLAN-QR-Code</b> und bestätigen Sie die Verbindung. Alternativ wählen Sie <b>OrionBridge-XXXXXX</b> in den WLAN-Einstellungen und geben das individuelle Passwort ein. Details und Portal-QR-Code: Seite 28.'),
 ('Ohne Internet verbunden bleiben', 'Wenn das Handy „Kein Internet“ meldet, bleiben Sie ausdrücklich in diesem WLAN. Ein automatischer Wechsel in ein anderes WLAN kann den Gerätezugriff unterbrechen.'),
 ('Lokale Adresse aufrufen', 'Öffnen Sie einen normalen Browser und geben Sie vollständig <b>https://192.168.4.1/</b> in die Adresszeile ein. Verwenden Sie https, keine Websuche und keine Adresse einer lokalen PC-Vorschau.'),
 ('Lokale Zertifikatsausnahme prüfen', 'Der Prototyp nutzt ein selbstsigniertes Zertifikat. Prüfen Sie, dass Sie direkt mit Ihrem erwarteten Bridge-WLAN verbunden sind und genau diese lokale Adresse geöffnet haben. Bestätigen Sie nur dafür die Browser-Ausnahme.')),
 note('Direkter Link bei bestehender Verbindung', '<link href="https://192.168.4.1/" color="#136d78"><b>https://192.168.4.1/</b></link><br/>Die Adresse funktioniert erst, wenn Ihr Handy oder Computer mit dem WLAN der Bridge verbunden ist.'),
 h('So funktioniert das Zeitfenster'),
 table(['Situation', 'Verhalten'],[
 ['Start ohne verbundenes Handy', 'WLAN schließt nach 5 Minuten.'],
 ['Mindestens ein WLAN-Gerät verbunden', 'Service-WLAN bleibt aktiv.'],
 ['Letztes WLAN-Gerät getrennt', 'Neue Frist von 5 Minuten bis zum Schließen.'],
 ['WLAN bereits geschlossen', 'BOOT nach dem normalen Start länger als 2 Sekunden halten. Einstellungen bleiben erhalten.']],[0.46,0.54]),
 p('Das Handy kann die WLAN-Liste trotz leuchtender LED erst beim nächsten Suchlauf aktualisieren. Öffnet es nur ein WLAN-Anmeldefenster, wechseln Sie in den normalen Browser. Weitere Fehlerhilfe: Seite 19.'))

page('Administratorkonto und Zugangsdaten', 'ERSTER ZUGANG · 3 VON 3',
 h('Beim allerersten Aufruf'),
 p('Wählen Sie einen Benutzernamen mit 3-32 Zeichen aus A-Z/a-z, Ziffern, Unterstrich oder Bindestrich und ein eigenes Passwort. Halten Sie BOOT beim Absenden der Kontoanlage gedrückt, bis die Antwort erscheint. Die Verarbeitung kann einige Sekunden dauern; nicht mehrfach absenden.'),
 p('Passwörter umfassen <b>12-128 UTF-8-Bytes</b>: einfache Buchstaben und Ziffern je ein Byte, Umlaute und Emojis mehr. Leerzeichen bleiben erhalten. Der Administratorzugang ist unabhängig von WLAN-Passwort, Orion-PIN und Readout-Schlüssel.'),
 h('Eigenes Passwort ändern'),
 steps(('Einstellungen öffnen', 'Mit dem bestehenden Administratorkonto anmelden und <b>„Einstellungen“ → „Passwort ändern“</b> öffnen.'),
 ('Änderung speichern', 'Aktuelles Passwort eingeben, neues Passwort festlegen und identisch wiederholen. „Passwort ändern“ wählen. Die Sitzung endet; danach mit demselben Benutzernamen und dem neuen Passwort anmelden.')),
 h('Passwort vergessen: Zugang wiederherstellen'),
 steps(('Wiederherstellung öffnen', 'Im Bridge-WLAN auf der Anmeldeseite <b>„Passwort vergessen?“</b> wählen. Die Seite ist auch unter <b>https://192.168.4.1/recover</b> erreichbar.'),
 ('Zurücksetzen bestätigen', 'Das Bestätigungsfeld markieren. BOOT am bereits gestarteten Gerät gedrückt halten, während Sie <b>„Passwort zurücksetzen“</b> wählen, bis das Ergebnis erscheint. Danach BOOT loslassen.'),
 ('Anmelden und eigenes Passwort setzen', 'Den bisherigen Benutzernamen und das folgende Wiederherstellungspasswort verwenden. Anschließend sofort unter „Einstellungen“ ein eigenes Passwort setzen.')),
 note('Festgelegtes Wiederherstellungspasswort', '<b>X8T6W4BDABQMZCYH6V</b><br/>Einmal zufällig erzeugter, hier veröffentlichter Standard. Nach jeder Wiederherstellung sofort ändern; kein WLAN-Passwort.', 'warn'),
 p('<b>Erhalten bleiben:</b> Benutzername, WLAN-Passwort, Zertifikat, Orion-Verbindung und Schlüssel, Batterienamen, NMEA-Zuweisungen und gespeicherte Daten. Nur das Administratorpasswort wird ersetzt; bestehende Sitzungen enden.'),
 p('Ohne authentifizierte Anfrage endet die Sitzung nach 15 Minuten; Monitor-Abfragen halten sie aktiv. Beim Schließen des Service-WLANs endet sie ebenfalls.'))

page('Orion-Daten in VictronConnect finden', 'EINRICHTUNG · 1 VON 2',
 p('Ermitteln Sie die Daten möglichst vor dem Wechsel ins Bridge-WLAN. Verwenden Sie die Angaben genau des Ladegeräts, das die Bridge später überwachen soll.'),
 steps(('Mit dem Orion verbinden', 'Öffnen Sie VictronConnect und wählen Sie das gewünschte Ladegerät. Stellen Sie bei Bedarf die normale Bluetooth-Verbindung mit dessen PIN her.'),
 ('Produktinformationen öffnen', 'Öffnen Sie die Einstellungen, dann das Menü mit den drei Punkten und <b>Produktinformationen / Product info</b>. Die genaue Beschriftung hängt von App-Version und Sprache ab. [H3]'),
 ('Instant Readout einschalten', 'Aktivieren Sie <b>Instant Readout</b>, falls es deaktiviert ist. Die Funktion überträgt Messwerte in verschlüsselten Bluetooth-Datenpaketen, die die Bridge passiv empfängt. [H3]'),
 ('MAC und Schlüssel übernehmen', 'Öffnen Sie die Instant-Readout-Details, sofern sie angeboten werden, und zeigen Sie die Verschlüsselungsdaten an. Benötigt werden die Bluetooth-MAC und der zugehörige 32-stellige hexadezimale Schlüssel. [H4]'),
 ('Zur Bridge wechseln', 'Kehren Sie zum Bridge-WLAN und dem Browser zurück. Melden Sie sich an und öffnen Sie die geführte „Anleitung“ oder „Einstellungen“.')),
 table(['Angabe', 'Woran Sie das Format erkennen'],[
 ['Bluetooth-MAC', '12 Zeichen aus 0-9 und A-F, häufig als sechs Paare mit Doppelpunkten. Ein frei erfundenes Formatbeispiel ist AA:BB:CC:DD:EE:FF.'],
 ['Instant-Readout-Schlüssel', 'Genau 32 Zeichen aus 0-9 und A-F. Keine Bluetooth-PIN, kein WLAN-Passwort und keine Seriennummer.']],[0.35,0.65]),
 note('Schlüssel vertraulich behandeln', 'Keine echten Schlüssel in Screenshots, Supportmeldungen oder Projektdateien veröffentlichen. Der Prototyp speichert den Schlüssel lokal, aber nicht in verschlüsseltem Flash. Schützen Sie deshalb auch den physischen Zugriff auf das Gerät.', 'warn'),
 p('Nach einer Änderung der Orion-PIN oder seiner Konfiguration kann ein neuer Readout-Schlüssel erforderlich werden. Wenn später die Entschlüsselung fehlschlägt, die aktuellen Angaben in VictronConnect erneut ablesen.'))

page('Orion und Batterieseiten zuordnen', 'EINRICHTUNG · 2 VON 2',
 steps(('MAC und Schlüssel eintragen', 'Unter „Einstellungen“ die Orion-MAC eingeben oder einfügen. Doppelpunkte ergänzt das Formular automatisch. Den 32-stelligen Readout-Schlüssel vollständig eintragen.'),
 ('Instanzen auswählen', 'Eine Instanz ist eine Kennnummer für einen Datenkanal im NMEA-Netz. Vorgabe: <b>Ausgang 0</b>, <b>Eingang 1</b>. Beide müssen verschieden sein, im Bereich 0-252 liegen und zur übrigen Netzbelegung passen.'),
 ('Speichern und neu starten', 'Die Schaltfläche wird erst bei gültigen Eingaben freigegeben. Bei unveränderter Orion-MAC darf das Schlüsselfeld leer bleiben: Der gespeicherte Schlüssel bleibt erhalten, auch bei geänderten Instanzen. Eine neue MAC benötigt ihren vollständigen Schlüssel. Danach startet die Bridge neu.'),
 ('Wieder verbinden und prüfen', 'Bei Bedarf erneut ins Bridge-WLAN wechseln und anmelden. Die geführte Anleitung führt anschließend zur Prüfung. Kontrollieren Sie im Monitor, ob aktuelle Daten eintreffen.')),
 h('Aussagekräftige Namen vergeben'),
 p('Im Abschnitt <b>„Batterien benennen“</b> heißt der Eingang zunächst „Startbatterie“ und der Ausgang „Bugbatterie“. Passen Sie diese Bezeichnungen an Ihr Boot an. Erlaubt sind jeweils 1-32 Zeichen ohne Steuerzeichen. Die beiden Namen müssen sich unterscheiden; Groß-/Kleinschreibung allein genügt nicht.'),
 note('„Namen speichern“ ist eine eigene Aktion', 'Namen werden ohne Readout-Schlüssel und ohne Neustart gespeichert. Sie verändern weder die NMEA-Instanzen noch die Orion-Einstellungen. Der Garmin übernimmt diese lokalen Namen nicht automatisch.'),
 table(['Beispielzuordnung', 'Eingang', 'Ausgang'],[
 ['Aufgabe', 'Versorgt den Orion', 'Lädt die Zielbatterie'],
 ['Lokaler Name', 'Startbatterie', 'Bugbatterie'],
 ['NMEA-Instanz', '1', '0']],[0.34,0.33,0.33]),
 p('„Orion vergessen“ entfernt die gespeicherte Orion-MAC und den Schlüssel und startet die Bridge neu. Bis zur erneuten Einrichtung wird keine Orion-Telemetrie ausgegeben. Administrator und Kanalnamen bleiben bestehen. Verwenden Sie diese Aktion nur bei einer bewussten Neuzuordnung.'))

page('Die Übersicht lesen', 'BEDIENUNG · WEBINTERFACE',
 pic('portal-channels.png', 220, 'Die beiden Messwertkarten des Original-Webinterfaces. Alle Werte stammen aus einer lokalen Simulation; kein Nachweis einer realen Bordmessung.'),
 table(['Bereich', 'So verwenden Sie ihn'],[
 ['Übersicht', 'Schneller Blick auf Eingang, Ausgang und die getrennten Orion-/NMEA-Statusanzeigen.'],
 ['Einstellungen', 'Batterienamen, Orion-Zugangsdaten und NMEA-Instanzen ändern.'],
 ['Anleitung', 'Vier Schritte: lokaler Zugang, Orion-Daten, NMEA-Zuordnung, Prüfung.'],
 ['Monitor', 'Einzelparameter, Datenalter, Sendeaufträge und Diagnoseereignisse prüfen.'],
 ['Auswertung / Meldungen', 'Orion-Verlauf und beobachtete Energie ansehen; Warnungen einstellen und bestätigen. Seiten 25-27.']],[0.27,0.73]),
 p('Die Sprache wählen Sie oben auf der Seite. Deutsch ist die Vorgabe. Die Auswahl wird im Browser gespeichert, nicht auf der Bridge; ein anderes Handy startet daher gegebenenfalls wieder mit Deutsch. Bei gesperrtem Browserspeicher kann die Auswahl nur für die aktuelle Seite gelten.'),
 note('Zwei getrennte Statusanzeigen lesen', 'Ein guter Bluetooth-Empfang sagt nichts über den Empfang am Garmin aus. Ein akzeptierter NMEA-Sendeauftrag ist ebenfalls noch keine Empfangsbestätigung des Plotters.'))

page('Werte, Farben und Meldungen verstehen', 'BEDIENUNG · RICHTIG INTERPRETIEREN',
 table(['Anzeige', 'Bedeutung und richtige Reaktion'],[
 ['Grün / OK', 'Die aktuellen Prüfungen des Portals sind unauffällig. Die reale Anzeige am Garmin zusätzlich kontrollieren.'],
 ['Gelb / Warnung', 'Warten auf Daten, veraltete oder einzelne fehlende Werte, Abschaltgrund oder frühere Fehler. Den dazugehörigen Text lesen.'],
 ['Rot / Fehler', 'Aktiver erkannter Empfangs-/Ladegerätefehler oder relevanter fehlgeschlagener NMEA-Sendeauftrag. Im Monitor die Ursache eingrenzen.'],
 ['Strich / Nicht verfügbar', 'Für dieses Feld liegt kein aktueller oder unterstützter Wert vor. Ein Strich ist nicht gleich null.'],
 ['0.000 A', 'Ein gültiger gemeldeter Nullstrom; beispielsweise kann der Orion eingeschaltet sein, ohne gerade zu laden.']],[0.32,0.68]),
 h('Drei Nachkommastellen sind keine höhere Genauigkeit'),
 p('Das Portal schreibt beispielsweise <b>13.420 V</b> oder <b>4.500 A</b>. Der implementierte Bluetooth-Datensatz liefert Spannung in 0,01-V-Schritten und Strom in 0,1-A-Schritten. Die zusätzlichen Nullen sind Formatierung. Die tatsächliche Messgenauigkeit wird dadurch nicht verbessert.'),
 p('Leistung wird aus Spannung und Strom berechnet: 13,420 V × 4,500 A = 60,390 W. Das ist ein Rechenbeispiel. Eingangs- und Ausgangsleistung müssen wegen Verlusten, unterschiedlicher Messzeitpunkte und Rundung nicht identisch sein.'),
 h('Warum Ladephasen und Strom sich ändern'),
 p('„Bulk“, „Absorption“ und „Float“ bezeichnen Ladephasen des Orion. Die Bridge meldet ausgewählte bekannte Phasen weiter, legt aber selbst keine Ladespannung fest. Verwenden Sie zur Bewertung des Ladevorgangs die Anleitung Ihres Orion und die Vorgaben des Batterieherstellers.'),
 note('Zehn Sekunden ohne neues Paket', 'Nach zehn Sekunden ohne neue Orion-Daten werden Messwerte als veraltet behandelt und nicht als aktuelle NMEA-Messwerte weitergegeben. Die letzte NMEA-Karte kann trotzdem noch einen älteren Sendeversuch mit seinem Alter zeigen.'),
 p('Bei „Verbindung unterbrochen“ betrifft die Meldung zunächst den Browserkontakt zur Bridge. Prüfen Sie WLAN und Anmeldung. Ob die Bridge unabhängig davon weiter sendet, muss am Monitor nach Wiederverbindung und am Garmin geprüft werden.'))

page('Im Monitor die Ursache finden', 'BEDIENUNG · DIAGNOSE',
 pic('portal-counters.png', 210, 'Die Diagnosezähler im echten Monitor, hier mit simulierten Beispieldaten. Darunter folgen im Browser die Orion-Parameter und NMEA-Meldungen.'),
 table(['Feld oder Gruppe', 'So lesen Sie die Anzeige'],[
 ['Alter / Aktualität / Signalstärke', 'Alter der Daten und Funkempfang prüfen. RSSI ist ein Funkpegel in dBm; weniger negative Werte bedeuten normalerweise stärkeren Empfang. Keine feste Reichweitengrenze daraus ableiten.'],
 ['Orion-Fehler', 'Summe aus verworfenen Datensätzen, vollen Warteschlangen und Startfehlern. Doppelte Pakete werden separat gezählt und sind nicht automatisch ein Fehler.'],
 ['NMEA-Fehler', 'Abgelehnte Sendeaufträge. Akzeptierte Aufträge bestätigen keine physische Übertragung oder Darstellung am Garmin.'],
 ['PGN-Karten', 'Zeigen letzten Sendeversuch, Alter und Felder der jeweiligen Meldungsart. Ein alter Einzelstatus kann vom aktuellen Gesamtstatus abweichen.'],
 ['Aktuelle Meldungen', 'Bis zu 64 Ereignisse seit Start: Laufzeit oder UTC mit Zeitqualität. Frühe Ereignisse erhalten später geschätzte Uhrzeiten. Kein dauerhaftes Logbuch; siehe Seite 27.']],[0.32,0.68]),
 note('Vor einem Neustart festhalten', 'Fehlermeldung, Datenalter, relevante Zähler und Uhrzeit notieren. Zähler beginnen mit dem Gerätestart neu; nach einem Neustart ist ein früherer Verlauf nicht mehr als dauerhaft gespeicherte Diagnose verfügbar.'))

page('Garmin einrichten und abnehmen', 'PRÜFUNG VOR DEM ERSTEN EINSATZ',
 p('Die Bridge muss im endgültigen Aufbau geprüft werden: im geschlossenen Gehäuse, am vorgesehenen Einbauort und mit dem tatsächlich verwendeten Orion und Plotter. Das Projekt dokumentiert noch keine vollständige Garmin-/Bordabnahme.'),
 steps(('Orion-Empfang vergleichen', 'Im Webinterface müssen aktuelle Werte für Eingang und Ausgang erscheinen. Vergleichen Sie diese zeitnah mit VictronConnect bei möglichst ruhigem Ladezustand. Notieren Sie Abweichungen; keine zusätzliche Dezimalstelle als Genauigkeitsnachweis werten.'),
 ('Bridge in der Geräteliste suchen', 'Öffnen Sie auf dem Garmin die Liste der NMEA-2000-Geräte. Die Bridge meldet sich als <b>BatterySentinel Orion Bridge</b>. Der genaue Menüpfad ist von Modell und Softwareversion abhängig; verwenden Sie die zugehörige Garmin-Anleitung.'),
 ('Datenquellen zuordnen', 'Wählen Sie für die gewünschten elektrischen Datenfelder die passende Quelle bzw. Batterieinstanz. Ausgang ist standardmäßig 0, Eingang 1. Ein anderer vorhandener Batteriesensor darf nicht unbeabsichtigt dieselbe Zuordnung überlagern.'),
 ('Spannung und Strom prüfen', 'Kontrollieren Sie, ob die Werte zur richtigen Orion-Seite gehören und sich bei verändertem Ladebetrieb plausibel mitändern. Die lokalen Namen „Startbatterie“ und „Bugbatterie“ werden nicht automatisch an den Plotter übertragen.'),
 ('Ausfallanzeige kontrolliert prüfen', 'Im sicheren Stillstand einen Empfangsausfall durch eine geeignete, reversible Maßnahme erzeugen, zum Beispiel vorübergehend Instant Readout deaktivieren. Nach zehn Sekunden muss das Portal veraltete Daten erkennen. Prüfen Sie, wie der Plotter fehlende Daten kennzeichnet. Danach die Ausgangseinstellung wiederherstellen.'),
 ('Wiederanlauf prüfen', 'Die Bridge kontrolliert neu starten. Gespeicherte Zuordnung und automatischen Empfang ohne angemeldetes Handy prüfen. Ergebnis im Protokoll auf Seite 22 festhalten.')),
 note('Bei Abweichungen keine Freigabe voraussetzen', 'Bleiben Werte falsch, fehlen erwartete Quellen oder hält der Plotter alte Daten ohne erkennbare Kennzeichnung fest, Installation und Darstellung mit einer Fachperson klären. Die Bridge liefert keine erfundenen SOC-, Temperatur- oder Restlaufzeitwerte.', 'warn'),
 p('Ob eine bestimmte PGN als Garmin-Datenfeld angeboten wird, hängt vom Plotter ab. Die aufgeführten NMEA-Meldungen auf Seite 23 sind keine Zusicherung, dass jede Information auf jedem Garmin angezeigt wird.'))

page('Täglicher Betrieb', 'AN BORD',
 h('Vor der Fahrt'),
 steps(('Sichtkontrolle', 'Gehäuse, Stecker und Leitungen auf festen Sitz, Beschädigung und Feuchtigkeit prüfen. USB muss abgezogen sein, der Schalter auf RUN stehen.'),
 ('System starten', 'NMEA-Netz und Orion gemäß der normalen Bordroutine einschalten. Die Bridge startet mit der Versorgung. Ein ständig angemeldetes Handy ist nicht nötig.'),
 ('Daten prüfen', 'Am Garmin die richtige Quelle und plausible aktuelle Werte prüfen. Bei Zweifeln das Service-WLAN öffnen und den Monitor aufrufen. Ein laufender Ladebetrieb ist nicht in jedem Zustand zu erwarten.'),
 ('Auffälligkeiten klären', 'Bei Strichen, falscher Zuordnung oder Fehlertexten die Fehlerhilfe auf Seiten 19-21 verwenden. Nicht allein auf die Farbe einer Statuskarte verlassen.')),
 h('Während des Betriebs'),
 p('Die Bridge hört die Orion-Bluetooth-Daten passiv mit. Sie startet keine Ladezyklen und ändert keine Orion-Einstellungen. Das Schließen des Browsers oder das automatische Abschalten des Service-WLANs beendet die eingerichtete Datenübertragung nicht.'),
 p('Für einen späteren Kontrollbesuch BOOT nach dem normalen Start länger als zwei Sekunden halten, ins Bridge-WLAN wechseln und anmelden. Geben Sie WLAN und Administratorzugang nur an Personen weiter, die das Gerät bedienen dürfen.'),
 h('Nach der Fahrt und bei längerer Pause'),
 p('Verlassen Sie die lokale Sitzung über die Abmeldefunktion und trennen Sie das Handy vom Bridge-WLAN. Schalten Sie das Bordnetz nach der für Ihr Boot vorgesehenen Routine ab. Die Bridge besitzt keinen eigenen Ein-/Ausschalter; RUN/SERVICE ist eine Umschaltung für den Servicebetrieb.'),
 p('Bei abgeschalteter Versorgung werden keine Orion-Daten übertragen. Konfiguration und Kanalnamen bleiben im nichtflüchtigen Gerätespeicher erhalten. Bei Wiederinbetriebnahme nach längerer Pause Anschlüsse und Aktualität erneut prüfen.'),
 note('Keine Kalibrierung in der Bridge', 'Für Orion-Messwerte gibt es in diesem Portal keine eigene Kalibrierfunktion. Bei dauerhaft auffälligen Spannungen oder Strömen zuerst Vergleichsmessung, Orion-Konfiguration und Verkabelung prüfen lassen.'))

page('Wartung, Updates und Wiederherstellung', 'SERVICE',
 h('Pflege und regelmäßige Kontrolle'),
 p('Kabel, Scheuerstellen und Feuchtigkeit vor der Nutzung und nach Arbeiten prüfen. Abgeschaltet außen mit einem weichen, leicht angefeuchteten Tuch reinigen; nichts in Öffnungen sprühen, keine Lösungsmittel verwenden.'),
 h('Firmware vom Handy installieren'),
 p('Unter <b>„Einstellungen“ → „Firmware-Update“</b> ist ein lokales Update ohne Internet möglich. Fehlt dieser Bereich, ist zunächst USB-Service nötig. Die reale Update-Abnahme steht noch aus.'),
 steps(('Datei vorher beschaffen', 'Die vertrauenswürdige <b>orion-dongle-1.2.0.bin</b> für die Orion-Bridge mit 4-MB-SuperMini und der Kennung <b>orion_dongle</b> auf dem Handy speichern. Kein ZIP, Bootloader oder vollständiges Flash-Abbild verwenden. Instanzen und Zugangsdaten vorher sicher dokumentieren.'),
 ('Update starten', 'Im sicheren Stillstand stabile Versorgung sicherstellen. Im normalen RUN-Betrieb bleibt USB abgezogen. Im Bridge-WLAN als Administrator anmelden, „Einstellungen“ öffnen und unter „Firmware-Update“ die Datei wählen und die Installation starten.'),
 ('Übertragung abwarten', 'Handy im WLAN lassen, Seite offen halten und Versorgung nicht unterbrechen. Live-Anzeigen pausieren. 100 % übertragen bedeutet noch nicht fertig: Prüfung und Installation abwarten.'),
 ('Nach dem Neustart prüfen', 'Erneut verbinden, anmelden und installierte Version kontrollieren. Danach Prüfung von Seite 16 durchführen. Bei Abbruch oder unbekanntem Ergebnis zuerst wieder verbinden und die Version prüfen, bevor Sie erneut hochladen.')),
 note('Abgelehnte Datei', 'Bei Ziel- oder Prüfsummenfehler passende Datei erneut beschaffen. Die Prüfung bestätigt nicht den Herausgeber. Bei „OTA nicht verfügbar“ oder dauerhaftem Schreibfehler USB-Service veranlassen.'),
 p('<b>USB-Service:</b> SERVICE vor USB; fachkundig die 4-MB-Firmware <b>orion_dongle</b> installieren. Danach USB abziehen und RUN wählen. Alte Firmware muss die neue Updatefunktion erst erhalten.'),
 h('Verlorenes Administratorpasswort'),
 p('Auf der Anmeldung „Passwort vergessen?“ öffnen und mit BOOT bestätigen; Ablauf und Wiederherstellungspasswort stehen auf Seite 10. Nur das Administratorpasswort wird ersetzt, alle Daten und Zuweisungen bleiben erhalten. Weder NVS löschen noch „Orion vergessen“ verwenden.'),
 p('Zur Entsorgung Daten löschen lassen und eine Elektronik-Sammelstelle nutzen.'))

page('Fehlerhilfe: WLAN und Anmeldung', 'TROUBLESHOOTING · ZUGANG',
 p('Beginnen Sie mit der zum Symptom passenden Zeile. Prüfen Sie nach jeder Maßnahme erneut, bevor Sie weitere Einstellungen verändern.'),
 table(['Symptom', 'Schritte zur Behebung'],[
 ['WLAN nicht sichtbar', '1. Versorgung und RUN ohne USB prüfen. 2. Blaue LED abwarten; bei geschlossenem WLAN BOOT länger als 2 Sekunden halten. 3. WLAN-Liste am Handy aktualisieren. 4. Innerhalb von 5 Minuten verbinden. Weitere USB-Diagnose: Seite 8.'],
 ['WLAN-Passwort falsch', 'Gespeichertes Bridge-WLAN am Handy entfernen und neu verbinden. Individuelles Passwort über USB/BOOT auslesen. Administratorpasswort und Orion-PIN funktionieren hier nicht.'],
 ['„Kein Internet“', 'Das ist für dieses lokale WLAN normal. Verbunden bleiben und die lokale Adresse im Browser öffnen.'],
 ['Seite lädt nicht', 'WLAN-Zuordnung prüfen, dann https://192.168.4.1/ vollständig eingeben. Bei Bedarf VPN oder automatischen Netzwechsel vorübergehend für die Diagnose deaktivieren und danach wiederherstellen. Normalen Browser verwenden.'],
 ['Zertifikatswarnung', 'Ausnahme nur direkt im erwarteten Bridge-WLAN für die lokale Adresse bestätigen. Erlaubt ein verwalteter Browser keine Ausnahme, ein geeignetes anderes Gerät verwenden; keine globalen Sicherheitsfunktionen abschalten.'],
 ['Konto lässt sich nicht anlegen', 'Benutzername und Passwortlänge prüfen. BOOT vom Absenden des Formulars bis zur Antwort gedrückt halten.'],
 ['Anmeldung wirkt eingefroren', 'Prüfung abwarten, nicht mehrfach absenden. Ist die Seite danach unerreichbar: einmal neu laden oder https://192.168.4.1/ öffnen.'],
 ['„Sitzung abgelaufen“', 'Seite neu laden und erneut anmelden. Nicht gespeicherte Eingaben gegebenenfalls wiederholen.'],
 ['USB zeigt nichts', 'SERVICE, Datenkabel, richtigen Port und 115200 Baud prüfen. Anderen Port/Kabel testen, normalen Start abwarten und BOOT länger als 2 Sekunden drücken.'],
 ['BOOT hilft nach Reset nicht', 'Möglicherweise wurde BOOT beim Einschalten gehalten. Taste loslassen und normal neu starten; danach erst BOOT für WLAN verwenden.']],[0.3,0.7]),
 note('Administratorpasswort verloren', '„Passwort vergessen?“ mit BOOT-Bestätigung nach Seite 10 verwenden. Daten bleiben erhalten. Bei Ablehnung Seite neu laden, Bestätigungsfeld markieren und BOOT bis zur Antwort halten.'))

page('Fehlerhilfe: Orion und Messwerte', 'TROUBLESHOOTING · BLUETOOTH',
 table(['Symptom / Meldung', 'Prüfung und nächster Schritt'],[
 ['„Einrichtung erforderlich“', 'Die Bridge hat noch keine vollständige Orion-Zuordnung. MAC, Readout-Schlüssel und zwei verschiedene Instanzen eintragen, speichern und Neustart abwarten.'],
 ['Warte auf Bluetooth-Datenpaket', 'Orion eingeschaltet? Instant Readout aktiv? MAC des richtigen Geräts übernommen? Bridge näher an den Orion bringen und Metallabschirmung vermeiden.'],
 ['„Daten veraltet“', 'Seit mindestens 10 Sekunden kein neues Paket. Orion-Versorgung, Funkweg und Datenalter prüfen. Den Browser neu zu laden repariert keinen ausgefallenen Funkempfang.'],
 ['Schlüssel stimmt nicht überein / Entschlüsselung fehlgeschlagen', 'MAC und aktuellen 32-stelligen Readout-Schlüssel als zusammengehöriges Paar erneut aus VictronConnect übernehmen. Nach PIN-Änderung besonders auf einen geänderten Schlüssel achten.'],
 ['Nicht unterstütztes Datenpaket / Datensatz unplausibel', 'Exaktes Orion-Modell und Firmwarestand dokumentieren. Ein korrekt formatiertes Schlüsselfeld beweist keinen passenden Schlüssel. Bei korrekten Zugangsdaten Kompatibilität prüfen lassen.'],
 ['BLE-Suche oder Warteschlange konnte nicht starten', 'Meldung vor Neustart festhalten. Bridge einmal normal neu starten. Wiederholt sich der Fehler, Versorgung und Firmware durch eine kundige Person prüfen lassen.'],
 ['Orion meldet Fehler / Abschaltgrund', 'Fehlercode und Abschaltgrund in VictronConnect sowie der Anleitung des konkreten Ladegeräts prüfen. Keine Codes raten und keine Schutzfunktion über die Bridge umgehen.'],
 ['0 A oder geringe Leistung', 'Kann bei Ladepause, voller Batterie oder Strombegrenzung richtig sein. Ladegerätstatus in VictronConnect prüfen. Die Bridge selbst kann keinen Ladevorgang starten.'],
 ['Abweichende Werte', 'Gleiche Seite, Quelle und Zeitpunkt prüfen. Andere Messgeräte erfassen möglicherweise weitere Verbraucher. Nachkommastellen nicht mit Genauigkeit verwechseln.'],
 ['Fehlerzähler / gelber Status', 'Neue Fehler oder alte Zähler? Doppelte Pakete zählen separat. Steigende Verluste oder Neustarts im endgültigen Einbau untersuchen lassen.']],[0.34,0.66]),
 note('Für die Fehlermeldung notieren', 'Gerätemodell, Firmware, exakten Meldungstext, Datenalter, RSSI und Zähleränderung festhalten. Niemals den Readout-Schlüssel oder Passwörter mitsenden.'))

page('Fehlerhilfe: NMEA 2000 und Garmin', 'TROUBLESHOOTING · NETZWERK',
 table(['Symptom', 'Prüfung und nächster Schritt'],[
 ['Im Portal Werte, am Garmin nichts', 'Orion-Empfang funktioniert wahrscheinlich. NMEA-Netz einschalten, Busversorgung und T-Stück prüfen. Bei USB-only ist die R5-Busseite nicht automatisch versorgt. Danach Garmin-Geräteliste und Datenquellen prüfen.'],
 ['Bridge fehlt in der Geräteliste', 'Ist ein Orion vollständig eingerichtet? Vorher ist NMEA in dieser Firmware deaktiviert. Danach Kabel, Busversorgung, CAN-Anbindung und zwei Endabschlüsse durch die Fachperson prüfen lassen.'],
 ['Sendeaufträge akzeptiert, Anzeige trotzdem leer', 'Akzeptiert bedeutet nur, dass die lokale Sendefunktion den Auftrag angenommen hat. Richtige Quelle/Instanz, Plotter-Unterstützung und physische CAN-Übertragung gesondert prüfen.'],
 ['NMEA-Sendeauftrag fehlgeschlagen', 'Versorgung beider Geräteseiten, Kabel und Netzwerk prüfen. Fehlertext und Zähler dokumentieren. Nach einer Behebung erneut prüfen; alte Zähler verschwinden erst beim Neustart.'],
 ['Eingang und Ausgang vertauscht', 'In der Bridge und am Garmin dieselben Instanzen zuordnen. Vorgabe: Eingang 1, Ausgang 0. Bei unverändertem Orion kann der gespeicherte Schlüssel beibehalten werden.'],
 ['Werte wechseln zwischen Geräten', 'Mögliche doppelte Instanzen oder falsche Datenquelle. Belegung sämtlicher Batteriesensoren mit der installierenden Person prüfen. Nicht wahllos Nummern ändern.'],
 ['SOC, Temperatur oder Restlaufzeit fehlen', 'Diese Messgrößen liefert die Orion-Bridge nicht. Ein leeres Feld ist dafür kein Defekt. Geeignete Spannungs- und Stromfelder auswählen.'],
 ['Ladezustands-PGN bleibt alt', 'PGN 127507 wird nur für geeignete aktuelle Ladephasen ohne Orion-Fehler gesendet. Eine alte Karte allein muss den aktuellen Gesamtstatus nicht auf Fehler setzen.'],
 ['Andere NMEA-Geräte fallen nach Anschluss aus', 'Netz sicher abschalten. Neue Bridge samt Abzweig durch eine Fachperson prüfen lassen: Kurzschluss, falsche Adern, Strombudget oder zusätzlicher Abschluss sind mögliche Ursachen. Bei Überhitzung nicht weiter testen.']],[0.34,0.66]),
 note('Elektrische Messungen nur fachkundig', 'Bei vollständig spannungsfreiem, korrekt abgeschlossenem Bus sind zwischen CAN-H und CAN-L ungefähr 60 Ohm plausibel. Niemals eine Widerstandsmessung am eingeschalteten Netz durchführen. Dieser Einzelwert beweist noch keine fehlerfreie Installation.', 'warn'))

page('Einbau- und Übergabeprotokoll', 'ZUM AUSFÜLLEN · OHNE GEHEIMNISSE',
 p('Tragen Sie die Angaben zur tatsächlich geprüften Installation ein. Dieses Blatt ist ein Arbeitsprotokoll und keine Zertifizierung. Passwörter und Readout-Schlüssel separat privat aufbewahren.'),
 ('form',),
 h('Abnahme gemeinsam durchführen'),
 ('checks', [
 'R5-Baugruppe, Verkabelung, Isolation und geschlossene Montage geprüft.',
 'RUN/SERVICE am realen Schalter geprüft und eindeutig markiert.',
 'USB-Service-Reihenfolge erklärt; keine USB-Verbindung in RUN.',
 'Versorgung, Netzbudget, zwei Abschlüsse und Dropkabel geprüft.',
 'WLAN und Administratorzugang funktionieren; Daten privat übergeben.',
 'Orion-Werte zeitnah mit VictronConnect verglichen.',
 'Garmin zeigt passende Quelle, Instanzen und aktuelle Werte.',
 'Veraltete Daten und Wiederanlauf geprüft; Ergebnis dokumentiert.',
 'Offene Punkte festgehalten und vor regulärem Einsatz bewertet.']),
 p('Offene Punkte / Vergleichswerte / Verhalten bei Datenverlust:'),
 ('lines', 3),
 p('Datum / ausführende Person / Unterschrift:'), ('lines', 1))

page('Technische Daten und Begriffe', 'NACHSCHLAGEN',
 table(['Merkmal', 'Dokumentierter Stand'],[
 ['Hardware / Firmware', 'Orion-R5, ESP32-C3 SuperMini, 4 MB; Firmwarekennung orion_dongle.'],
 ['Versorgung fertige Bridge', 'NMEA 2000: 9-16 V DC; vorläufig 12 LEN (600 mA Budget). Reale Leistungsaufnahme noch zu messen.'],
 ['Lokaler Zugang', 'WPA2-WLAN OrionBridge-XXXXXX; HTTPS 192.168.4.1; USB-Seriell 115200 Baud.'],
 ['CAN / NMEA 2000', '250 kbit/s, galvanisch getrennte CAN-Anbindung; kein Abschluss am Drop.'],
 ['PGN 127508', 'Spannung/Strom für Ausgang und Eingang, jeweils jede Sekunde.'],
 ['PGN 127506', 'Metadaten für Ausgang (Battery) und Eingang (Converter), alle 5 Sekunden. Keine SOC-Erfindung.'],
 ['PGN 127507', 'Ausgewählte Ladephasen Bulk/Absorption/Float bei aktuellen Daten ohne Orion-Fehler, im 1-Sekunden-Zyklus.'],
 ['Aktualität', 'Orion-Daten nach 10 Sekunden ohne neues Paket veraltet; elektrische NMEA-Werte dann nicht verfügbar.'],
 ['Betriebsgrenzen', 'Keine freigegebene Schutzart oder qualifizierte Umgebungstemperatur dokumentiert. Trockener, geschützter Einbau.']],[0.34,0.66]),
 h('Kleine Übersetzungshilfe'),
 table(['Begriff', 'Einfache Erklärung'],[
 ['Bridge / Dongle', 'Das Gerät, das Orion-Daten in das NMEA-Netz übersetzt.'],
 ['BLE / Instant Readout', 'Bluetooth-Übertragung kurzer, verschlüsselter Messdatenpakete.'],
 ['MAC / Schlüssel', 'Bluetooth-Geräteadresse und Geheimnis zum Lesen der Pakete.'],
 ['Backbone / Drop', 'Hauptleitung des Borddatennetzes / Geräteabzweig.'],
 ['Instanz / PGN', 'Kennnummer eines Datenkanals / Nummer einer NMEA-Meldungsart.'],
 ['NVS / Firmware / SOC', 'Dauerhafter Einstellspeicher / Geräteprogramm / Batterie-Ladezustand in Prozent.']],[0.34,0.66]))

page('Dokumentstand und weiterführende Hilfe', 'QUELLEN & GELTUNGSBEREICH',
 p('<b>Ausgabe 1.5 · 10.10.2026 · Deutsch · Firmware 1.2.0</b><br/>Erstellt für die BatterySentinel-N2K Orion-Bridge mit ESP32-C3 SuperMini und R5-Baugruppe. Beschrieben sind Einbau, Bedienung, Passwortverwaltung, Auswertung, Meldungen, QR-Zugang und erste Hardwareprüfung. Maßgeblich ist der dokumentierte lokale Projektstand.'),
 h('Projektquellen'),
 p('<b>[P1] Bedienung und Firmware:</b> docs/erstverbindung.md, docs/orion-xs-bridge.md; src/BridgePortal.cpp, BridgePortalUi.h, BridgePortalOta.h, BridgePortalTranslations.h, BridgeSettings.cpp und dongle_main.cpp. Belege für Bedienung, Zeitfenster, Updates und Diagnose.'),
 p('<b>[P2] Daten und Auswertung:</b> src/NmeaPublisher.cpp, BridgeDiagnostics.cpp, BridgePortalInsights.h; lib/OrionBridge, BridgeInsights, BridgeTime und BridgeNmeaAlerts. Belege für Messdaten, Beobachtungen, Uhr und Warnungen.'),
 p('<b>[P3] R5-Hardware:</b> hardware/altium-r5/power-review.md und module-selection.md; tools/r5_schematic_plan.py. Belege für die USB-Trennung, Versorgung und J1-Belegung der beschriebenen Baugruppe.'),
 h('Herstellerinformationen · abgerufen am 24.09.2026'),
 p('<b>[H1]</b> <link href="https://www8.garmin.com/manuals/webhelp/GUID-1415AAD0-FE63-42A6-8F8D-DB713D616122/EN-US/GUID-9C47C97C-88A2-4EC6-9846-9B6937C3ACA7.html" color="#136d78">Garmin: NMEA 2000 Glossary</link> · Versorgung, LEN und Dropkabel.<br/><b>[H2]</b> <link href="https://www8.garmin.com/manuals/webhelp/GUID-1415AAD0-FE63-42A6-8F8D-DB713D616122/EN-US/GUID-FABDEBBC-4930-4460-BC64-232E160406E3.html" color="#136d78">Garmin: Network Termination</link> · Endabschlüsse.<br/><b>[H3]</b> <link href="https://www.victronenergy.com/media/pg/VictronConnect_app/en/stored-trends---instant-readout.html" color="#136d78">VictronConnect: Stored trends &amp; Instant readout</link> · Aktivierung in den Produktinformationen.<br/><b>[H4]</b> <link href="https://www.victronenergy.com/media/pg/Blue_Smart_IP22_Charger_230V_manual/en/monitoring---bsc---psc.html" color="#136d78">Victron: Monitoring / Instant readout details</link> · Allgemeiner App-Ablauf zum Anzeigen von MAC und Schlüssel; kein Kompatibilitätsnachweis dieses Ladegeräts mit der Bridge.'),
 h('Was noch physisch zu bestätigen ist'),
 p('Ein dokumentierter Erfolgsbericht bestätigt den Orion-Empfang nach Eingabe von MAC und Schlüssel. Messwertvergleich, Versorgung und Erwärmung der bestückten R5-Baugruppe, Gehäuse-/Modulpassung, Funkbetrieb am Einbauort und Garmin-Verhalten müssen am konkreten Gerät abgenommen werden. Aus einer CAD-Prüfung mit null Regelverletzungen folgt keine bestandene elektrische oder maritime Zulassungsprüfung.'),
 note('Gestaltung und Abbildungen', 'Farben und Oberflächen stammen aus dem Projektportal. Das Dokumentzeichen verbindet die vorhandene Batterie-Schild-Kontur mit einem Blitz. Die Portalbilder zeigen echte Oberflächen mit simulierten Daten. Verbindungsskizzen sind Funktionsbilder, keine maßstäblichen Verdrahtungspläne.'),
 p('Für Unterstützung das ausgefüllte Protokoll, Modell-/Firmwareangaben, Fehlermeldungen und betroffene Seite dieser Anleitung bereithalten. Die installierende Person oder Projektbetreuung ist die erste Anlaufstelle; Zugangsdaten vorher aus allen Aufnahmen entfernen.'))

page('Auswertung: Spannung und Orion-Energie', 'NEU IN 1.2.0 · 1 VON 3',
 pic('portal-insights.png', 225, 'Auswertung im echten Portal mit simulierten Beispieldaten. Die Namen bezeichnen den Orion-Eingang und -Ausgang; keine vollständige Batteriemessung.'),
 table(['Anzeige', 'So lesen Sie sie'],[
 ['Min. / Max.', 'Niedrigste und höchste gültige Spannung seit diesem Start.'],
 ['Verlauf / Trend', 'Bis zu 60 zusammenhängende Werte aus höchstens fünf Minuten. Der Trend in V/min benötigt mindestens drei Werte über zehn Sekunden; die tatsächliche Zeitspanne steht daneben.'],
 ['Orion-Ladung / Energie', 'Beobachtete Ah/Wh durch den Orion. Die angezeigte Datenabdeckung und Beobachtungsdauer zeigen, wie viel tatsächlich erfasst wurde. Andere Verbraucher fehlen.'],
 ['Zeit unter Unterspannungsgrenze', 'Nur beobachtete Zeit unter dem gespeicherten Grenzwert. Ändern Sie diesen Wert, beginnt diese Zeitsumme neu.']],[0.3,0.7]),
 p('Lücken von mehr als <b>fünf Sekunden</b> und ungültige Werte werden nicht überbrückt oder hochgerechnet. Danach beginnt ein neuer zusammenhängender Verlauf. Bereits beobachtete Summen bleiben bis zum Neustart erhalten; Rückstrom wird nicht als vorwärts übertragene Energie gezählt.'),
 note('Beobachtung, keine Batteriediagnose', 'Laden und die anschließende Spannungsberuhigung können den Trend ändern. Daraus folgen weder Ladezustand, Restlaufzeit noch Batteriegesundheit. Beim Neustart beginnen Summen und Verlauf neu; ausgeschaltete Zeit bleibt unbeobachtet.'))

page('Meldungen einstellen und bestätigen', 'NEU IN 1.2.0 · 2 VON 3',
 p('Öffnen Sie <b>„Meldungen“</b>. Benachrichtigungen sind zunächst insgesamt ausgeschaltet. Prüfen Sie die Werte für Eingang und Ausgang, aktivieren Sie den Hauptschalter und wählen Sie <b>„Benachrichtigungen speichern“</b>. Die Grenzen gelten auch beim Laden.'),
 table(['Regel', 'Vorgabe und Einstellbereich'],[
 ['Hauptschalter', 'Aus. Einzelregeln gelten nur bei eingeschaltetem Hauptschalter und eingerichtetem Orion.'],
 ['Unterspannung je Anschluss', 'Ein: unter 12,00 V warnen; ab 12,30 V entwarnen.'],
 ['Überspannung je Anschluss', 'Aus: über 15,00 V warnen; bis 14,70 V entwarnen.'],
 ['Spannung bestätigen / entwarnen', '10 s / 30 s; je 1-600 s einstellbar. Mindestens drei neue gültige Werte über die jeweilige Dauer.'],
 ['Fehlende Orion-Daten', 'Ein: 30 s ohne gültige Daten; 10-3600 s einstellbar. Entwarnung nach neuen gültigen Daten.'],
 ['Orion-Ladefehler', 'Ein: feste 10 s bis zur Warnung und 30 s bis zur Entwarnung; mindestens drei neue gültige Werte.'],
 ['Wiederholungen', '0 min = aus; sonst 1-1440 min für unbestätigte aktive Vorfälle.'],
 ['Garmin-Zustellung', 'Aus. Experimentell; am eigenen Plotter prüfen. Bestätigung nur hier im Portal.']],[0.38,0.62]),
 p('Spannungswerte: <b>4-65 V</b>. Die Reihenfolge muss sein: untere Warngrenze &lt; untere Entwarnung &lt; obere Entwarnung &lt; obere Warngrenze. Der Eingabebereich ist keine Batterieempfehlung. Wählen Sie zur Anlage passende Grenzen.'),
 steps(('Aktive Warnung prüfen', 'Ein Banner bleibt auf allen Tabs sichtbar. „Meldungen öffnen“ führt zur Ursache. Bei Verbindungsabbruch ist der Status unbekannt, nicht automatisch in Ordnung.'),
 ('Bei Bedarf bestätigen', '„Bestätigen“ beendet die Erinnerungen für diesen Vorfall. Die aktive Warnung bleibt bis zur Entwarnung sichtbar; ihre Ursache wird dadurch nicht beseitigt. Ein neuer Vorfall muss neu bestätigt werden.')),
 note('Fehlende Daten sind keine Entwarnung', 'Ein vorhandener Spannungs- oder Ladefehler bleibt bei Empfangsausfall aktiv, sein aktueller Zustand wird unbekannt. Änderungen werden gespeichert; ein Neustart beginnt aktive Vorfälle neu.'))

page('Uhrzeit, Garmin und neue Fehlerhilfe', 'NEU IN 1.2.0 · 3 VON 3',
 pic('portal-active-alert.png', 104, 'Aktive Meldung mit lokaler Bestätigung, hier aus der Simulation. Das Warnbanner bleibt auch auf anderen Tabs sichtbar.'),
 h('Netzwerkzeit ergänzt UTC'),
 p('Ohne geprüfte Uhr zeigt der Monitor die Gerätelaufzeit. Drei zusammenpassende Zeitwerte einer erkannten NMEA-Quelle über mindestens eine Sekunde stellen UTC bereit. Frühere Ereignisse <b>desselben Starts</b> erhalten nachträglich geschätzte Kalenderzeiten. Die Berechnungen und Warnfristen verwenden immer die Laufzeit, nie die Kalenderuhr.'),
 p('Nach mehr als 30 s ohne akzeptierte Zeitaktualisierung läuft die Uhr geschätzt weiter. Ein widersprüchlicher Zeitsprung wird abgewiesen; die letzte geprüfte Zuordnung bleibt erhalten. Uhr und Ereignisse werden nicht dauerhaft gespeichert. Nach Neustart beginnt die Zeitsuche neu; die ausgeschaltete Dauer ist unbekannt.'),
 h('Garmin-Zustellung bleibt experimentell'),
 p('Die optionale Garmin-Zustellung ist ungeprüft. Ein Sendeauftrag beweist weder Anzeige, Ton noch Entwarnung. <b>Am Garmin bestätigen ist nicht unterstützt.</b> Bestätigen Sie im Portal. Vor geplantem Neustart: bis zu drei Rücknahmeversuche binnen fünf Sekunden. Die Entwarnung am Plotter bleibt unbestätigt; eine alte Warnung kann bestehen bleiben.'),
 table(['Symptom', 'Nächster Schritt'],[
 ['Keine Warnung', 'Hauptschalter und Einzelregel einschalten, speichern, gültige Orion-Daten und Bestätigungsdauer prüfen.'],
 ['Keine Uhrzeit / Zeitsprung', 'NMEA-Versorgung und Zeitquelle prüfen. Die Spannungswarnung funktioniert auch ohne Kalenderuhr.'],
 ['Garmin-Warnung bleibt stehen', 'Ursache und Portalstatus prüfen. Zustellung, Rücknahme und Wiederanlauf müssen am Plotter abgenommen werden; Stromausfall kann keine Rücknahme senden.']],[0.31,0.69]),
 p('<b>Zeitquelle:</b> Die Bridge empfängt und fordert 129029 (GNSS) sowie 126992 (Systemzeit) an. Garmin GPSMAP 7x3 ist für 129029 als Sender/Empfänger dokumentiert, für 126992 nur als Empfänger. Der eingebaute Garmin-Unterspannungsalarm ersetzt keinen Nachweis eigener Batteriealarme.'),
 p('<link href="https://www8.garmin.com/manuals/webhelp/GUID-BF2FF273-008A-482A-A96F-362ADA8996BA/EN-US/GUID-0C4B3FAB-3E41-438C-B31E-9B5489790913.html" color="#136d78">Garmin: PGN-Richtungen</link> · <link href="https://www8.garmin.com/manuals/webhelp/GUID-3E67C80C-0812-4EEC-BC60-699751B9CF6F/EN-US/GUID-353F7FD4-424B-4993-8124-A3CB450297BE.html" color="#136d78">Garmin: Systemalarme</link> · geprüft am 26.09.2026. Weitere Bediengrenzen: docs/diagnostics-logging.md.'))

page('Ersteinrichtung mit QR-Code', 'GERÄTEZUGANG · OHNE KONSOLE',
 p('Ihre installierende Person liefert eine <b>Geräte-Zugangsseite</b> mit genau Ihrer WLAN-Kennung und Ihrem gespeicherten WLAN-Passwort. Sie wird dieser Anleitung beigefügt. Diese allgemeine Ausgabe enthält keine individuellen WLAN-Zugangsdaten.'),
 steps(('Bridge starten', 'Im geprüften Aufbau einschalten. Die blaue LED zeigt die Bereitschaft des Service-WLANs. Ist es geschlossen, BOOT nach dem Start länger als zwei Sekunden halten und loslassen.'),
 ('WLAN-QR-Code der Zugangsseite scannen', 'Mit Kamera oder WLAN-Scanner des Handys scannen und die Verbindung bestätigen. Bei „Kein Internet“ im Bridge-WLAN bleiben. Der QR-Code übergibt Kennung und Passwort; er legt kein Administratorkonto an.'),
 ('Portal öffnen', 'Erst nach der WLAN-Verbindung den folgenden Portal-QR-Code scannen oder die Adresse im Browser eingeben. Bei einem bereits eingerichteten Gerät anmelden; beim ersten Konto BOOT wie auf Seite 10 halten.')),
 ('qr', 'https://192.168.4.1/', 'PORTAL ÖFFNEN · verbindet nicht mit dem WLAN'),
 p('<link href="https://192.168.4.1/" color="#136d78"><b>https://192.168.4.1/</b></link> · Lokale Zertifikatsausnahme wie auf Seite 9 prüfen.'),
 note('WLAN-Code ist ein Zugangsschlüssel', 'Die persönliche Zugangsseite sicher aufbewahren. Wer den WLAN-Code besitzt, kennt das WLAN-Passwort. Administrator-Passwort und Orion-Readout-Schlüssel gehören nicht in diesen Code.'),
 p('Ohne Geräte-Zugangsseite: individuelles Passwort bei der installierenden Person anfordern; USB-Auslesen auf Seite 8 bleibt der Serviceweg. Nach vollständigem Löschen des Gerätespeichers kann ein neues WLAN-Passwort entstehen; dann muss die Zugangsseite erneuert werden.'))

page('Die erste Baugruppe auf dem Tisch prüfen', 'HARDWARE · VOR DEM BOOTSANSCHLUSS',
 note('Kiloohm sind keine Anschlussfreigabe', 'Eine stromlose Messung findet manche Kurzschlüsse, aber keine falsche Polarität, Reglerüberspannung oder Busstörung im Betrieb. Messwerte mit Leitungspaar und Schalterstellung protokollieren.', 'warn'),
 steps(('Stromlos prüfen', 'Boot und USB abtrennen. Micro-C-Pins bis J1 durchmessen: 1 Schirm, 2 NET-S, 3 NET-C, 4 CAN-H, 5 CAN-L. Schirm, Busmasse und Logikmasse sind getrennt. Zwischen Bus- und Logikmasse darf kein stabiler leitender Pfad bestehen. RUN = SW3 1-2; SERVICE = 2-3.'),
 ('USB-Test in SERVICE', 'SERVICE vor USB wählen. Portal, WLAN und Orion-Empfang prüfen. Das testet noch nicht Busversorgung oder CAN-Treiber. Vor RUN USB vollständig abziehen.'),
 ('Busversorgung getrennt vom Boot prüfen', 'Netzteil ausgeschaltet: nur + an J1.2 und − an J1.3, Datenleitungen frei. 12 V einstellen, RUN wählen. Mit etwa 0,10 A Stromgrenze kurz auf groben Fehler prüfen; damit ist normaler Start nicht zugesichert. Bei unauffälliger Sicht- und Spannungsprüfung ausschalten, dann für den Funktionstest bis 0,60 A begrenzen.'),
 ('Spannungen und Startverhalten messen', '5V_BUS gegen GND_BUS: Ziel 5 V, U1 zulässig 4,5-5,5 V. 5V_ISO, 5V_MODULE und 3V3_LOGIC jeweils gegen GND_LOGIC messen. 3V3_LOGIC muss auch bei Start/Funklast innerhalb 3,0-3,6 V bleiben. Einbrüche und Einschaltspitzen mit geeigneter Oszilloskopmessung prüfen.'),
 ('CAN separat prüfen', 'Erst danach einen kleinen, korrekt versorgten Prüfbus mit zwei 120-Ω-Endabschlüssen und einem zweiten aktiven CAN/NMEA-Knoten nutzen. Die Bridge hat keinen eigenen Abschluss. Ohne zweiten Knoten fehlt CAN-ACK; Sendefehler beweisen dann keinen Hardwaredefekt.')),
 note('Messgerät darf Isolation nicht überbrücken', 'Normale Oszilloskop-Masseklemmen sind häufig untereinander und mit Schutzleiter verbunden. Niemals gleichzeitig an Busmasse und Logikmasse klemmen. Differenztastkopf oder nachgewiesen isolierte Messkanäle verwenden; Schutzleiter nicht entfernen.', 'danger'),
 p('Bei unerwarteter Erwärmung, Geruch, bleibender Strombegrenzung oder falschen Spannungen ausschalten. 9/12/16-V-Start-, Funklast- und geschlossene Gehäusetests folgen vor der Bordabnahme. Detaillierte Messpunkte und Protokoll: docs/orion-r5-commissioning.md.'))

page('Fehlerfolgen und erster Anschluss am Boot', 'HARDWARE · RISIKEN UND ABNAHME',
 table(['Fehler', 'Mögliche Folge'],[
 ['Versorgung auf CAN-Pin / falscher Steckerblick', 'Beschädigung von Schutzbauteilen, Transceivern oder angeschlossenen Geräten. Eine Stromsicherung schützt die Datenleitungen nicht zuverlässig.'],
 ['Kurzschluss, Verpolung, falscher Regler', 'Ausfall, Erwärmung oder Bauteilschaden; im Fehlerfall auch Kabel-/Brandrisiko. Schutzbauteile ersetzen keine geprüfte Bestückung.'],
 ['CAN-H/L vertauscht, falsche Abschlüsse, defekter Treiber', 'Keine Kommunikation bis zum Ausfall des gesamten NMEA-Netzes; Ausfall angezeigter Navigations-, Motor- oder Alarmdaten.'],
 ['USB in RUN / Massebrücke', 'Rückspeisung oder Verlust der galvanischen Trennung; mögliche Schäden und Störungen auch am USB-Computer.'],
 ['Zu wenig Versorgungsreserve / Funklast / Wärme', 'Spannungseinbrüche, Neustarts, instabile Übertragung und beschleunigte Alterung.'],
 ['Doppelte Instanzen / ungeprüfte Warnungen', 'Falsch zugeordnete oder alte Anzeigen; Warnungen können fehlen oder stehen bleiben.']],[0.35,0.65]),
 steps(('Backbone zuerst prüfen', 'Vollständig spannungsfrei: CAN-H gegen CAN-L ungefähr 60 Ω durch zwei parallele 120-Ω-Abschlüsse. 120 Ω deutet auf einen fehlenden Abschluss hin, deutlich weniger auf zusätzliche Abschlüsse oder Fehler. Kiloohm am Backbone sind kein normaler Abschlussnachweis. [H2]'),
 ('Versorgung und Reserve bestätigen', 'Am Geräteabzweig 9-16 V mit richtiger Polarität. Keine direkte 24-V-Versorgung. Für die Bridge vorläufig 12 LEN = 600 mA reservieren; tatsächliche Spitzen und Spannungsabfall messen. Das ist keine gemessene Verbrauchsangabe. [H1]'),
 ('Im sicheren Stillstand anschließen', 'Alle Tischprüfungen zuerst abschließen. Bestehende Geräteliste und Anzeigen festhalten. NMEA abschalten, Bridge am Drop anschließen, USB bleibt abgezogen. Einschalten und Versorgung, Strom, Geräteliste sowie bestehende Daten vergleichen.'),
 ('Bei Störung zurückbauen', 'Bei neuen Ausfällen oder Fehlern Netz abschalten und nur die Bridge abtrennen. Den vorherigen Zustand prüfen. Keine Tests während Fahrt oder sicherheitsabhängigem Betrieb.')),
 p('Bauteilschutz ist keine Garantie für die komplette Baugruppe. Die ISO1042-Isolation und Busfehlerfestigkeit gelten unter Datenblattbedingungen; Lötfehler, falsche Anschlüsse und externe Massebrücken können sie umgehen. Keine Zertifizierung oder Bordfreigabe wird daraus abgeleitet.'),
 p('<link href="https://www.ti.com/lit/ds/symlink/iso1042.pdf" color="#136d78">TI: ISO1042</link> · <link href="https://support.garmin.com/en-HK/?faq=656KiuIo733b27xQgmLBy7" color="#136d78">Garmin: NMEA-Fehlersuche und 60-Ω-Prüfung</link> · geprüft 10.10.2026.'))

def para(text, style='p'):
    return Paragraph(text, ST[style])

def logo(c, x, y, size):
    """Project shield outline, with the requested lightning center, all vector."""
    c.saveState(); c.translate(x,y); c.scale(size/64,size/64)
    c.setFillColor(SURFACE); c.roundRect(0,0,64,64,17,fill=1,stroke=0)
    c.setLineWidth(2.6); c.setStrokeColor(TEAL); c.setLineJoin(1)
    q=c.beginPath(); q.moveTo(17,51); q.lineTo(47,51); q.curveTo(51,51,52,49,52,46)
    q.lineTo(52,30); q.curveTo(52,18,43,10,32,5); q.curveTo(21,10,12,18,12,30)
    q.lineTo(12,46); q.curveTo(12,49,13,51,17,51); q.close(); c.drawPath(q)
    c.setFillColor(BLUE); c.roundRect(25,51,14,6,1.5,fill=1,stroke=0)
    q=c.beginPath(); q.moveTo(35,45); q.lineTo(22,29); q.lineTo(31,29); q.lineTo(28,16)
    q.lineTo(43,35); q.lineTo(34,35); q.close(); c.setFillColor(TEAL); c.drawPath(q,fill=1,stroke=0)
    c.restoreState()

class Note(Flowable):
    def __init__(self,title,text,kind):
        Flowable.__init__(self); self.title=para(title,'h'); self.body=para(text); self.kind=kind
    def wrap(self,w,h):
        self.width=w; self.th=self.title.wrap(w-28,h)[1]; self.bh=self.body.wrap(w-28,h)[1]
        self.height=self.th+self.bh+27; return w,self.height
    def draw(self):
        c=self.canv; c.setFillColor({'info':PALE,'warn':HexColor('#fff5e5'),'danger':HexColor('#fff0ef')}[self.kind])
        c.roundRect(0,0,self.width,self.height,10,stroke=0,fill=1)
        c.setFillColor({'info':HexColor('#239b94'),'warn':HexColor('#cf963c'),'danger':HexColor('#c95958')}[self.kind])
        c.roundRect(0,11,3,self.height-22,1.5,stroke=0,fill=1)
        self.title.drawOn(c,14,self.height-10-self.th)
        self.body.drawOn(c,14,12)

class Diagram(Flowable):
    def __init__(self,kind): Flowable.__init__(self); self.kind=kind; self.width=CW; self.height=146 if kind=='flow' else 157
    def draw(self):
        c=self.canv; c.setFillColor(NAVY); c.roundRect(0,0,self.width,self.height,12,fill=1,stroke=0)
        def label(x,y,t,size=10,color=white): c.setFont('Bold',size); c.setFillColor(color); c.drawCentredString(x,y,t)
        if self.kind=='flow':
            xs=[65,250,441]
            for x,title,sub in zip(xs,['ORION','ORION-BRIDGE','GARMIN'],['Ladegerät','Übersetzt Messwerte','Zeigt Daten an']):
                c.setFillColor(SURFACE); c.roundRect(x-55,62,110,52,9,fill=1,stroke=0); label(x,93,title,10); label(x,76,sub,8,BLUE)
            c.setStrokeColor(TEAL); c.setLineWidth(2)
            for a,b in [(120,194),(305,385)]:
                c.line(a,87,b,87); c.line(b-6,91,b,87); c.line(b-6,83,b,87)
            label(157,121,'Bluetooth',8,TEAL); label(346,121,'NMEA 2000',8,TEAL)
            label(250,28,'Handy / Browser über lokales WLAN zur Bridge',10,TEAL)
            c.line(250,40,250,59)
        else:
            c.setStrokeColor(TEAL); c.setLineWidth(5); c.line(55,106,455,106)
            for x in [55,455]:
                c.setFillColor(BLUE); c.roundRect(x-5,93,10,26,2,fill=1,stroke=0)
            label(59,130,'120 Ω',9,BLUE); label(453,130,'120 Ω',9,BLUE)
            for x,title in [(170,'Orion-Bridge'),(345,'Plotter')]:
                c.setLineWidth(2); c.line(x,106,x,59); c.setFillColor(SURFACE); c.roundRect(x-66,26,132,34,8,fill=1,stroke=0); label(x,39,title,10)
            label(250,127,'Backbone / Hauptleitung',10,TEAL)
            label(87,73,'Drop',9,BLUE); label(254,77,'T-Stücke',9,BLUE)
            label(250,9,'Schema · bestehende abgesicherte Netzversorgung vorausgesetzt',8,BLUE)

def make_table(headers, rows, widths):
    widths=widths or [1/len(headers)]*len(headers)
    data=[[para(escape(x),'cellhead') for x in headers]]+[[para(x,'cell') for x in row] for row in rows]
    t=Table(data,colWidths=[CW*f for f in widths],hAlign='LEFT')
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),SURFACE),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),10),('RIGHTPADDING',(0,0),(-1,-1),10),('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7),('ROWBACKGROUNDS',(0,1),(-1,-1),[PALE,white]),('LINEBELOW',(0,1),(-1,-1),0.4,LINE)]))
    return t

def flowables(block):
    typ=block[0]
    if typ in ['p','h']: return [para(block[1],typ)]
    if typ=='note': return [Note(*block[1:])]
    if typ=='table': return [make_table(*block[1:])]
    if typ=='diagram': return [Diagram(block[1])]
    if typ=='qr':
        code=QrCodeWidget(block[1],barLevel='M',barBorder=4)
        x0,y0,x1,y1=code.getBounds(); size=128
        drawing=Drawing(size,size,transform=[size/(x1-x0),0,0,size/(y1-y0),0,0])
        drawing.add(code)
        return [drawing,para(block[2],'small')]
    if typ=='steps':
        return [para(f'<font color="#147c80"><b>{i:02d}</b></font>  <b>{title}</b><br/>{text}') for i,(title,text) in enumerate(block[1],1)]
    if typ=='pic':
        path=ASSETS/block[1]; w,h=PILImage.open(path).size; scale=min(CW/w,block[2]/h)
        return [Image(str(path),w*scale,h*scale,hAlign='CENTER'),para(block[3],'small')]
    return []

def footer(c,n,total):
    c.setStrokeColor(LINE); c.setLineWidth(.6); c.line(M,42,W-M,42)
    c.setFont('Body',8); c.setFillColor(MUTED); c.drawString(M,27,'BatterySentinel-N2K · Orion-R5   |   Ausgabe 1.5 · 10.10.2026')
    c.setFont('Bold',8); c.drawRightString(W-M,27,f'{n:02d} / {total:02d}')

def cover(c,total):
    c.setFillColor(NAVY); c.rect(0,0,W,H,fill=1,stroke=0)
    c.setStrokeColor(HexColor('#163043')); c.setLineWidth(.4)
    for x in range(0,600,36): c.line(x,0,x,H)
    for y in range(0,850,36): c.line(0,y,W,y)
    logo(c,M,660,106)
    c.setFillColor(TEAL); c.setFont('Bold',11); c.drawString(M,623,'BATTERYSENTINEL-N2K')
    c.setFillColor(white); c.setFont('Bold',40); c.drawString(M,568,'Energie im Blick.')
    c.setFont('Light',29); c.drawString(M,517,'Betriebs- und'); c.drawString(M,480,'Installationsanleitung')
    c.setFont('Bold',15); c.setFillColor(BLUE); c.drawString(M,437,'Orion-R5 / Orion-Bridge')
    c.setFont('Body',12); c.setFillColor(HexColor('#c0d2db'))
    for y,t in [(394,'Schritt für Schritt vom Einbau zur Anzeige am Garmin.'),(373,'Mit Bedienhilfe, Fehlerdiagnose und Übergabeprotokoll.')]: c.drawString(M,y,t)
    c.setFillColor(SURFACE); c.roundRect(M,171,CW,132,17,stroke=0,fill=1)
    for i,(num,title,sub) in enumerate([('01','INSTALLIEREN','Anschließen und prüfen'),('02','EINRICHTEN','Verbinden und zuordnen'),('03','BETREIBEN','Verstehen und beheben')]):
        x=M+19+i*165; c.setFillColor(TEAL); c.setFont('Bold',22); c.drawString(x,263,num)
        c.setFont('Bold',10); c.setFillColor(white); c.drawString(x,230,title)
        c.setFont('Body',8.9); c.setFillColor(BLUE); c.drawString(x,210,sub)
    c.setFillColor(TEAL); c.setFont('Bold',10); c.drawString(M,123,'DEUTSCH · AUSGABE 1.5 · 10. OKTOBER 2026')
    c.setFont('Body',9); c.setFillColor(HexColor('#b8cbd5')); c.drawString(M,100,'Firmware 1.2.0 · Eigenbau-Prototyp mit 4-MB-SuperMini.')
    c.drawString(M,84,'Vor Installation und USB-Service die Sicherheitshinweise lesen.')
    c.setFont('Body',8); c.drawRightString(W-M,27,f'01 / {total:02d}')
    c.bookmarkPage('cover'); c.addOutlineEntry('Titel', 'cover', 0); c.showPage()

def build():
    OUT.parent.mkdir(parents=True,exist_ok=True)
    c=canvas.Canvas(str(OUT),pagesize=(W,H),pageCompression=1)
    c.setTitle('BatterySentinel-N2K Orion-R5 | Betriebs- und Installationsanleitung')
    c.setAuthor('BatterySentinel-N2K Projekt'); c.setSubject('Deutsche Anleitung mit Installation, Bedienung und Troubleshooting')
    c.setCreator('BatterySentinel-N2K · ReportLab manual builder')
    c._doc.Catalog.Lang=PDFString('de-DE')
    total=len(PAGES)+1; cover(c,total); measures=[]
    for n,(title,subtitle,blocks) in enumerate(PAGES,2):
        c.setFillColor(NAVY); c.rect(0,H-126,W,126,fill=1,stroke=0)
        logo(c,W-M-46,H-63,40)
        c.setFillColor(TEAL); c.setFont('Bold',8.6); c.drawString(M,H-39,subtitle)
        fs=23
        while pdfmetrics.stringWidth(title,'Bold',fs)>CW: fs-=.25
        c.setFillColor(white); c.setFont('Bold',fs); c.drawString(M,H-79,title)
        c.setFillColor(BLUE); c.setFont('Body',9); c.drawString(M,H-104,'BatterySentinel-N2K  /  Orion-R5')
        c.bookmarkPage(f'p{n}'); c.addOutlineEntry(title,f'p{n}',0)
        footer(c,n,total); y=H-144
        for block in blocks:
            if block[0]=='form':
                for j,label in enumerate(['Boot / Einbauort','Bridge-Kennung / Firmware','Orion-Modell / Firmware','Garmin-Modell / Software','Eingang: Name / Instanz','Ausgang: Name / Instanz']):
                    c.setFont('Bold',9); c.setFillColor(INK); c.drawString(M,y-12,label)
                    c.acroForm.textfield(name=f'record_{j}',tooltip=label,x=M+181,y=y-23,width=CW-181,height=24,fontName='Helvetica',fontSize=10,borderWidth=.5,borderColor=LINE,fillColor=PALE,textColor=INK,forceBorder=True)
                    y-=34
                y-=6; continue
            if block[0]=='checks':
                for j,text in enumerate(block[1]):
                    pp=para(text,'cell'); _,height=pp.wrap(CW-25,700)
                    c.acroForm.checkbox(name=f'check_{j}',tooltip=text,x=M+1,y=y-13,size=11,borderWidth=.7,borderColor=MUTED,fillColor=white,buttonStyle='check',checked=False,forceBorder=True)
                    pp.drawOn(c,M+24,y-height); y-=max(height,14)+7
                y-=6; continue
            if block[0]=='lines':
                c.setStrokeColor(LINE); c.setLineWidth(.6)
                for _ in range(block[1]): y-=21; c.line(M,y,W-M,y)
                y-=9; continue
            for f in flowables(block):
                before=getattr(f,'spaceBefore',0); after=getattr(f,'spaceAfter',0)
                width,height=f.wrap(CW,700); y-=before
                if y-height<54: raise ValueError(f'Page {n} overflow ({y-height:.1f}): {title} / {block[0]}')
                x=M+(CW-width)/2 if isinstance(f,Image) else M
                f.drawOn(c,x,y-height); y-=height+max(after,8)
        if y<46: raise ValueError(f'Page {n} custom content overflow: {y}')
        measures.append({'page':n,'title':title,'bottom_y':round(y,2)})
        c.showPage()
    c.save()
    (ROOT/'tmp/pdfs').mkdir(parents=True,exist_ok=True)
    (ROOT/'tmp/pdfs/manual-layout.json').write_text(json.dumps(measures,indent=2,ensure_ascii=False),encoding='utf8')
    source_files=['src/BridgePortalUi.h','src/BridgePortal.cpp','src/BridgePortalOta.h','src/BridgePortalTranslations.h','src/BridgeSettings.cpp','src/dongle_main.cpp','src/NmeaPublisher.cpp','include/config.h','hardware/altium-r5/power-review.md','hardware/altium-r5/module-selection.md']
    source_files += ['src/BridgeFirmwareIdentity.h', 'src/BridgePortalForm.h', 'lib/BridgeAuth/src/BridgePasswordUpdate.h']
    source_files += ['src/BridgePortalInsights.h','src/BridgePortalLanguage.h','src/BridgeDiagnostics.cpp','src/BridgeDiagnostics.h','src/BridgeNotificationForm.h','lib/BridgeInsights/src/BridgeInsights.h','lib/BridgeInsights/src/BridgeNotificationStore.h','lib/BridgeTime/src/BridgeTime.h','lib/BridgeNmeaAlerts/src/BridgeNmeaAlerts.h']
    source_files += ['docs/diagnostics-logging.md','docs/orion-xs-bridge.md','docs/firmware-update.md','tools/build_german_manual.py','tools/check_german_manual.py','tools/capture_manual_portal.cjs','docs/manual-assets/portal-channels.png','docs/manual-assets/portal-counters.png','docs/manual-assets/portal-insights.png','docs/manual-assets/portal-active-alert.png']
    source_files += ['tools/create_service_wifi_manual.py','tools/check_service_wifi_manual.py','docs/service-wifi-qr.md','docs/orion-r5-commissioning.md']
    manifest={'manual':'1.5','date':'2026-10-10','firmware':'1.2.0','pages':total,'sources':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in source_files}}
    (ASSETS/'source-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    print(f'Created {OUT} ({total} pages)')

if __name__=='__main__': build()
