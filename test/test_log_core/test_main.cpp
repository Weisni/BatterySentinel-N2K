#include <unity.h>
#include <cstring>

#include <LogCore.h>

using namespace bs::log;

void setUp() {}
void tearDown() {}

void test_record_is_exactly_32_bytes() {
    TEST_ASSERT_EQUAL_UINT32(32, sizeof(LogRecord));
}

void test_encode_and_crc_validation() {
    SampleInput in;
    in.utcSeconds = 1787891234;
    in.utcValid = true;
    in.uptimeMs = 123456;
    in.systemVoltageV = 12.63;
    in.systemCurrentA = -184.25;
    in.systemSocPct = 78.4;
    in.systemAlerts = 0x0012;
    in.systemValid = true;
    in.systemSocValid = true;
    in.event = true;

    const auto r = encode(42, in);
    TEST_ASSERT_TRUE(valid(r));
    TEST_ASSERT_EQUAL_UINT16(42, r.sequence);
    TEST_ASSERT_EQUAL_UINT16(12630, r.systemMv);
    TEST_ASSERT_EQUAL_INT32(-184250, r.systemMa);
    TEST_ASSERT_EQUAL_UINT16(784, r.systemSocPermille);
    TEST_ASSERT_TRUE((r.flags & FlagEvent) != 0);
    TEST_ASSERT_TRUE((r.flags & FlagUtcValid) != 0);
}

void test_single_bit_corruption_is_detected() {
    auto r = encode(1, SampleInput{});
    TEST_ASSERT_TRUE(valid(r));

    auto* bytes = reinterpret_cast<uint8_t*>(&r);
    bytes[10] ^= 0x01;
    TEST_ASSERT_FALSE(valid(r));
}

void test_disabled_second_channel_has_no_valid_flags() {
    SampleInput in;
    in.secondEnabled = false;
    in.secondValid = false;
    in.secondSocValid = false;
    const auto r = encode(0, in);

    TEST_ASSERT_FALSE((r.flags & FlagSecondEnabled) != 0);
    TEST_ASSERT_FALSE((r.flags & FlagSecondValid) != 0);
    TEST_ASSERT_FALSE((r.flags & FlagSecondSocValid) != 0);
}

void test_numeric_values_saturate_safely() {
    SampleInput in;
    in.systemVoltageV = 100.0;
    in.systemCurrentA = 3.0e9;
    in.systemSocPct = 150.0;
    const auto r = encode(0, in);

    TEST_ASSERT_EQUAL_UINT16(65535, r.systemMv);
    TEST_ASSERT_EQUAL_INT32(INT32_MAX, r.systemMa);
    TEST_ASSERT_EQUAL_UINT16(1000, r.systemSocPermille);
}

void test_one_hertz_storage_budget_supports_five_days_in_32mb() {
    const uint32_t daily = bytesPerDay(1000);
    TEST_ASSERT_EQUAL_UINT32(2764800, daily);
    const uint64_t fiveDays = static_cast<uint64_t>(daily) * 5ULL;
    TEST_ASSERT_TRUE(fiveDays < 32ULL * 1024ULL * 1024ULL);
}

int main(int argc, char** argv) {
    UNITY_BEGIN();
    RUN_TEST(test_record_is_exactly_32_bytes);
    RUN_TEST(test_encode_and_crc_validation);
    RUN_TEST(test_single_bit_corruption_is_detected);
    RUN_TEST(test_disabled_second_channel_has_no_valid_flags);
    RUN_TEST(test_numeric_values_saturate_safely);
    RUN_TEST(test_one_hertz_storage_budget_supports_five_days_in_32mb);
    return UNITY_END();
}
