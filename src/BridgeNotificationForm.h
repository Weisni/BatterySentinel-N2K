#pragma once

#include <BridgeInsights.h>
#include <cstddef>
#include <cstdint>

namespace bs::insights {

// Strict decimal parsing, independent of Arduino and browser validation.
// Reject signs, exponents, whitespace, overflow and partially parsed values.
inline bool parseUnsigned(const char* value, size_t length, uint32_t maximum, uint32_t& out) {
    if (!value || length == 0 || length > 10) return false;
    uint32_t parsed = 0;
    for (size_t i = 0; i < length; ++i) {
        if (value[i] < '0' || value[i] > '9') return false;
        const uint32_t digit = static_cast<uint32_t>(value[i] - '0');
        if (digit > maximum || parsed > (maximum - digit) / 10) return false;
        parsed = parsed * 10 + digit;
    }
    out = parsed;
    return true;
}

inline bool parseVoltage(const char* value, size_t length, uint16_t& out) {
    if (!value || length == 0 || length > 5) return false;
    size_t decimal = length;
    for (size_t i = 0; i < length; ++i) if (value[i] == '.') {
        if (decimal != length) return false;
        decimal = i;
    }
    uint32_t volts = 0, fraction = 0;
    if (!parseUnsigned(value, decimal, 65, volts)) return false;
    if (decimal < length) {
        const size_t digits = length - decimal - 1;
        if (digits == 0 || digits > 2 ||
            !parseUnsigned(value + decimal + 1, digits, 99, fraction)) return false;
        if (digits == 1) fraction *= 10;
    }
    const uint32_t cv = volts * 100 + fraction;
    if (cv < 400 || cv > 6500) return false;
    out = static_cast<uint16_t>(cv);
    return true;
}

} // namespace bs::insights
