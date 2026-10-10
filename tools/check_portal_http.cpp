// Run with: python tools/verify_portal_http.py
// The production HTTP methods are included unchanged by that driver. Adapters
// replace Arduino, the HTTP transport, and device hardware only; they contain no
// routing or authentication policy. All account data below is synthetic.
#include <algorithm>
#include <atomic>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <map>
#include <memory>
#include <new>
#include <sstream>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <vector>

#include <BridgePasswordUpdate.h>
#include <OrionAliases.h>
#include <OrionFrame.h>
#include "BridgePortalUi.h"
#include "BridgePortalTranslations.h"
#include "BridgePortalLanguage.h"
#include "BridgePortalForm.h"
#include "BridgePortalOta.h"
#include "BridgePortalInsights.h"
#include "BridgeNotificationForm.h"

class String : public std::string {
public:
    using std::string::string;
    String() = default;
    String(char value) : std::string(1, value) {}
    String(const std::string& value) : std::string(value) {}
    template <typename T, std::enable_if_t<std::is_integral_v<T>, int> = 0>
    String(T value) : std::string(std::to_string(value)) {}
    String(double value, unsigned places) {
        std::ostringstream stream;
        stream.setf(std::ios::fixed);
        stream.precision(places);
        stream << value;
        assign(stream.str());
    }
    int indexOf(const String& value, size_t start = 0) const {
        const auto index = find(value, start);
        return index == npos ? -1 : static_cast<int>(index);
    }
    int indexOf(char value, size_t start = 0) const {
        const auto index = find(value, start);
        return index == npos ? -1 : static_cast<int>(index);
    }
    bool startsWith(const char* prefix) const { return find(prefix) == 0; }
    long toInt() const { return std::strtol(c_str(), nullptr, 10); }
    bool isEmpty() const { return empty(); }
    void replace(const char* from, const char* to) {
        size_t at = 0;
        while ((at = find(from, at)) != npos) {
            std::string::replace(at, std::strlen(from), to);
            at += std::strlen(to);
        }
    }
};

using esp_err_t = int;
constexpr esp_err_t ESP_OK = 0;
constexpr esp_err_t ESP_FAIL = -1;
constexpr esp_err_t ESP_ERR_HTTPD_RESP_SEND = 0x7006;
constexpr int HTTP_GET = 0;
constexpr int HTTP_POST = 1;
constexpr int HTTPD_RESP_USE_STRLEN = -1;
constexpr int LOW = 0;
uint32_t clockMs = 1000;
uint32_t millis() { return clockMs; }
void delay(uint32_t amount) { clockMs += amount; }
int digitalRead(int) { return 1; }
#define portENTER_CRITICAL(value) (void)(value)
#define portEXIT_CRITICAL(value) (void)(value)
struct SerialAdapter {
    template <typename... Args> void printf(const char*, Args...) {}
} Serial;
struct EspAdapter { unsigned restarts = 0; void restart() { ++restarts; } } ESP;

struct httpd_req_t {
    const char* uri = "/";
    int method = HTTP_GET;
    int content_len = 0;
    void* user_ctx = nullptr;
    std::string incoming;
    std::string cookie;
    size_t received = 0;
    std::string status = "200 OK";
    std::string type;
    std::map<std::string, std::string> headers;
    std::string outgoing;
    std::vector<std::string> activity;
    size_t sendCount = 0;
    size_t failSendAt = 0;
    bool complete = false;
};

