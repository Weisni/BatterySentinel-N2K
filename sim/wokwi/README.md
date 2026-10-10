> **Project-internal engineering record.** Historical designs, unbuilt concepts and test targets in this file are development material, not existing or released product variants. Use the current operating and assembly guides for the Orion Bridge. [Internal index](../../docs/internal/README.md).

# BatterySentinel N2K – Wokwi

This Wokwi setup selects the internal `esp32c3` measurement firmware and a
simulated INA238 system-battery sensor. It does not select the released Orion
Bridge firmware. The circuit/custom chip are implemented; complete automated
firmware scenario execution is not established.

## Start in VS Code

1. Install PlatformIO and the Wokwi extension.
2. Build the firmware from the repository root:
   `pio run -e esp32c3`
3. Open `diagram.json`.
4. Start **Wokwi: Start Simulator**.

The precompiled INA238 custom-chip WASM is tracked in `sim/wokwi/chips/ina238.chip.wasm`. `.github/workflows/wokwi-chip.yml` compiles changed chip sources and runs circuit lint. Its [last recorded successful run](https://github.com/Weisni/BatterySentinel-N2K/actions/runs/33204456947) is from 2026-08-28; this is chip/circuit evidence, not an automated full-firmware scenario run.

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

The setup can support exploration of INA238 transactions, scheduling and GPIO,
but currently has no scripted firmware acceptance scenarios, FRAM/NOR models
or SPI/TWAI analyzer wiring. [Issue #8](https://github.com/Weisni/BatterySentinel-N2K/issues/8)
tracks that optional internal backlog; #6 is consolidated into it.

[Wokwi's support matrix](https://docs.wokwi.com/guides/esp32#simulation-features)
lists ESP32-C3 TWAI as partial and Bluetooth as unsupported. An Orion harness
would need synthetic inputs; it cannot establish actual BLE reception or
coexistence. Final NMEA2000 electrical/bus acceptance still requires the real
transceiver and network/test fixture. See [the current issue status](../../docs/internal/backlog-status-2026-10-10.md).
