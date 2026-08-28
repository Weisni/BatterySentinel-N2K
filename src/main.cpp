#include <Arduino.h>
#include <Preferences.h>
#include <Wire.h>
#include <cmath>

#include <BatteryCore.h>
#include <BatteryProfiles.h>
#include "DiagnosticsPortal.h"
#include "Ina238.h"
#include "NmeaPublisher.h"
#include "SettingsStore.h"
#include "config.h"

using namespace bs;

namespace {

DeviceSettings settings;
SettingsStore settingsStore;
DiagnosticsPortal diagnostics;

BatteryConfig makeSystemConfig(const DeviceSettings& s) {
    BatteryConfig cfg = toBatteryConfig(s.system, s.systemMaxCurrentA);
    cfg.highLoadCurrentA = 50.0;
    cfg.lowVoltageLoadedV = s.systemLowVoltageLoadedV;
    return cfg;
}

BatteryConfig makeBowConfig(const DeviceSettings& s) {
    BatteryConfig cfg = toBatteryConfig(s.bow, s.bowMaxCurrentA);
    cfg.highLoadCurrentA = 20.0;
    cfg.lowVoltageLoadedV = s.bowLowVoltageLoadedV;
    return cfg;
}

// System uses wide ±163.84 mV range to preserve cranking headroom.
Ina238 systemSensor(Wire, config::INA238_SYSTEM_ADDRESS, config::SYSTEM_SHUNT_OHM, false);
// Bow uses narrow ±40.96 mV range. It remains completely optional in V1.
Ina238 bowSensor(Wire, config::INA238_BOW_ADDRESS, config::BOW_SHUNT_OHM, true);

BatteryCore systemBattery;
BatteryCore bowBattery;
NmeaPublisher nmea;
Preferences statePreferences;

Measurement systemMeasurement{};
Measurement bowMeasurement{};
uint32_t previousSystemAlerts = AlertNone;
uint32_t previousBowAlerts = AlertNone;

uint32_t lastSampleMs = 0;
uint32_t lastFastN2kMs = 0;
uint32_t lastDcN2kMs = 0;
uint32_t lastPersistMs = 0;
bool bowHighLoadSeen = false;
bool systemHighLoadSeen = false;

bool timeDue(uint32_t now, uint32_t& last, uint32_t period) {
    if (static_cast<uint32_t>(now - last) < period) return false;
    last = now;
    return true;
}

bool profileMatchesStored(const char* prefix, const BatteryProfile& profile) {
    String chemKey(prefix); chemKey += "chem";
    String capKey(prefix); capKey += "cap";
    const uint8_t storedChem = statePreferences.getUChar(chemKey.c_str(), 0xFF);
    const float storedCapacity = statePreferences.getFloat(capKey.c_str(), -1.0f);
    return storedChem == static_cast<uint8_t>(profile.chemistry) &&
           std::fabs(static_cast<double>(storedCapacity) - profile.capacityAh) < 0.05;
}

void restoreSoc() {
    statePreferences.begin("batsentinel", false);

    if (settings.system.socEnabled && profileMatchesStored("sys_", settings.system)) {
        const float sysSoc = statePreferences.getFloat("soc_sys", -1.0f);
        if (sysSoc >= 0.0f && sysSoc <= 100.0f) systemBattery.restoreSoc(sysSoc);
    }

    if (settings.bowChannelEnabled && settings.bow.socEnabled && profileMatchesStored("bow_", settings.bow)) {
        const float bowSoc = statePreferences.getFloat("soc_bow", -1.0f);
        if (bowSoc >= 0.0f && bowSoc <= 100.0f) bowBattery.restoreSoc(bowSoc);
    }
}

void persistProfileIdentity(const char* prefix, const BatteryProfile& profile) {
    String chemKey(prefix); chemKey += "chem";
    String capKey(prefix); capKey += "cap";
    statePreferences.putUChar(chemKey.c_str(), static_cast<uint8_t>(profile.chemistry));
    statePreferences.putFloat(capKey.c_str(), static_cast<float>(profile.capacityAh));
}

void persistSoc() {
    const auto& sys = systemBattery.snapshot();
    if (settings.system.socEnabled && sys.socInitialized) {
        persistProfileIdentity("sys_", settings.system);
        statePreferences.putFloat("soc_sys", static_cast<float>(sys.socPct));
    }

    if (settings.bowChannelEnabled && settings.bow.socEnabled) {
        const auto& bow = bowBattery.snapshot();
        if (bow.socInitialized) {
            persistProfileIdentity("bow_", settings.bow);
            statePreferences.putFloat("soc_bow", static_cast<float>(bow.socPct));
        }
    }
}

void reportAlertChange(const char* name, uint32_t alerts, uint32_t& previous) {
    if (alerts == previous) return;
    Serial.printf("[%s] alerts: 0x%08lX -> 0x%08lX\n",
                  name,
                  static_cast<unsigned long>(previous),
                  static_cast<unsigned long>(alerts));
    previous = alerts;
}

void sampleBatteries(uint32_t now) {
    const uint32_t elapsedMs = lastSampleMs == 0 ? config::SAMPLE_PERIOD_MS : now - lastSampleMs;
    lastSampleMs = now;
    const double dtS = static_cast<double>(elapsedMs) / 1000.0;

    systemMeasurement = systemSensor.read();
    const auto sys = systemBattery.update(systemMeasurement, dtS);
    reportAlertChange("SYSTEM", sys.alerts, previousSystemAlerts);

    BatterySnapshot bow{};
    if (settings.bowChannelEnabled) {
        bowMeasurement = bowSensor.read();
        bow = bowBattery.update(bowMeasurement, dtS);
        reportAlertChange("BOW", bow.alerts, previousBowAlerts);
    } else {
        bowMeasurement = {};
        previousBowAlerts = AlertNone;
    }

    // Persist shortly after a high-current event ends. FRAM will later replace this as the
    // primary 1 s checkpoint path; NVS remains a fallback until that hardware is fitted.
    const bool systemHighNow = systemMeasurement.valid && std::fabs(systemMeasurement.currentA) > 50.0;
    const bool bowHighNow = settings.bowChannelEnabled && bowMeasurement.valid &&
                            std::fabs(bowMeasurement.currentA) > 20.0;
    const bool highEventEnded = (systemHighLoadSeen && !systemHighNow) ||
                                (bowHighLoadSeen && !bowHighNow);

    if (highEventEnded) persistSoc();
    systemHighLoadSeen = systemHighNow;
    bowHighLoadSeen = bowHighNow;

    const bool hasAlert = sys.alerts != AlertNone ||
                          (settings.bowChannelEnabled && bow.alerts != AlertNone);
    digitalWrite(config::PIN_STATUS_LED, hasAlert ? HIGH : LOW);
}

void publishNmea(uint32_t now) {
    if (timeDue(now, lastFastN2kMs, config::N2K_FAST_PERIOD_MS)) {
        nmea.publishFast(0, systemBattery.snapshot(), systemMeasurement.valid);
        if (settings.bowChannelEnabled) {
            nmea.publishFast(1, bowBattery.snapshot(), bowMeasurement.valid);
        }
    }

    if (timeDue(now, lastDcN2kMs, config::N2K_DC_PERIOD_MS)) {
        if (settings.system.socEnabled) {
            nmea.publishDc(0, systemBattery.snapshot(), systemMeasurement.valid);
        }
        if (settings.bowChannelEnabled && settings.bow.socEnabled) {
            nmea.publishDc(1, bowBattery.snapshot(), bowMeasurement.valid);
        }
    }
}

} // namespace

