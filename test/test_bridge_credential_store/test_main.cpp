#include <unity.h>
#include <BridgeCredentialStore.h>

#include <array>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

using Salt = std::array<uint8_t, bs::auth::kSaltBytes>;
using Hash = std::array<uint8_t, bs::auth::kHashBytes>;
using Bytes = std::vector<uint8_t>;
using Format = bs::auth::CredentialFormat;

struct PowerLoss : std::runtime_error { PowerLoss() : std::runtime_error("synthetic power loss") {} };

// This model exposes the NVS atomic-entry contract: an interrupted commit
// leaves either the whole old value or the whole new value, never mixed bytes.
// Synthetic settings only; no real device or credential store is read.
struct Store {
    std::map<std::string, Bytes> blobs{
        {"orion_key", Bytes(16, 0x42)},
    };
    std::map<std::string, std::string> strings{
        {"username", "synthetic_admin"},
        {"orion_mac", "aa:bb:cc:dd:ee:ff"},
        {"orion_aliases", "Starter\nHouse"},
        {"ap_pass", "synthetic_wifi_password"},
        {"tls3_cert", "synthetic_certificate"},
        {"tls3_key", "synthetic_private_key"},
    };
    std::map<std::string, uint8_t> bytes{{"n2k_in", 3}, {"n2k_out", 7}, {"tls_ver", 3}};
    std::vector<std::string> writes;
    std::vector<std::string> reads;
    size_t failAt = 0;
    size_t powerLossAt = 0;
    bool powerLossAfterCommit = false;
    size_t shortReadAt = 0;

    bool isKey(const char* key) const {
        return blobs.count(key) || strings.count(key) || bytes.count(key);
    }
    size_t getBytesLength(const char* key) const {
        const auto found = blobs.find(key);
        return found == blobs.end() ? 0 : found->second.size();
    }
    size_t getBytes(const char* key, void* destination, size_t size) {
        reads.emplace_back(key);
        const auto found = blobs.find(key);
        if (found == blobs.end() || found->second.size() > size) return 0;
        const size_t length = found->second.size() - (reads.size() == shortReadAt ? 1 : 0);
        std::memcpy(destination, found->second.data(), length);
        return length;
    }
    bool beforeWrite(const char* key) {
        writes.emplace_back(key);
        if (writes.size() == powerLossAt && !powerLossAfterCommit) throw PowerLoss();
        return writes.size() != failAt;
    }
    void afterWrite() {
        if (writes.size() == powerLossAt && powerLossAfterCommit) throw PowerLoss();
    }
    size_t putBytes(const char* key, const void* data, size_t length) {
        if (!beforeWrite(key)) return 0;
        const auto* source = static_cast<const uint8_t*>(data);
        blobs[key] = Bytes(source, source + length);
        afterWrite();
        return length;
    }
    size_t putString(const char* key, const std::string& value) {
        if (!beforeWrite(key)) return 0;
        strings[key] = value;
        afterWrite();
        return value.length();
    }
    bool remove(const char* key) {
        if (!beforeWrite(key)) return false;
        blobs.erase(key);
        strings.erase(key);
        bytes.erase(key);
        afterWrite();
        return true;
    }
};

const Salt oldSalt = [] { Salt value{}; value.fill(0x31); return value; }();
const Salt newSalt = [] { Salt value{}; value.fill(0x62); return value; }();
const Hash oldHash = [] { Hash value{}; value.fill(0x53); return value; }();
const Hash newHash = [] { Hash value{}; value.fill(0x74); return value; }();

Store legacyStore() {
    Store store;
    store.blobs["pw_salt"] = Bytes(oldSalt.begin(), oldSalt.end());
    store.blobs["pw_hash"] = Bytes(oldHash.begin(), oldHash.end());
    return store;
}

void assertCredential(Store& store, Format expectedFormat, const Salt& expectedSalt, const Hash& expectedHash) {
    Salt salt{};
    Hash hash{};
    TEST_ASSERT_EQUAL_INT(static_cast<int>(expectedFormat),
        static_cast<int>(bs::auth::loadCredential(store, salt.data(), hash.data())));
    TEST_ASSERT_TRUE(salt == expectedSalt);
    TEST_ASSERT_TRUE(hash == expectedHash);
}

