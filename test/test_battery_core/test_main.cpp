#include <unity.h>
#include <cmath>

#include <BatteryCore.h>

using namespace bs;

static BatteryConfig baseConfig(double capacityAh = 70.0) {
    BatteryConfig cfg;
    cfg.capacityAh = capacityAh;
    cfg.chargeEfficiency = 0.92;
    cfg.startupOcvDelayS = 1.0;
    cfg.ocvCorrectionDelayS = 300.0;
    cfg.fullDetectDelayS = 2.0;
    cfg.overCurrentDelayS = 0.5;
    cfg.lowVoltageDelayIdleS = 2.0;
    cfg.lowVoltageDelayLoadedS = 0.5;
    cfg.maxIntegrationGapS = 5.0;
    return cfg;
}

void setUp() {}
void tearDown() {}

void test_one_hour_discharge_integrates_coulombs() {
    auto cfg = baseConfig(70.0);
    BatteryCore bat(cfg);
    bat.reset(100.0, true);

    for (int i = 0; i < 3600; ++i) {
        bat.update({12.4, -10.0, true}, 1.0);
    }

    TEST_ASSERT_DOUBLE_WITHIN(0.02, 85.714, bat.snapshot().socPct);
}

void test_charge_efficiency_is_applied_only_when_charging() {
    auto cfg = baseConfig(70.0);
    BatteryCore bat(cfg);
    bat.reset(50.0, true);

    for (int i = 0; i < 3600; ++i) {
        bat.update({13.8, 10.0, true}, 1.0);
    }

    const double expected = 50.0 + (10.0 * 0.92 / 70.0) * 100.0;
    TEST_ASSERT_DOUBLE_WITHIN(0.02, expected, bat.snapshot().socPct);
}

void test_long_time_gap_is_not_integrated() {
    auto cfg = baseConfig();
    BatteryCore bat(cfg);
    bat.reset(80.0, true);

    const auto s = bat.update({12.4, -100.0, true}, 3600.0);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 80.0, s.socPct);
    TEST_ASSERT_TRUE((s.alerts & AlertDataGap) != 0);
}

void test_invalid_sensor_data_sets_fault_and_does_not_change_soc() {
    auto cfg = baseConfig();
    BatteryCore bat(cfg);
    bat.reset(80.0, true);

    const auto s = bat.update({NAN, -10.0, true}, 1.0);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 80.0, s.socPct);
    TEST_ASSERT_TRUE((s.alerts & AlertSensorFault) != 0);
}

void test_startup_ocv_estimation_initializes_soc() {
    auto cfg = baseConfig();
    BatteryCore bat(cfg);
    bat.reset(50.0, false);

    const auto s = bat.update({12.60, 0.0, true}, 1.0);
    TEST_ASSERT_TRUE(s.socInitialized);
    TEST_ASSERT_DOUBLE_WITHIN(0.1, 90.0, s.socPct);
}

void test_charger_voltage_is_not_used_as_ocv() {
    auto cfg = baseConfig();
    BatteryCore bat(cfg);
    bat.reset(50.0, false);

    // 13.8 V is clearly charger-influenced and above the OCV eligibility window,
    // while still below the explicit full-charge synchronization threshold.
    for (int i = 0; i < 20; ++i) {
        bat.update({13.8, 0.0, true}, 1.0);
    }

    TEST_ASSERT_FALSE(bat.snapshot().socInitialized);
}

void test_full_charge_tail_current_synchronizes_to_100_percent() {
    auto cfg = baseConfig(90.0);
    BatteryCore bat(cfg);
    bat.reset(75.0, true);

    bat.update({14.4, 1.5, true}, 1.0);
    const auto s = bat.update({14.4, 1.5, true}, 1.0);

    TEST_ASSERT_TRUE(s.fullySynchronized);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 100.0, s.socPct);
}

void test_bow_thruster_normal_sag_does_not_trigger_low_voltage() {
    auto cfg = baseConfig(90.0);
    cfg.maxAbsCurrentA = 250.0;
    cfg.highLoadCurrentA = 20.0;
    cfg.lowVoltageLoadedV = 9.5;
    BatteryCore bat(cfg);
    bat.reset(80.0, true);

    for (int i = 0; i < 20; ++i) {
        bat.update({10.2, -180.0, true}, 0.1);
    }

    TEST_ASSERT_FALSE((bat.snapshot().alerts & AlertLowVoltage) != 0);
    TEST_ASSERT_FALSE((bat.snapshot().alerts & AlertOverCurrent) != 0);
}

