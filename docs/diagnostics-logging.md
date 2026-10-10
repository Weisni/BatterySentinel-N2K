# Orion Bridge observations, notifications and time

Firmware **1.2.0** adds **Insights** and **Alerts** to the local portal. They use Orion input/output measurements while the bridge is powered. They do not measure all battery consumers, estimate battery state of charge, resistance, health or remaining runtime, or control charging.

## Read the observations

The two cards use your saved channel names. The input card describes the Orion input; the output card describes its output. A battery name does not change the measurement location.

| Display | Meaning |
| --- | --- |
| Minimum / maximum voltage | Lowest/highest valid channel voltage observed since this start |
| Voltage history | Up to 60 consecutive recent samples within a maximum five-minute window; the actual span depends on packet arrival |
| Voltage trend | Fitted change in V/min over the displayed span; available after at least three samples spanning ten seconds |
| Observed Orion charge / energy | Ah/Wh integrated from valid forward channel current and voltage over covered intervals |
| Voltage coverage / energy duration | Valid voltage observation coverage and the duration actually included in Ah/Wh |
| Observed time below the low limit | Covered time with voltage below the saved low threshold shown on the card; resets when that threshold changes |

A gap longer than **five seconds**, missing voltage or an invalid record breaks continuity. Recent history/trend starts a new continuous segment; the bridge does not draw or integrate through an unknown interval. Already observed totals and extrema remain. Uncharacterized reverse current is excluded from forward Ah/Wh. Zero Ah with zero covered time is not proof that no energy flowed.

Observations, active incidents and recent events are held in RAM and start again after reboot. They are not a persistent voyage log or evidence of conditions while power was off. Changing the configured Orion also resets its observations. Notification settings remain saved.

Rising voltage during charging and falling voltage after charging describe a trend, not battery condition. Voltage warnings remain active during charging and relaxation. Ordinary live telemetry/NMEA publication has its separate **ten-second** stale timeout; the shorter five-second limit protects calculations.

## Set notifications

Open **Alerts** (German: **Meldungen**), review both named connections, set appropriate limits and choose **Save notifications**. Notifications are **globally disabled by default**. Rules run only with the master enabled and an Orion configured.

| Setting | Default | Allowed range / behavior |
| --- | --- | --- |
| Enable notifications | Off | Master switch |
| Low voltage, each channel | On; warn below 12.00 V | Configurable threshold |
| Clear low voltage | At or above 12.30 V | Above the low warning threshold |
| High voltage, each channel | Off; warn above 15.00 V | Configurable threshold |
| Clear high voltage | At or below 14.70 V | Below high warning, above low clear |
| Confirm voltage warning / clear | 10 s / 30 s | Each 1-600 s; shared by that channel's low/high rules |
| Missing Orion data | On; 30 s | 10-3600 s since last valid record, or from configuration if none arrived |
| Orion charger error | On | Fixed 10 s to warn / 30 s to clear; unknown error is not clear |
| Repeat unacknowledged warnings | 0 min | 0 disables reminders; otherwise 1-1440 min |
| Request Garmin notifications | Off | Experimental; requires testing on the installed plotter |

All four voltage settings must be within **4-65 V**, with low warning < low clear < high clear < high warning. This accepted input range is not a recommendation for a particular battery. Voltage and charger-error confirmation/clearing need at least three distinct valid records over the required duration. Missing-data activation instead uses the absence timeout; clearing requires fresh valid records again. Missing data interrupts confirmation and never silently clears an existing voltage/error warning; its condition becomes unknown.

Select **Acknowledge** to stop that incident's local reminders. The active card and a banner on every portal tab remain until the condition clears. Acknowledgment does not change thresholds or remove the cause. A new incident requires a new acknowledgment. Disabling a rule cancels its incident. During a connection failure the banner says that warning status is unavailable; it does not imply all-clear.

Unsaved settings survive polling and language changes. A rejected save keeps the previous stored settings. A review notice means the stored notification configuration needs checking and saving.

## Garmin delivery

The optional sender emits NMEA alert/status and text (PGNs 126983 and 126985). Delivery is **experimental and unverified on the installed chartplotter**. An accepted local send request does not prove receipt, display, sound or clearing. Plotter acknowledgment is not supported; acknowledge in this portal.

Garmin documents GPSMAP 7x3 reception of these alert messages. That establishes directions, not compatibility with every custom alert. Its documented **Unit Voltage** alarm does not establish separate alarms for arbitrary received battery instances. [Garmin PGN table](https://www8.garmin.com/manuals/webhelp/GUID-BF2FF273-008A-482A-A96F-362ADA8996BA/EN-US/GUID-0C4B3FAB-3E41-438C-B31E-9B5489790913.html), [System Alarms](https://www8.garmin.com/manuals/webhelp/GUID-3E67C80C-0812-4EEC-BC60-699751B9CF6F/EN-US/GUID-353F7FD4-424B-4993-8124-A3CB450297BE.html).

The Alerts page warns when the bounded record of 24 retired alert identities is full and a new remote occurrence or reassignment must wait. This is not a general delivery queue or a receipt confirmation. Check the local active cards and the chartplotter. Disabling delivery still permits withdrawal traffic for earlier remote warnings. A deliberate restart attempts withdrawal up to three times, with a maximum five-second wait. Receiver clearing remains unconfirmed; abrupt power loss cannot deliver a final withdrawal, and pending withdrawal history is not saved across restart. The portal does not provide a persistent report of failed shutdown withdrawals.

Validate activation, repeats, local acknowledgment, clearing, disconnection and restart on the actual Garmin/software before relying on its presentation. Evaluation continues with the browser closed while the bridge is powered. There are no phone push, email or internet notifications.

## Network UTC and the event timeline

Calculations and confirmation periods always use monotonic device time. Calendar time is optional and is not required for a warning.

The bridge listens for UTC in **129029 GNSS position data** and **126992 System time** and requests them while acquiring time. Garmin lists 129029 as transmit/receive for the GPSMAP 723xsv family, but 126992 as receive-only; do not assume the plotter sends 126992. Another source may provide it. [Garmin PGN directions](https://www8.garmin.com/manuals/webhelp/GUID-BF2FF273-008A-482A-A96F-362ADA8996BA/EN-US/GUID-0C4B3FAB-3E41-438C-B31E-9B5489790913.html).

The clock needs three consistent advancing observations from an identified source spanning at least one second. Date/time and GNSS quality are validated. Identity/consistency checks are not cryptographic authentication. No internet clock or timezone setting is needed; displayed calendar time is **UTC**.

| Clock state | Interpretation |
| --- | --- |
| Unknown / acquiring | No established calendar time; events show uptime |
| Synchronized | A validated recent network clock is available |
| Holdover | No accepted update for over 30 s; estimated time continues from the last trusted anchor |
| Conflict / quarantined | An inconsistent jump was rejected; the previous trusted correlation is retained |

An accepted clock lets earlier events from **the same boot** receive estimated calendar times. They are labeled as backdated. Browser caches and event cursors reset when the boot identity changes. Clock and shutdown time are not persisted; elapsed power-off time remains unknown.

The Monitor holds a bounded recent event list: warnings activated/cleared/acknowledged/cancelled, reminders and clock-state changes. Record details before reboot. Remove passwords and Orion readout keys from screenshots and support messages.
