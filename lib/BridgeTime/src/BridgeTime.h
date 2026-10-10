#pragma once

#include <cmath>
#include <cstdint>

namespace bs { namespace time {

enum class Quality : uint8_t { Unknown, Acquiring, Synchronized, Holdover, Quarantined };
inline const char* qualityName(Quality q) {
    switch (q) {
    case Quality::Acquiring: return "acquiring";
    case Quality::Synchronized: return "synchronized";
    case Quality::Holdover: return "holdover";
    case Quality::Quarantined: return "quarantined";
    default: return "unknown";
    }
}

struct Snapshot {
    Quality quality = Quality::Unknown;
    bool valid = false;
    uint64_t utcMs = 0, anchorUtcMs = 0, anchorMonotonicMs = 0, monotonicMs = 0;
    uint64_t sourceName = 0, ageMs = 0;
    uint32_t sourcePgn = 0, rejected = 0;
    uint8_t sourceAddress = 255;
    // The caller must associate this snapshot and event with the same boot.
    // Holdover/quarantine retains the last trusted correlation, never a jump.
    bool utcFor(uint64_t eventMs, uint64_t& result) const {
        if (!valid || eventMs > monotonicMs) return false;
        if (eventMs >= anchorMonotonicMs) {
            result = anchorUtcMs + eventMs - anchorMonotonicMs;
        } else {
            const uint64_t delta = anchorMonotonicMs - eventMs;
            if (delta > anchorUtcMs) return false;
            result = anchorUtcMs - delta;
        }
        return true;
    }
};

inline bool decodeUtc(uint16_t days, double seconds, uint64_t& result) {
    // Reject unavailable/error encodings, impossible times and implausible epochs.
    // Leap-second 86400 is not representable by this Unix-millisecond clock.
    if (days < 18262 || days >= 47847 || !std::isfinite(seconds) ||
        seconds < 0 || seconds >= 86400) return false; // 2020..2100
    result = uint64_t(days) * 86400000ULL + uint64_t(seconds * 1000.0);
    return true;
}

class Clock {
public:
    static constexpr uint64_t kFreshMs = 30000;
    void reject() { ++state_.rejected; }
    bool observe(uint64_t utcMs, uint64_t now, uint64_t name, uint8_t address,
                 uint32_t pgn) {
        if (!name || name == UINT64_MAX || address >= 254 ||
            (pgn != 129029 && pgn != 126992) || utcMs < 1577836800000ULL ||
            utcMs >= 4133980800000ULL || now < state_.anchorMonotonicMs) {
            reject(); return false;
        }
        if (state_.valid) {
            const uint64_t expected = state_.anchorUtcMs + now - state_.anchorMonotonicMs;
            const uint64_t error = utcMs > expected ? utcMs - expected : expected - utcMs;
            // At most five seconds even after a long outage. A real calendar
            // correction needs a fresh boot instead of silently rewriting history.
            const uint64_t age = now - lastValid_;
            const uint64_t tolerance = 1500 + (age / 1000 < 3500 ? age / 1000 : 3500);
            if (error > tolerance) {
                reject();
                if (name == state_.sourceName) quarantined_ = true;
                candidateCount_ = 0;
                return false;
            }
            if (name == state_.sourceName && !quarantined_ && age <= kFreshMs) {
                if (now <= lastValid_ || utcMs <= lastUtc_) { reject(); return false; }
                accept(utcMs, now, name, address, pgn); return true;
            }
            // Keep an established, fresh source; do not mix competing clocks.
            if (name != state_.sourceName && age <= kFreshMs) return false;
        }
        if (candidateName_ != name || !candidateCount_ ||
            now < candidateLastMs_ || now - candidateLastMs_ > 10000) {
            startCandidate(utcMs, now, name, pgn); return false;
        }
        if (now - candidateLastMs_ < 250) return false;
        const uint64_t expected = candidateUtc_ + now - candidateLastMs_;
        const uint64_t error = utcMs > expected ? utcMs - expected : expected - utcMs;
        const uint64_t firstExpected = candidateFirstUtc_ + now - candidateFirstMs_;
        const uint64_t totalError = utcMs > firstExpected ? utcMs - firstExpected : firstExpected - utcMs;
        if (utcMs <= candidateUtc_ || error > 1500 || totalError > 1500) {
            reject(); startCandidate(utcMs, now, name, pgn); return false;
        }
        candidateLastMs_ = now; candidateUtc_ = utcMs; ++candidateCount_;
        if (candidateCount_ < 3 || now - candidateFirstMs_ < 1000) return false;
        accept(utcMs, now, name, address, pgn); return true;
    }
    Snapshot snapshot(uint64_t now) const {
        Snapshot result = state_;
        result.monotonicMs = now;
        if (result.valid) {
            result.ageMs = now >= lastValid_ ? now - lastValid_ : 0;
            result.utcMs = result.anchorUtcMs + now - result.anchorMonotonicMs;
            result.quality = quarantined_ ? Quality::Quarantined :
                result.ageMs > kFreshMs ? Quality::Holdover : Quality::Synchronized;
        } else result.quality = candidateCount_ ? Quality::Acquiring : Quality::Unknown;
        return result;
    }
private:
    void startCandidate(uint64_t utc, uint64_t now, uint64_t name, uint32_t pgn) {
        (void)pgn;
        candidateName_ = name; candidateUtc_ = candidateFirstUtc_ = utc;
        candidateFirstMs_ = candidateLastMs_ = now; candidateCount_ = 1;
    }
    void accept(uint64_t utc, uint64_t now, uint64_t name, uint8_t address, uint32_t pgn) {
        state_.valid = true; state_.anchorUtcMs = utc; state_.anchorMonotonicMs = now;
        state_.sourceName = name; state_.sourceAddress = address; state_.sourcePgn = pgn;
        lastValid_ = now; lastUtc_ = utc; quarantined_ = false; candidateCount_ = 0;
    }
    Snapshot state_{};
    uint64_t lastValid_ = 0, lastUtc_ = 0, candidateName_ = 0, candidateUtc_ = 0;
    uint64_t candidateFirstMs_ = 0, candidateLastMs_ = 0, candidateFirstUtc_ = 0;
    uint8_t candidateCount_ = 0;
    bool quarantined_ = false;
};

}} // namespace bs::time
