// Host-side entry point for exercising the actual device image validator.
// Compile with: g++ -std=c++17 -Ilib/FirmwareOta/src tools/check_ota_image.cpp -o check_ota_image
// Supply SHA-256 calculated independently over the image excluding its last
// 32 bytes. Requiring the digest avoids silently validating it against itself.
#include <FirmwareOta.h>

#include <fstream>
#include <iostream>
#include <limits>
#include <string>

int main(int argc, char** argv) {
    if (argc != 4) {
        std::cerr << "Usage: check_ota_image FIRMWARE.bin EXPECTED_PROJECT COMPUTED_SHA256_HEX\n";
        return 2;
    }
    const std::string digestHex(argv[3]);
    uint8_t digest[bs::ota::ImageValidator::DigestSize] = {};
    if (digestHex.size() != sizeof(digest) * 2 || digestHex.find_first_not_of("0123456789abcdefABCDEF") != std::string::npos) {
        std::cerr << "The computed SHA-256 must contain exactly 64 hexadecimal characters.\n";
        return 2;
    }
    for (size_t i = 0; i < sizeof(digest); ++i) {
        digest[i] = static_cast<uint8_t>(std::stoul(digestHex.substr(i * 2, 2), nullptr, 16));
    }
    std::ifstream file(argv[1], std::ios::binary | std::ios::ate);
    if (!file) {
        std::cerr << "Cannot open firmware file.\n";
        return 2;
    }
    const std::streamoff fileSize = file.tellg();
    if (fileSize < 0 || static_cast<uint64_t>(fileSize) > std::numeric_limits<size_t>::max()) {
        std::cerr << "Cannot determine firmware file size.\n";
        return 2;
    }
    file.seekg(0);
    bs::ota::ImageValidator validator(argv[2], static_cast<size_t>(fileSize));
    uint8_t chunk[4096];
    size_t totalHashBytes = 0;
    while (file.read(reinterpret_cast<char*>(chunk), sizeof(chunk)) || file.gcount()) {
        size_t hashBytes = 0;
        if (!validator.write(chunk, static_cast<size_t>(file.gcount()), hashBytes)) {
            std::cerr << validator.errorCode() << ": " << validator.errorMessage() << '\n';
            return 1;
        }
        totalHashBytes += hashBytes;
    }
    if (!file.eof()) {
        std::cerr << "Could not read the complete firmware file.\n";
        return 2;
    }
    if (!validator.finish(digest)) {
        std::cerr << validator.errorCode() << ": " << validator.errorMessage() << '\n';
        return 1;
    }
    std::cout << "Valid " << argv[2] << " firmware " << validator.firmwareVersion()
              << ": " << validator.bytesReceived() << " bytes, " << totalHashBytes << " hashed bytes.\n";
    return 0;
}
