# BatterySentinel simulation environments

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

The next simulator milestone compiles the production `BatteryCore` and `BatteryProfiles` C++ sources to WebAssembly. At that point the browser UI and firmware/native TDD will all execute the same battery-domain implementation. Until then, native TDD remains authoritative for algorithm acceptance and the browser Lab is used for interactive system/scenario exploration.

## 2. Wokwi (`sim/wokwi`)

Hardware-oriented simulator target for the real ESP32-C3 firmware.

A custom INA238 model is included under `sim/wokwi/chips/`. It exposes live controls for:
- bus voltage;
- battery current (+charge / -discharge);
- sensor-present / sensor-fault state.

The model implements the INA238 registers used by firmware (`CONFIG`, `VSHUNT`, `VBUS`) and responds at I2C address `0x40`.

Wokwi supports ESP32-C3, I2C/SPI/Wi-Fi and custom WebAssembly chips. TWAI/CAN is only partially simulated, so Wokwi is used for firmware/peripheral validation rather than final NMEA electrical acceptance.

## Online hosting

`sim/web` is intentionally a pure static site (HTML/CSS/JS), so it can be published with GitHub Pages without a server.

Do not enable Pages automatically without deciding visibility: a Pages site may be publicly reachable even when the source repository is private, depending on the GitHub plan/account type. The simulator itself contains no secrets, but publication should be an explicit project decision.
