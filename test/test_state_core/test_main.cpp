#include <unity.h>

#include <StateCore.h>

using namespace bs::state;

void setUp() {}
void tearDown() {}

void test_state_record_is_fixed_64_bytes() {
    TEST_ASSERT_EQUAL_UINT32(64, sizeof(PersistentState));
}

void test_sealed_state_validates_and_roundtrips_soc() {
    auto s = makeSystemState(17, 78.432, 17.253, SocConfidence::Estimated,
                             FlagUtcValid | FlagSocValid,
                             1787891234u, 123456u, 998u, 1u);
    TEST_ASSERT_TRUE(valid(s));
    TEST_ASSERT_EQUAL_UINT32(17, s.sequence);
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 78.432, milliPctToSoc(s.systemSocMilliPct));
    TEST_ASSERT_EQUAL_UINT32(1787891234u, s.utcSeconds);
}

void test_partial_or_corrupt_write_is_rejected_by_crc() {
    auto s = makeSystemState(18, 50.0, 40.0, SocConfidence::Synced,
                             FlagSocValid, 0, 1000, 1, 1);
    TEST_ASSERT_TRUE(valid(s));
    reinterpret_cast<uint8_t*>(&s)[31] ^= 0x80;
    TEST_ASSERT_FALSE(valid(s));
}

void test_newer_sequence_is_selected_normally() {
    TEST_ASSERT_TRUE(sequenceNewer(11, 10));
    TEST_ASSERT_FALSE(sequenceNewer(10, 11));
    TEST_ASSERT_FALSE(sequenceNewer(10, 10));
}

void test_sequence_comparison_handles_uint32_wrap() {
    TEST_ASSERT_TRUE(sequenceNewer(0u, 0xFFFFFFFFu));
    TEST_ASSERT_TRUE(sequenceNewer(1u, 0xFFFFFFFFu));
    TEST_ASSERT_FALSE(sequenceNewer(0xFFFFFFFFu, 0u));
}

void test_soc_encoding_clamps_out_of_range_values() {
    TEST_ASSERT_EQUAL_INT32(0, socToMilliPct(-5.0));
    TEST_ASSERT_EQUAL_INT32(100000, socToMilliPct(120.0));
    TEST_ASSERT_DOUBLE_WITHIN(0.001, 100.0, milliPctToSoc(100001));
}

int main(int argc, char** argv) {
    UNITY_BEGIN();
    RUN_TEST(test_state_record_is_fixed_64_bytes);
    RUN_TEST(test_sealed_state_validates_and_roundtrips_soc);
    RUN_TEST(test_partial_or_corrupt_write_is_rejected_by_crc);
    RUN_TEST(test_newer_sequence_is_selected_normally);
    RUN_TEST(test_sequence_comparison_handles_uint32_wrap);
    RUN_TEST(test_soc_encoding_clamps_out_of_range_values);
    return UNITY_END();
}
