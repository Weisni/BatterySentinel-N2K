#include "BridgeSettings.h"
#include <HWCDC.h>

#include <esp_system.h>
#include <mbedtls/md.h>
#include <mbedtls/pkcs5.h>
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

bool validMac(const String& mac) {
    if (mac.length() != 17) return false;
    for (int i = 0; i < 17; ++i) {
        if (i % 3 == 2 ? mac[i] != ':' : hexDigit(mac[i]) < 0) return false;
    }
    return true;
}

bool passwordHash(const String& password, const uint8_t salt[16], uint8_t out[32]) {
    const mbedtls_md_info_t* md = mbedtls_md_info_from_type(MBEDTLS_MD_SHA256);
    if (!md) return false;
    mbedtls_md_context_t context;
    mbedtls_md_init(&context);
    bool ok = mbedtls_md_setup(&context, md, 1) == 0;
    if (ok) ok = mbedtls_pkcs5_pbkdf2_hmac(&context,
        reinterpret_cast<const unsigned char*>(password.c_str()), password.length(),
        salt, 16, 120000, 32, out) == 0;
    mbedtls_md_free(&context);
    return ok;
}

} // namespace

bool BridgeSettings::begin() {
    if (!prefs_.begin("orion-bridge", false)) return false;
    username_ = prefs_.isKey("username") ? prefs_.getString("username", "") : "";
    mac_ = prefs_.isKey("orion_mac") ? prefs_.getString("orion_mac", "") : "";
    mac_.toLowerCase();
    outputInstance_ = prefs_.getUChar("n2k_out", 0);
    inputInstance_ = prefs_.getUChar("n2k_in", 1);
    keyPresent_ = prefs_.isKey("orion_key") &&
                  prefs_.getBytesLength("orion_key") == sizeof(key_);
    if (keyPresent_) prefs_.getBytes("orion_key", key_, sizeof(key_));
    const bool saltPresent = prefs_.isKey("pw_salt") &&
                             prefs_.getBytesLength("pw_salt") == sizeof(salt_);
    const bool hashPresent = prefs_.isKey("pw_hash") &&
                             prefs_.getBytesLength("pw_hash") == sizeof(hash_);
    if (saltPresent)
        prefs_.getBytes("pw_salt", salt_, sizeof(salt_));
    if (hashPresent)
        prefs_.getBytes("pw_hash", hash_, sizeof(hash_));
    if (!saltPresent || !hashPresent) username_.clear();

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
    uint8_t salt[16], hash[32];
    esp_fill_random(salt, sizeof(salt));
    if (!passwordHash(password, salt, hash)) return false;
    if (prefs_.putBytes("pw_salt", salt, sizeof(salt)) != sizeof(salt)) return false;
    if (prefs_.putBytes("pw_hash", hash, sizeof(hash)) != sizeof(hash)) return false;
    if (prefs_.putString("username", username) == 0) return false;
    username_ = username;
    std::memcpy(salt_, salt, sizeof(salt_));
    std::memcpy(hash_, hash, sizeof(hash_));
    return true;
}

bool BridgeSettings::checkAdmin(const String& username, const String& password) const {
    if (!hasAdmin() || username != username_ || password.length() > 128) return false;
    uint8_t calculated[32]{};
    if (!passwordHash(password, salt_, calculated)) return false;
    uint8_t difference = 0;
    for (size_t i = 0; i < sizeof(hash_); ++i) difference |= hash_[i] ^ calculated[i];
    return difference == 0;
}

bool BridgeSettings::setOrion(const String& mac, const String& keyHex,
                              uint8_t outputInstance, uint8_t inputInstance) {
    uint8_t parsedKey[16];
    if (!validMac(mac) || !decodeHex(keyHex, parsedKey, sizeof(parsedKey)) ||
        outputInstance == inputInstance || outputInstance > 252 || inputInstance > 252) return false;
    String normalized = mac;
    normalized.toLowerCase();
    if (prefs_.putBytes("orion_key", parsedKey, sizeof(parsedKey)) != sizeof(parsedKey)) return false;
    if (prefs_.putString("orion_mac", normalized) == 0) return false;
    if (prefs_.putUChar("n2k_out", outputInstance) == 0) return false;
    if (prefs_.putUChar("n2k_in", inputInstance) == 0) return false;
    mac_ = normalized;
    std::memcpy(key_, parsedKey, sizeof(key_));
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

bool BridgeSettings::saveCertificate(const String& certificate, const String& privateKey) {
    return prefs_.putString("tls_cert", certificate) > 0 &&
           prefs_.putString("tls_key", privateKey) > 0 &&
           prefs_.putUChar("tls_ver", 2) == 1;
}

} // namespace bs
