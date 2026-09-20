#pragma once

#include <cstddef>
#include <cstdint>

namespace bs::orion {

struct Value {
    double number = 0.0;
    bool valid = false;
};

struct Telemetry {
    Value outputVoltage;
    Value outputCurrent;
    Value inputVoltage;
    Value inputCurrent;
    uint8_t state = 0xff;
    uint8_t error = 0xff;
    uint32_t offReason = 0;
    uint16_t counter = 0;
    uint32_t receivedAtMs = 0;
    int rssi = 0;
    bool received = false;

    bool fresh(uint32_t now, uint32_t maxAgeMs = 10000) const {
        return received && static_cast<uint32_t>(now - receivedAtMs) <= maxAgeMs;
    }
};

inline uint16_t little16(const uint8_t* bytes) {
    return static_cast<uint16_t>(bytes[0] | (static_cast<uint16_t>(bytes[1]) << 8));
}

inline uint32_t little32(const uint8_t* bytes) {
    return static_cast<uint32_t>(bytes[0]) |
           (static_cast<uint32_t>(bytes[1]) << 8) |
           (static_cast<uint32_t>(bytes[2]) << 16) |
           (static_cast<uint32_t>(bytes[3]) << 24);
}

// Decrypted Orion XS record 0x0f. Its layout has been published for the XS
// 12/12-50A; operation with an XS 1400 must be checked against real frames.
inline bool decodeXsRecord(const uint8_t* bytes, size_t length, Telemetry& out) {
    if (!bytes || length < 14) return false;
    out.state = bytes[0];
    out.error = bytes[1];

    const uint16_t outV = little16(bytes + 2);
    const uint16_t outI = little16(bytes + 4);
    const uint16_t inV = little16(bytes + 6);
    const uint16_t inI = little16(bytes + 8);
    out.outputVoltage = {static_cast<int16_t>(outV) * 0.01, outV != 0x7fff};
    out.outputCurrent = {static_cast<int16_t>(outI) * 0.1, outI != 0x7fff};
    out.inputVoltage = {inV * 0.01, inV != 0xffff};
    out.inputCurrent = {inI * 0.1, inI != 0xffff};
    out.offReason = little32(bytes + 10);
    return true;
}

} // namespace bs::orion
