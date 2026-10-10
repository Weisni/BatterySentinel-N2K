// Native pixel preview of the actual model with the firmware's U8g2 fonts.
// This exercises graphics only; it does not simulate an OLED controller or I2C.
#include "DebugDisplayModel.h"
#include "u8g2.h"
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <vector>

namespace {
using namespace bs::debugdisplay;
struct Surface {
    u8g2_t graphics{};
    u8x8_display_info_t info{};
    std::vector<uint8_t> buffer;
    unsigned width, height;
    Surface(unsigned w, unsigned h) : buffer(w * h / 8), width(w), height(h) {
        info.tile_width = uint8_t(w / 8); info.tile_height = uint8_t(h / 8);
        info.pixel_width = uint16_t(w); info.pixel_height = uint16_t(h);
        u8x8_SetupDefaults(&graphics.u8x8);
        graphics.u8x8.display_info = &info;
        u8g2_SetupBuffer(&graphics, buffer.data(), uint8_t(h / 8),
                        u8g2_ll_hvline_vertical_top_lsb, U8G2_R0);
        u8g2_ClearBuffer(&graphics);
    }
    bool pixel(unsigned x, unsigned y) const { return (buffer[x + (y / 8) * width] >> (y % 8)) & 1; }
};

void checkedText(Surface& target, const uint8_t* font, unsigned baseline,
                 const char* value, unsigned top, unsigned bottom) {
    // Draw on a larger real U8g2 canvas first: this detects actual lit pixels
    // falling outside the 72-pixel row or its allotted vertical band.
    Surface probe(96, 64);
    u8g2_SetFont(&probe.graphics, font);
    u8g2_DrawStr(&probe.graphics, 8, baseline + 8, value);
    for (unsigned y = 0; y < probe.height; ++y)
        for (unsigned x = 0; x < probe.width; ++x)
            if (probe.pixel(x, y) && (x < 8 || x >= 80 || y < top + 8 || y >= bottom + 8))
                throw std::runtime_error(std::string("Text exceeds display band: ") + value);
    u8g2_SetFont(&target.graphics, font);
    if (u8g2_GetStrWidth(&target.graphics, value) > 72)
        throw std::runtime_error(std::string("Text is wider than display: ") + value);
    u8g2_DrawStr(&target.graphics, 0, baseline, value);
}

void writeFrame(const std::filesystem::path& directory, std::ofstream& manifest,
                unsigned index, const char* caption, const Snapshot& snapshot, uint8_t page) {
    Pager pager;
    pager.due(0);
    for (uint8_t i = 1; i <= page; ++i) pager.due(i * 2000);
    Frame frame;
    pager.render(snapshot, frame);
    Surface target(72, 40);
    checkedText(target, u8g2_font_5x7_tf, 7, frame.status, 0, 9);
    u8g2_DrawHLine(&target.graphics, 0, 9, 72);
    for (unsigned i = 0; i < 3; ++i)
        checkedText(target, u8g2_font_6x10_tf, 17 + i * 10, frame.rows[i], 10 + i * 10, 20 + i * 10);
    const std::string filename = "frame-" + std::to_string(index) + ".pgm";
    std::ofstream pixels(directory / filename, std::ios::binary);
    pixels << "P5\n72 40\n255\n";
    for (unsigned y = 0; y < 40; ++y)
        for (unsigned x = 0; x < 72; ++x) pixels.put(target.pixel(x, y) ? char(255) : char(0));
    if (!pixels) throw std::runtime_error("Cannot write raster frame");
    manifest << filename << '\t' << caption << '\t' << frame.status;
    for (const auto& row : frame.rows) manifest << '\t' << row;
    manifest << '\n';
}

Snapshot healthy() {
    Snapshot s;
    s.nowMs = 20000; s.uptimeMs = 20000; s.serviceReady = true;
    s.canRunning = true; s.canReceived = true; s.canLastReceivedMs = 19700;
    s.canReceivedFrames = 4567; s.canTxFailures = 8;
    s.orionConfigured = true; s.orionReceived = true; s.orionReceivedAtMs = 19000;
    s.orionRssi = -67; s.orionAccepted = 321; s.orionErrors = 2;
    s.input.voltage = {12.34, true}; s.input.current = {5.6, true};
    s.output.voltage = {13.5, true}; s.output.current = {5.0, true};
    s.timeQuality = TimeQuality::Synchronized; s.utcValid = true;
    s.utcMs = 1780317296000ULL; s.timeAgeMs = 1000;
    s.heapFree = 102400; s.heapMinimum = 51200; s.wifiClients = 1; s.httpsClients = 1;
    s.activeAlerts = 2; s.unacknowledgedAlerts = 1;
    s.chargerState = 3; s.chargerError = 0; s.notificationsEnabled = true;
    return s;
}
} // namespace

int main(int argc, char** argv) {
    try {
        if (argc != 2) throw std::runtime_error("Usage: render_debug_oled <frame-directory>");
        const std::filesystem::path directory(argv[1]);
        std::filesystem::create_directories(directory);
        std::ofstream manifest(directory / "frames.tsv");
        unsigned index = 0;
        const char* captions[] = {"1 / Input", "2 / Output", "3 / BLE", "4 / CAN", "5 / UTC", "6 / Memory", "7 / Alerts"};
        for (uint8_t page = 0; page < 7; ++page) writeFrame(directory, manifest, index++, captions[page], healthy(), page);
        writeFrame(directory, manifest, index++, "Startup / no data", Snapshot{}, 0);
        auto s = healthy(); s.nowMs = 40000;
        writeFrame(directory, manifest, index++, "Stale / quiet CAN", s, 1);
        s = healthy(); s.canBusOff = true; s.canTxErrorCount = 128;
        writeFrame(directory, manifest, index++, "CAN fault", s, 3);
        s = healthy(); s.timeQuality = TimeQuality::Holdover; s.timeAgeMs = 45000;
        writeFrame(directory, manifest, index++, "UTC holdover", s, 4);
        s = healthy(); s.timeQuality = TimeQuality::Quarantined;
        writeFrame(directory, manifest, index++, "UTC quarantine", s, 4);
        s = healthy(); s.notificationsEnabled = false; s.activeAlerts = 0; s.unacknowledgedAlerts = 0;
        writeFrame(directory, manifest, index++, "Notifications disabled", s, 6);
        s = healthy(); s.output.voltage = {65.0, true}; s.output.current = {-150.0, true};
        writeFrame(directory, manifest, index++, "Formatting limit / signed power", s, 1);
        s = healthy(); s.canReceivedFrames = UINT64_MAX; s.canTxFailures = UINT64_MAX;
        s.canTxErrorCount = UINT32_MAX; s.canRxErrorCount = UINT32_MAX;
        writeFrame(directory, manifest, index++, "Saturated CAN counters", s, 3);
        s = healthy(); s.heapFree = UINT32_MAX; s.heapMinimum = UINT32_MAX;
        s.wifiClients = UINT32_MAX; s.httpsClients = UINT32_MAX;
        writeFrame(directory, manifest, index++, "Saturated memory / clients", s, 5);
        if (!manifest) throw std::runtime_error("Cannot write frame manifest");
        std::cout << index << " frames rendered; actual glyph pixels fit all display bands.\n";
        return 0;
    } catch (const std::exception& e) { std::cerr << e.what() << '\n'; return 1; }
}
