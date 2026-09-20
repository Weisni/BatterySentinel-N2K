#include "BridgePortal.h"
#include "BridgePortalUi.h"
#include "BridgePortalTranslations.h"
#include "BridgePortalLanguage.h"
#include <HWCDC.h>

#include <WiFi.h>
#include <esp_system.h>
#include <mbedtls/bignum.h>
#include <mbedtls/ecp.h>
#include <mbedtls/oid.h>
#include <mbedtls/pk.h>
#include <mbedtls/x509_crt.h>
#include <cstring>

namespace bs {
namespace {

int hardwareRandom(void*, unsigned char* output, size_t length) {
    esp_fill_random(output, length);
    return 0;
}

String randomHex(size_t bytes) {
    static const char digits[] = "0123456789abcdef";
    String result;
    result.reserve(bytes * 2);
    for (size_t i = 0; i < bytes; ++i) {
        const uint8_t value = static_cast<uint8_t>(esp_random());
        result += digits[value >> 4];
        result += digits[value & 0x0f];
    }
    return result;
}

String numberOrNull(const orion::Value& value, bool fresh) {
    return fresh && value.valid ? String(value.number, 2) : String("null");
}

void serverStarted(void*) {
    Serial.println("HTTPS server task ready");
}

void responseHeaders(httpd_req_t* request, const char* type) {
    httpd_resp_set_type(request, type);
    httpd_resp_set_hdr(request, "Cache-Control", "no-store");
    httpd_resp_set_hdr(request, "Connection", "close");
    httpd_resp_set_hdr(request, "X-Content-Type-Options", "nosniff");
    httpd_resp_set_hdr(request, "X-Frame-Options", "DENY");
}

} // namespace

void BridgePortal::begin(BridgeSettings& settings, OrionBleReceiver& receiver,
                         NmeaPublisher& nmea, orion::Telemetry& telemetry) {
    settings_ = &settings;
    receiver_ = &receiver;
    nmea_ = &nmea;
    telemetry_ = &telemetry;
    pinMode(9, INPUT_PULLUP); // BOOT button on common ESP32-C3 SuperMini boards.
    // Keep a short service window on every boot. Otherwise provisioning the
    // administrator can make the device disappear after its first restart.
    start();
}

size_t BridgePortal::httpsClients() const {
    if (!server_) return 0;
    int sockets[3]{};
    size_t count = 3;
    return httpd_get_client_list(server_, &count, sockets) == ESP_OK ? count : 0;
}

bool BridgePortal::ensureCertificate() {
    certificate_ = settings_->certificate();
    privateKey_ = settings_->privateKey();
    if (settings_->hasCurrentCertificate() &&
        certificate_.length() > 100 && privateKey_.length() > 100) {
        mbedtls_x509_crt storedCert;
        mbedtls_pk_context storedKey;
        mbedtls_x509_crt_init(&storedCert);
        mbedtls_pk_init(&storedKey);
        const int certResult = mbedtls_x509_crt_parse(&storedCert,
            reinterpret_cast<const unsigned char*>(certificate_.c_str()), certificate_.length() + 1);
        const int keyResult = mbedtls_pk_parse_key(&storedKey,
            reinterpret_cast<const unsigned char*>(privateKey_.c_str()), privateKey_.length() + 1,
            nullptr, 0);
        const int pairResult = certResult == 0 && keyResult == 0 ?
            mbedtls_pk_check_pair(&storedCert.pk, &storedKey) : -1;
        mbedtls_pk_free(&storedKey);
        mbedtls_x509_crt_free(&storedCert);
        Serial.printf("Stored HTTPS certificate: cert=%d key=%d pair=%d\n",
                      certResult, keyResult, pairResult);
        if (certResult == 0 && keyResult == 0 && pairResult == 0) return true;
    }

    mbedtls_pk_context key;
    mbedtls_x509write_cert cert;
    mbedtls_mpi serial;
    mbedtls_pk_init(&key);
    mbedtls_x509write_crt_init(&cert);
    mbedtls_mpi_init(&serial);
    char certificatePem[1800]{};
    char keyPem[900]{};
    bool ok = mbedtls_pk_setup(&key, mbedtls_pk_info_from_type(MBEDTLS_PK_ECKEY)) == 0;
    if (ok) ok = mbedtls_ecp_gen_key(MBEDTLS_ECP_DP_SECP256R1,
        mbedtls_pk_ec(key), hardwareRandom, nullptr) == 0;
    if (ok) ok = mbedtls_mpi_lset(&serial, 1) == 0;
    if (ok) {
        mbedtls_x509write_crt_set_subject_key(&cert, &key);
        mbedtls_x509write_crt_set_issuer_key(&cert, &key);
        mbedtls_x509write_crt_set_md_alg(&cert, MBEDTLS_MD_SHA256);
        ok = mbedtls_x509write_crt_set_subject_name(&cert, "CN=192.168.4.1") == 0 &&
             mbedtls_x509write_crt_set_issuer_name(&cert, "CN=192.168.4.1") == 0 &&
             mbedtls_x509write_crt_set_serial(&cert, &serial) == 0 &&
             mbedtls_x509write_crt_set_validity(&cert, "20260101000000", "20351231235959") == 0;
    }
    if (ok) {
        // GeneralNames ::= SEQUENCE { iPAddress [7] OCTET STRING 192.168.4.1 }
        static const unsigned char ipSan[] = {0x30, 0x06, 0x87, 0x04, 192, 168, 4, 1};
        // ExtendedKeyUsage ::= SEQUENCE { id-kp-serverAuth }
        static const unsigned char serverAuth[] =
            {0x30, 0x0a, 0x06, 0x08, 0x2b, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x01};
        ok = mbedtls_x509write_crt_set_basic_constraints(&cert, 0, -1) == 0 &&
             mbedtls_x509write_crt_set_key_usage(&cert, MBEDTLS_X509_KU_DIGITAL_SIGNATURE) == 0 &&
             mbedtls_x509write_crt_set_extension(&cert, MBEDTLS_OID_SUBJECT_ALT_NAME,
                 sizeof(MBEDTLS_OID_SUBJECT_ALT_NAME) - 1, 0, ipSan, sizeof(ipSan)) == 0 &&
             mbedtls_x509write_crt_set_extension(&cert, MBEDTLS_OID_EXTENDED_KEY_USAGE,
                 sizeof(MBEDTLS_OID_EXTENDED_KEY_USAGE) - 1, 0,
                 serverAuth, sizeof(serverAuth)) == 0;
    }
    if (ok) ok = mbedtls_x509write_crt_pem(&cert,
        reinterpret_cast<unsigned char*>(certificatePem), sizeof(certificatePem), hardwareRandom, nullptr) == 0;
    if (ok) ok = mbedtls_pk_write_key_pem(&key,
        reinterpret_cast<unsigned char*>(keyPem), sizeof(keyPem)) == 0;
    if (ok) ok = settings_->saveCertificate(certificatePem, keyPem);
    if (ok) {
        certificate_ = certificatePem;
        privateKey_ = keyPem;
    }
    std::memset(keyPem, 0, sizeof(keyPem));
    mbedtls_mpi_free(&serial);
    mbedtls_x509write_crt_free(&cert);
    mbedtls_pk_free(&key);
    return ok;
}

bool BridgePortal::start() {
    if (server_) return true;
    if (!ensureCertificate()) {
        Serial.println("HTTPS certificate setup failed");
        return false;
    }
    const uint64_t chip = ESP.getEfuseMac();
    char ssid[32];
    snprintf(ssid, sizeof(ssid), "OrionBridge-%06lX",
             static_cast<unsigned long>(chip & 0xffffff));
    WiFi.mode(WIFI_AP);
    if (!WiFi.softAP(ssid, settings_->apPassword().c_str())) return false;
    httpd_ssl_config_t config = HTTPD_SSL_CONFIG_DEFAULT();
    config.cacert_pem = reinterpret_cast<const uint8_t*>(certificate_.c_str());
    config.cacert_len = certificate_.length() + 1;
    config.prvtkey_pem = reinterpret_cast<const uint8_t*>(privateKey_.c_str());
    config.prvtkey_len = privateKey_.length() + 1;
    config.httpd.max_uri_handlers = 16;
    config.httpd.max_open_sockets = 3;
    config.httpd.lru_purge_enable = true;
    const esp_err_t startResult = httpd_ssl_start(&server_, &config);
    if (startResult != ESP_OK) {
        Serial.printf("Web server start failed: %d\n", startResult);
        WiFi.softAPdisconnect(true);
        WiFi.mode(WIFI_OFF);
        return false;
    }
    for (const char* path : {"/", "/setup", "/login", "/logout", "/config", "/forget", "/api/live", "/api/events"}) {
        for (httpd_method_t method : {HTTP_GET, HTTP_POST}) {
            httpd_uri_t uri{};
            uri.uri = path;
            uri.method = method;
            uri.handler = dispatch;
            uri.user_ctx = this;
            const esp_err_t registerResult = httpd_register_uri_handler(server_, &uri);
            if (registerResult != ESP_OK)
                Serial.printf("HTTPS route registration failed: %s %d\n", path, registerResult);
        }
    }
    const esp_err_t probeResult = httpd_queue_work(server_, serverStarted, nullptr);
    if (probeResult != ESP_OK) Serial.printf("HTTPS task probe failed: %d\n", probeResult);
    lastClientMs_ = millis();
    Serial.printf("Service Wi-Fi: %s, https://%s/\n", ssid,
                  WiFi.softAPIP().toString().c_str());
    addEvent("PORTAL", "Service portal opened");
    return true;
}

void BridgePortal::stop() {
    if (!server_) return;
    httpd_ssl_stop(server_);
    server_ = nullptr;
    WiFi.softAPdisconnect(true);
    WiFi.mode(WIFI_OFF);
    session_.clear();
    csrf_.clear();
    addEvent("PORTAL", "Service portal closed");
}

void BridgePortal::loop() {
    const uint32_t now = millis();
    if (digitalRead(9) == LOW) {
        if (!buttonSinceMs_) buttonSinceMs_ = now;
        if (!buttonTriggered_ && static_cast<uint32_t>(now - buttonSinceMs_) > 2000) {
            if (!server_) start();
            if (Serial) Serial.printf("Service AP password: %s\n", settings_->apPassword().c_str());
            buttonTriggered_ = true;
        }
    } else {
        buttonSinceMs_ = 0;
        buttonTriggered_ = false;
    }
    if (server_ && static_cast<uint32_t>(now - lastServiceCheckMs_) >= 1000) {
        lastServiceCheckMs_ = now;
        if (WiFi.softAPgetStationNum() > 0) lastClientMs_ = now;
        if (static_cast<uint32_t>(now - lastClientMs_) > 5UL * 60UL * 1000UL)
            stop();
    }
}

void BridgePortal::addEvent(const char* type, const char* detail) {
    Event& event = events_[(nextSequence_ - 1) % kEventCount];
    event.sequence = nextSequence_++;
    event.atMs = millis();
    strlcpy(event.type, type, sizeof(event.type));
    strlcpy(event.detail, detail, sizeof(event.detail));
}

esp_err_t BridgePortal::dispatch(httpd_req_t* request) {
    return static_cast<BridgePortal*>(request->user_ctx)->handle(request);
}

void BridgePortal::send(httpd_req_t* request, const String& data, const char* type) {
    responseHeaders(request, type);
    httpd_resp_send(request, data.c_str(), data.length());
}

esp_err_t BridgePortal::sendPage(httpd_req_t* request, const char* body,
                                  const char* messageTitle, const char* messageText) {
    responseHeaders(request, "text/html; charset=utf-8");
    if (httpd_resp_send_chunk(request, ui::kDocumentStart,
                              strlen(ui::kDocumentStart)) != ESP_OK) return ESP_FAIL;
    if (httpd_resp_send_chunk(request, ui::kTranslations,
                              strlen(ui::kTranslations)) != ESP_OK) return ESP_FAIL;
    if (httpd_resp_send_chunk(request, ui::kLanguageController,
                              strlen(ui::kLanguageController)) != ESP_OK) return ESP_FAIL;
    const char* cursor = body;
    while (const char* marker = strstr(cursor, "{{")) {
        const char* end = strstr(marker + 2, "}}");
        if (!end) return ESP_FAIL;
        if (marker > cursor &&
            httpd_resp_send_chunk(request, cursor, marker - cursor) != ESP_OK) return ESP_FAIL;
        const size_t nameLength = end - marker - 2;
        const char* replacement = "";
        String dynamicValue;
        if (nameLength == 5 && strncmp(marker + 2, "BRAND", 5) == 0)
            replacement = ui::kBrand;
        else if (nameLength == 4 && strncmp(marker + 2, "CSRF", 4) == 0)
            replacement = csrf_.c_str();
        else if (nameLength == 3 && strncmp(marker + 2, "MAC", 3) == 0) {
            dynamicValue = escape(settings_->mac());
            replacement = dynamicValue.c_str();
        } else if (nameLength == 12 && strncmp(marker + 2, "OUT_INSTANCE", 12) == 0) {
            dynamicValue = String(settings_->outputInstance());
            replacement = dynamicValue.c_str();
        } else if (nameLength == 11 && strncmp(marker + 2, "IN_INSTANCE", 11) == 0) {
            dynamicValue = String(settings_->inputInstance());
            replacement = dynamicValue.c_str();
        } else if (nameLength == 10 && strncmp(marker + 2, "CONFIGURED", 10) == 0)
            replacement = settings_->hasOrion() ? "1" : "0";
        else if (nameLength == 13 && strncmp(marker + 2, "MESSAGE_TITLE", 13) == 0)
            replacement = messageTitle;
        else if (nameLength == 12 && strncmp(marker + 2, "MESSAGE_TEXT", 12) == 0)
            replacement = messageText;
        if (*replacement &&
            httpd_resp_send_chunk(request, replacement, strlen(replacement)) != ESP_OK)
            return ESP_FAIL;
        cursor = end + 2;
    }
    if (httpd_resp_send_chunk(request, cursor, strlen(cursor)) != ESP_OK) return ESP_FAIL;
    if (httpd_resp_send_chunk(request, ui::kDocumentEnd,
                              strlen(ui::kDocumentEnd)) != ESP_OK) return ESP_FAIL;
    return httpd_resp_send_chunk(request, nullptr, 0);
}

void BridgePortal::denied(httpd_req_t* request) {
    httpd_resp_set_status(request, "401 Unauthorized");
    send(request, "Login required", "text/plain");
}

String BridgePortal::body(httpd_req_t* request) {
    if (request->content_len < 0 || request->content_len > 512) return "";
    char buffer[513]{};
    int received = 0;
    while (received < request->content_len) {
        const int n = httpd_req_recv(request, buffer + received, request->content_len - received);
        if (n <= 0) return "";
        received += n;
    }
    return String(buffer);
}

String BridgePortal::field(const String& form, const char* name) {
    const String prefix = String(name) + "=";
    int pos = form.indexOf(prefix);
    if (pos < 0 || (pos > 0 && form[pos - 1] != '&')) return "";
    pos += prefix.length();
    int end = form.indexOf('&', pos);
    if (end < 0) end = form.length();
    String result;
    for (int i = pos; i < end; ++i) {
        if (form[i] == '+') result += ' ';
        else if (form[i] == '%' && i + 2 < end) {
            const char hex[3] = {form[i + 1], form[i + 2], 0};
            result += static_cast<char>(strtoul(hex, nullptr, 16));
            i += 2;
        } else result += form[i];
    }
    return result;
}

String BridgePortal::escape(const String& value) {
    String result = value;
    result.replace("&", "&amp;"); result.replace("<", "&lt;");
    result.replace(">", "&gt;"); result.replace("\"", "&quot;");
    result.replace("'", "&#39;");
    return result;
}

String BridgePortal::jsonEscape(const String& value) {
    String result;
    for (size_t i = 0; i < value.length(); ++i) {
        const char c = value[i];
        if (c == '\\' || c == '"') result += '\\';
        if (c >= 32) result += c;
    }
    return result;
}

bool BridgePortal::authenticated(httpd_req_t* request) {
    if (session_.length() != 32 ||
        static_cast<uint32_t>(millis() - sessionLastMs_) > 15UL * 60UL * 1000UL) return false;
    char cookie[160]{};
    if (httpd_req_get_hdr_value_str(request, "Cookie", cookie, sizeof(cookie)) != ESP_OK)
        return false;
    if (String(cookie).indexOf("session=" + session_) < 0) return false;
    sessionLastMs_ = millis();
    return true;
}

bool BridgePortal::csrfValid(const String& form) const {
    return csrf_.length() == 32 && field(form, "csrf") == csrf_;
}

void BridgePortal::newSession() {
    session_ = randomHex(16);
    csrf_ = randomHex(16);
    sessionLastMs_ = millis();
}

esp_err_t BridgePortal::handle(httpd_req_t* request) {
    const String path(request->uri);
    const bool post = request->method == HTTP_POST;
    lastClientMs_ = millis();
    if (path == "/setup" && post && !settings_->hasAdmin()) {
        if (digitalRead(9) != LOW) {
            httpd_resp_set_status(request, "403 Forbidden");
            return sendPage(request, ui::kMessageBody, "Hold BOOT to continue",
                            "Hold the physical BOOT button while creating the administrator account.");
        }
        const String form = body(request);
        if (!settings_->setAdmin(field(form, "user"), field(form, "password"))) {
            httpd_resp_set_status(request, "400 Bad Request");
            return sendPage(request, ui::kMessageBody, "Check account details",
                            "Use a 3–32 character username and a password of at least 12 characters.");
        }
        newSession();
        const String cookie = "session=" + session_ + "; Secure; HttpOnly; SameSite=Strict; Path=/";
        httpd_resp_set_hdr(request, "Set-Cookie", cookie.c_str());
        httpd_resp_set_status(request, "303 See Other");
        httpd_resp_set_hdr(request, "Location", "/");
        send(request, "Administrator created", "text/plain");
        addEvent("ADMIN", "Administrator provisioned");
        return ESP_OK;
    }
    if (path == "/login" && post && settings_->hasAdmin()) {
        const String form = body(request);
        const uint32_t verificationStartedMs = millis();
        const bool valid = settings_->checkAdmin(field(form, "user"), field(form, "password"));
        const uint32_t verificationMs = millis() - verificationStartedMs;
        if (!valid) {
            delay(500);
            httpd_resp_set_status(request, "401 Unauthorized");
            return sendPage(request, ui::kMessageBody, "Sign-in did not work",
                            "Check the administrator username and password, then try again.");
        }
        char detail[64];
        snprintf(detail, sizeof(detail), "Password verification %lu ms",
                 static_cast<unsigned long>(verificationMs));
        addEvent("AUTH", detail);
        newSession();
        const String cookie = "session=" + session_ + "; Secure; HttpOnly; SameSite=Strict; Path=/";
        httpd_resp_set_hdr(request, "Set-Cookie", cookie.c_str());
        httpd_resp_set_status(request, "303 See Other");
        httpd_resp_set_hdr(request, "Location", "/");
        send(request, "Signed in", "text/plain");
        return ESP_OK;
    }
    if (path == "/" && !post && !settings_->hasAdmin()) {
        return sendPage(request, ui::kFirstSetupBody);
    }
    if (path == "/" && !post && !authenticated(request)) {
        return sendPage(request, ui::kLoginBody);
    }
    if (!authenticated(request)) { denied(request); return ESP_OK; }

    if (path == "/" && !post) {
        return sendPage(request, ui::kDashboardBody);
    }
    if (path.startsWith("/api/live") && !post) {
        const bool fresh = telemetry_->fresh(millis());
        String data = "{\"outV\":" + numberOrNull(telemetry_->outputVoltage, fresh) +
            ",\"outI\":" + numberOrNull(telemetry_->outputCurrent, fresh) +
            ",\"inV\":" + numberOrNull(telemetry_->inputVoltage, fresh) +
            ",\"inI\":" + numberOrNull(telemetry_->inputCurrent, fresh) +
            ",\"outW\":" + (fresh && telemetry_->outputVoltage.valid && telemetry_->outputCurrent.valid ? String(telemetry_->outputVoltage.number * telemetry_->outputCurrent.number, 1) : String("null")) +
            ",\"inW\":" + (fresh && telemetry_->inputVoltage.valid && telemetry_->inputCurrent.valid ? String(telemetry_->inputVoltage.number * telemetry_->inputCurrent.number, 1) : String("null")) +
            ",\"state\":" + (fresh ? String(telemetry_->state) : String("null")) +
            ",\"error\":" + (fresh ? String(telemetry_->error) : String("null")) +
            ",\"offReason\":" + (fresh ? String(telemetry_->offReason) : String("null")) +
            ",\"rssi\":" + (fresh ? String(telemetry_->rssi) : String("null")) +
            ",\"age\":" + (telemetry_->received ? String(millis() - telemetry_->receivedAtMs) : String("null")) +
            ",\"status\":\"" + jsonEscape(!settings_->hasOrion() ? "Unconfigured" :
                !fresh && telemetry_->received ? "Stale" : receiver_->lastProblem()) +
            "\",\"rx\":" + String(receiver_->receivedFrames()) +
            ",\"rejected\":" + String(receiver_->rejectedFrames()) +
            ",\"tx\":" + String(nmea_->transmitted()) +
            ",\"txFailed\":" + String(nmea_->failed()) + ",\"events\":[";
        uint32_t after = 0;
        const int index = path.indexOf("after=");
        if (index >= 0) after = strtoul(path.c_str() + index + 6, nullptr, 10);
        bool first = true;
        const uint32_t firstSeq = nextSequence_ > kEventCount ? nextSequence_ - kEventCount : 1;
        for (uint32_t seq = firstSeq; seq < nextSequence_; ++seq) {
            if (seq <= after) continue;
            const Event& event = events_[(seq - 1) % kEventCount];
            if (!first) data += ',';
            first = false;
            data += "{\"seq\":" + String(event.sequence) + ",\"ms\":" + String(event.atMs) +
                ",\"type\":\"" + jsonEscape(event.type) + "\",\"detail\":\"" +
                jsonEscape(event.detail) + "\"}";
        }
        data += "]}";
        send(request, data, "application/json");
        return ESP_OK;
    }
    if (path.startsWith("/api/events") && !post) {
        uint32_t after = 0;
        const int index = path.indexOf("after=");
        if (index >= 0) after = strtoul(path.c_str() + index + 6, nullptr, 10);
        String data = "{\"events\":[";
        bool first = true;
        const uint32_t firstSeq = nextSequence_ > kEventCount ? nextSequence_ - kEventCount : 1;
        for (uint32_t seq = firstSeq; seq < nextSequence_; ++seq) {
            if (seq <= after) continue;
            const Event& event = events_[(seq - 1) % kEventCount];
            if (!first) data += ',';
            first = false;
            data += "{\"seq\":" + String(event.sequence) + ",\"ms\":" + String(event.atMs) +
                ",\"type\":\"" + jsonEscape(event.type) + "\",\"detail\":\"" +
                jsonEscape(event.detail) + "\"}";
        }
        data += "]}";
        send(request, data, "application/json");
        return ESP_OK;
    }
    if (post) {
        const String form = body(request);
        if (!csrfValid(form)) {
            httpd_resp_set_status(request, "403 Forbidden");
            return sendPage(request, ui::kMessageBody, "Session expired",
                            "Reload the portal and try your change again.");
        }
        if (path == "/logout") {
            session_.clear();
            csrf_.clear();
            httpd_resp_set_hdr(request, "Set-Cookie", "session=; Max-Age=0; Secure; HttpOnly; SameSite=Strict; Path=/");
            httpd_resp_set_status(request, "303 See Other");
            httpd_resp_set_hdr(request, "Location", "/");
            send(request, "Signed out", "text/plain");
            return ESP_OK;
        }
        if (path == "/forget") {
            if (!settings_->forgetOrion()) {
                httpd_resp_set_status(request, "500 Internal Server Error");
                return sendPage(request, ui::kMessageBody, "Could not forget Orion",
                                "The saved identity could not be erased. Restart the dongle and try again.");
            }
            addEvent("CONFIG", "Orion identity and key erased");
            sendPage(request, ui::kRestartBody);
            delay(300);
            ESP.restart();
            return ESP_OK;
        }
        if (path == "/config") {
            const long output = field(form, "out").toInt();
            const long input = field(form, "in").toInt();
            if (output < 0 || output > 252 || input < 0 || input > 252 ||
                !settings_->setOrion(field(form, "mac"), field(form, "key"), output, input)) {
                httpd_resp_set_status(request, "400 Bad Request");
                return sendPage(request, ui::kMessageBody, "Check Orion settings",
                                "Enter a valid MAC, a 32-digit Instant Readout key, and two different NMEA instances.");
            }
            addEvent("CONFIG", "Orion identity and key saved");
            sendPage(request, ui::kRestartBody);
            delay(300);
            ESP.restart();
            return ESP_OK;
        }
    }
    httpd_resp_set_status(request, "404 Not Found");
    send(request, "Not found", "text/plain");
    return ESP_OK;
}

} // namespace bs
