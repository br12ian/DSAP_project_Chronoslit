#pragma once

#include <QObject>
#include <QString>
#include <QDate>
#include <QDateTime>
#include <QStringList>
#include <QVariantList>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <regex>
#include <string>
#include <iostream>
#include <utility>   // std::move
#include <vector>
#include "interval_tree.h"
#include <QRandomGenerator>

class SchedulerController : public QObject {
    Q_OBJECT

signals:
    void eventAdded(int id, QString title, int startMin, int duration, int dayIndex, QString tag, QString globalDate);
    void errorOccurred(QString msg);
    void calendarCleared();
    void viewChanged(QStringList dayLabels, QStringList dateLabels, QVariantList isCurrentMonth, QVariantList isToday, QString rangeLabel);
    void tagAdded(const QString& name, const QString& colorCode);

private:
    IntervalTree tree;
    int  nextId_       = 0;
    bool m_autoSave    = true;
    bool m_autoRefresh = true;
    bool m_isMonthView = false;
    QDate m_anchor;
    QString m_searchQuery = "";
    QString m_defaultTag    = "Work";  // 預設 Type 初始值為 Work
    QString m_defaultPolicy = "soft";  // 預設策略初始值為 soft

    static QDateTime baseline() {
        return QDateTime(QDate(2026, 5, 4), QTime(0, 0));
    }

    static QDate minToDate(long long absMin) {
        return baseline().addSecs(absMin * 60LL).date();
    }

    long long dateToMin(QDate d) const {
        return baseline().secsTo(QDateTime(d, QTime(0, 0))) / 60;
    }

    long long convertToMinutes(const std::string& date, const std::string& time) const {
        QDateTime dt = QDateTime::fromString(QString::fromStdString(date + " " + time), "yyyy/M/d h:mm");
        return baseline().secsTo(dt) / 60;
    }

    static QDate toMonday(QDate d) {
        return d.addDays(-(d.dayOfWeek() - 1));
    }

    static QDate toFirstOfMonth(QDate d) {
        return QDate(d.year(), d.month(), 1);
    }

    void refreshView() {
        emit calendarCleared();
        
        QDate   viewStart;
        int     displayDays;
        QString rangeLabel;
        int     curMonth = -1;
        
        if (m_isMonthView) {
            viewStart   = toMonday(m_anchor);
            displayDays = 42;
            curMonth    = m_anchor.month();
            rangeLabel  = m_anchor.toString("yyyy年 M月");
        } else {
            viewStart   = m_anchor;
            displayDays = 7;
            rangeLabel  = viewStart.toString("MM/dd") + " – " + viewStart.addDays(6).toString("MM/dd");
        }

        const long long wStart = dateToMin(viewStart);
        const long long wEnd   = wStart + (long long)displayDays * 1440;
        
        for (const Event& e : tree.query(wStart, wEnd)) {
            int idx      = static_cast<int>((e.start - wStart) / 1440);
            int relStart = static_cast<int>((e.start - wStart) % 1440);
            int duration = static_cast<int>(e.end - e.start);
            
            if (idx >= 0 && idx < displayDays) {
                if (!m_searchQuery.isEmpty()) {
                    if (!e.title.contains(m_searchQuery, Qt::CaseInsensitive) && 
                        !e.tag.contains(m_searchQuery, Qt::CaseInsensitive)) {
                        continue; // 不符合條件, 跳過不渲染
                    }
                }
                QString gDate = viewStart.addDays(idx).toString("yyyy/M/d");
                emit eventAdded(e.id, e.title, relStart, duration, idx, e.tag, gDate);
            }
        }

        const QStringList kDays = {"週一", "週二", "週三", "週四", "週五", "週六", "週日"};
        QStringList  dateLabels;
        QVariantList isCurrentMonth;
        QVariantList isToday;
        const QDate  realToday = QDate::currentDate();
        
        for (int i = 0; i < displayDays; ++i) {
            QDate d = viewStart.addDays(i);
            dateLabels     << QString::number(d.day());
            isCurrentMonth << QVariant(m_isMonthView ? (d.month() == curMonth) : true);
            isToday        << QVariant(d == realToday);
        }
        
        emit viewChanged(kDays, dateLabels, isCurrentMonth, isToday, rangeLabel);
    }

public:
    explicit SchedulerController(QObject* parent = nullptr) : QObject(parent) {
        m_anchor = toMonday(QDate::currentDate());
    }

