#pragma once

#include <stddef.h>
#include <stdint.h>
#include <string.h>

namespace bs {
namespace ota {

// Streaming validation of an unsigned ESP-IDF ESP32-C3 application image.
// Layout matches esp_app_format.h: 24-byte image header, 8-byte segment
// headers, a 256-byte app descriptor at the start of segment zero, checksum
// at the end of a 16-byte block, and a mandatory appended SHA-256 digest.
// This detects corruption and product mismatch; it is not a signature check.
// The caller supplies SHA-256 and still uses the ESP-IDF OTA finalization API
// to verify hardware revision and bootloader-specific image requirements.
class ImageValidator {
public:
    static constexpr size_t DigestSize = 32;
    static constexpr size_t DescriptorSize = 256;

    ImageValidator(const char* expectedProject, size_t maximumImageBytes)
        : maximumImageBytes_(maximumImageBytes) {
        size_t length = 0;
        if (expectedProject) {
            while (length < sizeof(expectedProject_) && expectedProject[length]) ++length;
        }
        if (!length || length >= sizeof(expectedProject_)) {
            fail(Error::InvalidTarget);
            return;
        }
        memcpy(expectedProject_, expectedProject, length);
        if (maximumImageBytes_ < 24 + 8 + DescriptorSize + 16 + DigestSize) {
            fail(Error::TooLarge);
        }
    }

    // Feed each byte exactly once. On success, hashBytes is the length of the
    // contiguous prefix of THIS input to pass to SHA-256. The appended digest
    // is deliberately excluded, even when a chunk crosses its boundary.
    bool write(const uint8_t* data, size_t length, size_t& hashBytes) {
        hashBytes = 0;
        if (error_ != Error::None) return false;
        if (length && !data) return fail(Error::InvalidInput);
        if (length > maximumImageBytes_ - received_) return fail(Error::TooLarge);
        for (size_t i = 0; i < length; ++i) {
            if (stage_ == Stage::Complete) return fail(Error::TrailingData);
            if (stage_ != Stage::Digest) ++hashBytes;
            ++received_;
            if (!consume(data[i])) return false;
        }
        return true;
    }

    // Call after EOF and after finishing SHA-256 over every hashBytes prefix.
    // No image is valid until this succeeds. A syntax-complete image alone
    // must never be selected as the next boot partition.
    bool finish(const uint8_t computedSha256[DigestSize]) {
        if (error_ != Error::None) return false;
        if (stage_ != Stage::Complete) return fail(Error::Truncated);
        if (!computedSha256) return fail(Error::InvalidInput);
        uint8_t different = 0;
        for (size_t i = 0; i < DigestSize; ++i) {
            different |= expectedDigest_[i] ^ computedSha256[i];
        }
        if (different) return fail(Error::DigestMismatch);
        valid_ = true;
        return true;
    }

    bool targetVerified() const { return targetVerified_; }
    bool valid() const { return valid_; }
    size_t bytesReceived() const { return received_; }
    const uint8_t* expectedDigest() const { return expectedDigest_; }
    const char* firmwareVersion() const { return firmwareVersion_; }

    const char* errorCode() const {
        switch (error_) {
        case Error::None: return "";
        case Error::InvalidTarget:
        case Error::WrongChip:
        case Error::WrongProject: return "target";
        case Error::TooLarge: return "size";
        case Error::ChecksumMismatch: return "checksum";
        case Error::MissingDigest:
        case Error::DigestMismatch: return "hash";
        default: return "image";
        }
    }

    const char* errorMessage() const {
        switch (error_) {
        case Error::None: return "";
        case Error::InvalidInput: return "Invalid firmware input.";
        case Error::InvalidTarget: return "The expected firmware target is invalid.";
        case Error::BadMagic: return "Select an application firmware .bin file.";
        case Error::BadSegmentCount: return "The firmware segment count is invalid.";
        case Error::WrongChip: return "The firmware is not for an ESP32-C3.";
        case Error::UnsupportedFlash: return "The firmware requires unsupported flash settings.";
        case Error::MissingDigest: return "The firmware has no supported SHA-256 integrity digest.";
        case Error::TooLarge: return "The firmware exceeds the allowed image size.";
        case Error::BadSegment: return "The firmware segment layout is invalid.";
        case Error::BadDescriptor: return "The firmware application descriptor is missing or invalid.";
        case Error::WrongProject: return "The firmware is for a different product.";
        case Error::BadPadding: return "The firmware image padding is invalid.";
        case Error::ChecksumMismatch: return "The firmware checksum does not match.";
        case Error::DigestMismatch: return "The firmware SHA-256 digest does not match.";
        case Error::Truncated: return "The firmware upload is incomplete.";
        case Error::TrailingData: return "The file contains data after the firmware image.";
        }
        return "The firmware is invalid.";
    }

private:
    enum class Stage { Header, SegmentHeader, SegmentData, Padding, Checksum, Digest, Complete };
    enum class Error {
        None, InvalidInput, InvalidTarget, BadMagic, BadSegmentCount,
        WrongChip, UnsupportedFlash, MissingDigest, TooLarge, BadSegment,
        BadDescriptor, WrongProject, BadPadding, ChecksumMismatch,
        DigestMismatch, Truncated, TrailingData
    };

    static uint32_t little32(const uint8_t* bytes) {
        return static_cast<uint32_t>(bytes[0]) |
               (static_cast<uint32_t>(bytes[1]) << 8) |
               (static_cast<uint32_t>(bytes[2]) << 16) |
               (static_cast<uint32_t>(bytes[3]) << 24);
    }

