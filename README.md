# BatterySentinel N2K — Orion Bridge

The Orion Bridge receives the charger's Bluetooth Instant Readout and forwards its input and output values to NMEA 2000. Its local HTTPS portal provides setup, live values, channel observations, configurable notifications, diagnostics, administrator password management and firmware updates. The current hardware uses an ESP32-C3 SuperMini with 4 MB flash on the Orion-R5 board.

![Battery Sentinel Orion Bridge logo](assets/battery-sentinel-orion-logo.svg)

## Start here

- [First connection — German, available before joining the bridge Wi-Fi](docs/erstverbindung.md).
- [German operating and installation manual](output/pdf/BatterySentinel-N2K-Orion-R5-Betriebs-und-Installationsanleitung-DE.pdf).
- [Official Orion Bridge 1.2.0](https://github.com/Weisni/BatterySentinel-N2K/releases/tag/v1.2.0), [latest official release](https://github.com/Weisni/BatterySentinel-N2K/releases/latest), [release channels](docs/release-channels.md) and [update instructions](docs/firmware-update.md).
- [Current hardware and assembly](hardware/altium-r5/README.md).
- [PCB hand-assembly data: BOM, placement, orientation and checklists](hardware/altium-r5/Project%20Outputs/Hand%20Assembly/README.md).
- [Illustrated enclosure assembly manual — English](output/pdf/Orion-R5-Enclosure-Assembly-Manual-EN.pdf).

Save the first-connection instructions and firmware file before connecting to the bridge. The device Wi-Fi provides local access without an internet connection.

## Local access and setup

For console-free owner setup, create a private device manual with the actual stored Wi-Fi credentials using [the local QR generator](docs/service-wifi-qr.md). Double-click `tools/create_service_wifi_manual.cmd` for local entry, or inject a private JSON file. The resulting manual includes a Wi-Fi connection QR and a separate portal QR. Private credentials and PDFs remain outside public releases.

Connect to `OrionBridge-XXXXXX` using the device's individual Wi-Fi password, then open **https://batterysentinel.local/**. Use **https://192.168.4.1/** if the name does not resolve. Stay connected when the phone reports that this network has no internet access.

The blue SuperMini LED lights only when the access point has started, its IP address is available and the HTTPS service is ready. It does not require a connected phone. Service Wi-Fi closes after five minutes without a connected client; hold BOOT for more than two seconds after normal startup to reopen it.

On first use, hold BOOT while creating the local administrator account. Enter the Orion Bluetooth MAC address and 32-character hexadecimal Instant Readout key from VictronConnect, then choose distinct NMEA instances for input and output. The Bluetooth PIN is used in VictronConnect. The portal defaults to German and also supports English.

To change the administrator password, open **Settings → Change password** and verify the current password. **Forgot password?** requires confirmation and physical BOOT access, then restores the fixed recovery password published in the manual. It preserves the username, Wi-Fi password, Orion connection, battery names and NMEA assignments. Existing sessions end; choose a personal password after recovery. Full instructions are in the [first-connection guide](docs/erstverbindung.md).

## Values and diagnostics

The portal shows input/output voltage and current, calculated power, charger state, errors, off reasons, packet age and signal strength. Its Monitor includes separate reception and NMEA-send counters, per-message fields and an event timeline. Channel names can be changed without restarting the bridge.

Bluetooth source resolution is 0.01 V and 0.1 A. Three-decimal formatting does not add measurement precision; power is calculated as voltage × current. After ten seconds without an accepted Orion record, electrical values become unavailable for NMEA publication. Orion currents describe the charger's channels; they do not provide a complete battery balance or state of charge. The bridge does not control the charger.

NMEA output uses PGN 127508 for electrical values, 127506 for source metadata and 127507 for eligible charger states. An accepted send request does not confirm that a Garmin received or displayed it. See the [parameter and diagnostics reference](docs/orion-xs-bridge.md#monitor-parameters-precision-and-counters).

**Insights** shows channel voltage extrema, a recent trend/history of up to 60 samples within five minutes, observed Orion Ah/Wh and their covered duration, plus observed time below the saved low-voltage threshold. Gaps over five seconds are excluded. Observations reset on reboot; these are charger-channel totals, not a complete battery balance.

**Alerts** provides separate input/output low/high limits, confirmation/clear periods, data-loss and charger-error rules, reminders and local acknowledgment. The master switch and experimental Garmin delivery are off by default. Active warnings remain visible across portal tabs; missing browser contact is shown as unknown status. UTC from validated NMEA time can backdate events from the same boot. No clock or observation history survives a reboot. See [observations, notifications and time](docs/diagnostics-logging.md) for defaults, limits and Garmin acceptance.

## Enclosure and printing

**Current enclosure revision - V2.3 thin walls:** [V2 for the confirmed 7 mm cable](hardware/altium-r5/enclosure/sealed-v2/README.md) implements the approved [seal revision concept](hardware/altium-r5/enclosure/seal-redesign/README.md): separate internal strain relief, a stiff three-screw pressure plate, raised bead seals and a 16 mm longer cable bay. Free wall fields are reduced to 3 mm with six projecting symmetric screw bosses; only seal rims and connector/insert pads retain local reinforcement. The bevels, shallow ribs and centred flush branding remain. It includes CAD/STL, a complete six-plate 3MF, coupons, an [assembly manual](output/pdf/Orion-Enclosure-V2-Assembly-EN.pdf) and a [manufacturing / TPU Air manual](output/pdf/Orion-Enclosure-V2-Manufacturing-EN.pdf). See the digital validation reports; physical calibration, retention and sealing remain open. The earlier 95A trial bent the cap and did not retain the cable; SainSmart TPU Air is ordered but not physically qualified.

The previous [Bambu P2S four-plate project](hardware/altium-r5/enclosure/sealed-print/Orion-R5-P2S-flush-colour.3mf), [printing and assembly guide](hardware/altium-r5/enclosure/sealed-print/README.md) and [plate/colour instructions](hardware/altium-r5/enclosure/sealed-print/flush-colour/README.md) are preserved as the earlier prototype, including the user's test plates and settings. Do not mix its seals with V2 parts. Both revisions retain contrasting PETG lettering and a logo flush with the lid surface.

The 52 × 36 mm board has independent retention. Screw-fastened service covers, continuous TPU face seals and an unsplit cable cartridge provide the service and sealing arrangement. Thread the cartridge onto the cable before soldering. Measure the delivered cable and verify the actual inserts, screws, USB plug and module fit before assembly. Complete cable-retention and wet tests with electronics removed. No verified IP rating is claimed.

[Optional P2S process presets](hardware/altium-r5/enclosure/sealed-print/awesome-ai-profiles/README.md) and the [filament colour shortlist](docs/enclosure-filament-colours.md) support print preparation. Physical colour, adhesion, fit and sealing remain acceptance checks.

## Progress and open tasks

Status updated on 2026-10-10:

- [x] Add [official and release-candidate channels](docs/release-channels.md), gated by the complete CI and verified draft assets. Pinned release dependencies match the validated local platform. Fixed Linux OLED format warnings without changing the display cadence or standard Wi-Fi settings.
- [x] Published the first official [v1.2.0 release](https://github.com/Weisni/BatterySentinel-N2K/releases/tag/v1.2.0) after exact-commit CI passed. All six public downloads, their SHA-256 digests, firmware identity and Latest status were independently verified; see [the publication record](docs/releases/1.2.0-verification.md).

- [x] First Orion-R5 assembled; USB, Wi-Fi and portal setup work, reported by the user on 2026-10-10. Boat-side power/CAN/thermal acceptance is still open.
- [x] German manual edition 1.5 adds QR handover, bench checks and fault consequences. A device-specific generator creates private access pages without firmware changes.
- [ ] Complete [the release-bound Orion-R5 bench and boat commissioning checklist](docs/orion-r5-commissioning.md). Several kiloohms measured on the unpowered standalone board do not establish safe network operation.
- [x] Close the [Wi-Fi heating investigation](docs/orion-r5-thermal-investigation.md) following the user's final assessment: Wi-Fi causes the observed heating and the chip takes considerable time to cool after shutdown. The reduced-power trial made no noticeable difference and was discarded. The user accepts the standard firmware's behavior; no BLE/CPU changes or further diagnostic firmware are planned for this concern. Measured closed-case temperatures and final boat acceptance remain separate open checks.
- [ ] Generate and scan the first device's private Wi-Fi code, verify receiver data and reconcile the current firmware LEN declaration with measured power demand.

- [x] All parts ordered and PCB manufacture commissioned, confirmed by the user on 2026-09-25.
- [x] Native Altium design completed by the user; the supplied DRC report records zero violations. This is the supplied result, not a newly executed DRC.
- [x] Successful Orion reception after entering MAC/key and a phone OTA update reported by the user.
- [x] Password change, BOOT-confirmed password recovery and status-based blue Wi-Fi LED implemented.
- [x] Implemented channel observations, validated network UTC and configurable local notifications for firmware 1.2.0; experimental Garmin alert delivery stays opt-in and requires plotter testing.
- [x] Portal/browser checks cover both languages, mobile/desktop layouts, observation gaps/coverage, settings persistence, incident acknowledgment, boot-aware event time and request coordination.
- [x] Public operating guides updated for firmware 1.2.0; German operating PDF includes the new functions. The enclosure manual is unchanged.
- [x] Firmware 1.2.0 built; 147 native cases, 175 extracted HTTP-handler checks with regression mutations, portal/preview/OTA and Edge browser checks passed. Independent Python and production C++ OTA validators accepted the final image.
- [x] Added the separate requested OLED debug build `orion_debug_oled` / `1.2.0-debug.1`, with a persistent connectivity bar and seven diagnostic pages advancing every 2 seconds. Full native suite now passes 165 cases; driver fault checks, exact-target OTA checks and firmware builds pass. See the [debug guide](docs/internal/oled-debug.md).
- [ ] Validate the delivered OLED's 72 x 40 profile, border/orientation, separately wired CAN TX4/RX7, live connectivity and simultaneous BLE/HTTPS/CAN operation on the debug board.
- [ ] Record first-board inspection, complete the enclosure and document its fit/retention checks; first PCB assembly is already reported complete.
- [x] Recorded failed 95A TPU seal/cable-cap trial and prepared a revision sketch for the confirmed 7 mm cable.
- [x] Implemented V2 enclosure geometry, nine cable sleeves, independent clamp, fit/hardness coupons and separate assembly/manufacturing instructions with engineering Shore A targets.
- [ ] Calibrate the actual TPU Air spool/nozzle; validate measured hardness, sealing, creep and independent strain relief on the printed V2 enclosure.
- [ ] Verify actual module/cable/fastener fit, power switching, temperature and empty-case sealing.
- [ ] Confirm repeated login with 1.2.0 on the reporting phone, including reload and return to the login address.
- [ ] Test password changes and recovery across power cycles, preservation of assignments, LED timing and supported phone/browser combinations on hardware.
- [ ] Complete BLE/Wi-Fi coexistence, raw NMEA traffic and Garmin acceptance on the assembled installation.
- [ ] Reconcile the configured NMEA load declaration with measured hardware consumption before release.
- [ ] Verify suitable voltage thresholds, actual power availability, covered Ah/Wh against recorded Orion samples, time-source changes, warning clearing/acknowledgment and experimental Garmin presentation on the installed hardware.

Official downloads include the application image, segmented USB package, manual, release notes, checksums and a manifest identifying the exact validated source commit. Application images must fit the 1,966,080-byte OTA slot. Publication does not install firmware on the device; ordering and successful software checks do not complete physical acceptance.

## Recorded procurement costs

Amounts reported by the user on 2026-09-25, with import duty added on 2026-09-30; payment is confirmed only where stated.

| Supplier / item | Recorded cost | Status |
| --- | ---: | --- |
| JLC | EUR 40.20 | Paid |
| LCSC | EUR 58.22 | Paid |
| Amazon: NMEA 2000 T-piece, 1 unit | EUR 18.14 | Ordered; payment not separately confirmed |
| Amazon: ESP32-C3 SuperMini, pack of 4 without OLED | EUR 18.99 | Ordered; payment not separately confirmed |
| Amazon: male-to-bare-wire NMEA 2000 drop cable, 1 m | EUR 16.26 | Ordered; payment not separately confirmed |
| Amazon: Habwea insert assortment and WZHUIDA M2 fastener assortment, combined order | EUR 20.98 | Ordered; payment not separately confirmed |
| PCB customs and DHL processing | EUR 23.85 | Paid, confirmed by the user on 2026-09-30; [invoice](hardware/altium-r5/procurement/2026-09-30-DHL-PCB-customs-invoice.pdf) archived |
| **Confirmed paid** | **EUR 122.27** | |
| **Amazon subtotal** | **EUR 74.37** | Payment not separately confirmed |
| **Total recorded costs** | **EUR 196.64** | |

The T-piece and combined assortment order are each counted once. The displayed module coupon is not deducted without a confirmed checkout amount. Verify delivered insert dimensions and screw lengths against the assembly guide. The M2 assortment does not establish availability of the required M3 × 8 screws.

## Development

The requested integrated-OLED ESP32-C3 debug board has its own [USB firmware package](output/firmware/debug-oled/1.2.0-debug.1/README.md) and [wiring/status guide](docs/internal/oled-debug.md). Build it with `pio run -e orion_debug_oled`. Its OLED occupies GPIO5/6, so CAN TX is GPIO4 and RX is GPIO7. It needs a separate wired test interface and is not a plug-in carrier replacement. The distinct firmware target prevents cross-board OTA updates. Display geometry and real hardware operation still need physical acceptance.

Build the current bridge and run its checks:

```bash
pio run -e orion_dongle
pio test -e native
node tools/verify_portal_ui.mjs
python tools/verify_portal_http.py
```

The [local portal preview](docs/web-preview.md) serves the firmware interface with synthetic Orion data:

```bash
node tools/preview_portal.mjs
```

Engineering history, source-production notes and internal investigations are indexed in the [project-internal documentation](docs/internal/README.md). Use the user guides above for installation and operation.
