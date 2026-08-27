#include "Ina238.h"

#include <Ina238Math.h>

namespace bs {

bool Ina238::begin() {
    present_ = ping();
    if (!present_) return false;
    present_ = configure();
    return present_;
}

bool Ina238::configure() {
    // ADCRANGE=0 -> ±163.84 mV, 5 uV/LSB.
    // ADCRANGE=1 -> ±40.96 mV, 1.25 uV/LSB.
    // Default ADC_CONFIG already continuously converts bus, shunt and die temperature.
    return write16(REG_CONFIG, narrowRange_ ? CONFIG_ADCRANGE : 0x0000);
}

Measurement Ina238::read() {
    Measurement m{};
    if (shuntOhm_ <= 0.0) return m;

    // Allow a sensor/isolated domain that was missing during boot to recover later.
    if (!present_) {
        present_ = ping() && configure();
        if (!present_) return m;
    }

    uint16_t rawBus = 0;
    uint16_t rawShuntUnsigned = 0;
    if (!read16(REG_VBUS, rawBus) || !read16(REG_VSHUNT, rawShuntUnsigned)) {
        present_ = false;
        return m;
    }

    const int16_t rawShunt = static_cast<int16_t>(rawShuntUnsigned);
    m.voltageV = ina238math::busVoltageV(rawBus);
    m.currentA = ina238math::currentA(rawShunt, shuntOhm_, narrowRange_);
    m.valid = m.voltageV >= 0.0 && m.voltageV <= 20.0;
    return m;
}

bool Ina238::ping() {
    wire_.beginTransmission(address_);
    return wire_.endTransmission() == 0;
}

bool Ina238::write16(uint8_t reg, uint16_t value) {
    wire_.beginTransmission(address_);
    wire_.write(reg);
    wire_.write(static_cast<uint8_t>(value >> 8));
    wire_.write(static_cast<uint8_t>(value & 0xff));
    return wire_.endTransmission() == 0;
}

bool Ina238::read16(uint8_t reg, uint16_t& value) {
    wire_.beginTransmission(address_);
    wire_.write(reg);
    if (wire_.endTransmission(false) != 0) return false;

    if (wire_.requestFrom(static_cast<int>(address_), 2) != 2) return false;
    const uint8_t msb = wire_.read();
    const uint8_t lsb = wire_.read();
    value = (static_cast<uint16_t>(msb) << 8) | lsb;
    return true;
}

} // namespace bs
