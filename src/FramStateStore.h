#pragma once

#include <Arduino.h>
#include <Wire.h>

#include <StateCore.h>

namespace bs {

// MB85RC256-compatible 16-bit-address I2C FRAM store.
// Two 64-byte slots are alternated; CRC and sequence number make interrupted writes safe.
class FramStateStore {
public:
    explicit FramStateStore(uint8_t address = 0x50) : address_(address) {}

    bool begin(TwoWire& wire);
    bool load(state::PersistentState& out);
    bool save(state::PersistentState value);

    bool present() const { return present_; }
    uint32_t lastSequence() const { return lastSequence_; }

private:
    static constexpr uint16_t SLOT0_ADDRESS = 0x0000;
    static constexpr uint16_t SLOT1_ADDRESS = 0x0040;
    static constexpr size_t IO_CHUNK = 28;  // 2 address bytes + payload stays below Wire buffers.

    TwoWire* wire_ = nullptr;
    uint8_t address_ = 0x50;
    bool present_ = false;
    int8_t activeSlot_ = -1;
    uint32_t lastSequence_ = 0;

    bool ping();
    bool readRecord(uint16_t address, state::PersistentState& out);
    bool writeRecord(uint16_t address, const state::PersistentState& value);
    bool readBytes(uint16_t address, uint8_t* data, size_t size);
    bool writeBytes(uint16_t address, const uint8_t* data, size_t size);
};

} // namespace bs
