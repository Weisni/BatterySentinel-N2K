#include <BatteryCore.h>

#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

using namespace bs;

struct Segment {
    std::string label;
    double seconds;
    double voltageV;
    double currentA;
    bool valid = true;
};

struct Scenario {
    std::string name;
    std::vector<Segment> system;
    std::vector<Segment> bow;
};

static BatteryConfig systemConfig() {
    BatteryConfig cfg;
    cfg.capacityAh = 70.0;
    cfg.maxAbsCurrentA = 450.0; // provisional until real starter current is measured
    cfg.highLoadCurrentA = 50.0;
    cfg.lowVoltageLoadedV = 9.5;
    return cfg;
}

static BatteryConfig bowConfig() {
    BatteryConfig cfg;
    cfg.capacityAh = 90.0;
    cfg.maxAbsCurrentA = 250.0;
    cfg.highLoadCurrentA = 20.0;
    cfg.lowVoltageLoadedV = 9.5;
    return cfg;
}

static std::string alertsToString(uint32_t a) {
    if (a == AlertNone) return "OK";
    std::string s;
    auto add = [&](uint32_t flag, const char* text) {
        if ((a & flag) != 0) {
            if (!s.empty()) s += "|";
            s += text;
        }
    };
    add(AlertSensorFault, "SENSOR_FAULT");
    add(AlertDataGap, "DATA_GAP");
    add(AlertLowVoltage, "LOW_VOLTAGE");
    add(AlertOverVoltage, "OVER_VOLTAGE");
    add(AlertOverCurrent, "OVER_CURRENT");
    add(AlertLowSoc, "LOW_SOC");
    add(AlertCriticalSoc, "CRITICAL_SOC");
    return s;
}

static void runSegments(const char* bankName, BatteryCore& core,
                        const std::vector<Segment>& segments, double stepS = 0.1) {
    std::cout << "\n=== " << bankName << " ===\n";
    uint32_t previousAlerts = core.snapshot().alerts;

    for (const auto& segment : segments) {
        double elapsed = 0.0;
        while (elapsed < segment.seconds) {
            const double dt = std::min(stepS, segment.seconds - elapsed);
            const auto state = core.update({segment.voltageV, segment.currentA, segment.valid}, dt);
            elapsed += dt;

            if (state.alerts != previousAlerts || state.fullySynchronized) {
                std::cout << std::fixed << std::setprecision(2)
                          << segment.label << ": V=" << state.voltageV
                          << " V, I=" << state.currentA
                          << " A, SOC=" << state.socPct
                          << " %, action=" << alertsToString(state.alerts);
                if (state.fullySynchronized) std::cout << "|SOC_SYNC_100";
                std::cout << "\n";
                previousAlerts = state.alerts;
            }
        }

        const auto& s = core.snapshot();
        std::cout << std::fixed << std::setprecision(2)
                  << "  end " << segment.label << " -> V=" << s.voltageV
                  << " V, I=" << s.currentA
                  << " A, SOC=" << s.socPct
                  << " %, alerts=" << alertsToString(s.alerts) << "\n";
    }
}

static Scenario normalTrip() {
    return {
        "normal_trip",
        {
            {"rest/start", 12.0, 12.60, 0.0},
            {"electronics", 600.0, 12.45, -5.0},
            {"charging", 600.0, 14.20, 12.0},
            {"charge taper", 310.0, 14.40, 1.0},
        },
        {
            {"rest/start", 12.0, 12.60, 0.0},
            {"idle", 120.0, 12.58, -0.2},
            {"thruster normal", 8.0, 10.20, -180.0},
            {"recovery", 120.0, 12.48, -0.2},
            {"charging", 600.0, 14.30, 10.0},
            {"charge taper", 310.0, 14.40, 1.5},
        }
    };
}

static Scenario faultTrip() {
    return {
        "fault_trip",
        {
            {"normal", 5.0, 12.50, -4.0},
            {"overvoltage", 3.0, 15.30, 2.0},
            {"recover", 3.0, 14.40, 1.0},
            {"sensor disconnected", 1.0, 0.0, 0.0, false},
            {"sensor recovered", 2.0, 12.40, -4.0, true},
        },
        {
            {"normal", 5.0, 12.55, 0.0},
            {"thruster overload", 2.0, 9.80, -270.0},
            {"recover", 2.0, 12.30, 0.0},
            {"deep sag", 1.0, 9.20, -180.0},
            {"recover", 2.0, 12.20, 0.0},
        }
    };
}

int main(int argc, char** argv) {
    const bool faults = argc > 1 && std::string(argv[1]) == "faults";
    const Scenario scenario = faults ? faultTrip() : normalTrip();

    std::cout << "BatterySentinel-N2K simulator: " << scenario.name << "\n";
    std::cout << "Convention: +I=charge, -I=discharge\n";

    BatteryCore system(systemConfig());
    BatteryCore bow(bowConfig());

    // A persisted SOC would normally be loaded from ESP32 NVS. Simulation starts at 80%.
    system.reset(80.0, true);
    bow.reset(80.0, true);

    runSegments("SYSTEM 70Ah", system, scenario.system);
    runSegments("BOW 90Ah", bow, scenario.bow);

    return 0;
}
