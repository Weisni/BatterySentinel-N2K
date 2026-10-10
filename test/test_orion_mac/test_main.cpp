#include <unity.h>
#include <OrionMac.h>
#include <cstring>

void setUp() {}
void tearDown() {}

void test_normalizes_supported_mac_input_formats() {
    const char* addresses[] = {
        "AAbb01CD23eF", "AA:bb:01:CD:23:eF", "AA-bb-01-CD-23-eF",
        "AA bb 01 CD 23 eF", " \tAA  bb\t01 CD 23 eF\r\n",
        "\r\nAAbb01CD23eF "
    };
    for (const char* address : addresses) {
        char normalized[18];
        TEST_ASSERT_TRUE_MESSAGE(bs::orion::normalizeMac(address, std::strlen(address), normalized), address);
        TEST_ASSERT_EQUAL_STRING("aa:bb:01:cd:23:ef", normalized);
    }
}

void test_rejects_invalid_mac_without_overwriting_output() {
    const char* addresses[] = {
        "", "   ", "AABB01CD23E", "AABB01CD23EFF", "AABB01CD23EG",
        "AA:BB:01:CD:23", "AA:BB:01:CD:23:EF:00", "AA:BB:01:CD:23:EFx",
        "AA:BB:01:CD:23:EF:", "AA::BB:01:CD:23:EF", "A:ABB:01:CD:23:EF",
        "AA:BB-01:CD:23:EF", "AA.BB.01.CD.23.EF", "AA BB 01 CD 23 E F"
    };
    for (const char* address : addresses) {
        char normalized[18] = "unchanged";
        TEST_ASSERT_FALSE_MESSAGE(bs::orion::normalizeMac(address, std::strlen(address), normalized), address);
        TEST_ASSERT_EQUAL_STRING("unchanged", normalized);
    }
    char normalized[18] = "unchanged";
    TEST_ASSERT_FALSE(bs::orion::normalizeMac(nullptr, 0, normalized));
    const char embeddedNull[] = "AA:BB:01:CD:23:EF\0AA";
    TEST_ASSERT_FALSE(bs::orion::normalizeMac(embeddedNull, sizeof(embeddedNull) - 1, normalized));
}

int main(int, char**) {
    UNITY_BEGIN();
    RUN_TEST(test_normalizes_supported_mac_input_formats);
    RUN_TEST(test_rejects_invalid_mac_without_overwriting_output);
    return UNITY_END();
}
