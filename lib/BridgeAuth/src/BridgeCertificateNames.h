#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace bs::tls {

inline constexpr std::array<uint8_t, 4> kServiceIpv4{192, 168, 4, 1};

// GeneralNames ::= SEQUENCE { dNSName [2] IA5String, iPAddress [7] OCTET STRING }
// This bounded builder is for the short, fixed service DNS name supplied by
// BridgeNetworkIdentity.h. The terminating C-string NUL is not encoded.
template <size_t N>
constexpr std::array<uint8_t, N + 9> makeSubjectAltNames(const char (&dns)[N]) {
    static_assert(N > 1 && N + 7 < 128, "Service SAN must fit short-form DER lengths");
    std::array<uint8_t, N + 9> result{};
    result[0] = 0x30;
    result[1] = static_cast<uint8_t>(N + 7);
    result[2] = 0x82;
    result[3] = static_cast<uint8_t>(N - 1);
    for (size_t i = 0; i < N - 1; ++i) result[i + 4] = static_cast<uint8_t>(dns[i]);
    result[N + 3] = 0x87;
    result[N + 4] = static_cast<uint8_t>(kServiceIpv4.size());
    for (size_t i = 0; i < kServiceIpv4.size(); ++i) result[N + 5 + i] = kServiceIpv4[i];
    return result;
}

// Consume raw entries from a successfully parsed certificate's SAN extension.
// mbedTLS 2.28.7 retains the raw IP entry even though its higher-level SAN
// decoder reports that type as unsupported. Match tags, lengths and bytes;
// a CN, URI, wildcard or arbitrary certificate substring cannot satisfy this.
class CertificateNames {
public:
    explicit CertificateNames(const char* expectedDns)
        : expectedDns_(expectedDns), dnsLength_(expectedDns ? std::strlen(expectedDns) : 0) {}

    void add(int tag, const uint8_t* bytes, size_t length) {
        if (!bytes) return;
        if (tag == 0x87 && length == kServiceIpv4.size() &&
            std::memcmp(bytes, kServiceIpv4.data(), length) == 0) hasIp_ = true;
        if (tag != 0x82 || !dnsLength_ || length != dnsLength_) return;
        for (size_t i = 0; i < length; ++i) {
            if (asciiLower(bytes[i]) != asciiLower(static_cast<uint8_t>(expectedDns_[i]))) return;
        }
        hasDns_ = true;
    }

    bool complete() const { return hasDns_ && hasIp_; }

private:
    const char* expectedDns_;
    size_t dnsLength_;
    bool hasDns_ = false;
    bool hasIp_ = false;

    static uint8_t asciiLower(uint8_t byte) {
        return byte >= 'A' && byte <= 'Z' ? static_cast<uint8_t>(byte + ('a' - 'A')) : byte;
    }
};

} // namespace bs::tls
