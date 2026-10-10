#include <unity.h>
#include <BridgeInsights.h>
#include <limits>

using namespace bs::insights;

namespace {
bs::orion::Telemetry packet(uint64_t at, uint16_t counter, double input = 12.5,
                            double output = 13.0, double inputCurrent = 10,
                            double outputCurrent = 5, uint8_t error = 0) {
    bs::orion::Telemetry t;
    t.received = true; t.receivedAtMs = uint32_t(at); t.counter = counter;
    t.inputVoltage = {input, true}; t.outputVoltage = {output, true};
    t.inputCurrent = {inputCurrent, true}; t.outputCurrent = {outputCurrent, true};
    t.state = 3; t.error = error;
    return t;
}
Config enabled() {
    Config c; c.enabled = true; c.dataLossDelayS = 10;
    for (auto& channel : c.channels) { channel.delayS = 1; channel.clearS = 3; }
    return c;
}
struct Fixture {
    Engine engine;
    uint16_t counter = 0;
    bs::orion::Telemetry last;
    explicit Fixture(const Config& config = enabled()) { engine.applyConfig(config, 0); }
    void sample(uint64_t at, double input = 12.5, double output = 13.0,
                double inputCurrent = 10, double outputCurrent = 5, uint8_t error = 0) {
        last = packet(at, ++counter, input, output, inputCurrent, outputCurrent, error);
        engine.update(last, at, true);
    }
    void low() { sample(0, 11.9); sample(500, 11.9); sample(1000, 11.9); }
};
size_t countEvents(Engine& e, TransitionKind kind, uint8_t slot) {
    size_t count = 0; Transition t;
    while (e.popTransition(t)) if (t.kind == kind && t.slot == slot) ++count;
    return count;
}
void crc(uint8_t* blob) {
    const auto value = detail::crc32(blob, kConfigBlobSize - 4);
    for (unsigned i = 0; i < 4; ++i) blob[kConfigBlobSize - 4 + i] = uint8_t(value >> (8 * i));
}

void test_config_round_trip_and_ranges() {
    Config c;
    TEST_ASSERT_TRUE(validConfig(c)); TEST_ASSERT_FALSE(c.enabled);
    c.enabled = true; c.nmeaEnabled = true; c.dataLossEnabled = false;
    c.chargerErrorEnabled = false; c.dataLossDelayS = 3600; c.repeatMinutes = 1440;
    c.channels[0] = {false, true, 400, 401, 6500, 6499, 1, 600};
    c.channels[1] = {true, true, 2300, 2400, 3100, 3000, 600, 1};
    uint8_t blob[kConfigBlobSize]{}; Config decoded;
    TEST_ASSERT_TRUE(encodeConfig(c, blob, sizeof(blob)));
    TEST_ASSERT_TRUE(decodeConfig(blob, sizeof(blob), decoded));
    TEST_ASSERT_TRUE(sameConfig(c, decoded));
    TEST_ASSERT_EQUAL_UINT8('B', blob[0]); TEST_ASSERT_EQUAL_UINT8(1, blob[3]);
    TEST_ASSERT_EQUAL_UINT8(0x90, blob[14]); TEST_ASSERT_EQUAL_UINT8(1, blob[15]);
    c.channels[0].lowCv = 399; TEST_ASSERT_FALSE(validConfig(c));
    c.channels[0].lowCv = 400; c.channels[0].highCv = 6501; TEST_ASSERT_FALSE(validConfig(c));
    c = Config{}; c.channels[1].lowClearCv = c.channels[1].lowCv; TEST_ASSERT_FALSE(validConfig(c));
    c = Config{}; c.channels[1].highClearCv = c.channels[1].highCv; TEST_ASSERT_FALSE(validConfig(c));
    c = Config{}; c.channels[1].highClearCv = c.channels[1].lowClearCv; TEST_ASSERT_FALSE(validConfig(c));
    c = Config{}; c.channels[1].delayS = 0; TEST_ASSERT_FALSE(validConfig(c));
    c = Config{}; c.channels[1].clearS = 601; TEST_ASSERT_FALSE(validConfig(c));
    c = Config{}; c.dataLossDelayS = 9; TEST_ASSERT_FALSE(validConfig(c));
    c = Config{}; c.dataLossDelayS = 3601; TEST_ASSERT_FALSE(validConfig(c));
    c = Config{}; c.repeatMinutes = 1441; TEST_ASSERT_FALSE(validConfig(c));
}
void test_blob_rejects_corruption_reserved_flags_and_unknown_version() {
    uint8_t blob[kConfigBlobSize]{};
    Config original = enabled(); Config out;
    TEST_ASSERT_TRUE(encodeConfig(original, blob, sizeof(blob)));
    for (size_t i = 0; i < sizeof(blob); ++i) {
        blob[i] ^= 1;
        TEST_ASSERT_FALSE(decodeConfig(blob, sizeof(blob), out));
        TEST_ASSERT_TRUE(sameConfig(Config{}, out));
        blob[i] ^= 1;
    }
    const size_t reserved[] = {5, 10, 11, 13, 27};
    for (const size_t i : reserved) {
        encodeConfig(original, blob, sizeof(blob)); blob[i] = 1; crc(blob);
        TEST_ASSERT_FALSE(decodeConfig(blob, sizeof(blob), out));
    }
    encodeConfig(original, blob, sizeof(blob)); blob[4] |= 128; crc(blob);
    TEST_ASSERT_FALSE(decodeConfig(blob, sizeof(blob), out));
    encodeConfig(original, blob, sizeof(blob)); blob[12] |= 4; crc(blob);
    TEST_ASSERT_FALSE(decodeConfig(blob, sizeof(blob), out));
    encodeConfig(original, blob, sizeof(blob)); blob[3] = 2; crc(blob);
    TEST_ASSERT_FALSE(decodeConfig(blob, sizeof(blob), out));
    encodeConfig(original, blob, sizeof(blob)); detail::put16(blob + 14, 100); crc(blob);
    TEST_ASSERT_FALSE(decodeConfig(blob, sizeof(blob), out));
    TEST_ASSERT_FALSE(decodeConfig(nullptr, sizeof(blob), out));
    TEST_ASSERT_FALSE(decodeConfig(blob, sizeof(blob) - 1, out));
    TEST_ASSERT_FALSE(encodeConfig(original, nullptr, sizeof(blob)));
}
void test_low_limit_is_strict_and_three_samples_are_required() {
    Fixture f;
    f.sample(0, 12); f.sample(1000, 12); f.sample(2000, 12);
    TEST_ASSERT_FALSE(f.engine.snapshot(2000).alerts[0].pending);
    f.sample(3000, 11.9); f.sample(4500, 11.9);
    TEST_ASSERT_FALSE(f.engine.snapshot(4500).alerts[0].active);
    f.sample(5000, 11.9);
    auto s = f.engine.snapshot(5000);
    TEST_ASSERT_TRUE(s.alerts[0].active); TEST_ASSERT_FALSE(s.alerts[1].active);
    TEST_ASSERT_EQUAL_UINT32(1, s.alerts[0].generation);
    TEST_ASSERT_EQUAL_UINT64(5000, s.alerts[0].activatedAtMs);
    TEST_ASSERT_EQUAL(1, countEvents(f.engine, TransitionKind::Activated, 0));
}
void test_hysteresis_clear_and_new_incident() {
    Fixture f; f.low();
    f.sample(2000, 12); f.sample(3000, 12.29); f.sample(4000, 12.30);
    f.sample(5000, 12.30); TEST_ASSERT_TRUE(f.engine.snapshot(5000).alerts[0].active);
    f.sample(7000, 12.30); TEST_ASSERT_FALSE(f.engine.snapshot(7000).alerts[0].active);
    TEST_ASSERT_EQUAL(1, countEvents(f.engine, TransitionKind::Cleared, 0));
    f.sample(8000, 11.9); f.sample(8500, 11.9); f.sample(9000, 11.9);
    TEST_ASSERT_TRUE(f.engine.snapshot(9000).alerts[0].active);
    TEST_ASSERT_EQUAL_UINT32(2, f.engine.snapshot(9000).alerts[0].generation);
}
void test_high_voltage_uses_its_own_strict_limit_and_inclusive_clear() {
    Config c = enabled(); c.channels[1].highEnabled = true; Fixture f(c);
    f.sample(0, 12.5, 15); f.sample(1000, 12.5, 15); f.sample(2000, 12.5, 15);
    TEST_ASSERT_FALSE(f.engine.snapshot(2000).alerts[3].active);
    f.sample(3000, 12.5, 15.01); f.sample(3500, 12.5, 15.01); f.sample(4000, 12.5, 15.01);
    TEST_ASSERT_TRUE(f.engine.snapshot(4000).alerts[3].active);
    f.sample(5000, 12.5, 14.71); f.sample(6000, 12.5, 14.70);
    f.sample(7000, 12.5, 14.70); f.sample(9000, 12.5, 14.70);
    TEST_ASSERT_FALSE(f.engine.snapshot(9000).alerts[3].active);
}
void test_duplicates_retimed_duplicate_and_same_time_do_not_advance() {
    Fixture f; f.sample(0, 11.9);
    f.engine.update(f.last, 1000, true);
    auto t = f.last; t.receivedAtMs = 2000; f.engine.update(t, 2000, true);
    t = f.last; t.counter += 1; f.engine.update(t, 3000, true);
    auto s = f.engine.snapshot(3000);
    TEST_ASSERT_EQUAL_UINT64(1, s.acceptedSamples);
    TEST_ASSERT_FALSE(s.alerts[0].active); TEST_ASSERT_EQUAL_UINT64(0, s.channels[0].coveredMs);
    f.sample(4000, 11.9); TEST_ASSERT_FALSE(f.engine.snapshot(4000).alerts[0].active);
    f.sample(5000, 11.9); TEST_ASSERT_TRUE(f.engine.snapshot(5000).alerts[0].active);
}
void test_gaps_reset_pending_and_preserve_active_unknown() {
    Fixture f; f.sample(0, 11.9); f.sample(500, 11.9); f.sample(5501, 11.9);
    TEST_ASSERT_FALSE(f.engine.snapshot(5501).alerts[0].active);
    f.sample(6000, 11.9); f.sample(6501, 11.9);
    TEST_ASSERT_TRUE(f.engine.snapshot(6501).alerts[0].active);
    f.engine.update(f.last, 11502, true);
    const auto s = f.engine.snapshot(11502);
    TEST_ASSERT_TRUE(s.alerts[0].active); TEST_ASSERT_FALSE(s.alerts[0].known);
    TEST_ASSERT_FALSE(s.channels[0].voltageValid); TEST_ASSERT_FALSE(s.channels[0].trendValid);
    f.sample(12000, 12.5); f.sample(13000, 12.5); f.sample(19000, 12.5);
    TEST_ASSERT_TRUE(f.engine.snapshot(19000).alerts[0].active);
    f.sample(20000, 12.5); f.sample(22000, 12.5);
    TEST_ASSERT_FALSE(f.engine.snapshot(22000).alerts[0].active);
}
void test_chatter_and_invalid_fields_break_qualification() {
    Fixture f; f.sample(0, 11.9); f.sample(500, 11.9); f.sample(1000, 12.0);
    f.sample(2000, 11.9); f.sample(2500, 11.9);
    auto t = packet(3000, ++f.counter, 11.9); t.inputVoltage.valid = false;
    f.engine.update(t, 3000, true); f.sample(4000, 11.9); f.sample(4500, 11.9);
    TEST_ASSERT_FALSE(f.engine.snapshot(4500).alerts[0].active);
    f.sample(5000, 11.9); TEST_ASSERT_TRUE(f.engine.snapshot(5000).alerts[0].active);
}
void test_integration_uses_trapezoid_and_covered_intervals_only() {
    Fixture f; f.sample(0, 12, 13, 10, 5); f.sample(5000, 14, 15, 20, 15);
    auto s = f.engine.snapshot(5000);
    TEST_ASSERT_DOUBLE_WITHIN(1e-12, 15.0 * 5 / 3600, s.channels[0].transferAh);
    TEST_ASSERT_DOUBLE_WITHIN(1e-12, 200.0 * 5 / 3600, s.channels[0].transferWh);
    TEST_ASSERT_DOUBLE_WITHIN(1e-12, 10.0 * 5 / 3600, s.channels[1].transferAh);
    TEST_ASSERT_EQUAL_UINT64(5000, s.channels[0].transferCoveredMs);
    f.engine.update(f.last, 9000, true);
    TEST_ASSERT_DOUBLE_WITHIN(1e-12, s.channels[0].transferWh, f.engine.snapshot(9000).channels[0].transferWh);
    f.sample(10001, 14, 15, 20, 15); f.sample(11001, 14, 15, 20, 15);
    s = f.engine.snapshot(11001);
    TEST_ASSERT_EQUAL_UINT64(6000, s.channels[0].transferCoveredMs);
    TEST_ASSERT_DOUBLE_WITHIN(1e-12, (200.0 * 5 + 280.0) / 3600, s.channels[0].transferWh);
}
void test_reverse_and_invalid_current_never_fabricate_transfer() {
    Fixture f; f.sample(0); f.sample(1000);
    const double initial = f.engine.snapshot(1000).channels[0].transferAh;
    f.sample(2000, 12.5, 13, 10, -0.1); f.sample(3000);
    TEST_ASSERT_DOUBLE_WITHIN(1e-12, initial, f.engine.snapshot(3000).channels[0].transferAh);
    f.sample(4000, 12.5, 13, 6553, 5);
    f.sample(5000, 12.5, 13, std::numeric_limits<double>::infinity(), 5);
    f.sample(6000, 12.5, 13, std::numeric_limits<double>::quiet_NaN(), 5);
    f.sample(7000);
    auto s = f.engine.snapshot(7000);
    TEST_ASSERT_DOUBLE_WITHIN(1e-12, initial, s.channels[0].transferAh);
    TEST_ASSERT_EQUAL_UINT64(7000, s.channels[0].coveredMs);
    f.sample(8000); TEST_ASSERT_EQUAL_UINT64(2000, f.engine.snapshot(8000).channels[0].transferCoveredMs);
}
void test_invalid_voltage_extrema_and_low_time_are_conservative() {
    Fixture f; f.sample(0, 11.9); f.sample(1000, 11.8); f.sample(2000, 12.5);
    f.sample(3000, -1); f.sample(4000, 66); f.sample(5000, std::numeric_limits<double>::quiet_NaN());
    f.sample(6000, 1e30); f.sample(7000, 11.7);
    auto s = f.engine.snapshot(7000);
    TEST_ASSERT_DOUBLE_WITHIN(1e-12, 11.7, s.channels[0].minimumVoltage);
    TEST_ASSERT_DOUBLE_WITHIN(1e-12, 12.5, s.channels[0].maximumVoltage);
    TEST_ASSERT_EQUAL_UINT64(1000, s.channels[0].belowLowMs);
    TEST_ASSERT_EQUAL_UINT64(2000, s.channels[0].coveredMs);
    TEST_ASSERT_EQUAL_UINT16(1, s.channels[0].historySamples);
}
void test_arrival_epoch_rollover_counter_rollover_and_queue_age() {
    Engine e; e.applyConfig(enabled(), 0);
    const uint64_t start = 0xfffffff0ULL;
    e.update(packet(start, 65535), start + 100, true);
    e.update(packet(start + 1000, 0), start + 1200, true);
    auto s = e.snapshot(start + 1200);
    TEST_ASSERT_EQUAL_UINT64(start + 1000, s.lastSampleAtMs);
    TEST_ASSERT_EQUAL_UINT64(1000, s.channels[0].transferCoveredMs);
    TEST_ASSERT_EQUAL_UINT64(2, s.acceptedSamples);
    e.update(packet(start + 2000, 1), start + 8000, true);
    TEST_ASSERT_EQUAL_UINT64(2, e.snapshot(start + 8000).acceptedSamples);
    e.update(packet(start + 9000, 2), start + 9000, true);
    TEST_ASSERT_EQUAL_UINT64(1000, e.snapshot(start + 9000).channels[0].transferCoveredMs);
}
void test_backwards_time_and_out_of_order_arrival_are_rejected() {
    Fixture f; f.sample(1000); f.sample(2000);
    f.engine.update(packet(3000, 3), 1500, true);
    f.engine.update(packet(1000, 4), 2500, true);
    TEST_ASSERT_EQUAL_UINT64(2, f.engine.snapshot(2500).acceptedSamples);
    Config c = enabled(); c.channels[0].lowCv = 1100;
    TEST_ASSERT_FALSE(f.engine.applyConfig(c, 1500));
}
void test_history_is_bounded_chronological_and_regression_uses_actual_time() {
    Fixture f;
    for (uint16_t i = 0; i <= 61; ++i) f.sample(uint64_t(i) * 1000, 12 + double(i) / 100);
    auto s = f.engine.snapshot(61000);
    TEST_ASSERT_EQUAL_UINT16(60, s.channels[0].historySamples);
    TEST_ASSERT_EQUAL_UINT64(2000, s.channels[0].history[0].atMs);
    TEST_ASSERT_EQUAL_UINT64(61000, s.channels[0].history[59].atMs);
    TEST_ASSERT_EQUAL_UINT64(59000, s.channels[0].trendSpanMs);
    TEST_ASSERT_TRUE(s.channels[0].trendValid);
    TEST_ASSERT_DOUBLE_WITHIN(1e-9, 0.6, s.channels[0].trendVoltsPerMinute);
    f.sample(67000, 12.5);
    TEST_ASSERT_EQUAL_UINT16(1, f.engine.snapshot(67000).channels[0].historySamples);
    TEST_ASSERT_FALSE(f.engine.snapshot(67000).channels[0].trendValid);
}
void test_data_loss_boot_delay_recovery_and_unconfigured_state() {
    Fixture f;
    f.engine.update({}, 0, false); f.engine.update({}, 30000, false);
    TEST_ASSERT_FALSE(f.engine.snapshot(30000).alerts[4].enabled);
    f.engine.update({}, 40000, true); f.engine.update({}, 49999, true);
    TEST_ASSERT_FALSE(f.engine.snapshot(49999).alerts[4].active);
    f.engine.update({}, 50000, true);
    TEST_ASSERT_TRUE(f.engine.snapshot(50000).alerts[4].active);
    f.sample(51000); f.sample(52000);
    TEST_ASSERT_TRUE(f.engine.snapshot(52000).alerts[4].active);
    f.sample(53000); TEST_ASSERT_FALSE(f.engine.snapshot(53000).alerts[4].active);
    f.engine.update(f.last, 63000, true);
    TEST_ASSERT_TRUE(f.engine.snapshot(63000).alerts[4].active);
}
void test_error_is_qualified_and_unknown_does_not_recover() {
    Fixture f; f.sample(0, 12.5, 13, 10, 5, 17); f.sample(5000, 12.5, 13, 10, 5, 17);
    TEST_ASSERT_FALSE(f.engine.snapshot(5000).alerts[5].active);
    f.sample(10000, 12.5, 13, 10, 5, 17);
    TEST_ASSERT_TRUE(f.engine.snapshot(10000).alerts[5].active);
    f.sample(11000, 12.5, 13, 10, 5, 255);
    TEST_ASSERT_TRUE(f.engine.snapshot(11000).alerts[5].active);
    TEST_ASSERT_FALSE(f.engine.snapshot(11000).alerts[5].known);
    for (uint64_t at = 12000; at <= 42000; at += 5000) f.sample(at);
    TEST_ASSERT_FALSE(f.engine.snapshot(42000).alerts[5].active);
}
void test_acknowledgement_reminders_and_rearm_are_separate() {
    Config c = enabled(); c.repeatMinutes = 1; Fixture f(c); f.low();
    f.engine.update(f.last, 61000, true);
    TEST_ASSERT_EQUAL(1, countEvents(f.engine, TransitionKind::Reminder, 0));
    TEST_ASSERT_TRUE(f.engine.acknowledge(0, 61000));
    TEST_ASSERT_FALSE(f.engine.acknowledge(0, 61000));
    TEST_ASSERT_FALSE(f.engine.acknowledge(6, 61000));
    f.engine.update(f.last, 121000, true);
    auto s = f.engine.snapshot(121000);
    TEST_ASSERT_TRUE(s.alerts[0].active); TEST_ASSERT_TRUE(s.alerts[0].acknowledged);
    TEST_ASSERT_EQUAL(0, countEvents(f.engine, TransitionKind::Reminder, 0));
    f.sample(122000); f.sample(123000); f.sample(125000);
    f.sample(126000, 11.9); f.sample(126500, 11.9); f.sample(127000, 11.9);
    s = f.engine.snapshot(127000);
    TEST_ASSERT_TRUE(s.alerts[0].active); TEST_ASSERT_FALSE(s.alerts[0].acknowledged);
    TEST_ASSERT_EQUAL_UINT32(2, s.alerts[0].generation);
}
void test_config_changes_cancel_only_affected_rules_and_preserve_totals() {
    Fixture f; f.sample(0, 11.9, 11.8); f.sample(500, 11.9, 11.8); f.sample(1000, 11.9, 11.8);
    auto c = f.engine.config(); c.nmeaEnabled = true;
    TEST_ASSERT_TRUE(f.engine.applyConfig(c, 1000));
    TEST_ASSERT_TRUE(f.engine.snapshot(1000).alerts[0].active);
    c.channels[0].lowCv = 1100; TEST_ASSERT_TRUE(f.engine.applyConfig(c, 1000));
    auto s = f.engine.snapshot(1000);
    TEST_ASSERT_FALSE(s.alerts[0].active); TEST_ASSERT_TRUE(s.alerts[1].active);
    TEST_ASSERT_EQUAL_UINT64(0, s.channels[0].belowLowMs);
    TEST_ASSERT_EQUAL_UINT64(1000, s.channels[1].belowLowMs);
    TEST_ASSERT_EQUAL_UINT64(1000, s.channels[0].transferCoveredMs);
    TEST_ASSERT_EQUAL(1, countEvents(f.engine, TransitionKind::Cancelled, 0));
    c.enabled = false; f.engine.applyConfig(c, 1000);
    TEST_ASSERT_FALSE(f.engine.snapshot(1000).alerts[1].active);
    TEST_ASSERT_FALSE(f.engine.snapshot(1000).alerts[1].enabled);
    TEST_ASSERT_EQUAL(1, countEvents(f.engine, TransitionKind::Cancelled, 1));
    f.sample(2000, 11.9, 11.8);
    TEST_ASSERT_EQUAL_UINT64(2000, f.engine.snapshot(2000).channels[0].transferCoveredMs);
}
void test_invalid_configuration_leaves_engine_unchanged() {
    Fixture f; f.low(); const auto before = f.engine.config();
    Config c = before; c.channels[0].clearS = 0;
    TEST_ASSERT_FALSE(f.engine.applyConfig(c, 1000));
    TEST_ASSERT_TRUE(sameConfig(before, f.engine.config()));
    TEST_ASSERT_TRUE(f.engine.snapshot(1000).alerts[0].active);
}
void test_disabled_rules_still_observe_and_enabling_requires_new_samples() {
    Config c = enabled(); c.enabled = false; Fixture f(c); f.low();
    TEST_ASSERT_FALSE(f.engine.snapshot(1000).alerts[0].enabled);
    TEST_ASSERT_EQUAL_UINT64(1000, f.engine.snapshot(1000).channels[0].coveredMs);
    c.enabled = true; TEST_ASSERT_TRUE(f.engine.applyConfig(c, 1000));
    f.engine.update(f.last, 3000, true);
    TEST_ASSERT_FALSE(f.engine.snapshot(3000).alerts[0].pending);
    f.sample(4000, 11.9); f.sample(5000, 11.9);
    TEST_ASSERT_FALSE(f.engine.snapshot(5000).alerts[0].active);
    f.sample(6000, 11.9); TEST_ASSERT_TRUE(f.engine.snapshot(6000).alerts[0].active);
}
void test_threshold_change_does_not_count_time_before_new_limit() {
    Fixture f; f.sample(0, 11); f.sample(1000, 11);
    Config c = f.engine.config(); c.channels[0].lowCv = 1150;
    TEST_ASSERT_TRUE(f.engine.applyConfig(c, 1500));
    f.sample(2000, 11);
    TEST_ASSERT_EQUAL_UINT64(0, f.engine.snapshot(2000).channels[0].belowLowMs);
    TEST_ASSERT_EQUAL_UINT64(2000, f.engine.snapshot(2000).channels[0].coveredMs);
    f.sample(3000, 11);
    TEST_ASSERT_EQUAL_UINT64(1000, f.engine.snapshot(3000).channels[0].belowLowMs);
}
void test_all_mutations_guard_the_monotonic_epoch_and_direct_snapshot() {
    Fixture f; f.low();
    TEST_ASSERT_TRUE(f.engine.acknowledge(0, 2000));
    f.engine.update(packet(1500, ++f.counter, 12.5), 1500, true);
    Snapshot snapshot;
    f.engine.snapshot(2000, snapshot);
    TEST_ASSERT_EQUAL_UINT64(3, snapshot.acceptedSamples);
    TEST_ASSERT_TRUE(snapshot.alerts[0].acknowledged);
    TEST_ASSERT_EQUAL_UINT64(2000, f.engine.alert(0).changedAtMs);
    auto config = f.engine.config(); config.nmeaEnabled = true;
    TEST_ASSERT_TRUE(f.engine.applyConfig(config, 3000));
    f.engine.resetObservations(2500);
    TEST_ASSERT_TRUE(f.engine.alert(0).active);
    TEST_ASSERT_FALSE(f.engine.alert(255).active);
}
void test_source_reset_cancels_incidents_and_discards_previous_source_totals() {
    Fixture f; f.low(); const auto before = f.engine.snapshot(1000);
    f.engine.resetObservations(1000);
    auto s = f.engine.snapshot(1000);
    TEST_ASSERT_FALSE(s.fresh); TEST_ASSERT_FALSE(s.alerts[0].active);
    TEST_ASSERT_FALSE(s.channels[0].hasExtrema); TEST_ASSERT_EQUAL_UINT64(0, s.acceptedSamples);
    TEST_ASSERT_TRUE(s.alerts[0].sequence > before.alerts[0].sequence);
    f.sample(2000, 11.9); TEST_ASSERT_FALSE(f.engine.snapshot(2000).alerts[0].active);
    TEST_ASSERT_EQUAL_UINT64(0, f.engine.snapshot(2000).channels[0].transferCoveredMs);
}
void test_event_queue_is_bounded_with_visible_loss_and_ordered_sequence() {
    Fixture f;
    auto c = f.engine.config();
    for (size_t i = 0; i < 100; ++i) { c.nmeaEnabled = !c.nmeaEnabled; f.engine.applyConfig(c, i); }
    TEST_ASSERT_TRUE(f.engine.snapshot(100).droppedTransitions > 0);
    Transition t; uint32_t previous = 0; size_t count = 0;
    while (f.engine.popTransition(t)) {
        TEST_ASSERT_TRUE(t.sequence > previous); previous = t.sequence; ++count;
    }
    TEST_ASSERT_EQUAL(kTransitionCapacity, count);
    TEST_ASSERT_TRUE(sizeof(Engine) < 8192);
}
} // namespace

