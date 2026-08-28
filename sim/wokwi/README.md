# BatterySentinel N2K – Wokwi

This Wokwi project runs the real ESP32-C3 firmware against a simulated INA238 system-battery sensor.

## Start in VS Code

1. Install PlatformIO and the Wokwi extension.
2. Build the firmware from the repository root:
   `pio run -e esp32c3`
3. Open `diagram.json`.
4. Start **Wokwi: Start Simulator**.

The precompiled INA238 custom-chip WASM is tracked in `sim/wokwi/chips/ina238.chip.wasm`. It is rebuilt automatically by `.github/workflows/wokwi-chip.yml` whenever its source changes. The same workflow runs `wokwi-cli lint` against `diagram.json`.

## Simulated hardware

- ESP32-C3 DevKitM-1, 8 MB flash
- INA238 at I2C address `0x40`
- SDA GPIO4 / SCL GPIO5
- ignition switch on GPIO21 (LOW = off, HIGH = on)
- status/alarm LED GPIO10
- logic analyzer on SDA / SCL / IGN
- USB Serial/JTAG terminal

Select the INA238 custom chip in the Wokwi diagram to change:

- `busVoltage`: 8…16 V
- `currentA`: -400…+100 A (positive = charging, negative = discharge)
- `sensorPresent`: 1 = present, 0 = simulated sensor fault

Useful scenarios:

- idle battery: 12.7 V / 0 A
- engine crank: approximately 9.5–11 V / -150…-225 A for a short pulse
- alternator charging: approximately 14.2–14.7 V / positive current
- sensor fault: set `sensorPresent` to 0
- low-voltage alarm: reduce `busVoltage` while applying discharge current
- ignition input: toggle the slide switch between 0 V and 3.3 V

## Current firmware gap

`PIN_IGN_SENSE` is defined as GPIO21 and the Wokwi circuit now drives this signal, but the current production `main.cpp` does not yet read or act on it. Therefore the switch can currently be observed with the logic analyzer but does not yet trigger power-off / wake / off-time behavior in firmware. That behavior should be implemented and acceptance-tested separately rather than being faked in the simulator.

## Scope / limitation

Wokwi currently only partially simulates ESP32-C3 TWAI. This project therefore validates firmware execution, INA238/I2C behavior, state handling, diagnostics/Wi-Fi startup and GPIO behavior. Final NMEA2000 electrical/bus acceptance still requires a real CAN transceiver and NMEA2000 network/test fixture.
