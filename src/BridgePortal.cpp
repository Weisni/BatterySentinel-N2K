#include "BridgePortal.h"
#include "BridgePortalUi.h"
#include "BridgePortalTranslations.h"
#include "BridgePortalLanguage.h"
#include "BridgePortalForm.h"
#include "BridgePortalOta.h"
#include "BridgePortalInsights.h"
#include "BridgeNotificationForm.h"
#include "BridgeFirmwareIdentity.h"
#include "BridgeNetworkIdentity.h"
#include <BridgeCertificateNames.h>
#include <BridgePasswordUpdate.h>
#include <FirmwareOta.h>
#include <HWCDC.h>

#include <WiFi.h>
#include <ESPmDNS.h>
#include <esp_system.h>
#include <esp_ota_ops.h>
#include <esp_wifi.h>
#include <esp_timer.h>
#include <mbedtls/bignum.h>
#include <mbedtls/ecp.h>
#include <mbedtls/oid.h>
#include <mbedtls/pk.h>
#include <mbedtls/platform_util.h>
#include <mbedtls/sha256.h>
#include <mbedtls/x509_crt.h>
#include <cstring>
#include <algorithm>
#include <memory>
#include <new>

namespace bs {
namespace {

void setServiceWifiLed(bool enabled) {
#if defined(BATTERYSENTINEL_ORION_DONGLE) && !defined(BATTERYSENTINEL_ORION_R4)
    // The selected SuperMini's blue LED sinks current on GPIO8. The R4 WROOM
    // carrier has no such LED; do not drive its strapping pin for this feature.
    digitalWrite(8, enabled ? LOW : HIGH);
#else
    (void)enabled;
#endif
}

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
    return fresh && value.valid ? String(value.number, 3) : String("null");
}

void serverStarted(void* ready) {
    Serial.println("HTTPS server task ready");
    static_cast<std::atomic<bool>*>(ready)->store(true);
}

void responseHeaders(httpd_req_t* request, const char* type) {
    httpd_resp_set_type(request, type);
    httpd_resp_set_hdr(request, "Cache-Control", "no-store");
    httpd_resp_set_hdr(request, "Connection", "close");
    httpd_resp_set_hdr(request, "X-Content-Type-Options", "nosniff");
    httpd_resp_set_hdr(request, "X-Frame-Options", "DENY");
}

esp_err_t otaResponse(httpd_req_t* request, const char* status, const char* error) {
    httpd_resp_set_status(request, status);
    responseHeaders(request, "application/json");
    char data[96];
    snprintf(data, sizeof(data), "{\"ok\":false,\"error\":\"%s\"}", error);
    httpd_resp_send(request, data, HTTPD_RESP_USE_STRLEN);
    // Close rejected requests, including any unread upload body. A Connection
    // header alone does not close an ESP-IDF HTTP server session.
    return ESP_FAIL;
}

const esp_partition_t* otaPartition() {
    const auto* running = esp_ota_get_running_partition();
    const auto* next = esp_ota_get_next_update_partition(nullptr);
    if (!running || !next || next->address == running->address ||
        next->size != running->size || next->address > ESP.getFlashChipSize() ||
        next->size > ESP.getFlashChipSize() - next->address ||
        !esp_partition_find_first(ESP_PARTITION_TYPE_DATA, ESP_PARTITION_SUBTYPE_DATA_OTA, nullptr))
        return nullptr;
    return next;
}

// Always release an unfinished OTA handle and its hash context on disconnects
// and failures. The boot selection is untouched until every check succeeds.
struct OtaUpload {
    explicit OtaUpload(std::atomic<bool>& busy) : busy(busy) {
        busy.store(true);
        mbedtls_sha256_init(&hash);
    }
    ~OtaUpload() {
        if (open) esp_ota_abort(handle);
        mbedtls_sha256_free(&hash);
        busy.store(false);
    }
    std::atomic<bool>& busy;
    esp_ota_handle_t handle = 0;
    bool open = false;
    mbedtls_sha256_context hash;
};

} // namespace

void BridgePortal::initializeServiceWifiLed() {
#if defined(BATTERYSENTINEL_ORION_DONGLE) && !defined(BATTERYSENTINEL_ORION_R4)
    // Set the inactive latch before enabling the output, before Serial, BLE or
    // certificate initialization can leave the active-low LED lit during boot.
    digitalWrite(8, HIGH);
    pinMode(8, OUTPUT);
#endif
}

void BridgePortal::updateServiceWifiLed() {
    // Arduino sets/clears AP_STARTED_BIT on AP_START/AP_STOP in its event task.
    // The FreeRTOS event-group read is safe across tasks; no callback writes GPIO
    // or reads server_. A successful softAP() call alone is not readiness.
    const bool apStarted = (WiFi.getStatusBits() & AP_STARTED_BIT) != 0;
    const uint32_t address = apStarted ? static_cast<uint32_t>(WiFi.softAPIP()) : 0;
    const bool ready = server_ && httpsTaskReady_.load() && apStarted &&
        address != 0 && address != UINT32_MAX;
    if (ready != serviceWifiLedOn_) {
        setServiceWifiLed(ready);
        serviceWifiLedOn_ = ready;
    }
}

