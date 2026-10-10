#pragma once

// Test-only helper. Include explicitly in a temporary hardware diagnostic and
// supply public test inputs. It never reads/writes NVS or prints credentials.
// Do not call from the production boot or login path.
#include <BridgePasswordHashMbedTls.h>
#include <esp_timer.h>
#include <mbedtls/md.h>
#include <mbedtls/pkcs5.h>

namespace bs::auth::test {

struct HardwareComparison {
    bool referenceOk = false;
    bool optimizedOk = false;
    bool equal = false;
    int64_t referenceMicroseconds = 0;
    int64_t optimizedMicroseconds = 0;
};

inline HardwareComparison comparePasswordHashOnDevice(
    const uint8_t* password, size_t passwordLength, const uint8_t salt[kSaltBytes],
    uint32_t iterations = kPasswordIterations) {
    HardwareComparison result;
    if (!salt || (!password && passwordLength) ||
        passwordLength > kPasswordBytes || !iterations) return result;
    uint8_t reference[kHashBytes]{}, optimized[kHashBytes]{};
    mbedtls_md_context_t context;
    mbedtls_md_init(&context);
    const auto* md = mbedtls_md_info_from_type(MBEDTLS_MD_SHA256);
    int64_t started = esp_timer_get_time();
    result.referenceOk = md && mbedtls_md_setup(&context, md, 1) == 0 &&
        mbedtls_pkcs5_pbkdf2_hmac(&context, password, passwordLength,
            salt, kSaltBytes, iterations, kHashBytes, reference) == 0;
    mbedtls_md_free(&context);
    result.referenceMicroseconds = esp_timer_get_time() - started;

    started = esp_timer_get_time();
    result.optimizedOk = passwordHash<MbedTlsSha256>(password, passwordLength,
        salt, iterations, optimized);
    result.optimizedMicroseconds = esp_timer_get_time() - started;
    uint8_t difference = 0;
    for (size_t i = 0; i < kHashBytes; ++i) difference |= reference[i] ^ optimized[i];
    result.equal = result.referenceOk && result.optimizedOk && difference == 0;
    secureClear(reference, sizeof(reference));
    secureClear(optimized, sizeof(optimized));
    return result;
}

} // namespace bs::auth::test
