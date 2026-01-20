#pragma once
#include <QString>
#include <QObject>
#include <QDateTime>
#include <QMetaType>

class ChildProfile {
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id)
    Q_PROPERTY(QString name MEMBER name)
    Q_PROPERTY(int age MEMBER age)
    Q_PROPERTY(QString avatar MEMBER avatar)
    Q_PROPERTY(QDateTime createdAt MEMBER createdAt)
    Q_PROPERTY(QDateTime lastPlayedAt MEMBER lastPlayedAt)
    Q_PROPERTY(int totalPoints MEMBER totalPoints)
    Q_PROPERTY(int gamesPlayed MEMBER gamesPlayed)
    Q_PROPERTY(QString favoriteGame MEMBER favoriteGame)
    Q_PROPERTY(QString personalityId MEMBER personalityId)
    Q_PROPERTY(bool isActive MEMBER isActive)

public:
    QString id;
    QString name;
    int age = 0;
    QString avatar;
    QDateTime createdAt;
    QDateTime lastPlayedAt;
    int totalPoints = 0;
    int gamesPlayed = 0;
    QString favoriteGame;
    QString personalityId;
    bool isActive = false;

    ChildProfile() = default;

    ChildProfile(const QString& childName, int childAge)
        : name(childName)
        , age(childAge)
        , createdAt(QDateTime::currentDateTime())
        , lastPlayedAt(QDateTime::currentDateTime())
        , isActive(true) {}

    bool isValid() const { return !name.isEmpty() && age > 0; }
};

Q_DECLARE_METATYPE(ChildProfile)