esp_err_t httpd_resp_set_status(httpd_req_t* request, const char* value) {
    request->status = value;
    return ESP_OK;
}
esp_err_t httpd_resp_set_type(httpd_req_t* request, const char* value) {
    request->type = value;
    return ESP_OK;
}
esp_err_t httpd_resp_set_hdr(httpd_req_t* request, const char* key, const char* value) {
    request->headers[key] = value;
    return ESP_OK;
}
esp_err_t transmit(httpd_req_t* request, const char* bytes, std::ptrdiff_t length, bool chunked) {
    request->activity.emplace_back("send");
    if (++request->sendCount == request->failSendAt) {
        request->activity.emplace_back("send-failure");
        return ESP_ERR_HTTPD_RESP_SEND;
    }
    if (length == HTTPD_RESP_USE_STRLEN) length = std::strlen(bytes);
    if (bytes && length) request->outgoing.append(bytes, static_cast<size_t>(length));
    if (!chunked || !length) {
        request->complete = true;
        request->activity.emplace_back("response-complete");
    }
    return ESP_OK;
}
esp_err_t httpd_resp_send(httpd_req_t* request, const char* bytes, std::ptrdiff_t length) {
    return transmit(request, bytes, length, false);
}
esp_err_t httpd_resp_send_chunk(httpd_req_t* request, const char* bytes, std::ptrdiff_t length) {
    return transmit(request, bytes, length, true);
}
int httpd_req_recv(httpd_req_t* request, char* buffer, size_t maximum) {
    const size_t count = std::min(maximum, request->incoming.size() - request->received);
    std::memcpy(buffer, request->incoming.data() + request->received, count);
    request->received += count;
    return static_cast<int>(count);
}
esp_err_t httpd_req_get_hdr_value_str(httpd_req_t* request, const char* name, char* output, size_t size) {
    if (std::strcmp(name, "Cookie") || request->cookie.empty() || request->cookie.size() >= size) return ESP_FAIL;
    std::memcpy(output, request->cookie.c_str(), request->cookie.size() + 1);
    return ESP_OK;
}

