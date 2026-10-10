#pragma once
#include <cstddef>
#include <cstdint>
#include <cstdlib>
struct WireFixture {
    size_t bufferResult = 128, requestedBuffer = 0;
    bool beginResult = true, locked = false;
    int beginCalls = 0, startCalls = 0, endCalls = 0, writeCalls = 0;
    int failEndAt = 0, shortWriteAt = 0, sda = -1, scl = -1;
    uint32_t frequency = 0;
    uint16_t timeout = 0;
    uint8_t address = 0;
    size_t bytes = 0, maxBytes = 0;
    size_t setBufferSize(size_t value) { requestedBuffer = value; return bufferResult; }
    bool begin(int data, int clock, uint32_t hz) {
        ++beginCalls; sda = data; scl = clock; frequency = hz; return beginResult;
    }
    void setTimeOut(uint16_t value) { timeout = value; }
    void beginTransmission(uint8_t value) {
        if (locked) std::abort();
        locked = true; address = value; bytes = 0; ++startCalls;
    }
    size_t write(const uint8_t*, size_t size) {
        if (!locked) std::abort();
        ++writeCalls;
        if (writeCalls == shortWriteAt) return 0;
        bytes += size; if (bytes > maxBytes) maxBytes = bytes;
        return size;
    }
    uint8_t endTransmission() {
        if (!locked) std::abort();
        locked = false; ++endCalls;
        return endCalls == failEndAt ? 5 : 0;
    }
};
inline WireFixture Wire;
