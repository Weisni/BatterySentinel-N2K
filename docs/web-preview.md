# Orion-Weboberfläche ohne Gerät öffnen und debuggen

Die lokale Vorschau lädt die echte HTML-, CSS- und JavaScript-Oberfläche aus dem Firmware-Quellcode. Ein kleiner Server liefert simulierte Orion- und NMEA-Daten. Dafür brauchst du Node.js und das Repository auf deinem Computer; ein ESP32, Orion oder Garmin ist nicht erforderlich.

## Starten

Öffne ein Terminal im Hauptverzeichnis des Repositorys und starte:

```powershell
node tools/preview_portal.mjs
```

Öffne dann **[http://127.0.0.1:8765/](http://127.0.0.1:8765/)** im Browser. Das Terminal bleibt während der Vorschau offen. Mit **Strg+C** beendest du den Server.

Falls der Port belegt ist, wähle einen anderen:

```powershell
node tools/preview_portal.mjs --port 8766
```

Die Adresse lautet dann [http://127.0.0.1:8766/](http://127.0.0.1:8766/). Der Server ist nur auf dem eigenen Computer erreichbar.

## Ausprobieren

Über die zusätzliche Debug-Leiste wechselst du zwischen Dashboard, Anmeldung und erster Administratoreinrichtung. Die erzwungene Anmelde-Vorschau liegt unter `/__preview/login`. Ein normaler Aufruf von `/login` leitet wie die Firmware nach `/` weiter; die Vorschau zeigt dort ihr simuliertes Dashboard. Die eigentliche Anmeldung sendet weiterhin einmalig per POST an `/login` und wechselt anschließend per 303-Weiterleitung nach `/`.

Du kannst außerdem simulierte Zustände auswählen:

- laufender Empfang mit gültigen Messwerten;
- Orion-Empfangsfehler;
- NMEA-Sendefehler;
- veraltete Orion-Daten;
- Verbindungsunterbrechung;
- abgelaufene Anmeldung.
- eine simulierte Unterspannungswarnung (aktiviert den Hauptschalter der Vorschau);
- verfügbare Netzwerkzeit mit nachträglich zugeordneten Ereigniszeiten;
- OTA-Ablehnung, Verbindungsverlust und simuliert gedrückte BOOT-Taste.

Im Dashboard kannst du Übersicht, Einstellungen, Anleitung, Parameter-Monitor, Auswertung und Meldungen bedienen und Deutsch/Englisch wechseln. Die Übersicht gruppiert Eingang und Ausgang jeweils mit Spannung, Strom und berechneter Leistung. Ist ein Orion bereits eingerichtet, entfällt dort die Aufforderung „Orion einrichten“; Änderungen erreichst du weiterhin über „Einstellungen“.

Die **Auswertung** zeigt Beispielverläufe, Min./Max., Spannungstrend, beobachtete Orion-Ah/Wh samt Datenabdeckung und Zeit unter der gespeicherten Unterspannungsgrenze. Es handelt sich um simulierte Anschlusswerte, nicht um den gesamten Batterieverbrauch. Eine Werte-Lücke im Vorschauverlauf prüft, dass die Darstellung keine Verbindung über fehlende Daten zeichnet; die Firmware beginnt nach einer längeren Empfangslücke einen neuen zusammenhängenden Verlauf.

Unter **Meldungen** sind der Hauptschalter und Garmin-Zustellung zunächst aus. Ändere die Eingangswerte, aktualisiere die Live-Daten oder wechsle die Sprache: ungespeicherte Eingaben bleiben erhalten. Speichern verwendet die tatsächlichen Formularfelder und eine Weiterleitung zurück zu `/#notifications`. Das Szenario „Spannungswarnung“ erzeugt eine aktive Ausgangsmeldung und ein Banner auf allen Tabs. Nach lokalem Bestätigen bleibt die Ursache aktiv, weitere Erinnerungen werden für diesen Vorfall beendet. Ein alter Bestätigungsauftrag darf keinen neuen Vorfall bestätigen.

Das Szenario „Netzwerkzeit“ ergänzt UTC; bereits angezeigte Ereignisse desselben Starts erhalten nachträglich zugeordnete Zeiten. Bei fehlendem Browserkontakt zeigen Auswertung und Warnbanner einen unbekannten Status. Die Vorschau stellt keine echte Netzwerk-Uhrprüfung oder Garmin-Zustellung nach. Die [Bedienreferenz](diagnostics-logging.md) beschreibt das tatsächliche Verhalten und die Vorgaben der Firmware 1.2.0.

Unter „Einstellungen“ lassen sich die Kanalnamen getrennt speichern: Vorgabe ist **Startbatterie** für den Eingang und **Bugbatterie** für den Ausgang. Verwende zwei verschiedene Namen mit jeweils 1–32 Zeichen ohne Steuerzeichen. Das Speichern benötigt keinen Orion-Schlüssel und keinen Neustart. Prüfe die Namen anschließend in der Übersicht und nach dem Neuladen; Änderungen an der Orion-Verbindung oder „Orion vergessen“ behalten sie bei. In der Vorschau bleiben die Namen nur bis zum Beenden des Servers gespeichert.

Die Statusfarben helfen beim Prüfen der Szenarien: Grün steht für einen ordnungsgemäßen aktuellen Zustand, Gelb für Warten, veraltete oder fehlende Daten, einen Abschaltgrund oder frühere Fehler. Rot kennzeichnet einen aktuellen erkannten Fehler. Ein alter Fehlversuch für die momentan nicht benötigte Ladezustands-PGN 127507 hält den Gesamtstatus nicht auf Rot. Die einzelnen PGN-Karten zeigen weiterhin ihren letzten Sendeversuch samt Alter.

Prüfe unter „Einstellungen“ auch die Rückmeldung während der Eingabe: Eine unvollständige MAC-Adresse oder ein zu kurzer Schlüssel zeigt einen Hinweis, ungültige Zeichen oder zu lange Eingaben einen Fehler. Die MAC-Doppelpunkte werden automatisch ergänzt. Zum Freigeben von „Speichern und neu starten“ sind eine vollständige MAC, genau 32 Hexadezimalzeichen als Schlüssel und zwei verschiedene ganzzahlige NMEA-Instanzen von 0 bis 252 erforderlich. Ungültige Zeichen und zu lange eingefügte Werte bleiben sichtbar. Probiere etwa `AABBCCDDEEFF`, einen Schlüssel aus 32 Nullen und zunächst gleiche, dann verschiedene Instanzen aus.

Formularaktionen sind simuliert und verändern kein Gerät. Verwende ausschließlich erfundene Zugangsdaten und Schlüssel. Die Vorschau speichert ihre Geräteeinstellungen nur im Arbeitsspeicher; ein Serverneustart setzt sie zurück. Die Sprachwahl kann wie beim echten Portal im Browser gespeichert bleiben.

## Debuggen

Öffne mit **F12** die Entwicklerwerkzeuge des Browsers. In der Konsole siehst du JavaScript-Fehler, unter „Netzwerk“ die Abfragen an `/api/live`, und mit der Geräteansicht prüfst du schmale Handy-Layouts. Haltepunkte im ausgelieferten JavaScript helfen beim Nachvollziehen der Bedienung.

Ändere die Portaldateien unter `src/`, zum Beispiel `BridgePortalUi.h`, `BridgePortalTranslations.h`, `BridgePortalLanguage.h`, die Formularlogik in `BridgePortalForm.h` oder den Auswertungs-Controller `BridgePortalInsights.h`, und lade die Browserseite neu. Die Vorschau liest den aktuellen Quellcode beim Laden; ein Firmware-Build ist dafür nicht nötig.

Die Vorschau prüft Darstellung und Browser-Verhalten. Sie emuliert weder den ESP32 noch Bluetooth, CAN, NMEA-Empfang am Garmin, HTTPS-Zertifikate oder die echte Passwortprüfung. Diese Eigenschaften müssen weiterhin mit Hardware geprüft werden.

Zum echten Gerät führt die separate [Anleitung zur Erstverbindung](erstverbindung.md).

Der optionale Browsertest `node tools/verify_portal_login_browser.cjs` nutzt Playwright und Microsoft Edge. Bei einer anderen Playwright-Installation gibst du deren Modulpfad über `MANUAL_PLAYWRIGHT` an. Der Test prüft normale und verzögerte Anmeldung, Schutz gegen doppeltes Absenden, Neuladen nach der Weiterleitung und die Rückkehr per Browser-Zurück in Deutsch und Englisch. Er prüft außerdem die Wiederherstellung nach einer simulierten fehlgeschlagenen Navigation. Diese lokalen Prüfungen bilden weder die TLS-Verbindung des ESP32 noch seine Passwortberechnung nach.

Der Login löst keine automatischen Wiederholungen aus. Nach erfolgreicher 303-Weiterleitung lädt „Neu laden“ nur das Dashboard. Bei einer fehlgeschlagenen POST-Navigation kann der Browser beim ausdrücklich gewählten Neuladen das Formular erneut senden; das bleibt Browser-Verhalten. Ein erneuter Aufruf von `/login` über die Adresszeile verwendet dagegen GET und leitet nach `/` weiter.

`node tools/verify_portal_insights_browser.cjs` prüft Auswertung und Meldungen in Edge, Deutsch/Englisch und 390/1280 Pixel Breite: sichtbare Datenlücken, Abdeckung, Eingabegrenzen, Erhalt ungespeicherter Änderungen, Speichern ohne parallele Live-Abfrage, doppelte Formularereignisse, vorfallbezogenes Bestätigen, tabübergreifendes Warnbanner, Zustellungsrückstand sowie UTC-Zuordnung und neue Boot-Kennung. Eine zusätzliche künstliche Antwort prüft den Hinweis auf unbestätigte Garmin-Rücknahmen. Im tatsächlichen Neustartablauf ist die Live-Abfrage während der Rücknahme gesperrt; nach Neustart wird diese Markierung nicht erhalten. Der Test belegt daher nur die Darstellung dieses Hinweises, keine abrufbare Abschalthistorie. Prüfbilder liegen unter `tmp/insights-ui/`. `verify_portal_ui.mjs`, `verify_portal_preview.mjs` und `verify_portal_ota.mjs` ergänzen die automatisierten Prüfungen ohne Hardware.
