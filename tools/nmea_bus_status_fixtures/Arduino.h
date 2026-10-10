#pragma once
#include <cstdint>

using TickType_t = uint32_t;
#define pdMS_TO_TICKS(value) (value)

extern uint32_t testMillis;
inline uint32_t millis() { return testMillis; }

struct TestSerial {
    template<typename... Args> void printf(const char*, Args...) {}
};
extern TestSerial Serial;
