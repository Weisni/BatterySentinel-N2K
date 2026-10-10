#pragma once

#include <cstddef>
#include <cstdint>
#include <cstring>
#include <initializer_list>

namespace bs { namespace alerts {

constexpr size_t kSlots = 6;
struct Input {
    uint32_t generation = 0;
    uint8_t instance = 0;
    bool active = false, known = false, acknowledged = false;
};
struct Identity {
    uint64_t name = 0;
    uint8_t slot = 0, instance = 0, occurrence = 0;
};
struct Packet { uint32_t pgn = 0; uint8_t bytes[128]{}; size_t size = 0; };
enum class State : uint8_t { Disabled = 0, Normal = 1, Active = 2, Acknowledged = 4 };

// Field order/bit widths: CANboat PGNs 126983/126984/126985 and ALERT_*
// lookup tables, https://canboat.github.io/canboat/canboat.html (2026-09-26).
// These source-scoped local IDs/system=0/subsystem=0 are experimental;
// they do not claim a standardized electrical alarm assignment.
inline void putName(uint8_t* bytes, uint64_t name) {
    for (size_t i = 0; i < 8; ++i) bytes[i] = uint8_t(name >> (8 * i));
}
inline uint64_t getName(const uint8_t* bytes) {
    uint64_t value = 0;
    for (size_t i = 0; i < 8; ++i) value |= uint64_t(bytes[i]) << (8 * i);
    return value;
}
inline void identityBytes(const Identity& id, uint8_t* bytes) {
    bytes[0] = 0x15; // Technical (1), Warning (5)
    bytes[1] = 0; bytes[2] = 0;
    bytes[3] = id.slot + 1; bytes[4] = 0;
    putName(bytes + 5, id.name);
    bytes[13] = id.instance; bytes[14] = id.slot; bytes[15] = id.occurrence;
}
inline Packet alertPacket(const Identity& id, State state) {
    Packet result; result.pgn = 126983; result.size = 28;
    identityBytes(id, result.bytes);
    // No silence, escalation or remote acknowledgement support. The finite
    // occurrence field cannot disambiguate delayed replies across cold boots.
    result.bytes[16] = 0xc0 | (state == State::Acknowledged ? 2 : 0);
    putName(result.bytes + 17, state == State::Acknowledged ? id.name : UINT64_MAX);
    const uint8_t threshold = state == State::Active || state == State::Acknowledged ?
        (id.slot < 2 ? 3 : 1) : 0;
    result.bytes[25] = uint8_t((threshold << 4) | (state == State::Disabled ? 3 : 1));
    result.bytes[26] = 5; // Local warning priority; not a Garmin severity promise.
    result.bytes[27] = uint8_t(state);
    return result;
}
inline Packet textPacket(const Identity& id) {
    static const char* const descriptions[kSlots] = {
        "Orion input voltage low", "Orion output voltage low",
        "Orion input voltage high", "Orion output voltage high",
        "Orion measurements unavailable", "Orion charger error"
    };
    Packet result; result.pgn = 126985; result.size = 17;
    identityBytes(id, result.bytes); result.bytes[16] = 0; // English (US)
    const char* text = id.slot < kSlots ? descriptions[id.slot] : "Orion alert";
    const char* location = "Orion Bridge";
    for (const char* value : {text, location}) {
        const size_t length = std::strlen(value);
        result.bytes[result.size++] = uint8_t(length + 2);
        result.bytes[result.size++] = 1; // STRING_LAU ASCII
        std::memcpy(result.bytes + result.size, value, length); result.size += length;
    }
    return result;
}
inline bool isAcknowledgement(const uint8_t* bytes, size_t size, const Identity& id,
                              uint64_t respondingName) {
    if (size != 25 || !respondingName || respondingName == UINT64_MAX) return false;
    uint8_t expected[16]; identityBytes(id, expected);
    return std::memcmp(bytes, expected, sizeof(expected)) == 0 &&
        getName(bytes + 16) == respondingName && (bytes[24] & 3) == 0;
}

struct Status {
    bool enabled = false, backlog = false, draining = false, drainComplete = false;
    bool drainTimedOut = false, withdrawalsUnconfirmed = false;
    uint32_t accepted = 0, failed = 0, ignoredResponses = 0;
    uint32_t pending = 0, withdrawals = 0;
    uint64_t lastAttemptMs = 0;
};

class Delivery {
public:
    void begin(uint64_t name) { name_ = name; }
    void set(const Input (&inputs)[kSlots], bool enabled) {
        if (status_.draining) return;
        status_.enabled = enabled; status_.backlog = false;
        for (size_t slot = 0; slot < kSlots; ++slot) {
            Entry& entry = entries_[slot]; const Input& input = inputs[slot];
            if (!entry.used && input.instance > 252) continue;
            const uint8_t instance = input.instance <= 252 ? input.instance : entry.id.instance;
            const uint8_t occurrence = uint8_t(input.generation % 253);
            // Retain old mapped identities for every later receiver reconnect.
            // Never discard a required withdrawal just to make room for a remap.
            const bool unresolvedOccurrence = entry.announced && entry.id.occurrence != occurrence &&
                (entry.announcedState == State::Active || entry.announcedState == State::Acknowledged);
            if (entry.used && entry.announced && (entry.id.instance != instance || unresolvedOccurrence)) {
                if (!retire(entry)) {
                    status_.backlog = true;
                    if (entry.state != State::Disabled) entry.dirty = true;
                    entry.state = State::Disabled;
                    continue;
                }
                entry = Entry{};
            }
            const State state = !enabled || input.instance > 252 ? State::Disabled :
                input.active ? (input.acknowledged ? State::Acknowledged : State::Active) :
                input.known ? State::Normal : State::Disabled;
            // A disabled default configuration emits nothing until enabled once.
            if (!entry.used && !enabled) continue;
            // A mapping can return to a previously withdrawn instance. Do not
            // keep sending its old tombstone alongside the current state.
            for (Entry& retired : retired_) if (retired.used &&
                retired.id.slot == slot && retired.id.instance == instance &&
                retired.id.occurrence == occurrence) retired = Entry{};
            if (!entry.used || entry.state != state || entry.id.occurrence != occurrence ||
                entry.id.instance != instance) {
                entry.dirty = true; entry.textDirty = true;
            }
            entry.used = true; entry.id = {name_, uint8_t(slot), instance, occurrence};
            entry.state = state;
        }
    }
    void reconcile() {
        for (Entry& entry : entries_) if (entry.used) entry.dirty = entry.textDirty = true;
        for (Entry& entry : retired_) if (entry.used) entry.dirty = true;
    }
    void prepareForRestart(uint64_t now) {
        if (status_.draining) return;
        status_.draining = true; status_.enabled = false;
        drainStarted_ = now;
        for (size_t index = 0; index < kSlots + kRetired; ++index) {
            Entry& entry = at(index);
            if (!entry.used) continue;
            if (!entry.announced) { entry = Entry{}; continue; }
            entry.state = State::Disabled; entry.dirty = true; entry.drainRemaining = 3;
        }
    }
    // One fast packet per call, rate-limited globally; failed submissions retry.
    void tick(uint64_t now) {
        if (status_.draining && now - drainStarted_ >= 5000 && !status().drainComplete) {
            status_.drainTimedOut = true; status_.withdrawalsUnconfirmed = true;
        }
    }
    bool next(uint64_t now, Packet& packet) {
        tick(now);
        if (!name_ || (sentAny_ && now - lastSent_ < 100)) return false;
        for (size_t n = 0; n < kSlots + kRetired; ++n) {
            const size_t index = (cursor_ + n) % (kSlots + kRetired);
            Entry& entry = at(index);
            if (!entry.used) continue;
            const uint64_t interval = status_.draining && entry.drainRemaining ? 250 :
                index < kSlots && entry.state != State::Disabled ? 1000 : 10000;
            const bool statusDue = entry.dirty || !entry.announced || now - entry.lastStatus >= interval;
            const bool textDue = index < kSlots && entry.state != State::Disabled &&
                (entry.textDirty || now - entry.lastText >= 10000);
            // Alternate text/status under load so active status cannot starve text.
            if (!statusDue && !textDue) continue;
            pendingText_ = textDue && (!statusDue || entry.lastWasStatus);
            packet = pendingText_ ? textPacket(entry.id) : alertPacket(entry.id, entry.state);
            pendingIndex_ = index; cursor_ = (index + 1) % (kSlots + kRetired);
            lastSent_ = now; sentAny_ = true; status_.lastAttemptMs = now;
            return true;
        }
        return false;
    }
    void result(bool accepted, uint64_t now) {
        if (accepted) ++status_.accepted; else { ++status_.failed; return; }
        Entry& entry = at(pendingIndex_);
        if (pendingText_) { entry.textDirty = false; entry.lastText = now; entry.lastWasStatus = false; }
        else {
            entry.dirty = false; entry.lastStatus = now; entry.announced = true; entry.lastWasStatus = true;
            entry.announcedState = entry.state;
            if (entry.drainRemaining) --entry.drainRemaining;
        }
    }
    void responseIgnored() { ++status_.ignoredResponses; }
    Status status() const {
        Status result = status_;
        result.drainComplete = result.draining;
        for (const Entry& entry : entries_) if (entry.used && (entry.dirty || !entry.announced || entry.drainRemaining)) ++result.pending;
        for (const Entry& entry : retired_) if (entry.used) { ++result.withdrawals; if (entry.dirty || entry.drainRemaining) ++result.pending; }
        for (const Entry& entry : entries_) if (entry.drainRemaining) result.drainComplete = false;
        for (const Entry& entry : retired_) if (entry.drainRemaining) result.drainComplete = false;
        return result;
    }
private:
    static constexpr size_t kRetired = 24;
    struct Entry {
        Identity id{}; State state = State::Disabled, announcedState = State::Disabled;
        uint8_t drainRemaining = 0;
        bool used = false, dirty = false, textDirty = false, announced = false, lastWasStatus = false;
        uint64_t lastStatus = 0, lastText = 0;
    };
    bool retire(const Entry& original) {
        for (Entry& entry : retired_) {
            if (entry.used && entry.id.slot == original.id.slot && entry.id.instance == original.id.instance &&
                entry.id.occurrence == original.id.occurrence) {
                entry = original; entry.state = State::Disabled; entry.dirty = true; return true;
            }
        }
        for (Entry& entry : retired_) if (!entry.used) {
            entry = original; entry.state = State::Disabled; entry.dirty = true; return true;
        }
        return false;
    }
    Entry& at(size_t index) { return index < kSlots ? entries_[index] : retired_[index - kSlots]; }
    Entry entries_[kSlots]{}, retired_[kRetired]{};
    Status status_{};
    uint64_t name_ = 0, lastSent_ = 0, drainStarted_ = 0;
    size_t cursor_ = 0, pendingIndex_ = 0;
    bool sentAny_ = false, pendingText_ = false;
};

}} // namespace bs::alerts
