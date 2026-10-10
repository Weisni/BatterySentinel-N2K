#pragma once

#include <BridgePasswordHash.h>

namespace bs::auth {

inline constexpr char kCredentialEntry[] = "pw_cred_v1";
inline constexpr uint8_t kCredentialVersion = 1;
inline constexpr size_t kCredentialPayloadBytes = 4 + kSaltBytes + kHashBytes;
inline constexpr size_t kCredentialBlobBytes = kCredentialPayloadBytes + 4;

enum class CredentialFormat { Missing, Legacy, Current, InvalidCurrent };

namespace credential_detail {

// NVS already protects blob integrity. This checksum also rejects malformed
// exports and accidental format changes before any stored hash is accepted.
inline uint32_t checksum(const uint8_t* bytes, size_t length) {
    uint32_t result = 0xffffffffu;
    while (length--) {
        result ^= *bytes++;
        for (unsigned bit = 0; bit < 8; ++bit)
            result = (result >> 1) ^ (0xedb88320u & (0u - (result & 1u)));
    }
    return ~result;
}

struct Blob {
    uint8_t bytes[kCredentialBlobBytes]{};
    ~Blob() { secureClear(bytes, sizeof(bytes)); }
};

} // namespace credential_detail

// A single NVS blob replaces both salt and hash at one commit point. Never
// rewrite legacy entries: a rejected/interrupted write leaves the previous
// complete credential available, including during the first legacy migration.
template <class Store>
bool saveCredential(Store& store, const uint8_t salt[kSaltBytes],
                    const uint8_t hash[kHashBytes]) {
    if (!salt || !hash) return false;
    credential_detail::Blob blob;
    blob.bytes[0] = 'B';
    blob.bytes[1] = 'S';
    blob.bytes[2] = 'P';
    blob.bytes[3] = kCredentialVersion;
    std::memcpy(blob.bytes + 4, salt, kSaltBytes);
    std::memcpy(blob.bytes + 4 + kSaltBytes, hash, kHashBytes);
    const uint32_t checksum = credential_detail::checksum(blob.bytes, kCredentialPayloadBytes);
    for (unsigned i = 0; i < 4; ++i)
        blob.bytes[kCredentialPayloadBytes + i] = static_cast<uint8_t>(checksum >> (8 * i));
    return store.putBytes(kCredentialEntry, blob.bytes, sizeof(blob.bytes)) == sizeof(blob.bytes);
}

// A present but invalid current entry must never reactivate an obsolete legacy
// password. The caller keeps the existing account closed to first-time setup
// and permits repair only through the physical password-recovery workflow.
template <class Store>
CredentialFormat loadCredential(Store& store, uint8_t salt[kSaltBytes],
                                uint8_t hash[kHashBytes]) {
    secureClear(salt, kSaltBytes);
    secureClear(hash, kHashBytes);
    if (!salt || !hash) return CredentialFormat::Missing;
    credential_detail::Blob blob;
    if (store.isKey(kCredentialEntry)) {
        if (store.getBytesLength(kCredentialEntry) != sizeof(blob.bytes) ||
            store.getBytes(kCredentialEntry, blob.bytes, sizeof(blob.bytes)) != sizeof(blob.bytes) ||
            blob.bytes[0] != 'B' || blob.bytes[1] != 'S' || blob.bytes[2] != 'P' ||
            blob.bytes[3] != kCredentialVersion) return CredentialFormat::InvalidCurrent;
        const uint32_t checksum = credential_detail::checksum(blob.bytes, kCredentialPayloadBytes);
        for (unsigned i = 0; i < 4; ++i)
            if (blob.bytes[kCredentialPayloadBytes + i] != static_cast<uint8_t>(checksum >> (8 * i)))
                return CredentialFormat::InvalidCurrent;
        std::memcpy(salt, blob.bytes + 4, kSaltBytes);
        std::memcpy(hash, blob.bytes + 4 + kSaltBytes, kHashBytes);
        return CredentialFormat::Current;
    }
    if (!store.isKey("pw_salt") || !store.isKey("pw_hash") ||
        store.getBytesLength("pw_salt") != kSaltBytes ||
        store.getBytesLength("pw_hash") != kHashBytes ||
        store.getBytes("pw_salt", blob.bytes, kSaltBytes) != kSaltBytes ||
        store.getBytes("pw_hash", blob.bytes + kSaltBytes, kHashBytes) != kHashBytes)
        return CredentialFormat::Missing;
    std::memcpy(salt, blob.bytes, kSaltBytes);
    std::memcpy(hash, blob.bytes + kSaltBytes, kHashBytes);
    return CredentialFormat::Legacy;
}

// Only for an account that does not yet exist. Remove any incomplete legacy
// setup's username before staging credentials; username is the final activation
// point. A failed setup remains retryable without activating an orphaned hash.
template <class Store, class Text>
bool saveInitialAdministrator(Store& store, const Text& username,
                              const uint8_t salt[kSaltBytes], const uint8_t hash[kHashBytes]) {
    if (!username.length() || !salt || !hash) return false;
    if (store.isKey("username") && !store.remove("username")) return false;
    if (!saveCredential(store, salt, hash)) return false;
    return store.putString("username", username) == username.length();
}

} // namespace bs::auth
