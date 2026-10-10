#include <unity.h>
#include <BridgePasswordHash.h>
#include "../../tools/password_hash_test_backend.h"

#include <algorithm>
#include <array>
#include <cstring>
#include <string>
#include <vector>

namespace {

using password_hash_test::Sha256;
using Salt = std::array<uint8_t, bs::auth::kSaltBytes>;
using Digest = std::array<uint8_t, bs::auth::kHashBytes>;

Salt sequenceSalt() {
    Salt salt{};
    for (size_t i = 0; i < salt.size(); ++i) salt[i] = static_cast<uint8_t>(i);
    return salt;
}

Digest decodeDigest(const char* hex) {
    Digest result{};
    for (size_t i = 0; i < result.size(); ++i) {
        result[i] = static_cast<uint8_t>(std::stoul(std::string(hex + 2 * i, 2), nullptr, 16));
    }
    return result;
}

void matches(const std::vector<uint8_t>& password, const Salt& salt,
             uint32_t iterations, const char* expectedHex) {
    const auto originalPassword = password;
    const auto originalSalt = salt;
    Digest output{};
    TEST_ASSERT_TRUE_MESSAGE(password_hash_test::available(), password_hash_test::backendError());
    TEST_ASSERT_TRUE(bs::auth::passwordHash<Sha256>(
        password.data(), password.size(), salt.data(), iterations, output.data()));
    const auto expected = decodeDigest(expectedHex);
    TEST_ASSERT_EQUAL_UINT8_ARRAY(expected.data(), output.data(), output.size());
    TEST_ASSERT_TRUE(password == originalPassword);
    TEST_ASSERT_TRUE(salt == originalSalt);
    TEST_ASSERT_EQUAL_UINT32(0, password_hash_test::liveHashes());
}

// Failure injection wraps real SHA operations; it does not substitute a hash
// algorithm. Every operation is failed individually, including later rounds.
class FailingSha256 {
public:
    inline static size_t active = 0;
    inline static size_t constructed = 0;
    inline static size_t destroyed = 0;
    inline static size_t operations = 0;
    inline static size_t failAt = 0;
    inline static bool seen[4] = {};

    FailingSha256() { ++active; ++constructed; }
    ~FailingSha256() { --active; ++destroyed; }
    FailingSha256(const FailingSha256&) = delete;
    FailingSha256& operator=(const FailingSha256&) = delete;

    bool start() { return !fails(0) && hash_.start(); }
    bool update(const uint8_t* data, size_t size) {
        return !fails(1) && hash_.update(data, size);
    }
    bool finish(uint8_t output[32]) {
        if (fails(2)) {
            std::fill(output, output + 32, 0xee);
            return false;
        }
        return hash_.finish(output);
    }
    bool clone(const FailingSha256& source) {
        return !fails(3) && hash_.clone(source.hash_);
    }

    static void reset(size_t failure = 0) {
        constructed = destroyed = operations = 0;
        failAt = failure;
        std::fill(std::begin(seen), std::end(seen), false);
    }

private:
    Sha256 hash_;
    static bool fails(size_t operation) {
        seen[operation] = true;
        return ++operations == failAt;
    }
};

void assertZero(const Digest& output) {
    const Digest zero{};
    TEST_ASSERT_EQUAL_UINT8_ARRAY(zero.data(), output.data(), output.size());
}

} // namespace

void setUp() {}
void tearDown() {
    TEST_ASSERT_EQUAL_UINT32(0, FailingSha256::active);
    TEST_ASSERT_EQUAL_UINT32(0, password_hash_test::liveHashes());
}

void test_password_hash_format_constants_remain_compatible() {
    TEST_ASSERT_EQUAL_UINT32(120000, bs::auth::kPasswordIterations);
    TEST_ASSERT_EQUAL_UINT32(128, bs::auth::kPasswordBytes);
    TEST_ASSERT_EQUAL_UINT32(16, bs::auth::kSaltBytes);
    TEST_ASSERT_EQUAL_UINT32(32, bs::auth::kHashBytes);
}

