#include <unity.h>
#include <BridgeNotificationStore.h>
#include "../../src/BridgeNotificationForm.h"

#include <cstdio>
#include <cstring>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>

using namespace bs::insights;

namespace {
using Bytes = std::vector<uint8_t>;
struct PowerLoss : std::runtime_error { PowerLoss() : std::runtime_error("synthetic power loss") {} };

// Models Preferences' atomic single-entry commit contract. An interrupted
// commit has an old or new complete value; torn-byte corruption is tested
// separately on load. This does not simulate or validate physical flash.
struct Store {
    std::map<std::string, Bytes> values{
        {"pw_cred_v1", Bytes(56, 0x12)}, {"username", {'u', 's', 'e', 'r'}},
        {"orion_key", Bytes(16, 0x34)}, {"orion_mac", Bytes(17, 0x56)},
        {"n2k_in", {1}}, {"n2k_out", {0}}, {"orion_aliases", Bytes(32, 0x78)},
        {"ap_pass", Bytes(20, 0x91)}, {"tls3_cert", Bytes(512, 0xab)},
        {"tls3_key", Bytes(256, 0xcd)}
    };
    size_t writes = 0;
    std::string lastKey;
    bool failWrite = false, shortRead = false;
    bool losePowerBefore = false, losePowerAfter = false;
    bool isKey(const char* key) const { return values.count(key) != 0; }
    size_t getBytesLength(const char* key) const {
        const auto found = values.find(key);
        return found == values.end() ? 0 : found->second.size();
    }
    size_t getBytes(const char* key, void* destination, size_t length) const {
        const auto found = values.find(key);
        if (found == values.end() || found->second.size() > length) return 0;
        const size_t copied = found->second.size() - (shortRead ? 1 : 0);
        std::memcpy(destination, found->second.data(), copied);
        return copied;
    }
    size_t putBytes(const char* key, const void* bytes, size_t length) {
        ++writes; lastKey = key;
        if (losePowerBefore) throw PowerLoss();
        if (failWrite) return 0;
        const auto* input = static_cast<const uint8_t*>(bytes);
        values[key] = Bytes(input, input + length);
        if (losePowerAfter) throw PowerLoss();
        return length;
    }
};

Config custom() {
    Config c;
    c.enabled = true; c.nmeaEnabled = true; c.dataLossEnabled = false;
    c.chargerErrorEnabled = false; c.dataLossDelayS = 60; c.repeatMinutes = 15;
    c.channels[0] = {true, true, 1180, 1250, 1480, 1430, 12, 40};
    c.channels[1] = {false, true, 2300, 2400, 3000, 2900, 20, 60};
    return c;
}
void test_missing_entry_is_not_corruption_and_does_not_mutate() {
    Store store; Config value = custom();
    TEST_ASSERT_EQUAL_INT(int(LoadResult::Missing), int(loadNotifications(store, value)));
    TEST_ASSERT_TRUE(sameConfig(custom(), value));
    TEST_ASSERT_EQUAL_UINT32(0, store.writes);
}
void test_single_blob_round_trip_preserves_all_other_settings() {
    Store store; const auto unrelated = store.values; const Config target = custom();
    TEST_ASSERT_TRUE(saveNotifications(store, target));
    TEST_ASSERT_EQUAL_UINT32(1, store.writes);
    TEST_ASSERT_EQUAL_STRING(kNotificationEntry, store.lastKey.c_str());
    TEST_ASSERT_EQUAL_UINT32(kConfigBlobSize, store.values[kNotificationEntry].size());
    Config rebooted;
    TEST_ASSERT_EQUAL_INT(int(LoadResult::Current), int(loadNotifications(store, rebooted)));
    TEST_ASSERT_TRUE(sameConfig(target, rebooted));
    auto remaining = store.values; remaining.erase(kNotificationEntry);
    TEST_ASSERT_TRUE(remaining == unrelated);
}
void test_invalid_configuration_never_attempts_a_write() {
    Store store; TEST_ASSERT_TRUE(saveNotifications(store, custom()));
    const auto before = store.values;
    Config invalid = custom(); invalid.channels[0].lowClearCv = invalid.channels[0].lowCv;
    TEST_ASSERT_FALSE(saveNotifications(store, invalid));
    TEST_ASSERT_EQUAL_UINT32(1, store.writes);
    TEST_ASSERT_TRUE(store.values == before);
}
void test_failed_write_preserves_previous_value_after_reload() {
    Store store; const Config previous = custom(); TEST_ASSERT_TRUE(saveNotifications(store, previous));
    const auto before = store.values;
    store.failWrite = true;
    TEST_ASSERT_FALSE(saveNotifications(store, Config{}));
    Config rebooted;
    TEST_ASSERT_EQUAL_INT(int(LoadResult::Current), int(loadNotifications(store, rebooted)));
    TEST_ASSERT_TRUE(sameConfig(previous, rebooted));
    TEST_ASSERT_TRUE(store.values == before);
    Store empty; empty.failWrite = true;
    TEST_ASSERT_FALSE(saveNotifications(empty, custom()));
    TEST_ASSERT_EQUAL_INT(int(LoadResult::Missing), int(loadNotifications(empty, rebooted)));
}
void test_power_loss_before_or_after_commit_reloads_a_complete_version() {
    const Config old = custom(), next{};
    for (const bool after : {false, true}) {
        Store store; TEST_ASSERT_TRUE(saveNotifications(store, old));
        const auto before = store.values;
        store.losePowerAfter = after; store.losePowerBefore = !after;
        bool interrupted = false;
        try { saveNotifications(store, next); } catch (const PowerLoss&) { interrupted = true; }
        TEST_ASSERT_TRUE(interrupted);
        Config rebooted;
        TEST_ASSERT_EQUAL_INT(int(LoadResult::Current), int(loadNotifications(store, rebooted)));
        TEST_ASSERT_TRUE(sameConfig(after ? next : old, rebooted));
        auto remaining = store.values, expected = before;
        remaining.erase(kNotificationEntry); expected.erase(kNotificationEntry);
        TEST_ASSERT_TRUE(remaining == expected);
    }
}
void test_bad_length_short_read_and_corruption_preserve_destination() {
    Store baseline; TEST_ASSERT_TRUE(saveNotifications(baseline, Config{}));
    Config destination = custom();
    Store truncated = baseline; truncated.values[kNotificationEntry].pop_back();
    TEST_ASSERT_EQUAL_INT(int(LoadResult::Invalid), int(loadNotifications(truncated, destination)));
    TEST_ASSERT_TRUE(sameConfig(custom(), destination));
    Store oversized = baseline; oversized.values[kNotificationEntry].push_back(0);
    TEST_ASSERT_EQUAL_INT(int(LoadResult::Invalid), int(loadNotifications(oversized, destination)));
    Store shortRead = baseline; shortRead.shortRead = true;
    TEST_ASSERT_EQUAL_INT(int(LoadResult::Invalid), int(loadNotifications(shortRead, destination)));
    for (size_t i = 0; i < kConfigBlobSize; ++i) {
        Store corrupt = baseline; corrupt.values[kNotificationEntry][i] ^= 1;
        TEST_ASSERT_EQUAL_INT(int(LoadResult::Invalid), int(loadNotifications(corrupt, destination)));
        TEST_ASSERT_TRUE(sameConfig(custom(), destination));
        TEST_ASSERT_EQUAL_UINT32(1, corrupt.writes);
    }
}
void test_corrupt_boot_stays_disabled_until_explicit_successful_repair() {
    Store store; TEST_ASSERT_TRUE(saveNotifications(store, custom()));
    store.values[kNotificationEntry][3] = 99;
    Config boot;
    TEST_ASSERT_EQUAL_INT(int(LoadResult::Invalid), int(loadNotifications(store, boot)));
    TEST_ASSERT_FALSE(boot.enabled); TEST_ASSERT_FALSE(boot.nmeaEnabled);
    TEST_ASSERT_TRUE(saveNotifications(store, custom()));
    TEST_ASSERT_EQUAL_INT(int(LoadResult::Current), int(loadNotifications(store, boot)));
    TEST_ASSERT_TRUE(sameConfig(custom(), boot));
}
void test_unsigned_parser_handles_full_range_and_does_not_accept_partial_text() {
    uint32_t out = 123;
    TEST_ASSERT_TRUE(parseUnsigned("0", 1, 0, out)); TEST_ASSERT_EQUAL_UINT32(0, out);
    TEST_ASSERT_TRUE(parseUnsigned("4294967295", 10, UINT32_MAX, out));
    TEST_ASSERT_EQUAL_UINT32(UINT32_MAX, out);
    TEST_ASSERT_TRUE(parseUnsigned("0000000005", 10, 5, out)); TEST_ASSERT_EQUAL_UINT32(5, out);
    const char* rejected[] = {"", "4294967296", "00000000000", "-1", "+1", "1e1", "1.0", "1 ", " 1", "0x10", "1a"};
    for (const char* text : rejected) {
        out = 123;
        TEST_ASSERT_FALSE(parseUnsigned(text, std::strlen(text), UINT32_MAX, out));
        TEST_ASSERT_EQUAL_UINT32(123, out);
    }
    TEST_ASSERT_FALSE(parseUnsigned("6", 1, 5, out));
    TEST_ASSERT_FALSE(parseUnsigned("1", 1, 0, out));
    TEST_ASSERT_FALSE(parseUnsigned(nullptr, 1, 5, out));
    const char embedded[] = {'1', 0, '2'};
    TEST_ASSERT_FALSE(parseUnsigned(embedded, sizeof(embedded), UINT32_MAX, out));
}
void test_voltage_parser_accepts_each_representable_centivolt_without_rounding() {
    for (uint16_t cents = 400; cents <= 6500; ++cents) {
        char text[8]; std::snprintf(text, sizeof(text), "%u.%02u", cents / 100, cents % 100);
        uint16_t out = 0;
        TEST_ASSERT_TRUE(parseVoltage(text, std::strlen(text), out));
        TEST_ASSERT_EQUAL_UINT16(cents, out);
    }
    uint16_t out = 0;
    TEST_ASSERT_TRUE(parseVoltage("4", 1, out)); TEST_ASSERT_EQUAL_UINT16(400, out);
    TEST_ASSERT_TRUE(parseVoltage("12.3", 4, out)); TEST_ASSERT_EQUAL_UINT16(1230, out);
    TEST_ASSERT_TRUE(parseVoltage("65", 2, out)); TEST_ASSERT_EQUAL_UINT16(6500, out);
}
void test_voltage_parser_rejects_non_decimal_and_out_of_range_without_mutation() {
    const char* rejected[] = {"", ".4", "4.", "3.99", "65.01", "66", "99999", "12.001", "12..3", "1.2.3", "-12", "+12", "1e1", "NaN", "inf", "12v", "12 ", " 12", "0xC"};
    for (const char* text : rejected) {
        uint16_t out = 1234;
        TEST_ASSERT_FALSE(parseVoltage(text, std::strlen(text), out));
        TEST_ASSERT_EQUAL_UINT16(1234, out);
    }
    uint16_t out = 1234;
    TEST_ASSERT_FALSE(parseVoltage(nullptr, 4, out));
    const char embedded[] = {'1', '2', 0, '3'};
    TEST_ASSERT_FALSE(parseVoltage(embedded, sizeof(embedded), out));
    TEST_ASSERT_EQUAL_UINT16(1234, out);
}
} // namespace

void setUp() {}
void tearDown() {}
int main() {
    UNITY_BEGIN();
    RUN_TEST(test_missing_entry_is_not_corruption_and_does_not_mutate);
    RUN_TEST(test_single_blob_round_trip_preserves_all_other_settings);
    RUN_TEST(test_invalid_configuration_never_attempts_a_write);
    RUN_TEST(test_failed_write_preserves_previous_value_after_reload);
    RUN_TEST(test_power_loss_before_or_after_commit_reloads_a_complete_version);
    RUN_TEST(test_bad_length_short_read_and_corruption_preserve_destination);
    RUN_TEST(test_corrupt_boot_stays_disabled_until_explicit_successful_repair);
    RUN_TEST(test_unsigned_parser_handles_full_range_and_does_not_accept_partial_text);
    RUN_TEST(test_voltage_parser_accepts_each_representable_centivolt_without_rounding);
    RUN_TEST(test_voltage_parser_rejects_non_decimal_and_out_of_range_without_mutation);
    return UNITY_END();
}
