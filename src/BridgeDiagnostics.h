#pragma once

#include <Arduino.h>
#include <BridgeInsights.h>
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>

namespace bs {

// The main loop owns observation updates; HTTPS may configure or acknowledge.
// Copy bounded snapshots under a task mutex and format JSON after releasing it.
class BridgeDiagnostics {
public:
    void begin(const insights::Config& config);
    bool available() const { return mutex_ != nullptr; }
    void update(const orion::Telemetry& telemetry, bool configured);
    bool configure(const insights::Config& config);
    bool acknowledge(uint8_t slot, uint32_t generation);
    bool popTransition(insights::Transition& transition);
    void snapshot(insights::Snapshot& out) const;
    insights::Config config() const;
    String insightsJson() const;
    String notificationsJson(bool storageValid, const String& delivery, bool nmeaSupported) const;

private:
    insights::Engine engine_;
    mutable SemaphoreHandle_t mutex_ = nullptr;
};

} // namespace bs
