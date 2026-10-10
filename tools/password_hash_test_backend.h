#pragma once

// Test-only SHA-256 adapter for the production PBKDF2/HMAC template. Windows
// uses its built-in BCrypt; Linux/macOS use the installed OpenSSL runtime.
// Dynamic loading keeps native tests free of crypto linker configuration.
// No SHA implementation or password-hashing logic is duplicated here.
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <limits>

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <bcrypt.h>
#else
#include <dlfcn.h>
// OpenSSL's public opaque types; no headers or implementation are vendored.
struct evp_md_ctx_st;
struct evp_md_st;
struct engine_st;
#endif

namespace password_hash_test {
namespace detail {

inline size_t hashes = 0;

class Api {
public:
#ifdef _WIN32
    HMODULE module = nullptr;
    BCRYPT_ALG_HANDLE provider = nullptr;
    decltype(&BCryptOpenAlgorithmProvider) open = nullptr;
    decltype(&BCryptCloseAlgorithmProvider) close = nullptr;
    decltype(&BCryptCreateHash) create = nullptr;
    decltype(&BCryptDestroyHash) destroy = nullptr;
    decltype(&BCryptDuplicateHash) duplicate = nullptr;
    decltype(&BCryptHashData) update = nullptr;
    decltype(&BCryptFinishHash) finish = nullptr;
#else
    using Context = evp_md_ctx_st;
    using Digest = evp_md_st;
    void* module = nullptr;
    Context* (*create)() = nullptr;
    void (*destroy)(Context*) = nullptr;
    const Digest* (*sha256)() = nullptr;
    int (*start)(Context*, const Digest*, engine_st*) = nullptr;
    int (*duplicate)(Context*, const Context*) = nullptr;
    int (*update)(Context*, const void*, size_t) = nullptr;
    int (*finish)(Context*, unsigned char*, unsigned int*) = nullptr;
#endif
    bool ready = false;

    Api() {
#ifdef _WIN32
        module = LoadLibraryW(L"bcrypt.dll");
        if (!module || !load(open, "BCryptOpenAlgorithmProvider") ||
            !load(close, "BCryptCloseAlgorithmProvider") ||
            !load(create, "BCryptCreateHash") || !load(destroy, "BCryptDestroyHash") ||
            !load(duplicate, "BCryptDuplicateHash") || !load(update, "BCryptHashData") ||
            !load(finish, "BCryptFinishHash")) return;
        ready = open(&provider, BCRYPT_SHA256_ALGORITHM, nullptr, 0) >= 0;
#else
        const char* libraries[] = {"libcrypto.so.3", "libcrypto.so.1.1", "libcrypto.dylib"};
        for (const auto* library : libraries) {
            module = dlopen(library, RTLD_NOW | RTLD_LOCAL);
            if (module) break;
        }
        ready = module && load(create, "EVP_MD_CTX_new") && load(destroy, "EVP_MD_CTX_free") &&
            load(sha256, "EVP_sha256") && load(start, "EVP_DigestInit_ex") &&
            load(duplicate, "EVP_MD_CTX_copy_ex") && load(update, "EVP_DigestUpdate") &&
            load(finish, "EVP_DigestFinal_ex");
#endif
    }

    ~Api() {
#ifdef _WIN32
        if (provider && close) close(provider, 0);
        if (module) FreeLibrary(module);
#else
        if (module) dlclose(module);
#endif
    }
    Api(const Api&) = delete;
    Api& operator=(const Api&) = delete;

private:
    template <typename Function> bool load(Function& target, const char* name) {
#ifdef _WIN32
        const auto symbol = GetProcAddress(module, name);
#else
        const auto symbol = dlsym(module, name);
#endif
        if (!symbol) return false;
        static_assert(sizeof(target) == sizeof(symbol), "System function pointer size mismatch");
        std::memcpy(&target, &symbol, sizeof(target));
        return true;
    }
};

inline Api& api() {
    static Api instance;
    return instance;
}

} // namespace detail

inline bool available() { return detail::api().ready; }
inline size_t liveHashes() { return detail::hashes; }
inline const char* backendError() {
#ifdef _WIN32
    return "Windows BCrypt SHA-256 backend is unavailable; cryptographic tests cannot run.";
#else
    return "OpenSSL libcrypto SHA-256 backend is unavailable; cryptographic tests cannot run.";
#endif
}

class Sha256 {
public:
    Sha256() = default;
    ~Sha256() { clear(); }
    Sha256(const Sha256&) = delete;
    Sha256& operator=(const Sha256&) = delete;

    bool start() {
        clear();
        auto& api = detail::api();
        if (!api.ready) return false;
#ifdef _WIN32
        if (api.create(api.provider, &context_, nullptr, 0, nullptr, 0, 0) < 0) return false;
        ++detail::hashes;
        return true;
#else
        context_ = api.create();
        if (!context_) return false;
        ++detail::hashes;
        if (api.start(context_, api.sha256(), nullptr) == 1) return true;
        clear();
        return false;
#endif
    }

    bool clone(const Sha256& source) {
        if (!source.context_) return false;
        if (this == &source) return true;
        clear();
        auto& api = detail::api();
#ifdef _WIN32
        if (api.duplicate(source.context_, &context_, nullptr, 0, 0) < 0) return false;
        ++detail::hashes;
        return true;
#else
        context_ = api.create();
        if (!context_) return false;
        ++detail::hashes;
        if (api.duplicate(context_, source.context_) == 1) return true;
        clear();
        return false;
#endif
    }

    bool update(const uint8_t* bytes, size_t length) {
        if (!context_ || (!bytes && length)) return false;
        if (!length) return true;
#ifdef _WIN32
        if (length > std::numeric_limits<ULONG>::max()) return false;
        return detail::api().update(context_, const_cast<PUCHAR>(bytes), static_cast<ULONG>(length), 0) >= 0;
#else
        return detail::api().update(context_, bytes, length) == 1;
#endif
    }

    bool finish(uint8_t output[32]) {
        if (!context_ || !output) return false;
#ifdef _WIN32
        return detail::api().finish(context_, output, 32, 0) >= 0;
#else
        unsigned int length = 0;
        return detail::api().finish(context_, output, &length) == 1 && length == 32;
#endif
    }

private:
#ifdef _WIN32
    BCRYPT_HASH_HANDLE context_ = nullptr;
#else
    detail::Api::Context* context_ = nullptr;
#endif

    void clear() {
        if (!context_) return;
        detail::api().destroy(context_);
        context_ = nullptr;
        --detail::hashes;
    }
};

} // namespace password_hash_test
