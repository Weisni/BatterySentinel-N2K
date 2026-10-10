#include <unity.h>
#include <OrionAliases.h>
#include <cstring>
#include <string>

using bs::orion::Aliases;

void setUp() {}
void tearDown() {}

bool pair(const std::string& input, const std::string& output, Aliases& aliases) {
    return bs::orion::normalizeAliases(input.data(), input.size(), output.data(), output.size(), aliases);
}

void test_defaults_and_outer_whitespace() {
    Aliases aliases;
    TEST_ASSERT_TRUE(pair(" \t\r\nStartbatterie\v\f ", "\tBugbatterie  ", aliases));
    TEST_ASSERT_EQUAL_STRING(bs::orion::kDefaultInputAlias, aliases.input);
    TEST_ASSERT_EQUAL_STRING(bs::orion::kDefaultOutputAlias, aliases.output);
    TEST_ASSERT_TRUE(pair(u8" Vorn: Öl & <Strom> \"1\" ", u8"Heck ⚓", aliases));
    TEST_ASSERT_EQUAL_STRING(u8"Vorn: Öl & <Strom> \"1\"", aliases.input);
    TEST_ASSERT_EQUAL_STRING(u8"Heck ⚓", aliases.output);
}

void test_limits_count_unicode_scalars_not_bytes_or_utf16_units() {
    std::string emoji32;
    for (size_t i = 0; i < 32; ++i) emoji32 += u8"🔋";
    Aliases aliases;
    TEST_ASSERT_TRUE(pair(emoji32, std::string(32, 'B'), aliases));
    TEST_ASSERT_EQUAL_STRING(emoji32.c_str(), aliases.input);
    TEST_ASSERT_EQUAL_UINT32(128, std::strlen(aliases.input));
    TEST_ASSERT_FALSE(pair(emoji32 + u8"🔋", "Other", aliases));
    TEST_ASSERT_FALSE(pair("Input", std::string(33, 'B'), aliases));
    TEST_ASSERT_TRUE(pair("A", u8"Ö", aliases));
}

void test_case_fold_rejects_duplicate_names() {
    const char* duplicates[][2] = {
        {" Startbatterie ", "startBATTERIE"},
        {u8"BÜGBÄTTERIÖ", u8"bügbätteriö"},
        {u8"GROẞ", u8"groß"},
        {u8"Äß ÖÜ", u8"äẞ öü"}
    };
    for (const auto& duplicate : duplicates) {
        Aliases aliases;
        TEST_ASSERT_FALSE_MESSAGE(pair(duplicate[0], duplicate[1], aliases), duplicate[0]);
    }
    // Deliberately no general Unicode case folding or canonical normalization.
    Aliases aliases;
    TEST_ASSERT_TRUE(pair(u8"Straße", "STRASSE", aliases));
    TEST_ASSERT_TRUE(pair(u8"Ω", u8"ω", aliases));
    TEST_ASSERT_TRUE(pair(u8"Ä", "A\xcc\x88", aliases));
}

void test_controls_and_empty_names_are_rejected() {
    const std::string invalid[] = {
        "", " \t\n\v\f\r", "A\tB", "A\nB", "A\rB", "A\x01" "B",
        "A\x7f" "B", "A\xc2\x80" "B", "A\xc2\x9f" "B",
        u8"A\u2028B", u8"A\u2029B", std::string("A\0B", 3)
    };
    for (const auto& name : invalid) {
        Aliases aliases;
        TEST_ASSERT_FALSE(pair(name, "Output", aliases));
        TEST_ASSERT_FALSE(pair("Input", name, aliases));
    }
}

void test_rejects_malformed_utf8() {
    const char* invalid[] = {
        "\x80", "\xc2", "\xc0\xaf", "\xc1\xbf", "\xc2" "A",
        "\xe0\x80\xaf", "\xed\xa0\x80", "\xed\xbf\xbf",
        "\xf0\x80\x80\xaf", "\xf0\x9f\x94", "\xf4\x90\x80\x80", "\xf5\x80\x80\x80"
    };
    for (const char* name : invalid) {
        Aliases aliases;
        TEST_ASSERT_FALSE(pair(name, "Output", aliases));
    }
}

void test_invalid_update_never_changes_either_alias() {
    Aliases aliases;
    TEST_ASSERT_TRUE(pair("Original input", "Original output", aliases));
    TEST_ASSERT_FALSE(pair("New input", "\n", aliases));
    TEST_ASSERT_EQUAL_STRING("Original input", aliases.input);
    TEST_ASSERT_EQUAL_STRING("Original output", aliases.output);
    TEST_ASSERT_FALSE(pair(" DUPLICATE ", "duplicate", aliases));
    TEST_ASSERT_EQUAL_STRING("Original input", aliases.input);
    TEST_ASSERT_EQUAL_STRING("Original output", aliases.output);
    TEST_ASSERT_FALSE(bs::orion::normalizeAliases(nullptr, 0, "Output", 6, aliases));
}

int main(int, char**) {
    UNITY_BEGIN();
    RUN_TEST(test_defaults_and_outer_whitespace);
    RUN_TEST(test_limits_count_unicode_scalars_not_bytes_or_utf16_units);
    RUN_TEST(test_case_fold_rejects_duplicate_names);
    RUN_TEST(test_controls_and_empty_names_are_rejected);
    RUN_TEST(test_rejects_malformed_utf8);
    RUN_TEST(test_invalid_update_never_changes_either_alias);
    return UNITY_END();
}
