#pragma once
#include <QJsonArray>
#include <vector>
#include "event.h"

struct ITNode {
    Event event;
    long long max_end;
    ITNode* left;
    ITNode* right;

    ITNode(const Event& e) 
        : event(e), max_end(e.end), left(nullptr), right(nullptr) {}
};

class IntervalTree {
public:
    IntervalTree();
    ~IntervalTree();

    bool insert(const Event& e);
    void clear();
    QJsonArray exportToJsonArray() const;
    std::vector<Event> query(long long start, long long end) const;

private:
    ITNode* root_;

    ITNode* insertHelper_(ITNode* node, const Event& e, bool& success);
    void clearHelper_(ITNode* node);
    void exportHelper_(ITNode* node, QJsonArray& array) const;
    void queryHelper_(ITNode* node, long long start, long long end, std::vector<Event>& result) const;
    long long getMaxEnd_(ITNode* node);
};