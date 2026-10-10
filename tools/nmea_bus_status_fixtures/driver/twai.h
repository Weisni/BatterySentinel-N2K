#pragma once
#include <Arduino.h>
#include <driver/gpio.h>

using esp_err_t = int;
constexpr esp_err_t ESP_OK = 0;
constexpr int TWAI_MODE_NORMAL = 0;
constexpr uint32_t TWAI_ALERT_BUS_OFF = 1, TWAI_ALERT_BUS_RECOVERED = 2;
constexpr uint32_t TWAI_ALERT_RX_QUEUE_FULL = 4, TWAI_ALERT_TX_FAILED = 8;
constexpr uint32_t TWAI_MSG_FLAG_EXTD = 1, TWAI_MSG_FLAG_RTR = 2;

enum twai_state_t {
    TWAI_STATE_STOPPED, TWAI_STATE_RUNNING, TWAI_STATE_BUS_OFF, TWAI_STATE_RECOVERING
};
struct twai_general_config_t {
    gpio_num_t tx_io, rx_io;
    int mode;
    uint32_t tx_queue_len = 0, rx_queue_len = 0, alerts_enabled = 0;
};
struct twai_timing_config_t {};
struct twai_filter_config_t {};
struct twai_message_t {
    uint32_t identifier = 0, flags = 0;
    uint8_t data_length_code = 0, data[8]{};
};
struct twai_status_info_t {
    twai_state_t state = TWAI_STATE_STOPPED;
    uint32_t tx_error_counter = 0, rx_error_counter = 0, tx_failed_count = 0;
};

#define TWAI_GENERAL_CONFIG_DEFAULT(tx, rx, mode) twai_general_config_t{tx, rx, mode}
#define TWAI_TIMING_CONFIG_250KBITS() twai_timing_config_t{}
#define TWAI_FILTER_CONFIG_ACCEPT_ALL() twai_filter_config_t{}

esp_err_t twai_driver_install(const twai_general_config_t*, const twai_timing_config_t*,
                             const twai_filter_config_t*);
esp_err_t twai_start();
esp_err_t twai_driver_uninstall();
esp_err_t twai_transmit(const twai_message_t*, TickType_t);
esp_err_t twai_receive(twai_message_t*, TickType_t);
esp_err_t twai_get_status_info(twai_status_info_t*);
