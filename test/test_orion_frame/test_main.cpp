#include <unity.h>
#include <OrionFrame.h>

using bs::orion::Telemetry;

void setUp() {}
void tearDown() {}

void test_xs_record_scales_and_preserves_status() {
    // Synthetic decrypted record: 28.40 V / 35.2 A output, 13.76 V / 74.3 A input.
    const uint8_t record[14] = {3, 0, 0x18, 0x0b, 0x60, 0x01,
                                0x60, 0x05, 0xe7, 0x02, 0x04, 0, 0, 0};
    Telemetry value;
    TEST_ASSERT_TRUE(bs::orion::decodeXsRecord(record, sizeof(record), value));
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 28.40, value.outputVoltage.number);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 35.2, value.outputCurrent.number);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 13.76, value.inputVoltage.number);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 74.3, value.inputCurrent.number);
    TEST_ASSERT_EQUAL_UINT8(3, value.state);
    TEST_ASSERT_EQUAL_UINT32(4, value.offReason);
}

void test_sentinels_and_truncation() {
    const uint8_t missing[14] = {0xff, 0, 0xff, 0x7f, 0xff, 0x7f,
                                 0xff, 0xff, 0xff, 0xff, 0, 0, 0, 0};
    Telemetry value;
    TEST_ASSERT_FALSE(bs::orion::decodeXsRecord(missing, 13, value));
    TEST_ASSERT_TRUE(bs::orion::decodeXsRecord(missing, sizeof(missing), value));
    TEST_ASSERT_FALSE(value.outputVoltage.valid);
    TEST_ASSERT_FALSE(value.outputCurrent.valid);
    TEST_ASSERT_FALSE(value.inputVoltage.valid);
    TEST_ASSERT_FALSE(value.inputCurrent.valid);
}

void test_freshness_wrap() {
    Telemetry value;
    TEST_ASSERT_FALSE(value.fresh(10));
    value.received = true;
    value.receivedAtMs = 0xfffffff0U;
    TEST_ASSERT_TRUE(value.fresh(10, 30));
    TEST_ASSERT_FALSE(value.fresh(10, 20));
}

int main(int, char**) {
    UNITY_BEGIN();
    RUN_TEST(test_xs_record_scales_and_preserves_status);
    RUN_TEST(test_sentinels_and_truncation);
    RUN_TEST(test_freshness_wrap);
    return UNITY_END();
}
