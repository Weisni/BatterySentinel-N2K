#include <unity.h>
#include <Ina238Math.h>

using namespace bs::ina238math;

void setUp() {}
void tearDown() {}

void test_500a_50mv_shunt_wide_range_is_50ma_per_lsb() {
    const double shuntOhm = 0.000100;
    TEST_ASSERT_DOUBLE_WITHIN(1e-9, 0.05, currentA(1, shuntOhm, false));
}

void test_500a_50mv_shunt_narrow_range_is_12_5ma_per_lsb() {
    const double shuntOhm = 0.000100;
    TEST_ASSERT_DOUBLE_WITHIN(1e-9, 0.0125, currentA(1, shuntOhm, true));
}

void test_200a_bow_current_converts_with_expected_sign() {
    const double shuntOhm = 0.000100;
    // 200 A -> 20 mV -> 16000 narrow-range counts.
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 200.0, currentA(16000, shuntOhm, true));
    TEST_ASSERT_DOUBLE_WITHIN(0.001, -200.0, currentA(-16000, shuntOhm, true));
}

void test_bus_voltage_scaling() {
    // 12.5 V / 3.125 mV = 4000 counts.
    TEST_ASSERT_DOUBLE_WITHIN(1e-9, 12.5, busVoltageV(4000));
}

void test_zero_shunt_resistance_fails_safe() {
    TEST_ASSERT_DOUBLE_WITHIN(1e-12, 0.0, currentA(100, 0.0, false));
}

int main(int argc, char** argv) {
    UNITY_BEGIN();
    RUN_TEST(test_500a_50mv_shunt_wide_range_is_50ma_per_lsb);
    RUN_TEST(test_500a_50mv_shunt_narrow_range_is_12_5ma_per_lsb);
    RUN_TEST(test_200a_bow_current_converts_with_expected_sign);
    RUN_TEST(test_bus_voltage_scaling);
    RUN_TEST(test_zero_shunt_resistance_fails_safe);
    return UNITY_END();
}
