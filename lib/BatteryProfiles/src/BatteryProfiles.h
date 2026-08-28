#pragma once

#include <cstdint>
#include <cstring>
#include <BatteryCore.h>

namespace bs {

enum class BatteryChemistry : uint8_t {
    Unknown = 0,
    FloodedLeadAcid,
    AGM,
    GEL,
    EFB,
    LiFePO4,
    Custom
};

struct BatteryProfile {
    BatteryChemistry chemistry = BatteryChemistry::Unknown;
    char name[24] = "Unknown";
    double capacityAh = 0.0;
    double chargeEfficiency = 0.93;
    double fullChargeVoltageV = 14.20;
    double fullTailCurrentFractionC = 0.02;
    double lowVoltageIdleV = 11.60;
    double overVoltageV = 15.00;
    double selfDischargePctPerMonth = 0.0;
    bool socEnabled = false;
    bool ocvCorrectionEnabled = false;
};

inline const char* chemistryName(BatteryChemistry chemistry) {
    switch (chemistry) {
        case BatteryChemistry::FloodedLeadAcid: return "Flooded Lead Acid";
        case BatteryChemistry::AGM: return "AGM";
        case BatteryChemistry::GEL: return "GEL";
        case BatteryChemistry::EFB: return "EFB";
        case BatteryChemistry::LiFePO4: return "LiFePO4";
        case BatteryChemistry::Custom: return "Custom";
        default: return "Unknown";
    }
}

inline BatteryProfile makeProfile(BatteryChemistry chemistry, double capacityAh) {
    BatteryProfile p;
    p.chemistry = chemistry;
    p.capacityAh = capacityAh;
    std::strncpy(p.name, chemistryName(chemistry), sizeof(p.name) - 1);
    p.name[sizeof(p.name) - 1] = '\0';

    switch (chemistry) {
        case BatteryChemistry::FloodedLeadAcid:
            p.chargeEfficiency = 0.90;
            p.fullChargeVoltageV = 14.40;
            p.fullTailCurrentFractionC = 0.02;
            p.lowVoltageIdleV = 11.60;
            p.overVoltageV = 15.10;
            p.selfDischargePctPerMonth = 3.0;
            p.socEnabled = capacityAh > 0.0;
            p.ocvCorrectionEnabled = true;
            break;
        case BatteryChemistry::AGM:
            p.chargeEfficiency = 0.93;
            p.fullChargeVoltageV = 14.40;
            p.fullTailCurrentFractionC = 0.02;
            p.lowVoltageIdleV = 11.70;
            p.overVoltageV = 15.00;
            p.selfDischargePctPerMonth = 2.0;
            p.socEnabled = capacityAh > 0.0;
            p.ocvCorrectionEnabled = true;
            break;
        case BatteryChemistry::GEL:
            p.chargeEfficiency = 0.92;
            p.fullChargeVoltageV = 14.10;
            p.fullTailCurrentFractionC = 0.02;
            p.lowVoltageIdleV = 11.70;
            p.overVoltageV = 14.60;
            p.selfDischargePctPerMonth = 2.0;
            p.socEnabled = capacityAh > 0.0;
            p.ocvCorrectionEnabled = true;
            break;
        case BatteryChemistry::EFB:
            p.chargeEfficiency = 0.91;
            p.fullChargeVoltageV = 14.40;
            p.fullTailCurrentFractionC = 0.02;
            p.lowVoltageIdleV = 11.60;
            p.overVoltageV = 15.10;
            p.selfDischargePctPerMonth = 3.0;
            p.socEnabled = capacityAh > 0.0;
            p.ocvCorrectionEnabled = true;
            break;
        case BatteryChemistry::LiFePO4:
            // Flat OCV curve: V1 explicitly disables voltage-based SOC correction.
            // Coulomb counting and an explicit full-charge synchronization remain enabled.
            p.chargeEfficiency = 0.99;
            p.fullChargeVoltageV = 14.20;
            p.fullTailCurrentFractionC = 0.05;
            p.lowVoltageIdleV = 11.50;
            p.overVoltageV = 14.60;
            p.selfDischargePctPerMonth = 1.0;
            p.socEnabled = capacityAh > 0.0;
            p.ocvCorrectionEnabled = false;
            break;
        case BatteryChemistry::Custom:
            p.socEnabled = capacityAh > 0.0;
            // Custom defaults conservatively to no OCV correction until explicitly modeled.
            p.ocvCorrectionEnabled = false;
            break;
        default:
            p.capacityAh = capacityAh;
            p.socEnabled = false;
            p.ocvCorrectionEnabled = false;
            break;
    }
    return p;
}

inline BatteryConfig toBatteryConfig(const BatteryProfile& p, double maxAbsCurrentA) {
    BatteryConfig cfg;
    cfg.capacityAh = p.capacityAh > 0.0 ? p.capacityAh : 100.0;
    cfg.chargeEfficiency = p.chargeEfficiency;
    cfg.ocvCorrectionEnabled = p.ocvCorrectionEnabled;
    cfg.fullChargeVoltageV = p.fullChargeVoltageV;
    cfg.fullTailCurrentFractionC = p.fullTailCurrentFractionC;
    cfg.lowVoltageIdleV = p.lowVoltageIdleV;
    cfg.overVoltageV = p.overVoltageV;
    cfg.maxAbsCurrentA = maxAbsCurrentA;
    return cfg;
}

} // namespace bs
