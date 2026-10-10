#include <unity.h>
#include <BridgeCertificateNames.h>
#include "../../src/BridgeNetworkIdentity.h"

#include <array>
#include <cstring>
#include <fstream>
#include <string>

namespace {

using bs::tls::CertificateNames;
constexpr auto serviceSan = bs::tls::makeSubjectAltNames(bs::kServiceDnsName);

void addDns(CertificateNames& names, const char* dns = bs::kServiceDnsName, int tag = 0x82) {
    names.add(tag, reinterpret_cast<const uint8_t*>(dns), std::strlen(dns));
}

void addIp(CertificateNames& names) {
    names.add(0x87, bs::tls::kServiceIpv4.data(), bs::tls::kServiceIpv4.size());
}

} // namespace

void setUp() {}
void tearDown() {}

void test_der_contains_dns_and_binary_ipv4_without_terminating_nul() {
    const uint8_t expected[] = {
        0x30, 0x1d, 0x82, 0x15,
        0x62, 0x61, 0x74, 0x74, 0x65, 0x72, 0x79, 0x73, 0x65, 0x6e, 0x74,
        0x69, 0x6e, 0x65, 0x6c, 0x2e, 0x6c, 0x6f, 0x63, 0x61, 0x6c,
        0x87, 0x04, 0xc0, 0xa8, 0x04, 0x01,
    };
    static_assert(serviceSan.size() == 31, "Service SAN DER must contain exactly 31 bytes");
    TEST_ASSERT_EQUAL_UINT8_ARRAY(expected, serviceSan.data(), sizeof(expected));

    constexpr auto shortName = bs::tls::makeSubjectAltNames("x.local");
    const uint8_t shortExpected[] = {0x30, 0x0f, 0x82, 0x07, 'x', '.', 'l', 'o', 'c', 'a', 'l',
        0x87, 0x04, 192, 168, 4, 1};
    TEST_ASSERT_EQUAL_UINT8_ARRAY(shortExpected, shortName.data(), sizeof(shortExpected));
}

void test_requires_both_san_types_in_either_order() {
    CertificateNames dnsFirst(bs::kServiceDnsName);
    TEST_ASSERT_FALSE(dnsFirst.complete());
    addDns(dnsFirst);
    TEST_ASSERT_FALSE(dnsFirst.complete());
    addDns(dnsFirst);
    TEST_ASSERT_FALSE(dnsFirst.complete());
    addIp(dnsFirst);
    TEST_ASSERT_TRUE(dnsFirst.complete());

    CertificateNames ipFirst(bs::kServiceDnsName);
    addIp(ipFirst);
    addIp(ipFirst);
    TEST_ASSERT_FALSE(ipFirst.complete());
    addDns(ipFirst);
    TEST_ASSERT_TRUE(ipFirst.complete());
}

void test_dns_match_is_case_insensitive_and_exact() {
    CertificateNames names(bs::kServiceDnsName);
    addDns(names, "BATTERYSENTINEL.LOCAL");
    addIp(names);
    TEST_ASSERT_TRUE(names.complete());

    CertificateNames expectedUpper("BATTERYSENTINEL.LOCAL");
    addDns(expectedUpper);
    addIp(expectedUpper);
    TEST_ASSERT_TRUE(expectedUpper.complete());

    const char* mismatches[] = {"batterysentinel", "batterysentinel.loca", "batterysentinel.local.evil",
        "xbatterysentinel.local", "*.local", "https://batterysentinel.local", "batterysentinel.local.",
        "192.168.4.1", "orion.local", ""};
    for (const auto* mismatch : mismatches) {
        CertificateNames rejected(bs::kServiceDnsName);
        addIp(rejected);
        addDns(rejected, mismatch);
        TEST_ASSERT_FALSE_MESSAGE(rejected.complete(), mismatch);
    }
}

