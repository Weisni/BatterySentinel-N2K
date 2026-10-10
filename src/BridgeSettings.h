#pragma once

#include <Arduino.h>
#include <Preferences.h>
#include <OrionAliases.h>
#include <BridgeCertificateStore.h>
#include <BridgeInsights.h>

namespace bs {

class BridgeSettings {
public:
    bool begin();
    bool hasAdmin() const { return username_.length() != 0; }
    bool hasOrion() const { return mac_.length() == 17 && keyPresent_; }
    const String& username() const { return username_; }
    const String& mac() const { return mac_; }
    const String& apPassword() const { return apPassword_; }
    uint8_t outputInstance() const { return outputInstance_; }
    uint8_t inputInstance() const { return inputInstance_; }
    const String& inputAlias() const { return inputAlias_; }
    const String& outputAlias() const { return outputAlias_; }
    const uint8_t* key() const { return key_; }

    bool setAdmin(const String& username, const String& password);
    bool changePassword(const String& password);
    bool checkAdmin(const String& username, const String& password) const;
    bool setOrion(const String& mac, const String& keyHex, uint8_t outputInstance, uint8_t inputInstance);
    bool setAliases(const String& input, const String& output);
    bool forgetOrion();
    const insights::Config& notifications() const { return notifications_; }
    bool notificationSettingsValid() const { return notificationSettingsValid_; }
    bool setNotifications(const insights::Config& value);
    String certificate() {
        const char* entry = hasCurrentCertificate() ? tls::kCertificateEntry : "tls_cert";
        return prefs_.isKey(entry) ? prefs_.getString(entry, "") : "";
    }
    String privateKey() {
        const char* entry = hasCurrentCertificate() ? tls::kPrivateKeyEntry : "tls_key";
        // Keep recovery able to reuse the legacy key if a V3 key entry is missing.
        if (!prefs_.isKey(entry)) entry = "tls_key";
        return prefs_.isKey(entry) ? prefs_.getString(entry, "") : "";
    }
    bool hasCurrentCertificate() {
        return prefs_.getUChar(tls::kCertificateVersionEntry, 0) == tls::kCertificateVersion;
    }
    bool saveCertificate(const String& certificate, const String& privateKey);

private:
    Preferences prefs_;
    String username_;
    String mac_;
    String apPassword_;
    String inputAlias_ = orion::kDefaultInputAlias;
    String outputAlias_ = orion::kDefaultOutputAlias;
    uint8_t key_[16]{};
    uint8_t salt_[16]{};
    uint8_t hash_[32]{};
    bool credentialsPresent_ = false;
    bool keyPresent_ = false;
    uint8_t outputInstance_ = 0;
    uint8_t inputInstance_ = 1;
    insights::Config notifications_{};
    bool notificationSettingsValid_ = true;
};

} // namespace bs
