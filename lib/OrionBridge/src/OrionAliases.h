#pragma once

#include <cstddef>
#include <cstdint>
#include <cstring>

namespace bs::orion {

constexpr size_t kAliasMaxCharacters = 32;
constexpr size_t kAliasMaxBytes = kAliasMaxCharacters * 4;
constexpr const char* kDefaultInputAlias = "Startbatterie";
constexpr const char* kDefaultOutputAlias = "Bugbatterie";

struct Aliases {
    char input[kAliasMaxBytes + 1]{};
    char output[kAliasMaxBytes + 1]{};
};

inline bool aliasWhitespace(unsigned char c) {
    return c == 0x20 || (c >= 0x09 && c <= 0x0d);
}

// Strict UTF-8 scalar decoding: reject malformed, overlong, surrogate and
// out-of-range encodings instead of treating their bytes as alias characters.
inline bool aliasCodepoint(const char* text, size_t length, size_t& position, uint32_t& out) {
    if (position >= length) return false;
    const uint8_t first = static_cast<uint8_t>(text[position++]);
    if (first < 0x80) { out = first; return true; }
    const size_t continuation = first >= 0xc2 && first <= 0xdf ? 1 :
        first >= 0xe0 && first <= 0xef ? 2 : first >= 0xf0 && first <= 0xf4 ? 3 : 0;
    if (!continuation || length - position < continuation) return false;
    uint32_t value = first & (0x7f >> continuation >> 1);
    for (size_t i = 0; i < continuation; ++i) {
        const uint8_t byte = static_cast<uint8_t>(text[position++]);
        if ((byte & 0xc0) != 0x80) return false;
        value = (value << 6) | (byte & 0x3f);
    }
    if ((continuation == 1 && value < 0x80) ||
        (continuation == 2 && value < 0x800) ||
        (continuation == 3 && value < 0x10000) ||
        (value >= 0xd800 && value <= 0xdfff) || value > 0x10ffff) return false;
    out = value;
    return true;
}

// Preserve spelling, trim outer ASCII whitespace, then count Unicode scalar
// values (not UTF-8 bytes or UTF-16 code units). No general NFC normalization.
inline bool normalizeAlias(const char* input, size_t length, char (&out)[kAliasMaxBytes + 1]) {
    if (!input) return false;
    while (length && aliasWhitespace(static_cast<unsigned char>(*input))) { ++input; --length; }
    while (length && aliasWhitespace(static_cast<unsigned char>(input[length - 1]))) --length;
    if (!length || length > kAliasMaxBytes) return false;
    size_t position = 0, characters = 0;
    while (position < length) {
        uint32_t cp;
        if (!aliasCodepoint(input, length, position, cp) ||
            cp < 0x20 || (cp >= 0x7f && cp <= 0x9f) || cp == 0x2028 || cp == 0x2029 ||
            ++characters > kAliasMaxCharacters) return false;
    }
    std::memcpy(out, input, length);
    out[length] = '\0';
    return true;
}

inline uint32_t foldAliasCodepoint(uint32_t cp) {
    if ((cp >= 'A' && cp <= 'Z') || cp == 0x00c4 || cp == 0x00d6 || cp == 0x00dc)
        return cp + 0x20;
    return cp == 0x1e9e ? 0x00df : cp;
}

inline bool sameAlias(const char* left, const char* right) {
    const size_t leftLength = std::strlen(left), rightLength = std::strlen(right);
    size_t leftPosition = 0, rightPosition = 0;
    while (leftPosition < leftLength && rightPosition < rightLength) {
        uint32_t leftCp, rightCp;
        if (!aliasCodepoint(left, leftLength, leftPosition, leftCp) ||
            !aliasCodepoint(right, rightLength, rightPosition, rightCp) ||
            foldAliasCodepoint(leftCp) != foldAliasCodepoint(rightCp)) return false;
    }
    return leftPosition == leftLength && rightPosition == rightLength;
}

// Validate the pair completely before writing either normalized result.
inline bool normalizeAliases(const char* input, size_t inputLength,
                             const char* output, size_t outputLength, Aliases& out) {
    Aliases candidate;
    if (!normalizeAlias(input, inputLength, candidate.input) ||
        !normalizeAlias(output, outputLength, candidate.output) ||
        sameAlias(candidate.input, candidate.output)) return false;
    out = candidate;
    return true;
}

} // namespace bs::orion