void test_correct_bytes_in_wrong_san_types_do_not_match() {
    for (int tag : {0x02, 0x16, 0x81, 0x86, 0xa2, 0x87}) {
        CertificateNames names(bs::kServiceDnsName);
        addIp(names);
        addDns(names, bs::kServiceDnsName, tag);
        TEST_ASSERT_FALSE(names.complete());
    }
    for (int tag : {0x04, 0x82, 0x86, 0xa7}) {
        CertificateNames names(bs::kServiceDnsName);
        addDns(names);
        names.add(tag, bs::tls::kServiceIpv4.data(), bs::tls::kServiceIpv4.size());
        TEST_ASSERT_FALSE(names.complete());
    }
}

void test_malformed_and_textual_ip_entries_do_not_match() {
    const uint8_t wrong[] = {192, 168, 4, 2};
    const uint8_t longIp[] = {192, 168, 4, 1, 0};
    const uint8_t mapped[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xff, 0xff, 192, 168, 4, 1};
    const char* textual = "192.168.4.1";
    CertificateNames names(bs::kServiceDnsName);
    addDns(names);
    names.add(0x87, wrong, sizeof(wrong));
    names.add(0x87, longIp, sizeof(longIp));
    names.add(0x87, bs::tls::kServiceIpv4.data(), 3);
    names.add(0x87, mapped, sizeof(mapped));
    names.add(0x87, reinterpret_cast<const uint8_t*>(textual), std::strlen(textual));
    TEST_ASSERT_FALSE(names.complete());
    addIp(names);
    TEST_ASSERT_TRUE(names.complete());
}

void test_null_truncated_and_embedded_nul_names_do_not_match() {
    CertificateNames names(bs::kServiceDnsName);
    addIp(names);
    names.add(0x82, nullptr, std::strlen(bs::kServiceDnsName));
    names.add(0x82, reinterpret_cast<const uint8_t*>(bs::kServiceDnsName), 0);
    names.add(0x82, reinterpret_cast<const uint8_t*>(bs::kServiceDnsName), std::strlen(bs::kServiceDnsName) - 1);
    names.add(0x82, reinterpret_cast<const uint8_t*>(bs::kServiceDnsName), sizeof(bs::kServiceDnsName));
    std::array<uint8_t, sizeof(bs::kServiceDnsName) - 1> embedded{};
    std::memcpy(embedded.data(), bs::kServiceDnsName, embedded.size());
    embedded[5] = 0;
    names.add(0x82, embedded.data(), embedded.size());
    TEST_ASSERT_FALSE(names.complete());
    addDns(names);
    TEST_ASSERT_TRUE(names.complete());

    for (const char* expected : {static_cast<const char*>(nullptr), ""}) {
        CertificateNames absent(expected);
        addDns(absent);
        addIp(absent);
        TEST_ASSERT_FALSE(absent.complete());
    }
}

void test_unrelated_entries_do_not_hide_required_names() {
    CertificateNames names(bs::kServiceDnsName);
    addDns(names, "unrelated.example");
    addDns(names, "https://batterysentinel.local", 0x86);
    names.add(0x87, nullptr, 4);
    addDns(names);
    addIp(names);
    addDns(names, "second.example");
    TEST_ASSERT_TRUE(names.complete());
}

int main(int argc, char** argv) {
    // Export the exact production builder bytes for external OpenSSL ASN.1 QA.
    if (argc == 3 && std::string(argv[1]) == "--export-der") {
        std::ofstream file(argv[2], std::ios::binary);
        file.write(reinterpret_cast<const char*>(serviceSan.data()), serviceSan.size());
        return file ? 0 : 1;
    }
    UNITY_BEGIN();
    RUN_TEST(test_der_contains_dns_and_binary_ipv4_without_terminating_nul);
    RUN_TEST(test_requires_both_san_types_in_either_order);
    RUN_TEST(test_dns_match_is_case_insensitive_and_exact);
    RUN_TEST(test_correct_bytes_in_wrong_san_types_do_not_match);
    RUN_TEST(test_malformed_and_textual_ip_entries_do_not_match);
    RUN_TEST(test_null_truncated_and_embedded_nul_names_do_not_match);
    RUN_TEST(test_unrelated_entries_do_not_hide_required_names);
    return UNITY_END();
}
