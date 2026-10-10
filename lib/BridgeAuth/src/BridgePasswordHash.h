#pragma once

#include <cstddef>
#include <cstdint>
#include <cstring>

namespace bs::auth {

inline constexpr uint32_t kPasswordIterations = 120000;
inline constexpr size_t kPasswordBytes = 128;
inline constexpr size_t kSaltBytes = 16;
inline constexpr size_t kHashBytes = 32;

// Volatile stores keep secret cleanup from being removed by optimization.
inline void secureClear(void* memory, size_t length) {
    volatile uint8_t* bytes = static_cast<volatile uint8_t*>(memory);
    if (bytes) while (length--) *bytes++ = 0;
}

// PBKDF2-HMAC-SHA256 for the existing administrator credential format: a
// 16-byte salt and one 32-byte output block. Sha256 supplies start, update,
// finish and clone operations returning bool; its destructor clears its state.
// Its update operation must consume/copy its input before returning, as HMAC
// reuses the intermediate digest buffer after update completes.
template <class Sha256>
bool passwordHash(const uint8_t* password, size_t passwordLength,
                  const uint8_t* salt, uint32_t iterations, uint8_t* output) {
    struct OutputGuard {
        uint8_t* bytes;
        bool complete = false;
        ~OutputGuard() { if (!complete) secureClear(bytes, kHashBytes); }
    } outputGuard{output};
    if (!output || !salt || (!password && passwordLength) ||
        passwordLength > kPasswordBytes || !iterations) return false;

    struct Scratch {
        uint8_t pad[64]{};
        uint8_t digest[kHashBytes]{};
        uint8_t result[kHashBytes]{};
        ~Scratch() { secureClear(this, sizeof(*this)); }
    } scratch;
    Sha256 inner, outer, working;

    // HMAC hashes keys strictly longer than its 64-byte block size first.
    if (passwordLength > sizeof(scratch.pad)) {
        if (!working.start() || !working.update(password, passwordLength) ||
            !working.finish(scratch.digest)) return false;
        password = scratch.digest;
        passwordLength = kHashBytes;
    }

    std::memset(scratch.pad, 0x36, sizeof(scratch.pad));
    for (size_t i = 0; i < passwordLength; ++i) scratch.pad[i] ^= password[i];
    if (!inner.start() || !inner.update(scratch.pad, sizeof(scratch.pad))) return false;
    for (uint8_t& byte : scratch.pad) byte ^= 0x36 ^ 0x5c;
    if (!outer.start() || !outer.update(scratch.pad, sizeof(scratch.pad))) return false;

    // Cache both keyed SHA states once. Each following HMAC needs only its
    // message/finalization blocks, without rehashing the identical key pads.
    auto hmac = [&](const uint8_t* message, size_t length) {
        return working.clone(inner) && working.update(message, length) &&
            working.finish(scratch.digest) && working.clone(outer) &&
            working.update(scratch.digest, kHashBytes) &&
            working.finish(scratch.digest);
    };

    std::memcpy(scratch.pad, salt, kSaltBytes);
    scratch.pad[kSaltBytes] = 0;
    scratch.pad[kSaltBytes + 1] = 0;
    scratch.pad[kSaltBytes + 2] = 0;
    scratch.pad[kSaltBytes + 3] = 1;
    if (!hmac(scratch.pad, kSaltBytes + 4)) return false;
    std::memcpy(scratch.result, scratch.digest, kHashBytes);

    // U1 is included above; the loop supplies exactly iterations - 1 further
    // PRF evaluations. Neither the round count nor stored format is reduced.
    for (uint32_t round = 1; round < iterations; ++round) {
        if (!hmac(scratch.digest, kHashBytes)) return false;
        for (size_t i = 0; i < kHashBytes; ++i) scratch.result[i] ^= scratch.digest[i];
    }
    std::memcpy(output, scratch.result, kHashBytes);
    outputGuard.complete = true;
    return true;
}

} // namespace bs::auth
