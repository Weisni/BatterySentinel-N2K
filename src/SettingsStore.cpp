#include "SettingsStore.h"

namespace bs {

namespace {

String key(const char* prefix, const char* suffix) {
    String k(prefix);
    k += suffix;
    return k;
}

BatteryChemistry clampChemistry(uint8_t raw) {
    if (raw > static_cast<uint8_t>(BatteryChemistry::Custom)) {
        return BatteryChemistry::Unknown;
    }
    return static_cast<BatteryChemistry>(raw);
}

} // namespace

bool SettingsStore::begin() {
    return prefs_.begin("bs-config", false);
}

DeviceSettings SettingsStore::load() {
    DeviceSettings s;

    s.schemaVersion = prefs_.getUInt("schema", 1);
    s.system = loadProfile("sys_", s.system);
    s.bow = loadProfile("bow_", s.bow);

    s.systemMaxCurrentA = prefs_.getDouble("sys_imax", s.systemMaxCurrentA);
    s.bowMaxCurrentA = prefs_.getDouble("bow_imax", s.bowMaxCurrentA);
    s.systemLowVoltageLoadedV = prefs_.getDouble("sys_uvload", s.systemLowVoltageLoadedV);
    s.bowLowVoltageLoadedV = prefs_.getDouble("bow_uvload", s.bowLowVoltageLoadedV);
    s.bowChannelEnabled = prefs_.getBool("bow_enable", s.bowChannelEnabled);

    // Unknown chemistry intentionally disables SOC. This prevents an unconfigured
    // second battery from accidentally inheriting the system battery model.
    if (s.system.chemistry == BatteryChemistry::Unknown || s.system.capacityAh <= 0.0) {
        s.system.socEnabled = false;
    }
    if (s.bow.chemistry == BatteryChemistry::Unknown || s.bow.capacityAh <= 0.0) {
        s.bow.socEnabled = false;
    }

    return s;
}

bool SettingsStore::save(const DeviceSettings& s) {
    bool ok = true;
    ok &= prefs_.putUInt("schema", s.schemaVersion) > 0;
    saveProfile("sys_", s.system);
    saveProfile("bow_", s.bow);

    ok &= prefs_.putDouble("sys_imax", s.systemMaxCurrentA) > 0;
    ok &= prefs_.putDouble("bow_imax", s.bowMaxCurrentA) > 0;
    ok &= prefs_.putDouble("sys_uvload", s.systemLowVoltageLoadedV) > 0;
    ok &= prefs_.putDouble("bow_uvload", s.bowLowVoltageLoadedV) > 0;
    ok &= prefs_.putBool("bow_enable", s.bowChannelEnabled) > 0;
    return ok;
}

bool SettingsStore::factoryReset() {
    return prefs_.clear();
}

BatteryProfile SettingsStore::loadProfile(const char* prefix, const BatteryProfile& defaults) {
    const BatteryChemistry chemistry = clampChemistry(
        prefs_.getUChar(key(prefix, "chem").c_str(), static_cast<uint8_t>(defaults.chemistry)));
    const double capacityAh = prefs_.getDouble(key(prefix, "cap").c_str(), defaults.capacityAh);

    BatteryProfile p = makeProfile(chemistry, capacityAh);
    p.chargeEfficiency = prefs_.getDouble(key(prefix, "eta").c_str(), p.chargeEfficiency);
    p.fullChargeVoltageV = prefs_.getDouble(key(prefix, "vfull").c_str(), p.fullChargeVoltageV);
    p.fullTailCurrentFractionC = prefs_.getDouble(key(prefix, "tail").c_str(), p.fullTailCurrentFractionC);
    p.lowVoltageIdleV = prefs_.getDouble(key(prefix, "uv").c_str(), p.lowVoltageIdleV);
    p.overVoltageV = prefs_.getDouble(key(prefix, "ov").c_str(), p.overVoltageV);
    p.selfDischargePctPerMonth = prefs_.getDouble(key(prefix, "self").c_str(), p.selfDischargePctPerMonth);
    p.socEnabled = prefs_.getBool(key(prefix, "soc").c_str(), p.socEnabled);

    const String profileName = prefs_.getString(key(prefix, "name").c_str(), p.name);
    strlcpy(p.name, profileName.c_str(), sizeof(p.name));
    return p;
}

void SettingsStore::saveProfile(const char* prefix, const BatteryProfile& p) {
    prefs_.putUChar(key(prefix, "chem").c_str(), static_cast<uint8_t>(p.chemistry));
    prefs_.putDouble(key(prefix, "cap").c_str(), p.capacityAh);
    prefs_.putDouble(key(prefix, "eta").c_str(), p.chargeEfficiency);
    prefs_.putDouble(key(prefix, "vfull").c_str(), p.fullChargeVoltageV);
    prefs_.putDouble(key(prefix, "tail").c_str(), p.fullTailCurrentFractionC);
    prefs_.putDouble(key(prefix, "uv").c_str(), p.lowVoltageIdleV);
    prefs_.putDouble(key(prefix, "ov").c_str(), p.overVoltageV);
    prefs_.putDouble(key(prefix, "self").c_str(), p.selfDischargePctPerMonth);
    prefs_.putBool(key(prefix, "soc").c_str(), p.socEnabled);
    prefs_.putString(key(prefix, "name").c_str(), p.name);
}

} // namespace bs
