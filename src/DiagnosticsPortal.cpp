#include "DiagnosticsPortal.h"

#include <Update.h>
#include <WiFi.h>

#include "config.h"

namespace bs {

DiagnosticsPortal::DiagnosticsPortal() = default;

void DiagnosticsPortal::begin(DeviceSettings& settings,
                              SettingsStore& store,
                              BatteryCore& systemBattery,
                              BatteryCore& bowBattery) {
    settings_ = &settings;
    store_ = &store;
    systemBattery_ = &systemBattery;
    bowBattery_ = &bowBattery;

    const uint64_t mac = ESP.getEfuseMac();
    char suffix[9];
    snprintf(suffix, sizeof(suffix), "%08lX", static_cast<unsigned long>(mac & 0xFFFFFFFFu));

    ssid_ = "BatterySentinel-" + String(suffix + 4);
    password_ = "BSN2K-" + String(suffix);

    WiFi.mode(WIFI_AP);
    WiFi.setSleep(true);
    if (!WiFi.softAP(ssid_.c_str(), password_.c_str())) {
        Serial.println("Diagnostics AP failed to start");
        active_ = false;
        return;
    }

    configureRoutes();
    server_.begin();
    active_ = true;
    everConnected_ = false;
    startedAtMs_ = millis();
    lastClientSeenMs_ = startedAtMs_;

    Serial.printf("Diagnostics AP: %s\n", ssid_.c_str());
    Serial.printf("Diagnostics password: %s\n", password_.c_str());
    Serial.print("Portal: http://");
    Serial.println(WiFi.softAPIP());
}

void DiagnosticsPortal::loop() {
    if (!active_) return;

    server_.handleClient();

    const uint32_t now = millis();
    const uint8_t stations = WiFi.softAPgetStationNum();
    if (stations > 0) {
        everConnected_ = true;
        lastClientSeenMs_ = now;
        return;
    }

    if (!everConnected_) {
        if (static_cast<uint32_t>(now - startedAtMs_) >= config::DIAG_BOOT_WINDOW_MS) {
            stop();
        }
        return;
    }

    if (static_cast<uint32_t>(now - lastClientSeenMs_) >= config::DIAG_DISCONNECT_GRACE_MS) {
        stop();
    }
}

void DiagnosticsPortal::stop() {
    if (!active_) return;
    server_.stop();
    WiFi.softAPdisconnect(true);
    WiFi.mode(WIFI_OFF);
    active_ = false;
    Serial.println("Diagnostics Wi-Fi disabled");
}

void DiagnosticsPortal::configureRoutes() {
    server_.on("/", HTTP_GET, [this]() { handleRoot(); });
    server_.on("/api/live", HTTP_GET, [this]() { handleLive(); });
    server_.on("/save", HTTP_POST, [this]() { handleSave(); });
    server_.on("/update", HTTP_POST,
               [this]() { handleUpdateFinished(); },
               [this]() { handleUpdateUpload(); });
    server_.onNotFound([this]() { server_.send(404, "text/plain", "Not found"); });
}

void DiagnosticsPortal::handleRoot() {
    const auto& sys = systemBattery_->snapshot();
    const auto& bow = bowBattery_->snapshot();

    String html;
    html.reserve(7000);
    html += F("<!doctype html><html><head><meta name='viewport' content='width=device-width,initial-scale=1'>");
    html += F("<title>BatterySentinel N2K</title><style>body{font-family:system-ui;margin:20px;max-width:900px}"
              "table{border-collapse:collapse;width:100%}td,th{padding:8px;border-bottom:1px solid #ddd;text-align:left}"
              "input,select,button{padding:8px;margin:4px 0;max-width:280px;width:100%}.grid{display:grid;grid-template-columns:1fr 1fr;gap:20px}"
              "@media(max-width:700px){.grid{grid-template-columns:1fr}}.warn{background:#fff4cc;padding:10px;border-radius:6px}</style></head><body>");
    html += F("<h1>BatterySentinel N2K</h1><p>Boot diagnostics / configuration / OTA</p>");
    html += F("<h2>Live</h2><table><tr><th>Bank</th><th>Voltage</th><th>Current</th><th>SOC</th><th>Alerts</th></tr>");

    auto row = [&](const char* name, const BatterySnapshot& s, bool socAllowed) {
        html += "<tr><td>" + String(name) + "</td><td>" + String(s.voltageV, 2) + " V</td><td>" + String(s.currentA, 2) + " A</td><td>";
        html += (socAllowed && s.socInitialized) ? String(s.socPct, 1) + " %" : String("n/a");
        html += "</td><td>0x" + String(s.alerts, HEX) + "</td></tr>";
    };
    row("System", sys, settings_->system.socEnabled);
    row("Bow", bow, settings_->bow.socEnabled && settings_->bowChannelEnabled);
    html += F("</table><p><a href='/api/live'>Live JSON</a></p>");

    html += F("<h2>Configuration</h2><form action='/save' method='post'><div class='grid'><section><h3>System battery</h3>");
    html += F("<label>Type</label><select name='sys_chem'>") + chemistryOptions(settings_->system.chemistry) + F("</select>");
    html += F("<label>Capacity [Ah]</label><input name='sys_cap' type='number' min='1' max='1000' step='0.1' value='") + String(settings_->system.capacityAh, 1) + F("'>");
    html += F("<label>Max current alarm [A]</label><input name='sys_imax' type='number' min='1' max='1500' step='1' value='") + String(settings_->systemMaxCurrentA, 0) + F("'>");
    html += F("<label>Loaded undervoltage [V]</label><input name='sys_uv' type='number' min='6' max='15' step='0.1' value='") + String(settings_->systemLowVoltageLoadedV, 1) + F("'></section>");

    html += F("<section><h3>Second battery</h3><label><input style='width:auto' name='bow_enable' type='checkbox' value='1'");
    if (settings_->bowChannelEnabled) html += F(" checked");
    html += F("> Enable channel</label><br><label>Type</label><select name='bow_chem'>") + chemistryOptions(settings_->bow.chemistry) + F("</select>");
    html += F("<label>Capacity [Ah]</label><input name='bow_cap' type='number' min='0' max='1000' step='0.1' value='") + String(settings_->bow.capacityAh, 1) + F("'>");
    html += F("<label>Max current alarm [A]</label><input name='bow_imax' type='number' min='1' max='1500' step='1' value='") + String(settings_->bowMaxCurrentA, 0) + F("'>");
    html += F("<label>Loaded undervoltage [V]</label><input name='bow_uv' type='number' min='6' max='15' step='0.1' value='") + String(settings_->bowLowVoltageLoadedV, 1) + F("'></section></div>");
    html += F("<p class='warn'>Changing configuration stores it persistently and restarts the controller. Unknown battery type disables SOC but not voltage/current measurement.</p>");
    html += F("<button type='submit'>Save & restart</button></form>");

    html += F("<h2>Firmware OTA</h2><form method='POST' action='/update' enctype='multipart/form-data'>");
    html += F("<input type='file' name='firmware' accept='.bin' required><button type='submit'>Upload firmware</button></form>");
    html += F("<p>Wi-Fi shuts down after 5 minutes if nobody connects. If connected, it remains active until 60 s after the last client disconnects.</p>");
    html += F("<script>setInterval(()=>fetch('/api/live').then(r=>r.json()).then(j=>document.title='BatterySentinel '+j.system.voltage.toFixed(2)+'V').catch(()=>{}),2000)</script>");
    html += F("</body></html>");

    server_.send(200, "text/html; charset=utf-8", html);
}

void DiagnosticsPortal::handleLive() {
    const auto& sys = systemBattery_->snapshot();
    const auto& bow = bowBattery_->snapshot();

    String json = "{\"system\":{";
    json += "\"voltage\":" + String(sys.voltageV, 3);
    json += ",\"current\":" + String(sys.currentA, 3);
    json += ",\"soc\":" + String((settings_->system.socEnabled && sys.socInitialized) ? sys.socPct : -1.0, 2);
    json += ",\"alerts\":" + String(sys.alerts);
    json += "},\"bow\":{";
    json += "\"enabled\":" + String(settings_->bowChannelEnabled ? "true" : "false");
    json += ",\"voltage\":" + String(bow.voltageV, 3);
    json += ",\"current\":" + String(bow.currentA, 3);
    json += ",\"soc\":" + String((settings_->bow.socEnabled && bow.socInitialized) ? bow.socPct : -1.0, 2);
    json += ",\"alerts\":" + String(bow.alerts) + "}}";
    server_.send(200, "application/json", json);
}

void DiagnosticsPortal::handleSave() {
    if (!settings_ || !store_) {
        server_.send(500, "text/plain", "Settings unavailable");
        return;
    }

    const BatteryChemistry sysChem = chemistryFromArg(server_.arg("sys_chem"));
    const BatteryChemistry bowChem = chemistryFromArg(server_.arg("bow_chem"));
    const double sysCapacity = server_.arg("sys_cap").toDouble();
    const double bowCapacity = server_.arg("bow_cap").toDouble();

    if (sysCapacity <= 0.0 || sysCapacity > 1000.0 || bowCapacity < 0.0 || bowCapacity > 1000.0) {
        server_.send(400, "text/plain", "Invalid capacity");
        return;
    }

    settings_->system = makeProfile(sysChem, sysCapacity);
    settings_->bow = makeProfile(bowChem, bowCapacity);
    settings_->bowChannelEnabled = server_.hasArg("bow_enable") && server_.arg("bow_enable") == "1";
    settings_->systemMaxCurrentA = server_.arg("sys_imax").toDouble();
    settings_->bowMaxCurrentA = server_.arg("bow_imax").toDouble();
    settings_->systemLowVoltageLoadedV = server_.arg("sys_uv").toDouble();
    settings_->bowLowVoltageLoadedV = server_.arg("bow_uv").toDouble();

    if (!store_->save(*settings_)) {
        server_.send(500, "text/plain", "Failed to store configuration");
        return;
    }

    server_.send(200, "text/html", "<h1>Saved</h1><p>BatterySentinel is restarting...</p>");
    delay(300);
    ESP.restart();
}

void DiagnosticsPortal::handleUpdateFinished() {
    const bool ok = !Update.hasError();
    server_.send(ok ? 200 : 500, "text/plain", ok ? "OTA complete. Restarting." : "OTA failed.");
    if (ok) {
        delay(300);
        ESP.restart();
    }
}

void DiagnosticsPortal::handleUpdateUpload() {
    HTTPUpload& upload = server_.upload();
    if (upload.status == UPLOAD_FILE_START) {
        Serial.printf("OTA start: %s\n", upload.filename.c_str());
        if (!Update.begin(UPDATE_SIZE_UNKNOWN, U_FLASH)) {
            Update.printError(Serial);
        }
    } else if (upload.status == UPLOAD_FILE_WRITE) {
        if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
            Update.printError(Serial);
        }
    } else if (upload.status == UPLOAD_FILE_END) {
        if (!Update.end(true)) Update.printError(Serial);
        else Serial.printf("OTA success: %u bytes\n", upload.totalSize);
    } else if (upload.status == UPLOAD_FILE_ABORTED) {
        Update.abort();
        Serial.println("OTA aborted");
    }
}

String DiagnosticsPortal::htmlEscape(const String& value) {
    String out = value;
    out.replace("&", "&amp;");
    out.replace("<", "&lt;");
    out.replace(">", "&gt;");
    out.replace("\"", "&quot;");
    out.replace("'", "&#39;");
    return out;
}

String DiagnosticsPortal::chemistryOptions(BatteryChemistry selected) {
    String out;
    for (uint8_t raw = static_cast<uint8_t>(BatteryChemistry::Unknown);
         raw <= static_cast<uint8_t>(BatteryChemistry::Custom); ++raw) {
        const auto chemistry = static_cast<BatteryChemistry>(raw);
        out += "<option value='" + String(raw) + "'";
        if (chemistry == selected) out += " selected";
        out += ">" + htmlEscape(chemistryName(chemistry)) + "</option>";
    }
    return out;
}

BatteryChemistry DiagnosticsPortal::chemistryFromArg(const String& value) {
    const int raw = value.toInt();
    if (raw < static_cast<int>(BatteryChemistry::Unknown) ||
        raw > static_cast<int>(BatteryChemistry::Custom)) {
        return BatteryChemistry::Unknown;
    }
    return static_cast<BatteryChemistry>(raw);
}

} // namespace bs