void setup() {
    pinMode(config::PIN_STATUS_LED, OUTPUT);
    digitalWrite(config::PIN_STATUS_LED, LOW);

    Serial.begin(115200);
    delay(250);
    Serial.println("BatterySentinel N2K V1 boot");

    if (!settingsStore.begin()) {
        Serial.println("WARNING: runtime settings store unavailable; using defaults");
    }
    settings = settingsStore.load();

    systemBattery = BatteryCore(makeSystemConfig(settings));
    bowBattery = BatteryCore(makeBowConfig(settings));

    Serial.printf("System profile: %s, %.1f Ah, SOC=%s\n",
                  chemistryName(settings.system.chemistry), settings.system.capacityAh,
                  settings.system.socEnabled ? "enabled" : "disabled");
    Serial.printf("Second battery: %s, profile=%s, %.1f Ah\n",
                  settings.bowChannelEnabled ? "enabled" : "disabled",
                  chemistryName(settings.bow.chemistry), settings.bow.capacityAh);

    Wire.begin(config::PIN_I2C_SDA, config::PIN_I2C_SCL, 100000);
    restoreSoc();

    const bool systemOk = systemSensor.begin();
    bool bowOk = false;
    if (settings.bowChannelEnabled) bowOk = bowSensor.begin();
    Serial.printf("INA238 system=%s, bow=%s\n",
                  systemOk ? "OK" : "MISSING",
                  settings.bowChannelEnabled ? (bowOk ? "OK" : "MISSING") : "DISABLED");

    const uint64_t mac = ESP.getEfuseMac();
    const uint32_t uniqueNumber = static_cast<uint32_t>((mac ^ (mac >> 24)) & 0x1FFFFFu);
    nmea.begin(uniqueNumber == 0 ? 1 : uniqueNumber);

    diagnostics.begin(settings, settingsStore, systemBattery, bowBattery);

    const uint32_t now = millis();
    lastSampleMs = now - config::SAMPLE_PERIOD_MS;
    lastFastN2kMs = now - config::N2K_FAST_PERIOD_MS;
    lastDcN2kMs = now - config::N2K_DC_PERIOD_MS;
    lastPersistMs = now;
}

void loop() {
    const uint32_t now = millis();

    if (static_cast<uint32_t>(now - lastSampleMs) >= config::SAMPLE_PERIOD_MS) {
        sampleBatteries(now);
    }

    publishNmea(now);
    nmea.process();
    diagnostics.loop();

    if (timeDue(now, lastPersistMs, config::SOC_PERSIST_PERIOD_MS)) {
        persistSoc();
    }

    delay(2);
}
