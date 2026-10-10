# Orion-R5 Wi-Fi heating: final user assessment

Status: closed by user decision on 2026-10-10; standard firmware retained.

## Final finding and decision

The user revised the earlier observations: Wi-Fi causes the observed ESP32-chip heating, and the chip takes considerable time to cool after service Wi-Fi shuts down. Warmth felt several minutes after shutdown was therefore not evidence that Wi-Fi remained active or that another task caused the reported symptom.

The user reports that the 2-dBm trial made no noticeable difference and explicitly requested that it be discarded. The experimental firmware, source package, patch and dedicated verification tool are removed from the current project. The standard firmware's existing Wi-Fi settings, BLE reception, CPU behavior and service timeout remain unchanged. The user accepts the observed behavior; no further radio-free diagnostic firmware or thermal mitigation is planned for this concern.

This final assessment supersedes the earlier unresolved-fault interpretation, the claim that the trial had not been installed, and the proposed Bluetooth/runtime investigation. It records the user's practical observations and acceptance, not an independently measured temperature or cooling curve.

## Recorded observations

- The assembled board starts from 12 V with external CAN and USB disconnected and SW3 in RUN.
- At the module, the user measured 5V = 4.94 V and 3V3 = 3.292 V.
- The supply display was poorly resolved and appeared to show less than 60 mA; this is not a peak-current measurement.
- The ESP32 chip also becomes hot with the SuperMini standalone on USB.
- No calibrated temperature was supplied. Touch observations do not establish a component operating-limit violation or thermal equilibrium.

## Source context and remaining commissioning

The inspected normal portal shutdown calls `WiFi.softAPdisconnect(true)` and `WiFi.mode(WIFI_OFF)`. Configured BLE scanning and bridge tasks continue after the service portal closes. Those source facts do not override the user's corrected thermal observation and are not evidence of a defect.

Closed-case temperature, startup/load captures, input power budget, CAN signaling, isolation and final boat-network acceptance remain separate checks in the [commissioning checklist](orion-r5-commissioning.md). No boat acceptance or calibrated thermal qualification is claimed by closing this investigation.
