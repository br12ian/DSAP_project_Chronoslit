#include "interval_tree.h"
#include <algorithm>
#include <iostream>

IntervalTree::IntervalTree() : root_(nullptr) {}

IntervalTree::~IntervalTree() {
    clear();
}

void IntervalTree::clear() {
    clearHelper_(root_);
    root_ = nullptr;
}

void IntervalTree::clearHelper_(ITNode* node) {
    if (!node) return;
    clearHelper_(node->left);
    clearHelper_(node->right);
    delete node;
}

long long IntervalTree::getMaxEnd_(ITNode* node) {
    if (!node) return 0;
    return node->max_end;
}

bool IntervalTree::insert(const Event& e) {
    // 檢查是否有 Hard 衝突
    if (e.policy == Policy::Hard) {
        std::vector<Event> conflicts = query(e.start, e.end);
        for (const auto& conflict : conflicts) {
            if (conflict.policy == Policy::Hard) {
                return false; // 衝堂，拒絕插入
            }
        }
    }
    
    bool success = false;
    root_ = insertHelper_(root_, e, success);
    return success;
}

ITNode* IntervalTree::insertHelper_(ITNode* node, const Event& e, bool& success) {
    if (!node) {
        success = true;
        return new ITNode(e);
    }

    if (e.start < node->event.start) {
        node->left = insertHelper_(node->left, e, success);
    } else {
        node->right = insertHelper_(node->right, e, success);
    }

    // 更新 max_end
    node->max_end = std::max({node->event.end, getMaxEnd_(node->left), getMaxEnd_(node->right)});
    return node;
}

QJsonArray IntervalTree::exportToJsonArray() const {
    QJsonArray array;
    exportHelper_(root_, array);
    return array;
}

void IntervalTree::exportHelper_(ITNode* node, QJsonArray& array) const {
    if (!node) return;
    exportHelper_(node->left, array);
    array.append(node->event.toJson());
    exportHelper_(node->right, array);
}

std::vector<Event> IntervalTree::query(long long start, long long end) const {
    std::vector<Event> result;
    queryHelper_(root_, start, end, result);
    return result;
}

void IntervalTree::queryHelper_(ITNode* node, long long start, long long end, std::vector<Event>& result) const {
    if (!node) return;

    // 判斷重疊條件
    if (node->event.start < end && node->event.end > start) {
        result.push_back(node->event);
    }

    if (node->left && node->left->max_end > start) {
        queryHelper_(node->left, start, end, result);
    }

    if (node->right && node->event.start < end) {
        queryHelper_(node->right, start, end, result);
    }
}