void BridgePortal::begin(BridgeSettings& settings, OrionBleReceiver& receiver,
                         NmeaPublisher& nmea, orion::Telemetry& telemetry, BridgeDiagnostics& diagnostics) {
    settings_ = &settings;
    receiver_ = &receiver;
    nmea_ = &nmea;
    telemetry_ = &telemetry;
    diagnostics_ = &diagnostics;
    bootId_ = esp_random();
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
    mbedtls_pk_context key;
    mbedtls_pk_init(&key);
    const int keyResult = privateKey_.length() > 100 ? mbedtls_pk_parse_key(&key,
        reinterpret_cast<const unsigned char*>(privateKey_.c_str()), privateKey_.length() + 1,
        nullptr, 0) : -1;
    const bool reuseKey = keyResult == 0 && mbedtls_pk_can_do(&key, MBEDTLS_PK_ECDSA) &&
        mbedtls_pk_ec(key)->grp.id == MBEDTLS_ECP_DP_SECP256R1 &&
        mbedtls_ecp_check_privkey(&mbedtls_pk_ec(key)->grp, &mbedtls_pk_ec(key)->d) == 0 &&
        mbedtls_pk_check_pair(&key, &key) == 0;

    auto certificateValid = [&](const char* pem, size_t length) {
        mbedtls_x509_crt storedCert;
        mbedtls_x509_crt_init(&storedCert);
        const int certResult = mbedtls_x509_crt_parse(&storedCert,
            reinterpret_cast<const unsigned char*>(pem), length + 1);
        const int pairResult = certResult == 0 ? mbedtls_pk_check_pair(&storedCert.pk, &key) : -1;
        tls::CertificateNames names(kServiceDnsName);
        if (certResult == 0) {
            // The installed mbedTLS parser retains raw DNS and IP SAN entries.
            for (const auto* san = &storedCert.subject_alt_names; san; san = san->next)
                names.add(san->buf.tag, san->buf.p, san->buf.len);
        }
        unsigned char digest[32]{};
        const int requiredExtensions = MBEDTLS_X509_EXT_SUBJECT_ALT_NAME |
            MBEDTLS_X509_EXT_BASIC_CONSTRAINTS | MBEDTLS_X509_EXT_KEY_USAGE |
            MBEDTLS_X509_EXT_EXTENDED_KEY_USAGE;
        const bool valid = certResult == 0 && pairResult == 0 && names.complete() &&
            storedCert.version == 3 && !storedCert.ca_istrue &&
            (storedCert.ext_types & requiredExtensions) == requiredExtensions &&
            mbedtls_x509_crt_check_key_usage(&storedCert, MBEDTLS_X509_KU_DIGITAL_SIGNATURE) == 0 &&
            mbedtls_x509_crt_check_extended_key_usage(&storedCert, MBEDTLS_OID_SERVER_AUTH,
                sizeof(MBEDTLS_OID_SERVER_AUTH) - 1) == 0 &&
            storedCert.sig_md == MBEDTLS_MD_SHA256 && storedCert.sig_pk == MBEDTLS_PK_ECDSA &&
            mbedtls_sha256_ret(storedCert.tbs.p, storedCert.tbs.len, digest, 0) == 0 &&
            mbedtls_pk_verify(&storedCert.pk, MBEDTLS_MD_SHA256, digest, sizeof(digest),
                storedCert.sig.p, storedCert.sig.len) == 0;
        mbedtls_x509_crt_free(&storedCert);
        return valid;
    };
    if (settings_->hasCurrentCertificate() && reuseKey && certificate_.length() > 100 &&
        certificateValid(certificate_.c_str(), certificate_.length())) {
        mbedtls_pk_free(&key);
        return true;
    }

    mbedtls_x509write_cert cert;
    mbedtls_mpi serial;
    mbedtls_x509write_crt_init(&cert);
    mbedtls_mpi_init(&serial);
    char certificatePem[1800]{};
    char keyPem[900]{};
    bool ok = reuseKey;
    if (!reuseKey) {
        mbedtls_pk_free(&key);
        mbedtls_pk_init(&key);
        ok = mbedtls_pk_setup(&key, mbedtls_pk_info_from_type(MBEDTLS_PK_ECKEY)) == 0 &&
            mbedtls_ecp_gen_key(MBEDTLS_ECP_DP_SECP256R1,
                mbedtls_pk_ec(key), hardwareRandom, nullptr) == 0;
    }
    unsigned char serialBytes[16];
    esp_fill_random(serialBytes, sizeof(serialBytes));
    serialBytes[0] = (serialBytes[0] & 0x7f) | 1;
    if (ok) ok = mbedtls_mpi_read_binary(&serial, serialBytes, sizeof(serialBytes)) == 0;
    const String subject = "CN=" + String(kServiceDnsName);
    if (ok) {
        mbedtls_x509write_crt_set_subject_key(&cert, &key);
        mbedtls_x509write_crt_set_issuer_key(&cert, &key);
        mbedtls_x509write_crt_set_md_alg(&cert, MBEDTLS_MD_SHA256);
        ok = mbedtls_x509write_crt_set_subject_name(&cert, subject.c_str()) == 0 &&
             mbedtls_x509write_crt_set_issuer_name(&cert, subject.c_str()) == 0 &&
             mbedtls_x509write_crt_set_serial(&cert, &serial) == 0 &&
             mbedtls_x509write_crt_set_validity(&cert, "20260101000000", "20351231235959") == 0;
    }
    if (ok) {
        static constexpr auto names = tls::makeSubjectAltNames(kServiceDnsName);
        // ExtendedKeyUsage ::= SEQUENCE { id-kp-serverAuth }
        static const unsigned char serverAuth[] =
            {0x30, 0x0a, 0x06, 0x08, 0x2b, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x01};
        ok = mbedtls_x509write_crt_set_basic_constraints(&cert, 0, -1) == 0 &&
             mbedtls_x509write_crt_set_key_usage(&cert, MBEDTLS_X509_KU_DIGITAL_SIGNATURE) == 0 &&
             mbedtls_x509write_crt_set_extension(&cert, MBEDTLS_OID_SUBJECT_ALT_NAME,
                 sizeof(MBEDTLS_OID_SUBJECT_ALT_NAME) - 1, 0, names.data(), names.size()) == 0 &&
             mbedtls_x509write_crt_set_extension(&cert, MBEDTLS_OID_EXTENDED_KEY_USAGE,
                 sizeof(MBEDTLS_OID_EXTENDED_KEY_USAGE) - 1, 0,
                 serverAuth, sizeof(serverAuth)) == 0;
    }
    if (ok) ok = mbedtls_x509write_crt_pem(&cert,
        reinterpret_cast<unsigned char*>(certificatePem), sizeof(certificatePem), hardwareRandom, nullptr) == 0;
    if (ok && !reuseKey) ok = mbedtls_pk_write_key_pem(&key,
        reinterpret_cast<unsigned char*>(keyPem), sizeof(keyPem)) == 0;
    if (ok) ok = certificateValid(certificatePem, std::strlen(certificatePem));
    if (ok) ok = settings_->saveCertificate(certificatePem, reuseKey ? privateKey_ : String(keyPem));
    if (ok) {
        certificate_ = certificatePem;
        if (!reuseKey) privateKey_ = keyPem;
        Serial.printf("HTTPS certificate renewed for %s and 192.168.4.1 (key %s)\n",
                      kServiceDnsName, reuseKey ? "reused" : "generated");
    }
    mbedtls_platform_zeroize(keyPem, sizeof(keyPem));
    mbedtls_mpi_free(&serial);
    mbedtls_x509write_crt_free(&cert);
    mbedtls_pk_free(&key);
    return ok;
}

