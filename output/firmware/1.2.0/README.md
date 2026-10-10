# Orion Bridge 1.2.0

Application firmware for the Orion Bridge with ESP32-C3 SuperMini on the Orion-R5 board: [Download orion-dongle-1.2.0.bin](orion-dongle-1.2.0.bin).

Save this file on your phone, then install it through **Settings → Firmware update** while keeping device power stable. The portal target must be `orion-dongle`. Follow the [update instructions](../../../docs/firmware-update.md).

- File size: 1,902,064 bytes.
- OTA application slot: 1,966,080 bytes; 64,016 bytes remain.
- File checksum: [SHA256SUMS.txt](SHA256SUMS.txt).
- SHA-256 of the complete downloadable file: `8f14e3480ce6b0f8768657601d1f04fda5600d0f1214d4cf547e867e3599e979`.

## Included functions

- Per-channel voltage minimum/maximum, recent trend, covered Orion charge/energy and observed time below the selected low limit.
- Configurable low/high voltage, missing-data and charger-error notifications, with a visible portal warning, local acknowledgement, recovery thresholds, qualification periods and optional reminders.
- Network UTC acquisition and validation, with calendar timestamps back-calculated for earlier log entries from the same boot. Uptime remains available when network time is missing.
- Optional experimental NMEA alert output. Receiver display, sound and withdrawal must be verified on the actual chartplotter; a successful send is not a delivery confirmation. Acknowledgement is through the portal.

Notifications and experimental NMEA delivery initially default off. Review channel thresholds and enable the desired rules under **Alerts** (German: **Meldungen**). The low-voltage starting values are 12.00 V trigger and 12.30 V recovery. Voltage warnings remain eligible while charging and during post-charge voltage relaxation.

Existing credentials, Wi-Fi settings, Orion identity and NMEA assignments are retained. Notification settings are stored separately; an update does not require resetting the device. Observations, incidents, recent log entries and clock correlation start again after reboot. Ah/Wh represent covered Orion-channel transfer; no complete battery SOC, remaining-runtime or service-life estimate is claimed.

## Validation

Firmware builds, 165 native cases, 175 production-handler HTTP checks, bilingual mobile/desktop browser checks and independent application-image validation passed. The complete binary fits both existing OTA slots. The two injected original login defects are still rejected by regression tests.

This package has not been installed on the device during this task. Hardware acceptance remains necessary for radio/TLS operation, received time, battery-side voltage interpretation, continuous power after ignition-off, and Garmin warning behavior. See [operation and limitations](../../../docs/diagnostics-logging.md) and the [German operating manual](../../pdf/BatterySentinel-N2K-Orion-R5-Betriebs-und-Installationsanleitung-DE.pdf).

Current project snapshot rebuilt and checked on 2026-10-10. Standard Wi-Fi settings are retained. This supersedes the earlier local download artifact; no device was flashed.