    void setAutoSave(bool e)    { m_autoSave    = e; }
    void setAutoRefresh(bool e) { m_autoRefresh = e; }

    void clearAll() {
        tree.clear();
        nextId_ = 0;
        QFile::remove("schedules.json");
        std::cout << "[Info] Cleared all data.\n";
    }

    void saveToFile(const QString& filename = "schedules.json") {
        QFile file(filename);
        if (!file.open(QIODevice::WriteOnly)) {
            std::cerr << "[Error] Cannot open file for saving.\n";
            return;
        }
        file.write(QJsonDocument(tree.exportToJsonArray()).toJson());
        file.close();
    }

    void loadFromFile(const QString& filename = "schedules.json") {
        QFile file(filename);
        if (file.open(QIODevice::ReadOnly)) {
            const QJsonArray arr = QJsonDocument::fromJson(file.readAll()).array();
            int maxId = -1;
            for (int i = 0; i < arr.size(); ++i) {
                Event e = Event::fromJson(arr[i].toObject());
                if (e.id > maxId) maxId = e.id;
                tree.insert(e);
            }
            nextId_ = maxId + 1;
            file.close();
            std::cout << "[Success] Loaded " << arr.size() << " events.\n";
        } else {
            std::cout << "[Info] No save file found. Starting fresh.\n";
        }
        refreshView();
    }
    
    Q_INVOKABLE void toggleViewMode(bool isMonth) {
        m_isMonthView = isMonth;
        m_anchor = isMonth ? toFirstOfMonth(m_anchor) : toMonday(m_anchor);
        refreshView();
    }

    Q_INVOKABLE void nextRange() {
        m_anchor = m_isMonthView ? toFirstOfMonth(m_anchor.addMonths(1)) : m_anchor.addDays(7);
        refreshView();
    }

    Q_INVOKABLE void prevRange() {
        m_anchor = m_isMonthView ? toFirstOfMonth(m_anchor.addMonths(-1)) : m_anchor.addDays(-7);
        refreshView();
    }

    Q_INVOKABLE void initView() { 
        refreshView(); 
    }

