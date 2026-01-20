#pragma once
#include <QObject>
#include <QTimer>
#include "../services/MQTTService.h"

class ControlsViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)
    Q_PROPERTY(double batteryLevel READ batteryLevel NOTIFY batteryLevelChanged)
    Q_PROPERTY(double volumeLevel READ volumeLevel WRITE setVolumeLevel NOTIFY volumeLevelChanged)
    Q_PROPERTY(bool isSleepMode READ isSleepMode WRITE setIsSleepMode NOTIFY isSleepModeChanged)
    Q_PROPERTY(int brightness READ brightness WRITE setBrightness NOTIFY brightnessChanged)
    Q_PROPERTY(QString robotStatus READ robotStatus NOTIFY robotStatusChanged)
    Q_PROPERTY(bool autoShutdownEnabled READ autoShutdownEnabled WRITE setAutoShutdownEnabled NOTIFY autoShutdownEnabledChanged)
    Q_PROPERTY(int autoShutdownMinutes READ autoShutdownMinutes WRITE setAutoShutdownMinutes NOTIFY autoShutdownMinutesChanged)

public:
    explicit ControlsViewModel(QObject *parent = nullptr);
    ~ControlsViewModel();

    bool isConnected() const { return m_isConnected; }
    double batteryLevel() const { return m_batteryLevel; }

    double volumeLevel() const { return m_volumeLevel; }
    void setVolumeLevel(double level);

    bool isSleepMode() const { return m_isSleepMode; }
    void setIsSleepMode(bool sleep);

    int brightness() const { return m_brightness; }
    void setBrightness(int level);

    QString robotStatus() const { return m_robotStatus; }

    bool autoShutdownEnabled() const { return m_autoShutdownEnabled; }
    void setAutoShutdownEnabled(bool enabled);

    int autoShutdownMinutes() const { return m_autoShutdownMinutes; }
    void setAutoShutdownMinutes(int minutes);

public slots:
    void connectToRobot();
    void disconnectFromRobot();
    void sendCommand(const QString &command);
    void rebootRobot();
    void shutdownRobot();
    void wakeUpRobot();
    void playAnimation(const QString &animationName);
    void sayPhrase(const QString &text);
    void updateStatus();

signals:
    void isConnectedChanged();
    void batteryLevelChanged();
    void volumeLevelChanged();
    void isSleepModeChanged();
    void brightnessChanged();
    void robotStatusChanged();
    void autoShutdownEnabledChanged();
    void autoShutdownMinutesChanged();
    void commandSent(const QString &command);
    void errorOccurred(const QString &error);

private:
    MQTTService *m_mqttService;
    QTimer *m_statusTimer;

    bool m_isConnected = false;
    double m_batteryLevel = 75.0;
    double m_volumeLevel = 50.0;
    bool m_isSleepMode = false;
    int m_brightness = 70;
    QString m_robotStatus = "Idle";
    bool m_autoShutdownEnabled = false;
    int m_autoShutdownMinutes = 30;

    void onMqttConnected();
    void onMqttDisconnected();
    void onMqttMessageReceived(const QString &topic, const QByteArray &message);
    void sendMqttCommand(const QString &topic, const QString &payload);
};