bool BridgePortal::start() {
    if (server_) return true;
    httpsTaskReady_.store(false);
    updateServiceWifiLed();
    if (!ensureCertificate()) {
        Serial.println("HTTPS certificate setup failed");
        return false;
    }
    const uint64_t chip = ESP.getEfuseMac();
    char ssid[32];
    snprintf(ssid, sizeof(ssid), "OrionBridge-%06lX",
             static_cast<unsigned long>(chip & 0xffffff));
    if (!WiFi.mode(WIFI_AP)) return false;
    if (!WiFi.softAP(ssid, settings_->apPassword().c_str())) {
        WiFi.mode(WIFI_OFF);
        return false;
    }
    if (!WiFi.softAPsetHostname(kServiceHostname))
        Serial.println("Service AP hostname could not be set");
#if !defined(BATTERYSENTINEL_ORION_R4)
    // SuperMini hardware acceptance required this cap for reliable AP discovery.
    // The driver is started; do not depend on Arduino's asynchronous AP event bit.
    if (esp_wifi_set_max_tx_power(static_cast<int8_t>(WIFI_POWER_8_5dBm)) != ESP_OK) {
        Serial.println("Service Wi-Fi TX power limit failed");
        setServiceWifiLed(false);
        WiFi.softAPdisconnect(true);
        WiFi.mode(WIFI_OFF);
        return false;
    }
    Serial.println("Service Wi-Fi TX power limited to 8.5 dBm (SuperMini)");
#endif
    httpd_ssl_config_t config = HTTPD_SSL_CONFIG_DEFAULT();
    config.cacert_pem = reinterpret_cast<const uint8_t*>(certificate_.c_str());
    config.cacert_len = certificate_.length() + 1;
    config.prvtkey_pem = reinterpret_cast<const uint8_t*>(privateKey_.c_str());
    config.prvtkey_len = privateKey_.length() + 1;
    config.httpd.max_uri_handlers = 28;
    // Let LRU release the previous TLS session before starting a new handshake.
    config.httpd.max_open_sockets = 1;
    config.httpd.lru_purge_enable = true;
    const esp_err_t startResult = httpd_ssl_start(&server_, &config);
    if (startResult != ESP_OK) {
        Serial.printf("Web server start failed: %d\n", startResult);
        setServiceWifiLed(false);
        WiFi.softAPdisconnect(true);
        WiFi.mode(WIFI_OFF);
        return false;
    }
    for (const char* path : {"/", "/setup", "/login", "/logout", "/config", "/aliases", "/forget", "/password", "/recover", "/api/live", "/api/events", "/api/firmware", "/notifications", "/notifications/ack"}) {
        for (httpd_method_t method : {HTTP_GET, HTTP_POST}) {
            httpd_uri_t uri{};
            uri.uri = path;
            uri.method = method;
            uri.handler = dispatch;
            uri.user_ctx = this;
            const esp_err_t registerResult = httpd_register_uri_handler(server_, &uri);
            if (registerResult != ESP_OK) {
                Serial.printf("HTTPS route registration failed: %s %d\n", path, registerResult);
                stop();
                return false;
            }
        }
    }
    const esp_err_t probeResult = httpd_queue_work(server_, serverStarted, &httpsTaskReady_);
    if (probeResult != ESP_OK) {
        Serial.printf("HTTPS task probe failed: %d\n", probeResult);
        stop();
        return false;
    }
    mdnsActive_ = MDNS.begin(kServiceHostname);
    if (mdnsActive_) {
        MDNS.setInstanceName("Battery Sentinel Orion Bridge");
        if (!MDNS.addService("https", "tcp", 443))
            Serial.println("HTTPS service announcement unavailable; mDNS host remains active");
        Serial.printf("Local service address: https://%s/\n", kServiceDnsName);
    } else {
        // begin can fail after allocating the responder. Keep direct IP access
        // working, and free any partially initialized discovery resources.
        MDNS.end();
        Serial.println("mDNS unavailable; use https://192.168.4.1/");
    }
    lastClientMs_ = millis();
    Serial.printf("Service Wi-Fi: %s, https://%s/\n", ssid,
                  WiFi.softAPIP().toString().c_str());
    addEvent("PORTAL", "Service portal opened");
    updateServiceWifiLed();
    return true;
}

