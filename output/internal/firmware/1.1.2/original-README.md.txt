# Orion Bridge 1.1.2 — SuperMini / Orion-R5

Install `orion-dongle-1.1.2.bin` through **Settings → Firmware update**.
Save it locally on the phone before connecting to the bridge Wi-Fi and keep
the device powered during installation. This is an application image for
SuperMini/R5, not Orion-R4 or the original battery monitor.

- Blue onboard LED on while the service Wi-Fi is open; off when it closes.
- Local address: **https://batterysentinel.local/** via mDNS.
- The existing **https://192.168.4.1/** address remains available.
- One-time certificate renewal covers both addresses; the browser may ask for
  its local certificate exception again. Passwords and Orion settings remain.
- Includes the faster login, saved-key indication and OTA improvements in 1.1.1.

This image was built, validated and installed via HTTPS OTA on the attached
SuperMini. See [test scope and local-address details](../../../docs/service-wifi-2026-09-25.md)
and [phone update instructions](../../../docs/firmware-update.md).

Size: 1,804,992 bytes. File SHA-256:

```text
1db128bc51b3b4618e80536fa53f0aa17adc7aeb643bdfc37645b8c0b04135cc
```
