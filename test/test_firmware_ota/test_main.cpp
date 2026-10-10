#include <unity.h>
#include <FirmwareOta.h>

#include <algorithm>
#include <cstring>
#include <limits>
#include <vector>

using bs::ota::ImageValidator;

void setUp() {}
void tearDown() {}

namespace {

void set32(std::vector<uint8_t>& bytes, size_t offset, uint32_t value) {
    for (size_t i = 0; i < 4; ++i) bytes[offset + i] = static_cast<uint8_t>(value >> (i * 8));
}

// The SHA-256 implementation belongs to the caller. These synthetic digest
// bytes test the parser's hash boundary and digest comparison contract.
std::vector<uint8_t> image(const char* project = "orion-dongle", bool extraSegment = false,
                           size_t firstLength = 256, size_t secondLength = 12) {
    std::vector<uint8_t> bytes(24, 0);
    bytes[0] = 0xe9;
    bytes[1] = extraSegment ? 2 : 1;
    bytes[2] = 2;
    bytes[3] = 0x20;
    bytes[12] = 5;
    bytes[23] = 1;
    bytes.resize(32 + firstLength, 0);
    set32(bytes, 24, 0x3c000020U);
    set32(bytes, 28, static_cast<uint32_t>(firstLength));
    set32(bytes, 32, 0xabcd5432U);
    memcpy(bytes.data() + 48, "1.2.3", 5);
    memcpy(bytes.data() + 80, project, std::min<size_t>(strlen(project), 32));
    uint8_t checksum = 0xef;
    for (size_t i = 32; i < bytes.size(); ++i) checksum ^= bytes[i];
    if (extraSegment) {
        const size_t offset = bytes.size();
        bytes.resize(offset + 8 + secondLength, 0);
        set32(bytes, offset, 0x3fc80000U);
        set32(bytes, offset + 4, static_cast<uint32_t>(secondLength));
        for (size_t i = offset + 8; i < bytes.size(); ++i) {
            bytes[i] = static_cast<uint8_t>(i);
            checksum ^= bytes[i];
        }
    }
    while ((bytes.size() & 15) != 15) bytes.push_back(0);
    bytes.push_back(checksum);
    for (uint8_t i = 0; i < ImageValidator::DigestSize; ++i) bytes.push_back(0x3f ^ i);
    return bytes;
}

bool feed(ImageValidator& validator, const std::vector<uint8_t>& bytes, size_t chunk = 17,
          std::vector<uint8_t>* hashed = nullptr) {
    for (size_t offset = 0; offset < bytes.size(); offset += chunk) {
        const size_t size = std::min(chunk, bytes.size() - offset);
        size_t hashBytes = 0;
        if (!validator.write(bytes.data() + offset, size, hashBytes)) return false;
        TEST_ASSERT_LESS_OR_EQUAL_UINT32(size, hashBytes);
        if (hashed) hashed->insert(hashed->end(), bytes.begin() + offset, bytes.begin() + offset + hashBytes);
    }
    return true;
}

void rejects(const std::vector<uint8_t>& bytes, const char* code,
             const char* project = "orion-dongle", size_t maximum = 4096) {
    ImageValidator validator(project, maximum);
    const bool streamed = feed(validator, bytes);
    uint8_t digest[ImageValidator::DigestSize] = {};
    if (bytes.size() >= sizeof(digest)) memcpy(digest, bytes.data() + bytes.size() - sizeof(digest), sizeof(digest));
    TEST_ASSERT_FALSE(streamed && validator.finish(digest));
    TEST_ASSERT_FALSE(validator.valid());
    TEST_ASSERT_EQUAL_STRING(code, validator.errorCode());
    TEST_ASSERT_TRUE(strlen(validator.errorMessage()) > 0);
}

} // namespace