void BridgePortal::stop() {
    httpsTaskReady_.store(false);
    updateServiceWifiLed();
    if (!server_) return;
    if (mdnsActive_) {
        MDNS.end();
        mdnsActive_ = false;
    }
    httpd_ssl_stop(server_);
    server_ = nullptr;
    // A queued ready callback may finish while httpd_ssl_stop joins the task.
    httpsTaskReady_.store(false);
    WiFi.softAPdisconnect(true);
    WiFi.mode(WIFI_OFF);
    setServiceWifiLed(false);
    session_.clear();
    csrf_.clear();
    recoveryCsrf_.clear();
    addEvent("PORTAL", "Service portal closed");
}

void BridgePortal::loop() {
    // Keep AP_STOP and loss of the AP address visible even during an OTA upload.
    updateServiceWifiLed();
    const uint32_t now = millis();
    if (otaRestartPending_.load()) {
        if (static_cast<uint32_t>(now - otaRestartStartedMs_) >= 1500 && nmea_->restartReady()) ESP.restart();
        return;
    }
    if (otaInProgress_.load()) return;
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
    const uint64_t atMs = static_cast<uint64_t>(esp_timer_get_time()) / 1000;
    portENTER_CRITICAL(&eventMux_);
    Event& event = events_[(nextSequence_ - 1) % kEventCount];
    event.sequence = nextSequence_++;
    event.atMs = atMs;
    strlcpy(event.type, type, sizeof(event.type));
    strlcpy(event.detail, detail, sizeof(event.detail));
    portEXIT_CRITICAL(&eventMux_);
}

void BridgePortal::scheduleRestart() {
    nmea_->prepareForRestart();
    otaRestartStartedMs_ = millis();
    otaRestartPending_.store(true);
}

