#pragma once
#include <QObject>
#include <QString>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDir>
#include <QStandardPaths>

namespace SimpleMoxieSwitcher {

class StorageService : public QObject {
    Q_OBJECT

public:
    explicit StorageService(QObject *parent = nullptr);

    // Generic JSON storage
    Q_INVOKABLE bool saveJson(const QString &filename, const QJsonObject &data);
    Q_INVOKABLE bool saveJsonArray(const QString &filename, const QJsonArray &data);
    Q_INVOKABLE QJsonObject loadJson(const QString &filename);
    Q_INVOKABLE QJsonArray loadJsonArray(const QString &filename);
    Q_INVOKABLE bool deleteFile(const QString &filename);
    Q_INVOKABLE bool fileExists(const QString &filename);

    // Settings
    Q_INVOKABLE void saveSetting(const QString &key, const QVariant &value);
    Q_INVOKABLE QVariant loadSetting(const QString &key, const QVariant &defaultValue = QVariant());

    // Data directory
    Q_INVOKABLE QString dataPath() const { return m_dataPath; }

signals:
    void saveError(const QString &filename, const QString &error);
    void loadError(const QString &filename, const QString &error);

private:
    QString getFilePath(const QString &filename) const;
    void ensureDirectoryExists();

    QString m_dataPath;
};

} // namespace SimpleMoxieSwitcher
