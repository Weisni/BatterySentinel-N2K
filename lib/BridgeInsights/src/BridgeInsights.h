#pragma once

#include <OrionFrame.h>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace bs::insights {

constexpr size_t kChannelCount = 2;
constexpr size_t kAlertCount = 6;
constexpr size_t kConfigBlobSize = 44;
constexpr size_t kHistoryCapacity = 60;
constexpr size_t kTransitionCapacity = 24;
constexpr uint64_t kMaxSampleGapMs = 5000;
constexpr uint64_t kHistoryWindowMs = 300000;
constexpr uint8_t kSettingsSlot = 255;

// Channel 0 is the Orion input; channel 1 is its output. These are charger
// observations, not complete battery current or an estimate of battery SOC.
struct ChannelConfig {
    bool lowEnabled = true;
    bool highEnabled = false;
    uint16_t lowCv = 1200;
    uint16_t lowClearCv = 1230;
    uint16_t highCv = 1500;
    uint16_t highClearCv = 1470;
    uint16_t delayS = 10;
    uint16_t clearS = 30;
};

struct Config {
    bool enabled = false;
    bool nmeaEnabled = false;
    bool dataLossEnabled = true;
    bool chargerErrorEnabled = true;
    uint16_t dataLossDelayS = 30;
    uint16_t repeatMinutes = 0;
    ChannelConfig channels[kChannelCount];
};

inline bool sameChannelConfig(const ChannelConfig& a, const ChannelConfig& b) {
    return a.lowEnabled == b.lowEnabled && a.highEnabled == b.highEnabled &&
           a.lowCv == b.lowCv && a.lowClearCv == b.lowClearCv &&
           a.highCv == b.highCv && a.highClearCv == b.highClearCv &&
           a.delayS == b.delayS && a.clearS == b.clearS;
}

inline bool sameConfig(const Config& a, const Config& b) {
    return a.enabled == b.enabled && a.nmeaEnabled == b.nmeaEnabled &&
           a.dataLossEnabled == b.dataLossEnabled &&
           a.chargerErrorEnabled == b.chargerErrorEnabled &&
           a.dataLossDelayS == b.dataLossDelayS && a.repeatMinutes == b.repeatMinutes &&
           sameChannelConfig(a.channels[0], b.channels[0]) &&
           sameChannelConfig(a.channels[1], b.channels[1]);
}

inline bool validConfig(const Config& c) {
    if (c.dataLossDelayS < 10 || c.dataLossDelayS > 3600 || c.repeatMinutes > 1440)
        return false;
    for (const auto& v : c.channels) {
        if (v.lowCv < 400 || v.highCv > 6500 || v.lowCv >= v.lowClearCv ||
            v.lowClearCv >= v.highClearCv || v.highClearCv >= v.highCv ||
            v.delayS < 1 || v.delayS > 600 || v.clearS < 1 || v.clearS > 600)
            return false;
    }
    return true;
}

namespace detail {
inline void put16(uint8_t* b, uint16_t v) { b[0] = uint8_t(v); b[1] = uint8_t(v >> 8); }
inline uint16_t get16(const uint8_t* b) { return uint16_t(b[0] | uint16_t(b[1]) << 8); }
inline uint32_t crc32(const uint8_t* bytes, size_t length) {
    uint32_t crc = 0xffffffffU;
    for (size_t i = 0; i < length; ++i) {
        crc ^= bytes[i];
        for (unsigned bit = 0; bit < 8; ++bit)
            crc = (crc >> 1) ^ (0xedb88320U & (0U - (crc & 1U)));
    }
    return ~crc;
}
inline bool validVoltage(const orion::Value& v) {
    return v.valid && std::isfinite(v.number) && v.number >= 0 && v.number <= 65;
}
inline bool validForwardCurrent(const orion::Value& v) {
    return v.valid && std::isfinite(v.number) && v.number >= 0 && v.number <= 150;
}
} // namespace detail

