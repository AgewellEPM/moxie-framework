#pragma once
#include <QString>
#include <QDateTime>
#include <QMetaType>
#include <QList>
#include <QJsonObject>
#include <QJsonArray>

// ChatMessage represents a single message in a conversation
struct ChatMessage {
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(QString role MEMBER role)
    Q_PROPERTY(QString content MEMBER content)
    Q_PROPERTY(QDateTime timestamp MEMBER timestamp)

public:
    QString id;
    QString role;      // user, assistant, system
    QString content;
    QDateTime timestamp;

    ChatMessage() = default;

    ChatMessage(const QString& msgRole, const QString& msgContent)
        : role(msgRole)
        , content(msgContent)
        , timestamp(QDateTime::currentDateTime()) {
        id = QString::number(QDateTime::currentMSecsSinceEpoch());
    }

    QJsonObject toJson() const {
        QJsonObject obj;
        obj["id"] = id;
        obj["role"] = role;
        obj["content"] = content;
        obj["timestamp"] = timestamp.toString(Qt::ISODate);
        return obj;
    }

    static ChatMessage fromJson(const QJsonObject& json) {
        ChatMessage m;
        m.id = json["id"].toString();
        m.role = json["role"].toString();
        m.content = json["content"].toString();
        m.timestamp = QDateTime::fromString(json["timestamp"].toString(), Qt::ISODate);
        return m;
    }
};

Q_DECLARE_METATYPE(ChatMessage)

// Conversation represents a chat session
struct Conversation {
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(QString title MEMBER title)
    Q_PROPERTY(QString childProfileId MEMBER childProfileId)
    Q_PROPERTY(QString personalityId MEMBER personalityId)
    Q_PROPERTY(QDateTime createdAt MEMBER createdAt)
    Q_PROPERTY(QDateTime updatedAt MEMBER updatedAt)
    Q_PROPERTY(int messageCount MEMBER messageCount)
    Q_PROPERTY(bool isArchived MEMBER isArchived)

public:
    QString id;
    QString title;
    QString childProfileId;
    QString personalityId;
    QList<ChatMessage> messages;
    QDateTime createdAt;
    QDateTime updatedAt;
    int messageCount = 0;
    bool isArchived = false;

    Conversation() = default;

    Conversation(const QString& conversationTitle, const QString& profileId)
        : title(conversationTitle)
        , childProfileId(profileId)
        , createdAt(QDateTime::currentDateTime())
        , updatedAt(QDateTime::currentDateTime()) {
        id = QString::number(QDateTime::currentMSecsSinceEpoch());
    }

    void addMessage(const ChatMessage& msg) {
        messages.append(msg);
        messageCount = messages.size();
        updatedAt = QDateTime::currentDateTime();
    }

    QJsonObject toJson() const {
        QJsonObject obj;
        obj["id"] = id;
        obj["title"] = title;
        obj["childProfileId"] = childProfileId;
        obj["personalityId"] = personalityId;
        obj["createdAt"] = createdAt.toString(Qt::ISODate);
        obj["updatedAt"] = updatedAt.toString(Qt::ISODate);
        obj["messageCount"] = messageCount;
        obj["isArchived"] = isArchived;

        QJsonArray msgArray;
        for (const auto& msg : messages) {
            msgArray.append(msg.toJson());
        }
        obj["messages"] = msgArray;

        return obj;
    }

    static Conversation fromJson(const QJsonObject& json) {
        Conversation c;
        c.id = json["id"].toString();
        c.title = json["title"].toString();
        c.childProfileId = json["childProfileId"].toString();
        c.personalityId = json["personalityId"].toString();
        c.createdAt = QDateTime::fromString(json["createdAt"].toString(), Qt::ISODate);
        c.updatedAt = QDateTime::fromString(json["updatedAt"].toString(), Qt::ISODate);
        c.messageCount = json["messageCount"].toInt(0);
        c.isArchived = json["isArchived"].toBool(false);

        QJsonArray msgArray = json["messages"].toArray();
        for (const auto& m : msgArray) {
            c.messages.append(ChatMessage::fromJson(m.toObject()));
        }

        return c;
    }
};

Q_DECLARE_METATYPE(Conversation)