void test_valid_images_and_hash_boundaries_for_every_chunk_size() {
    static_assert(sizeof(ImageValidator) <= 320, "Validation must use bounded, small memory.");
    const size_t chunks[] = {1, 2, 7, 16, 31, 79, 112, 288, 1024};
    for (const size_t chunk : chunks) {
        for (size_t firstLength = 256; firstLength <= 272; firstLength += 4) {
            const auto bytes = image("orion-dongle", true, firstLength);
            ImageValidator validator("orion-dongle", bytes.size());
            std::vector<uint8_t> hashed;
            TEST_ASSERT_TRUE(feed(validator, bytes, chunk, &hashed));
            TEST_ASSERT_TRUE(validator.targetVerified());
            TEST_ASSERT_FALSE(validator.valid());
            TEST_ASSERT_EQUAL_STRING("1.2.3", validator.firmwareVersion());
            TEST_ASSERT_EQUAL_UINT32(bytes.size(), validator.bytesReceived());
            TEST_ASSERT_EQUAL_UINT32(bytes.size() - 32, hashed.size());
            TEST_ASSERT_EQUAL_UINT8_ARRAY(bytes.data(), hashed.data(), hashed.size());
            TEST_ASSERT_EQUAL_UINT8_ARRAY(bytes.data() + hashed.size(), validator.expectedDigest(), 32);
            TEST_ASSERT_TRUE(validator.finish(bytes.data() + hashed.size()));
            TEST_ASSERT_TRUE(validator.valid());
            TEST_ASSERT_EQUAL_STRING("", validator.errorCode());
        }
    }
}

void test_identity_available_before_flash_write() {
    const auto bytes = image();
    ImageValidator validator("orion-dongle", bytes.size());
    size_t hashBytes = 0;
    TEST_ASSERT_TRUE(validator.write(bytes.data(), 111, hashBytes));
    TEST_ASSERT_FALSE(validator.targetVerified());
    TEST_ASSERT_TRUE(validator.write(bytes.data() + 111, 1, hashBytes));
    TEST_ASSERT_TRUE(validator.targetVerified());
    TEST_ASSERT_FALSE(validator.valid());
}

void test_correct_product_variant_required() {
    rejects(image("orion-r4"), "target");
    rejects(image("orion-dongle"), "target", "orion-r4");
    rejects(image("orion-dongle-other"), "target");
    rejects(image("orion-dongl"), "target");
    rejects(image(""), "target");
    rejects(image("01234567890123456789012345678901"), "target");
    const auto bytes = image("orion-r4");
    ImageValidator validator("orion-r4", bytes.size());
    TEST_ASSERT_TRUE(feed(validator, bytes));
    TEST_ASSERT_TRUE(validator.finish(bytes.data() + bytes.size() - 32));
}

void test_bootloader_and_other_chip_images_rejected() {
    auto bytes = image();
    bytes[0] = 0xff;
    rejects(bytes, "image");
    bytes = image();
    bytes[12] = 9;
    rejects(bytes, "target");
    bytes = image();
    bytes[13] = 1;
    rejects(bytes, "target");
    bytes = image();
    bytes[32] ^= 1;
    rejects(bytes, "image");
}

void test_debug_oled_target_accepts_only_its_own_images() {
    const auto bytes = image("orion-debug-oled");
    for (const size_t chunk : {1U, 17U, 112U, 1024U}) {
        ImageValidator validator("orion-debug-oled", bytes.size());
        TEST_ASSERT_TRUE(feed(validator, bytes, chunk));
        TEST_ASSERT_TRUE(validator.targetVerified());
        TEST_ASSERT_TRUE(validator.finish(bytes.data() + bytes.size() - 32));
        TEST_ASSERT_TRUE(validator.valid());
    }
    // Pin assignments differ: matching chip/flash geometry is not sufficient.
    const char* targets[] = {"orion-dongle", "orion-r4", "orion-debug-oled"};
    for (const auto actual : targets) {
        for (const auto expected : targets) {
            if (strcmp(actual, expected) != 0) rejects(image(actual), "target", expected);
        }
    }
    for (const auto actual : {"orion-debug", "orion-debug-oled-other", "orion-debug-oled "}) {
        rejects(image(actual), "target", "orion-debug-oled");
    }
}

