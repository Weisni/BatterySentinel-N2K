#include <unity.h>
#include <BridgePasswordUpdate.h>
#include <string>

namespace {
using bs::auth::PasswordUpdateResult;
struct Settings {
    bool admin = true;
    bool writeOk = true;
    int writes = 0;
    int checks = 0;
    std::string user = "test-admin";
    std::string password = "previous-password";
    bool hasAdmin() const { return admin; }
    const std::string& username() const { return user; }
    bool checkAdmin(const std::string& name, const std::string& candidate) {
        ++checks;
        return name == user && candidate == password;
    }
    bool changePassword(const std::string& value) {
        ++writes;
        if (writeOk) password = value;
        return writeOk;
    }
};

PasswordUpdateResult change(Settings& settings, bool authorized = true,
                            std::string current = "previous-password",
                            std::string password = "replacement-password",
                            std::string confirm = "replacement-password") {
    return bs::auth::changeOwnPassword(settings, authorized, current, password, confirm);
}
void unauthorizedChangeNeverVerifiesOrWrites() {
    Settings settings;
    TEST_ASSERT_TRUE(change(settings, false) == PasswordUpdateResult::Forbidden);
    settings.admin = false;
    TEST_ASSERT_TRUE(change(settings) == PasswordUpdateResult::Forbidden);
    TEST_ASSERT_EQUAL(0, settings.checks);
    TEST_ASSERT_EQUAL(0, settings.writes);
}
void invalidNewPasswordNeverWrites() {
    Settings settings;
    TEST_ASSERT_TRUE(change(settings, true, settings.password, "short", "short") == PasswordUpdateResult::InvalidPassword);
    TEST_ASSERT_TRUE(change(settings, true, settings.password, std::string(129, 'a'), std::string(129, 'a')) == PasswordUpdateResult::InvalidPassword);
    TEST_ASSERT_TRUE(change(settings, true, settings.password, "replacement-password", "different-password") == PasswordUpdateResult::InvalidPassword);
    TEST_ASSERT_EQUAL(0, settings.checks);
    TEST_ASSERT_EQUAL(0, settings.writes);
}
void wrongCurrentPasswordNeverWrites() {
    Settings settings;
    TEST_ASSERT_TRUE(change(settings, true, "incorrect-password") == PasswordUpdateResult::IncorrectCurrentPassword);
    TEST_ASSERT_EQUAL(1, settings.checks);
    TEST_ASSERT_EQUAL(0, settings.writes);
}
void changeAcceptsByteBoundsAndPreservesUsername() {
    for (const size_t length : {12U, 128U}) {
        Settings settings;
        const std::string replacement(length, 'a');
        TEST_ASSERT_TRUE(change(settings, true, settings.password, replacement, replacement) == PasswordUpdateResult::Saved);
        TEST_ASSERT_TRUE(settings.password == replacement);
        TEST_ASSERT_EQUAL_STRING("test-admin", settings.user.c_str());
        TEST_ASSERT_EQUAL(1, settings.writes);
    }
}
void storageFailureIsNotReportedAsSuccess() {
    Settings settings;
    settings.writeOk = false;
    TEST_ASSERT_TRUE(change(settings) == PasswordUpdateResult::StorageFailure);
    TEST_ASSERT_EQUAL_STRING("previous-password", settings.password.c_str());
    TEST_ASSERT_TRUE(bs::auth::recoverPassword(settings, true, true, true) == PasswordUpdateResult::StorageFailure);
    TEST_ASSERT_EQUAL_STRING("previous-password", settings.password.c_str());
}
void recoveryRequiresAllFourGuards() {
    // Includes missing/expired CSRF, no physical button, no explicit checkbox,
    // and attempts to create an administrator through recovery.
    for (unsigned mask = 0; mask < 15; ++mask) {
        Settings settings;
        settings.admin = mask & 8;
        TEST_ASSERT_TRUE(bs::auth::recoverPassword(settings, mask & 4, mask & 2, mask & 1) == PasswordUpdateResult::Forbidden);
        TEST_ASSERT_EQUAL(0, settings.writes);
        TEST_ASSERT_EQUAL(0, settings.checks);
    }
}
void recoveryUsesDocumentedDefaultWithoutOldPassword() {
    Settings settings;
    TEST_ASSERT_TRUE(bs::auth::recoverPassword(settings, true, true, true) == PasswordUpdateResult::Saved);
    TEST_ASSERT_EQUAL_STRING(bs::auth::kRecoveryPassword, settings.password.c_str());
    TEST_ASSERT_EQUAL_STRING("test-admin", settings.user.c_str());
    TEST_ASSERT_EQUAL(0, settings.checks);
    TEST_ASSERT_EQUAL(1, settings.writes);
}
}
void setUp() {}
void tearDown() {}
int main() {
    UNITY_BEGIN();
    RUN_TEST(unauthorizedChangeNeverVerifiesOrWrites);
    RUN_TEST(invalidNewPasswordNeverWrites);
    RUN_TEST(wrongCurrentPasswordNeverWrites);
    RUN_TEST(changeAcceptsByteBoundsAndPreservesUsername);
    RUN_TEST(storageFailureIsNotReportedAsSuccess);
    RUN_TEST(recoveryRequiresAllFourGuards);
    RUN_TEST(recoveryUsesDocumentedDefaultWithoutOldPassword);
    return UNITY_END();
}
