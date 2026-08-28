#pragma once

#include <cstdint>

namespace bs::config {

// ESP32-C3-WROOM-02 pin map. GPIO18/19 are reserved for native USB Serial/JTAG.
inline constexpr int PIN_I2C_SDA = 4;
inline constexpr int PIN_I2C_SCL = 5;
inline constexpr int PIN_CAN_TX  = 6;
inline constexpr int PIN_CAN_RX  = 7;
inline constexpr int PIN_STATUS_LED = 10;

// External 32 MB SPI NOR logger. Avoid ESP32-C3 strapping pins GPIO2/8/9.
inline constexpr int PIN_LOG_SCK  = 0;
inline constexpr int PIN_LOG_MOSI = 1;
inline constexpr int PIN_LOG_MISO = 3;
inline constexpr int PIN_LOG_CS   = 20;

// Ignition-presence / power-loss input. The PCB converts 12 V IGN to 3.3 V logic.
inline constexpr int PIN_IGN_SENSE = 21;

inline constexpr uint8_t INA238_SYSTEM_ADDRESS = 0x40;
inline constexpr uint8_t INA238_BOW_ADDRESS    = 0x41;

// Positive current means battery charging, negative current means discharge.
// Both V1 channels use the same high-side 500 A / 50 mV shunt (100 uOhm).
// Sense orientation: IN+ = load/charger side, IN- = battery side.
inline constexpr double SYSTEM_SHUNT_OHM = 0.000100;
inline constexpr double BOW_SHUNT_OHM    = 0.000100;

inline constexpr double SYSTEM_CAPACITY_AH = 70.0;
inline constexpr double BOW_CAPACITY_AH    = 90.0;

// Main loop / communication periods. 50 Hz capture resolves starter and bow-thruster events.
inline constexpr uint32_t SAMPLE_PERIOD_MS = 20;
inline constexpr uint32_t N2K_FAST_PERIOD_MS = 1500;
inline constexpr uint32_t N2K_DC_PERIOD_MS = 5000;

// State is checkpointed to FRAM much more often than flash/NVS. NVS remains fallback storage.
inline constexpr uint32_t SOC_PERSIST_PERIOD_MS = 60000;
inline constexpr uint32_t FRAM_CHECKPOINT_PERIOD_MS = 1000;

// Diagnostics Wi-Fi AP starts automatically on every boot. If nobody connects during this
// window the radio is shut down. If a client connects, keep diagnostics alive while it is
// connected and shut down after the disconnect grace period.
inline constexpr uint32_t DIAG_BOOT_WINDOW_MS = 5UL * 60UL * 1000UL;
inline constexpr uint32_t DIAG_DISCONNECT_GRACE_MS = 60UL * 1000UL;

// Logging: 1 Hz long-term record plus 50 Hz event capture using the same raw sample stream.
inline constexpr uint32_t LOG_NORMAL_PERIOD_MS = 1000;
inline constexpr uint32_t EVENT_PRETRIGGER_MS = 10000;
inline constexpr uint32_t EVENT_POSTTRIGGER_MS = 30000;

// Default software alert limits. All values are configurable through the local web UI.
// System starter is expected around 150-225 A; 350 A gives transient headroom while still
// detecting an abnormal sustained starter current. Bow thruster max operating current ~200 A.
inline constexpr double SYSTEM_MAX_ABS_CURRENT_A = 350.0;
inline constexpr double BOW_MAX_ABS_CURRENT_A = 250.0;

}  // namespace bs::config
