#include "NmeaPublisher.h"

#include <algorithm>
#include <cmath>
#include <esp_timer.h>

#include <N2kMessages.h>

#include "Nmea2000Twai.h"
#include "config.h"
#if defined(BATTERYSENTINEL_ORION_DONGLE)
#include "BridgeFirmwareIdentity.h"
#endif

namespace bs {

namespace {
Nmea2000Twai nmeaBus(static_cast<gpio_num_t>(config::PIN_CAN_TX),
                     static_cast<gpio_num_t>(config::PIN_CAN_RX));
NmeaPublisher* activePublisher = nullptr;
const unsigned long kTransmitMessages[] PROGMEM = {126983L, 126985L, 127506L, 127507L, 127508L, 0};
const unsigned long kReceiveMessages[] PROGMEM = {60928L, 126984L, 126992L, 129029L, 0};
uint64_t monotonicMs() { return uint64_t(esp_timer_get_time()) / 1000; }
String decimal64(uint64_t value) {
    char buffer[24]; snprintf(buffer, sizeof(buffer), "%llu", static_cast<unsigned long long>(value));
    return String(buffer);
}

struct MonitorField {
    const char* name;
    bool integer;
};
constexpr MonitorField kBatteryFields[] = {
    {"sid", true}, {"voltage", false}, {"current", false}, {"temperature", false}
};
constexpr MonitorField kChargerFields[] = {
    {"batteryInstance", true}, {"chargeState", true}, {"chargerMode", true},
    {"enabled", true}, {"equalizationPending", true}, {"equalizationTimeRemaining", false}
};
constexpr MonitorField kDcFields[] = {
    {"sid", true}, {"dcType", true}, {"soc", true}, {"soh", true},
    {"timeRemaining", false}, {"rippleVoltage", false}, {"capacity", false}
};

double byteOrNa(uint8_t value) {
    return value == N2kUInt8NA ? N2kDoubleNA : value;
}
}

BusStatus NmeaPublisher::busStatus() const {
    return nmeaBus.busStatus();
}

void NmeaPublisher::begin(uint32_t uniqueNumber, bool orionBridge) {
    char serial[16];
    snprintf(serial, sizeof(serial), "%08lX", static_cast<unsigned long>(uniqueNumber));

    nmeaBus.SetProductInformation(
        serial,
        100,
        orionBridge ? "BatterySentinel Orion Bridge" : "BatterySentinel N2K",
#if defined(BATTERYSENTINEL_ORION_DONGLE)
        kBridgeFirmwareVersion,
#else
        "0.1.0",
#endif
        config::N2K_MODEL_VERSION,
        config::N2K_LOAD_EQUIVALENCY
    );

    // Function 170 = Battery; class 35 = Electrical Generation. The bridge
    // advertises its own identity, not Victron's manufacturer identity.
    // Manufacturer code 2046 is deliberately used as a DIY/unregistered placeholder.
    nmeaBus.SetDeviceInformation(uniqueNumber & 0x1FFFFFu, 170, 35, 2046);
    nmeaBus.ExtendTransmitMessages(kTransmitMessages);
    nmeaBus.ExtendReceiveMessages(kReceiveMessages);
    activePublisher = this;
    nmeaBus.SetMsgHandler(&NmeaPublisher::handleMessage);
    nmeaBus.SetMode(tNMEA2000::N2km_NodeOnly, 25);
    nmeaBus.EnableForward(false);
    nmeaBus.Open();
    portENTER_CRITICAL(&snapshotMux_); begun_ = true; portEXIT_CRITICAL(&snapshotMux_);
    alertDelivery_.begin(nmeaBus.GetDeviceInformation().GetName());
    publishServiceSnapshot();
}

void NmeaPublisher::process() {
    if (!begun_) return;
    bool drain; uint64_t requestedAt;
    portENTER_CRITICAL(&snapshotMux_);
    drain = restartRequested_; requestedAt = restartRequestedAtMs_;
    portEXIT_CRITICAL(&snapshotMux_);
    if (drain) alertDelivery_.prepareForRestart(requestedAt);
    nmeaBus.ParseMessages();
    const uint64_t now = monotonicMs();
    alertDelivery_.tick(now); // The restart deadline also advances while CAN is closed.
    const time::Snapshot clock = clock_.snapshot(now);
    // Garmin is documented to transmit GNSS 129029; some clocks provide
    // System Time instead. Requests are acquisition aids, never a wait loop.
    if (nmeaBus.IsOpen() && (!timeRequested_ ||
        (clock.quality != time::Quality::Synchronized && now - lastTimeRequestMs_ >= 15000))) {
        for (unsigned long pgn : {60928UL, 129029UL, 126992UL}) {
            tN2kMsg request;
            SetN2kPGNISORequest(request, 255, pgn);
            if (nmeaBus.SendMsg(request)) ++timeRequestsAccepted_; else ++timeRequestsFailed_;
        }
        lastTimeRequestMs_ = now; timeRequested_ = true;
    }
    alerts::Packet packet;
    if (nmeaBus.IsOpen() && alertDelivery_.next(now, packet)) {
        tN2kMsg message; message.SetPGN(packet.pgn); message.Priority = 2;
        for (size_t i = 0; i < packet.size; ++i) message.AddByte(packet.bytes[i]);
        alertDelivery_.result(nmeaBus.SendMsg(message), now);
    }
    publishServiceSnapshot();
}

void NmeaPublisher::handleMessage(const tN2kMsg& msg) {
    if (activePublisher) activePublisher->receive(msg);
}

void NmeaPublisher::receive(const tN2kMsg& msg) {
    if (msg.Source >= 254 || msg.Source == nmeaBus.GetN2kSource()) return;
    if (msg.PGN == 60928 && msg.DataLen == 8) {
        int index = 0; const uint64_t name = msg.GetUInt64(index);
        if (!name || name == UINT64_MAX) return;
        for (uint64_t& known : sourceNames_) if (known == name) known = 0;
        sourceNames_[msg.Source] = name;
        // Any device returning to the bus may be the display, or a gateway
        // forwarding to it. Reannounce current states and retained withdrawals.
        alertDelivery_.reconcile();
        return;
    }
    if (msg.PGN == 126984) {
        // Deliberately unsupported: an 8-bit occurrence cannot identify late
        // responses across reboot. Never silence a new incident from this PGN.
        alertDelivery_.responseIgnored(); return;
    }
    if (msg.PGN != 129029 && msg.PGN != 126992) return;
    if (!sourceNames_[msg.Source]) { clock_.reject(); return; }
    uint8_t sid = 0; uint16_t days = 0; double seconds = 0;
    bool valid = false;
    if (msg.PGN == 126992 && msg.DataLen == 8) {
        tN2kTimeSource source;
        valid = ParseN2kSystemTime(msg, sid, days, seconds, source) && uint8_t(source) <= 4;
    } else if (msg.PGN == 129029 && msg.DataLen >= 43) {
        double lat, lon, altitude, hdop, pdop, separation, correctionAge;
        tN2kGNSStype type, referenceType; tN2kGNSSmethod method;
        uint8_t satellites, references; uint16_t referenceId;
        valid = ParseN2kGNSS(msg, sid, days, seconds, lat, lon, altitude, type, method,
            satellites, hdop, pdop, separation, references, referenceType, referenceId, correctionAge) &&
            uint8_t(method) >= 1 && uint8_t(method) <= 5 && (msg.Data[32] & 3) <= 1 &&
            satellites > 0 && satellites < 253;
    }
    uint64_t utc;
    if (!valid || !time::decodeUtc(days, seconds, utc)) { clock_.reject(); return; }
    clock_.observe(utc, monotonicMs(), sourceNames_[msg.Source], msg.Source, msg.PGN);
}

void NmeaPublisher::publishServiceSnapshot() {
    const alerts::Status delivery = alertDelivery_.status();
    portENTER_CRITICAL(&snapshotMux_);
    publishedClock_ = clock_; publishedDelivery_ = delivery;
    publishedRequestsAccepted_ = timeRequestsAccepted_; publishedRequestsFailed_ = timeRequestsFailed_;
    portEXIT_CRITICAL(&snapshotMux_);
}

time::Snapshot NmeaPublisher::clockSnapshot() const {
    time::Clock snapshot;
    portENTER_CRITICAL(&snapshotMux_);
    snapshot = publishedClock_;
    portEXIT_CRITICAL(&snapshotMux_);
    // This advances even before NMEA provisioning/startup and while unsynced.
    return snapshot.snapshot(monotonicMs());
}

String NmeaPublisher::timeJson() const {
    const time::Snapshot state = clockSnapshot();
    uint32_t accepted, failed;
    portENTER_CRITICAL(&snapshotMux_);
    accepted = publishedRequestsAccepted_; failed = publishedRequestsFailed_;
    portEXIT_CRITICAL(&snapshotMux_);
    char name[20]; snprintf(name, sizeof(name), "%016llX", static_cast<unsigned long long>(state.sourceName));
    String result; result.reserve(400);
    result = "{\"quality\":\""; result += time::qualityName(state.quality);
    result += "\",\"utcMs\":"; result += state.valid ? decimal64(state.utcMs) : String("null");
    result += ",\"anchorUtcMs\":"; result += state.valid ? decimal64(state.anchorUtcMs) : String("null");
    result += ",\"anchorMonotonicMs\":"; result += state.valid ? decimal64(state.anchorMonotonicMs) : String("null");
    result += ",\"monotonicMs\":" + decimal64(state.monotonicMs);
    result += ",\"sourceName\":"; result += state.valid ? String('"') + name + '"' : String("null");
    result += ",\"sourceAddress\":"; result += state.valid ? String(state.sourceAddress) : String("null");
    result += ",\"sourcePgn\":"; result += state.valid ? String(state.sourcePgn) : String("null");
    result += ",\"ageMs\":"; result += state.valid ? decimal64(state.ageMs) : String("null");
    result += ",\"rejected\":" + String(state.rejected) + ",\"requestsAccepted\":" + String(accepted) +
        ",\"requestsFailed\":" + String(failed) + '}';
    return result;
}

void NmeaPublisher::setAlerts(const alerts::Input (&inputs)[alerts::kSlots], bool enabled) {
    alertDelivery_.set(inputs, enabled);
    publishServiceSnapshot();
}

String NmeaPublisher::deliveryJson() const {
    alerts::Status state;
    portENTER_CRITICAL(&snapshotMux_); state = publishedDelivery_; portEXIT_CRITICAL(&snapshotMux_);
    return String("{\"supported\":true,\"experimental\":true,\"receiverVerified\":false,\"remoteAckSupported\":false,\"enabled\":") +
        (state.enabled ? "true" : "false") + ",\"accepted\":" + String(state.accepted) +
        ",\"failed\":" + String(state.failed) + ",\"pending\":" + String(state.pending) +
        ",\"withdrawals\":" + String(state.withdrawals) + ",\"backlog\":" + (state.backlog ? "true" : "false") +
        ",\"draining\":" + (state.draining ? "true" : "false") +
        ",\"drainComplete\":" + (state.drainComplete ? "true" : "false") +
        ",\"drainTimedOut\":" + (state.drainTimedOut ? "true" : "false") +
        ",\"withdrawalsUnconfirmed\":" + (state.withdrawalsUnconfirmed ? "true" : "false") +
        ",\"ignoredResponses\":" + String(state.ignoredResponses) + ",\"lastAttemptMs\":" +
        (state.accepted || state.failed ? decimal64(state.lastAttemptMs) : String("null")) + '}';
}

void NmeaPublisher::prepareForRestart() {
    const uint64_t now = monotonicMs();
    portENTER_CRITICAL(&snapshotMux_);
    if (!restartRequested_) restartRequestedAtMs_ = now;
    restartRequested_ = true;
    portEXIT_CRITICAL(&snapshotMux_);
}

bool NmeaPublisher::restartReady() const {
    portENTER_CRITICAL(&snapshotMux_);
    const bool ready = !begun_ || (restartRequested_ &&
        (publishedDelivery_.accepted == 0 || publishedDelivery_.drainComplete || publishedDelivery_.drainTimedOut));
    portEXIT_CRITICAL(&snapshotMux_);
    return ready;
}

void NmeaPublisher::sendOrion(const tN2kMsg& msg, size_t slot) {
    MessageSnapshot snapshot;
    for (double& value : snapshot.fields) value = N2kDoubleNA;
    uint8_t instance = 0, sid = 0;
    // Decode the exact payload that is submitted, including its quantization
    // and unavailable sentinels. Never substitute the newer Orion reading.
    if (msg.PGN == 127508L) {
        double voltage, current, temperature;
        if (ParseN2kDCBatStatus(msg, instance, voltage, current, temperature, sid)) {
            snapshot.fields[0] = byteOrNa(sid);
            snapshot.fields[1] = voltage;
            snapshot.fields[2] = current;
            snapshot.fields[3] = temperature;
        }
    } else if (msg.PGN == 127507L) {
        uint8_t batteryInstance;
        tN2kChargeState chargeState;
        tN2kChargerMode chargerMode;
        tN2kOnOff enabled, equalizationPending;
        double equalizationTimeRemaining;
        if (ParseN2kChargerStatus(msg, instance, batteryInstance, chargeState, chargerMode,
                                enabled, equalizationPending, equalizationTimeRemaining)) {
            snapshot.fields[0] = byteOrNa(batteryInstance);
            snapshot.fields[1] = chargeState == N2kCS_Unavailable ? N2kDoubleNA : chargeState;
            snapshot.fields[2] = chargerMode == N2kCM_Unavailable ? N2kDoubleNA : chargerMode;
            snapshot.fields[3] = enabled == N2kOnOff_Unavailable ? N2kDoubleNA : enabled;
            snapshot.fields[4] = equalizationPending == N2kOnOff_Unavailable ?
                N2kDoubleNA : equalizationPending;
            snapshot.fields[5] = equalizationTimeRemaining;
        }
    } else if (msg.PGN == 127506L) {
        uint8_t soc, soh;
        tN2kDCType dcType;
        double timeRemaining, rippleVoltage, capacity;
        if (ParseN2kDCStatus(msg, sid, instance, dcType, soc, soh,
                            timeRemaining, rippleVoltage, capacity)) {
            snapshot.fields[0] = byteOrNa(sid);
            snapshot.fields[1] = static_cast<uint8_t>(dcType) == N2kUInt8NA ?
                N2kDoubleNA : dcType;
            snapshot.fields[2] = byteOrNa(soc);
            snapshot.fields[3] = byteOrNa(soh);
            snapshot.fields[4] = timeRemaining;
            snapshot.fields[5] = rippleVoltage;
            snapshot.fields[6] = capacity;
        }
    }
    snapshot.instance = instance;
    snapshot.attemptedAtMs = millis();
    snapshot.attempted = true;
    snapshot.accepted = nmeaBus.SendMsg(msg);
    if (snapshot.accepted) ++transmitted_; else ++failed_;
    portENTER_CRITICAL(&snapshotMux_);
    snapshots_[slot] = snapshot;
    portEXIT_CRITICAL(&snapshotMux_);
}

String NmeaPublisher::monitorJson(uint8_t outputInstance, uint8_t inputInstance) const {
    // HTTPS runs in a separate task. Copy under a short lock; string allocation
    // and JSON formatting must stay outside that critical section.
    MessageSnapshot snapshots[5];
    portENTER_CRITICAL(&snapshotMux_);
    for (size_t i = 0; i < 5; ++i) snapshots[i] = snapshots_[i];
    portEXIT_CRITICAL(&snapshotMux_);
    const uint32_t now = millis();
    String result;
    result.reserve(1600);
    result = '[';
    for (size_t slot = 0; slot < 5; ++slot) {
        const MessageSnapshot& snapshot = snapshots[slot];
        const unsigned long pgn = slot < 2 ? 127508L : slot == 2 ? 127507L : 127506L;
        const uint8_t instance = snapshot.attempted ? snapshot.instance :
            slot == 1 || slot == 4 ? inputInstance : outputInstance;
        const MonitorField* fields = slot < 2 ? kBatteryFields :
            slot == 2 ? kChargerFields : kDcFields;
        const size_t fieldCount = slot < 2 ? 4 : slot == 2 ? 6 : 7;
        if (slot) result += ',';
        result += "{\"pgn\":" + String(pgn) + ",\"instance\":" + String(instance) +
            ",\"age\":" + (snapshot.attempted ?
                String(static_cast<uint32_t>(now - snapshot.attemptedAtMs)) : String("null")) +
            ",\"accepted\":" + (snapshot.attempted ?
                String(snapshot.accepted ? "true" : "false") : String("null")) + ",\"fields\":{";
        for (size_t i = 0; i < fieldCount; ++i) {
            if (i) result += ',';
            result += '"';
            result += fields[i].name;
            result += "\":";
            const double value = snapshot.fields[i];
            if (!snapshot.attempted || value == N2kDoubleNA || !std::isfinite(value))
                result += "null";
            else if (fields[i].integer) result += String(static_cast<unsigned long>(value));
            else result += String(value, 3);
        }
        result += "}}";
    }
    result += ']';
    return result;
}

void NmeaPublisher::publishFast(uint8_t batteryInstance,
                                const BatterySnapshot& state,
                                bool measurementValid) {
    tN2kMsg msg;
    const double voltage = measurementValid ? state.voltageV : N2kDoubleNA;
    const double current = measurementValid ? state.currentA : N2kDoubleNA;

    SetN2kDCBatStatus(msg, batteryInstance, voltage, current, N2kDoubleNA, sid_++);
    nmeaBus.SendMsg(msg);
}

void NmeaPublisher::publishDc(uint8_t batteryInstance,
                              const BatterySnapshot& state,
                              bool measurementValid) {
    if (!measurementValid || !state.socInitialized) return;

    tN2kMsg msg;
    const uint8_t soc = static_cast<uint8_t>(std::lround(std::max(0.0, std::min(100.0, state.socPct))));
    const double timeRemaining = state.timeRemainingS >= 0.0 ? state.timeRemainingS : N2kDoubleNA;

    SetN2kDCStatus(msg,
                   sid_++,
                   batteryInstance,
                   N2kDCt_Battery,
                   soc,
                   N2kUInt8NA,
                   timeRemaining,
                   N2kDoubleNA);
    nmeaBus.SendMsg(msg);
}

void NmeaPublisher::publishOrion(const orion::Telemetry& state, uint32_t now,
                                 uint8_t outputInstance, uint8_t inputInstance) {
    const bool fresh = state.fresh(now);
    const auto valueOrNa = [fresh](const orion::Value& value) {
        return fresh && value.valid ? value.number : N2kDoubleNA;
    };
    tN2kMsg msg;
    SetN2kDCBatStatus(msg, outputInstance,
                      valueOrNa(state.outputVoltage), valueOrNa(state.outputCurrent),
                      N2kDoubleNA, sid_++);
    sendOrion(msg, 0);
    SetN2kDCBatStatus(msg, inputInstance,
                      valueOrNa(state.inputVoltage), valueOrNa(state.inputCurrent),
                      N2kDoubleNA, sid_++);
    sendOrion(msg, 1);

    // Documented Victron state values: Bulk 3, Absorption 4, Float 5.
    // Errors, disabled, unknown and stale states never become charger alarms.
    if (!fresh || state.error != 0) return;
    tN2kChargeState chargeState = N2kCS_Unavailable;
    if (state.state == 3) chargeState = N2kCS_Bulk;
    else if (state.state == 4) chargeState = N2kCS_Absorption;
    else if (state.state == 5) chargeState = N2kCS_Float;
    if (chargeState == N2kCS_Unavailable) return;
    SetN2kChargerStatus(msg, outputInstance, outputInstance, chargeState);
    sendOrion(msg, 2);
}

void NmeaPublisher::publishOrionMetadata(uint8_t outputInstance, uint8_t inputInstance) {
    tN2kMsg msg;
    SetN2kDCStatus(msg, sid_++, outputInstance, N2kDCt_Battery,
                   N2kUInt8NA, N2kUInt8NA, N2kDoubleNA);
    sendOrion(msg, 3);
    SetN2kDCStatus(msg, sid_++, inputInstance, N2kDCt_Converter,
                   N2kUInt8NA, N2kUInt8NA, N2kDoubleNA);
    sendOrion(msg, 4);
}

} // namespace bs
