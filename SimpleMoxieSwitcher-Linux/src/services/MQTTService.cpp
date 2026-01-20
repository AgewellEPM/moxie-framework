#include "MQTTService.h"
#include <QDebug>

MQTTService::MQTTService(QObject *parent) : QObject(parent) {
    mosquitto_lib_init();
    m_mosquitto = mosquitto_new("SimpleMoxieSwitcher", true, this);

    if (m_mosquitto) {
        mosquitto_connect_callback_set(m_mosquitto, onConnect);
        mosquitto_disconnect_callback_set(m_mosquitto, onDisconnect);
        mosquitto_message_callback_set(m_mosquitto, onMessage);
    }
}

MQTTService::~MQTTService() {
    if (m_mosquitto) {
        mosquitto_destroy(m_mosquitto);
    }
    mosquitto_lib_cleanup();
}

bool MQTTService::connect(const QString& host, int port) {
    if (!m_mosquitto) return false;

    int result = mosquitto_connect(m_mosquitto, host.toUtf8().constData(), port, 60);
    if (result == MOSQ_ERR_SUCCESS) {
        mosquitto_loop_start(m_mosquitto);
        return true;
    }

    emit errorOccurred(QString("Failed to connect: %1").arg(mosquitto_strerror(result)));
    return false;
}

void MQTTService::disconnect() {
    if (m_mosquitto) {
        mosquitto_disconnect(m_mosquitto);
        mosquitto_loop_stop(m_mosquitto, false);
    }
}

bool MQTTService::publish(const QString& topic, const QByteArray& payload, int qos) {
    if (!m_mosquitto || !m_connected) return false;

    int result = mosquitto_publish(m_mosquitto, nullptr,
        topic.toUtf8().constData(),
        payload.size(), payload.constData(), qos, false);

    return result == MOSQ_ERR_SUCCESS;
}

bool MQTTService::subscribe(const QString& topic, int qos) {
    if (!m_mosquitto || !m_connected) return false;

    int result = mosquitto_subscribe(m_mosquitto, nullptr,
        topic.toUtf8().constData(), qos);

    return result == MOSQ_ERR_SUCCESS;
}

void MQTTService::onConnect(struct mosquitto *mosq, void *obj, int result) {
    auto *service = static_cast<MQTTService*>(obj);
    if (result == 0) {
        service->m_connected = true;
        emit service->connected();
    } else {
        emit service->errorOccurred(QString("Connection failed: %1").arg(result));
    }
}

void MQTTService::onDisconnect(struct mosquitto *mosq, void *obj, int result) {
    auto *service = static_cast<MQTTService*>(obj);
    service->m_connected = false;
    emit service->disconnected();
}

void MQTTService::onMessage(struct mosquitto *mosq, void *obj,
                            const struct mosquitto_message *message) {
    auto *service = static_cast<MQTTService*>(obj);
    QString topic = QString::fromUtf8(static_cast<const char*>(message->topic));
    QByteArray payload(static_cast<const char*>(message->payload), message->payloadlen);
    emit service->messageReceived(topic, payload);
}
