# Orion Bridge: Erstverbindung ohne Zugriff auf das Gerät

Diese Anleitung ist im Repository verfügbar, **bevor** du dich mit dem WLAN der Orion Bridge verbindest. Speichere sie vorher auf dem Handy oder drucke sie aus. Sie gilt für die Orion Bridge mit ESP32-C3 SuperMini auf der Orion-R5-Platine.

## Das brauchst du

- Die eingeschaltete Orion Bridge mit installierter Firmware.
- Ein Handy oder einen Computer mit WLAN und Browser.
- Den Geräte-WLAN-QR-Code oder das individuelle WLAN-Passwort der Bridge. Mit der mitgelieferten Geräte-Zugangsseite brauchst du keine Konsole. Ohne Zugangsdaten lässt die installierende Person das Passwort einmal über USB auslesen.
- Für die anschließende Orion-Einrichtung: die Bluetooth-MAC-Adresse und den Instant-Readout-Schlüssel aus VictronConnect.

## 1. WLAN öffnen und Passwort ablesen

**Mit Geräte-Zugangsseite:** Starte die Bridge, scanne deren WLAN-QR-Code und bestätige die Verbindung. Der Code enthält genau die Kennung und das Passwort dieses Geräts. Bleibe trotz „Kein Internet“ verbunden; öffne dann den separaten Portal-QR-Code oder die Adresse unter Schritt 2. Bei bereits eingerichteter Bridge meldest du dich normal an. Den folgenden USB-Abschnitt brauchst du dafür nicht. Die installierende Person erstellt die Zugangsseite mit dem [lokalen QR-Skript](service-wifi-qr.md); die allgemeine Anleitung enthält keine individuellen WLAN-Zugangsdaten.

Die Bridge öffnet nach jedem normalen Start das WLAN **`OrionBridge-XXXXXX`**. Die letzten sechs Zeichen unterscheiden die Geräte. Ohne verbundenen WLAN-Client schließt es nach fünf Minuten. Während ein Client verbunden ist, bleibt es geöffnet; nach dem letzten Client beginnt wieder eine Frist von fünf Minuten.

Die **blaue LED auf dem SuperMini** wird beim Start der Anwendung sofort ausgeschaltet. Sie leuchtet erst, wenn der WLAN-Treiber den gestarteten Access Point meldet, dessen IP-Adresse verfügbar ist und der HTTPS-Dienst bereit ist. Dazu muss noch kein Handy verbunden sein. Sobald das WLAN geschlossen wird, erlischt sie. Die Anzeige folgt dem Status ohne feste Wartezeit. Die WLAN-Liste deines Handys kann sich erst beim nächsten Suchlauf aktualisieren; ein kurzes Aufleuchten vor dem Anwendungsstart durch Boot-ROM/Bootloader ist damit nicht ausgeschlossen.

Falls das WLAN schon geschlossen ist, halte die Taste **BOOT nach dem normalen Start länger als zwei Sekunden** gedrückt. Das öffnet das WLAN erneut und lässt die gespeicherten Einstellungen bestehen. Halte BOOT dabei nicht während eines Resets oder beim Einschalten: Das kann den Programmiermodus starten.

Es gibt kein gemeinsames Standard-WLAN-Passwort. Das zufällig erzeugte Passwort gehört genau zu deiner Bridge. So liest du es lokal aus:

1. Stelle den Schalter der aufgebauten Bridge auf **SERVICE**, bevor du sie über ein USB-Datenkabel mit dem Computer verbindest. Trenne USB wieder, bevor du auf **RUN** umschaltest.
2. Öffne den zugehörigen USB-Seriell-Port mit **115200 Baud**. In einem vorhandenen PlatformIO-Projekt ist beispielsweise `pio device monitor -b 115200` möglich; wähle bei mehreren Ports den Port der Bridge.
3. Warte den normalen Start ab und halte dann BOOT länger als zwei Sekunden gedrückt.
4. Lies im seriellen Monitor die Zeile **`Service AP password:`**. Das funktioniert auch, wenn das WLAN bereits offen ist. Vor dem Anlegen des ersten Administrators erscheint diese Zeile zusätzlich beim Start.

