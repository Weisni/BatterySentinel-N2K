#pragma once
// A transport exerciser, not an OLED emulator. It deliberately continues all
// callback messages after an error so the production callback must suppress I/O.
#include <cstdint>
struct u8x8_t;
using ByteCallback = uint8_t (*)(u8x8_t*, uint8_t, uint8_t, void*);
struct u8x8_t { ByteCallback byte_cb = nullptr; };
enum { U8X8_MSG_BYTE_INIT, U8X8_MSG_BYTE_START_TRANSFER, U8X8_MSG_BYTE_SEND,
       U8X8_MSG_BYTE_END_TRANSFER, U8X8_MSG_BYTE_SET_DC };
inline constexpr uint8_t U8X8_PIN_NONE = 255;
inline constexpr int U8G2_R0 = 0;
inline constexpr uint8_t u8g2_font_5x7_tf[] = {0};
inline constexpr uint8_t u8g2_font_6x10_tf[] = {1};
class U8G2_SSD1306_72X40_ER_F_HW_I2C {
public:
    U8G2_SSD1306_72X40_ER_F_HW_I2C(int, uint8_t) {}
    u8x8_t* getU8x8() { return &device_; }
    void setI2CAddress(uint8_t) {}
    void begin() { device_.byte_cb(&device_, U8X8_MSG_BYTE_INIT, 0, nullptr); packet(2); }
    void setContrast(uint8_t) { packet(2); }
    void clearBuffer() {}
    void setFont(const uint8_t*) {}
    void drawStr(int, int, const char*) {}
    void drawHLine(int, int, int) {}
    void drawFrame(int, int, int, int) {}
    void sendBuffer() { for (int row = 0; row < 5; ++row) packet(72); }
private:
    u8x8_t device_;
    void packet(uint8_t size) {
        uint8_t bytes[72]{};
        device_.byte_cb(&device_, U8X8_MSG_BYTE_START_TRANSFER, 0, nullptr);
        device_.byte_cb(&device_, U8X8_MSG_BYTE_SEND, 1, bytes);
        device_.byte_cb(&device_, U8X8_MSG_BYTE_SEND, size, bytes);
        device_.byte_cb(&device_, U8X8_MSG_BYTE_END_TRANSFER, 0, nullptr);
    }
};
