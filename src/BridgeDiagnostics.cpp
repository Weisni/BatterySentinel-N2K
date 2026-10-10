#include "BridgeDiagnostics.h"
#include <esp_timer.h>
#include <cmath>
#include <algorithm>
#include <memory>
#include <new>

namespace bs {
namespace {
uint64_t diagnosticNow() { return static_cast<uint64_t>(esp_timer_get_time()) / 1000; }
String integer64(uint64_t value) {
    char text[24];
    snprintf(text, sizeof(text), "%llu", static_cast<unsigned long long>(value));
    return String(text);
}
String boolean(bool value) { return value ? "true" : "false"; }
String finiteNumber(double value, unsigned decimals = 3) {
    return std::isfinite(value) ? String(value, decimals) : String("null");
}
String channelConfigJson(const insights::ChannelConfig& config) {
    return String("{\"lowEnabled\":") + boolean(config.lowEnabled) +
        ",\"highEnabled\":" + boolean(config.highEnabled) +
        ",\"lowV\":" + String(config.lowCv / 100.0, 2) +
        ",\"lowClearV\":" + String(config.lowClearCv / 100.0, 2) +
        ",\"highV\":" + String(config.highCv / 100.0, 2) +
        ",\"highClearV\":" + String(config.highClearCv / 100.0, 2) +
        ",\"delayS\":" + String(config.delayS) +
        ",\"clearS\":" + String(config.clearS) + "}";
}
class Guard {
public:
    explicit Guard(SemaphoreHandle_t mutex) : mutex_(mutex) {
        if (mutex_) xSemaphoreTake(mutex_, portMAX_DELAY);
    }
    ~Guard() { if (mutex_) xSemaphoreGive(mutex_); }
private:
    SemaphoreHandle_t mutex_;
};
}

void BridgeDiagnostics::begin(const insights::Config& config) {
    if (!mutex_) mutex_ = xSemaphoreCreateMutex();
    configure(config);
}

void BridgeDiagnostics::update(const orion::Telemetry& telemetry, bool configured) {
    if (!mutex_) return;
    Guard guard(mutex_);
    engine_.update(telemetry, diagnosticNow(), configured);
}

bool BridgeDiagnostics::configure(const insights::Config& config) {
    if (!mutex_) return false;
    Guard guard(mutex_);
    return engine_.applyConfig(config, diagnosticNow());
}

bool BridgeDiagnostics::acknowledge(uint8_t slot, uint32_t generation) {
    if (!mutex_ || slot >= insights::kAlertCount) return false;
    Guard guard(mutex_);
    const auto alert = engine_.alert(slot);
    if (!alert.active || alert.generation != generation) return false;
    return alert.acknowledged || engine_.acknowledge(slot, diagnosticNow());
}

bool BridgeDiagnostics::popTransition(insights::Transition& transition) {
    if (!mutex_) return false;
    Guard guard(mutex_);
    return engine_.popTransition(transition);
}

void BridgeDiagnostics::snapshot(insights::Snapshot& out) const {
    if (!mutex_) { out = insights::Snapshot{}; return; }
    Guard guard(mutex_);
    engine_.snapshot(diagnosticNow(), out);
}

insights::Config BridgeDiagnostics::config() const {
    if (!mutex_) return insights::Config{};
    Guard guard(mutex_);
    return engine_.config();
}

String BridgeDiagnostics::insightsJson() const {
    if (!mutex_) return "null";
    // Keep the history snapshot off the relatively small HTTPS task stack.
    std::unique_ptr<insights::Snapshot> state(new (std::nothrow) insights::Snapshot);
    if (!state) return "null";
    snapshot(*state);
    const uint64_t now = diagnosticNow();
    String json;
    json.reserve(6000);
    json = "{\"sinceMs\":0,\"nowMs\":" + integer64(now) +
        ",\"maxGapMs\":" + integer64(insights::kMaxSampleGapMs);
    for (size_t channel = 0; channel < insights::kChannelCount; ++channel) {
        const auto& value = state->channels[channel];
        json += channel == 0 ? ",\"input\":{" : ",\"output\":{";
        json += "\"minV\":" + (value.hasExtrema ? finiteNumber(value.minimumVoltage) : String("null")) +
            ",\"maxV\":" + (value.hasExtrema ? finiteNumber(value.maximumVoltage) : String("null")) +
            ",\"trendVPerMin\":" + (value.trendValid ? finiteNumber(value.trendVoltsPerMinute) : String("null")) +
            ",\"trendSpanMs\":" + integer64(value.trendSpanMs) +
            ",\"ah\":" + finiteNumber(value.transferAh) +
            ",\"wh\":" + finiteNumber(value.transferWh) +
            ",\"coveredMs\":" + integer64(value.coveredMs) +
            ",\"transferCoveredMs\":" + integer64(value.transferCoveredMs) +
            ",\"belowLowMs\":" + integer64(value.belowLowMs) +
            ",\"coveragePct\":" + finiteNumber(now ? std::min(100.0, value.coveredMs * 100.0 / now) : 0.0, 1) +
            ",\"fresh\":" + boolean(state->fresh && value.voltageValid) +
            ",\"history\":[";
        for (size_t i = 0; i < value.historySamples; ++i) {
            if (i) json += ',';
            json += "{\"ms\":" + integer64(value.history[i].atMs) +
                ",\"v\":" + finiteNumber(value.history[i].voltage) + "}";
        }
        json += "]}";
    }
    json += '}';
    return json;
}

String BridgeDiagnostics::notificationsJson(bool storageValid, const String& delivery, bool nmeaSupported) const {
    if (!mutex_) return "null";
    std::unique_ptr<insights::Snapshot> state(new (std::nothrow) insights::Snapshot);
    if (!state) return "null";
    insights::Config settings;
    {
        Guard guard(mutex_);
        engine_.snapshot(diagnosticNow(), *state);
        settings = engine_.config();
    }
    String json;
    json.reserve(2500);
    json = "{\"storageValid\":" + boolean(storageValid) +
        ",\"nmeaStatus\":\"" + (nmeaSupported ? "unverified" : "unavailable") + "\",\"delivery\":" + delivery +
        ",\"config\":{\"enabled\":" + boolean(settings.enabled) +
        ",\"nmeaEnabled\":" + boolean(settings.nmeaEnabled) +
        ",\"dataLossEnabled\":" + boolean(settings.dataLossEnabled) +
        ",\"chargerErrorEnabled\":" + boolean(settings.chargerErrorEnabled) +
        ",\"dataLossDelayS\":" + String(settings.dataLossDelayS) +
        ",\"repeatMinutes\":" + String(settings.repeatMinutes) +
        ",\"input\":" + channelConfigJson(settings.channels[0]) +
        ",\"output\":" + channelConfigJson(settings.channels[1]) + "},\"alerts\":[";
    static const char* kinds[] = {"inputLow", "outputLow", "inputHigh", "outputHigh", "dataLoss", "chargerError"};
    for (size_t i = 0; i < insights::kAlertCount; ++i) {
        const auto& alert = state->alerts[i];
        if (i) json += ',';
        json += "{\"id\":" + String(i) + ",\"kind\":\"" + kinds[i] +
            "\",\"enabled\":" + boolean(alert.enabled) + ",\"active\":" + boolean(alert.active) +
            ",\"acknowledged\":" + boolean(alert.acknowledged) + ",\"known\":" + boolean(alert.known) +
            ",\"pending\":" + boolean(alert.pending) + ",\"generation\":" + String(alert.generation) +
            ",\"value\":" + finiteNumber(alert.value) + ",\"activatedAtMs\":" + integer64(alert.activatedAtMs) +
            ",\"changedAtMs\":" + integer64(alert.changedAtMs) + "}";
    }
    json += "]}";
    return json;
}

} // namespace bs
