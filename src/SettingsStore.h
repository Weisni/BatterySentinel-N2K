#pragma once

#include <Arduino.h>
#include <Preferences.h>
#include <BatteryProfiles.h>

namespace bs {

struct DeviceSettings {
    uint32_t schemaVersion = 1;
    BatteryProfile system = makeProfile(BatteryChemistry::FloodedLeadAcid, 80.0);
    BatteryProfile bow = makeProfile(BatteryChemistry::Unknown, 0.0);

    double systemMaxCurrentA = 350.0;
    double bowMaxCurrentA = 250.0;
    double systemLowVoltageLoadedV = 9.5;
    double bowLowVoltageLoadedV = 9.5;

    bool bowChannelEnabled = false;
};

class SettingsStore {
public:
    bool begin();
    DeviceSettings load();
    bool save(const DeviceSettings& settings);
    bool factoryReset();

private:
    Preferences prefs_;

    BatteryProfile loadProfile(const char* prefix, const BatteryProfile& defaults);
    void saveProfile(const char* prefix, const BatteryProfile& profile);
};

} // namespace bs
