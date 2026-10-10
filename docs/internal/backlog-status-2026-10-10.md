# Issue status for Orion Bridge 1.2.0

Status reconciled on 2026-10-10 against `main` commit
`eb4830973f6db3f3d83e7ce97f7ae991551369c0` and the
[official 1.2.0 release](https://github.com/Weisni/BatterySentinel-N2K/releases/tag/v1.2.0).
The released source is `b01e69173c046cca40553fc73405ac5defc018ee`.
This update records current behavior and outstanding work; it changes no firmware,
hardware, simulation code, build configuration or published release assets.

The August issues describe the unbuilt shunt-based measurement concept. The
current product is the 4 MB ESP32-C3 SuperMini Orion Bridge. It receives charger
channels over BLE and forwards them to NMEA 2000; those measurements cannot
establish whole-battery SOC or conditions while the bridge is unpowered.

## Issue dispositions

| Issue | Disposition | Current meaning |
| --- | --- | --- |
| [#1](https://github.com/Weisni/BatterySentinel-N2K/issues/1) | Open; high priority | Portal/Wi-Fi/validated OTA are implemented. Track application-health confirmation after OTA separately from image checks. |
| [#2](https://github.com/Weisni/BatterySentinel-N2K/issues/2) | Closed as not planned for this hardware | The external 32 MB logger belongs to the unbuilt concept. Record codec/CRC tests are not a working persistent logger. |
| [#3](https://github.com/Weisni/BatterySentinel-N2K/issues/3) | Closed as not planned for this hardware | FRAM, ignition sensing and supercap hold-up are not fitted to Orion-R5. Driver/state-format work remains internal and unintegrated. |
| [#4](https://github.com/Weisni/BatterySentinel-N2K/issues/4) | Open; medium priority | UTC and notifications are implemented. Retain physical Garmin/time/withdrawal acceptance; remote acknowledgment remains deliberately unsupported. |
| [#6](https://github.com/Weisni/BatterySentinel-N2K/issues/6) | Closed as duplicate of #8 | One issue tracks the remaining internal Wokwi work. Existing diagram/chip/CI setup is not pending creation. |
| [#7](https://github.com/Weisni/BatterySentinel-N2K/issues/7) | Open; optional medium-priority proposal | A browser harness using the actual Orion observation/time/alert cores remains proposed. No production-core WASM binding exists. |
| [#8](https://github.com/Weisni/BatterySentinel-N2K/issues/8) | Open; low-priority internal backlog | Legacy Wokwi setup exists; automated firmware scenarios remain absent. This is not end-to-end Orion/BLE/CAN validation. |

Closing superseded work does not mark it implemented. Original issue requirements
remain preserved below the current status in each issue. Simulation proposals
are backlog items, not authorization to implement or change the current product.

## Implemented and remaining behavior

### Service Wi-Fi and OTA

`BridgePortal` starts the service access point and HTTPS portal. `BridgeSettings`
generates and stores an individual random Wi-Fi password. A connected station
keeps service open; it stops after five minutes without a station, including
after the last station disconnects. The August request's separate 60-second
disconnect grace is not the current bridge behavior. BOOT reopens service Wi-Fi.

OTA writes the inactive application slot and validates target, structure, size,
checksum and digest before selecting it. This is implemented and described in
[the update guide](../firmware-update.md).

The pinned Arduino 2.0.17 core enables rollback support but defaults
`verifyOta()` to true and `verifyRollbackLater()` to false. It confirms a pending
image in `initArduino()` before the project's `setup()`. The project overrides
neither hook and has no subsequent application-specific health gate. A valid
image that fails during or after application initialization is therefore not
covered by an application-health rollback policy. Remaining work in #1 is to
define and test that policy, including successful confirmation, failed startup,
reset/power interruption and preservation of saved settings.

Sources: [Arduino 2.0.17 initialization](https://github.com/espressif/arduino-esp32/blob/2.0.17/cores/esp32/esp32-hal-misc.c)
and [Espressif OTA rollback](https://docs.espressif.com/projects/esp-idf/en/v4.4.7/esp32c3/api-reference/system/ota.html#app-rollback).
Published file-integrity validation is distinct from this remaining behavior.

### UTC, notifications and receiver acceptance

`NmeaPublisher` receives 129029/126992 and `BridgeTime` validates and maintains
UTC/monotonic correlation within a boot. `BridgeInsights` implements bounded
channel observations and qualified local incidents. Optional delivery emits
126983/126985; it defaults off and remains experimental.

Incoming 126984 responses are explicitly ignored. An 8-bit occurrence alone
cannot distinguish a delayed response from a new incident after cold boot.
Remote acknowledgment would require a separately designed identity/replay policy
and receiver tests; the issue does not promise support. Local acknowledgment
is implemented. UTC, observations and incidents do not persist across reboot.
No FRAM off-time or whole-battery SOC estimation is implemented for the bridge.

The remaining #4 acceptance covers the actual receiver's time transmission,
alert presentation, clearing/withdrawal, local acknowledgment, late startup,
bus loss, restart and abrupt power loss. See [current operating limits](../diagnostics-logging.md)
and [the commissioning checklist](../orion-r5-commissioning.md).

### Internal logging and simulation

`LogCore` encodes fixed records with CRC; it has no integrated NOR ring writer,
sector recovery, persistent retention, pre/post-trigger capture or CSV export.
`FramStateStore` provides alternating CRC/sequence slots, but no application
instantiates it. The legacy `main.cpp` still uses NVS SOC persistence and does
not act on ignition loss. None of this is compiled into the current bridge target.

Root `wokwi.toml` and `diagram.json` point to the internal `esp32c3` target.
The INA238 chip model/WASM, LED, ignition switch and SDA/SCL/IGN analyzer wiring
are present. The chip compile/lint workflow [last succeeded on 2026-08-28](https://github.com/Weisni/BatterySentinel-N2K/actions/runs/33204456947).
That historical success is not a current automated firmware-scenario test.
FRAM/NOR models and scripted execution are still absent, and ignition switching
does not yet drive firmware shutdown. SPI/TWAI analyzer wiring is not present.

`sim/web` and `sim/browser` retain independent JavaScript battery models;
the native CMake simulator executes `BatteryCore`. None is a production-core
WebAssembly simulator for Orion. The actual Orion portal preview and existing
native/HTTP/browser checks remain the available current-product harnesses.

Wokwi documents Bluetooth as unsupported and TWAI as partially implemented.
An Orion harness would need synthetic inputs or adapters and could not prove
actual BLE reception, coexistence or electrical CAN operation.
[Wokwi support matrix](https://docs.wokwi.com/guides/esp32#simulation-features).
Detailed scope is in [the simulation guide](../simulation.md).

## Remaining priorities

1. Application-specific OTA health confirmation and recovery (#1).
2. Physical receiver/time/alert acceptance (#4), plus the existing power, LEN,
   isolation and enclosure commissioning tasks.
3. Optional Orion production-core browser harness (#7).
4. Internal legacy Wokwi automation (#8), only if that target remains useful.

Normal Wi-Fi/BLE/CPU behavior and the accepted heating decision remain unchanged.
Version 1.2.0 remains the official release; this documentation creates no new
firmware version and completes no physical acceptance test.
