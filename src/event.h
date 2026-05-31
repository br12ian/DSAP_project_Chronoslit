#pragma once
#include <QString>
#include <QJsonObject>
#include <string>

enum class Policy { Hard, Soft };

struct Event {
    int id;          
    long long start; 
    long long end;   
    QString title;   
    Policy policy;
    QString date;
    QString tag;

    Event() : id(0), start(0), end(0), policy(Policy::Hard) {}

    // 建構子：給指令解析器使用
    Event(int id, long long s, long long e, std::string t, Policy p, QString d = "", QString tg = "")
        : id(id), start(s), end(e), title(QString::fromStdString(t)), policy(p), date(d), tag(tg) {}

    // 建構子：給 JSON 讀檔使用
    Event(int id, long long s, long long e, QString t, Policy p, QString d = "", QString tg = "")
        : id(id), start(s), end(e), title(t), policy(p), date(d), tag(tg) {}

    QJsonObject toJson() const {
        QJsonObject json;
        json["id"] = id;
        json["start"] = (qint64)start;
        json["end"] = (qint64)end;
        json["title"] = title; 
        json["policy"] = (policy == Policy::Hard) ? "hard" : "soft";
        json["date"] = date;
        json["tag"] = tag; // 💡 存入 JSON
        return json;
    }

    static Event fromJson(const QJsonObject& json) {
        Event e;
        e.id = json["id"].toInt();
        e.start = json["start"].toVariant().toLongLong();
        e.end = json["end"].toVariant().toLongLong();
        e.title = json["title"].toString(); 
        e.policy = (json["policy"].toString() == "hard") ? Policy::Hard : Policy::Soft;
        e.date = json["date"].toString();
        e.tag = json["tag"].toString(); // 💡 讀取 JSON
        return e;
    }
};