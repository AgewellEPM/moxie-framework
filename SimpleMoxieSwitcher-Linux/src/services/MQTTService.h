#pragma once

#include <QObject>
#include <QString>
#include <QByteArray>
#include <mosquitto.h>

class MQTTService : public QObject {
    Q_OBJECT

public:
    explicit MQTTService(QObject *parent = nullptr);
    ~MQTTService();

    bool connect(const QString& host, int port = 1883);
    void disconnect();
    bool publish(const QString& topic, const QByteArray& payload, int qos = 0);
    bool subscribe(const QString& topic, int qos = 0);
    bool isConnected() const { return m_connected; }

signals:
    void connected();
    void disconnected();
    void messageReceived(const QString& topic, const QByteArray& payload);
    void errorOccurred(const QString& error);

private:
    static void onConnect(struct mosquitto *mosq, void *obj, int result);
    static void onDisconnect(struct mosquitto *mosq, void *obj, int result);
    static void onMessage(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message);

    struct mosquitto *m_mosquitto = nullptr;
    bool m_connected = false;
};
