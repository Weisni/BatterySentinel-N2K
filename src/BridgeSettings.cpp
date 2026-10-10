#include "BridgeSettings.h"
#include <BridgePasswordHashMbedTls.h>
#include <BridgeCredentialStore.h>
#include <OrionMac.h>
#include <BridgeNotificationStore.h>
#include <HWCDC.h>

#include <esp_system.h>
#include <cstring>

namespace bs {
namespace {

int hexDigit(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

bool decodeHex(const String& hex, uint8_t* out, size_t length) {
    if (hex.length() != length * 2) return false;
    for (size_t i = 0; i < length; ++i) {
        const int hi = hexDigit(hex[2 * i]);
        const int lo = hexDigit(hex[2 * i + 1]);
        if (hi < 0 || lo < 0) return false;
        out[i] = static_cast<uint8_t>((hi << 4) | lo);
    }
    return true;
}

bool passwordHash(const String& password, const uint8_t salt[16], uint8_t out[32]) {
    return auth::passwordHash<auth::MbedTlsSha256>(
        reinterpret_cast<const uint8_t*>(password.c_str()), password.length(),
        salt, auth::kPasswordIterations, out);
}

} // namespace

bool BridgeSettings::begin() {
    if (!prefs_.begin("orion-bridge", false)) return false;
    username_ = prefs_.isKey("username") ? prefs_.getString("username", "") : "";
    mac_ = prefs_.isKey("orion_mac") ? prefs_.getString("orion_mac", "") : "";
    mac_.toLowerCase();
    outputInstance_ = prefs_.getUChar("n2k_out", 0);
    inputInstance_ = prefs_.getUChar("n2k_in", 1);
    notifications_ = insights::Config{};
    notificationSettingsValid_ =
        insights::loadNotifications(prefs_, notifications_) != insights::LoadResult::Invalid;
    // Both aliases share one NVS entry, so a failed write cannot persist only
    // one side. Missing/invalid legacy data keeps the distinct defaults.
    inputAlias_ = orion::kDefaultInputAlias;
    outputAlias_ = orion::kDefaultOutputAlias;
    if (prefs_.isKey("orion_aliases")) {
        const String stored = prefs_.getString("orion_aliases", "");
        const int separator = stored.indexOf('\n');
        orion::Aliases aliases;
        if (separator >= 0 && orion::normalizeAliases(
                stored.c_str(), separator,
                stored.c_str() + separator + 1, stored.length() - separator - 1, aliases)) {
            inputAlias_ = aliases.input;
            outputAlias_ = aliases.output;
        }
    }
    keyPresent_ = prefs_.isKey("orion_key") &&
                  prefs_.getBytesLength("orion_key") == sizeof(key_);
    if (keyPresent_) prefs_.getBytes("orion_key", key_, sizeof(key_));
    const auto credentialFormat = auth::loadCredential(prefs_, salt_, hash_);
    credentialsPresent_ = credentialFormat == auth::CredentialFormat::Legacy ||
                          credentialFormat == auth::CredentialFormat::Current;
    // Keep an existing username when the current blob is corrupt. This closes
    // first-time setup and requires physical recovery instead of silently
    // restoring a superseded legacy password.
    if (credentialFormat == auth::CredentialFormat::Missing) username_.clear();

    apPassword_ = prefs_.isKey("ap_pass") ? prefs_.getString("ap_pass", "") : "";
    const bool firstAccessPoint = apPassword_.length() < 16;
    if (firstAccessPoint) {
        static const char alphabet[] = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        apPassword_.clear();
        for (int i = 0; i < 20; ++i) apPassword_ += alphabet[esp_random() % (sizeof(alphabet) - 1)];
        if (prefs_.putString("ap_pass", apPassword_) == 0) return false;
    }
    // BOOT is a physical recovery channel for prototype boards with no label.
    // Before an administrator exists, serial is the local recovery channel.
    if (firstAccessPoint || !hasAdmin())
        Serial.printf("Service AP password: %s\n", apPassword_.c_str());
    return true;
}

bool BridgeSettings::setAdmin(const String& username, const String& password) {
    if (username.length() < 3 || username.length() > 32 ||
        password.length() < 12 || password.length() > 128) return false;
    for (size_t i = 0; i < username.length(); ++i) {
        const char c = username[i];
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
              (c >= '0' && c <= '9') || c == '_' || c == '-')) return false;
    }
    // Administrator setup does not rename an existing account. Password-only
    // updates preserve its username and all device configuration.
    if (hasAdmin()) return username == username_ && changePassword(password);
    uint8_t salt[16], hash[32]{};
    esp_fill_random(salt, sizeof(salt));
    const bool saved = passwordHash(password, salt, hash) &&
                       auth::saveInitialAdministrator(prefs_, username, salt, hash);
    if (saved) {
        username_ = username;
        std::memcpy(salt_, salt, sizeof(salt_));
        std::memcpy(hash_, hash, sizeof(hash_));
        credentialsPresent_ = true;
    }
    auth::secureClear(salt, sizeof(salt));
    auth::secureClear(hash, sizeof(hash));
    return saved;
}