void test_bow_thruster_overcurrent_is_delayed_then_asserted() {
    auto cfg = baseConfig(90.0);
    cfg.maxAbsCurrentA = 250.0;
    cfg.overCurrentDelayS = 0.5;
    BatteryCore bat(cfg);
    bat.reset(80.0, true);

    for (int i = 0; i < 4; ++i) {
        bat.update({10.0, -270.0, true}, 0.1);
    }
    TEST_ASSERT_FALSE((bat.snapshot().alerts & AlertOverCurrent) != 0);

    bat.update({10.0, -270.0, true}, 0.1);
    TEST_ASSERT_TRUE((bat.snapshot().alerts & AlertOverCurrent) != 0);
}

void test_short_idle_voltage_dip_does_not_false_alarm() {
    auto cfg = baseConfig();
    cfg.lowVoltageIdleV = 11.6;
    cfg.lowVoltageDelayIdleS = 2.0;
    BatteryCore bat(cfg);
    bat.reset(50.0, true);

    bat.update({11.4, -1.0, true}, 1.0);
    TEST_ASSERT_FALSE((bat.snapshot().alerts & AlertLowVoltage) != 0);

    bat.update({12.2, -1.0, true}, 1.0);
    TEST_ASSERT_FALSE((bat.snapshot().alerts & AlertLowVoltage) != 0);
}

void test_sustained_idle_undervoltage_sets_and_hysteresis_clears_alarm() {
    auto cfg = baseConfig();
    cfg.lowVoltageIdleV = 11.6;
    cfg.lowVoltageDelayIdleS = 2.0;
    BatteryCore bat(cfg);
    bat.reset(50.0, true);

    bat.update({11.4, -1.0, true}, 1.0);
    bat.update({11.4, -1.0, true}, 1.0);
    TEST_ASSERT_TRUE((bat.snapshot().alerts & AlertLowVoltage) != 0);

    bat.update({11.7, -1.0, true}, 0.5);
    TEST_ASSERT_TRUE((bat.snapshot().alerts & AlertLowVoltage) != 0);

    bat.update({11.9, -1.0, true}, 0.5);
    TEST_ASSERT_FALSE((bat.snapshot().alerts & AlertLowVoltage) != 0);
}

void test_soc_alerts_have_recovery_hysteresis() {
    auto cfg = baseConfig();
    BatteryCore bat(cfg);
    bat.reset(9.0, true);

    auto s = bat.update({12.0, 0.0, true}, 0.1);
    TEST_ASSERT_TRUE((s.alerts & AlertLowSoc) != 0);
    TEST_ASSERT_TRUE((s.alerts & AlertCriticalSoc) != 0);

    bat.reset(23.0, true);
    s = bat.update({12.3, 0.0, true}, 0.1);
    TEST_ASSERT_FALSE((s.alerts & AlertLowSoc) != 0);
    TEST_ASSERT_FALSE((s.alerts & AlertCriticalSoc) != 0);
}

void test_ocv_curve_endpoints_are_clamped() {
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 0.0, BatteryCore::estimateSocFromOcv(11.0));
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 100.0, BatteryCore::estimateSocFromOcv(13.0));
}

int main(int argc, char** argv) {
    UNITY_BEGIN();
    RUN_TEST(test_one_hour_discharge_integrates_coulombs);
    RUN_TEST(test_charge_efficiency_is_applied_only_when_charging);
    RUN_TEST(test_long_time_gap_is_not_integrated);
    RUN_TEST(test_invalid_sensor_data_sets_fault_and_does_not_change_soc);
    RUN_TEST(test_startup_ocv_estimation_initializes_soc);
    RUN_TEST(test_charger_voltage_is_not_used_as_ocv);
    RUN_TEST(test_full_charge_tail_current_synchronizes_to_100_percent);
    RUN_TEST(test_bow_thruster_normal_sag_does_not_trigger_low_voltage);
    RUN_TEST(test_bow_thruster_overcurrent_is_delayed_then_asserted);
    RUN_TEST(test_short_idle_voltage_dip_does_not_false_alarm);
    RUN_TEST(test_sustained_idle_undervoltage_sets_and_hysteresis_clears_alarm);
    RUN_TEST(test_soc_alerts_have_recovery_hysteresis);
    RUN_TEST(test_ocv_curve_endpoints_are_clamped);
    return UNITY_END();
}