void assertUnrelatedSettings(const Store& before, const Store& after) {
    TEST_ASSERT_TRUE(before.strings == after.strings);
    TEST_ASSERT_TRUE(before.bytes == after.bytes);
    auto beforeBlobs = before.blobs;
    auto afterBlobs = after.blobs;
    beforeBlobs.erase(bs::auth::kCredentialEntry);
    afterBlobs.erase(bs::auth::kCredentialEntry);
    TEST_ASSERT_TRUE(beforeBlobs == afterBlobs);
}

} // namespace

void setUp() {}
void tearDown() {}

void test_legacy_load_is_read_only_and_migration_preserves_all_other_keys() {
    Store store = legacyStore();
    const Store before = store;
    assertCredential(store, Format::Legacy, oldSalt, oldHash);
    TEST_ASSERT_TRUE(store.writes.empty());
    TEST_ASSERT_TRUE(bs::auth::saveCredential(store, newSalt.data(), newHash.data()));
    TEST_ASSERT_EQUAL_UINT32(1, store.writes.size());
    TEST_ASSERT_EQUAL_STRING(bs::auth::kCredentialEntry, store.writes[0].c_str());
    assertUnrelatedSettings(before, store);
    assertCredential(store, Format::Current, newSalt, newHash);
}

void test_failed_migration_or_replacement_retains_previous_credentials_after_reload() {
    for (bool alreadyMigrated : {false, true}) {
        Store store = legacyStore();
        if (alreadyMigrated) TEST_ASSERT_TRUE(bs::auth::saveCredential(store, oldSalt.data(), oldHash.data()));
        store.writes.clear();
        const Store before = store;
        store.failAt = 1;
        TEST_ASSERT_FALSE(bs::auth::saveCredential(store, newSalt.data(), newHash.data()));
        TEST_ASSERT_TRUE(store.blobs == before.blobs);
        assertUnrelatedSettings(before, store);
        assertCredential(store, alreadyMigrated ? Format::Current : Format::Legacy, oldSalt, oldHash);
    }
}

void test_power_loss_before_or_after_commit_never_mixes_salt_and_hash() {
    for (bool alreadyMigrated : {false, true}) {
        for (bool committed : {false, true}) {
            Store store = legacyStore();
            if (alreadyMigrated) TEST_ASSERT_TRUE(bs::auth::saveCredential(store, oldSalt.data(), oldHash.data()));
            store.writes.clear();
            const Store before = store;
            store.powerLossAt = 1;
            store.powerLossAfterCommit = committed;
            bool interrupted = false;
            try { bs::auth::saveCredential(store, newSalt.data(), newHash.data()); }
            catch (const PowerLoss&) { interrupted = true; }
            TEST_ASSERT_TRUE(interrupted);
            assertUnrelatedSettings(before, store);
            assertCredential(store, committed || alreadyMigrated ? Format::Current : Format::Legacy,
                committed ? newSalt : oldSalt, committed ? newHash : oldHash);
        }
    }
}

void test_current_entry_prevents_all_corrupt_or_unsupported_legacy_fallbacks() {
    Store initial = legacyStore();
    TEST_ASSERT_TRUE(bs::auth::saveCredential(initial, newSalt.data(), newHash.data()));
    for (size_t byte = 0; byte < bs::auth::kCredentialBlobBytes; ++byte) {
        Store store = initial;
        store.reads.clear();
        store.blobs.at(bs::auth::kCredentialEntry)[byte] ^= 1;
        assertCredential(store, Format::InvalidCurrent, Salt{}, Hash{});
        TEST_ASSERT_EQUAL_UINT32(1, store.reads.size());
        TEST_ASSERT_EQUAL_STRING(bs::auth::kCredentialEntry, store.reads[0].c_str());
    }
    for (size_t size : {size_t(0), size_t(1), bs::auth::kCredentialBlobBytes - 1,
                       bs::auth::kCredentialBlobBytes + 1}) {
        Store store = initial;
        store.reads.clear();
        store.blobs.at(bs::auth::kCredentialEntry).resize(size);
        assertCredential(store, Format::InvalidCurrent, Salt{}, Hash{});
        TEST_ASSERT_TRUE(store.reads.empty());
    }
    Store store = initial;
    store.reads.clear();
    store.shortReadAt = 1;
    assertCredential(store, Format::InvalidCurrent, Salt{}, Hash{});
}

