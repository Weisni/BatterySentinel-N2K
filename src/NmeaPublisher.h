#pragma once

#include <Arduino.h>
#include <BatteryCore.h>
#include <OrionFrame.h>
#include <BridgeTime.h>
#include <BridgeNmeaAlerts.h>
#include <freertos/FreeRTOS.h>
#include "Nmea2000Twai.h"

class tN2kMsg;

namespace bs {

class NmeaPublisher {
public:
    void begin(uint32_t uniqueNumber, bool orionBridge = false);
    void process();

    void publishFast(uint8_t batteryInstance, const BatterySnapshot& state, bool measurementValid);
    void publishDc(uint8_t batteryInstance, const BatterySnapshot& state, bool measurementValid);
    void publishOrion(const orion::Telemetry& state, uint32_t now,
                      uint8_t outputInstance, uint8_t inputInstance);
    void publishOrionMetadata(uint8_t outputInstance, uint8_t inputInstance);
    uint32_t transmitted() const { return transmitted_; }
    uint32_t failed() const { return failed_; }
    // Main-loop only. Safe before begin() or with NMEA disabled/uninstalled.
    // For reception age use uint32_t(now - lastRxMs), guarded by received.
    BusStatus busStatus() const;
    // Latest attempts for the five Orion telemetry messages, not network
    // management traffic. SendMsg acceptance does not confirm bus delivery.
    String monitorJson(uint8_t outputInstance, uint8_t inputInstance) const;
    time::Snapshot clockSnapshot() const;
    String timeJson() const;
    static constexpr bool alertsSupported() { return true; }
    // Main-loop only. JSON/snapshot readers may run on the HTTPS task.
    void setAlerts(const alerts::Input (&inputs)[alerts::kSlots], bool enabled);
    String deliveryJson() const;
    bool drainRemoteAck(uint8_t&, uint32_t&) { return false; }
    // Thread-safe restart gate; main must keep process() running until ready.
    void prepareForRestart();
    bool restartReady() const;

private:
    struct MessageSnapshot {
        uint32_t attemptedAtMs = 0;
        uint8_t instance = 0;
        bool attempted = false;
        bool accepted = false;
        double fields[8]{};
    };
    void sendOrion(const tN2kMsg& msg, size_t slot);
    static void handleMessage(const tN2kMsg& msg);
    void receive(const tN2kMsg& msg);
    void publishServiceSnapshot();

    uint8_t sid_ = 0;
    uint32_t transmitted_ = 0;
    uint32_t failed_ = 0;
    MessageSnapshot snapshots_[5]{};
    time::Clock clock_{};
    time::Clock publishedClock_{};
    alerts::Delivery alertDelivery_{};
    alerts::Status publishedDelivery_{};
    uint64_t sourceNames_[254]{};
    uint64_t lastTimeRequestMs_ = 0;
    uint32_t timeRequestsAccepted_ = 0, timeRequestsFailed_ = 0;
    uint32_t publishedRequestsAccepted_ = 0, publishedRequestsFailed_ = 0;
    bool timeRequested_ = false, begun_ = false;
    bool restartRequested_ = false;
    uint64_t restartRequestedAtMs_ = 0;
    mutable portMUX_TYPE snapshotMux_ = portMUX_INITIALIZER_UNLOCKED;
};

} // namespace bs
