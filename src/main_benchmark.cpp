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
    std::cout << "Launching Benchmark ➔ Dataset Size: " << dataSize << " events\n";
    std::cout << "--------------------------------------------------\n";

    std::random_device rd;
    std::mt19937 gen(rd());
    
    // Scale timeline to 1 full year (365 days * 1440 minutes = 525,600 minutes)
    long long totalMinutesInYear = 365 * 1440;
    std::uniform_int_distribution<long long> distTime(0, totalMinutesInYear - 120);
    std::uniform_int_distribution<long long> distDuration(30, 120);

    IntervalTree tree;             
    std::vector<Event> bruteForceVector; 

    // 1. Benchmark: Large-scale Insertion Performance
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
    std::cout << "➔ [Interval Tree] Total Insertion: " << durationInsert << " us (Avg per entry: " 
              << (double)durationInsert / dataSize << " us)\n";

    // 2. Benchmark: Random Single Window Query (Head-to-Head)
    long long testStart = 200 * 1440 + 840; // Day 200, 14:00
    long long testEnd = 200 * 1440 + 960;   // Day 200, 16:00

    // --- (A) Interval Tree Query ---
    auto startTreeQuery = std::chrono::high_resolution_clock::now();
    auto treeResults = tree.query(testStart, testEnd);
    auto endTreeQuery = std::chrono::high_resolution_clock::now();
    auto durationTreeQuery = std::chrono::duration_cast<std::chrono::nanoseconds>(endTreeQuery - startTreeQuery).count();

    // --- (B) Brute Force Linear Scan ---
    auto startBruteQuery = std::chrono::high_resolution_clock::now();
    auto bruteResults = bruteForceCheckOverlap(bruteForceVector, testStart, testEnd);
    auto endBruteQuery = std::chrono::high_resolution_clock::now();
    auto durationBruteQuery = std::chrono::duration_cast<std::chrono::nanoseconds>(endBruteQuery - startBruteQuery).count();

    std::cout << "➔ [Interval Tree] Single Query: " << durationTreeQuery << " ns (Found " << treeResults.size() << " entries)\n";
    std::cout << "➔ [Brute Force]   Linear Query: " << durationBruteQuery << " ns (Found " << bruteResults.size() << " entries)\n";
    
    if (durationTreeQuery > 0) {
        std::cout << "Performance Margin: Interval Tree is " 
                  << (double)durationBruteQuery / durationTreeQuery << " times faster than Brute Force!\n\n";
    }
}

int main() {
    std::cout << "==================================================\n";
    std::cout << "ChronoSlit Interval Tree Performance Benchmark\n";
    std::cout << "==================================================\n\n";

    runBenchmark(100);       
    runBenchmark(1000);      
    runBenchmark(10000);     
    runBenchmark(100000);    // 100k Stress Test

    std::cout << "==================================================\n";
    return 0;
}