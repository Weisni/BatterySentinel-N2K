#pragma once

#include "BridgePasswordHash.h"
#include <mbedtls/sha256.h>

namespace bs::auth {

// Use the SDK's SHA implementation, including its hardware synchronization.
// Public clone preserves the complete resumable state on ESP32-C3. No SHA
// registers, shared locks, or cryptographic compression are implemented here.
class MbedTlsSha256 {
public:
    MbedTlsSha256() { mbedtls_sha256_init(&context_); }
    ~MbedTlsSha256() { mbedtls_sha256_free(&context_); }
    MbedTlsSha256(const MbedTlsSha256&) = delete;
    MbedTlsSha256& operator=(const MbedTlsSha256&) = delete;

    bool start() { return mbedtls_sha256_starts_ret(&context_, 0) == 0; }
    bool update(const uint8_t* input, size_t length) {
        return mbedtls_sha256_update_ret(&context_, input, length) == 0;
    }
    bool finish(uint8_t output[kHashBytes]) {
        return mbedtls_sha256_finish_ret(&context_, output) == 0;
    }
    bool clone(const MbedTlsSha256& source) {
        mbedtls_sha256_clone(&context_, &source.context_);
        return true;
    }

private:
    mbedtls_sha256_context context_;
};

} // namespace bs::auth
