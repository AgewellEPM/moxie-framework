#pragma once
#include <QObject>
#include <QString>
#include <QProcess>
#include <QTimer>

namespace SimpleMoxieSwitcher {

class DockerService : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isDockerRunning READ isDockerRunning NOTIFY dockerStatusChanged)
    Q_PROPERTY(bool isContainerRunning READ isContainerRunning NOTIFY containerStatusChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit DockerService(QObject *parent = nullptr);
    ~DockerService();

    bool isDockerRunning() const { return m_dockerRunning; }
    bool isContainerRunning() const { return m_containerRunning; }
    QString status() const { return m_status; }

    Q_INVOKABLE void checkDockerStatus();
    Q_INVOKABLE void startContainer();
    Q_INVOKABLE void stopContainer();
    Q_INVOKABLE void restartContainer();
    Q_INVOKABLE void pullImage();

signals:
    void dockerStatusChanged();
    void containerStatusChanged();
    void statusChanged();
    void errorOccurred(const QString &error);
    void containerStarted();
    void containerStopped();

private slots:
    void onProcessFinished(int exitCode, QProcess::ExitStatus status);
    void onProcessError(QProcess::ProcessError error);

private:
    void executeCommand(const QStringList &args);
    void updateStatus(const QString &newStatus);

    QProcess *m_process;
    QTimer *m_statusTimer;
    bool m_dockerRunning = false;
    bool m_containerRunning = false;
    QString m_status = "Checking...";
    QString m_containerName = "openmoxie-server";
    QString m_imageName = "openmoxie/openmoxie-server:latest";
};

} // namespace SimpleMoxieSwitcher
