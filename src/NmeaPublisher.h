#pragma once

#include <Arduino.h>
#include <BatteryCore.h>

namespace bs {

class NmeaPublisher {
public:
    void begin(uint32_t uniqueNumber);
    void process();

    void publishFast(uint8_t batteryInstance, const BatterySnapshot& state, bool measurementValid);
    void publishDc(uint8_t batteryInstance, const BatterySnapshot& state, bool measurementValid);

private:
    uint8_t sid_ = 0;
};

} // namespace bs
