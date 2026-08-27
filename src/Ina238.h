#pragma once

#include <Arduino.h>
#include <Wire.h>

#include <BatteryCore.h>

namespace bs {

class Ina238 {
public:
    Ina238(TwoWire& wire, uint8_t address, double shuntOhm)
        : wire_(wire), address_(address), shuntOhm_(shuntOhm) {}

    bool begin();
    Measurement read();
    bool present() const { return present_; }

private:
    static constexpr uint8_t REG_CONFIG = 0x00;
    static constexpr uint8_t REG_VSHUNT = 0x04;
    static constexpr uint8_t REG_VBUS = 0x05;

    // INA238 ADCRANGE=0: signed shunt-voltage LSB = 5 uV/bit.
    static constexpr double SHUNT_LSB_V = 5.0e-6;
    // INA238 bus-voltage LSB = 3.125 mV/bit.
    static constexpr double BUS_LSB_V = 3.125e-3;

    TwoWire& wire_;
    uint8_t address_;
    double shuntOhm_;
    bool present_ = false;

    bool ping();
    bool write16(uint8_t reg, uint16_t value);
    bool read16(uint8_t reg, uint16_t& value);
};

} // namespace bs