// Explicit wire format, independent of compiler padding: BSI/version, flags,
// reserved zeros, timers, two channel records, CRC32. Store as one NVS entry.
inline bool encodeConfig(const Config& c, uint8_t* bytes, size_t length) {
    if (!bytes || length != kConfigBlobSize || !validConfig(c)) return false;
    for (size_t i = 0; i < length; ++i) bytes[i] = 0;
    bytes[0] = 'B'; bytes[1] = 'S'; bytes[2] = 'I'; bytes[3] = 1;
    bytes[4] = uint8_t(c.enabled | (c.nmeaEnabled << 1) |
                       (c.dataLossEnabled << 2) | (c.chargerErrorEnabled << 3));
    detail::put16(bytes + 6, c.dataLossDelayS);
    detail::put16(bytes + 8, c.repeatMinutes);
    for (size_t i = 0; i < kChannelCount; ++i) {
        const auto& v = c.channels[i];
        uint8_t* b = bytes + 12 + 14 * i;
        b[0] = uint8_t(v.lowEnabled | (v.highEnabled << 1));
        detail::put16(b + 2, v.lowCv); detail::put16(b + 4, v.lowClearCv);
        detail::put16(b + 6, v.highCv); detail::put16(b + 8, v.highClearCv);
        detail::put16(b + 10, v.delayS); detail::put16(b + 12, v.clearS);
    }
    const uint32_t crc = detail::crc32(bytes, length - 4);
    for (size_t i = 0; i < 4; ++i) bytes[length - 4 + i] = uint8_t(crc >> (8 * i));
    return true;
}

inline bool decodeConfig(const uint8_t* bytes, size_t length, Config& out) {
    if (!bytes || length != kConfigBlobSize || bytes[0] != 'B' || bytes[1] != 'S' ||
        bytes[2] != 'I' || bytes[3] != 1 || (bytes[4] & 0xf0) || bytes[5] ||
        bytes[10] || bytes[11]) return false;
    uint32_t stored = 0;
    for (size_t i = 0; i < 4; ++i) stored |= uint32_t(bytes[length - 4 + i]) << (8 * i);
    if (stored != detail::crc32(bytes, length - 4)) return false;
    Config c;
    c.enabled = bytes[4] & 1; c.nmeaEnabled = bytes[4] & 2;
    c.dataLossEnabled = bytes[4] & 4; c.chargerErrorEnabled = bytes[4] & 8;
    c.dataLossDelayS = detail::get16(bytes + 6); c.repeatMinutes = detail::get16(bytes + 8);
    for (size_t i = 0; i < kChannelCount; ++i) {
        const uint8_t* b = bytes + 12 + 14 * i;
        if ((b[0] & 0xfc) || b[1]) return false;
        auto& v = c.channels[i];
        v.lowEnabled = b[0] & 1; v.highEnabled = b[0] & 2;
        v.lowCv = detail::get16(b + 2); v.lowClearCv = detail::get16(b + 4);
        v.highCv = detail::get16(b + 6); v.highClearCv = detail::get16(b + 8);
        v.delayS = detail::get16(b + 10); v.clearS = detail::get16(b + 12);
    }
    if (!validConfig(c)) return false;
    out = c;
    return true;
}

enum class TransitionKind : uint8_t {
    Activated, Cleared, Acknowledged, Cancelled, Reminder, SettingsChanged
};

struct Transition {
    TransitionKind kind = TransitionKind::SettingsChanged;
    uint8_t slot = kSettingsSlot;
    uint32_t generation = 0;
    uint32_t sequence = 0;
    uint64_t atMs = 0;
    double value = 0;
};

struct AlertState {
    bool enabled = false;
    bool active = false;
    bool acknowledged = false;
    bool known = false;
    bool pending = false;
    uint32_t generation = 0;
    uint32_t sequence = 0;
    uint64_t activatedAtMs = 0;
    uint64_t changedAtMs = 0;
    double value = 0;
};

struct HistoryPoint { uint64_t atMs = 0; double voltage = 0; };

struct ChannelSnapshot {
    bool voltageValid = false;
    // Valid here means admitted for forward-transfer integration. Negative or
    // unsupported current remains visible as a number, but is never integrated.
    bool currentValid = false;
    double voltage = 0;
    double current = 0;
    bool hasExtrema = false;
    double minimumVoltage = 0;
    double maximumVoltage = 0;
    double transferAh = 0;
    double transferWh = 0;
    uint64_t coveredMs = 0;
    uint64_t transferCoveredMs = 0;
    // Conservatively counts only intervals with both endpoints below the limit.
    // Reset when the low threshold changes; other totals are since source reset.
    uint64_t belowLowMs = 0;
    uint16_t historySamples = 0;
    bool trendValid = false;
    double trendVoltsPerMinute = 0;
    uint64_t trendSpanMs = 0;
    // Chronological in returned snapshots; only historySamples entries are used.
    HistoryPoint history[kHistoryCapacity];
};

