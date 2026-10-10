#pragma once

#include <cstddef>
#include <cstring>

namespace bs::orion {

inline bool macWhitespace(char c) {
    return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}

// Accept compact hex or six octets separated consistently by colons, hyphens,
// or whitespace. Only write the canonical lowercase address after validation.
inline bool normalizeMac(const char* input, size_t length, char (&out)[18]) {
    if (!input) return false;
    while (length && macWhitespace(*input)) {
        ++input;
        --length;
    }
    while (length && macWhitespace(input[length - 1])) --length;

    const bool compact = length == 12;
    char normalized[18]{};
    char separator = 0;
    size_t position = 0;
    for (size_t octet = 0; octet < 6; ++octet) {
        if (octet && !compact) {
            if (position >= length) return false;
            const char current = input[position];
            const char kind = macWhitespace(current) ? ' ' : current;
            if (kind != ':' && kind != '-' && kind != ' ') return false;
            if (separator && separator != kind) return false;
            separator = kind;
            ++position;
            if (kind == ' ')
                while (position < length && macWhitespace(input[position])) ++position;
        }
        for (size_t digit = 0; digit < 2; ++digit) {
            if (position >= length) return false;
            char c = input[position++];
            if (c >= 'A' && c <= 'F') c += 'a' - 'A';
            if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))) return false;
            normalized[octet * 3 + digit] = c;
        }
        if (octet < 5) normalized[octet * 3 + 2] = ':';
    }
    if (position != length) return false;
    std::memcpy(out, normalized, sizeof(normalized));
    return true;
}

} // namespace bs::orion
