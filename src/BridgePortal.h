#pragma once

#include <Arduino.h>
#include <atomic>
#include <esp_https_server.h>
#include <OrionFrame.h>

#include "BridgeSettings.h"
#include "NmeaPublisher.h"
#include "OrionBleReceiver.h"
#include "BridgeDiagnostics.h"

namespace bs {

class BridgePortal {
public:
    static void initializeServiceWifiLed();
    void begin(BridgeSettings& settings, OrionBleReceiver& receiver,
               NmeaPublisher& nmea, orion::Telemetry& telemetry, BridgeDiagnostics& diagnostics);
    void loop();
    void addEvent(const char* type, const char* detail);
    bool active() const { return server_ != nullptr; }
    // Main-loop snapshot of the same AP/address/HTTPS readiness as the blue LED.
    bool serviceWifiReady() const { return serviceWifiLedOn_; }
    bool restartPending() const { return otaRestartPending_.load(); }
    size_t httpsClients() const;

private:
    struct Event {
        uint32_t sequence = 0;
        uint64_t atMs = 0;
        char type[16]{};
        char detail[80]{};
    };
    static constexpr size_t kEventCount = 64;
    static esp_err_t dispatch(httpd_req_t* request);
    esp_err_t handle(httpd_req_t* request);
    esp_err_t firmwareInfo(httpd_req_t* request);
    esp_err_t firmwareUpload(httpd_req_t* request);
    esp_err_t notificationSettings(httpd_req_t* request, const String& form);
    esp_err_t notificationAcknowledge(httpd_req_t* request, const String& form);
    String eventsJson(uint32_t after) const;
    bool start();
    void stop();
    void updateServiceWifiLed();
    bool authenticated(httpd_req_t* request);
    bool csrfValid(const String& body) const;
    String body(httpd_req_t* request, size_t maximumLength = 512);
    static String field(const String& body, const char* name);
    static String escape(const String& value);
    static String jsonEscape(const String& value);
    static void send(httpd_req_t* request, const String& data, const char* type = "text/html");
    esp_err_t sendPage(httpd_req_t* request, const char* body,
                       const char* messageTitle = "", const char* messageText = "");
    static void denied(httpd_req_t* request);
    bool ensureCertificate();
    void newSession();
    void endSession(httpd_req_t* request);
    void scheduleRestart();

    BridgeSettings* settings_ = nullptr;
    OrionBleReceiver* receiver_ = nullptr;
    NmeaPublisher* nmea_ = nullptr;
    orion::Telemetry* telemetry_ = nullptr;
    BridgeDiagnostics* diagnostics_ = nullptr;
    httpd_handle_t server_ = nullptr;
    std::atomic<bool> httpsTaskReady_{false};
    bool serviceWifiLedOn_ = false;
    bool mdnsActive_ = false;
    String certificate_;
    String privateKey_;
    String session_;
    String csrf_;
    String recoveryCsrf_;
    uint32_t recoveryStartedMs_ = 0;
    uint32_t sessionLastMs_ = 0;
    uint32_t lastClientMs_ = 0;
    uint32_t lastServiceCheckMs_ = 0;
    std::atomic<bool> otaInProgress_{false};
    std::atomic<bool> otaRestartPending_{false};
    uint32_t otaRestartStartedMs_ = 0;
    uint32_t buttonSinceMs_ = 0;
    bool buttonTriggered_ = false;
    uint32_t nextSequence_ = 1;
    uint32_t bootId_ = 0;
    Event events_[kEventCount]{};
    mutable portMUX_TYPE eventMux_ = portMUX_INITIALIZER_UNLOCKED;
};

} // namespace bs
