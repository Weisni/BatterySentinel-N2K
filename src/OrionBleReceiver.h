#pragma once

#include <Arduino.h>
#include <BLEAdvertisedDevice.h>
#include <BLEScan.h>
#include <OrionFrame.h>
#include <freertos/FreeRTOS.h>
#include <freertos/queue.h>

namespace bs {

class OrionBleReceiver final : private BLEAdvertisedDeviceCallbacks {
public:
    bool begin(const String& mac, const uint8_t key[16]);
    bool poll(orion::Telemetry& telemetry);
    orion::Telemetry snapshot(const orion::Telemetry& telemetry) const;
    uint32_t receivedFrames() const { return receivedFrames_; }
    uint32_t rejectedFrames() const { return rejectedFrames_; }
    uint32_t droppedFrames() const { return droppedFrames_; }
    uint32_t duplicateFrames() const { return duplicateFrames_; }
    uint32_t startupFailures() const { return startupFailures_; }
    uint32_t errors() const { return rejectedFrames_ + droppedFrames_ + startupFailures_; }
    const char* lastProblem() const { return lastProblem_; }

private:
    struct Frame {
        uint8_t bytes[32]{};
        uint8_t length = 0;
        uint32_t atMs = 0;
        int16_t rssi = 0;
    };

    void onResult(BLEAdvertisedDevice device) override;
    enum class DecodeResult { Accepted, Duplicate, Rejected };
    DecodeResult decode(const Frame& frame, orion::Telemetry& telemetry);

    QueueHandle_t queue_ = nullptr;
    BLEScan* scan_ = nullptr;
    String mac_;
    uint8_t key_[16]{};
    bool ready_ = false;
    bool haveCounter_ = false;
    uint16_t lastCounter_ = 0;
    uint32_t receivedFrames_ = 0;
    uint32_t rejectedFrames_ = 0;
    uint32_t droppedFrames_ = 0;
    uint32_t duplicateFrames_ = 0;
    uint32_t startupFailures_ = 0;
    const char* lastProblem_ = "Waiting for data";
    mutable portMUX_TYPE telemetryMux_ = portMUX_INITIALIZER_UNLOCKED;
};

} // namespace bs
