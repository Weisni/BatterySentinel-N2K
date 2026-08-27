#include "Ina238.h"

namespace bs {

bool Ina238::begin() {
    present_ = ping();
    if (!present_) return false;

    // CONFIG=0 keeps ADCRANGE=0 (±163.84 mV) and the default continuous conversion path.
    // We intentionally compute current from raw VSHUNT instead of the calibrated CURRENT
    // register so each channel can use its exact measured shunt resistance later.
    present_ = write16(REG_CONFIG, 0x0000);
    return present_;
}

Measurement Ina238::read() {
    Measurement m{};
    if (!present_ || shuntOhm_ <= 0.0) return m;

    uint16_t rawBus = 0;
    uint16_t rawShuntUnsigned = 0;
    if (!read16(REG_VBUS, rawBus) || !read16(REG_VSHUNT, rawShuntUnsigned)) {
        present_ = ping();
        return m;
    }

    const int16_t rawShunt = static_cast<int16_t>(rawShuntUnsigned);
    const double shuntV = static_cast<double>(rawShunt) * SHUNT_LSB_V;

    m.voltageV = static_cast<double>(rawBus) * BUS_LSB_V;
    m.currentA = shuntV / shuntOhm_;
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