    Q_INVOKABLE void parseCommand(QString rawCommand) {
        QString cmdStr = rawCommand.trimmed();
        if (cmdStr.isEmpty()) return;

        std::string sRaw = cmdStr.toStdString();
        std::smatch rmMatch;

        // ─────────────────────────────────────────────────────────────────────
        // ── 流派一：系統控制指令 (以 / 開頭)
        // ─────────────────────────────────────────────────────────────────────
        if (cmdStr.startsWith("/")) {
            // 💡 1. 匹配 "/find" (清空搜尋條件，回復全部顯示)
            std::regex findClearPattern(R"(^/find\s*$)");
            if (std::regex_search(sRaw, rmMatch, findClearPattern)) {
                m_searchQuery = "";
                refreshView();
                return;
            }

            // 💡 2. 匹配 "/find 關鍵字" (過濾顯示標題或標籤包含此字串的行程)
            std::regex findPattern(R"(^/find\s+(.+))");
            if (std::regex_search(sRaw, rmMatch, findPattern)) {
                m_searchQuery = QString::fromStdString(rmMatch[1].str()).trimmed();
                refreshView();
                return;
            }

            // 💡 3. 透過名稱刪除 (/rm #Exam)
            std::regex rmTitlePattern(R"(^/rm\s+#(\w+))");
            if (std::regex_search(sRaw, rmMatch, rmTitlePattern)) {
                QString targetTitle = QString::fromStdString(rmMatch[1].str());
                std::vector<Event> allEvents = tree.query(-5256000, 5256000);
                std::vector<Event> toKeep;
                bool found = false;

                for (const auto& e : allEvents) {
                    if (e.title == targetTitle) {
                        found = true;
                    } else {
                        toKeep.push_back(e);
                    }
                }

                if (found) {
                    tree.clear();
                    for (const auto& e : toKeep) tree.insert(e);
                    if (m_autoSave)    saveToFile();
                    if (m_autoRefresh) refreshView();
                    std::cout << "[Delete] Removed event(s) with title: " << targetTitle.toStdString() << "\n";
                } else {
                    emit errorOccurred("Event not found with title: #" + targetTitle);
                }
                return;
            }

            // 💡 4. 透過絕對 ID 刪除 (/rm 5)
            std::regex rmIdPattern(R"(^/rm\s+(\d+))");
            if (std::regex_search(sRaw, rmMatch, rmIdPattern)) {
                int targetId = std::stoi(rmMatch[1].str());
                std::vector<Event> allEvents = tree.query(-5256000, 5256000);
                std::vector<Event> toKeep;
                bool found = false;

                for (const auto& e : allEvents) {
                    if (e.id == targetId) {
                        found = true;
                    } else {
                        toKeep.push_back(e);
                    }
                }

                if (found) {
                    tree.clear();
                    for (const auto& e : toKeep) tree.insert(e);
                    if (m_autoSave)    saveToFile();
                    if (m_autoRefresh) refreshView();
                    std::cout << "[Delete] Removed event with ID: " << targetId << "\n";
                } else {
                    emit errorOccurred("Event not found with ID: " + QString::number(targetId));
                }
                return;
            }

            // 💡 5. 匹配 "/default #TagName" (動態修改預設 Type)
            std::regex defTagPattern(R"(^/default\s+#(\w+))");
            if (std::regex_search(sRaw, rmMatch, defTagPattern)) {
                m_defaultTag = QString::fromStdString(rmMatch[1].str()).trimmed();
                std::cout << "[Config] Default Type updated to: #" << m_defaultTag.toStdString() << "\n";
                return;
            }

            // 💡 6. 匹配 "/default -p policy" (動態修改預設策略)
            std::regex defPolicyPattern(R"(^/default\s+-p\s+(soft|hard))");
            if (std::regex_search(sRaw, rmMatch, defPolicyPattern)) {
                m_defaultPolicy = QString::fromStdString(rmMatch[1].str()).trimmed();
                std::cout << "[Config] Default Policy updated to: " << m_defaultPolicy.toStdString() << "\n";
                return;
            }

            emit errorOccurred("Unknown command. Available: /find, /find <query>, /rm #Title, /rm <id>");
            return;

            // 💡 7. 匹配 "/tag #TagName" 或 "/tag #TagName #HexColor" (透過指令新增標籤)
            // 範例：/tag #Project 或 /tag #Meta #FF5500
            std::regex tagCmdPattern(R"(^/tag\s+#(\w+)(?:\s+(#[0-9a-fA-F]{6}))?)");
            if (std::regex_search(sRaw, rmMatch, tagCmdPattern)) {
                QString tagName = QString::fromStdString(rmMatch[1].str()).trimmed();

                QString tagColor;
                if (rmMatch[2].matched) {
                    // 使用者有自訂顏色
                    tagColor = QString::fromStdString(rmMatch[2].str()).trimmed();
                } else {
                    // 💡 使用者沒輸入顏色：從 8 款大眾質感行事曆色系中隨機盲抽
                    QStringList popularColors = {
                        "#3182CE", // 經典藍 (Blue)
                        "#38A169", // 石墨綠 (Green)
                        "#E53E3E", // 番茄紅 (Red)
                        "#D69E2E", // 芥末黃 (Amber)
                        "#805AD5", // 薰衣草紫 (Purple)
                        "#DD6B20", // 活力橘 (Orange)
                        "#D53F8C", // 玫瑰粉 (Pink)
                        "#319795"  // 莫蘭迪青 (Teal)
                    };
                    int idx = QRandomGenerator::global()->bounded(popularColors.size());
                    tagColor = popularColors[idx];
                }
                
                emit tagAdded(tagName, tagColor);
                std::cout << "[Tag] Command created new tag: #" << tagName.toStdString() << " with color " << tagColor.toStdString() << "\n";
                return;
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // ── 流派二：常規排程指令 (智慧前處理管線 Smart Preprocessor)
        // ─────────────────────────────────────────────────────────────────────
        QDate targetDate = QDate::currentDate(); // 預設留白機制：今天

        // 💡 步驟 A：識別相對日期關鍵字（支援今天、明天、today、tomorrow）
        if (cmdStr.startsWith("tomorrow ", Qt::CaseInsensitive) || cmdStr.startsWith("明天 ")) {
            targetDate = QDate::currentDate().addDays(1);
            cmdStr = cmdStr.mid(cmdStr.indexOf(" ") + 1).trimmed();
        } else if (cmdStr.startsWith("today ", Qt::CaseInsensitive) || cmdStr.startsWith("今天 ")) {
            targetDate = QDate::currentDate();
            cmdStr = cmdStr.mid(cmdStr.indexOf(" ") + 1).trimmed();
        } else {
            // 💡 步驟 B：檢查日期數字縮寫 (如 5/31 或 2026/5/31)
            std::string sDateCheck = cmdStr.toStdString();
            std::regex fullDatePat(R"(^(\d{4})/(\d{1,2})/(\d{1,2})\s+)");
            std::regex shortDatePat(R"(^(\d{1,2})/(\d{1,2})\s+)");
            std::smatch dateMatch;

            if (std::regex_search(sDateCheck, dateMatch, fullDatePat)) {
                targetDate = QDate(std::stoi(dateMatch[1].str()), std::stoi(dateMatch[2].str()), std::stoi(dateMatch[3].str()));
                cmdStr = QString::fromStdString(sDateCheck.substr(dateMatch[0].length())).trimmed();
            } else if (std::regex_search(sDateCheck, dateMatch, shortDatePat)) {
                // 假如沒多說年份 -> 自動假定為「今年」
                targetDate = QDate(QDate::currentDate().year(), std::stoi(dateMatch[1].str()), std::stoi(dateMatch[2].str()));
                cmdStr = QString::fromStdString(sDateCheck.substr(dateMatch[0].length())).trimmed();
            }
            // 💡 留白機制：如果完全沒有寫任何日期關鍵字或數字，預設直接填補為今天
        }

        // 💡 步驟 C：時間縮寫標準化 (支援 14-15, 14.-15., 14.30-16 等格式轉譯成 14:00-15:00)
        std::string sTimeCmd = cmdStr.toStdString();
        std::regex timePat(R"((\d{1,2})(?:\.|:(\d{2}))?[-~~~\.]+(\d{1,2})(?:\.|:(\d{2}))?)");
        std::smatch timeMatch;
        if (std::regex_search(sTimeCmd, timeMatch, timePat)) {
            int startH = std::stoi(timeMatch[1].str());
            int startM = timeMatch[2].matched ? std::stoi(timeMatch[2].str()) : 0;
            int endH = std::stoi(timeMatch[3].str());
            int endM = timeMatch[4].matched ? std::stoi(timeMatch[4].str()) : 0;

            char buf[64];
            snprintf(buf, sizeof(buf), "%02d:%02d-%02d:%02d", startH, startM, endH, endM);
            sTimeCmd.replace(timeMatch.position(0), timeMatch.length(0), std::string(buf));
            cmdStr = QString::fromStdString(sTimeCmd);
        }

        // 💡 步驟 D：智慧參數填補 Regex (讓策略 -p 與標籤 -t 變成 Optional 可省略)
        std::regex insertPattern(R"(^(\d{1,2}:\d{2})-(\d{1,2}:\d{2})\s+#(\w+)(?:\s+-p\s+(\w+))?(?:\s+-t\s+(\w+))?)");
        std::string sFinal = cmdStr.toStdString();
        std::smatch match;

        if (!std::regex_search(sFinal, match, insertPattern)) {
            emit errorOccurred("Format: [Date] HH:MM-HH:MM #Title [-p policy] [-t tag]");
            std::cout << "[Error] Parse failed for: " << sFinal << "\n";
            return;
        }

        // 填補留白：沒寫策略預設 soft，沒寫標籤預設 Work
        std::string startTimeStr = match[1].str();
        std::string endTimeStr   = match[2].str();
        std::string title        = match[3].str();
        std::string policyStr    = match[4].matched ? match[4].str() : m_defaultPolicy.toStdString();
        std::string tagStr       = match[5].matched ? match[5].str() : m_defaultTag.toStdString();

        QString dateLabel = QString("%1/%2/%3").arg(targetDate.year()).arg(targetDate.month()).arg(targetDate.day());
        std::string stdDate = dateLabel.toStdString();

        const long long startMin = convertToMinutes(stdDate, startTimeStr);
        const long long endMin   = convertToMinutes(stdDate, endTimeStr);
        const Policy    pol      = (policyStr == "soft") ? Policy::Soft : Policy::Hard;
        const QString   qTag     = QString::fromStdString(tagStr);
        const QString   qTitle   = QString::fromStdString(title);

        if (startMin >= endMin) {
            emit errorOccurred("Invalid time range: end must be after start.");
            return;
        }

        // 💡 步驟 E：進入區間樹進行排程插入
        if (pol == Policy::Hard) {
            Event e(nextId_, startMin, endMin, qTitle, Policy::Hard, dateLabel, qTag);
            if (tree.insert(e)) {
                ++nextId_;
                if (m_autoSave)    saveToFile();

                m_anchor = toMonday(targetDate);

                if (m_autoRefresh) refreshView();
                std::cout << "[Hard] Inserted: " << title << "\n";
            } else {
                emit errorOccurred("Conflict: a Hard event already occupies this slot.");
            }
            return;
        }

        // Soft 策略：平衡樹碎片裁剪處理
        using Seg = std::pair<long long, long long>;
        std::vector<Seg> alive = {{startMin, endMin}};
        
        for (const Event& hard : tree.query(startMin, endMin)) {
            if (hard.policy != Policy::Hard) continue;
            
            std::vector<Seg> next;
            next.reserve(alive.size() + 1);
            for (const Seg& s : alive) {
                if (s.second <= hard.start || s.first >= hard.end) {
                    next.push_back(s);
                    continue;
                }
                if (s.first < hard.start)  next.push_back({s.first, hard.start});
                if (s.second > hard.end)   next.push_back({hard.end, s.second});
            }
            alive = std::move(next);
        }

        if (alive.empty()) {
            emit errorOccurred("Soft event fully blocked by Hard schedules.");
            return;
        }

        int inserted = 0;
        for (const Seg& seg : alive) {
            QString fragDate = minToDate(seg.first).toString("yyyy/M/d");
            Event piece(nextId_, seg.first, seg.second, qTitle, Policy::Soft, fragDate, qTag);
            if (tree.insert(piece)) {
                ++nextId_;
                ++inserted;
            }
        }

        if (inserted > 0) {
            if (m_autoSave)    saveToFile();

            m_anchor = toMonday(targetDate);

            if (m_autoRefresh) refreshView();
            std::cout << "[Soft] Inserted " << inserted << " fragment(s): " << title << "\n";
        } else {
            emit errorOccurred("Soft event fragments overlapped existing schedules.");
        }
    }
};