#pragma once

#include <cstdint>

namespace bs::tls {

inline constexpr uint8_t kCertificateVersion = 3;
inline constexpr char kCertificateEntry[] = "tls3_cert";
inline constexpr char kPrivateKeyEntry[] = "tls3_key";
inline constexpr char kCertificateVersionEntry[] = "tls_ver";

// Stage the new identity separately from the legacy certificate/key. The
// version marker is the commit point, so an interrupted V2 migration keeps
// the complete old identity available. Legacy entries are never overwritten.
template <class Store, class Text>
bool saveCertificate(Store& store, const Text& certificate, const Text& privateKey) {
    if (!certificate.length() || !privateKey.length()) return false;
    if (store.putString(kPrivateKeyEntry, privateKey) != privateKey.length()) return false;
    if (store.putString(kCertificateEntry, certificate) != certificate.length()) return false;
    return store.putUChar(kCertificateVersionEntry, kCertificateVersion) == 1;
}

} // namespace bs::tls