struct Snapshot {
    ChannelSnapshot channels[kChannelCount];
    AlertState alerts[kAlertCount];
    bool configured = false;
    bool fresh = false;
    uint64_t lastSampleAtMs = 0;
    uint64_t acceptedSamples = 0;
    uint32_t droppedTransitions = 0;
};

// Single-owner pure engine. The firmware adapter must serialize calls/snapshots.
// Timers use the same monotonic epoch as Telemetry::receivedAtMs modulo 2^32.
class Engine {
public:
    const Config& config() const { return config_; }

    bool applyConfig(const Config& next, uint64_t nowMs) {
        if (!validConfig(next) || (haveUpdate_ && nowMs < lastUpdateMs_)) return false;
        lastUpdateMs_ = nowMs; haveUpdate_ = true;
        if (sameConfig(config_, next)) return true;
        for (size_t i = 0; i < kChannelCount; ++i) {
            const auto& a = config_.channels[i]; const auto& b = next.channels[i];
            const bool timing = a.delayS != b.delayS || a.clearS != b.clearS;
            if (config_.enabled != next.enabled || timing || a.lowEnabled != b.lowEnabled ||
                a.lowCv != b.lowCv || a.lowClearCv != b.lowClearCv) cancel(i, nowMs);
            if (config_.enabled != next.enabled || timing || a.highEnabled != b.highEnabled ||
                a.highCv != b.highCv || a.highClearCv != b.highClearCv) cancel(i + 2, nowMs);
            if (a.lowCv != b.lowCv) channels_[i].values.belowLowMs = 0;
        }
        if (config_.enabled != next.enabled || config_.dataLossEnabled != next.dataLossEnabled ||
            config_.dataLossDelayS != next.dataLossDelayS) {
            cancel(4, nowMs); lossStartMs_ = nowMs;
        }
        if (config_.enabled != next.enabled || config_.chargerErrorEnabled != next.chargerErrorEnabled)
            cancel(5, nowMs);
        config_ = next;
        refreshEnabled(nowMs);
        emit(TransitionKind::SettingsChanged, kSettingsSlot, nowMs);
        return true;
    }

    void resetObservations(uint64_t nowMs) {
        if (haveUpdate_ && nowMs < lastUpdateMs_) return;
        for (size_t i = 0; i < kAlertCount; ++i) cancel(i, nowMs);
        for (auto& c : channels_) c = Channel{};
        haveSample_ = false; acceptedSamples_ = 0; lastSampleAtMs_ = 0;
        lossStartMs_ = nowMs;
        lastUpdateMs_ = nowMs; haveUpdate_ = true;
    }