void test_invalid_image_header_fields_rejected() {
    for (const uint8_t count : {0, 17, 255}) {
        auto bytes = image();
        bytes[1] = count;
        rejects(bytes, "image");
    }
    for (const uint8_t flash : {0x00, 0x10, 0x30, 0x40, 0xf0, 0x23}) {
        auto bytes = image();
        bytes[3] = flash;
        rejects(bytes, "image");
    }
    auto bytes = image();
    bytes[2] = 6;
    rejects(bytes, "image");
    for (const uint8_t flag : {0, 2, 255}) {
        bytes = image();
        bytes[23] = flag;
        rejects(bytes, "hash");
    }
}

void test_descriptor_must_fit_inside_first_segment() {
    for (const uint32_t length : {0U, 4U, 80U, 252U}) {
        auto bytes = image();
        set32(bytes, 28, length);
        rejects(bytes, "image");
    }
    auto bytes = image();
    std::fill(bytes.begin() + 80, bytes.begin() + 112, 'a');
    rejects(bytes, "target");
}

void test_descriptor_requires_drom_address_and_printable_version() {
    for (const uint32_t address : {0U, 0x3bffffffU, 0x3c7fff01U, 0x3c800000U, 0xffffffffU}) {
        auto bytes = image();
        set32(bytes, 24, address);
        rejects(bytes, "image");
    }
    for (const uint8_t character : {0, 1, 0x1f, 0x7f, 0xff}) {
        auto bytes = image();
        bytes[48] = character;
        rejects(bytes, "image");
    }
    auto bytes = image();
    std::fill(bytes.begin() + 48, bytes.begin() + 80, '1');
    rejects(bytes, "image");
}

void test_oversized_and_unaligned_segments_rejected_without_overflow() {
    auto bytes = image();
    set32(bytes, 28, 0xfffffffcU);
    rejects(bytes, "size");
    bytes = image();
    set32(bytes, 28, 0xffffffffU);
    rejects(bytes, "size");
    bytes = image();
    set32(bytes, 28, 257);
    rejects(bytes, "image");
    bytes = image("orion-dongle", true);
    set32(bytes, 32 + 256 + 4, 0xfffffff0U);
    rejects(bytes, "size");
    // On a 64-bit native host, an artificially huge cap must not bypass ESP's
    // own segment limit, even when the arithmetic itself cannot overflow.
    bytes = image();
    set32(bytes, 28, 0x1000000U);
    rejects(bytes, "image", "orion-dongle", std::numeric_limits<size_t>::max());
}

void test_zero_length_later_segment_is_supported() {
    const auto bytes = image("orion-dongle", true, 256, 0);
    ImageValidator validator("orion-dongle", bytes.size());
    TEST_ASSERT_TRUE(feed(validator, bytes, 1));
    TEST_ASSERT_TRUE(validator.finish(bytes.data() + bytes.size() - 32));
}

void test_corruption_padding_and_checksum_rejected() {
    auto bytes = image();
    bytes[200] ^= 0x80;
    rejects(bytes, "checksum");
    bytes = image();
    bytes[bytes.size() - 33] ^= 1;
    rejects(bytes, "checksum");
    bytes = image();
    bytes[288] = 0xff;
    rejects(bytes, "image");
}

void test_digest_mismatch_blocks_finalization() {
    auto bytes = image();
    uint8_t computed[32];
    memcpy(computed, bytes.data() + bytes.size() - 32, 32);
    bytes.back() ^= 1;
    ImageValidator validator("orion-dongle", bytes.size());
    TEST_ASSERT_TRUE(feed(validator, bytes));
    TEST_ASSERT_FALSE(validator.finish(computed));
    TEST_ASSERT_EQUAL_STRING("hash", validator.errorCode());
    TEST_ASSERT_FALSE(validator.valid());
    // Corruption with cancelling XOR errors must still fail the SHA check.
    bytes = image();
    bytes[200] ^= 1;
    bytes[201] ^= 1;
    ImageValidator paired("orion-dongle", bytes.size());
    TEST_ASSERT_TRUE(feed(paired, bytes));
    computed[0] ^= 1; // Represents the caller's changed SHA-256 for changed data.
    TEST_ASSERT_FALSE(paired.finish(computed));
    TEST_ASSERT_EQUAL_STRING("hash", paired.errorCode());
}

