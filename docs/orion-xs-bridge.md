# Orion Bridge operation and telemetry

The Orion Bridge receives encrypted Bluetooth Instant Readout advertisements from the configured Orion and publishes its input/output values on NMEA 2000. Setup and monitoring use the local HTTPS portal. Start with the [first-connection guide](erstverbindung.md) and the [German operating and installation manual](../output/pdf/BatterySentinel-N2K-Orion-R5-Betriebs-und-Installationsanleitung-DE.pdf).

## Configure the Orion

Obtain the Bluetooth MAC address and 32-character hexadecimal Instant Readout key from the charger's product information in VictronConnect. Enable Instant Readout there if needed. The Bluetooth PIN belongs in VictronConnect; it is not the encryption key used by the bridge.

The portal inserts MAC separators while typing and accepts formatted addresses. If a key is already stored, stars indicate its presence without returning the key to the browser. Leave the key field empty to retain it when the MAC address is unchanged. A different MAC address requires the full key for that Orion.

Input and output NMEA instances must be distinct integers from 0 to 252; defaults are output 0 and input 1. Saving connection settings restarts the bridge. Channel names have a separate save action and need no restart or key re-entry. Their defaults are `Startbatterie` for input and `Bugbatterie` for output. Names label the portal; NMEA assignments remain controlled by the instance fields.

## Monitor parameters, precision and counters

The Monitor shows the fields received through the implemented Orion Instant Readout record and the NMEA messages prepared by the bridge:

- Input/output voltage and current, locally calculated input/output power, device state, charger error code and off-reason bitmask.
- Packet counter, signal strength (RSSI), data age and availability, retaining their native integer/code meanings.
- NMEA input/output instances, per-message status and transmitted fields. Unknown source fields remain unavailable.
- Separate Orion reception and NMEA sending diagnostics, plus a bounded event timeline. Credentials and raw encrypted advertisements are not exposed.

Measurements use three decimal places, including derived watts. **Formatting does not increase source resolution or measurement accuracy.** The implemented Bluetooth record carries voltages at 0.01 V and currents at 0.1 A. For example, `13.420 V` represents a 0.01 V source step and `4.500 A` a 0.1 A source step. Power is calculated as voltage × current; it is not a separate Bluetooth power measurement.

The Orion error total concerns reception and decoding. Rejected records, dropped queued records and receiver startup failures belong to that side; the current charger error code is a separate parameter. Repeated packets with the same counter are counted as duplicates without inflating the error total.

NMEA diagnostics count accepted and failed stack send requests separately. Acceptance is not a CAN acknowledgement or confirmation that Garmin received or displayed a value. Counters cover the current boot and reset when the bridge restarts. After ten seconds without an accepted Orion record, electrical values become stale and the NMEA voltage/current fields become unavailable.

Orion channel currents do not provide a complete battery balance. The bridge has no source measurement for battery state of charge, temperature, capacity or remaining runtime. Unavailable fields stay unavailable. The bridge does not control the charger. Configurable local notifications and opt-in experimental NMEA alert delivery are separate from measurement forwarding.

## Observations, notifications and time

Firmware 1.2.0 adds **Insights** and **Alerts** (German: **Auswertung** and **Meldungen**). Insights shows voltage extrema since boot, a recent history/trend with up to 60 samples within five minutes, observed forward Orion Ah/Wh and covered duration, and covered time below each saved low-voltage threshold. Gaps longer than five seconds are not integrated or bridged. The history starts a new continuous segment after a gap; already observed totals remain until restart. These are channel observations, not state of charge or battery health.

Notifications are globally off by default. Each channel defaults to a low warning below 12.00 V, clearing at or above 12.30 V, with 10 s confirmation and 30 s clearing. High-voltage rules are off by default (15.00 V warning / 14.70 V clearing). Missing-data and charger-error rules are enabled under the master switch; reminders default to off. An active-warning banner stays visible on every tab. Acknowledge in the portal to stop reminders for that incident; the warning remains until its cause clears. A browser disconnection reports unavailable warning status rather than all-clear.

