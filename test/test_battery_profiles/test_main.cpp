#include <unity.h>

#include <BatteryProfiles.h>

using namespace bs;

void setUp() {}
void tearDown() {}

void test_unknown_profile_disables_soc() {
    const auto p = makeProfile(BatteryChemistry::Unknown, 90.0);
    TEST_ASSERT_EQUAL_UINT8(static_cast<uint8_t>(BatteryChemistry::Unknown),
                            static_cast<uint8_t>(p.chemistry));
    TEST_ASSERT_FALSE(p.socEnabled);
    TEST_ASSERT_FALSE(p.ocvCorrectionEnabled);
}

void test_flooded_system_profile_uses_configured_capacity() {
    const auto p = makeProfile(BatteryChemistry::FloodedLeadAcid, 80.0);
    TEST_ASSERT_TRUE(p.socEnabled);
    TEST_ASSERT_TRUE(p.ocvCorrectionEnabled);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 80.0, p.capacityAh);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 0.90, p.chargeEfficiency);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 14.40, p.fullChargeVoltageV);
}

void test_agm_profile_is_distinct_from_flooded() {
    const auto flooded = makeProfile(BatteryChemistry::FloodedLeadAcid, 90.0);
    const auto agm = makeProfile(BatteryChemistry::AGM, 90.0);
    TEST_ASSERT_TRUE(agm.socEnabled);
    TEST_ASSERT_TRUE(agm.ocvCorrectionEnabled);
    TEST_ASSERT_NOT_EQUAL(flooded.chargeEfficiency, agm.chargeEfficiency);
    TEST_ASSERT_NOT_EQUAL(flooded.lowVoltageIdleV, agm.lowVoltageIdleV);
}

void test_zero_capacity_disables_soc_even_for_known_chemistry() {
    const auto p = makeProfile(BatteryChemistry::AGM, 0.0);
    TEST_ASSERT_FALSE(p.socEnabled);
}

void test_profile_converts_to_battery_core_config() {
    const auto p = makeProfile(BatteryChemistry::FloodedLeadAcid, 80.0);
    const auto cfg = toBatteryConfig(p, 350.0);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 80.0, cfg.capacityAh);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 350.0, cfg.maxAbsCurrentA);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, p.fullChargeVoltageV, cfg.fullChargeVoltageV);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, p.overVoltageV, cfg.overVoltageV);
    TEST_ASSERT_TRUE(cfg.ocvCorrectionEnabled);
    TEST_ASSERT_TRUE(cfg.restCurrentA > 0.0);
}

void test_lifepo4_profile_does_not_use_lead_acid_ocv_estimator() {
    const auto p = makeProfile(BatteryChemistry::LiFePO4, 100.0);
    const auto cfg = toBatteryConfig(p, 200.0);
    TEST_ASSERT_TRUE(p.socEnabled);
    TEST_ASSERT_FALSE(p.ocvCorrectionEnabled);
    TEST_ASSERT_FALSE(cfg.ocvCorrectionEnabled);
    TEST_ASSERT_TRUE(cfg.restCurrentA < 0.0);

    BatteryCore battery(cfg);
    battery.reset(50.0, false);
    for (int i = 0; i < 600; ++i) {
        battery.update({12.60, 0.0, true}, 1.0);
    }
    TEST_ASSERT_FALSE(battery.snapshot().socInitialized);
}

int main(int argc, char** argv) {
    UNITY_BEGIN();
    RUN_TEST(test_unknown_profile_disables_soc);
    RUN_TEST(test_flooded_system_profile_uses_configured_capacity);
    RUN_TEST(test_agm_profile_is_distinct_from_flooded);
    RUN_TEST(test_zero_capacity_disables_soc_even_for_known_chemistry);
    RUN_TEST(test_profile_converts_to_battery_core_config);
    RUN_TEST(test_lifepo4_profile_does_not_use_lead_acid_ocv_estimator);
    return UNITY_END();
}
