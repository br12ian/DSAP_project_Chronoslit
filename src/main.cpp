#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "scheduler_controller.h"

int main(int argc, char *argv[]) {
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

    QGuiApplication app(argc, argv);

    SchedulerController controller;
    QQmlApplicationEngine engine;

    // 綁定前後端
    engine.rootContext()->setContextProperty("backend", &controller);

    
    const QUrl url(QStringLiteral("qrc:/ChronoSlitApp/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    
    engine.load(url);

    return app.exec();
}