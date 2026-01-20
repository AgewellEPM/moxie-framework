#pragma once
#include <QString>
#include <QDateTime>
#include <QMetaType>
#include <QJsonObject>
#include <QJsonArray>

// Memory represents extracted memories from conversations
struct Memory {
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(QString content MEMBER content)
    Q_PROPERTY(QString category MEMBER category)
    Q_PROPERTY(QString source MEMBER source)
    Q_PROPERTY(QDateTime createdAt MEMBER createdAt)
    Q_PROPERTY(double importance MEMBER importance)
    Q_PROPERTY(int accessCount MEMBER accessCount)
    Q_PROPERTY(QDateTime lastAccessedAt MEMBER lastAccessedAt)

public:
    QString id;
    QString content;
    QString category;  // fact, preference, experience, relationship
    QString source;    // conversation ID or manual entry
    QDateTime createdAt;
    double importance = 0.5;
    int accessCount = 0;
    QDateTime lastAccessedAt;

    Memory() = default;

    Memory(const QString& memoryContent, const QString& memoryCategory)
        : content(memoryContent)
        , category(memoryCategory)
        , createdAt(QDateTime::currentDateTime())
        , lastAccessedAt(QDateTime::currentDateTime()) {
        id = QString::number(QDateTime::currentMSecsSinceEpoch());
    }

    bool isValid() const { return !content.isEmpty(); }

    QJsonObject toJson() const {
        QJsonObject obj;
        obj["id"] = id;
        obj["content"] = content;
        obj["category"] = category;
        obj["source"] = source;
        obj["createdAt"] = createdAt.toString(Qt::ISODate);
        obj["importance"] = importance;
        obj["accessCount"] = accessCount;
        obj["lastAccessedAt"] = lastAccessedAt.toString(Qt::ISODate);
        return obj;
    }

    static Memory fromJson(const QJsonObject& json) {
        Memory m;
        m.id = json["id"].toString();
        m.content = json["content"].toString();
        m.category = json["category"].toString();
        m.source = json["source"].toString();
        m.createdAt = QDateTime::fromString(json["createdAt"].toString(), Qt::ISODate);
        m.importance = json["importance"].toDouble(0.5);
        m.accessCount = json["accessCount"].toInt(0);
        m.lastAccessedAt = QDateTime::fromString(json["lastAccessedAt"].toString(), Qt::ISODate);
        return m;
    }
};

Q_DECLARE_METATYPE(Memory)
