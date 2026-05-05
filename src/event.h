#pragma once
#include <string>
#include <vector>

enum class Policy { Hard, Soft, Flexible };

struct Event {
    int id;
    long long start;  // Unix timestamp 或分鐘數
    long long end;
    std::string title;
    Policy policy;
    std::vector<std::string> tags;
    
    Event(int i, long long s, long long e, std::string t, Policy p, std::vector<std::string> tg = {})
        : id(i), start(s), end(e), title(std::move(t)), policy(p), tags(std::move(tg)) {}
};