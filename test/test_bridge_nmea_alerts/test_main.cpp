#include <unity.h>
#include <BridgeNmeaAlerts.h>

using namespace bs::alerts;
void setUp() {}
void tearDown() {}
void golden_alert_bytes_match_field_definition() {
    Identity id{0x0807060504030201ULL, 1, 12, 7};
    const auto packet = alertPacket(id, State::Active);
    const uint8_t expected[] = {0x15,0,0,2,0,1,2,3,4,5,6,7,8,12,1,7,
        0xc0,255,255,255,255,255,255,255,255,0x31,5,2};
    TEST_ASSERT_EQUAL_UINT32(126983, packet.pgn);
    TEST_ASSERT_EQUAL_UINT32(sizeof(expected), packet.size);
    TEST_ASSERT_EQUAL_UINT8_ARRAY(expected, packet.bytes, sizeof(expected));
    const auto clear = alertPacket(id, State::Normal);
    TEST_ASSERT_EQUAL_UINT8(1, clear.bytes[25]); TEST_ASSERT_EQUAL_UINT8(1, clear.bytes[27]);
    const auto disabled = alertPacket(id, State::Disabled);
    TEST_ASSERT_EQUAL_UINT8(3, disabled.bytes[25]); TEST_ASSERT_EQUAL_UINT8(0, disabled.bytes[27]);
}
void text_uses_matching_identity_and_two_lau_fields() {
    Identity id{123, 0, 3, 9}; const auto packet = textPacket(id);
    const auto state = alertPacket(id, State::Active);
    TEST_ASSERT_EQUAL_UINT32(126985, packet.pgn);
    TEST_ASSERT_EQUAL_UINT8_ARRAY(state.bytes, packet.bytes, 16);
    TEST_ASSERT_EQUAL_UINT8(0, packet.bytes[16]);
    size_t offset = 17;
    TEST_ASSERT_EQUAL_UINT8(1, packet.bytes[offset + 1]);
    TEST_ASSERT_EQUAL_MEMORY("Orion input voltage low", packet.bytes + offset + 2, 23);
    offset += packet.bytes[offset];
    TEST_ASSERT_EQUAL_UINT8(1, packet.bytes[offset + 1]);
    offset += packet.bytes[offset];
    TEST_ASSERT_EQUAL_UINT32(packet.size, offset);
}
void response_matching_checks_full_identity_occurrence_and_responder() {
    Identity id{123, 0, 3, 9}; uint8_t response[25]{};
    identityBytes(id, response); putName(response + 16, 42); response[24] = 0xfc;
    TEST_ASSERT_TRUE(isAcknowledgement(response, sizeof(response), id, 42));
    response[15] = 8;
    TEST_ASSERT_FALSE(isAcknowledgement(response, sizeof(response), id, 42));
    response[15] = 9;
    TEST_ASSERT_FALSE(isAcknowledgement(response, sizeof(response), id, 43));
    TEST_ASSERT_FALSE(isAcknowledgement(response, 24, id, 42));
    TEST_ASSERT_EQUAL_UINT8(0, alertPacket(id, State::Active).bytes[16] & 0x10);
}
void disabled_default_is_quiet_failures_retry_and_disable_withdraws() {
    Delivery delivery; delivery.begin(123); Input inputs[kSlots]{}; Packet packet;
    delivery.set(inputs, false); TEST_ASSERT_FALSE(delivery.next(0, packet));
    inputs[0] = {1, 3, true, true, false}; delivery.set(inputs, true);
    TEST_ASSERT_TRUE(delivery.next(0, packet)); TEST_ASSERT_EQUAL_UINT32(126983, packet.pgn);
    delivery.result(false, 0); TEST_ASSERT_EQUAL_UINT32(1, delivery.status().failed);
    TEST_ASSERT_FALSE(delivery.next(50, packet));
    for (uint64_t now = 100; now <= 2000; now += 100) if (delivery.next(now, packet)) delivery.result(true, now);
    delivery.set(inputs, false);
    bool withdrawn = false;
    for (uint64_t now = 2100; now <= 4000; now += 100) if (delivery.next(now, packet)) {
        if (packet.pgn == 126983 && packet.bytes[3] == 1 && packet.bytes[27] == 0) withdrawn = true;
        delivery.result(true, now);
    }
    TEST_ASSERT_TRUE(withdrawn);
}
void remap_keeps_old_withdrawal_and_reconnect_reannounces() {
    Delivery delivery; delivery.begin(123); Input inputs[kSlots]{}; Packet packet;
    inputs[0] = {1,3,true,true,false}; delivery.set(inputs,true);
    TEST_ASSERT_TRUE(delivery.next(0,packet)); delivery.result(true,0);
    inputs[0].instance = 4; delivery.set(inputs,true);
    TEST_ASSERT_EQUAL_UINT32(1,delivery.status().withdrawals);
    bool oldDisabled = false, newActive = false;
    for (uint64_t now=100;now<=3000;now+=100) if(delivery.next(now,packet)) {
        if(packet.pgn==126983 && packet.bytes[3]==1) {
            oldDisabled |= packet.bytes[13]==3 && packet.bytes[27]==0;
            newActive |= packet.bytes[13]==4 && packet.bytes[27]==2;
        }
        delivery.result(true,now);
    }
    TEST_ASSERT_TRUE(oldDisabled); TEST_ASSERT_TRUE(newActive);
    delivery.reconcile(); TEST_ASSERT_TRUE(delivery.status().pending >= 7);
    inputs[0].instance=3; delivery.set(inputs,true);
    TEST_ASSERT_EQUAL_UINT32(1,delivery.status().withdrawals);
}
void unchanged_inputs_do_not_queue_continuous_retransmissions() {
    Delivery delivery; delivery.begin(123); Input inputs[kSlots]{}; Packet packet;
    inputs[0] = {1,3,true,true,false}; delivery.set(inputs,true);
    for (uint64_t now=0;now<=2500;now+=100) if(delivery.next(now,packet)) delivery.result(true,now);
    const auto before = delivery.status();
    for (int n=0;n<100;++n) delivery.set(inputs,true);
    TEST_ASSERT_EQUAL_UINT32(before.pending,delivery.status().pending);
    TEST_ASSERT_EQUAL_UINT32(before.accepted,delivery.status().accepted);
    TEST_ASSERT_EQUAL_UINT32(0,delivery.status().withdrawals);
}
void full_retirement_buffer_reports_backlog_and_disables_old_alert() {
    Delivery delivery; delivery.begin(123); Input inputs[kSlots]{}; Packet packet;
    inputs[0] = {1,0,true,true,false}; uint64_t now=0;
    for (uint8_t instance=0;instance<26;++instance) {
        inputs[0].instance=instance; delivery.set(inputs,true);
        for (int n=0;n<40;++n,now+=100) if(delivery.next(now,packet)) delivery.result(true,now);
    }
    TEST_ASSERT_TRUE(delivery.status().backlog);
    TEST_ASSERT_EQUAL_UINT32(24,delivery.status().withdrawals);
    delivery.set(inputs,false); delivery.reconcile();
    bool disabledCurrent = false;
    for (int n=0;n<100;++n,now+=100) if(delivery.next(now,packet)) {
        if(packet.pgn==126983 && packet.bytes[3]==1 && packet.bytes[13]==24 && packet.bytes[27]==0)
            disabledCurrent=true;
        TEST_ASSERT_FALSE(packet.pgn==126983 && packet.bytes[3]==1 && packet.bytes[27]==2);
        delivery.result(true,now);
    }
    TEST_ASSERT_TRUE(disabledCurrent);
}
void loss_of_data_does_not_withdraw_an_unresolved_active_incident() {
    Delivery delivery; delivery.begin(123); Input inputs[kSlots]{}; Packet packet;
    inputs[0] = {1,3,true,false,false}; delivery.set(inputs,true);
    TEST_ASSERT_TRUE(delivery.next(0,packet));
    TEST_ASSERT_EQUAL_UINT8(2,packet.bytes[27]);
}
void unresolved_previous_occurrence_is_withdrawn_before_it_is_forgotten() {
    Delivery delivery; delivery.begin(123); Input inputs[kSlots]{}; Packet packet;
    inputs[0] = {1,3,true,true,false}; delivery.set(inputs,true);
    TEST_ASSERT_TRUE(delivery.next(0,packet)); delivery.result(true,0);
    inputs[0].active=false; delivery.set(inputs,true); // Clear never reaches CAN.
    inputs[0] = {2,3,true,true,false}; delivery.set(inputs,true);
    TEST_ASSERT_EQUAL_UINT32(1,delivery.status().withdrawals);
    bool oldDisabled=false,newActive=false;
    for(uint64_t now=100;now<3000;now+=100) if(delivery.next(now,packet)) {
        if(packet.pgn==126983 && packet.bytes[3]==1) {
            oldDisabled|=packet.bytes[15]==1 && packet.bytes[27]==0;
            newActive|=packet.bytes[15]==2 && packet.bytes[27]==2;
        }
        delivery.result(true,now);
    }
    TEST_ASSERT_TRUE(oldDisabled); TEST_ASSERT_TRUE(newActive);
}
void restart_withdraws_three_times_or_reports_bounded_timeout() {
    Delivery delivery; delivery.begin(123); Input inputs[kSlots]{}; Packet packet;
    inputs[0]={1,3,true,true,false}; delivery.set(inputs,true);
    TEST_ASSERT_TRUE(delivery.next(0,packet)); delivery.result(true,0);
    delivery.prepareForRestart(10);
    TEST_ASSERT_FALSE(delivery.status().drainComplete);
    unsigned clears=0;
    for(uint64_t now=100;now<2000;now+=100) if(delivery.next(now,packet)) {
        TEST_ASSERT_EQUAL_UINT32(126983,packet.pgn); TEST_ASSERT_EQUAL_UINT8(0,packet.bytes[27]);
        ++clears; delivery.result(true,now);
    }
    TEST_ASSERT_EQUAL_UINT32(3,clears); TEST_ASSERT_TRUE(delivery.status().drainComplete);
    TEST_ASSERT_FALSE(delivery.status().drainTimedOut);
    Delivery failed; failed.begin(123); failed.set(inputs,true);
    TEST_ASSERT_TRUE(failed.next(0,packet)); failed.result(true,0);
    failed.prepareForRestart(10); failed.tick(5010);
    TEST_ASSERT_TRUE(failed.status().drainTimedOut); TEST_ASSERT_TRUE(failed.status().withdrawalsUnconfirmed);
    TEST_ASSERT_FALSE(failed.status().drainComplete);
    Delivery quiet; quiet.prepareForRestart(0); TEST_ASSERT_TRUE(quiet.status().drainComplete);
}
void successfully_cleared_incidents_do_not_exhaust_retirement_history() {
    Delivery delivery; delivery.begin(123); Input inputs[kSlots]{}; Packet packet;
    uint64_t now=0;
    for(uint32_t generation=1;generation<=40;++generation) {
        for(bool active : {true,false}) {
            inputs[0]={generation,3,active,true,false}; delivery.set(inputs,true);
            for(int n=0;n<25;++n,now+=100) if(delivery.next(now,packet)) delivery.result(true,now);
        }
    }
    TEST_ASSERT_FALSE(delivery.status().backlog);
    TEST_ASSERT_EQUAL_UINT32(0,delivery.status().withdrawals);
}
int main() {
    UNITY_BEGIN();
    RUN_TEST(golden_alert_bytes_match_field_definition);
    RUN_TEST(text_uses_matching_identity_and_two_lau_fields);
    RUN_TEST(response_matching_checks_full_identity_occurrence_and_responder);
    RUN_TEST(disabled_default_is_quiet_failures_retry_and_disable_withdraws);
    RUN_TEST(remap_keeps_old_withdrawal_and_reconnect_reannounces);
    RUN_TEST(unchanged_inputs_do_not_queue_continuous_retransmissions);
    RUN_TEST(full_retirement_buffer_reports_backlog_and_disables_old_alert);
    RUN_TEST(loss_of_data_does_not_withdraw_an_unresolved_active_incident);
    RUN_TEST(unresolved_previous_occurrence_is_withdrawn_before_it_is_forgotten);
    RUN_TEST(restart_withdraws_three_times_or_reports_bounded_timeout);
    RUN_TEST(successfully_cleared_incidents_do_not_exhaust_retirement_history);
    return UNITY_END();
}
