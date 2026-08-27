#include <Arduino.h>
#include <Preferences.h>
#include <Wire.h>
#include <cmath>

#include <BatteryCore.h>
#include "Ina238.h"
#include "NmeaPublisher.h"
#include "config.h"

using namespace bs;

namespace {

BatteryConfig makeSystemConfig() {
    BatteryConfig cfg;
    cfg.capacityAh = config::SYSTEM_CAPACITY_AH;
    cfg.maxAbsCurrentA = config::SYSTEM_MAX_ABS_CURRENT_A;
    cfg.highLoadCurrentA = 50.0;
    cfg.lowVoltageLoadedV = 9.5;
    return cfg;
}

BatteryConfig makeBowConfig() {
    BatteryConfig cfg;
    cfg.capacityAh = config::BOW_CAPACITY_AH;
    cfg.maxAbsCurrentA = config::BOW_MAX_ABS_CURRENT_A;
    cfg.highLoadCurrentA = 20.0;
    cfg.lowVoltageLoadedV = 9.5;
    return cfg;
}

// System uses wide ±163.84 mV range to preserve cranking headroom.
Ina238 systemSensor(Wire, config::INA238_SYSTEM_ADDRESS, config::SYSTEM_SHUNT_OHM, false);
// Bow uses narrow ±40.96 mV range: 500 A/50 mV shunt then resolves ~12.5 mA/LSB
// and still has ~409 A electrical measurement span.
Ina238 bowSensor(Wire, config::INA238_BOW_ADDRESS, config::BOW_SHUNT_OHM, true);
BatteryCore systemBattery(makeSystemConfig());
BatteryCore bowBattery(makeBowConfig());
NmeaPublisher nmea;
Preferences preferences;

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

void restoreSoc() {
    preferences.begin("batsentinel", false);

    const float sysSoc = preferences.getFloat("soc_sys", -1.0f);
    const float bowSoc = preferences.getFloat("soc_bow", -1.0f);
    if (sysSoc >= 0.0f && sysSoc <= 100.0f) systemBattery.restoreSoc(sysSoc);
    if (bowSoc >= 0.0f && bowSoc <= 100.0f) bowBattery.restoreSoc(bowSoc);
}

void persistSoc() {
    const auto& sys = systemBattery.snapshot();
    const auto& bow = bowBattery.snapshot();
    if (sys.socInitialized) preferences.putFloat("soc_sys", static_cast<float>(sys.socPct));
    if (bow.socInitialized) preferences.putFloat("soc_bow", static_cast<float>(bow.socPct));
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
    bowMeasurement = bowSensor.read();

    const auto sys = systemBattery.update(systemMeasurement, dtS);
    const auto bow = bowBattery.update(bowMeasurement, dtS);

    reportAlertChange("SYSTEM", sys.alerts, previousSystemAlerts);
    reportAlertChange("BOW", bow.alerts, previousBowAlerts);

    // Persist shortly after a high-current event ends. This avoids losing the
    // coulomb-count contribution of a bow-thruster/starter pulse if ignition is
    // switched off before the regular persistence interval.
    const bool systemHighNow = systemMeasurement.valid && std::fabs(systemMeasurement.currentA) > 50.0;
    const bool bowHighNow = bowMeasurement.valid && std::fabs(bowMeasurement.currentA) > 20.0;
    const bool highEventEnded = (systemHighLoadSeen && !systemHighNow) ||
                                (bowHighLoadSeen && !bowHighNow);

    if (highEventEnded) persistSoc();
    systemHighLoadSeen = systemHighNow;
    bowHighLoadSeen = bowHighNow;

    digitalWrite(config::PIN_STATUS_LED,
                 (sys.alerts != AlertNone || bow.alerts != AlertNone) ? HIGH : LOW);
}

void publishNmea(uint32_t now) {
    if (timeDue(now, lastFastN2kMs, config::N2K_FAST_PERIOD_MS)) {
        nmea.publishFast(0, systemBattery.snapshot(), systemMeasurement.valid);
        nmea.publishFast(1, bowBattery.snapshot(), bowMeasurement.valid);
    }

    if (timeDue(now, lastDcN2kMs, config::N2K_DC_PERIOD_MS)) {
        nmea.publishDc(0, systemBattery.snapshot(), systemMeasurement.valid);
        nmea.publishDc(1, bowBattery.snapshot(), bowMeasurement.valid);
    }
}

} // namespace

void setup() {
    pinMode(config::PIN_STATUS_LED, OUTPUT);
    digitalWrite(config::PIN_STATUS_LED, LOW);

    Serial.begin(115200);
    delay(250);
    Serial.println("BatterySentinel N2K V1 boot");

    Wire.begin(config::PIN_I2C_SDA, config::PIN_I2C_SCL, 100000);
    restoreSoc();

    const bool systemOk = systemSensor.begin();
    const bool bowOk = bowSensor.begin();
    Serial.printf("INA238 system=%s, bow=%s\n", systemOk ? "OK" : "MISSING", bowOk ? "OK" : "MISSING");

    const uint64_t mac = ESP.getEfuseMac();
    const uint32_t uniqueNumber = static_cast<uint32_t>((mac ^ (mac >> 24)) & 0x1FFFFFu);
    nmea.begin(uniqueNumber == 0 ? 1 : uniqueNumber);

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

    if (timeDue(now, lastPersistMs, config::SOC_PERSIST_PERIOD_MS)) {
        persistSoc();
    }

    delay(2);
}
