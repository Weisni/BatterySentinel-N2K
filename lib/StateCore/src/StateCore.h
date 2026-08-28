#pragma once

#include <cstddef>
#include <cstdint>
#include <cstring>

namespace bs::state {

enum class SocConfidence : uint8_t {
    Unknown = 0,
    Estimated,
    WaitingForRest,
    Synced
};

enum StateFlags : uint32_t {
    FlagUtcValid        = 1u << 0,
    FlagSocValid        = 1u << 1,
    FlagCleanShutdown   = 1u << 2,
    FlagExternalChargeSuspected = 1u << 3,
};

#pragma pack(push, 1)
struct PersistentState {
    uint32_t magic = 0x42535354u;       // "BSST"
    uint16_t formatVersion = 1;
    uint16_t recordSize = sizeof(PersistentState);
    uint32_t sequence = 0;
    uint32_t flags = 0;

    uint32_t utcSeconds = 0;
    uint32_t uptimeMs = 0;

    int32_t systemSocMilliPct = 0;      // 0..100000 = 0..100.000 %
    int32_t systemConsumedMilliAh = 0;
    uint32_t logWriteRecord = 0;

    uint16_t configSchema = 0;
    uint8_t confidence = static_cast<uint8_t>(SocConfidence::Unknown);
    uint8_t reserved0 = 0;

    // Reserved for future channel/state evolution without changing the FRAM slot size.
    uint8_t reserved[20] = {};

    uint32_t crc32 = 0;
};
#pragma pack(pop)

static_assert(sizeof(PersistentState) == 64, "PersistentState must remain a fixed 64-byte FRAM slot");

inline uint32_t crc32(const uint8_t* data, std::size_t size) {
    uint32_t crc = 0xFFFFFFFFu;
    for (std::size_t i = 0; i < size; ++i) {
        crc ^= data[i];
        for (uint8_t bit = 0; bit < 8; ++bit) {
            const uint32_t mask = 0u - (crc & 1u);
            crc = (crc >> 1) ^ (0xEDB88320u & mask);
        }
    }
    return ~crc;
}

inline int32_t socToMilliPct(double socPct) {
    if (!(socPct > 0.0)) return 0;
    if (socPct >= 100.0) return 100000;
    return static_cast<int32_t>(socPct * 1000.0 + 0.5);
}

inline double milliPctToSoc(int32_t value) {
    if (value <= 0) return 0.0;
    if (value >= 100000) return 100.0;
    return static_cast<double>(value) / 1000.0;
}

inline void seal(PersistentState& state) {
    state.magic = 0x42535354u;
    state.formatVersion = 1;
    state.recordSize = sizeof(PersistentState);
    state.crc32 = 0;
    state.crc32 = crc32(reinterpret_cast<const uint8_t*>(&state), sizeof(PersistentState) - sizeof(state.crc32));
}

inline bool valid(const PersistentState& state) {
    if (state.magic != 0x42535354u ||
        state.formatVersion != 1 ||
        state.recordSize != sizeof(PersistentState)) {
        return false;
    }
    return state.crc32 == crc32(reinterpret_cast<const uint8_t*>(&state),
                                sizeof(PersistentState) - sizeof(state.crc32));
}

// Sequence comparison remains correct across uint32 wrap as long as two valid records are
// never more than 2^31 checkpoints apart, which is trivially true for the two-slot store.
inline bool sequenceNewer(uint32_t candidate, uint32_t reference) {
    return static_cast<int32_t>(candidate - reference) > 0;
}

inline PersistentState makeSystemState(uint32_t sequence,
                                       double socPct,
                                       double consumedAh,
                                       SocConfidence confidence,
                                       uint32_t flags,
                                       uint32_t utcSeconds,
                                       uint32_t uptimeMs,
                                       uint32_t logWriteRecord,
                                       uint16_t configSchema) {
    PersistentState s;
    s.sequence = sequence;
    s.flags = flags;
    s.utcSeconds = utcSeconds;
    s.uptimeMs = uptimeMs;
    s.systemSocMilliPct = socToMilliPct(socPct);
    const double milliAh = consumedAh * 1000.0;
    if (milliAh >= static_cast<double>(INT32_MAX)) s.systemConsumedMilliAh = INT32_MAX;
    else if (milliAh <= static_cast<double>(INT32_MIN)) s.systemConsumedMilliAh = INT32_MIN;
    else s.systemConsumedMilliAh = static_cast<int32_t>(milliAh >= 0.0 ? milliAh + 0.5 : milliAh - 0.5);
    s.logWriteRecord = logWriteRecord;
    s.configSchema = configSchema;
    s.confidence = static_cast<uint8_t>(confidence);
    seal(s);
    return s;
}

} // namespace bs::state
