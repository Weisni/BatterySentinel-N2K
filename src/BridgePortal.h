#pragma once

#include <Arduino.h>
#include <esp_https_server.h>
#include <OrionFrame.h>

#include "BridgeSettings.h"
#include "NmeaPublisher.h"
#include "OrionBleReceiver.h"

namespace bs {

class BridgePortal {
public:
    void begin(BridgeSettings& settings, OrionBleReceiver& receiver,
               NmeaPublisher& nmea, orion::Telemetry& telemetry);
    void loop();
    void addEvent(const char* type, const char* detail);
    bool active() const { return server_ != nullptr; }
    size_t httpsClients() const;

private:
    struct Event {
        uint32_t sequence = 0;
        uint32_t atMs = 0;
        char type[16]{};
        char detail[80]{};
    };
    static constexpr size_t kEventCount = 64;
    static esp_err_t dispatch(httpd_req_t* request);
    esp_err_t handle(httpd_req_t* request);
    bool start();
    void stop();
    bool authenticated(httpd_req_t* request);
    bool csrfValid(const String& body) const;
    String body(httpd_req_t* request);
    static String field(const String& body, const char* name);
    static String escape(const String& value);
    static String jsonEscape(const String& value);
    static void send(httpd_req_t* request, const String& data, const char* type = "text/html");
    esp_err_t sendPage(httpd_req_t* request, const char* body,
                       const char* messageTitle = "", const char* messageText = "");
    static void denied(httpd_req_t* request);
    bool ensureCertificate();
    void newSession();

    BridgeSettings* settings_ = nullptr;
    OrionBleReceiver* receiver_ = nullptr;
    NmeaPublisher* nmea_ = nullptr;
    orion::Telemetry* telemetry_ = nullptr;
    httpd_handle_t server_ = nullptr;
    String certificate_;
    String privateKey_;
    String session_;
    String csrf_;
    uint32_t sessionLastMs_ = 0;
    uint32_t lastClientMs_ = 0;
    uint32_t lastServiceCheckMs_ = 0;
    uint32_t buttonSinceMs_ = 0;
    bool buttonTriggered_ = false;
    uint32_t nextSequence_ = 1;
    Event events_[kEventCount]{};
};

} // namespace bs
