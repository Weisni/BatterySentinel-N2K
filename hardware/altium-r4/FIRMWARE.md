# Firmware für Orion Bridge R4

Das PlatformIO-Profil **`orion_r4`** ist für den ESP32-C3-WROOM-02-N4 der R4-Platine bestimmt. Es verwendet 4 MB Flash mit den bestehenden OTA-Partitionen, natives USB Serial/JTAG sowie CAN-TX GPIO6 und CAN-RX GPIO7. Der Firmware-Einstieg und die Weboberfläche entsprechen dem vorhandenen Orion-Dongle. Als NMEA-Modellrevision wird `R4` gemeldet; der vorläufige Leistungsbedarf ist **LEN 12 (600 mA)**.

Das bisherige Standardprofil `orion_dongle` bleibt unverändert ausgewählt. Für R4 deshalb ausdrücklich `-e orion_r4` angeben.

## Bauen und übertragen

Im Projektverzeichnis:

```powershell
pio run -e orion_r4
pio run -e orion_r4 -t upload
pio device monitor -e orion_r4
```

Wenn PlatformIO nicht im Suchpfad liegt, kann auf diesem Rechner stattdessen `C:\Users\marce\.platformio\penv\Scripts\platformio.exe` verwendet werden. Bei mehreren seriellen Geräten den gewünschten Port mit `--upload-port COMx` beziehungsweise beim Monitor mit `--port COMx` ergänzen.

Für die erste Programmierung eines leeren Moduls ein USB-Datenkabel anschließen. Falls der automatische Download nicht startet: **BOOT gedrückt halten, RESET kurz drücken, danach BOOT loslassen** und den Upload starten. Nach erfolgreichem Upload bei Bedarf RESET drücken. Die Spannungsversorgung über USB genügt zum Programmieren und zum Testen von Weboberfläche/Bluetooth. Für CAN-Kommunikation muss zusätzlich die NMEA-Busseite versorgt sein.

Nach dem normalen Start öffnet langes Drücken von BOOT die Serviceoberfläche wie beim bisherigen Dongle. BOOT beim Zurücksetzen gedrückt zu halten hat eine andere Funktion: Es wählt den ROM-Downloadmodus.

## Startbedingungen der Schaltung

- EN erhält 10 kΩ nach 3,3 V und 1 µF nach Logikmasse; RESET zieht EN nach Masse.
- GPIO2 und GPIO8 bleiben beim Reset durch externe Pull-ups hoch. GPIO9 besitzt einen Pull-up und wird nur durch BOOT nach Masse gezogen.
- Natives USB verwendet GPIO18/19; diese Leitungen dürfen nicht für CAN verwendet werden.
- TXD am ISO1042 besitzt einen eigenen Pull-up. Der CAN-Ausgang bleibt dadurch während MCU-Reset im rezessiven Zustand.
- D2/D4 entkoppeln isolierte Busversorgung und USB automatisch. Ein RUN/USB-Jumper ist bei R4 nicht erforderlich.

Die Pull-ups und RC-Beschaltung wirken bereits vor dem Start der Firmware. Sie dürfen deshalb nicht durch einen Software-Pull-up ersetzt werden.

## Nachweis

`pio run -e orion_r4` wurde am 23.09.2026 erfolgreich mit PlatformIO Espressif32 6.11.0 / Arduino-ESP32 2.0.17 kompiliert. RAM-Belegung: **66.884 von 327.680 Byte**. Programmspeicher: **1.699.674 von 1.966.080 Byte**. Das App-Image liegt unter `.pio/build/orion_r4/firmware.bin`, Bootloader und Partitionstabelle im selben Buildverzeichnis. Das App-Image allein ist kein vollständiges Erstprogrammierungs-Image; der PlatformIO-Upload schreibt die erforderlichen Bestandteile an die richtigen Adressen.

Prüfprotokoll: [firmware-build-validation.json](firmware-build-validation.json). Es wurde kein Gerät beschrieben und kein Hardware-Funktionstest durchgeführt. JLCPCB liefert ohne zusätzlich vereinbarte Programmierung leere Module; der PCBA-Auftrag allein enthält keine Firmware-Installation.
