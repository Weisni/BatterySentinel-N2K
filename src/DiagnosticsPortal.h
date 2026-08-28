#pragma once

#include <Arduino.h>
#include <WebServer.h>
#include <BatteryCore.h>

#include "SettingsStore.h"

namespace bs {

class DiagnosticsPortal {
public:
    DiagnosticsPortal();

    void begin(DeviceSettings& settings,
               SettingsStore& store,
               BatteryCore& systemBattery,
               BatteryCore& bowBattery);
    void loop();
    void stop();
    bool active() const { return active_; }

private:
    WebServer server_{80};
    DeviceSettings* settings_ = nullptr;
    SettingsStore* store_ = nullptr;
    BatteryCore* systemBattery_ = nullptr;
    BatteryCore* bowBattery_ = nullptr;

    bool active_ = false;
    bool everConnected_ = false;
    uint32_t startedAtMs_ = 0;
    uint32_t lastClientSeenMs_ = 0;
    String ssid_;
    String password_;

    void configureRoutes();
    void handleRoot();
    void handleLive();
    void handleSave();
    void handleUpdateFinished();
    void handleUpdateUpload();

    static String htmlEscape(const String& value);
    static String chemistryOptions(BatteryChemistry selected);
    static BatteryChemistry chemistryFromArg(const String& value);
};

} // namespace bs
