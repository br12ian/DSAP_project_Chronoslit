#include <iostream>
#include <chrono>
#include <vector>
#include <random>
#include "interval_tree.h"
#include "event.h"

std::vector<Event> bruteForceCheckOverlap(const std::vector<Event>& allEvents, long long start, long long end) {
    std::vector<Event> results;
    for (const auto& ev : allEvents) {
        if (!(ev.end <= start || ev.start >= end)) {
            results.push_back(ev);
        }
    }
    return results;
}

void runBenchmark(int dataSize) {
    std::cout << "--------------------------------------------------\n";
    std::cout << "開始進行測試 ➔ 樣本規模: " << dataSize << " 筆行程\n";
    std::cout << "--------------------------------------------------\n";

    std::random_device rd;
    std::mt19937 gen(rd());
    
    // 💡 修正二：將時間軸放大到一整年（365天 * 1440分鐘 = 525600分鐘），模擬真實稀疏行事曆
    long long totalMinutesInYear = 365 * 1440;
    std::uniform_int_distribution<long long> distTime(0, totalMinutesInYear - 120);
    std::uniform_int_distribution<long long> distDuration(30, 120);

    IntervalTree tree;             
    std::vector<Event> bruteForceVector; 

    // 1. 測試：大規模插入效能
    auto startInsert = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < dataSize; ++i) {
        long long startTime = distTime(gen);
        long long endTime = startTime + distDuration(gen);
        
        Event ev(i, startTime, endTime, QString("BenchmarkEvent"), Policy::Soft);
        tree.insert(ev);
        bruteForceVector.push_back(ev);
    }
    auto endInsert = std::chrono::high_resolution_clock::now();
    auto durationInsert = std::chrono::duration_cast<std::chrono::microseconds>(endInsert - startInsert).count();
    std::cout << "➔ [區間樹] 總插入耗時: " << durationInsert << " 微秒 (平均每筆: " 
              << (double)durationInsert / dataSize << " 微秒)\n";

    // 2. 測試：隨機某一天的某時段查詢（黃金對決）
    long long testStart = 200 * 1440 + 840; // 第 200 天的 14:00
    long long testEnd = 200 * 1440 + 960;   // 第 200 天的 16:00

    // --- (A) 區間樹查詢 ---
    auto startTreeQuery = std::chrono::high_resolution_clock::now();
    auto treeResults = tree.query(testStart, testEnd);
    auto endTreeQuery = std::chrono::high_resolution_clock::now();
    auto durationTreeQuery = std::chrono::duration_cast<std::chrono::nanoseconds>(endTreeQuery - startTreeQuery).count();

    // --- (B) 傳統法暴力遍歷 ---
    auto startBruteQuery = std::chrono::high_resolution_clock::now();
    auto bruteResults = bruteForceCheckOverlap(bruteForceVector, testStart, testEnd);
    auto endBruteQuery = std::chrono::high_resolution_clock::now();
    auto durationBruteQuery = std::chrono::duration_cast<std::chrono::nanoseconds>(endBruteQuery - startBruteQuery).count();

    std::cout << "➔ [區間樹] 單次查詢耗時: " << durationTreeQuery << " 奈秒 (找到 " << treeResults.size() << " 筆)\n";
    std::cout << "➔ [傳統法] 暴力查詢耗時: " << durationBruteQuery << " 奈秒 (找到 " << bruteResults.size() << " 筆)\n";
    
    if (durationTreeQuery > 0) {
        std::cout << "演算法效能差距: 區間樹比傳統暴力法快了 " 
                  << (double)durationBruteQuery / durationTreeQuery << " 倍！\n\n";
    }
}

int main() {
    std::cout << "==================================================\n";
    std::cout << "ChronoSlit 區間樹演算法效能測試啟動\n";
    std::cout << "==================================================\n\n";

    runBenchmark(100);       
    runBenchmark(1000);      
    runBenchmark(10000);     
    runBenchmark(100000);    // 十萬筆壓力測試

    std::cout << "==================================================\n";
    return 0;
}