void test_password_byte_and_sha_block_boundaries_match_python() {
    // Generated independently with Python hashlib.pbkdf2_hmac('sha256', ...).
    struct Vector { size_t length; const char* digest; };
    const Vector vectors[] = {
        {0, "b01769faf6a2ed2eb6258f32dca850daa77c443f81273b0efb782e1023abdb25"},
        {1, "0664f6764d20153f1abc9cf61afe00d5c45f676e29471b9219b7825fada733e8"},
        {12, "8ad05196bd9ce837a32800da6fbf5abf4da8d28949040c3f055c28389c31cc45"},
        {55, "0dd41a65ba008be0684c74618e91e14bce96ccf0162ef591335c92822fb41510"},
        {56, "08458d95e9a32d1c34a8ae23fd59f2aa5082bf18fff349c499da4a38ac2dc82e"},
        {63, "8d039bcb830d7839f08f538593e442fd14e31a50968a00d70b4e3298dd27f901"},
        {64, "f9f7952922896f0345abb903762fbbbbf93e6d77862018fdd392d2be97c32b5c"},
        {65, "b49477a5e6896af237d2841db0bbb999a19742ba644f5d3906aeb3febaf6494a"},
        {119, "19532b6bd592170709bead82558760ba2d3838d528ffa8f689788d5ea7c41047"},
        {120, "77e69429f9b6462c89506d6f462bc0ce6b72d5b3e31120c9f5cc5c6ed4f9ac38"},
        {127, "ff199c9b64f2ed99a165200aa8321b22dc816e8d902568e508b6050e6de50109"},
        {128, "fd5abd4f55c5bf5837d23d103de97724395afa89e8f0235fccff0501a8dd2946"},
    };
    for (const auto& vector : vectors) {
        std::vector<uint8_t> password(vector.length);
        for (size_t i = 0; i < password.size(); ++i) password[i] = static_cast<uint8_t>(i * 37 + 11);
        matches(password, sequenceSalt(), 2, vector.digest);
    }
}

void test_production_iterations_match_existing_password_format() {
    const std::string phrase = "correct horse battery staple";
    matches({}, sequenceSalt(), bs::auth::kPasswordIterations,
        "ac7f633639f64f211c4982d8f98dcbbba1b30b6b8badec5db51235bd5c36a646");
    matches(std::vector<uint8_t>(phrase.begin(), phrase.end()), sequenceSalt(), bs::auth::kPasswordIterations,
        "e962ebd8267bc839386d4608bbc3c8ac36bfb215faa8544e3a4e2cbccec84806");
    matches(std::vector<uint8_t>(64, 'A'), sequenceSalt(), bs::auth::kPasswordIterations,
        "fe18c5715fb5e90111ec93d3e9e6fce69632d4984971f3930854065d43f8d618");
    matches(std::vector<uint8_t>(65, 'A'), sequenceSalt(), bs::auth::kPasswordIterations,
        "543619c048988a8e22f5769c09fb0bba0b6c3d4a8499c8e592a3ecd47d24194b");
    std::vector<uint8_t> binary(128);
    for (size_t i = 0; i < binary.size(); ++i) binary[i] = static_cast<uint8_t>(i);
    matches(binary, sequenceSalt(), bs::auth::kPasswordIterations,
        "981a8c3b95703761a3477926d13a933c7270855ab3ff0911fe211df4dc877680");
    matches(std::vector<uint8_t>(128, 0), Salt{}, bs::auth::kPasswordIterations,
        "d6ec741358dd5f5eb8a50a2c952bd85e02a9e43c7fabe571b650d423e80b27c2");
    // Explicit UTF-8 bytes keep this test independent of compiler source encoding.
    const uint8_t utf8[] = {0x47, 0x72, 0xc3, 0xbc, 0xc3, 0x9f, 0x65, 0x20,
        0xf0, 0x9f, 0x94, 0x90, 0x20, 0xc3, 0xbc, 0x62, 0x65, 0x72, 0x20, 0x57, 0x4c, 0x41, 0x4e};
    Salt highSalt{};
    highSalt.fill(0xff);
    matches(std::vector<uint8_t>(std::begin(utf8), std::end(utf8)), highSalt, bs::auth::kPasswordIterations,
        "dbbc20ff2ce0967cb1249d0cd235161a134142d0d8fdf851d46f7b4adc511c26");
}