namespace bs {
String randomHex(size_t bytes) {
    static unsigned sequence = 0;
    return String(bytes * 2, static_cast<char>('a' + (++sequence % 6)));
}
struct SettingsAdapter {
    bool admin = true;
    int passwordChecks = 0;
    String user = "synthetic_admin";
    String password = "synthetic-password";
    insights::Config notificationConfig{};
    bool saveNotificationsOk = true;
    unsigned notificationWrites = 0;
    bool setOrionOk = true, forgetOrionOk = true;
    unsigned orionWrites = 0, forgetWrites = 0;
    String storedMac, storedKey;
    uint8_t storedInput = 1, storedOutput = 0;
    bool notificationSettingsValid() const { return true; }
    bool setNotifications(const insights::Config& value) {
        ++notificationWrites;
        if (!saveNotificationsOk) return false;
        notificationConfig = value;
        return true;
    }
    bool hasAdmin() const { return admin; }
    bool hasOrion() const { return !storedMac.isEmpty(); }
    const String& username() const { return user; }
    String mac() const { return storedMac; }
    String inputAlias() const { return "Input"; }
    String outputAlias() const { return "Output"; }
    uint8_t inputInstance() const { return storedInput; }
    uint8_t outputInstance() const { return storedOutput; }
    bool checkAdmin(const String& name, const String& candidate) {
        ++passwordChecks;
        return name == user && candidate == password;
    }
    bool changePassword(const String& value) { password = value; return true; }
    bool setAdmin(const String&, const String&) { admin = true; return true; }
    bool setAliases(const String&, const String&) { return true; }
    bool setOrion(const String& mac, const String& key, uint8_t output, uint8_t input) {
        ++orionWrites;
        if (!setOrionOk) return false;
        storedMac = mac; storedKey = key; storedOutput = output; storedInput = input;
        return true;
    }
    bool forgetOrion() {
        ++forgetWrites;
        if (!forgetOrionOk) return false;
        storedMac.clear(); storedKey.clear();
        return true;
    }
};
struct ReceiverAdapter {
    orion::Telemetry snapshot(const orion::Telemetry& value) const { return value; }
    String lastProblem() const { return "Waiting"; }
    unsigned receivedFrames() const { return 0; }
    unsigned rejectedFrames() const { return 0; }
    unsigned droppedFrames() const { return 0; }
    unsigned duplicateFrames() const { return 0; }
    unsigned startupFailures() const { return 0; }
    unsigned errors() const { return 0; }
};
struct NmeaAdapter {
    bool restartRequested = false;
    void prepareForRestart() { restartRequested = true; }
    struct Clock {
        bool ready = false;
        bool utcFor(uint64_t at, uint64_t& utc) const {
            if (!ready) return false;
            utc = 1780000000000ULL + at;
            return true;
        }
    };
    Clock clock;
    static bool alertsSupported() { return true; }
    Clock clockSnapshot() const { return clock; }
    String timeJson() const { return "{}"; }
    String deliveryJson() const { return "{}"; }
    unsigned transmitted() const { return 0; }
    unsigned failed() const { return 0; }
    String monitorJson(uint8_t, uint8_t) const { return "[]"; }
};
using NmeaPublisher = NmeaAdapter;

struct DiagnosticsAdapter {
    bool operational = true;
    bool available() const { return operational; }
    insights::Config config{};
    unsigned configureCalls = 0, ackCalls = 0;
    uint32_t activeGeneration = 7;
    String insightsJson() const { return "{}"; }
    String notificationsJson(bool, const String&, bool) const { return "{}"; }
    bool configure(const insights::Config& value) { config = value; ++configureCalls; return true; }
    bool acknowledge(uint8_t slot, uint32_t generation) {
        ++ackCalls;
        return slot == 0 && generation == activeGeneration;
    }
};

class BridgePortal {
public:
    struct Event {
        uint32_t sequence = 0;
        uint64_t atMs = 0;
        char type[16]{}, detail[80]{};
    };
    static constexpr size_t kEventCount = 64;
    SettingsAdapter settings;
    ReceiverAdapter receiver;
    NmeaAdapter nmea;
    DiagnosticsAdapter diagnostics;
    orion::Telemetry telemetry;
    SettingsAdapter* settings_ = &settings;
    ReceiverAdapter* receiver_ = &receiver;
    NmeaAdapter* nmea_ = &nmea;
    orion::Telemetry* telemetry_ = &telemetry;
    DiagnosticsAdapter* diagnostics_ = &diagnostics;
    String session_, csrf_, recoveryCsrf_;
    uint32_t recoveryStartedMs_ = 0, sessionLastMs_ = 0, lastClientMs_ = 0, nextSequence_ = 1;
    std::atomic<bool> otaRestartPending_{false};
    Event events_[kEventCount]{};
    uint32_t bootId_ = 12345;
    uint32_t otaRestartStartedMs_ = 0;
    mutable int eventMux_ = 0;

    static esp_err_t dispatch(httpd_req_t*);
    esp_err_t handle(httpd_req_t*);
    static void send(httpd_req_t*, const String&, const char* type = "text/html");
    esp_err_t sendPage(httpd_req_t*, const char*, const char* title = "", const char* text = "");
    static void denied(httpd_req_t*);
    String body(httpd_req_t*, size_t maximum = 512);
    static String field(const String&, const char*);
    static String escape(const String&);
    static String jsonEscape(const String&);
    bool authenticated(httpd_req_t*);
    bool csrfValid(const String&) const;
    void newSession();
    void endSession(httpd_req_t*);
    void addEvent(const char*, const char*) {}
    String eventsJson(uint32_t after) const;
    void scheduleRestart();
    esp_err_t notificationSettings(httpd_req_t*, const String&);
    esp_err_t notificationAcknowledge(httpd_req_t*, const String&);
    esp_err_t firmwareInfo(httpd_req_t* request) { send(request, "{}"); return ESP_OK; }
    esp_err_t firmwareUpload(httpd_req_t* request) { send(request, "{}"); return ESP_OK; }
};
} // namespace bs

#include "portal_http_methods.inc"

