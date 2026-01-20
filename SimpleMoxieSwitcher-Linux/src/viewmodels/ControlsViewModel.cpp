#include "ControlsViewModel.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>

ControlsViewModel::ControlsViewModel(QObject *parent)
    : QObject(parent)
    , m_mqttService(new MQTTService(this))
    , m_statusTimer(new QTimer(this)) {

    connect(m_mqttService, &MQTTService::connected, this, &ControlsViewModel::onMqttConnected);
    connect(m_mqttService, &MQTTService::disconnected, this, &ControlsViewModel::onMqttDisconnected);
    connect(m_mqttService, &MQTTService::messageReceived, this, &ControlsViewModel::onMqttMessageReceived);

    m_statusTimer->setInterval(5000); // Update status every 5 seconds
    connect(m_statusTimer, &QTimer::timeout, this, &ControlsViewModel::updateStatus);
}

ControlsViewModel::~ControlsViewModel() {
    if (m_isConnected) {
        disconnectFromRobot();
    }
}

void ControlsViewModel::setVolumeLevel(double level) {
    if (m_volumeLevel != level) {
        m_volumeLevel = qBound(0.0, level, 100.0);
        emit volumeLevelChanged();
        sendMqttCommand("moxie/control/volume", QString::number(m_volumeLevel));
    }
}

void ControlsViewModel::setIsSleepMode(bool sleep) {
    if (m_isSleepMode != sleep) {
        m_isSleepMode = sleep;
        emit isSleepModeChanged();
        sendMqttCommand("moxie/control/sleep", sleep ? "true" : "false");
    }
}

void ControlsViewModel::setBrightness(int level) {
    if (m_brightness != level) {
        m_brightness = qBound(0, level, 100);
        emit brightnessChanged();
        sendMqttCommand("moxie/control/brightness", QString::number(m_brightness));
    }
}

void ControlsViewModel::setAutoShutdownEnabled(bool enabled) {
    if (m_autoShutdownEnabled != enabled) {
        m_autoShutdownEnabled = enabled;
        emit autoShutdownEnabledChanged();
        sendMqttCommand("moxie/control/auto_shutdown", enabled ? "true" : "false");
    }
}

void ControlsViewModel::setAutoShutdownMinutes(int minutes) {
    if (m_autoShutdownMinutes != minutes) {
        m_autoShutdownMinutes = minutes;
        emit autoShutdownMinutesChanged();
        sendMqttCommand("moxie/control/auto_shutdown_time", QString::number(minutes));
    }
}

void ControlsViewModel::connectToRobot() {
    if (!m_isConnected) {
        m_mqttService->connect("localhost", 1883);
        qDebug() << "Connecting to Moxie...";
    }
}

void ControlsViewModel::disconnectFromRobot() {
    if (m_isConnected) {
        m_mqttService->disconnect();
        m_statusTimer->stop();
        qDebug() << "Disconnecting from Moxie...";
    }
}

void ControlsViewModel::sendCommand(const QString &command) {
    sendMqttCommand("moxie/control/command", command);
    emit commandSent(command);
}

void ControlsViewModel::rebootRobot() {
    sendMqttCommand("moxie/control/reboot", "true");
    m_robotStatus = "Rebooting...";
    emit robotStatusChanged();
}

void ControlsViewModel::shutdownRobot() {
    sendMqttCommand("moxie/control/shutdown", "true");
    m_robotStatus = "Shutting down...";
    emit robotStatusChanged();
}

void ControlsViewModel::wakeUpRobot() {
    setIsSleepMode(false);
    sendMqttCommand("moxie/control/wakeup", "true");
    m_robotStatus = "Waking up...";
    emit robotStatusChanged();
}

void ControlsViewModel::playAnimation(const QString &animationName) {
    sendMqttCommand("moxie/control/animation", animationName);
}

void ControlsViewModel::sayPhrase(const QString &text) {
    sendMqttCommand("moxie/control/speak", text);
}

void ControlsViewModel::updateStatus() {
    sendMqttCommand("moxie/status/request", "all");
}

void ControlsViewModel::onMqttConnected() {
    m_isConnected = true;
    emit isConnectedChanged();

    // Subscribe to status topics
    m_mqttService->subscribe("moxie/status/+");

    // Start status updates
    m_statusTimer->start();
    updateStatus();

    m_robotStatus = "Connected";
    emit robotStatusChanged();

    qDebug() << "Connected to Moxie!";
}

void ControlsViewModel::onMqttDisconnected() {
    m_isConnected = false;
    emit isConnectedChanged();

    m_statusTimer->stop();

    m_robotStatus = "Disconnected";
    emit robotStatusChanged();

    qDebug() << "Disconnected from Moxie";
}

void ControlsViewModel::onMqttMessageReceived(const QString &topic, const QByteArray &message) {
    QJsonDocument doc = QJsonDocument::fromJson(message);
    if (!doc.isObject()) return;

    QJsonObject obj = doc.object();

    if (topic == "moxie/status/battery") {
        double battery = obj["level"].toDouble();
        if (m_batteryLevel != battery) {
            m_batteryLevel = battery;
            emit batteryLevelChanged();
        }
    } else if (topic == "moxie/status/volume") {
        double volume = obj["level"].toDouble();
        if (m_volumeLevel != volume) {
            m_volumeLevel = volume;
            emit volumeLevelChanged();
        }
    } else if (topic == "moxie/status/sleep") {
        bool sleep = obj["sleeping"].toBool();
        if (m_isSleepMode != sleep) {
            m_isSleepMode = sleep;
            emit isSleepModeChanged();
        }
    } else if (topic == "moxie/status/general") {
        QString status = obj["status"].toString();
        if (m_robotStatus != status) {
            m_robotStatus = status;
            emit robotStatusChanged();
        }
    }
}

void ControlsViewModel::sendMqttCommand(const QString &topic, const QString &payload) {
    if (m_isConnected) {
        QJsonObject obj;
        obj["command"] = payload;
        obj["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);

        QJsonDocument doc(obj);
        m_mqttService->publish(topic, doc.toJson(QJsonDocument::Compact));
    } else {
        emit errorOccurred("Not connected to robot");
    }
}