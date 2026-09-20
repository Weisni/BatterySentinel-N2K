#pragma once

#include <Arduino.h>
#include <Preferences.h>

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
    const uint8_t* key() const { return key_; }

    bool setAdmin(const String& username, const String& password);
    bool checkAdmin(const String& username, const String& password) const;
    bool setOrion(const String& mac, const String& keyHex, uint8_t outputInstance, uint8_t inputInstance);
    bool forgetOrion();
    String certificate() { return prefs_.isKey("tls_cert") ? prefs_.getString("tls_cert", "") : ""; }
    String privateKey() { return prefs_.isKey("tls_key") ? prefs_.getString("tls_key", "") : ""; }
    bool hasCurrentCertificate() { return prefs_.getUChar("tls_ver", 0) == 2; }
    bool saveCertificate(const String& certificate, const String& privateKey);

private:
    Preferences prefs_;
    String username_;
    String mac_;
    String apPassword_;
    uint8_t key_[16]{};
    uint8_t salt_[16]{};
    uint8_t hash_[32]{};
    bool keyPresent_ = false;
    uint8_t outputInstance_ = 0;
    uint8_t inputInstance_ = 1;
};

} // namespace bs
