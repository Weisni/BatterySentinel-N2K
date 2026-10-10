#include <unity.h>
#include <DebugDisplayModel.h>
#include <cstring>
#include <limits>

using namespace bs::debugdisplay;

namespace {
Snapshot healthy() {
    Snapshot s;
    s.nowMs = 20000; s.uptimeMs = 20000; s.serviceReady = true;
    s.canRunning = true; s.canReceived = true; s.canLastReceivedMs = 15000;
    s.orionConfigured = true; s.orionReceived = true; s.orionReceivedAtMs = 10000;
    s.input.voltage = {12.34, true}; s.input.current = {5.6, true};
    s.output.voltage = {13.50, true}; s.output.current = {-2.0, true};
    s.orionRssi = -67; s.orionAccepted = 1234; s.orionErrors = 2;
    s.canReceivedFrames = 4567; s.canTxFailures = 8;
    s.timeQuality = TimeQuality::Synchronized; s.utcValid = true;
    s.utcMs = 45296000; s.timeAgeMs = 1000;
    s.heapFree = 102400; s.heapMinimum = 51200; s.wifiClients = 1; s.httpsClients = 1;
    s.notificationsEnabled = true; s.activeAlerts = 2; s.unacknowledgedAlerts = 1;
    s.chargerState = 3; s.chargerError = 0;
    return s;
}
Frame renderPage(uint8_t page, const Snapshot& snapshot) {
    Pager pager;
    pager.due(0);
    for (uint8_t i = 0; i < page; ++i) pager.due(uint32_t(i + 1) * 2000);
    Frame frame;
    pager.render(snapshot, frame);
    return frame;
}
void fits(const Frame& frame) {
    const char* lines[] = {frame.status, frame.rows[0], frame.rows[1], frame.rows[2]};
    for (const char* line : lines) {
        const void* end = std::memchr(line, 0, 13);
        TEST_ASSERT_NOT_NULL(end);
        for (const char* p = line; *p; ++p) {
            TEST_ASSERT_TRUE(*p >= 32 && *p <= 126);
        }
        TEST_ASSERT_NULL(std::strstr(line, "nan"));
        TEST_ASSERT_NULL(std::strstr(line, "inf"));
    }
}

// Catches startup omissions and >=/ > cadence mistakes without relying on
// private timer state or the display driver's scheduling implementation.
void initial_frame_and_exact_two_second_boundaries() {
    Pager pager;
    TEST_ASSERT_TRUE(pager.due(0)); TEST_ASSERT_EQUAL_UINT8(0, pager.page());
    TEST_ASSERT_FALSE(pager.due(0)); TEST_ASSERT_FALSE(pager.due(1999));
    TEST_ASSERT_TRUE(pager.due(2000)); TEST_ASSERT_EQUAL_UINT8(1, pager.page());
    TEST_ASSERT_FALSE(pager.due(3999));
    TEST_ASSERT_TRUE(pager.due(4000)); TEST_ASSERT_EQUAL_UINT8(2, pager.page());
}
void delayed_poll_does_not_burst_through_missed_pages() {
    Pager pager;
    TEST_ASSERT_TRUE(pager.due(9123)); TEST_ASSERT_EQUAL_UINT8(0, pager.page());
    TEST_ASSERT_TRUE(pager.due(19123)); TEST_ASSERT_EQUAL_UINT8(1, pager.page());
    TEST_ASSERT_FALSE(pager.due(19123)); TEST_ASSERT_FALSE(pager.due(21122));
    TEST_ASSERT_TRUE(pager.due(21123)); TEST_ASSERT_EQUAL_UINT8(2, pager.page());
}
void page_timer_survives_millis_rollover() {
    Pager pager;
    TEST_ASSERT_TRUE(pager.due(0xffffff00U));
    TEST_ASSERT_FALSE(pager.due(0x000006cfU));
    TEST_ASSERT_TRUE(pager.due(0x000006d0U)); TEST_ASSERT_EQUAL_UINT8(1, pager.page());
    TEST_ASSERT_FALSE(pager.due(0x000006d0U));
}
void all_pages_retain_status_and_loop_back_to_input() {
    Pager pager; Frame frame; const auto s = healthy();
    for (uint8_t i = 0; i <= 7; ++i) {
        TEST_ASSERT_TRUE(pager.due(uint32_t(i) * 2000));
        TEST_ASSERT_EQUAL_UINT8(i == 7 ? 0 : i, pager.page());
        for (char& c : frame.status) c = 'x';
        for (auto& row : frame.rows) for (char& c : row) c = 'x';
        pager.render(s, frame);
        TEST_ASSERT_EQUAL_STRING("W+ N+ O+ T+", frame.status);
        fits(frame);
    }
    TEST_ASSERT_EQUAL_STRING("IN 12.34V", frame.rows[0]);
}
void no_data_status_is_not_falsely_healthy() {
    Snapshot s;
    auto frame = renderPage(0, s);
    TEST_ASSERT_EQUAL_STRING("W- N- O- T-", frame.status);
    s.canRunning = true; s.canTxFailures = 0; s.orionConfigured = true;
    frame = renderPage(0, s);
    TEST_ASSERT_EQUAL_STRING("W- N? O? T-", frame.status);
    TEST_ASSERT_EQUAL_STRING("IN --V", frame.rows[0]);
}
void nmea_health_requires_recent_receive_not_successful_enqueue() {
    auto s = healthy(); s.canReceived = false;
    TEST_ASSERT_EQUAL_STRING("W+ N? O+ T+", renderPage(0, s).status);
    s.canReceived = true; s.canLastReceivedMs = 14999;
    TEST_ASSERT_EQUAL_STRING("W+ N? O+ T+", renderPage(0, s).status);
    s.canLastReceivedMs = 15000;
    TEST_ASSERT_EQUAL_STRING("W+ N+ O+ T+", renderPage(0, s).status);
    s.canTxErrorCount = 127; s.canRxErrorCount = 127;
    TEST_ASSERT_EQUAL_STRING("W+ N+ O+ T+", renderPage(0, s).status);
    s.canTxErrorCount = 128;
    TEST_ASSERT_EQUAL_STRING("W+ N! O+ T+", renderPage(0, s).status);
    s.canTxErrorCount = 0; s.canRxErrorCount = 128;
    TEST_ASSERT_EQUAL_STRING("W+ N! O+ T+", renderPage(0, s).status);
    s.canRxErrorCount = 0; s.canBusOff = true; s.canRunning = false;
    TEST_ASSERT_EQUAL_STRING("W+ N! O+ T+", renderPage(0, s).status);
    s.canBusOff = false; s.canRecovering = true;
    TEST_ASSERT_EQUAL_STRING("W+ N! O+ T+", renderPage(0, s).status);
}
void freshness_and_status_work_across_wrap() {
    auto s = healthy(); s.nowMs = 100; s.canLastReceivedMs = 0xfffffff0;
    s.orionReceivedAtMs = 0xfffffff0;
    TEST_ASSERT_EQUAL_STRING("W+ N+ O+ T+", renderPage(0, s).status);
    s.orionReceivedAtMs = s.nowMs - 10001;
    TEST_ASSERT_EQUAL_STRING("W+ N+ O? T+", renderPage(0, s).status);
    s.orionConfigured = false;
    TEST_ASSERT_EQUAL_STRING("W+ N+ O- T+", renderPage(0, s).status);
}
void time_quality_has_distinct_holdover_and_conflict_marks() {
    auto s = healthy(); s.timeQuality = TimeQuality::Holdover;
    TEST_ASSERT_EQUAL_STRING("W+ N+ O+ T~", renderPage(4, s).status);
    s.timeQuality = TimeQuality::Quarantined;
    TEST_ASSERT_EQUAL_STRING("W+ N+ O+ T!", renderPage(4, s).status);
    s.timeQuality = TimeQuality::Unknown;
    TEST_ASSERT_EQUAL_STRING("W+ N+ O+ T-", renderPage(4, s).status);
}
void channel_pages_keep_units_and_signed_orion_current() {
    const auto input = renderPage(0, healthy());
    TEST_ASSERT_EQUAL_STRING("IN 12.34V", input.rows[0]);
    TEST_ASSERT_EQUAL_STRING("IN 5.6A", input.rows[1]);
    TEST_ASSERT_EQUAL_STRING("IN 69.1W", input.rows[2]);
    const auto output = renderPage(1, healthy());
    TEST_ASSERT_EQUAL_STRING("OUT 13.50V", output.rows[0]);
    TEST_ASSERT_EQUAL_STRING("OUT -2.0A", output.rows[1]);
    TEST_ASSERT_EQUAL_STRING("OUT -27.0W", output.rows[2]);
}
void stale_measurements_are_unavailable_instead_of_last_good_values() {
    auto s = healthy(); s.nowMs += 1;
    auto frame = renderPage(0, s);
    TEST_ASSERT_EQUAL_STRING("IN --V", frame.rows[0]);
    TEST_ASSERT_EQUAL_STRING("IN --A", frame.rows[1]);
    TEST_ASSERT_EQUAL_STRING("IN --W", frame.rows[2]);
    frame = renderPage(2, s);
    TEST_ASSERT_EQUAL_STRING("BLE --dBm", frame.rows[0]);
    TEST_ASSERT_EQUAL_STRING("Age 10s", frame.rows[1]);
}
void invalid_channel_field_does_not_hide_the_other_valid_field() {
    auto s = healthy(); s.input.voltage.valid = false;
    auto frame = renderPage(0, s);
    TEST_ASSERT_EQUAL_STRING("IN --V", frame.rows[0]);
    TEST_ASSERT_EQUAL_STRING("IN 5.6A", frame.rows[1]);
    TEST_ASSERT_EQUAL_STRING("IN --W", frame.rows[2]);
    s = healthy(); s.output.current.valid = false;
    frame = renderPage(1, s);
    TEST_ASSERT_EQUAL_STRING("OUT 13.50V", frame.rows[0]);
    TEST_ASSERT_EQUAL_STRING("OUT --A", frame.rows[1]);
    TEST_ASSERT_EQUAL_STRING("OUT --W", frame.rows[2]);
}
void nonfinite_and_implausible_measurements_never_become_formatted_numbers() {
    const double bad[] = {std::numeric_limits<double>::quiet_NaN(),
        std::numeric_limits<double>::infinity(), -std::numeric_limits<double>::infinity(), 1e99};
    for (const double value : bad) {
        auto s = healthy(); s.input.voltage.number = value; s.input.current.number = value;
        auto frame = renderPage(0, s); fits(frame);
        TEST_ASSERT_EQUAL_STRING("IN --V", frame.rows[0]);
        TEST_ASSERT_EQUAL_STRING("IN --A", frame.rows[1]);
        TEST_ASSERT_EQUAL_STRING("IN --W", frame.rows[2]);
    }
    auto s = healthy(); s.input.voltage.number = -1; s.input.current.number = 151;
    TEST_ASSERT_EQUAL_STRING("IN --V", renderPage(0, s).rows[0]);
    TEST_ASSERT_EQUAL_STRING("IN --A", renderPage(0, s).rows[1]);
}
void diagnostic_pages_identify_counters_clock_memory_and_alerts() {
    auto s = healthy(); s.orionReceivedAtMs = 19000;
    auto frame = renderPage(2, s);
    TEST_ASSERT_EQUAL_STRING("BLE -67dBm", frame.rows[0]);
    TEST_ASSERT_EQUAL_STRING("Age 1s", frame.rows[1]);
    TEST_ASSERT_EQUAL_STRING("R999+ E2", frame.rows[2]);
    frame = renderPage(3, s);
    TEST_ASSERT_EQUAL_STRING("RX 4567", frame.rows[0]);
    TEST_ASSERT_EQUAL_STRING("TXF 8", frame.rows[1]);
    TEST_ASSERT_EQUAL_STRING("E0/0", frame.rows[2]);
    frame = renderPage(4, s);
    TEST_ASSERT_EQUAL_STRING("UTC 12:34:56", frame.rows[0]);
    TEST_ASSERT_EQUAL_STRING("Up 20s", frame.rows[1]);
    TEST_ASSERT_EQUAL_STRING("T age 1s", frame.rows[2]);
    frame = renderPage(5, s);
    TEST_ASSERT_EQUAL_STRING("Heap 100KiB", frame.rows[0]);
    TEST_ASSERT_EQUAL_STRING("Min 50KiB", frame.rows[1]);
    TEST_ASSERT_EQUAL_STRING("W1 H1", frame.rows[2]);
    frame = renderPage(6, s);
    TEST_ASSERT_EQUAL_STRING("Alerts 2", frame.rows[0]);
    TEST_ASSERT_EQUAL_STRING("Unacked 1", frame.rows[1]);
    TEST_ASSERT_EQUAL_STRING("St3 Err0", frame.rows[2]);
}
void unknown_time_and_charger_state_do_not_look_like_zero() {
    Snapshot s;
    auto frame = renderPage(4, s);
    TEST_ASSERT_EQUAL_STRING("UTC --:--:--", frame.rows[0]);
    TEST_ASSERT_EQUAL_STRING("T age --", frame.rows[2]);
    frame = renderPage(6, s);
    TEST_ASSERT_EQUAL_STRING("Alerts off", frame.rows[0]);
    TEST_ASSERT_EQUAL_STRING("St-- Err--", frame.rows[2]);
    s = healthy(); s.chargerState = 255; s.chargerError = 255;
    TEST_ASSERT_EQUAL_STRING("St-- Err--", renderPage(6, s).rows[2]);
}
void large_values_saturate_without_losing_rows_units_or_ascii() {
    auto s = healthy();
    s.uptimeMs = UINT64_MAX; s.utcMs = UINT64_MAX; s.timeAgeMs = UINT64_MAX;
    s.heapFree = UINT32_MAX; s.heapMinimum = UINT32_MAX;
    s.wifiClients = UINT32_MAX; s.httpsClients = UINT32_MAX;
    s.orionAccepted = UINT64_MAX; s.orionErrors = UINT64_MAX; s.orionRssi = INT16_MIN;
    s.canReceivedFrames = UINT64_MAX; s.canTxFailures = UINT64_MAX;
    s.canTxErrorCount = UINT32_MAX; s.canRxErrorCount = UINT32_MAX;
    s.activeAlerts = UINT32_MAX; s.unacknowledgedAlerts = UINT32_MAX;
    s.chargerState = 254; s.chargerError = 254;
    for (uint8_t i = 0; i < 7; ++i) fits(renderPage(i, s));
    TEST_ASSERT_EQUAL_STRING("RX 999999+", renderPage(3, s).rows[0]);
    TEST_ASSERT_EQUAL_STRING("E999+/999+", renderPage(3, s).rows[2]);
    TEST_ASSERT_EQUAL_STRING("Heap 999+KiB", renderPage(5, s).rows[0]);
    TEST_ASSERT_EQUAL_STRING("Unacked 999+", renderPage(6, s).rows[1]);
    TEST_ASSERT_EQUAL_STRING("St254 Err254", renderPage(6, s).rows[2]);
}
void monitoring_disabled_is_distinct_from_enabled_without_incidents() {
    auto s = healthy(); s.activeAlerts = 0; s.unacknowledgedAlerts = 0;
    auto frame = renderPage(6, s);
    TEST_ASSERT_EQUAL_STRING("Alerts 0", frame.rows[0]);
    TEST_ASSERT_EQUAL_STRING("Unacked 0", frame.rows[1]);
    s.notificationsEnabled = false;
    TEST_ASSERT_EQUAL_STRING("Alerts off", renderPage(6, s).rows[0]);
}
void largest_admitted_signed_power_keeps_its_sign_and_unit() {
    auto s = healthy();
    s.output.voltage.number = 65; s.output.current.number = -150;
    auto frame = renderPage(1, s); fits(frame);
    TEST_ASSERT_EQUAL_STRING("OUT 65.00V", frame.rows[0]);
    TEST_ASSERT_EQUAL_STRING("OUT -150.0A", frame.rows[1]);
    TEST_ASSERT_EQUAL_STRING("OUT -9750.0W", frame.rows[2]);
    s.output.current.number = 150;
    TEST_ASSERT_EQUAL_STRING("OUT 9750.0W", renderPage(1, s).rows[2]);
    s.output.current.number = -150.01;
    TEST_ASSERT_EQUAL_STRING("OUT --A", renderPage(1, s).rows[1]);
}
}

