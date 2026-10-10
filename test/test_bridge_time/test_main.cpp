#include <unity.h>
#include <BridgeTime.h>
#include <limits>

using namespace bs::time;
constexpr uint64_t epoch = 1790424000000ULL;
void setUp() {}
void tearDown() {}
void sync(Clock& clock, uint64_t base = 0, uint64_t name = 1) {
    TEST_ASSERT_FALSE(clock.observe(epoch, base, name, 20, 129029));
    TEST_ASSERT_FALSE(clock.observe(epoch + 1000, base + 1000, name, 20, 129029));
    TEST_ASSERT_TRUE(clock.observe(epoch + 2000, base + 2000, name, 20, 129029));
}
void unknown_never_invents_calendar_time() {
    Clock clock; uint64_t value = 123;
    const Snapshot state = clock.snapshot(100000);
    TEST_ASSERT_EQUAL_INT(int(Quality::Unknown), int(state.quality));
    TEST_ASSERT_EQUAL_UINT64(100000, state.monotonicMs);
    TEST_ASSERT_FALSE(state.utcFor(10, value)); TEST_ASSERT_EQUAL_UINT64(123, value);
    TEST_ASSERT_FALSE(clock.observe(epoch, 100000, 1, 20, 129029));
    TEST_ASSERT_EQUAL_INT(int(Quality::Acquiring), int(clock.snapshot(100100).quality));
    TEST_ASSERT_FALSE(clock.snapshot(100100).valid);
}
void acquires_repeated_time_and_backdates_same_boot() {
    Clock clock; sync(clock, 5000); uint64_t value;
    Snapshot state = clock.snapshot(8000);
    TEST_ASSERT_TRUE(state.valid); TEST_ASSERT_EQUAL_UINT64(epoch + 3000, state.utcMs);
    TEST_ASSERT_TRUE(state.utcFor(0, value)); TEST_ASSERT_EQUAL_UINT64(epoch - 5000, value);
    TEST_ASSERT_FALSE(state.utcFor(9000, value));
    state = clock.snapshot(40000);
    TEST_ASSERT_EQUAL_INT(int(Quality::Holdover), int(state.quality));
    TEST_ASSERT_EQUAL_UINT64(epoch + 35000, state.utcMs);
}
void rejects_bad_sources_dates_and_frozen_clock() {
    uint64_t value;
    TEST_ASSERT_FALSE(decodeUtc(0xffff, 100, value));
    TEST_ASSERT_FALSE(decodeUtc(20000, 86400, value));
    TEST_ASSERT_FALSE(decodeUtc(20000, std::numeric_limits<double>::quiet_NaN(), value));
    TEST_ASSERT_TRUE(decodeUtc(20000, 0.0001, value));
    Clock clock;
    TEST_ASSERT_FALSE(clock.observe(epoch, 0, 0, 20, 129029));
    TEST_ASSERT_FALSE(clock.observe(epoch, 0, 1, 254, 129029));
    clock.observe(epoch, 0, 1, 20, 129029);
    clock.observe(epoch, 1000, 1, 20, 129029);
    clock.observe(epoch, 2000, 1, 20, 129029);
    TEST_ASSERT_FALSE(clock.snapshot(2000).valid);
}
void jumps_are_quarantined_without_rewriting_history() {
    Clock clock; sync(clock);
    TEST_ASSERT_FALSE(clock.observe(epoch + 3603000, 3000, 1, 20, 129029));
    Snapshot state = clock.snapshot(4000);
    TEST_ASSERT_EQUAL_INT(int(Quality::Quarantined), int(state.quality));
    TEST_ASSERT_EQUAL_UINT64(epoch + 4000, state.utcMs);
    TEST_ASSERT_FALSE(clock.observe(epoch + 4000, 4000, 1, 20, 129029));
    TEST_ASSERT_FALSE(clock.observe(epoch + 5000, 5000, 1, 20, 129029));
    TEST_ASSERT_TRUE(clock.observe(epoch + 6000, 6000, 1, 20, 129029));
    TEST_ASSERT_EQUAL_INT(int(Quality::Synchronized), int(clock.snapshot(6000).quality));
}
void source_name_survives_address_change_and_switch_needs_reacquisition() {
    Clock clock; sync(clock);
    TEST_ASSERT_TRUE(clock.observe(epoch + 3000, 3000, 1, 41, 129029));
    TEST_ASSERT_EQUAL_UINT8(41, clock.snapshot(3000).sourceAddress);
    TEST_ASSERT_FALSE(clock.observe(epoch + 4000, 4000, 2, 20, 126992));
    TEST_ASSERT_EQUAL_UINT64(1, clock.snapshot(4000).sourceName);
    TEST_ASSERT_FALSE(clock.observe(epoch + 40000, 40000, 2, 20, 126992));
    TEST_ASSERT_FALSE(clock.observe(epoch + 41000, 41000, 2, 20, 126992));
    TEST_ASSERT_TRUE(clock.observe(epoch + 42000, 42000, 2, 20, 126992));
    TEST_ASSERT_EQUAL_UINT64(2, clock.snapshot(42000).sourceName);
}
void monotonic_has_no_32_bit_wrap() {
    Clock clock; const uint64_t base = 0xfffffff0ULL; sync(clock, base);
    const auto state = clock.snapshot(base + 5000);
    TEST_ASSERT_EQUAL_UINT64(epoch + 5000, state.utcMs);
    TEST_ASSERT_EQUAL_UINT64(base + 5000, state.monotonicMs);
}
void interleaved_time_pgns_acquire_and_holdover_requires_three_new_anchors() {
    Clock clock;
    TEST_ASSERT_FALSE(clock.observe(epoch, 0, 1, 20, 129029));
    TEST_ASSERT_FALSE(clock.observe(epoch + 1000, 1000, 1, 20, 126992));
    TEST_ASSERT_TRUE(clock.observe(epoch + 2000, 2000, 1, 20, 129029));
    TEST_ASSERT_FALSE(clock.observe(epoch + 40000, 40000, 1, 20, 129029));
    TEST_ASSERT_EQUAL_INT(int(Quality::Holdover), int(clock.snapshot(40000).quality));
    TEST_ASSERT_FALSE(clock.observe(epoch + 41000, 41000, 1, 20, 129029));
    TEST_ASSERT_TRUE(clock.observe(epoch + 42000, 42000, 1, 20, 129029));
}
void inconsistent_clock_rate_does_not_acquire() {
    Clock clock;
    clock.observe(epoch,0,1,20,129029);
    clock.observe(epoch+2000,1000,1,20,129029);
    clock.observe(epoch+4000,2000,1,20,129029);
    TEST_ASSERT_FALSE(clock.snapshot(2000).valid);
}
int main() {
    UNITY_BEGIN();
    RUN_TEST(unknown_never_invents_calendar_time);
    RUN_TEST(acquires_repeated_time_and_backdates_same_boot);
    RUN_TEST(rejects_bad_sources_dates_and_frozen_clock);
    RUN_TEST(jumps_are_quarantined_without_rewriting_history);
    RUN_TEST(source_name_survives_address_change_and_switch_needs_reacquisition);
    RUN_TEST(monotonic_has_no_32_bit_wrap);
    RUN_TEST(interleaved_time_pgns_acquire_and_holdover_requires_three_new_anchors);
    RUN_TEST(inconsistent_clock_rate_does_not_acquire);
    return UNITY_END();
}