    bool fail(Error error) {
        if (error_ == Error::None) error_ = error;
        valid_ = false;
        return false;
    }

    bool imageHeader() {
        if (scratch_[0] != 0xe9) return fail(Error::BadMagic);
        segmentCount_ = scratch_[1];
        if (!segmentCount_ || segmentCount_ > 16) return fail(Error::BadSegmentCount);
        if (scratch_[12] != 5 || scratch_[13] != 0) return fail(Error::WrongChip);
        const uint8_t flashSpeed = scratch_[3] & 0x0f;
        if ((scratch_[3] >> 4) != 2 || scratch_[2] > 5 ||
            (flashSpeed > 2 && flashSpeed != 0x0f)) {
            return fail(Error::UnsupportedFlash);
        }
        if (scratch_[23] != 1) return fail(Error::MissingDigest);
        fieldUsed_ = 0;
        stage_ = Stage::SegmentHeader;
        return true;
    }

    bool segmentHeader() {
        segmentLength_ = little32(scratch_ + 4);
        // Use subtraction so an adversarial 32-bit segment length cannot wrap.
        const size_t room = maximumImageBytes_ - received_;
        const size_t followingHeaders = static_cast<size_t>(segmentCount_ - segmentIndex_ - 1) * 8;
        if (room < followingHeaders + 1 + DigestSize ||
            segmentLength_ > room - followingHeaders - 1 - DigestSize) {
            return fail(Error::TooLarge);
        }
        if ((segmentLength_ & 3) || segmentLength_ >= 0x1000000U) return fail(Error::BadSegment);
        if (!segmentIndex_ && segmentLength_ < DescriptorSize) return fail(Error::BadDescriptor);
        if (!segmentIndex_) {
            const uint32_t address = little32(scratch_);
            if (address < 0x3c000000U || address >= 0x3c800000U ||
                segmentLength_ > 0x3c800000U - address) {
                return fail(Error::BadDescriptor);
            }
        }
        remainingSegmentBytes_ = segmentLength_;
        fieldUsed_ = 0;
        stage_ = Stage::SegmentData;
        if (!remainingSegmentBytes_) endSegment();
        return true;
    }

    bool descriptor() {
        // The entire fixed-width name must be NUL-terminated and match exactly.
        const uint8_t* project = scratch_ + 48;
        size_t length = 0;
        while (length < 32 && project[length]) ++length;
        if (length == 32 || length != strlen(expectedProject_) ||
            memcmp(project, expectedProject_, length) != 0) {
            return fail(Error::WrongProject);
        }
        size_t versionLength = 0;
        while (versionLength < 32 && scratch_[16 + versionLength]) {
            const uint8_t character = scratch_[16 + versionLength];
            if (character < 0x20 || character > 0x7e) return fail(Error::BadDescriptor);
            ++versionLength;
        }
        if (!versionLength || versionLength == 32) return fail(Error::BadDescriptor);
        memcpy(firmwareVersion_, scratch_ + 16, versionLength);
        targetVerified_ = true;
        return true;
    }

    void endSegment() {
        ++segmentIndex_;
        fieldUsed_ = 0;
        if (segmentIndex_ < segmentCount_) {
            stage_ = Stage::SegmentHeader;
        } else {
            // The XOR checksum is the last byte of the next 16-byte block.
            paddingBytes_ = 15 - (received_ & 15);
            stage_ = paddingBytes_ ? Stage::Padding : Stage::Checksum;
        }
    }

    bool consume(uint8_t value) {
        switch (stage_) {
        case Stage::Header:
            scratch_[fieldUsed_++] = value;
            return fieldUsed_ != 24 || imageHeader();
        case Stage::SegmentHeader:
            scratch_[fieldUsed_++] = value;
            return fieldUsed_ != 8 || segmentHeader();
        case Stage::SegmentData:
            checksum_ ^= value;
            if (!segmentIndex_ && fieldUsed_ < sizeof(scratch_)) {
                scratch_[fieldUsed_++] = value;
                if (fieldUsed_ == 4 && little32(scratch_) != 0xabcd5432U) return fail(Error::BadDescriptor);
                if (fieldUsed_ == sizeof(scratch_) && !descriptor()) return false;
            }
            if (!--remainingSegmentBytes_) endSegment();
            return true;
        case Stage::Padding:
            if (value != 0) return fail(Error::BadPadding);
            if (!--paddingBytes_) stage_ = Stage::Checksum;
            return true;
        case Stage::Checksum:
            if (value != checksum_) return fail(Error::ChecksumMismatch);
            stage_ = Stage::Digest;
            fieldUsed_ = 0;
            return true;
        case Stage::Digest:
            expectedDigest_[fieldUsed_++] = value;
            if (fieldUsed_ == DigestSize) stage_ = Stage::Complete;
            return true;
        case Stage::Complete:
            return fail(Error::TrailingData);
        }
        return fail(Error::InvalidInput);
    }

    size_t maximumImageBytes_;
    size_t received_ = 0;
    size_t paddingBytes_ = 0;
    uint32_t segmentLength_ = 0;
    uint32_t remainingSegmentBytes_ = 0;
    uint8_t segmentCount_ = 0;
    uint8_t segmentIndex_ = 0;
    size_t fieldUsed_ = 0;
    uint8_t checksum_ = 0xef;
    uint8_t scratch_[80] = {};
    uint8_t expectedDigest_[DigestSize] = {};
    char expectedProject_[32] = {};
    char firmwareVersion_[33] = {};
    Stage stage_ = Stage::Header;
    Error error_ = Error::None;
    bool targetVerified_ = false;
    bool valid_ = false;
};

} // namespace ota
} // namespace bs