void test_incomplete_legacy_reads_do_not_publish_half_a_credential() {
    for (size_t shortRead : {size_t(1), size_t(2)}) {
        Store store = legacyStore();
        store.shortReadAt = shortRead;
        assertCredential(store, Format::Missing, Salt{}, Hash{});
    }
    for (const char* missing : {"pw_salt", "pw_hash"}) {
        Store store = legacyStore();
        store.blobs.erase(missing);
        assertCredential(store, Format::Missing, Salt{}, Hash{});
    }
    Store store;
    assertCredential(store, Format::Missing, Salt{}, Hash{});
}

void test_corrupt_current_credential_can_be_repaired_without_other_changes() {
    Store store = legacyStore();
    store.blobs[bs::auth::kCredentialEntry] = Bytes{0};
    const Store before = store;
    assertCredential(store, Format::InvalidCurrent, Salt{}, Hash{});
    TEST_ASSERT_TRUE(bs::auth::saveCredential(store, newSalt.data(), newHash.data()));
    assertCredential(store, Format::Current, newSalt, newHash);
    assertUnrelatedSettings(before, store);
}

void test_failed_initial_setup_remains_retryable_without_activating_orphaned_hash() {
    for (size_t failing = 1; failing <= 3; ++failing) {
        Store store;
        // An incomplete legacy setup may have a username but no usable hash.
        const Store before = store;
        store.failAt = failing;
        TEST_ASSERT_FALSE(bs::auth::saveInitialAdministrator(store, std::string("new_admin"), newSalt.data(), newHash.data()));
        if (failing == 1) TEST_ASSERT_TRUE(store.blobs == before.blobs && store.strings == before.strings);
        else TEST_ASSERT_FALSE(store.isKey("username"));
        store.failAt = 0;
        store.writes.clear();
        TEST_ASSERT_TRUE(bs::auth::saveInitialAdministrator(store, std::string("new_admin"), oldSalt.data(), oldHash.data()));
        TEST_ASSERT_EQUAL_STRING("new_admin", store.strings.at("username").c_str());
        assertCredential(store, Format::Current, oldSalt, oldHash);
        Store expected = before;
        expected.strings["username"] = "new_admin";
        assertUnrelatedSettings(expected, store);
    }
}

void test_initial_setup_power_loss_keeps_account_inactive_until_username_commit() {
    for (size_t interruptedAt = 1; interruptedAt <= 3; ++interruptedAt) {
        for (bool committed : {false, true}) {
            Store store;
            store.powerLossAt = interruptedAt;
            store.powerLossAfterCommit = committed;
            bool interrupted = false;
            try { bs::auth::saveInitialAdministrator(store, std::string("new_admin"), newSalt.data(), newHash.data()); }
            catch (const PowerLoss&) { interrupted = true; }
            TEST_ASSERT_TRUE(interrupted);
            const bool active = store.isKey("username") &&
                store.strings.at("username") == "new_admin";
            TEST_ASSERT_EQUAL_INT(interruptedAt == 3 && committed, active);
            if (active) assertCredential(store, Format::Current, newSalt, newHash);
        }
    }
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_legacy_load_is_read_only_and_migration_preserves_all_other_keys);
    RUN_TEST(test_failed_migration_or_replacement_retains_previous_credentials_after_reload);
    RUN_TEST(test_power_loss_before_or_after_commit_never_mixes_salt_and_hash);
    RUN_TEST(test_current_entry_prevents_all_corrupt_or_unsupported_legacy_fallbacks);
    RUN_TEST(test_incomplete_legacy_reads_do_not_publish_half_a_credential);
    RUN_TEST(test_corrupt_current_credential_can_be_repaired_without_other_changes);
    RUN_TEST(test_failed_initial_setup_remains_retryable_without_activating_orphaned_hash);
    RUN_TEST(test_initial_setup_power_loss_keeps_account_inactive_until_username_commit);
    return UNITY_END();
}