    void update(const orion::Telemetry& t, uint64_t nowMs, bool configured) {
        if (haveUpdate_ && nowMs < lastUpdateMs_) return;
        lastUpdateMs_ = nowMs; haveUpdate_ = true;
        if (configured != configured_) {
            configured_ = configured;
            resetObservations(nowMs);
            refreshEnabled(nowMs);
        }
        if (!configured_) return;
        if (haveSample_ && nowMs - lastSampleAtMs_ > kMaxSampleGapMs) breakContinuity();
        const uint32_t age = uint32_t(uint32_t(nowMs) - t.receivedAtMs);
        const bool timely = t.received && age <= kMaxSampleGapMs && age <= nowMs;
        const uint64_t atMs = timely ? nowMs - age : 0;
        const bool distinct = timely && (!haveSample_ ||
            (t.counter != lastCounter_ && atMs > lastSampleAtMs_));
        if (distinct) {
            const bool contiguous = haveSample_ && atMs - lastSampleAtMs_ <= kMaxSampleGapMs;
            if (!contiguous) breakContinuity();
            const uint64_t dt = contiguous ? atMs - lastSampleAtMs_ : 0;
            // Reverse flow is uncharacterised; never count one side as forward
            // transfer when the paired channel provides contrary evidence.
            const bool reverse = (t.inputCurrent.valid && t.inputCurrent.number < 0) ||
                                 (t.outputCurrent.valid && t.outputCurrent.number < 0);
            observe(0, t.inputVoltage, t.inputCurrent, reverse, atMs, dt);
            observe(1, t.outputVoltage, t.outputCurrent, reverse, atMs, dt);
            evaluate(5, t.error != 0, t.error == 0, t.error != 255, double(t.error),
                     atMs, 10000, 30000);
            haveSample_ = true; lastSampleAtMs_ = atMs; lastCounter_ = t.counter;
            ++acceptedSamples_;
            if (alerts_[4].state.active)
                evaluate(4, false, true, true, 0, atMs, 0, 0);
            else resetPending(alerts_[4]);
            lossStartMs_ = atMs;
        }
        const bool fresh = haveSample_ && nowMs - lastSampleAtMs_ <= kMaxSampleGapMs;
        auto& loss = alerts_[4];
        if (loss.state.enabled) {
            loss.state.known = true;
            loss.state.value = double(nowMs - lossStartMs_) / 1000.0;
            if (!fresh && !loss.state.active) {
                loss.state.pending = true;
                if (nowMs - lossStartMs_ >= uint64_t(config_.dataLossDelayS) * 1000)
                    activate(4, nowMs);
            }
        }
        if (config_.repeatMinutes) {
            const uint64_t period = uint64_t(config_.repeatMinutes) * 60000;
            for (size_t i = 0; i < kAlertCount; ++i) {
                auto& a = alerts_[i];
                if (a.state.active && !a.state.acknowledged && nowMs - a.lastReminderMs >= period) {
                    a.lastReminderMs = nowMs;
                    emit(TransitionKind::Reminder, uint8_t(i), nowMs);
                }
            }
        }
    }

    bool acknowledge(uint8_t slot, uint64_t nowMs) {
        if (slot >= kAlertCount || (haveUpdate_ && nowMs < lastUpdateMs_)) return false;
        auto& a = alerts_[slot];
        if (!a.state.active || a.state.acknowledged) return false;
        a.state.acknowledged = true;
        lastUpdateMs_ = nowMs; haveUpdate_ = true;
        emit(TransitionKind::Acknowledged, slot, nowMs);
        return true;
    }

    Snapshot snapshot(uint64_t nowMs) const {
        Snapshot s;
        snapshot(nowMs, s);
        return s;
    }

    AlertState alert(uint8_t slot) const {
        return slot < kAlertCount ? alerts_[slot].state : AlertState{};
    }

    // Fill caller-owned storage without a large temporary on the HTTPS stack.
    void snapshot(uint64_t nowMs, Snapshot& s) const {
        s.configured = configured_;
        s.fresh = haveSample_ && nowMs >= lastSampleAtMs_ &&
                  nowMs - lastSampleAtMs_ <= kMaxSampleGapMs;
        s.lastSampleAtMs = lastSampleAtMs_; s.acceptedSamples = acceptedSamples_;
        s.droppedTransitions = droppedTransitions_;
        for (size_t i = 0; i < kChannelCount; ++i) {
            s.channels[i] = channels_[i].values;
            for (size_t p = 0; p < channels_[i].count; ++p)
                s.channels[i].history[p] = channels_[i].values.history[
                    (channels_[i].head + p) % kHistoryCapacity];
            if (!s.fresh) {
                s.channels[i].voltageValid = false; s.channels[i].currentValid = false;
                s.channels[i].trendValid = false;
            }
        }
        for (size_t i = 0; i < kAlertCount; ++i) {
            s.alerts[i] = alerts_[i].state;
            if (!s.fresh && i != 4) { s.alerts[i].known = false; s.alerts[i].pending = false; }
        }
    }

    bool popTransition(Transition& out) {
        if (!eventCount_) return false;
        out = events_[eventHead_];
        eventHead_ = (eventHead_ + 1) % kTransitionCapacity; --eventCount_;
        return true;
    }

private:
    struct Channel {
        ChannelSnapshot values;
        bool previousVoltageValid = false;
        bool previousTransferValid = false;
        double previousVoltage = 0;
        double previousCurrent = 0;
        uint16_t previousLowCv = 0;
        size_t head = 0;
        size_t count = 0;
    };
    struct Alert {
        AlertState state;
        uint64_t pendingSinceMs = 0;
        uint64_t lastReminderMs = 0;
        uint8_t pendingSamples = 0;
    };

