#pragma once
#include "event.h"
#include <vector>
#include <optional>

struct ITNode {
    Event event;
    long long max_end;
    ITNode* left = nullptr;
    ITNode* right = nullptr;
    
    ITNode(const Event& e) : event(e), max_end(e.end) {}
};

class IntervalTree {
public:
    IntervalTree() = default;
    ~IntervalTree();
    
    bool insert(const Event& e);
    std::vector<Event> query(long long start, long long end) const;
    void print() const;  // 除錯用
    
private:
    ITNode* root_ = nullptr;
    
    ITNode* insert_(ITNode* node, const Event& e, bool& success);
    void query_(ITNode* node, long long qs, long long qe, std::vector<Event>& result) const;
    void destroy_(ITNode* node);
    void print_(ITNode* node, int depth) const;
    void updateMax_(ITNode* node);
};