#include <unity.h>
#include <BridgeCertificateStore.h>

#include <map>
#include <string>
#include <vector>

namespace {

// Synthetic values only. Tests compare whole stores without printing keys or
// certificate contents; no real credentials or device storage are read.
const std::string newCertificate = "synthetic replacement certificate";
const std::string newPrivateKey = "synthetic reusable private key";

struct Store {
    std::map<std::string, std::string> strings{
        {"tls_cert", "synthetic legacy certificate"},
        {"tls_key", "synthetic legacy key"},
        {"username", "synthetic administrator"},
        {"ap_pass", "synthetic service credential"},
    };
    std::map<std::string, uint8_t> bytes{{"tls_ver", 2}, {"n2k_out", 3}};
    std::vector<std::string> writes;
    size_t failAt = 0;
    bool partialString = false;
    bool excessString = false;

    size_t putString(const char* name, const std::string& value) {
        writes.emplace_back(name);
        if (writes.size() == failAt) {
            if (partialString) {
                // Simulate an incomplete staged value as well as a short count.
                strings[name] = value.substr(0, value.length() - 1);
                return value.length() - 1;
            }
            if (excessString) return value.length() + 1;
            return 0;
        }
        strings[name] = value;
        return value.length();
    }

    size_t putUChar(const char* name, uint8_t value) {
        writes.emplace_back(name);
        if (writes.size() == failAt) return 0;
        bytes[name] = value;
        return 1;
    }
};

void preservesLegacyAndOtherSettings(const Store& before, const Store& after) {
    for (const auto& entry : before.strings) {
        const auto found = after.strings.find(entry.first);
        TEST_ASSERT_TRUE(found != after.strings.end());
        TEST_ASSERT_TRUE(found->second == entry.second);
    }
    for (const auto& entry : before.bytes) {
        if (entry.first == bs::tls::kCertificateVersionEntry) continue;
        const auto found = after.bytes.find(entry.first);
        TEST_ASSERT_TRUE(found != after.bytes.end());
        TEST_ASSERT_EQUAL_UINT8(entry.second, found->second);
    }
}

void checkWriteOrder(const Store& store, size_t expectedCount) {
    const char* expected[] = {"tls3_key", "tls3_cert", "tls_ver"};
    TEST_ASSERT_EQUAL_UINT32(expectedCount, store.writes.size());
    for (size_t i = 0; i < expectedCount; ++i) {
        TEST_ASSERT_EQUAL_STRING(expected[i], store.writes[i].c_str());
    }
}

} // namespace

void setUp() {}
void tearDown() {}

void test_success_stages_key_then_certificate_and_commits_version_last() {
    Store store;
    const Store before = store;
    TEST_ASSERT_TRUE(bs::tls::saveCertificate(store, newCertificate, newPrivateKey));
    checkWriteOrder(store, 3);
    preservesLegacyAndOtherSettings(before, store);
    auto expectedStrings = before.strings;
    expectedStrings["tls3_key"] = newPrivateKey;
    expectedStrings["tls3_cert"] = newCertificate;
    auto expectedBytes = before.bytes;
    expectedBytes["tls_ver"] = 3;
    TEST_ASSERT_TRUE(store.strings == expectedStrings);
    TEST_ASSERT_TRUE(store.bytes == expectedBytes);
    TEST_ASSERT_EQUAL_UINT8(3, bs::tls::kCertificateVersion);
}

void test_each_failed_write_retains_the_legacy_identity_and_version() {
    for (size_t failing = 1; failing <= 3; ++failing) {
        Store store;
        const Store before = store;
        store.failAt = failing;
        TEST_ASSERT_FALSE(bs::tls::saveCertificate(store, newCertificate, newPrivateKey));
        checkWriteOrder(store, failing);
        preservesLegacyAndOtherSettings(before, store);
        TEST_ASSERT_TRUE(store.bytes == before.bytes);
        TEST_ASSERT_EQUAL_UINT8(2, store.bytes.at("tls_ver"));
        if (failing == 1) TEST_ASSERT_TRUE(store.strings == before.strings);
        if (failing == 2) TEST_ASSERT_TRUE(store.strings.count("tls3_cert") == 0);
    }
}

void test_partial_or_excess_string_lengths_never_commit_the_version() {
    for (size_t failing : {size_t(1), size_t(2)}) {
        for (bool partial : {false, true}) {
            Store store;
            const Store before = store;
            store.failAt = failing;
            store.partialString = partial;
            store.excessString = !partial;
            TEST_ASSERT_FALSE(bs::tls::saveCertificate(store, newCertificate, newPrivateKey));
            checkWriteOrder(store, failing);
            preservesLegacyAndOtherSettings(before, store);
            TEST_ASSERT_TRUE(store.bytes == before.bytes);
        }
    }
}

void test_empty_certificate_or_key_performs_no_writes() {
    const std::string empty;
    for (const auto& values : {std::pair<std::string, std::string>{empty, newPrivateKey},
            {newCertificate, empty}, {empty, empty}}) {
        Store store;
        const Store before = store;
        TEST_ASSERT_FALSE(bs::tls::saveCertificate(store, values.first, values.second));
        TEST_ASSERT_TRUE(store.writes.empty());
        TEST_ASSERT_TRUE(store.strings == before.strings);
        TEST_ASSERT_TRUE(store.bytes == before.bytes);
    }
}

void test_retry_replaces_partial_staging_before_committing() {
    Store store;
    const Store before = store;
    store.failAt = 2;
    store.partialString = true;
    TEST_ASSERT_FALSE(bs::tls::saveCertificate(store, newCertificate, newPrivateKey));
    TEST_ASSERT_EQUAL_UINT8(2, store.bytes.at("tls_ver"));
    TEST_ASSERT_TRUE(store.strings.at("tls3_cert") != newCertificate);
    store.writes.clear();
    store.failAt = 0;
    store.partialString = false;
    TEST_ASSERT_TRUE(bs::tls::saveCertificate(store, newCertificate, newPrivateKey));
    checkWriteOrder(store, 3);
    preservesLegacyAndOtherSettings(before, store);
    TEST_ASSERT_TRUE(store.strings.at("tls3_key") == newPrivateKey);
    TEST_ASSERT_TRUE(store.strings.at("tls3_cert") == newCertificate);
    TEST_ASSERT_EQUAL_UINT8(3, store.bytes.at("tls_ver"));
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_success_stages_key_then_certificate_and_commits_version_last);
    RUN_TEST(test_each_failed_write_retains_the_legacy_identity_and_version);
    RUN_TEST(test_partial_or_excess_string_lengths_never_commit_the_version);
    RUN_TEST(test_empty_certificate_or_key_performs_no_writes);
    RUN_TEST(test_retry_replaces_partial_staging_before_committing);
    return UNITY_END();
}
