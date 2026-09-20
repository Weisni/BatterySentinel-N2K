#include <Arduino.h>
#include <HWCDC.h>
#include <WiFi.h>

#include <OrionFrame.h>
#include "BridgePortal.h"
#include "BridgeSettings.h"
#include "NmeaPublisher.h"
#include "OrionBleReceiver.h"

namespace {

bs::BridgeSettings settings;
bs::BridgePortal portal;
bs::OrionBleReceiver receiver;
bs::NmeaPublisher nmea;
bs::orion::Telemetry telemetry;
uint32_t lastValuesMs = 0;
uint32_t lastMetadataMs = 0;
uint32_t lastHealthMs = 0;
bool wasFresh = false;
bool nmeaActive = false;

bool due(uint32_t now, uint32_t& last, uint32_t interval) {
    if (static_cast<uint32_t>(now - last) < interval) return false;
    last = now;
    return true;
}

} // namespace

void setup() {
    Serial.begin(115200);
    pinMode(9, INPUT_PULLUP);
    const uint32_t serialStart = millis();
    while (!Serial && static_cast<uint32_t>(millis() - serialStart) < 5000) delay(10);
    Serial.println("BatterySentinel Orion Bridge boot");

    if (!settings.begin()) Serial.println("Bridge settings unavailable");
    const uint64_t mac = ESP.getEfuseMac();
    uint32_t unique = static_cast<uint32_t>((mac ^ (mac >> 24)) & 0x1fffffU);
    if (unique == 0) unique = 1;
    nmeaActive = settings.hasOrion();
    if (nmeaActive) nmea.begin(unique, true);
    else Serial.println("NMEA disabled until Orion is configured");

    if (settings.hasOrion()) {
        if (!receiver.begin(settings.mac(), settings.key()))
            Serial.println("BLE receiver failed to start");
    }
    portal.begin(settings, receiver, nmea, telemetry);
    portal.addEvent("BOOT", "Orion translation mode started");
    if (settings.hasOrion()) portal.addEvent("BLE", "Waiting for Orion advertisement");
    else portal.addEvent("CONFIG", "Orion identity and key required");

    const uint32_t now = millis();
    lastValuesMs = now - 1000;
    lastMetadataMs = now - 5000;
}

void loop() {
    const uint32_t now = millis();
    if (receiver.poll(telemetry)) {
        char detail[80];
        snprintf(detail, sizeof(detail), "Orion state %u, output %.2f V %.2f A",
                 telemetry.state, telemetry.outputVoltage.number,
                 telemetry.outputCurrent.number);
        portal.addEvent("BLE", detail);
    }

    const bool fresh = telemetry.fresh(now);
    if (wasFresh && !fresh) portal.addEvent("BLE", "Orion data stale");
    wasFresh = fresh;

    if (settings.hasOrion() && due(now, lastValuesMs, 1000)) {
        const uint32_t before = nmea.transmitted();
        const uint32_t failedBefore = nmea.failed();
        nmea.publishOrion(telemetry, now, settings.outputInstance(), settings.inputInstance());
        char detail[80];
        snprintf(detail, sizeof(detail), "PGN 127508 x2%s; sent %lu, failed %lu%s",
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
        snprintf(detail, sizeof(detail), "PGN 127506 x2; sent %lu, failed %lu",
                 static_cast<unsigned long>(nmea.transmitted() - before),
                 static_cast<unsigned long>(nmea.failed() - failedBefore));
        portal.addEvent("NMEA", detail);
    }

    if (nmeaActive) nmea.process();
    portal.loop();
    if (due(now, lastHealthMs, 10000) && Serial)
        Serial.printf("Bridge health: freeHeap=%lu minHeap=%lu Wi-Fi clients=%u HTTPS sessions=%u portal=%u\n",
                      static_cast<unsigned long>(ESP.getFreeHeap()),
                      static_cast<unsigned long>(ESP.getMinFreeHeap()),
                      WiFi.softAPgetStationNum(),
                      static_cast<unsigned int>(portal.httpsClients()), portal.active() ? 1 : 0);
    delay(2);
}
