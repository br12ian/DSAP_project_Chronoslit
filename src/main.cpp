#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext> 
#include <QStringLiteral>
#include <QUrl>
#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <iomanip>
#include <chrono> 
#include <random> // 💡 引入現代 C++ 隨機庫

#include "scheduler_controller.h"

std::vector<QString> generateMockCommands(int n) {
    std::vector<QString> commands;
    std::string policies[] = {"hard", "soft"};
    std::string tags[] = {"Work", "Study", "Gym", "Rest"};
    
    std::random_device rd;  
    std::mt19937 gen(rd()); 

    QDate today = QDate::currentDate();

    // 💡 定義分佈：隨機加 0 ~ 30 天
    std::uniform_int_distribution<> dayOffsetDist(0, 30); 
    std::uniform_int_distribution<> hourDist(0, 21);     
    std::uniform_int_distribution<> durationDist(1, 3);  
    std::uniform_int_distribution<> policyDist(0, 1);    
    std::uniform_int_distribution<> tagDist(0, 3);       

    for (int i = 0; i < n; ++i) {
        // 透過今天的日期動態向後延伸
        QDate targetDate = today.addDays(dayOffsetDist(gen));
        int startHour = hourDist(gen);
        int endHour = startHour + durationDist(gen);
        if (endHour > 24) endHour = 24;
        
        std::string policy = policies[policyDist(gen)];
        std::string tag = tags[tagDist(gen)];
        
        std::stringstream ss;
        ss << targetDate.year() << "/" << targetDate.month() << "/" << targetDate.day() << " "
           << std::setw(2) << std::setfill('0') << startHour << ":00-"
           << std::setw(2) << std::setfill('0') << endHour << ":00 "
           << "#AutoEvent" << i << " "
           << "-p " << policy << " "
           << "-t " << tag;
           
        commands.push_back(QString::fromStdString(ss.str()));
    }
    return commands;
}

int main(int argc, char *argv[]) {
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

    QGuiApplication app(argc, argv);

    SchedulerController controller;
    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("backend", &controller);

    const QUrl url(QStringLiteral("qrc:/ChronoSlitApp/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    
    engine.load(url);

    // 💡 測試與讀檔配置開關
    bool runTestMode = true; 

    if (runTestMode) {
        controller.clearAll();

        std::cout << "\n--- Starting Benchmark Test (True Random) ---\n";
        auto testCmds = generateMockCommands(15);

        controller.setAutoSave(false);
        controller.setAutoRefresh(false);   // 抑制單筆刷新

        for (const auto& cmd : testCmds)
            controller.parseCommand(cmd);

        controller.saveToFile();
        controller.setAutoSave(true);
        controller.setAutoRefresh(true);    // 恢復

        controller.initView();              // 最後進行單次高效總刷新
    } else {
        controller.loadFromFile();          
    }

    return app.exec();
}