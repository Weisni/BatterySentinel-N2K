// Exercise the production PBKDF2/HMAC implementation with a system SHA backend.
// g++ -std=c++17 -Wall -Wextra -Werror -Ilib/BridgeAuth/src tools/check_password_hash.cpp -o check_password_hash
// On Linux versions before glibc 2.34, add -ldl for dynamic library functions.
#include <BridgePasswordHash.h>
#include "password_hash_test_backend.h"

#include <array>
#include <iomanip>
#include <iostream>
#include <limits>
#include <string>
#include <vector>

namespace {

bool decode(const std::string& hex, std::vector<uint8_t>& bytes) {
    if ((hex.size() % 2) || hex.find_first_not_of("0123456789abcdefABCDEF") != std::string::npos) return false;
    for (size_t offset = 0; offset < hex.size(); offset += 2) {
        bytes.push_back(static_cast<uint8_t>(std::stoul(hex.substr(offset, 2), nullptr, 16)));
    }
    return true;
}

} // namespace

int main(int argc, char** argv) {
    if (argc != 4) {
        std::cerr << "Usage: check_password_hash PASSWORD_HEX SALT_HEX ITERATIONS\n";
        return 2;
    }
    std::vector<uint8_t> password, salt;
    const std::string rounds(argv[3]);
    uint32_t iterations = 0;
    if (!decode(argv[1], password) || !decode(argv[2], salt) || salt.size() != bs::auth::kSaltBytes ||
        rounds.empty() || rounds.find_first_not_of("0123456789") != std::string::npos) {
        std::cerr << "Invalid hexadecimal password, 16-byte salt or iteration count.\n";
        return 2;
    }
    try {
        const auto value = std::stoull(rounds);
        if (value > std::numeric_limits<uint32_t>::max()) throw std::out_of_range("iterations");
        iterations = static_cast<uint32_t>(value);
    } catch (const std::exception&) {
        std::cerr << "Iteration count exceeds the unsigned 32-bit range.\n";
        return 2;
    }
    if (!password_hash_test::available()) {
        std::cerr << password_hash_test::backendError() << '\n';
        return 2;
    }
    std::array<uint8_t, bs::auth::kHashBytes> output{};
    if (!bs::auth::passwordHash<password_hash_test::Sha256>(password.data(), password.size(),
            salt.data(), iterations, output.data())) {
        std::cerr << "Password derivation failed.\n";
        return 1;
    }
    for (const auto byte : output) std::cout << std::hex << std::setfill('0') << std::setw(2) << static_cast<unsigned int>(byte);
    std::cout << '\n';
    return 0;
}
