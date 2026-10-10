> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](../docs/internal/README.md).

# BatterySentinel simulation environments

## Orion Bridge portal preview

To open and debug the actual Orion portal without a device, run `node tools/preview_portal.mjs` from the repository root and open [http://127.0.0.1:8765/](http://127.0.0.1:8765/). The preview serves the firmware's own web UI with simulated telemetry, forms and selectable error scenarios. It is separate from the battery-model simulator below and does not emulate ESP32, BLE, CAN or HTTPS behavior. See the [German web preview guide](../docs/web-preview.md) for page selection, browser debugging and custom ports.

## 1. BatterySentinel Lab (`sim/web`)

Immediate interactive browser MVP. No hardware is required.

Open `sim/web/index.html` directly in a browser, or serve the directory with any static HTTP server.

Current controls/scenarios include:
- battery voltage and bidirectional current;
- ignition on/off;
- INA238 present/fault;
- configurable chemistry/capacity;
- time acceleration;
- Mercury starter pulse at 225 A;
- sustained discharge / charge;
- under-/overvoltage;
- power-off + 24 h time jump;
- virtual NMEA TX for 127508 and 127506;
- virtual RX of 129029 time and 126984 alert acknowledgement;
- SOC/alarm/internal-state panels and timeline.

### Important implementation status

The current browser MVP mirrors the BatteryCore behavior in JavaScript so it is immediately usable. It is a UI/system harness, not yet the authoritative algorithm implementation.

No production-core WebAssembly binding is implemented. `BatteryCore` and
`BatteryProfiles` belong to the internal measurement concept, not the released
Orion Bridge. Issue [#7](https://github.com/Weisni/BatterySentinel-N2K/issues/7)
now tracks an optional browser harness for the actual Orion observation/time/alert
cores. Native TDD remains authoritative for the tested C++ logic; the existing
Lab remains an internal JavaScript scenario model.

## 2. Wokwi (`sim/wokwi`)

Hardware-oriented setup for the internal `esp32c3` measurement firmware. Root
`wokwi.toml` and `diagram.json` already select that 8 MB target; they do not run
the released `orion_dongle` application.

A custom INA238 model is included under `sim/wokwi/chips/`. It exposes live controls for:
- bus voltage;
- battery current (+charge / -discharge);
- sensor-present / sensor-fault state.

The model implements the INA238 registers used by firmware (`CONFIG`, `VSHUNT`, `VBUS`) and responds at I2C address `0x40`.

The chip WASM and compile/lint workflow exist, as do the LED, ignition switch and
SDA/SCL/IGN analyzer. Automated firmware scenarios, FRAM/NOR models and ignition
shutdown integration remain absent; [#8](https://github.com/Weisni/BatterySentinel-N2K/issues/8)
consolidates this internal work from #6. Simulated FRAM/logger/shutdown indicators
in the browser Lab are not a demonstration of working device drivers.

[Wokwi](https://docs.wokwi.com/guides/esp32#simulation-features) supports ESP32-C3
but does not simulate Bluetooth; TWAI/CAN is partial. Current Orion BLE reception,
coexistence and electrical NMEA acceptance require hardware. See the
[dated issue status](../docs/internal/backlog-status-2026-10-10.md).

## Online hosting

`sim/web` is a project-internal static site (HTML/CSS/JS). Open it locally for engineering checks; its workflow runs syntax checks without publishing it.

Do not enable Pages automatically without deciding visibility: a Pages site may be publicly reachable even when the source repository is private, depending on the GitHub plan/account type. The simulator itself contains no secrets, but publication should be an explicit project decision.