void setUp() {}
void tearDown() {}
int main() {
    UNITY_BEGIN();
    RUN_TEST(initial_frame_and_exact_two_second_boundaries);
    RUN_TEST(delayed_poll_does_not_burst_through_missed_pages);
    RUN_TEST(page_timer_survives_millis_rollover);
    RUN_TEST(all_pages_retain_status_and_loop_back_to_input);
    RUN_TEST(no_data_status_is_not_falsely_healthy);
    RUN_TEST(nmea_health_requires_recent_receive_not_successful_enqueue);
    RUN_TEST(freshness_and_status_work_across_wrap);
    RUN_TEST(time_quality_has_distinct_holdover_and_conflict_marks);
    RUN_TEST(channel_pages_keep_units_and_signed_orion_current);
    RUN_TEST(stale_measurements_are_unavailable_instead_of_last_good_values);
    RUN_TEST(invalid_channel_field_does_not_hide_the_other_valid_field);
    RUN_TEST(nonfinite_and_implausible_measurements_never_become_formatted_numbers);
    RUN_TEST(diagnostic_pages_identify_counters_clock_memory_and_alerts);
    RUN_TEST(unknown_time_and_charger_state_do_not_look_like_zero);
    RUN_TEST(large_values_saturate_without_losing_rows_units_or_ascii);
    RUN_TEST(monitoring_disabled_is_distinct_from_enabled_without_incidents);
    RUN_TEST(largest_admitted_signed_power_keeps_its_sign_and_unit);
    return UNITY_END();
}