namespace {
unsigned checks = 0;
void require(bool value, const char* message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}

void invoke(bs::BridgePortal& portal, httpd_req_t& request) {
    request.user_ctx = &portal;
    request.content_len = static_cast<int>(request.incoming.size());
    const esp_err_t result = bs::BridgePortal::dispatch(&request);
    // IDF 4.4.7 closes the current socket after a handler returns non-OK. A
    // Connection header by itself does not invoke that lifecycle operation.
    require(result != ESP_OK, "Firmware dispatch must release the HTTPS connection");
    request.activity.emplace_back("handler-returned-close");
    require(request.headers["Connection"] == "close", "Close header must match socket lifecycle");
}

void completedBeforeClose(const httpd_req_t& request) {
    require(request.complete, "Response must finish before the close signal");
    require(request.activity.size() >= 2 &&
        request.activity[request.activity.size() - 2] == "response-complete",
        "Final response bytes must precede the close signal");
}

void loginRedirectRetainsCookieAndBody() {
    bs::BridgePortal portal;
    httpd_req_t request;
    request.uri = "/login";
    request.method = HTTP_POST;
    request.incoming = "user=synthetic_admin&password=synthetic-password";
    invoke(portal, request);
    completedBeforeClose(request);
    require(request.status == "303 See Other", "Valid login must redirect");
    require(request.headers["Location"] == "/", "Login target must be canonical root");
    require(request.outgoing == "Signed in", "Login response body must be preserved");
    require(request.headers["Set-Cookie"] == "session=" + portal.session_ +
        "; Secure; HttpOnly; SameSite=Strict; Path=/", "Login cookie must precede closure");
    require(portal.session_.length() == 32, "Login must create a session");
    require(portal.settings.passwordChecks == 1, "Login must verify its supplied credentials");

    httpd_req_t dashboard;
    dashboard.cookie = "session=" + portal.session_;
    invoke(portal, dashboard);
    completedBeforeClose(dashboard);
    require(dashboard.status == "200 OK", "Redirected dashboard must succeed");
    require(dashboard.outgoing.find("id=\"password-form\"") != std::string::npos,
        "Authenticated follow-up must receive the actual dashboard");
}

void getLoginRedirectsForEveryAccountState() {
    for (unsigned state = 0; state < 3; ++state) {
        bs::BridgePortal portal;
        portal.settings.admin = state != 0;
        httpd_req_t request;
        request.uri = "/login";
        if (state == 2) {
            portal.newSession();
            request.cookie = "session=" + portal.session_;
        }
        const String originalSession = portal.session_;
        invoke(portal, request);
        completedBeforeClose(request);
        require(request.status == "303 See Other", "GET /login must redirect before the auth guard");
        require(request.headers["Location"] == "/", "GET /login must use canonical root");
        require(request.headers.count("Set-Cookie") == 0, "GET /login must not replace authentication");
        require(portal.session_ == originalSession && portal.settings.passwordChecks == 0,
            "GET /login must not verify passwords or mutate a session");
    }
}

void errorsAndPageResponsesAlsoClose() {
    bs::BridgePortal portal;
    httpd_req_t badPassword;
    badPassword.uri = "/login";
    badPassword.method = HTTP_POST;
    badPassword.incoming = "user=synthetic_admin&password=incorrect-password";
    invoke(portal, badPassword);
    completedBeforeClose(badPassword);
    require(badPassword.status == "401 Unauthorized", "Wrong password must remain unauthorized");
    require(badPassword.headers.count("Set-Cookie") == 0 && portal.session_.empty(),
        "Wrong password must not set a session");

    httpd_req_t loginPage;
    invoke(portal, loginPage);
    completedBeforeClose(loginPage);
    require(loginPage.outgoing.find("id=\"login-submit\"") != std::string::npos,
        "Unauthenticated root must retain the actual login page");

    httpd_req_t protectedRequest;
    protectedRequest.uri = "/password";
    protectedRequest.method = HTTP_POST;
    invoke(portal, protectedRequest);
    completedBeforeClose(protectedRequest);
    require(protectedRequest.status == "401 Unauthorized", "Protected route must remain unauthorized");

    portal.otaRestartPending_.store(true);
    httpd_req_t restarting;
    invoke(portal, restarting);
    completedBeforeClose(restarting);
    require(restarting.status == "409 Conflict", "Pending OTA response must retain its status");
}

std::string validNotificationForm(const bs::BridgePortal& portal) {
    std::string form = "csrf=" + portal.csrf_ +
        "&enabled=1&data_loss_enabled=1&charger_error_enabled=1&data_loss_delay_s=30&repeat_minutes=0";
    for (const auto* role : {"input", "output"}) {
        for (const auto& value : {"_low_enabled=1", "_low_v=12.00", "_low_clear_v=12.30",
                                 "_high_v=15.00", "_high_clear_v=14.70", "_delay_s=10", "_clear_s=30"})
            form += "&" + std::string(role) + value;
    }
    return form;
}

httpd_req_t authenticatedPost(bs::BridgePortal& portal, const char* uri, const std::string& body) {
    httpd_req_t request;
    request.uri = uri;
    request.method = HTTP_POST;
    request.cookie = "session=" + portal.session_;
    request.incoming = body;
    invoke(portal, request);
    return request;
}

void notificationAuthorizationAndAtomicApplication() {
    bs::BridgePortal portal;
    portal.newSession();
    const auto form = validNotificationForm(portal);
    httpd_req_t denied;
    denied.uri = "/notifications";
    denied.method = HTTP_POST;
    denied.incoming = form;
    invoke(portal, denied);
    require(denied.status == "401 Unauthorized" && portal.settings.notificationWrites == 0,
            "Unauthenticated notification configuration cannot write settings");
    const auto forbidden = authenticatedPost(portal, "/notifications", "csrf=wrong&enabled=1");
    require(forbidden.status == "403 Forbidden" && portal.settings.notificationWrites == 0,
            "Notification settings require matching CSRF");
    const auto good = authenticatedPost(portal, "/notifications", form);
    completedBeforeClose(good);
    require(good.status == "303 See Other" && good.headers.at("Location") == "/#notifications",
            "Saved notifications return to their panel");
    require(portal.settings.notificationConfig.enabled &&
            portal.settings.notificationConfig.channels[0].lowCv == 1200 &&
            portal.settings.notificationConfig.channels[1].clearS == 30 &&
            portal.diagnostics.configureCalls == 1, "Notification config must retain typed per-channel settings");
    const auto baseline = portal.diagnostics.config;
    for (const auto& invalid : {"12garbage", "nan", "1e1", "-12", "12.001", "65.01"}) {
        auto bad = form;
        const auto at = bad.find("input_low_v=12.00");
        bad.replace(at, std::strlen("input_low_v=12.00"), "input_low_v=" + std::string(invalid));
        const auto result = authenticatedPost(portal, "/notifications", bad);
        require(result.status == "400 Bad Request", "Invalid voltage text must be rejected by firmware");
        require(portal.settings.notificationWrites == 1 && portal.diagnostics.configureCalls == 1,
                "Rejected settings must not mutate persistence or runtime");
    }
    auto badThresholds = form;
    badThresholds.replace(badThresholds.find("input_low_clear_v=12.30"),
                          std::strlen("input_low_clear_v=12.30"), "input_low_clear_v=11.00");
    require(authenticatedPost(portal, "/notifications", badThresholds).status == "400 Bad Request",
            "Low clear threshold must be above warning threshold");
    portal.settings.saveNotificationsOk = false;
    require(authenticatedPost(portal, "/notifications", form).status == "500 Internal Server Error",
            "Persistence failure must be reported");
    require(portal.diagnostics.configureCalls == 1 &&
            bs::insights::sameConfig(baseline, portal.diagnostics.config),
            "Persistence failure must preserve running notification rules");
    require(portal.settings.password == "synthetic-password" && portal.settings.user == "synthetic_admin",
            "Notification edits must preserve credentials");
}

void acknowledgementRequiresCurrentIncident() {
    bs::BridgePortal portal;
    portal.newSession();
    const auto prefix = "csrf=" + portal.csrf_ + "&id=0&generation=";
    require(authenticatedPost(portal, "/notifications/ack", prefix + "6").status == "409 Conflict",
            "A prior incident must not acknowledge a new alert");
    require(authenticatedPost(portal, "/notifications/ack", prefix + "7").status == "303 See Other",
            "Current incident acknowledgement succeeds");
    const auto calls = portal.diagnostics.ackCalls;
    require(authenticatedPost(portal, "/notifications/ack", prefix + "4294967296").status == "409 Conflict" &&
            portal.diagnostics.ackCalls == calls, "Overflowed occurrence cannot reach acknowledgement engine");
    require(authenticatedPost(portal, "/notifications/ack", "csrf=bad&id=0&generation=7").status == "403 Forbidden",
            "Acknowledgement is CSRF protected");
}

void unavailableDiagnosticsCannotSaveMonitoringSettings() {
    bs::BridgePortal portal;
    portal.newSession();
    portal.diagnostics.operational = false;
    const auto original = portal.settings.notificationConfig;
    const auto response = authenticatedPost(portal, "/notifications", validNotificationForm(portal));
    completedBeforeClose(response);
    require(response.status == "500 Internal Server Error" || response.status == "503 Service Unavailable",
            "Unavailable diagnostics must report that monitoring settings cannot be applied");
    require(portal.settings.notificationWrites == 0 && portal.diagnostics.configureCalls == 0 &&
            bs::insights::sameConfig(original, portal.settings.notificationConfig),
            "Unavailable monitoring must not persist settings or claim application succeeded");
}

void configurationAndForgetScheduleRestartAfterTheirResponses() {
    for (const bool forget : {false, true}) {
        bs::BridgePortal portal;
        portal.newSession();
        portal.settings.storedMac = "aa:bb:cc:dd:ee:ff";
        portal.settings.storedKey = "0123456789abcdef0123456789abcdef";
        portal.settings.notificationConfig.enabled = true;
        portal.settings.notificationConfig.nmeaEnabled = true;
        portal.settings.notificationConfig.channels[0].lowCv = 1175;
        const auto notifications = portal.settings.notificationConfig;
        const uint32_t startedAt = clockMs;
        const auto restartsBefore = ESP.restarts;
        const std::string form = "csrf=" + portal.csrf_ + (forget ? "" :
            "&mac=11%3A22%3A33%3A44%3A55%3A66&key=fedcba9876543210fedcba9876543210&out=7&in=8");
        const auto response = authenticatedPost(portal, forget ? "/forget" : "/config", form);
        completedBeforeClose(response);
        require(response.status == "200 OK" && !response.outgoing.empty(),
                "Successful device changes return the complete restart page");
        require(portal.otaRestartPending_.load() && portal.nmea.restartRequested,
                "Device changes must schedule main-loop restart and request alert withdrawal");
        require(ESP.restarts == restartsBefore && clockMs == startedAt,
                "Device-change handler must not reboot or delay before main-loop alert draining");
        require(portal.otaRestartStartedMs_ == startedAt,
                "Scheduled restart starts its grace period after the device change");
        require(bs::insights::sameConfig(notifications, portal.settings.notificationConfig) &&
                portal.settings.notificationWrites == 0,
                "Device remapping and forgetting must preserve saved notification configuration");
        require(portal.settings.user == "synthetic_admin" && portal.settings.password == "synthetic-password",
                "Device changes must preserve administrator credentials");
        if (forget) {
            require(portal.settings.forgetWrites == 1 && portal.settings.orionWrites == 0 &&
                    !portal.settings.hasOrion(), "Forget route must erase only the selected Orion connection");
        } else {
            require(portal.settings.orionWrites == 1 && portal.settings.forgetWrites == 0 &&
                    portal.settings.storedMac == "11:22:33:44:55:66" &&
                    portal.settings.storedOutput == 7 && portal.settings.storedInput == 8,
                    "Configuration route must pass decoded identity and mapping to storage");
        }
        const auto blocked = authenticatedPost(portal, "/notifications", validNotificationForm(portal));
        require(blocked.status == "409 Conflict" && portal.settings.notificationWrites == 0,
                "Restart pending must reject new settings while old alert identities drain");
    }
}

void failedDeviceChangesDoNotScheduleRestart() {
    for (const bool forget : {false, true}) {
        bs::BridgePortal portal;
        portal.newSession();
        portal.settings.setOrionOk = false;
        portal.settings.forgetOrionOk = false;
        const auto restartsBefore = ESP.restarts;
        const std::string form = "csrf=" + portal.csrf_ + (forget ? "" :
            "&mac=11%3A22%3A33%3A44%3A55%3A66&key=fedcba9876543210fedcba9876543210&out=7&in=8");
        const auto response = authenticatedPost(portal, forget ? "/forget" : "/config", form);
        completedBeforeClose(response);
        require(response.status == (forget ? "500 Internal Server Error" : "400 Bad Request"),
                "Failed device settings must return their failure response");
        require(!portal.otaRestartPending_.load() && !portal.nmea.restartRequested && ESP.restarts == restartsBefore,
                "Failed device settings cannot withdraw alerts or schedule a restart");
    }
}

void eventsGainUtcWithoutLosingUptime() {
    bs::BridgePortal portal;
    portal.events_[0].sequence = 1;
    portal.events_[0].atMs = 1250;
    std::strcpy(portal.events_[0].type, "BOOT");
    std::strcpy(portal.events_[0].detail, "Synthetic <event>");
    portal.nextSequence_ = 2;
    const auto before = portal.eventsJson(0);
    require(before.find("\"ms\":1250") != std::string::npos &&
            before.find("\"utcMs\":null") != std::string::npos,
            "Before network synchronization logs retain uptime without a fabricated date");
    portal.nmea.clock.ready = true;
    const auto after = portal.eventsJson(0);
    require(after.find("\"ms\":1250") != std::string::npos &&
            after.find("\"utcMs\":1780000001250") != std::string::npos,
            "Earlier same-boot events gain estimated UTC after synchronization");
    require(portal.eventsJson(1) == "[]", "Normal event cursor still filters already delivered events");
    require(portal.eventsJson(999).find("Synthetic") != std::string::npos,
            "A stale previous-boot cursor cannot permanently hide the current event ring");
}

void failedSendsStillReleaseConnection() {
    for (bool page : {false, true}) {
        bs::BridgePortal portal;
        httpd_req_t request;
        request.failSendAt = 1;
        if (!page) {
            request.uri = "/login";
            request.method = HTTP_POST;
            request.incoming = "user=synthetic_admin&password=synthetic-password";
        }
        invoke(portal, request);
        require(!request.complete, "Injected send failure must remain incomplete");
        require(request.activity[request.activity.size() - 2] == "send-failure",
            "Transport failure must release its socket without another send");
    }
}
} // namespace

int main() {
    try {
        loginRedirectRetainsCookieAndBody();
        getLoginRedirectsForEveryAccountState();
        errorsAndPageResponsesAlsoClose();
        failedSendsStillReleaseConnection();
        notificationAuthorizationAndAtomicApplication();
        acknowledgementRequiresCurrentIncident();
        unavailableDiagnosticsCannotSaveMonitoringSettings();
        configurationAndForgetScheduleRestartAfterTheirResponses();
        failedDeviceChangesDoNotScheduleRestart();
        eventsGainUtcWithoutLosingUptime();
        std::cout << "PASS: " << checks << " actual-firmware HTTP checks; login cookie/redirect, GET recovery, "
                     "response completion, authentication errors, OTA busy and send-failure closure.\n";
    } catch (const std::exception& error) {
        std::cerr << "FAIL: " << error.what() << '\n';
        return 1;
    }
}
