#include "FramStateStore.h"

#include <cstring>

namespace bs {

bool FramStateStore::begin(TwoWire& wire) {
    wire_ = &wire;
    present_ = ping();
    if (!present_) {
        activeSlot_ = -1;
        lastSequence_ = 0;
        return false;
    }

    state::PersistentState ignored;
    load(ignored);  // Initializes active slot/sequence if a valid record exists.
    return true;
}

bool FramStateStore::load(state::PersistentState& out) {
    if (!present_ || wire_ == nullptr) return false;

    state::PersistentState a{};
    state::PersistentState b{};
    const bool validA = readRecord(SLOT0_ADDRESS, a) && state::valid(a);
    const bool validB = readRecord(SLOT1_ADDRESS, b) && state::valid(b);

    if (!validA && !validB) {
        activeSlot_ = -1;
        lastSequence_ = 0;
        return false;
    }

    if (validA && (!validB || state::sequenceNewer(a.sequence, b.sequence))) {
        out = a;
        activeSlot_ = 0;
        lastSequence_ = a.sequence;
    } else {
        out = b;
        activeSlot_ = 1;
        lastSequence_ = b.sequence;
    }
    return true;
}

bool FramStateStore::save(state::PersistentState value) {
    if (!present_ || wire_ == nullptr) return false;

    value.sequence = lastSequence_ + 1u;
    state::seal(value);

    const int8_t targetSlot = activeSlot_ == 0 ? 1 : 0;
    const uint16_t address = targetSlot == 0 ? SLOT0_ADDRESS : SLOT1_ADDRESS;

    if (!writeRecord(address, value)) return false;

    // Read-after-write catches bus faults and makes sure the newly written slot is complete
    // before it becomes the active record in RAM.
    state::PersistentState verify{};
    if (!readRecord(address, verify) || !state::valid(verify) ||
        verify.sequence != value.sequence) {
        return false;
    }

    activeSlot_ = targetSlot;
    lastSequence_ = value.sequence;
    return true;
}

bool FramStateStore::ping() {
    if (wire_ == nullptr) return false;
    wire_->beginTransmission(address_);
    return wire_->endTransmission() == 0;
}

bool FramStateStore::readRecord(uint16_t address, state::PersistentState& out) {
    return readBytes(address, reinterpret_cast<uint8_t*>(&out), sizeof(out));
}

bool FramStateStore::writeRecord(uint16_t address, const state::PersistentState& value) {
    return writeBytes(address, reinterpret_cast<const uint8_t*>(&value), sizeof(value));
}

bool FramStateStore::readBytes(uint16_t address, uint8_t* data, size_t size) {
    size_t offset = 0;
    while (offset < size) {
        const size_t chunk = (size - offset) > IO_CHUNK ? IO_CHUNK : (size - offset);
        const uint16_t currentAddress = static_cast<uint16_t>(address + offset);

        wire_->beginTransmission(address_);
        wire_->write(static_cast<uint8_t>(currentAddress >> 8));
        wire_->write(static_cast<uint8_t>(currentAddress & 0xFFu));
        if (wire_->endTransmission(false) != 0) return false;

        const size_t received = wire_->requestFrom(static_cast<int>(address_), static_cast<int>(chunk));
        if (received != chunk) return false;
        for (size_t i = 0; i < chunk; ++i) {
            data[offset + i] = static_cast<uint8_t>(wire_->read());
        }
        offset += chunk;
    }
    return true;
}

bool FramStateStore::writeBytes(uint16_t address, const uint8_t* data, size_t size) {
    size_t offset = 0;
    while (offset < size) {
        const size_t chunk = (size - offset) > IO_CHUNK ? IO_CHUNK : (size - offset);
        const uint16_t currentAddress = static_cast<uint16_t>(address + offset);

        wire_->beginTransmission(address_);
        wire_->write(static_cast<uint8_t>(currentAddress >> 8));
        wire_->write(static_cast<uint8_t>(currentAddress & 0xFFu));
        if (wire_->write(data + offset, chunk) != chunk) return false;
        if (wire_->endTransmission() != 0) return false;
        offset += chunk;
    }
    return true;
}

} // namespace bs
