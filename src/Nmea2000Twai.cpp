#include "Nmea2000Twai.h"

#include <cstring>

namespace bs {

Nmea2000Twai::Nmea2000Twai(gpio_num_t txPin, gpio_num_t rxPin)
    : txPin_(txPin), rxPin_(rxPin) {}

bool Nmea2000Twai::CANOpen() {
    if (driverReady_) return true;

    twai_general_config_t general = TWAI_GENERAL_CONFIG_DEFAULT(txPin_, rxPin_, TWAI_MODE_NORMAL);
    general.tx_queue_len = 20;
    general.rx_queue_len = 40;
    general.alerts_enabled = TWAI_ALERT_BUS_OFF |
                             TWAI_ALERT_BUS_RECOVERED |
                             TWAI_ALERT_RX_QUEUE_FULL |
                             TWAI_ALERT_TX_FAILED;

    const twai_timing_config_t timing = TWAI_TIMING_CONFIG_250KBITS();
    const twai_filter_config_t filter = TWAI_FILTER_CONFIG_ACCEPT_ALL();

    esp_err_t err = twai_driver_install(&general, &timing, &filter);
    if (err != ESP_OK) {
        Serial.printf("TWAI install failed: %d\n", static_cast<int>(err));
        return false;
    }

    err = twai_start();
    if (err != ESP_OK) {
        Serial.printf("TWAI start failed: %d\n", static_cast<int>(err));
        twai_driver_uninstall();
        return false;
    }

    driverReady_ = true;
    Serial.printf("TWAI started at 250 kbit/s, TX=%d RX=%d\n",
                  static_cast<int>(txPin_), static_cast<int>(rxPin_));
    return true;
}

bool Nmea2000Twai::CANSendFrame(unsigned long id,
                                unsigned char len,
                                const unsigned char* buf,
                                bool waitSent) {
    if (!driverReady_ || len > 8 || buf == nullptr) return false;

    twai_message_t msg{};
    msg.identifier = static_cast<uint32_t>(id) & 0x1FFFFFFFu;
    msg.data_length_code = len;
    msg.flags = TWAI_MSG_FLAG_EXTD;
    std::memcpy(msg.data, buf, len);

    // NMEA2000 already has its own frame buffering. The driver queue therefore only
    // gets a short bounded wait when requested, never an unbounded block.
    const TickType_t timeout = waitSent ? pdMS_TO_TICKS(10) : 0;
    if (twai_transmit(&msg, timeout) != ESP_OK) {
        ++txFailures_;
        return false;
    }
    return true;
}

bool Nmea2000Twai::CANGetFrame(unsigned long& id,
                               unsigned char& len,
                               unsigned char* buf) {
    if (!driverReady_ || buf == nullptr) return false;

    twai_message_t msg{};
    while (twai_receive(&msg, 0) == ESP_OK) {
        // NMEA 2000 uses 29-bit extended data frames. Ignore standard frames and RTR.
        if ((msg.flags & TWAI_MSG_FLAG_EXTD) == 0 ||
            (msg.flags & TWAI_MSG_FLAG_RTR) != 0 ||
            msg.data_length_code > 8) {
            ++rxDroppedFrames_;
            continue;
        }

        id = static_cast<unsigned long>(msg.identifier & 0x1FFFFFFFu);
        len = msg.data_length_code;
        std::memcpy(buf, msg.data, len);
        return true;
    }
    return false;
}

} // namespace bs