    static void resetPending(Alert& a) {
        a.state.pending = false; a.pendingSinceMs = 0; a.pendingSamples = 0;
    }
    void emit(TransitionKind kind, uint8_t slot, uint64_t atMs) {
        Transition e;
        e.kind = kind; e.slot = slot; e.atMs = atMs; e.sequence = ++sequence_;
        if (slot < kAlertCount) {
            auto& s = alerts_[slot].state;
            s.sequence = e.sequence; s.changedAtMs = atMs;
            e.generation = s.generation; e.value = s.value;
        }
        if (eventCount_ == kTransitionCapacity) {
            eventHead_ = (eventHead_ + 1) % kTransitionCapacity; --eventCount_;
            ++droppedTransitions_;
        }
        events_[(eventHead_ + eventCount_) % kTransitionCapacity] = e;
        ++eventCount_;
    }
    void cancel(size_t slot, uint64_t nowMs) {
        auto& a = alerts_[slot];
        if (a.state.active) {
            a.state.active = false; a.state.acknowledged = false;
            emit(TransitionKind::Cancelled, uint8_t(slot), nowMs);
        }
        a.state.known = false; resetPending(a);
    }
    void refreshEnabled(uint64_t nowMs) {
        const bool on = config_.enabled && configured_;
        const bool enabled[kAlertCount] = {
            on && config_.channels[0].lowEnabled, on && config_.channels[1].lowEnabled,
            on && config_.channels[0].highEnabled, on && config_.channels[1].highEnabled,
            on && config_.dataLossEnabled, on && config_.chargerErrorEnabled};
        for (size_t i = 0; i < kAlertCount; ++i) {
            if (!enabled[i]) cancel(i, nowMs);
            alerts_[i].state.enabled = enabled[i];
        }
    }
    void activate(size_t slot, uint64_t atMs) {
        auto& a = alerts_[slot];
        a.state.active = true; a.state.acknowledged = false;
        ++a.state.generation; a.state.activatedAtMs = atMs; a.lastReminderMs = atMs;
        resetPending(a); emit(TransitionKind::Activated, uint8_t(slot), atMs);
    }
    void evaluate(size_t slot, bool trigger, bool recovery, bool valid, double value,
                  uint64_t atMs, uint64_t delayMs, uint64_t clearMs) {
        auto& a = alerts_[slot];
        if (!a.state.enabled) return;
        a.state.known = valid;
        if (!valid) { resetPending(a); return; }
        a.state.value = value;
        if (!(a.state.active ? recovery : trigger)) { resetPending(a); return; }
        if (!a.state.pending) {
            a.state.pending = true; a.pendingSinceMs = atMs; a.pendingSamples = 0;
        }
        if (a.pendingSamples < 3) ++a.pendingSamples;
        if (a.pendingSamples < 3 || atMs - a.pendingSinceMs < (a.state.active ? clearMs : delayMs)) return;
        if (!a.state.active) activate(slot, atMs);
        else {
            a.state.active = false; a.state.acknowledged = false;
            resetPending(a); emit(TransitionKind::Cleared, uint8_t(slot), atMs);
        }
    }
    void breakContinuity() {
        for (auto& a : alerts_) { a.state.known = false; resetPending(a); }
        for (auto& c : channels_) {
            c.previousVoltageValid = false; c.previousTransferValid = false;
            c.count = 0; c.head = 0; c.values.historySamples = 0;
            c.values.trendValid = false; c.values.trendSpanMs = 0;
        }
    }
    void addHistory(Channel& c, uint64_t atMs, double voltage) {
        while (c.count && (c.count == kHistoryCapacity ||
               atMs - c.values.history[c.head].atMs > kHistoryWindowMs)) {
            c.head = (c.head + 1) % kHistoryCapacity; --c.count;
        }
        c.values.history[(c.head + c.count) % kHistoryCapacity] = {atMs, voltage}; ++c.count;
        auto& v = c.values;
        v.historySamples = uint16_t(c.count);
        v.trendSpanMs = atMs - c.values.history[c.head].atMs;
        v.trendValid = c.count >= 3 && v.trendSpanMs >= 10000;
        if (!v.trendValid) return;
        // Relative times avoid cancellation after a long continuously powered run.
        double x = 0, y = 0, xx = 0, xy = 0;
        for (size_t i = 0; i < c.count; ++i) {
            const auto& p = c.values.history[(c.head + i) % kHistoryCapacity];
            const double seconds = double(p.atMs - c.values.history[c.head].atMs) / 1000;
            x += seconds; y += p.voltage; xx += seconds * seconds; xy += seconds * p.voltage;
        }
        const double divisor = double(c.count) * xx - x * x;
        v.trendValid = divisor > 0;
        if (v.trendValid) v.trendVoltsPerMinute =
            60.0 * (double(c.count) * xy - x * y) / divisor;
    }
    void observe(size_t channel, const orion::Value& voltage, const orion::Value& current,
                 bool reverse, uint64_t atMs, uint64_t dt) {
        auto& c = channels_[channel]; auto& v = c.values;
        v.voltageValid = detail::validVoltage(voltage);
        v.currentValid = !reverse && detail::validForwardCurrent(current);
        v.voltage = std::isfinite(voltage.number) ? voltage.number : 0;
        v.current = std::isfinite(current.number) ? current.number : 0;
        const auto& cfg = config_.channels[channel];
        // Advertisements resolve voltage to hundredths. Compare integer source
        // units so binary floating-point noise cannot move an inclusive limit.
        const auto cv = v.voltageValid ? uint16_t(std::lround(v.voltage * 100)) : 0;
        const auto previousCv = c.previousVoltageValid ?
            uint16_t(std::lround(c.previousVoltage * 100)) : 0;
        const bool transferValid = v.voltageValid && v.currentValid;
        if (dt && v.voltageValid && c.previousVoltageValid) {
            v.coveredMs += dt;
            if (c.previousLowCv == cfg.lowCv && cv < cfg.lowCv && previousCv < cfg.lowCv)
                v.belowLowMs += dt;
        }
        if (dt && transferValid && c.previousTransferValid) {
            const double hours = double(dt) / 3600000.0;
            v.transferAh += 0.5 * (c.previousCurrent + v.current) * hours;
            v.transferWh += 0.5 * (c.previousCurrent * c.previousVoltage + v.current * v.voltage) * hours;
            v.transferCoveredMs += dt;
        }
        if (v.voltageValid) {
            if (!v.hasExtrema) v.minimumVoltage = v.maximumVoltage = v.voltage;
            else {
                if (v.voltage < v.minimumVoltage) v.minimumVoltage = v.voltage;
                if (v.voltage > v.maximumVoltage) v.maximumVoltage = v.voltage;
            }
            v.hasExtrema = true; addHistory(c, atMs, v.voltage);
        } else {
            c.count = 0; c.head = 0; v.historySamples = 0;
            v.trendValid = false; v.trendSpanMs = 0;
        }
        c.previousVoltageValid = v.voltageValid; c.previousTransferValid = transferValid;
        c.previousVoltage = v.voltage; c.previousCurrent = v.current;
        c.previousLowCv = cfg.lowCv;
        evaluate(channel, cv < cfg.lowCv, cv >= cfg.lowClearCv,
                 v.voltageValid, v.voltage, atMs, uint64_t(cfg.delayS) * 1000, uint64_t(cfg.clearS) * 1000);
        evaluate(channel + 2, cv > cfg.highCv, cv <= cfg.highClearCv,
                 v.voltageValid, v.voltage, atMs, uint64_t(cfg.delayS) * 1000, uint64_t(cfg.clearS) * 1000);
    }

    Config config_;
    Channel channels_[kChannelCount];
    Alert alerts_[kAlertCount];
    Transition events_[kTransitionCapacity];
    size_t eventHead_ = 0;
    size_t eventCount_ = 0;
    uint32_t sequence_ = 0;
    uint32_t droppedTransitions_ = 0;
    bool configured_ = false;
    bool haveSample_ = false;
    bool haveUpdate_ = false;
    uint16_t lastCounter_ = 0;
    uint64_t lastSampleAtMs_ = 0;
    uint64_t lastUpdateMs_ = 0;
    uint64_t lossStartMs_ = 0;
    uint64_t acceptedSamples_ = 0;
};

} // namespace bs::insights
