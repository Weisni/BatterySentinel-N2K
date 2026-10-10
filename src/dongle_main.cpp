#include <Arduino.h>
#include <HWCDC.h>
#include <WiFi.h>
#include <esp_ota_ops.h>
#if defined(BATTERYSENTINEL_DEBUG_OLED)
#include <esp_timer.h>
#include "BridgeDebugDisplay.h"
#endif

#include <OrionFrame.h>
#include "BridgePortal.h"
#include "BridgeSettings.h"
#include "BridgeDiagnostics.h"
#include "NmeaPublisher.h"
#include "OrionBleReceiver.h"

namespace {

bs::BridgeSettings settings;
bs::BridgePortal portal;
bs::OrionBleReceiver receiver;
bs::NmeaPublisher nmea;
bs::BridgeDiagnostics diagnostics;
bs::insights::Snapshot insightSnapshot;
bs::orion::Telemetry telemetry;
#if defined(BATTERYSENTINEL_DEBUG_OLED)
bs::BridgeDebugDisplay debugDisplay;
#endif
uint32_t lastValuesMs = 0;
uint32_t lastMetadataMs = 0;
uint32_t lastHealthMs = 0;
uint32_t lastDiagnosticsMs = 0;
bool wasFresh = false;
bool nmeaActive = false;
bs::time::Quality previousTimeQuality = bs::time::Quality::Unknown;

void updateDebugDisplay() {
#if defined(BATTERYSENTINEL_DEBUG_OLED)
    const uint32_t now = millis();
    if (!debugDisplay.due(now)) return;
    bs::debugdisplay::Snapshot display;
    display.nowMs = now;
    display.uptimeMs = static_cast<uint64_t>(esp_timer_get_time()) / 1000ULL;
    display.serviceReady = portal.serviceWifiReady();
    const auto bus = nmea.busStatus();
    display.canRunning = bus.running;
    display.canBusOff = bus.busOff;
    display.canRecovering = bus.recovering;
    display.canReceived = bus.received;
    display.canLastReceivedMs = bus.lastRxMs;
    display.canTxErrorCount = bus.txErrors;
    display.canRxErrorCount = bus.rxErrors;
    display.canReceivedFrames = bus.rxFrames;
    display.canTxFailures = bus.txFailed;
    display.orionConfigured = settings.hasOrion();
    display.orionReceived = telemetry.received;
    display.orionReceivedAtMs = telemetry.receivedAtMs;
    display.orionRssi = telemetry.rssi;
    display.orionAccepted = receiver.receivedFrames();
    display.orionErrors = receiver.errors();
    display.input.voltage = {telemetry.inputVoltage.number, telemetry.inputVoltage.valid};
    display.input.current = {telemetry.inputCurrent.number, telemetry.inputCurrent.valid};
    display.output.voltage = {telemetry.outputVoltage.number, telemetry.outputVoltage.valid};
    display.output.current = {telemetry.outputCurrent.number, telemetry.outputCurrent.valid};
    const auto clock = nmea.clockSnapshot();
    using Quality = bs::debugdisplay::TimeQuality;
    switch (clock.quality) {
    case bs::time::Quality::Synchronized: display.timeQuality = Quality::Synchronized; break;
    case bs::time::Quality::Holdover: display.timeQuality = Quality::Holdover; break;
    case bs::time::Quality::Quarantined: display.timeQuality = Quality::Quarantined; break;
    default: display.timeQuality = Quality::Unknown; break;
    }
    display.utcValid = clock.valid;
    display.utcMs = clock.utcMs;
    display.timeAgeMs = clock.ageMs;
    display.heapFree = ESP.getFreeHeap();
    display.heapMinimum = ESP.getMinFreeHeap();
    display.wifiClients = WiFi.softAPgetStationNum();
    display.httpsClients = portal.httpsClients();
    display.notificationsEnabled = diagnostics.config().enabled;
    for (const auto& alert : insightSnapshot.alerts) {
        if (alert.active) {
            ++display.activeAlerts;
            if (!alert.acknowledged) ++display.unacknowledgedAlerts;
        }
    }
    display.chargerState = telemetry.state;
    display.chargerError = telemetry.error;
    debugDisplay.show(display);
#endif
}

bool due(uint32_t now, uint32_t& last, uint32_t interval) {
    if (static_cast<uint32_t>(now - last) < interval) return false;
    last = now;
    return true;
}

void updateDiagnostics() {
    diagnostics.update(telemetry, settings.hasOrion());
    bs::insights::Transition transition;
    static const char* names[] = {"Input low voltage", "Output low voltage",
        "Input high voltage", "Output high voltage", "Orion data unavailable", "Orion charger error"};
    while (diagnostics.popTransition(transition)) {
        if (transition.slot >= bs::insights::kAlertCount) continue;
        const char* action = "changed";
        switch (transition.kind) {
            case bs::insights::TransitionKind::Activated: action = "activated"; break;
            case bs::insights::TransitionKind::Cleared: action = "cleared"; break;
            case bs::insights::TransitionKind::Acknowledged: action = "acknowledged"; break;
            case bs::insights::TransitionKind::Cancelled: action = "cancelled"; break;
            case bs::insights::TransitionKind::Reminder: action = "reminder"; break;
            default: break;
        }
        char detail[80];
        snprintf(detail, sizeof(detail), "%s: %s", names[transition.slot], action);
        portal.addEvent("ALERT", detail);
    }
    diagnostics.snapshot(insightSnapshot);
    const auto config = diagnostics.config();
    bs::alerts::Input inputs[bs::alerts::kSlots]{};
    for (size_t i = 0; i < bs::alerts::kSlots; ++i) {
        const auto& alert = insightSnapshot.alerts[i];
        inputs[i].generation = alert.generation;
        inputs[i].instance = i < 4 ? ((i % 2) ? settings.outputInstance() : settings.inputInstance()) : 0;
        inputs[i].active = alert.active;
        inputs[i].known = alert.known;
        inputs[i].acknowledged = alert.acknowledged;
    }
    nmea.setAlerts(inputs, config.enabled && config.nmeaEnabled && settings.hasOrion());
}

void reportTimeQuality() {
    const auto quality = nmea.clockSnapshot().quality;
    if (quality == previousTimeQuality) return;
    previousTimeQuality = quality;
    const char* detail = nullptr;
    switch (quality) {
        case bs::time::Quality::Synchronized: detail = "System time synchronized"; break;
        case bs::time::Quality::Holdover: detail = "System time holdover"; break;
        case bs::time::Quality::Quarantined: detail = "System time conflict"; break;
        case bs::time::Quality::Unknown: detail = "System time unavailable"; break;
        default: break;
    }
    if (detail) portal.addEvent("TIME", detail);
}

} // namespace

