#include "BatteryCore.h"

#include <algorithm>
#include <cmath>

namespace bs {

BatteryCore::BatteryCore(BatteryConfig cfg) : cfg_(cfg) {
    reset();
}

void BatteryCore::reset(double initialSocPct, bool initialized) {
    state_ = {};
    state_.socPct = clamp(initialSocPct, 0.0, 100.0);
    state_.socInitialized = initialized;
    state_.alerts = AlertNone;
    state_.fullySynchronized = false;
    restTimerS_ = 0.0;
    fullTimerS_ = 0.0;
    lowVoltageTimerS_ = 0.0;
    overVoltageTimerS_ = 0.0;
    overCurrentTimerS_ = 0.0;
}

void BatteryCore::restoreSoc(double persistedSocPct) {
    if (std::isfinite(persistedSocPct) && persistedSocPct >= 0.0 && persistedSocPct <= 100.0) {
        state_.socPct = persistedSocPct;
        state_.socInitialized = true;
    }
}

BatterySnapshot BatteryCore::update(const Measurement& m, double dtS) {
    state_.fullySynchronized = false;
    state_.alerts &= ~static_cast<uint32_t>(AlertDataGap);

    if (!finiteMeasurement(m)) {
        state_.alerts |= AlertSensorFault;
        state_.timeRemainingS = -1.0;
        return state_;
    }

    state_.alerts &= ~static_cast<uint32_t>(AlertSensorFault);
    state_.voltageV = m.voltageV;
    state_.currentA = m.currentA;

    if (!std::isfinite(dtS) || dtS <= 0.0 || dtS > cfg_.maxIntegrationGapS) {
        state_.alerts |= AlertDataGap;
        lowVoltageTimerS_ = 0.0;
        overVoltageTimerS_ = 0.0;
        overCurrentTimerS_ = 0.0;
        updateRemainingTime(m);
        return state_;
    }

    updateSoc(m, dtS);
    updateAlerts(m, dtS);
    updateRemainingTime(m);
    return state_;
}

void BatteryCore::updateSoc(const Measurement& m, double dtS) {
    const double absCurrent = std::fabs(m.currentA);

    // A battery voltage above ~13 V is normally influenced by a charger and is therefore
    // not treated as open-circuit voltage.
    const bool ocvEligible = absCurrent <= cfg_.restCurrentA &&
                             m.voltageV >= 11.5 && m.voltageV <= 12.95;

    if (ocvEligible) {
        restTimerS_ += dtS;
    } else {
        restTimerS_ = 0.0;
    }

    if (!state_.socInitialized && restTimerS_ >= cfg_.startupOcvDelayS) {
        applyOcvCorrection(m.voltageV, true);
    } else if (state_.socInitialized && restTimerS_ >= cfg_.ocvCorrectionDelayS) {
        applyOcvCorrection(m.voltageV, false);
        // Avoid applying the blend every sample after the delay. Re-arm the timer.
        restTimerS_ = 0.0;
    }

    // Coulomb counting. Positive current charges; negative current discharges.
    double deltaAh = m.currentA * dtS / 3600.0;
    if (deltaAh > 0.0) {
        deltaAh *= cfg_.chargeEfficiency;
    }

    if (state_.socInitialized && cfg_.capacityAh > 0.0) {
        state_.socPct = clamp(state_.socPct + (deltaAh / cfg_.capacityAh) * 100.0, 0.0, 100.0);
    }

    state_.consumedAh = cfg_.capacityAh * (100.0 - state_.socPct) / 100.0;

    const double tailCurrentA = cfg_.capacityAh * cfg_.fullTailCurrentFractionC;
    const bool fullCondition = m.voltageV >= cfg_.fullChargeVoltageV &&
                               m.currentA >= 0.0 &&
                               m.currentA <= tailCurrentA;

    if (fullCondition) {
        fullTimerS_ += dtS;
        if (fullTimerS_ >= cfg_.fullDetectDelayS) {
            state_.socPct = 100.0;
            state_.consumedAh = 0.0;
            state_.socInitialized = true;
            state_.fullySynchronized = true;
            fullTimerS_ = 0.0;
        }
    } else {
        fullTimerS_ = 0.0;
    }
}

void BatteryCore::updateAlerts(const Measurement& m, double dtS) {
    const bool highDischarge = (-m.currentA) >= cfg_.highLoadCurrentA;
    const double lowThreshold = highDischarge ? cfg_.lowVoltageLoadedV : cfg_.lowVoltageIdleV;
    const double lowDelay = highDischarge ? cfg_.lowVoltageDelayLoadedS : cfg_.lowVoltageDelayIdleS;

    const bool lowActive = (state_.alerts & AlertLowVoltage) != 0;
    const bool lowCondition = lowActive
        ? m.voltageV < (lowThreshold + cfg_.voltageHysteresisV)
        : m.voltageV < lowThreshold;

    if (lowCondition) {
        lowVoltageTimerS_ += dtS;
        if (lowVoltageTimerS_ >= lowDelay) {
            state_.alerts |= AlertLowVoltage;
        }
    } else {
        lowVoltageTimerS_ = 0.0;
        state_.alerts &= ~static_cast<uint32_t>(AlertLowVoltage);
    }

    const bool ovActive = (state_.alerts & AlertOverVoltage) != 0;
    const bool ovCondition = ovActive
        ? m.voltageV > (cfg_.overVoltageV - cfg_.voltageHysteresisV)
        : m.voltageV > cfg_.overVoltageV;

    if (ovCondition) {
        overVoltageTimerS_ += dtS;
        if (overVoltageTimerS_ >= cfg_.overVoltageDelayS) {
            state_.alerts |= AlertOverVoltage;
        }
    } else {
        overVoltageTimerS_ = 0.0;
        state_.alerts &= ~static_cast<uint32_t>(AlertOverVoltage);
    }

    const bool ocActive = (state_.alerts & AlertOverCurrent) != 0;
    const double absCurrent = std::fabs(m.currentA);
    const bool ocCondition = ocActive
        ? absCurrent > (cfg_.maxAbsCurrentA - cfg_.currentHysteresisA)
        : absCurrent > cfg_.maxAbsCurrentA;

    if (ocCondition) {
        overCurrentTimerS_ += dtS;
        if (overCurrentTimerS_ >= cfg_.overCurrentDelayS) {
            state_.alerts |= AlertOverCurrent;
        }
    } else {
        overCurrentTimerS_ = 0.0;
        state_.alerts &= ~static_cast<uint32_t>(AlertOverCurrent);
    }

    if (state_.socInitialized && state_.socPct <= cfg_.lowSocPct) {
        state_.alerts |= AlertLowSoc;
    } else if (!state_.socInitialized || state_.socPct >= cfg_.lowSocPct + 2.0) {
        state_.alerts &= ~static_cast<uint32_t>(AlertLowSoc);
    }

    if (state_.socInitialized && state_.socPct <= cfg_.criticalSocPct) {
        state_.alerts |= AlertCriticalSoc;
    } else if (!state_.socInitialized || state_.socPct >= cfg_.criticalSocPct + 2.0) {
        state_.alerts &= ~static_cast<uint32_t>(AlertCriticalSoc);
    }
}

void BatteryCore::updateRemainingTime(const Measurement& m) {
    if (!state_.socInitialized || m.currentA >= -0.5) {
        state_.timeRemainingS = -1.0;
        return;
    }

    const double remainingAh = cfg_.capacityAh * state_.socPct / 100.0;
    state_.timeRemainingS = (remainingAh / -m.currentA) * 3600.0;
}

void BatteryCore::applyOcvCorrection(double voltageV, bool startup) {
    const double ocvSoc = estimateSocFromOcv(voltageV);
    if (startup || !state_.socInitialized) {
        state_.socPct = ocvSoc;
        state_.socInitialized = true;
    } else {
        state_.socPct = clamp(state_.socPct * (1.0 - cfg_.ocvBlend) + ocvSoc * cfg_.ocvBlend, 0.0, 100.0);
    }
}

double BatteryCore::estimateSocFromOcv(double voltageV) {
    // Generic 12 V AGM resting-voltage curve. Commissioning can replace this with
    // a battery-manufacturer-specific curve without changing the integration model.
    struct Point { double v; double soc; };
    static constexpr Point curve[] = {
        {11.90, 0.0},
        {12.00, 20.0},
        {12.15, 40.0},
        {12.30, 60.0},
        {12.45, 75.0},
        {12.60, 90.0},
        {12.75, 100.0},
    };

    if (!std::isfinite(voltageV)) return 50.0;
    if (voltageV <= curve[0].v) return curve[0].soc;
    if (voltageV >= curve[6].v) return curve[6].soc;

    for (std::size_t i = 1; i < 7; ++i) {
        if (voltageV <= curve[i].v) {
            const auto& a = curve[i - 1];
            const auto& b = curve[i];
            const double t = (voltageV - a.v) / (b.v - a.v);
            return a.soc + t * (b.soc - a.soc);
        }
    }
    return 50.0;
}

double BatteryCore::clamp(double value, double lo, double hi) {
    return std::max(lo, std::min(value, hi));
}

bool BatteryCore::finiteMeasurement(const Measurement& m) {
    return m.valid && std::isfinite(m.voltageV) && std::isfinite(m.currentA) &&
           m.voltageV >= 0.0 && m.voltageV <= 20.0 && std::fabs(m.currentA) <= 2000.0;
}

} // namespace bs
