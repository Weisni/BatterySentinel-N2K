#pragma once

#include <cstddef>
#include <cstdint>

namespace bs::log {

enum RecordFlags : uint8_t {
    FlagUtcValid        = 1u << 0,
    FlagSystemValid     = 1u << 1,
    FlagSystemSocValid  = 1u << 2,
    FlagSecondEnabled   = 1u << 3,
    FlagSecondValid     = 1u << 4,
    FlagSecondSocValid  = 1u << 5,
    FlagEvent           = 1u << 6,
    FlagCleanShutdown   = 1u << 7,
};

struct SampleInput {
    uint32_t utcSeconds = 0;
    bool utcValid = false;
    uint32_t uptimeMs = 0;

    double systemVoltageV = 0.0;
    double systemCurrentA = 0.0;
    double systemSocPct = 0.0;
    uint32_t systemAlerts = 0;
    bool systemValid = false;
    bool systemSocValid = false;

    double secondVoltageV = 0.0;
    double secondCurrentA = 0.0;
    double secondSocPct = 0.0;
    bool secondEnabled = false;
    bool secondValid = false;
    bool secondSocValid = false;

    bool event = false;
    bool cleanShutdown = false;
};

#pragma pack(push, 1)
struct LogRecord {
    uint16_t magic;               // 0x4253 = "BS"
    uint16_t sequence;
    uint32_t utcSeconds;
    uint32_t uptimeMs;
    uint16_t systemMv;
    int32_t systemMa;
    uint16_t systemSocPermille;   // 0..1000
    uint16_t systemAlerts;
    uint16_t secondMv;
    int32_t secondMa;
    uint16_t secondSocPermille;   // 0..1000
    uint8_t flags;
    uint8_t crc8;
};
#pragma pack(pop)

static_assert(sizeof(LogRecord) == 32, "LogRecord must stay 32 bytes");

inline uint8_t crc8(const uint8_t* data, std::size_t size) {
    uint8_t crc = 0xFF;
    for (std::size_t i = 0; i < size; ++i) {
        crc ^= data[i];
        for (uint8_t bit = 0; bit < 8; ++bit) {
            crc = (crc & 0x80u) ? static_cast<uint8_t>((crc << 1) ^ 0x31u)
                                : static_cast<uint8_t>(crc << 1);
        }
    }
    return crc;
}

inline uint16_t clampMilliVolts(double voltageV) {
    if (!(voltageV > 0.0)) return 0;
    const double mv = voltageV * 1000.0;
    if (mv >= 65535.0) return 65535;
    return static_cast<uint16_t>(mv + 0.5);
}

inline int32_t clampMilliAmps(double currentA) {
    const double ma = currentA * 1000.0;
    if (ma >= 2147483647.0) return INT32_MAX;
    if (ma <= -2147483648.0) return INT32_MIN;
    return static_cast<int32_t>(ma >= 0.0 ? ma + 0.5 : ma - 0.5);
}

inline uint16_t clampSocPermille(double socPct) {
    if (!(socPct > 0.0)) return 0;
    if (socPct >= 100.0) return 1000;
    return static_cast<uint16_t>(socPct * 10.0 + 0.5);
}

inline LogRecord encode(uint16_t sequence, const SampleInput& in) {
    LogRecord r{};
    r.magic = 0x4253;
    r.sequence = sequence;
    r.utcSeconds = in.utcSeconds;
    r.uptimeMs = in.uptimeMs;
    r.systemMv = clampMilliVolts(in.systemVoltageV);
    r.systemMa = clampMilliAmps(in.systemCurrentA);
    r.systemSocPermille = clampSocPermille(in.systemSocPct);
    r.systemAlerts = static_cast<uint16_t>(in.systemAlerts & 0xFFFFu);
    r.secondMv = clampMilliVolts(in.secondVoltageV);
    r.secondMa = clampMilliAmps(in.secondCurrentA);
    r.secondSocPermille = clampSocPermille(in.secondSocPct);

    if (in.utcValid) r.flags |= FlagUtcValid;
    if (in.systemValid) r.flags |= FlagSystemValid;
    if (in.systemSocValid) r.flags |= FlagSystemSocValid;
    if (in.secondEnabled) r.flags |= FlagSecondEnabled;
    if (in.secondValid) r.flags |= FlagSecondValid;
    if (in.secondSocValid) r.flags |= FlagSecondSocValid;
    if (in.event) r.flags |= FlagEvent;
    if (in.cleanShutdown) r.flags |= FlagCleanShutdown;

    r.crc8 = crc8(reinterpret_cast<const uint8_t*>(&r), sizeof(LogRecord) - 1);
    return r;
}

inline bool valid(const LogRecord& r) {
    return r.magic == 0x4253 &&
           r.crc8 == crc8(reinterpret_cast<const uint8_t*>(&r), sizeof(LogRecord) - 1);
}

inline constexpr uint32_t bytesPerDay(uint32_t intervalMs = 1000) {
    return intervalMs == 0 ? 0 : static_cast<uint32_t>((86400000ULL / intervalMs) * sizeof(LogRecord));
}

} // namespace bs::log