void setup() {
    bs::BridgePortal::initializeServiceWifiLed();
    Serial.begin(115200);
#if defined(BATTERYSENTINEL_DEBUG_OLED)
    debugDisplay.begin();
#endif
    pinMode(9, INPUT_PULLUP);
    const uint32_t serialStart = millis();
    while (!Serial && static_cast<uint32_t>(millis() - serialStart) < 5000) delay(10);
    Serial.println("BatterySentinel Orion Bridge boot");
    const auto* running = esp_ota_get_running_partition();
    esp_app_desc_t description{};
    const bool described = running && esp_ota_get_partition_description(running, &description) == ESP_OK;
    Serial.printf("Firmware boot: target=%.32s version=%.32s partition=%s address=0x%08lX\n",
                  described ? description.project_name : "unknown",
                  described ? description.version : "unknown",
                  running ? running->label : "unknown",
                  static_cast<unsigned long>(running ? running->address : 0));

#if defined(BATTERYSENTINEL_DEBUG_OLED)
    debugDisplay.boot("Settings");
#endif
    if (!settings.begin()) Serial.println("Bridge settings unavailable");
    const uint64_t mac = ESP.getEfuseMac();
    uint32_t unique = static_cast<uint32_t>((mac ^ (mac >> 24)) & 0x1fffffU);
    if (unique == 0) unique = 1;
    nmeaActive = settings.hasOrion();
    if (nmeaActive) nmea.begin(unique, true);
    else Serial.println("NMEA disabled until Orion is configured");

#if defined(BATTERYSENTINEL_DEBUG_OLED)
    debugDisplay.boot("BLE start");
#endif
    if (settings.hasOrion()) {
        if (!receiver.begin(settings.mac(), settings.key()))
            Serial.println("BLE receiver failed to start");
    }
    diagnostics.begin(settings.notifications());
#if defined(BATTERYSENTINEL_DEBUG_OLED)
    debugDisplay.boot("WiFi / HTTPS");
#endif
    portal.begin(settings, receiver, nmea, telemetry, diagnostics);
    portal.addEvent("BOOT", "Orion translation mode started");
    if (settings.hasOrion()) portal.addEvent("BLE", "Waiting for Orion advertisement");
    else portal.addEvent("CONFIG", "Orion identity and key required");

    const uint32_t now = millis();
    lastValuesMs = now - 1000;
    lastMetadataMs = now - 5000;
}

