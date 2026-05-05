#include "interval_tree.h"
#include <iostream>
#include <algorithm>

IntervalTree::~IntervalTree() {
    destroy_(root_);
}

void IntervalTree::destroy_(ITNode* node) {
    if (!node) return;
    destroy_(node->left);
    destroy_(node->right);
    delete node;
}

void IntervalTree::updateMax_(ITNode* node) {
    if (!node) return;
    node->max_end = node->event.end;
    if (node->left)  node->max_end = std::max(node->max_end, node->left->max_end);
    if (node->right) node->max_end = std::max(node->max_end, node->right->max_end);
}

bool IntervalTree::insert(const Event& e) {
    bool success = true;
    root_ = insert_(root_, e, success);
    return success;
}

ITNode* IntervalTree::insert_(ITNode* node, const Event& e, bool& success) {
    if (!node) {
        success = true; // 成功找到空位插入
        return new ITNode(e);
    }

    // --- 關鍵：衝突檢查 ---
    // 💡 判斷重疊的邏輯：新事件的起點早於舊事件的終點，且舊事件的起點早於新事件的終點
    bool isOverlap = (e.start < node->event.end) && (node->event.start < e.end);

    // 如果新事件是 Hard，且目前節點重疊，且該節點也是 Hard，就拒絕插入
    if (e.policy == Policy::Hard && isOverlap && node->event.policy == Policy::Hard) {
        success = false;
        return node;
    }

    // 標準 BST 插入邏輯
    if (e.start < node->event.start) {
        node->left = insert_(node->left, e, success);
    } else {
        node->right = insert_(node->right, e, success);
    }

    // 只有成功插入才更新 max_end
    if (success) {
        updateMax_(node);
    }
    
    return node;
}

std::vector<Event> IntervalTree::query(long long start, long long end) const {
    std::vector<Event> result;
    query_(root_, start, end, result);
    return result;
}

void IntervalTree::query_(ITNode* node, long long qs, long long qe, std::vector<Event>& result) const {
    if (!node) return;
    
    // 檢查當前節點是否重疊
    if (!(node->event.end <= qs || node->event.start >= qe)) {
        result.push_back(node->event);
    }
    
    // 左子樹可能有重疊
    if (node->left && node->left->max_end > qs) {
        query_(node->left, qs, qe, result);
    }
    
    // 右子樹可能有重疊
    if (node->event.start < qe) {
        query_(node->right, qs, qe, result);
    }
}

void IntervalTree::print() const {
    print_(root_, 0);
}

void IntervalTree::print_(ITNode* node, int depth) const {
    if (!node) return;
    print_(node->right, depth + 1);
    for (int i = 0; i < depth; i++) std::cout << "    ";
    std::cout << "[" << node->event.start << "," << node->event.end << "] " 
              << node->event.title << " (max=" << node->max_end << ")\n";
    print_(node->left, depth + 1);
}