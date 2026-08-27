#pragma once

#include <cstdint>

namespace bs {

enum AlertFlag : uint32_t {
    AlertNone        = 0,
    AlertSensorFault = 1u << 0,
    AlertDataGap     = 1u << 1,
    AlertLowVoltage  = 1u << 2,
    AlertOverVoltage = 1u << 3,
    AlertOverCurrent = 1u << 4,
    AlertLowSoc      = 1u << 5,
    AlertCriticalSoc = 1u << 6,
};

struct Measurement {
    double voltageV = 0.0;
    double currentA = 0.0;      // positive=charge, negative=discharge
    bool valid = false;
};

struct BatteryConfig {
    double capacityAh = 100.0;
    double chargeEfficiency = 0.93;

    // SOC / OCV model
    double restCurrentA = 0.8;
    double startupOcvDelayS = 10.0;
    double ocvCorrectionDelayS = 300.0;
    double ocvBlend = 0.20;
    double fullChargeVoltageV = 14.20;
    double fullTailCurrentFractionC = 0.02;  // C/50
    double fullDetectDelayS = 300.0;

    // Alert model
    double maxAbsCurrentA = 250.0;
    double overCurrentDelayS = 0.75;
    double highLoadCurrentA = 20.0;
    double lowVoltageIdleV = 11.60;
    double lowVoltageLoadedV = 9.50;
    double lowVoltageDelayIdleS = 10.0;
    double lowVoltageDelayLoadedS = 0.75;
    double overVoltageV = 15.00;
    double overVoltageDelayS = 2.0;
    double voltageHysteresisV = 0.20;
    double currentHysteresisA = 5.0;
    double lowSocPct = 20.0;
    double criticalSocPct = 10.0;

    // Integration safety: never integrate a long time gap caused by reset/power-off.
    double maxIntegrationGapS = 5.0;
};

struct BatterySnapshot {
    double voltageV = 0.0;
    double currentA = 0.0;
    double socPct = 50.0;
    double consumedAh = 0.0;
    double timeRemainingS = -1.0;
    uint32_t alerts = AlertNone;
    bool socInitialized = false;
    bool fullySynchronized = false;
};

class BatteryCore {
public:
    explicit BatteryCore(BatteryConfig cfg = {});

    void reset(double initialSocPct = 50.0, bool initialized = false);
    void restoreSoc(double persistedSocPct);
    BatterySnapshot update(const Measurement& m, double dtS);

    const BatterySnapshot& snapshot() const { return state_; }
    const BatteryConfig& config() const { return cfg_; }

    static double estimateSocFromOcv(double voltageV);

private:
    BatteryConfig cfg_;
    BatterySnapshot state_;

    double restTimerS_ = 0.0;
    double fullTimerS_ = 0.0;
    double lowVoltageTimerS_ = 0.0;
    double overVoltageTimerS_ = 0.0;
    double overCurrentTimerS_ = 0.0;

    void updateSoc(const Measurement& m, double dtS);
    void updateAlerts(const Measurement& m, double dtS);
    void updateRemainingTime(const Measurement& m);
    void applyOcvCorrection(double voltageV, bool startup);

    static double clamp(double value, double lo, double hi);
    static bool finiteMeasurement(const Measurement& m);
};

inline AlertFlag operator|(AlertFlag a, AlertFlag b) {
    return static_cast<AlertFlag>(static_cast<uint32_t>(a) | static_cast<uint32_t>(b));
}

} // namespace bs