void setUp() {}
void tearDown() {}
int main() {
    UNITY_BEGIN();
    RUN_TEST(test_config_round_trip_and_ranges);
    RUN_TEST(test_blob_rejects_corruption_reserved_flags_and_unknown_version);
    RUN_TEST(test_low_limit_is_strict_and_three_samples_are_required);
    RUN_TEST(test_hysteresis_clear_and_new_incident);
    RUN_TEST(test_high_voltage_uses_its_own_strict_limit_and_inclusive_clear);
    RUN_TEST(test_duplicates_retimed_duplicate_and_same_time_do_not_advance);
    RUN_TEST(test_gaps_reset_pending_and_preserve_active_unknown);
    RUN_TEST(test_chatter_and_invalid_fields_break_qualification);
    RUN_TEST(test_integration_uses_trapezoid_and_covered_intervals_only);
    RUN_TEST(test_reverse_and_invalid_current_never_fabricate_transfer);
    RUN_TEST(test_invalid_voltage_extrema_and_low_time_are_conservative);
    RUN_TEST(test_arrival_epoch_rollover_counter_rollover_and_queue_age);
    RUN_TEST(test_backwards_time_and_out_of_order_arrival_are_rejected);
    RUN_TEST(test_history_is_bounded_chronological_and_regression_uses_actual_time);
    RUN_TEST(test_data_loss_boot_delay_recovery_and_unconfigured_state);
    RUN_TEST(test_error_is_qualified_and_unknown_does_not_recover);
    RUN_TEST(test_acknowledgement_reminders_and_rearm_are_separate);
    RUN_TEST(test_config_changes_cancel_only_affected_rules_and_preserve_totals);
    RUN_TEST(test_invalid_configuration_leaves_engine_unchanged);
    RUN_TEST(test_disabled_rules_still_observe_and_enabling_requires_new_samples);
    RUN_TEST(test_threshold_change_does_not_count_time_before_new_limit);
    RUN_TEST(test_all_mutations_guard_the_monotonic_epoch_and_direct_snapshot);
    RUN_TEST(test_source_reset_cancels_incidents_and_discards_previous_source_totals);
    RUN_TEST(test_event_queue_is_bounded_with_visible_loss_and_ordered_sequence);
    return UNITY_END();
}