bool BridgeSettings::changePassword(const String& password) {
    if (!hasAdmin() || password.length() < 12 || password.length() > 128) return false;
    uint8_t salt[16], hash[32]{};
    esp_fill_random(salt, sizeof(salt));
    const bool saved = passwordHash(password, salt, hash) && auth::saveCredential(prefs_, salt, hash);
    // Runtime credentials change only after the complete blob is persisted.
    if (saved) {
        std::memcpy(salt_, salt, sizeof(salt_));
        std::memcpy(hash_, hash, sizeof(hash_));
        credentialsPresent_ = true;
    }
    auth::secureClear(salt, sizeof(salt));
    auth::secureClear(hash, sizeof(hash));
    return saved;
}

bool BridgeSettings::checkAdmin(const String& username, const String& password) const {
    if (!hasAdmin() || !credentialsPresent_ || username != username_ || password.length() > 128) return false;
    uint8_t calculated[32]{};
    if (!passwordHash(password, salt_, calculated)) return false;
    uint8_t difference = 0;
    for (size_t i = 0; i < sizeof(hash_); ++i) difference |= hash_[i] ^ calculated[i];
    auth::secureClear(calculated, sizeof(calculated));
    return difference == 0;
}

bool BridgeSettings::setOrion(const String& mac, const String& keyHex,
                              uint8_t outputInstance, uint8_t inputInstance) {
    uint8_t parsedKey[16]{};
    char normalized[18];
    if (!orion::normalizeMac(mac.c_str(), mac.length(), normalized) ||
        outputInstance == inputInstance || outputInstance > 252 || inputInstance > 252) return false;
    // The portal displays a placeholder, never the stored key. An empty input
    // can retain that key only for the same device; a changed MAC needs a key.
    const bool keepKey = keyHex.isEmpty() && hasOrion() && mac_ == normalized;
    if (!keepKey && !decodeHex(keyHex, parsedKey, sizeof(parsedKey))) return false;
    if (!keepKey && prefs_.putBytes("orion_key", parsedKey, sizeof(parsedKey)) != sizeof(parsedKey)) return false;
    if (prefs_.putString("orion_mac", normalized) == 0) return false;
    if (prefs_.putUChar("n2k_out", outputInstance) == 0) return false;
    if (prefs_.putUChar("n2k_in", inputInstance) == 0) return false;
    mac_ = normalized;
    if (!keepKey) std::memcpy(key_, parsedKey, sizeof(key_));
    keyPresent_ = true;
    outputInstance_ = outputInstance;
    inputInstance_ = inputInstance;
    return true;
}

bool BridgeSettings::forgetOrion() {
    const bool ok = prefs_.remove("orion_key") && prefs_.remove("orion_mac");
    if (ok) {
        std::memset(key_, 0, sizeof(key_));
        keyPresent_ = false;
        mac_.clear();
    }
    return ok;
}

bool BridgeSettings::setAliases(const String& input, const String& output) {
    orion::Aliases aliases;
    if (!orion::normalizeAliases(input.c_str(), input.length(),
                                 output.c_str(), output.length(), aliases)) return false;
    const String stored = String(aliases.input) + '\n' + aliases.output;
    const size_t expectedLength = std::strlen(aliases.input) + 1 + std::strlen(aliases.output);
    if (stored.length() != expectedLength ||
        prefs_.putString("orion_aliases", stored) != expectedLength) return false;
    inputAlias_ = aliases.input;
    outputAlias_ = aliases.output;
    return true;
}

bool BridgeSettings::saveCertificate(const String& certificate, const String& privateKey) {
    return tls::saveCertificate(prefs_, certificate, privateKey);
}

bool BridgeSettings::setNotifications(const insights::Config& value) {
    if (!insights::saveNotifications(prefs_, value)) return false;
    notifications_ = value;
    notificationSettingsValid_ = true;
    return true;
}

} // namespace bs
