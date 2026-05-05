#pragma once
#include <QObject>
#include <QString>
#include <regex>
#include <string>
#include <iostream>
#include <QDateTime>
#include "interval_tree.h" // 引入你的區間樹

class SchedulerController : public QObject {
    Q_OBJECT
    
signals: // 💡 這些訊號會傳遞給 QML
    void eventAdded(QString title, int startMin, int duration, int dayIndex);
    void errorOccurred(QString msg);

private:
    IntervalTree tree; // 你的核心大腦
    int nextId_ = 0;   // 給事件一個自動遞增的 ID

    // 將字串時間轉換為「距離 5/4 (週一) 00:00 的分鐘數」
    long long convertToMinutes(std::string dateStr, std::string timeStr) {
        QString full = QString::fromStdString(dateStr + " " + timeStr);
        QDateTime dt = QDateTime::fromString(full, "yyyy/M/d h:mm");
        // 設定基準點為 2026/05/04 00:00:00 (這週一)
        QDateTime baseTime(QDate(2026, 5, 4), QTime(0, 0));
        return baseTime.secsTo(dt) / 60; 
    }

public:
    explicit SchedulerController(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void parseCommand(QString rawCommand) {
        std::string cmd = rawCommand.toStdString();
        
        // 正規表達式藍圖
        std::regex pattern(R"((\d{4}/\d{1,2}/\d{1,2})\s+(\d{1,2}:\d{2})-(\d{1,2}:\d{2})\s+#(\w+)\s+-p\s+(\w+)\s+-t\s+(\w+))");
        std::smatch match;

        if (std::regex_search(cmd, match, pattern)) {
            // 1. 萃取並轉換時間
            long long startMin = convertToMinutes(match[1], match[2]);
            long long endMin   = convertToMinutes(match[1], match[3]);
            std::string title  = match[4];
            
            // 2. 建立事件 (這裡傳入空白的 tag vector，對齊你的建構子)
            Event e(nextId_++, startMin, endMin, title, Policy::Hard, {}); 

            // 3. 呼叫公開的 insert 函數，它會回傳 bool
            bool success = tree.insert(e);

            if (success) {
                // 如果插入成功，計算這是星期幾，以及當天第幾分鐘
                int day = (startMin / 1440); // 0 = 週一, 1 = 週二...
                int relStart = startMin % 1440; // 0~1439
                int duration = endMin - startMin; // 持續時間

                // 發射訊號通知 QML 畫圖！
                emit eventAdded(QString::fromStdString(title), relStart, duration, day);
                std::cout << "[Success] Event inserted: " << title << std::endl;
            } else {
                // 如果插入失敗（衝堂）
                emit errorOccurred("Conflict: A 'Hard' policy event blocks this time slot!");
                std::cout << "[Error] Hard policy conflict!" << std::endl;
            }
        } else {
            // 格式打錯
            emit errorOccurred("Invalid format. Follow the hint.");
            std::cout << "[Error] Parse failed." << std::endl;
        }
    }
};