UTC can come from validated NMEA 129029 or 126992 after three consistent anchors. Calculation intervals always use monotonic uptime. Earlier events in the current boot receive marked estimated calendar timestamps when time becomes available. After a network-time outage, the clock continues in holdover; a conflicting jump is rejected. A reboot resets the clock, event history and observations, while saved notification settings remain.

Garmin delivery is off by default, experimental, and requires verification on the actual plotter. The portal warns when retained withdrawal records are full; neither accepted transmission nor clearing locally proves remote display/clearing. Restart withdrawal attempts are bounded and cannot guarantee removal of an earlier plotter warning. Remote acknowledgment is not supported. Read the [complete defaults, limits and time behavior](diagnostics-logging.md).

## NMEA messages

| PGN | Contents | Publication |
| --- | --- | --- |
| 127508 | Output and input voltage/current, with separate instances | Every second when configured; stale values become unavailable |
| 127506 | Output as Battery and input as Converter, with available metadata | Every five seconds when configured |
| 127507 | Known Bulk, Absorption or Float charger state | When the current state is eligible |
| 126983 / 126985 | Experimental notification state / text | When delivery is enabled; withdrawal traffic can continue after disabling it |

The bridge also receives network UTC in 129029/126992. Garmin documents 129029 as transmit/receive for GPSMAP 7x3, but 126992 as receive-only. Time from that plotter should therefore be expected through 129029, not assumed from 126992. [Official Garmin PGN directions](https://www8.garmin.com/manuals/webhelp/GUID-BF2FF273-008A-482A-A96F-362ADA8996BA/EN-US/GUID-0C4B3FAB-3E41-438C-B31E-9B5489790913.html).

The Monitor shows the last attempt and age for each message. An earlier failed attempt for an optional charger-state message does not keep overall status red when that message is no longer eligible. Individual message cards retain their last result for diagnosis. Display compatibility and the values actually received must be checked on the installed NMEA network and Garmin.

## Local access and accounts

Join `OrionBridge-XXXXXX` with the bridge's individual Wi-Fi password and open **https://batterysentinel.local/**, or **https://192.168.4.1/** if name resolution fails. All portal assets are on the device. The portal defaults to German and supports English.

The blue SuperMini LED lights when the access point has started, its IP address is available and HTTPS is ready. A connected phone is not required for the indicator. Service Wi-Fi closes after five minutes without clients; hold BOOT for more than two seconds after normal startup to reopen it. On the assembled bridge, select SERVICE before connecting USB and disconnect USB before selecting RUN.

First administrator enrollment and password recovery require BOOT held during form submission. Password changes verify the current password. Recovery restores only the administrator password to the fixed recovery value in the manual; the username, Wi-Fi password, Orion identity/key, channel names and NMEA assignments remain saved. Both password operations end existing sessions. Follow the [complete account and recovery instructions](erstverbindung.md).

The portal uses a device-generated HTTPS certificate. Verify that the phone is connected directly to the expected bridge before accepting its local certificate warning. Firmware updates use a file saved on the phone and are described in the [update guide](firmware-update.md).

## Validation and remaining acceptance

The user reported successful Orion reception after entering the MAC/key, identifying the tested charger as Orion XC1400, and later reported a successful phone OTA update. Firmware 1.2.0 adds automated observation/time/notification checks and browser validation; the final build/package results are recorded in the [project progress](../README.md#progress-and-open-tasks).

Physical acceptance still requires recorded comparison with VictronConnect, BLE/Wi-Fi coexistence and closed-case reception checks, raw NMEA traffic and instance verification, and Garmin display testing on the assembled hardware. Include observation coverage, network UTC, warning timing, acknowledgment, clearing, reconnect and restart. These checks are distinct from software validation and the reported reception result.
