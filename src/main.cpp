#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext> 
#include <QStringLiteral>
#include <QUrl>
#include <iostream>

#include "scheduler_controller.h"

int main(int argc, char *argv[]) {
    // 1. 強制設定 Qt 樣式
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

    QGuiApplication app(argc, argv);

    // 2. 初始化核心控制器與 QML 引擎
    SchedulerController controller;
    QQmlApplicationEngine engine;

    // 3. 將 C++ 後端物件注入到 QML 前端環境中（命名為 backend）
    engine.rootContext()->setContextProperty("backend", &controller);

    const QUrl url(QStringLiteral("qrc:/ChronoSlitApp/Main.qml"));

    // 4. 防禦性機制：若 QML 載入失敗則安全退出
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);
    controller.loadFromFile();          

    return app.exec();
}