void loop() {
    if (portal.restartPending()) {
        if (nmeaActive) nmea.process();
        portal.loop();
        updateDebugDisplay();
        delay(2);
        return;
    }
    if (receiver.poll(telemetry)) {
        char detail[80];
        const String voltage = telemetry.outputVoltage.valid ?
            String(telemetry.outputVoltage.number, 3) : String("NA");
        const String current = telemetry.outputCurrent.valid ?
            String(telemetry.outputCurrent.number, 3) : String("NA");
        snprintf(detail, sizeof(detail), "Orion state %u, output %s V %s A",
                 telemetry.state, voltage.c_str(), current.c_str());
        portal.addEvent("BLE", detail);
    }

    const uint32_t now = millis();
    const bool fresh = telemetry.fresh(now);
    if (wasFresh && !fresh) portal.addEvent("BLE", "Orion data stale");
    wasFresh = fresh;

    if (settings.hasOrion() && due(now, lastValuesMs, 1000)) {
        const uint32_t before = nmea.transmitted();
        const uint32_t failedBefore = nmea.failed();
        nmea.publishOrion(telemetry, now, settings.outputInstance(), settings.inputInstance());
        char detail[80];
        snprintf(detail, sizeof(detail), "PGN 127508 x2%s; accepted %lu, failed %lu%s",
                 fresh && telemetry.error == 0 &&
                    (telemetry.state == 3 || telemetry.state == 4 || telemetry.state == 5)
                    ? ", 127507" : "",
                 static_cast<unsigned long>(nmea.transmitted() - before),
                 static_cast<unsigned long>(nmea.failed() - failedBefore),
                 fresh ? "" : "; values unavailable");
        portal.addEvent("NMEA", detail);
    }
    if (settings.hasOrion() && due(now, lastMetadataMs, 5000)) {
        const uint32_t before = nmea.transmitted();
        const uint32_t failedBefore = nmea.failed();
        nmea.publishOrionMetadata(settings.outputInstance(), settings.inputInstance());
        char detail[80];
        snprintf(detail, sizeof(detail), "PGN 127506 x2; accepted %lu, failed %lu",
                 static_cast<unsigned long>(nmea.transmitted() - before),
                 static_cast<unsigned long>(nmea.failed() - failedBefore));
        portal.addEvent("NMEA", detail);
    }

    if (due(now, lastDiagnosticsMs, 100)) updateDiagnostics();
    if (nmeaActive) nmea.process();
    reportTimeQuality();
    portal.loop();
    updateDebugDisplay();
    if (due(now, lastHealthMs, 10000) && Serial)
        Serial.printf("Bridge health: freeHeap=%lu minHeap=%lu Wi-Fi clients=%u HTTPS sessions=%u portal=%u\n",
                      static_cast<unsigned long>(ESP.getFreeHeap()),
                      static_cast<unsigned long>(ESP.getMinFreeHeap()),
                      WiFi.softAPgetStationNum(),
                      static_cast<unsigned int>(portal.httpsClients()), portal.active() ? 1 : 0);
    delay(2);
}
