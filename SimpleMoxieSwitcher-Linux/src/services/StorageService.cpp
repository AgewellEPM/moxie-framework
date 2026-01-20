#include "StorageService.h"
#include <QFile>
#include <QSettings>
#include <QDebug>

namespace SimpleMoxieSwitcher {

StorageService::StorageService(QObject *parent)
    : QObject(parent)
{
    m_dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    ensureDirectoryExists();
}

void StorageService::ensureDirectoryExists() {
    QDir dir(m_dataPath);
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    // Create subdirectories
    dir.mkpath("conversations");
    dir.mkpath("profiles");
    dir.mkpath("memories");
    dir.mkpath("usage");
}

QString StorageService::getFilePath(const QString &filename) const {
    return m_dataPath + "/" + filename;
}

bool StorageService::saveJson(const QString &filename, const QJsonObject &data) {
    QFile file(getFilePath(filename));
    if (!file.open(QIODevice::WriteOnly)) {
        emit saveError(filename, file.errorString());
        return false;
    }

    QJsonDocument doc(data);
    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();
    return true;
}

bool StorageService::saveJsonArray(const QString &filename, const QJsonArray &data) {
    QFile file(getFilePath(filename));
    if (!file.open(QIODevice::WriteOnly)) {
        emit saveError(filename, file.errorString());
        return false;
    }

    QJsonDocument doc(data);
    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();
    return true;
}

QJsonObject StorageService::loadJson(const QString &filename) {
    QFile file(getFilePath(filename));
    if (!file.exists()) {
        return QJsonObject();
    }

    if (!file.open(QIODevice::ReadOnly)) {
        emit loadError(filename, file.errorString());
        return QJsonObject();
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);

    if (error.error != QJsonParseError::NoError) {
        emit loadError(filename, error.errorString());
        return QJsonObject();
    }

    return doc.object();
}

QJsonArray StorageService::loadJsonArray(const QString &filename) {
    QFile file(getFilePath(filename));
    if (!file.exists()) {
        return QJsonArray();
    }

    if (!file.open(QIODevice::ReadOnly)) {
        emit loadError(filename, file.errorString());
        return QJsonArray();
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);

    if (error.error != QJsonParseError::NoError) {
        emit loadError(filename, error.errorString());
        return QJsonArray();
    }

    return doc.array();
}

bool StorageService::deleteFile(const QString &filename) {
    QFile file(getFilePath(filename));
    if (file.exists()) {
        return file.remove();
    }
    return true;
}

bool StorageService::fileExists(const QString &filename) {
    return QFile::exists(getFilePath(filename));
}

void StorageService::saveSetting(const QString &key, const QVariant &value) {
    QSettings settings("OpenMoxie", "SimpleMoxieSwitcher");
    settings.setValue(key, value);
}

QVariant StorageService::loadSetting(const QString &key, const QVariant &defaultValue) {
    QSettings settings("OpenMoxie", "SimpleMoxieSwitcher");
    return settings.value(key, defaultValue);
}

} // namespace SimpleMoxieSwitcher
