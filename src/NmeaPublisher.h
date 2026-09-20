#pragma once

#include <Arduino.h>
#include <BatteryCore.h>
#include <OrionFrame.h>

namespace bs {

class NmeaPublisher {
public:
    void begin(uint32_t uniqueNumber, bool orionBridge = false);
    void process();

    void publishFast(uint8_t batteryInstance, const BatterySnapshot& state, bool measurementValid);
    void publishDc(uint8_t batteryInstance, const BatterySnapshot& state, bool measurementValid);
    void publishOrion(const orion::Telemetry& state, uint32_t now,
                      uint8_t outputInstance, uint8_t inputInstance);
    void publishOrionMetadata(uint8_t outputInstance, uint8_t inputInstance);
    uint32_t transmitted() const { return transmitted_; }
    uint32_t failed() const { return failed_; }

private:
    uint8_t sid_ = 0;
    uint32_t transmitted_ = 0;
    uint32_t failed_ = 0;
};

} // namespace bs
