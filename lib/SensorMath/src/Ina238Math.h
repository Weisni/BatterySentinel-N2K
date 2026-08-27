#pragma once

#include <cstdint>

namespace bs::ina238math {

inline constexpr double shuntLsbV(bool narrowRange) {
    return narrowRange ? 1.25e-6 : 5.0e-6;
}

inline constexpr double busLsbV() {
    return 3.125e-3;
}

inline double shuntVoltageV(int16_t raw, bool narrowRange) {
    return static_cast<double>(raw) * shuntLsbV(narrowRange);
}

inline double busVoltageV(uint16_t raw) {
    return static_cast<double>(raw) * busLsbV();
}

inline double currentA(int16_t rawShunt, double shuntOhm, bool narrowRange) {
    return shuntOhm > 0.0 ? shuntVoltageV(rawShunt, narrowRange) / shuntOhm : 0.0;
}

} // namespace bs::ina238math
