#pragma once
#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>
struct SerialFixture {
    std::vector<std::string> lines;
    void println(const char* line) { lines.emplace_back(line); }
};
inline SerialFixture Serial;