void test_invalid_arguments_fail_with_zero_output() {
    const auto salt = sequenceSalt();
    std::vector<uint8_t> password(129, 'x');
    Digest output{};
    output.fill(0xa5);
    TEST_ASSERT_FALSE(bs::auth::passwordHash<Sha256>(nullptr, 1, salt.data(), 1, output.data()));
    assertZero(output);
    output.fill(0xa5);
    TEST_ASSERT_FALSE(bs::auth::passwordHash<Sha256>(password.data(), password.size(), salt.data(), 1, output.data()));
    assertZero(output);
    output.fill(0xa5);
    TEST_ASSERT_FALSE(bs::auth::passwordHash<Sha256>(password.data(), 12, nullptr, 1, output.data()));
    assertZero(output);
    output.fill(0xa5);
    TEST_ASSERT_FALSE(bs::auth::passwordHash<Sha256>(password.data(), 12, salt.data(), 0, output.data()));
    assertZero(output);
    TEST_ASSERT_FALSE(bs::auth::passwordHash<Sha256>(password.data(), 12, salt.data(), 1, nullptr));
    TEST_ASSERT_TRUE(bs::auth::passwordHash<Sha256>(nullptr, 0, salt.data(), 2, output.data()));
    const auto expected = decodeDigest("b01769faf6a2ed2eb6258f32dca850daa77c443f81273b0efb782e1023abdb25");
    TEST_ASSERT_EQUAL_UINT8_ARRAY(expected.data(), output.data(), output.size());
}

void test_each_crypto_failure_clears_output_and_releases_all_contexts() {
    const auto salt = sequenceSalt();
    for (size_t length : {size_t(12), size_t(65), size_t(128)}) {
        std::vector<uint8_t> password(length, 'q');
        Digest output{};
        FailingSha256::reset();
        TEST_ASSERT_TRUE(bs::auth::passwordHash<FailingSha256>(password.data(), password.size(), salt.data(), 3, output.data()));
        const size_t calls = FailingSha256::operations;
        for (const bool seen : FailingSha256::seen) TEST_ASSERT_TRUE(seen);
        TEST_ASSERT_EQUAL_UINT32(FailingSha256::constructed, FailingSha256::destroyed);
        for (size_t failing = 1; failing <= calls; ++failing) {
            FailingSha256::reset(failing);
            output.fill(0xa5);
            TEST_ASSERT_FALSE(bs::auth::passwordHash<FailingSha256>(password.data(), password.size(), salt.data(), 3, output.data()));
            TEST_ASSERT_EQUAL_UINT32(failing, FailingSha256::operations);
            assertZero(output);
            TEST_ASSERT_EQUAL_UINT32(0, FailingSha256::active);
            TEST_ASSERT_EQUAL_UINT32(FailingSha256::constructed, FailingSha256::destroyed);
            TEST_ASSERT_EQUAL_UINT32(0, password_hash_test::liveHashes());
        }
    }
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_password_hash_format_constants_remain_compatible);
    RUN_TEST(test_password_byte_and_sha_block_boundaries_match_python);
    RUN_TEST(test_production_iterations_match_existing_password_format);
    RUN_TEST(test_invalid_arguments_fail_with_zero_output);
    RUN_TEST(test_each_crypto_failure_clears_output_and_releases_all_contexts);
    return UNITY_END();
}
