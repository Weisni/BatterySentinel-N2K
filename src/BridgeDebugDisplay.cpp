#if defined(BATTERYSENTINEL_DEBUG_OLED)
#include "BridgeDebugDisplay.h"
#include "config.h"
#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

namespace {
constexpr uint8_t kAddress = 0x3c;
constexpr uint16_t kTimeoutMs = 20;
// No GPIOs are handed to U8g2: Wire owns the already configured I2C pins.
U8G2_SSD1306_72X40_ER_F_HW_I2C oled(U8G2_R0, U8X8_PIN_NONE);
bool transferFailed = false;

static_assert(bs::config::PIN_CAN_TX != bs::config::PIN_I2C_SDA &&
              bs::config::PIN_CAN_TX != bs::config::PIN_I2C_SCL &&
              bs::config::PIN_CAN_RX != bs::config::PIN_I2C_SDA &&
              bs::config::PIN_CAN_RX != bs::config::PIN_I2C_SCL,
              "OLED and CAN cannot share pins");

// Unlike U8g2's default Wire callback, propagate the first I2C failure and skip
// the remaining frame transactions. Wire's 128-byte buffer fits a 72-byte row.
uint8_t transfer(u8x8_t*, uint8_t message, uint8_t size, void* data) {
    if (transferFailed) return 0;
    switch (message) {
    case U8X8_MSG_BYTE_INIT: break; // Wire initialized before the address probe.
    case U8X8_MSG_BYTE_START_TRANSFER:
        Wire.beginTransmission(kAddress);
        break;
    case U8X8_MSG_BYTE_SEND:
        if (Wire.write(static_cast<uint8_t*>(data), size) != size) {
            Wire.endTransmission(); // Release Wire's transmission lock as well.
            transferFailed = true;
        }
        break;
    case U8X8_MSG_BYTE_END_TRANSFER:
        transferFailed = Wire.endTransmission() != 0;
        break;
    case U8X8_MSG_BYTE_SET_DC: break;
    default: return 0;
    }
    return transferFailed ? 0 : 1;
}

void paint(const bs::debugdisplay::Frame& frame, bool border = false) {
    oled.clearBuffer();
    oled.setFont(u8g2_font_5x7_tf);
    oled.drawStr(0, 7, frame.status);
    oled.drawHLine(0, 9, 72);
    oled.setFont(u8g2_font_6x10_tf);
    for (uint8_t i = 0; i < 3; ++i) oled.drawStr(0, 17 + 10 * i, frame.rows[i]);
    if (border) oled.drawFrame(0, 0, 72, 40);
    oled.sendBuffer();
}
} // namespace

namespace bs {
bool BridgeDebugDisplay::begin() {
    transferFailed = false;
    if (Wire.setBufferSize(128) < 128 ||
        !Wire.begin(config::PIN_I2C_SDA, config::PIN_I2C_SCL, 400000)) {
        Serial.println("OLED unavailable: I2C initialization failed");
        return false;
    }
    Wire.setTimeOut(kTimeoutMs);
    Wire.beginTransmission(kAddress);
    if (Wire.endTransmission() != 0) {
        Serial.println("OLED unavailable at 0x3C; bridge continues");
        return false;
    }
    oled.getU8x8()->byte_cb = transfer;
    oled.setI2CAddress(kAddress << 1);
    oled.begin();
    oled.setContrast(128);
    ready_ = !transferFailed;
    if (ready_) boot("USB / boot");
    else Serial.println("OLED initialization failed; bridge continues");
    return ready_;
}

void BridgeDebugDisplay::boot(const char* stage) {
    if (!ready_) return;
    debugdisplay::Frame frame{};
    snprintf(frame.status, sizeof(frame.status), "W- N- O- T-");
    snprintf(frame.rows[0], sizeof(frame.rows[0]), "Orion debug");
    snprintf(frame.rows[1], sizeof(frame.rows[1]), "%.12s", stage);
    snprintf(frame.rows[2], sizeof(frame.rows[2]), "72x40 OLED");
    paint(frame, true);
    ready_ = !transferFailed;
    if (!ready_) Serial.println("OLED boot frame failed; display disabled until reboot, bridge continues");
}

bool BridgeDebugDisplay::due(uint32_t now) {
    return ready_ && pager_.due(now);
}

void BridgeDebugDisplay::show(const debugdisplay::Snapshot& snapshot) {
    if (!ready_) return;
    debugdisplay::Frame frame{};
    pager_.render(snapshot, frame);
    paint(frame);
    if (transferFailed) {
        ready_ = false;
        Serial.println("OLED I2C failed; display disabled until reboot, bridge continues");
    }
}
} // namespace bs
#endif