esp_err_t BridgePortal::dispatch(httpd_req_t* request) {
    static_cast<BridgePortal*>(request->user_ctx)->handle(request);
    // All portal replies advertise Connection: close. IDF 4.4 keeps the TLS
    // socket alive on ESP_OK even after a complete reply, occupying our only
    // slot as the browser follows a 303 redirect. A non-OK handler result asks
    // IDF to free this transport synchronously after sending the response; it
    // does not change its HTTP status or invalidate the login session.
    return ESP_FAIL;
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
    // Login/setup/message pages need only translation. Avoid transferring the
    // dashboard's configuration and OTA scripts before the user signs in.
    if (body == ui::kDashboardBody) {
        if (httpd_resp_send_chunk(request, ui::kFormController,
                                  strlen(ui::kFormController)) != ESP_OK) return ESP_FAIL;
        if (httpd_resp_send_chunk(request, ui::kOtaController,
                                  strlen(ui::kOtaController)) != ESP_OK) return ESP_FAIL;
        if (httpd_resp_send_chunk(request, ui::kInsightsController,
                                  strlen(ui::kInsightsController)) != ESP_OK) return ESP_FAIL;
    }
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
        else if (nameLength == 13 && strncmp(marker + 2, "RECOVERY_CSRF", 13) == 0)
            replacement = recoveryCsrf_.c_str();
        else if (nameLength == 3 && strncmp(marker + 2, "MAC", 3) == 0) {
            dynamicValue = escape(settings_->mac());
            replacement = dynamicValue.c_str();
        } else if (nameLength == 12 && strncmp(marker + 2, "OUT_INSTANCE", 12) == 0) {
            dynamicValue = String(settings_->outputInstance());
            replacement = dynamicValue.c_str();
        } else if (nameLength == 11 && strncmp(marker + 2, "IN_INSTANCE", 11) == 0) {
            dynamicValue = String(settings_->inputInstance());
            replacement = dynamicValue.c_str();
        } else if (nameLength == 9 && strncmp(marker + 2, "OUT_ALIAS", 9) == 0) {
            dynamicValue = escape(settings_->outputAlias());
            replacement = dynamicValue.c_str();
        } else if (nameLength == 8 && strncmp(marker + 2, "IN_ALIAS", 8) == 0) {
            dynamicValue = escape(settings_->inputAlias());
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

String BridgePortal::body(httpd_req_t* request, size_t maximumLength) {
    if (request->content_len < 0 || request->content_len > maximumLength || maximumLength > 2048) return "";
    char buffer[2049]{};
    int received = 0;
    while (received < request->content_len) {
        const int n = httpd_req_recv(request, buffer + received, request->content_len - received);
        if (n <= 0) return "";
        received += n;
    }
    return String(buffer, received);
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
        if (static_cast<unsigned char>(c) >= 32) result += c;
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
    recoveryCsrf_.clear();
    session_ = randomHex(16);
    csrf_ = randomHex(16);
    sessionLastMs_ = millis();
}

void BridgePortal::endSession(httpd_req_t* request) {
    session_.clear();
    csrf_.clear();
    recoveryCsrf_.clear();
    httpd_resp_set_hdr(request, "Set-Cookie", "session=; Max-Age=0; Secure; HttpOnly; SameSite=Strict; Path=/");
}

esp_err_t BridgePortal::firmwareInfo(httpd_req_t* request) {
    const auto* partition = otaPartition();
    const auto* running = esp_ota_get_running_partition();
    const auto* boot = esp_ota_get_boot_partition();
    const auto* next = esp_ota_get_next_update_partition(running);
    auto partitionName = [](const esp_partition_t* value) -> String {
        return value ? "\"" + jsonEscape(String(value->label)) + "\"" : String("null");
    };
    auto partitionAddress = [](const esp_partition_t* value) -> String {
        return value ? String(value->address) : String("null");
    };
    // Read the descriptor from the running partition. Its ELF hash is patched
    // by esptool, so the compiled descriptor initializer is not the authority.
    esp_app_desc_t description{};
    String runningElfSha256 = "null";
    if (running && esp_ota_get_partition_description(running, &description) == ESP_OK) {
        static const char digits[] = "0123456789abcdef";
        char hash[65]{};
        for (size_t i = 0; i < sizeof(description.app_elf_sha256); ++i) {
            hash[2 * i] = digits[description.app_elf_sha256[i] >> 4];
            hash[2 * i + 1] = digits[description.app_elf_sha256[i] & 0x0f];
        }
        runningElfSha256 = "\"" + String(hash) + "\"";
    }
    const String data = "{\"target\":\"" + String(kBridgeFirmwareTarget) +
        "\",\"version\":\"" + String(kBridgeFirmwareVersion) +
        "\",\"maxSize\":" + String(partition ? partition->size : 0) +
        ",\"available\":" + String(partition ? "true" : "false") +
        ",\"runningPartition\":" + partitionName(running) +
        ",\"runningAddress\":" + partitionAddress(running) +
        ",\"bootPartition\":" + partitionName(boot) +
        ",\"bootAddress\":" + partitionAddress(boot) +
        ",\"nextPartition\":" + partitionName(next) +
        ",\"nextAddress\":" + partitionAddress(next) +
        ",\"uptimeMs\":" + String(millis()) +
        ",\"runningElfSha256\":" + runningElfSha256 + "}";
    send(request, data, "application/json");
    return ESP_OK;
}

esp_err_t BridgePortal::firmwareUpload(httpd_req_t* request) {
    char token[33]{};
    if (csrf_.length() != 32 ||
        httpd_req_get_hdr_value_str(request, "X-CSRF-Token", token, sizeof(token)) != ESP_OK ||
        csrf_ != token)
        return otaResponse(request, "403 Forbidden", "csrf");
    if (otaInProgress_.load()) return otaResponse(request, "409 Conflict", "busy");
    char contentType[40]{};
    if (httpd_req_get_hdr_value_str(request, "Content-Type", contentType, sizeof(contentType)) != ESP_OK ||
        strcmp(contentType, "application/octet-stream") != 0)
        return otaResponse(request, "415 Unsupported Media Type", "content_type");
    const auto* partition = otaPartition();
    if (!partition) return otaResponse(request, "409 Conflict", "partition");
    if (request->content_len < 336 || request->content_len > partition->size)
        return otaResponse(request, "413 Payload Too Large", "size");

    OtaUpload upload(otaInProgress_);
    ota::ImageValidator validator(kBridgeFirmwareTarget, request->content_len);
    if (mbedtls_sha256_starts_ret(&upload.hash, 0) != 0)
        return otaResponse(request, "500 Internal Server Error", "hash");
    const uint32_t started = millis();
    // Bounded streaming buffer: never retain the complete firmware in RAM.
    uint8_t buffer[2048];
    size_t received = 0;
    auto receive = [&](size_t length) {
        size_t offset = 0;
        unsigned timeouts = 0;
        while (offset < length) {
            if (static_cast<uint32_t>(millis() - started) > 5UL * 60UL * 1000UL) return false;
            const int n = httpd_req_recv(request, reinterpret_cast<char*>(buffer + offset), length - offset);
            if (n == HTTPD_SOCK_ERR_TIMEOUT && ++timeouts < 3) continue;
            if (n <= 0) return false;
            timeouts = 0;
            offset += static_cast<size_t>(n);
        }
        received += length;
        return true;
    };
    auto validate = [&](size_t length) -> const char* {
        size_t hashBytes = 0;
        if (!validator.write(buffer, length, hashBytes)) return validator.errorCode();
        if (hashBytes && mbedtls_sha256_update_ret(&upload.hash, buffer, hashBytes) != 0) return "hash";
        return nullptr;
    };

    // Inspect the app descriptor before erasing any flash. Bootloaders, merged
    // images and firmware for another board/product fail this preflight.
    constexpr size_t prefixSize = 24 + 8 + 256;
    if (!receive(prefixSize)) return otaResponse(request, "408 Request Timeout", "receive");
    if (const char* error = validate(prefixSize)) return otaResponse(request, "400 Bad Request", error);
    if (!validator.targetVerified()) return otaResponse(request, "400 Bad Request", "target");
    if (esp_ota_begin(partition, OTA_WITH_SEQUENTIAL_WRITES, &upload.handle) != ESP_OK)
        return otaResponse(request, "500 Internal Server Error", "write");
    upload.open = true;
    if (esp_ota_write(upload.handle, buffer, prefixSize) != ESP_OK)
        return otaResponse(request, "500 Internal Server Error", "write");

    while (received < request->content_len) {
        const size_t length = std::min(sizeof(buffer), request->content_len - received);
        if (!receive(length)) return otaResponse(request, "408 Request Timeout", "receive");
        if (const char* error = validate(length)) return otaResponse(request, "400 Bad Request", error);
        if (esp_ota_write(upload.handle, buffer, length) != ESP_OK)
            return otaResponse(request, "500 Internal Server Error", "write");
        delay(1);
    }
    uint8_t digest[32];
    if (mbedtls_sha256_finish_ret(&upload.hash, digest) != 0)
        return otaResponse(request, "500 Internal Server Error", "hash");
    if (!validator.finish(digest)) return otaResponse(request, "400 Bad Request", validator.errorCode());

    // IDF independently verifies the actual flash contents and chip revision.
    // esp_ota_end releases its handle on both success and failure.
    upload.open = false;
    if (esp_ota_end(upload.handle) != ESP_OK)
        return otaResponse(request, "400 Bad Request", "finalize");
    if (esp_ota_set_boot_partition(partition) != ESP_OK)
        return otaResponse(request, "500 Internal Server Error", "activate");
    addEvent("OTA", "Firmware verified; restarting");
    send(request, "{\"ok\":true,\"rebooting\":true}", "application/json");
    scheduleRestart();
    return ESP_OK;
}

String BridgePortal::eventsJson(uint32_t after) const {
    std::unique_ptr<Event[]> copy(new (std::nothrow) Event[kEventCount]);
    if (!copy) return "[]";
    size_t count = 0;
    portENTER_CRITICAL(&eventMux_);
    const uint32_t end = nextSequence_;
    const uint32_t first = end > kEventCount ? end - kEventCount : 1;
    // A reconnect after reboot may still carry the previous boot's cursor.
    if (after >= end) after = 0;
    for (uint32_t seq = first; seq < end; ++seq)
        if (seq > after) copy[count++] = events_[(seq - 1) % kEventCount];
    portEXIT_CRITICAL(&eventMux_);
    const auto clock = nmea_->clockSnapshot();
    String data;
    data.reserve(count * 150 + 2);
    data = '[';
    for (size_t i = 0; i < count; ++i) {
        const Event& event = copy[i];
        if (i) data += ',';
        char uptime[24], utcText[24];
        snprintf(uptime, sizeof(uptime), "%llu", static_cast<unsigned long long>(event.atMs));
        uint64_t utc = 0;
        const bool dated = clock.utcFor(event.atMs, utc);
        snprintf(utcText, sizeof(utcText), "%llu", static_cast<unsigned long long>(utc));
        data += "{\"seq\":" + String(event.sequence) + ",\"ms\":" + String(uptime) +
            ",\"utcMs\":" + (dated ? String(utcText) : String("null")) +
            ",\"timeQuality\":\"" + (dated ? "estimated" : "uptime") +
            "\",\"type\":\"" + jsonEscape(event.type) + "\",\"detail\":\"" +
            jsonEscape(event.detail) + "\"}";
    }
    data += ']';
    return data;
}

esp_err_t BridgePortal::notificationSettings(httpd_req_t* request, const String& form) {
    insights::Config candidate;
    bool valid = true;
    const auto flag = [&form, &valid](const char* name) {
        const String value = field(form, name);
        if (!value.isEmpty() && value != "1") valid = false;
        return value == "1";
    };
    const auto integer = [&form, &valid](const char* name, uint16_t& output, uint32_t maximum) {
        const String value = field(form, name);
        uint32_t parsed = 0;
        if (!insights::parseUnsigned(value.c_str(), value.length(), maximum, parsed)) valid = false;
        else output = static_cast<uint16_t>(parsed);
    };
    const auto voltage = [&form, &valid](const char* name, uint16_t& output) {
        const String value = field(form, name);
        if (!insights::parseVoltage(value.c_str(), value.length(), output)) valid = false;
    };
    candidate.enabled = flag("enabled");
    candidate.nmeaEnabled = flag("nmea_enabled");
    candidate.dataLossEnabled = flag("data_loss_enabled");
    candidate.chargerErrorEnabled = flag("charger_error_enabled");
    integer("data_loss_delay_s", candidate.dataLossDelayS, 3600);
    integer("repeat_minutes", candidate.repeatMinutes, 1440);
    for (size_t i = 0; i < insights::kChannelCount; ++i) {
        const char* prefix = i == 0 ? "input" : "output";
        auto& channel = candidate.channels[i];
        char name[40];
        snprintf(name, sizeof(name), "%s_low_enabled", prefix); channel.lowEnabled = flag(name);
        snprintf(name, sizeof(name), "%s_high_enabled", prefix); channel.highEnabled = flag(name);
        snprintf(name, sizeof(name), "%s_low_v", prefix); voltage(name, channel.lowCv);
        snprintf(name, sizeof(name), "%s_low_clear_v", prefix); voltage(name, channel.lowClearCv);
        snprintf(name, sizeof(name), "%s_high_v", prefix); voltage(name, channel.highCv);
        snprintf(name, sizeof(name), "%s_high_clear_v", prefix); voltage(name, channel.highClearCv);
        snprintf(name, sizeof(name), "%s_delay_s", prefix); integer(name, channel.delayS, 600);
        snprintf(name, sizeof(name), "%s_clear_s", prefix); integer(name, channel.clearS, 600);
    }
    valid = valid && insights::validConfig(candidate) &&
        (!candidate.nmeaEnabled || NmeaPublisher::alertsSupported());
    if (!valid) {
        httpd_resp_set_status(request, "400 Bad Request");
        return sendPage(request, ui::kMessageBody, "Check notification settings",
                        "Enter valid voltage thresholds and durations. The clear thresholds must be on the safe side of the warning thresholds.");
    }
    if (!diagnostics_->available() || !settings_->setNotifications(candidate)) {
        httpd_resp_set_status(request, "500 Internal Server Error");
        return sendPage(request, ui::kMessageBody, "Could not save notifications",
                        "The notification settings could not be saved. Your previous settings are unchanged.");
    }
    diagnostics_->configure(candidate);
    addEvent("CONFIG", "Notifications saved");
    httpd_resp_set_status(request, "303 See Other");
    httpd_resp_set_hdr(request, "Location", "/#notifications");
    send(request, "Notifications saved", "text/plain");
    return ESP_OK;
}

esp_err_t BridgePortal::notificationAcknowledge(httpd_req_t* request, const String& form) {
    const String slot = field(form, "id"), generation = field(form, "generation");
    uint32_t id = 0, incident = 0;
    if (!insights::parseUnsigned(slot.c_str(), slot.length(), insights::kAlertCount - 1, id) ||
        !insights::parseUnsigned(generation.c_str(), generation.length(), UINT32_MAX, incident) ||
        !diagnostics_->acknowledge(static_cast<uint8_t>(id), incident)) {
        httpd_resp_set_status(request, "409 Conflict");
        return sendPage(request, ui::kMessageBody, "Notification changed",
                        "This notification is no longer active or has changed. Reload the portal.");
    }
    httpd_resp_set_status(request, "303 See Other");
    httpd_resp_set_hdr(request, "Location", "/#notifications");
    send(request, "Notification acknowledged", "text/plain");
    return ESP_OK;
}

esp_err_t BridgePortal::handle(httpd_req_t* request) {
    const String path(request->uri);
    const bool post = request->method == HTTP_POST;
    lastClientMs_ = millis();
    if (otaRestartPending_.load()) return otaResponse(request, "409 Conflict", "busy");
    if (path == "/login" && !post) {
        // A reload/bookmark of the form's POST URL must remain navigable. The
        // canonical page selects setup, sign-in or dashboard from the session.
        httpd_resp_set_status(request, "303 See Other");
        httpd_resp_set_hdr(request, "Location", "/");
        send(request, "Open portal", "text/plain");
        return ESP_OK;
    }
    if (path == "/api/firmware") {
        if (!authenticated(request)) return otaResponse(request, "401 Unauthorized", "auth");
        return post ? firmwareUpload(request) : firmwareInfo(request);
    }
    if (path == "/recover" && settings_->hasAdmin()) {
        if (!post) {
            recoveryCsrf_ = randomHex(16);
            recoveryStartedMs_ = millis();
            return sendPage(request, ui::kRecoveryBody);
        }
        const String form = body(request);
        const bool validRequest = recoveryCsrf_.length() == 32 &&
            field(form, "csrf") == recoveryCsrf_ &&
            static_cast<uint32_t>(millis() - recoveryStartedMs_) <= 5UL * 60UL * 1000UL;
        // Only this explicit request resets the password. Ordinary BOOT holds
        // retain their Wi-Fi reopening/serial credential behavior.
        const auto result = auth::recoverPassword(*settings_, validRequest,
            digitalRead(9) == LOW, field(form, "confirm_reset") == "yes");
        if (result == auth::PasswordUpdateResult::Forbidden) {
            httpd_resp_set_status(request, "403 Forbidden");
            return sendPage(request, ui::kMessageBody, "Confirm password recovery",
                            "Open Forgot password again, confirm the reset, and hold BOOT while submitting.");
        }
        if (result != auth::PasswordUpdateResult::Saved) {
            httpd_resp_set_status(request, "500 Internal Server Error");
            return sendPage(request, ui::kMessageBody, "Could not save password",
                            "The password could not be saved. Your previous password remains valid. Try again.");
        }
        endSession(request);
        addEvent("ADMIN", "Administrator password reset with BOOT");
        return sendPage(request, ui::kAccountMessageBody, "Password reset",
                        "Sign in with your existing username and the recovery password printed in the manual. Then change it in Settings.");
    }
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

    if (path == "/password" && post) {
        // Three 128-byte passwords may expand to 1152 bytes when form-encoded.
        const String form = body(request, 2048);
        const auto result = auth::changeOwnPassword(*settings_, csrfValid(form),
            field(form, "current_password"), field(form, "new_password"),
            field(form, "confirm_password"));
        if (result == auth::PasswordUpdateResult::Forbidden) {
            httpd_resp_set_status(request, "403 Forbidden");
            return sendPage(request, ui::kMessageBody, "Session expired",
                            "Reload the portal and try your change again.");
        }
        if (result == auth::PasswordUpdateResult::InvalidPassword) {
            httpd_resp_set_status(request, "400 Bad Request");
            return sendPage(request, ui::kMessageBody, "Check the new password",
                            "Use 12–128 UTF-8 bytes for the new password and enter it identically in both fields.");
        }
        if (result == auth::PasswordUpdateResult::IncorrectCurrentPassword) {
            httpd_resp_set_status(request, "403 Forbidden");
            return sendPage(request, ui::kMessageBody, "Current password incorrect",
                            "Enter your current administrator password and try again.");
        }
        if (result != auth::PasswordUpdateResult::Saved) {
            httpd_resp_set_status(request, "500 Internal Server Error");
            return sendPage(request, ui::kMessageBody, "Could not save password",
                            "The password could not be saved. Your previous password remains valid. Try again.");
        }
        endSession(request);
        addEvent("ADMIN", "Administrator password changed");
        return sendPage(request, ui::kAccountMessageBody, "Password changed",
                        "Sign in with your new password. All saved data and assignments are unchanged.");
    }

    if (path == "/" && !post) {
        return sendPage(request, ui::kDashboardBody);
    }
    if (path.startsWith("/api/live") && !post) {
        const orion::Telemetry telemetry = receiver_->snapshot(*telemetry_);
        const uint32_t now = millis();
        const bool fresh = telemetry.fresh(now);
        String data = "{\"bootId\":" + String(bootId_) + ",\"outV\":" + numberOrNull(telemetry.outputVoltage, fresh) +
            ",\"outI\":" + numberOrNull(telemetry.outputCurrent, fresh) +
            ",\"inV\":" + numberOrNull(telemetry.inputVoltage, fresh) +
            ",\"inI\":" + numberOrNull(telemetry.inputCurrent, fresh) +
            ",\"outW\":" + (fresh && telemetry.outputVoltage.valid && telemetry.outputCurrent.valid ? String(telemetry.outputVoltage.number * telemetry.outputCurrent.number, 3) : String("null")) +
            ",\"inW\":" + (fresh && telemetry.inputVoltage.valid && telemetry.inputCurrent.valid ? String(telemetry.inputVoltage.number * telemetry.inputCurrent.number, 3) : String("null")) +
            ",\"state\":" + (fresh ? String(telemetry.state) : String("null")) +
            ",\"error\":" + (fresh ? String(telemetry.error) : String("null")) +
            ",\"offReason\":" + (fresh ? String(telemetry.offReason) : String("null")) +
            ",\"rssi\":" + (fresh ? String(telemetry.rssi) : String("null")) +
            ",\"age\":" + (telemetry.received ? String(static_cast<uint32_t>(now - telemetry.receivedAtMs)) : String("null")) +
            ",\"received\":" + String(telemetry.received ? "true" : "false") +
            ",\"fresh\":" + String(fresh ? "true" : "false") +
            ",\"counter\":" + (telemetry.received ? String(telemetry.counter) : String("null")) +
            ",\"status\":\"" + jsonEscape(!settings_->hasOrion() ? "Unconfigured" :
                !fresh && telemetry.received ? "Stale" : receiver_->lastProblem()) +
            "\",\"rx\":" + String(receiver_->receivedFrames()) +
            ",\"rejected\":" + String(receiver_->rejectedFrames()) +
            ",\"dropped\":" + String(receiver_->droppedFrames()) +
            ",\"duplicates\":" + String(receiver_->duplicateFrames()) +
            ",\"orionStartupFailed\":" + String(receiver_->startupFailures()) +
            ",\"orionErrors\":" + String(receiver_->errors()) +
            ",\"tx\":" + String(nmea_->transmitted()) +
            ",\"txFailed\":" + String(nmea_->failed()) +
            ",\"nmeaErrors\":" + String(nmea_->failed()) +
            ",\"nmea\":" + nmea_->monitorJson(settings_->outputInstance(), settings_->inputInstance()) +
            ",\"insights\":" + diagnostics_->insightsJson() +
            ",\"time\":" + nmea_->timeJson() +
            ",\"notifications\":" + diagnostics_->notificationsJson(
                settings_->notificationSettingsValid(), nmea_->deliveryJson(), NmeaPublisher::alertsSupported());
        uint32_t after = 0;
        const int index = path.indexOf("after=");
        if (index >= 0) after = strtoul(path.c_str() + index + 6, nullptr, 10);
        data += ",\"events\":" + eventsJson(after) + "}";
        send(request, data, "application/json");
        return ESP_OK;
    }
    if (path.startsWith("/api/events") && !post) {
        uint32_t after = 0;
        const int index = path.indexOf("after=");
        if (index >= 0) after = strtoul(path.c_str() + index + 6, nullptr, 10);
        const String data = "{\"time\":" + nmea_->timeJson() +
            ",\"events\":" + eventsJson(after) + "}";
        send(request, data, "application/json");
        return ESP_OK;
    }
    if (post) {
        const String form = body(request, path == "/notifications" ? 2048 : path == "/aliases" ? 1024 : 512);
        if (!csrfValid(form)) {
            httpd_resp_set_status(request, "403 Forbidden");
            return sendPage(request, ui::kMessageBody, "Session expired",
                            "Reload the portal and try your change again.");
        }
        if (path == "/notifications") return notificationSettings(request, form);
        if (path == "/notifications/ack") return notificationAcknowledge(request, form);
        if (path == "/aliases") {
            const String input = field(form, "input_alias");
            const String output = field(form, "output_alias");
            orion::Aliases aliases;
            if (!orion::normalizeAliases(input.c_str(), input.length(),
                                         output.c_str(), output.length(), aliases)) {
                httpd_resp_set_status(request, "400 Bad Request");
                return sendPage(request, ui::kMessageBody, "Check channel names",
                                "Enter two different names with 1–32 characters and no control characters.");
            }
            if (!settings_->setAliases(aliases.input, aliases.output)) {
                httpd_resp_set_status(request, "500 Internal Server Error");
                return sendPage(request, ui::kMessageBody, "Could not save channel names",
                                "The names could not be saved. Try again.");
            }
            addEvent("CONFIG", "Channel names saved");
            httpd_resp_set_status(request, "303 See Other");
            httpd_resp_set_hdr(request, "Location", "/");
            send(request, "Channel names saved", "text/plain");
            return ESP_OK;
        }
        if (path == "/logout") {
            endSession(request);
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
            scheduleRestart();
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
            scheduleRestart();
            return ESP_OK;
        }
    }
    httpd_resp_set_status(request, "404 Not Found");
    send(request, "Not found", "text/plain");
    return ESP_OK;
}

} // namespace bs
