#pragma once
#include <QString>
#include <QDateTime>
#include <QJsonObject>
#include <QMetaType>

class UsageRecord {
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(QString childProfileId MEMBER childProfileId)
    Q_PROPERTY(QString feature MEMBER feature)
    Q_PROPERTY(QString aiModel MEMBER aiModel)
    Q_PROPERTY(int tokensUsed MEMBER tokensUsed)
    Q_PROPERTY(double estimatedCost MEMBER estimatedCost)
    Q_PROPERTY(QDateTime timestamp MEMBER timestamp)
    Q_PROPERTY(int durationSeconds MEMBER durationSeconds)

public:
    QString id;
    QString childProfileId;
    QString feature; // "chat", "game", "story", etc.
    QString aiModel; // "gpt-4", "gpt-3.5-turbo", etc.
    int tokensUsed = 0;
    double estimatedCost = 0.0;
    QDateTime timestamp;
    int durationSeconds = 0;
    QString sessionId;
    bool wasSuccessful = true;
    QString errorMessage;

    UsageRecord() = default;

    UsageRecord(const QString& childId, const QString& featureUsed, const QString& model)
        : childProfileId(childId)
        , feature(featureUsed)
        , aiModel(model)
        , timestamp(QDateTime::currentDateTime()) {}

    double calculateCost(int tokens, const QString& model) {
        // Approximate costs per 1K tokens
        if (model.contains("gpt-4")) {
            return (tokens / 1000.0) * 0.03;
        } else if (model.contains("gpt-3.5")) {
            return (tokens / 1000.0) * 0.002;
        } else if (model.contains("claude")) {
            return (tokens / 1000.0) * 0.01;
        }
        return 0.0;
    }

    QJsonObject toJson() const {
        QJsonObject obj;
        obj["id"] = id;
        obj["childProfileId"] = childProfileId;
        obj["feature"] = feature;
        obj["aiModel"] = aiModel;
        obj["tokensUsed"] = tokensUsed;
        obj["estimatedCost"] = estimatedCost;
        obj["timestamp"] = timestamp.toString(Qt::ISODate);
        obj["durationSeconds"] = durationSeconds;
        obj["wasSuccessful"] = wasSuccessful;
        return obj;
    }
};

Q_DECLARE_METATYPE(UsageRecord)