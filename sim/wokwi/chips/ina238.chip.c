#include "wokwi-api.h"
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct {
  i2c_dev_t i2c;
  uint8_t reg;
  uint8_t write_index;
  uint8_t config_bytes[2];
  uint16_t config;
  uint8_t read_index;
  uint32_t attr_bus_voltage;
  uint32_t attr_current_a;
  uint32_t attr_present;
} chip_state_t;

static uint16_t clamp_u16(double x) {
  if (x < 0.0) return 0;
  if (x > 65535.0) return 65535;
  return (uint16_t)llround(x);
}

static int16_t clamp_i16(double x) {
  if (x < -32768.0) return -32768;
  if (x > 32767.0) return 32767;
  return (int16_t)llround(x);
}

static uint16_t current_register_value(chip_state_t *chip) {
  const bool narrow = (chip->config & (1u << 4)) != 0;
  const double lsb_v = narrow ? 1.25e-6 : 5.0e-6;
  const double current_a = attr_read_float(chip->attr_current_a);
  const double shunt_ohm = 0.000100; // 500 A / 50 mV
  const int16_t raw = clamp_i16((current_a * shunt_ohm) / lsb_v);
  return (uint16_t)raw;
}

static uint16_t bus_register_value(chip_state_t *chip) {
  const double bus_v = attr_read_float(chip->attr_bus_voltage);
  return clamp_u16(bus_v / 3.125e-3);
}

static uint16_t register_value(chip_state_t *chip, uint8_t reg) {
  switch (reg) {
    case 0x00: return chip->config;
    case 0x04: return current_register_value(chip); // VSHUNT
    case 0x05: return bus_register_value(chip);     // VBUS
    default: return 0;
  }
}

static bool on_i2c_connect(void *user_data, uint32_t address, bool read) {
  chip_state_t *chip = (chip_state_t *)user_data;
  (void)address;
  (void)read;
  chip->read_index = 0;
  chip->write_index = 0;
  return attr_read(chip->attr_present) != 0;
}

static uint8_t on_i2c_read(void *user_data) {
  chip_state_t *chip = (chip_state_t *)user_data;
  const uint16_t value = register_value(chip, chip->reg);
  const uint8_t result = chip->read_index == 0 ? (uint8_t)(value >> 8) : (uint8_t)(value & 0xff);
  chip->read_index = (chip->read_index + 1) & 1;
  return result;
}

static bool on_i2c_write(void *user_data, uint8_t data) {
  chip_state_t *chip = (chip_state_t *)user_data;
  if (chip->write_index == 0) {
    chip->reg = data;
    chip->write_index = 1;
    return true;
  }

  if (chip->reg == 0x00) {
    if (chip->write_index == 1) chip->config_bytes[0] = data;
    if (chip->write_index == 2) {
      chip->config_bytes[1] = data;
      chip->config = ((uint16_t)chip->config_bytes[0] << 8) | chip->config_bytes[1];
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
  chip->config = 0;
  chip->attr_bus_voltage = attr_init_float("busVoltage", 12.70f);
  chip->attr_current_a = attr_init_float("currentA", 0.0f);
  chip->attr_present = attr_init("sensorPresent", 1);

  const i2c_config_t config = {
    .address = 0x40,
    .scl = pin_init("SCL", INPUT_PULLUP),
    .sda = pin_init("SDA", INPUT_PULLUP),
    .connect = on_i2c_connect,
    .read = on_i2c_read,
    .write = on_i2c_write,
    .disconnect = on_i2c_disconnect,
    .user_data = chip,
  };

  chip->i2c = i2c_init(&config);
}