void test_every_truncation_is_rejected() {
    const auto bytes = image("orion-dongle", true);
    for (size_t length = 0; length < bytes.size(); ++length) {
        ImageValidator validator("orion-dongle", bytes.size());
        size_t hashBytes = 0;
        TEST_ASSERT_TRUE(validator.write(bytes.data(), length, hashBytes));
        TEST_ASSERT_FALSE(validator.finish(bytes.data() + bytes.size() - 32));
        TEST_ASSERT_EQUAL_STRING("image", validator.errorCode());
        TEST_ASSERT_FALSE(validator.valid());
    }
}

void test_trailing_data_and_concatenated_images_rejected() {
    auto bytes = image();
    bytes.push_back(0);
    rejects(bytes, "image");
    bytes = image();
    const auto appended = image();
    bytes.insert(bytes.end(), appended.begin(), appended.end());
    rejects(bytes, "image");
    bytes = image();
    ImageValidator validator("orion-dongle", bytes.size() + 1);
    TEST_ASSERT_TRUE(feed(validator, bytes));
    TEST_ASSERT_TRUE(validator.finish(bytes.data() + bytes.size() - 32));
    size_t hashBytes = 99;
    TEST_ASSERT_FALSE(validator.write(bytes.data(), 1, hashBytes));
    TEST_ASSERT_FALSE(validator.valid());
    TEST_ASSERT_EQUAL_STRING("image", validator.errorCode());
}

void test_declared_size_limit_and_invalid_arguments() {
    const auto bytes = image();
    rejects(bytes, "size", "orion-dongle", bytes.size() - 1);
    rejects(bytes, "size", "orion-dongle", 0);
    rejects(bytes, "target", "");
    rejects(bytes, "target", nullptr);
    rejects(bytes, "target", "01234567890123456789012345678901");
    ImageValidator validator("orion-dongle", bytes.size());
    size_t hashBytes = 99;
    TEST_ASSERT_TRUE(validator.write(nullptr, 0, hashBytes));
    TEST_ASSERT_EQUAL_UINT32(0, hashBytes);
    TEST_ASSERT_FALSE(validator.write(nullptr, 1, hashBytes));
    TEST_ASSERT_EQUAL_STRING("image", validator.errorCode());
    TEST_ASSERT_FALSE(validator.write(bytes.data(), bytes.size(), hashBytes));
    ImageValidator noDigest("orion-dongle", bytes.size());
    TEST_ASSERT_TRUE(feed(noDigest, bytes));
    TEST_ASSERT_FALSE(noDigest.finish(nullptr));
    TEST_ASSERT_EQUAL_STRING("image", noDigest.errorCode());
}

int main(int, char**) {
    UNITY_BEGIN();
    RUN_TEST(test_valid_images_and_hash_boundaries_for_every_chunk_size);
    RUN_TEST(test_identity_available_before_flash_write);
    RUN_TEST(test_correct_product_variant_required);
    RUN_TEST(test_debug_oled_target_accepts_only_its_own_images);
    RUN_TEST(test_bootloader_and_other_chip_images_rejected);
    RUN_TEST(test_invalid_image_header_fields_rejected);
    RUN_TEST(test_descriptor_must_fit_inside_first_segment);
    RUN_TEST(test_descriptor_requires_drom_address_and_printable_version);
    RUN_TEST(test_oversized_and_unaligned_segments_rejected_without_overflow);
    RUN_TEST(test_zero_length_later_segment_is_supported);
    RUN_TEST(test_corruption_padding_and_checksum_rejected);
    RUN_TEST(test_digest_mismatch_blocks_finalization);
    RUN_TEST(test_every_truncation_is_rejected);
    RUN_TEST(test_trailing_data_and_concatenated_images_rejected);
    RUN_TEST(test_declared_size_limit_and_invalid_arguments);
    return UNITY_END();
}