Bewahre das Passwort privat auf. WLAN-Passwort, Administrator-Passwort und Orion-Schlüssel sind unterschiedliche Zugangsdaten.

## 2. Mit dem Handy verbinden

1. Wähle in den WLAN-Einstellungen **`OrionBridge-XXXXXX`** und gib das individuelle WLAN-Passwort ein.
2. Bleibe mit diesem WLAN verbunden, auch wenn das Handy „Kein Internet“ meldet. Die Bridge ist ein lokales Netzwerk.
3. Öffne im Browser **[https://batterysentinel.local/](https://batterysentinel.local/)**. Tippe die vollständige Adresse mit `https://` in die Adresszeile. Der Name wird lokal über mDNS aufgelöst und ist für die direkte Verbindung mit dem Bridge-WLAN vorgesehen.
4. Falls der Name nicht funktioniert, etwa wegen der Namensauflösung, privatem DNS oder VPN, öffne **[https://192.168.4.1/](https://192.168.4.1/)**. Ein Internetzugang ist für beide Adressen nicht nötig.
5. Der Prototyp verwendet ein selbstsigniertes Zertifikat für den lokalen Namen und die IP-Adresse. Bestätige dessen Browser-Ausnahme nur für die Bridge, während du direkt mit dem erwarteten Bridge-WLAN verbunden bist.

## 3. Administrator anlegen oder anmelden

Beim ersten Zugriff legst du einen lokalen Administrator an. Der Benutzername hat 3–32 Zeichen: Buchstaben, Ziffern, Unterstrich oder Bindestrich. Das Passwort hat 12–128 Zeichen. **Halte BOOT gedrückt, während du das Formular zum Anlegen des Administrators absendest**, bis die Bridge die Anfrage angenommen hat.

Bei späteren Besuchen meldest du dich mit diesen Administrator-Zugangsdaten an. Die Passwortprüfung dauert einige Sekunden. Warte auf die Antwort, bevor du erneut absendest. Eine Sitzung läuft nach 15 Minuten ohne authentifizierte Anfrage ab; auch das Schließen des Service-WLANs beendet sie.

### Administrator-Passwort ändern

Öffne nach der Anmeldung **Einstellungen → Passwort ändern**. Gib das aktuelle Passwort und zweimal das neue Passwort ein und speichere. Das neue Passwort muss 12–128 UTF-8-Bytes lang sein; einfache lateinische Buchstaben und Ziffern benötigen jeweils ein Byte, Umlaute und Emoji mehr. Warte auf die Bestätigung und melde dich anschließend mit deinem bisherigen Benutzernamen und dem neuen Passwort an. Alle gespeicherten Daten und Zuweisungen bleiben erhalten.

### Administrator-Passwort vergessen

1. Verbinde dich wie oben mit dem Service-WLAN und öffne die Anmeldeseite.
2. Wähle **Passwort vergessen?** und bestätige im Formular, dass du das Administrator-Passwort zurücksetzen möchtest.
3. Halte **BOOT am bereits gestarteten Gerät** gedrückt, während du **Passwort zurücksetzen** auswählst. Halte die Taste bis zur Antwort; starte das Gerät dabei nicht neu. Die Wiederherstellungsseite ist fünf Minuten gültig. Öffne sie bei einer abgelaufenen Anfrage erneut.
4. Melde dich mit deinem **bisherigen Benutzernamen** und diesem einmal zufällig erzeugten, festgelegten Wiederherstellungspasswort an: **`X8T6W4BDABQMZCYH6V`**.
5. Ändere dieses veröffentlichte Standardpasswort anschließend unter **Einstellungen → Passwort ändern** in dein eigenes Passwort.

Nur das Administrator-Passwort wird ersetzt; bestehende Sitzungen werden beendet. Benutzername, WLAN-Passwort, Orion-MAC und -Schlüssel, Kanalnamen, NMEA-Zuweisungen und Zertifikat bleiben erhalten. Es wird kein Speicher gelöscht und kein Neustart ausgelöst. **BOOT allein setzt kein Passwort zurück.** Das Standardpasswort gilt nur nach diesem ausdrücklich bestätigten Vorgang, nicht als zusätzliches Anmeldepasswort. Falls die Wiederherstellungsfunktion nicht angezeigt wird, installiere die in der [Update-Anleitung](firmware-update.md) angegebene Firmware. Ist eine USB-Installation nötig, behalte den gespeicherten Gerätespeicher bei; lösche nicht den gesamten Flash-Speicher.

## 4. Orion einrichten

Öffne in VictronConnect die Produktinformationen deines Orions und aktiviere Instant Readout, falls es noch ausgeschaltet ist. Übernimm die Bluetooth-MAC-Adresse und den **32-stelligen hexadezimalen Instant-Readout-Schlüssel** in die Einrichtung der Bridge. Der Bluetooth-PIN gehört ausschließlich zu VictronConnect.

Die MAC-Adresse lässt sich ohne Doppelpunkte eingeben; die Bridge ergänzt die Trennzeichen automatisch. Bereits formatierte Adressen lassen sich ebenfalls einfügen. Die NMEA-Instanzen für Ausgang und Eingang müssen verschieden sein; die Vorgaben sind Ausgang `0` und Eingang `1`.

Ist bereits ein Orion-Schlüssel gespeichert, zeigt das Feld grüne Sterne und darunter **„Schlüssel vorhanden“**. Der echte Schlüssel wird nicht an den Browser übertragen. Lass das Feld leer, um den gespeicherten Schlüssel bei unveränderter MAC-Adresse beizubehalten. Zum Ersetzen gibst du alle 32 hexadezimalen Zeichen ein; bei einer anderen MAC-Adresse ist der Schlüssel des neuen Orion erforderlich. Die Sterne sind nur eine Anzeige und werden nicht als Schlüssel gespeichert.

Nach **Speichern und Neustarten** startet die Bridge neu; verbinde dich danach gegebenenfalls erneut mit ihrem WLAN und melde dich wieder an.

## 5. Empfang und Übertragung prüfen

Im **Monitor** findest du die Orion-Parameter, den Status der NMEA-Ausgabe und getrennte Zähler für beide Seiten. Nach zehn Sekunden ohne neues Orion-Paket gelten die Messwerte als veraltet; sie werden nicht als aktuelle Messung weitergeführt. Ein angenommener NMEA-Sendeauftrag allein bestätigt noch keinen Empfang am Garmin.

Die Anzeige nutzt drei Nachkommastellen für Messwerte. Das Bluetooth-Datenformat liefert Spannungen in Schritten von 0,01 V und Ströme in Schritten von 0,1 A. Die zusätzlichen Nullen sind Anzeigeformatierung; Wattwerte werden aus Spannung × Strom berechnet. Details stehen in der [technischen Bridge-Dokumentation](orion-xs-bridge.md#monitor-parameters-precision-and-counters).

## Wenn die Verbindung nicht klappt

| Problem | Nächster Schritt |
| --- | --- |
| WLAN nicht sichtbar | Bridge normal starten lassen, dann BOOT länger als zwei Sekunden halten; innerhalb von fünf Minuten verbinden. |
| WLAN-Passwort abgelehnt | Gespeichertes WLAN am Handy entfernen, individuelles Passwort wie oben über USB ablesen und erneut eingeben. |
| `batterysentinel.local` wird nicht gefunden | Direkt mit dem Bridge-WLAN verbinden und `https://192.168.4.1/` verwenden; Namensauflösung, privates DNS oder VPN können die lokale Auflösung verhindern. |
| Browser erreicht die Seite nicht | Prüfen, ob das Handy noch mit dem Bridge-WLAN verbunden ist; dann `https://192.168.4.1/` erneut öffnen. |
| Browser zeigt eine Zertifikatswarnung | Direkt mit dem erwarteten Bridge-WLAN verbinden und die lokale Browser-Ausnahme für die Bridge prüfen. Eine Zertifikatswarnung erfordert keinen Passwortreset. |
| Administrator-Passwort vergessen | „Passwort vergessen?“ öffnen, Rücksetzung bestätigen und beim Absenden BOOT halten. Mit bisherigem Benutzernamen und dem oben genannten Wiederherstellungspasswort anmelden, danach eigenes Passwort setzen. Daten und Zuweisungen bleiben erhalten. |

Zurück zum [Projektüberblick](../README.md).
