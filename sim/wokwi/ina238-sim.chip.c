#include "wokwi-api.h"
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

// Minimal INA238 model for BatterySentinel firmware bring-up.
// Implemented registers:
//   0x00 CONFIG (ADCRANGE bit 4)
//   0x04 VSHUNT
//   0x05 VBUS
// Shunt resistance is fixed to the V1 system value: 100 uOhm (500 A / 50 mV).

typedef struct {
  uint8_t reg;
  uint8_t write_index;
  uint8_t read_index;
  uint16_t config;
  uint16_t pending_write;
  uint32_t attr_voltage;
  uint32_t attr_current;
  uint32_t attr_present;
} chip_state_t;

static uint16_t reg_value(chip_state_t *chip, uint8_t reg) {
  const float voltage = attr_read_float(chip->attr_voltage);
  const float current = attr_read_float(chip->attr_current);

  if (reg == 0x00) {
    return chip->config;
  }

  if (reg == 0x05) {
    // INA238 VBUS LSB = 3.125 mV.
    long raw = lroundf(voltage / 0.003125f);
    if (raw < 0) raw = 0;
    if (raw > 65535) raw = 65535;
    return (uint16_t)raw;
  }

  if (reg == 0x04) {
    // Vshunt = I * 100 uOhm. ADCRANGE=0: 5 uV/LSB, ADCRANGE=1: 1.25 uV/LSB.
    const bool narrow = (chip->config & (1u << 4)) != 0;
    const float lsb = narrow ? 1.25e-6f : 5.0e-6f;
    const float vshunt = current * 0.000100f;
    long raw = lroundf(vshunt / lsb);
    if (raw < -32768) raw = -32768;
    if (raw > 32767) raw = 32767;
    return (uint16_t)(int16_t)raw;
  }

  return 0;
}

static bool on_i2c_connect(void *user_data, uint32_t address, bool read) {
  chip_state_t *chip = (chip_state_t *)user_data;
  (void)address;
  (void)read;
  chip->write_index = 0;
  chip->read_index = 0;
  return attr_read(chip->attr_present) != 0;
}

static uint8_t on_i2c_read(void *user_data) {
  chip_state_t *chip = (chip_state_t *)user_data;
  const uint16_t value = reg_value(chip, chip->reg);
  const uint8_t result = chip->read_index == 0 ? (uint8_t)(value >> 8) : (uint8_t)(value & 0xff);
  chip->read_index = (chip->read_index + 1) & 1;
  return result;
}

static bool on_i2c_write(void *user_data, uint8_t data) {
  chip_state_t *chip = (chip_state_t *)user_data;

  if (chip->write_index == 0) {
    chip->reg = data;
  } else if (chip->write_index == 1) {
    chip->pending_write = (uint16_t)data << 8;
  } else if (chip->write_index == 2) {
    chip->pending_write |= data;
    if (chip->reg == 0x00) {
      chip->config = chip->pending_write;
    }
  }

  chip->write_index++;
  return true;
}

static void on_i2c_disconnect(void *user_data) {
  chip_state_t *chip = (chip_state_t *)user_data;
  chip->write_index = 0;
  chip->read_index = 0;
}

void chip_init(void) {
  chip_state_t *chip = calloc(1, sizeof(chip_state_t));
  chip->config = 0x0000;
  chip->attr_voltage = attr_init_float("voltageV", 12.60f);
  chip->attr_current = attr_init_float("currentA", 0.0f);
  chip->attr_present = attr_init("present", 1);

  const i2c_config_t i2c_config = {
    .user_data = chip,
    .address = 0x40,
    .scl = pin_init("SCL", INPUT_PULLUP),
    .sda = pin_init("SDA", INPUT_PULLUP),
    .connect = on_i2c_connect,
    .read = on_i2c_read,
    .write = on_i2c_write,
    .disconnect = on_i2c_disconnect,
  };
  i2c_init(&i2c_config);
}
