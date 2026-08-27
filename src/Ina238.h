#pragma once

#include <Arduino.h>
#include <Wire.h>

#include <BatteryCore.h>

namespace bs {

class Ina238 {
public:
    Ina238(TwoWire& wire, uint8_t address, double shuntOhm, bool narrowRange = false)
        : wire_(wire), address_(address), shuntOhm_(shuntOhm), narrowRange_(narrowRange) {}

    bool begin();
    Measurement read();
    bool present() const { return present_; }
    bool narrowRange() const { return narrowRange_; }

private:
    static constexpr uint8_t REG_CONFIG = 0x00;
    static constexpr uint8_t REG_VSHUNT = 0x04;
    static constexpr uint8_t REG_VBUS = 0x05;
    static constexpr uint16_t CONFIG_ADCRANGE = 1u << 4;

    TwoWire& wire_;
    uint8_t address_;
    double shuntOhm_;
    bool narrowRange_;
    bool present_ = false;

    bool configure();
    bool ping();
    bool write16(uint8_t reg, uint16_t value);
    bool read16(uint8_t reg, uint16_t& value);
};

} // namespace bs
