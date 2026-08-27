#pragma once

#include <cstdint>

namespace bs::config {

// ESP32-C3-WROOM-02 pin map. GPIO18/19 are reserved for native USB Serial/JTAG.
inline constexpr int PIN_I2C_SDA = 4;
inline constexpr int PIN_I2C_SCL = 5;
inline constexpr int PIN_CAN_TX  = 6;
inline constexpr int PIN_CAN_RX  = 7;
inline constexpr int PIN_STATUS_LED = 10;

inline constexpr uint8_t INA238_SYSTEM_ADDRESS = 0x40;
inline constexpr uint8_t INA238_BOW_ADDRESS    = 0x41;

// Positive current means battery charging, negative current means discharge.
// Shunts are high-side and sensed as IN+ = load/charger side, IN- = battery side.
inline constexpr double SYSTEM_SHUNT_OHM = 0.000100;      // provisional 500 A / 50 mV
inline constexpr double BOW_SHUNT_OHM    = 0.0001666667;  // 300 A / 50 mV

inline constexpr double SYSTEM_CAPACITY_AH = 70.0;
inline constexpr double BOW_CAPACITY_AH    = 90.0;

// Main loop / communication periods.
inline constexpr uint32_t SAMPLE_PERIOD_MS = 100;
inline constexpr uint32_t N2K_FAST_PERIOD_MS = 1500;
inline constexpr uint32_t N2K_DC_PERIOD_MS = 5000;
inline constexpr uint32_t SOC_PERSIST_PERIOD_MS = 60000;

// Default alert limits. Hardware-specific tuning belongs in commissioning.
inline constexpr double SYSTEM_MAX_ABS_CURRENT_A = 450.0;
inline constexpr double BOW_MAX_ABS_CURRENT_A = 250.0;

}  // namespace bs::config
