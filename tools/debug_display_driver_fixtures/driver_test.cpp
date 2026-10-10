#include <BridgeDebugDisplay.h>
#include <Arduino.h>
#include <Wire.h>
#include <cstdio>
#include <cstring>
#include <stdexcept>

void require(bool value, const char* message) {
    if (!value) throw std::runtime_error(message);
}
void disabled(bs::BridgeDebugDisplay& display) {
    const int calls = Wire.startCalls;
    bs::debugdisplay::Snapshot snapshot;
    for (uint32_t now : {0U, 500U, 10000U, 0xffffffffU}) {
        require(!display.due(now), "Faulted display must not schedule frames");
        display.show(snapshot);
        display.boot("Retry stage");
    }
    require(Wire.startCalls == calls, "Faulted display retried I2C");
    require(!Wire.locked, "Fault path retained Wire's transmission lock");
}
int main(int argc, char** argv) {
    try {
        require(argc == 2, "Expected scenario");
        const char* scenario = argv[1];
        bs::BridgeDebugDisplay display;
        if (!strcmp(scenario, "buffer")) Wire.bufferResult = 0;
        if (!strcmp(scenario, "begin")) Wire.beginResult = false;
        if (!strcmp(scenario, "probe")) Wire.failEndAt = 1;
        if (!strcmp(scenario, "init")) Wire.failEndAt = 2;
        if (!strcmp(scenario, "contrast")) Wire.failEndAt = 3;
        if (!strcmp(scenario, "boot")) Wire.failEndAt = 4;
        const bool runtime = !strcmp(scenario, "runtime") || !strcmp(scenario, "short-write");
        const bool ready = display.begin();
        require(Wire.requestedBuffer == 128, "Incorrect I2C buffer request");
        if (!strcmp(scenario, "buffer")) require(!Wire.beginCalls, "Begin after allocation failure");
        else if (!strcmp(scenario, "begin")) require(!Wire.startCalls, "Probe after begin failure");
        else {
            require(Wire.sda == 5 && Wire.scl == 6, "Wrong debug I2C pins");
            require(Wire.frequency == 400000 && Wire.timeout == 20, "Missing bounded I2C setup");
            require(Wire.address == 0x3c, "Wrong I2C address");
        }
        if (runtime || !strcmp(scenario, "healthy")) {
            require(ready, "Healthy display failed to initialize");
            const int ends = Wire.endCalls;
            if (!strcmp(scenario, "runtime")) Wire.failEndAt = ends + 1;
            if (!strcmp(scenario, "short-write")) Wire.shortWriteAt = Wire.writeCalls + 1;
            display.show(bs::debugdisplay::Snapshot{});
            if (runtime) {
                require(Wire.endCalls == ends + 1, "Continued I2C after first frame error");
                disabled(display);
            } else {
                require(Wire.endCalls == ends + 5, "Healthy frame was not sent");
                require(Wire.maxBytes == 73, "Unexpected exercised row size");
                require(!Wire.locked, "Successful frame retained lock");
            }
        } else {
            require(!ready, "Initialization failure was ignored");
            if (Wire.failEndAt) require(Wire.endCalls == Wire.failEndAt, "Continued I2C after initialization error");
            disabled(display);
            require(!Serial.lines.empty(), "Display failure was not reported on Serial");
        }
        std::printf("PASS %s\n", scenario);
        return 0;
    } catch (const std::exception& error) {
        std::fprintf(stderr, "%s: %s\n", argc > 1 ? argv[1] : "test", error.what());
        return 1;
    }
}
