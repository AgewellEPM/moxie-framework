#include "DockerService.h"
#include <QDebug>

namespace SimpleMoxieSwitcher {

DockerService::DockerService(QObject *parent)
    : QObject(parent)
    , m_process(new QProcess(this))
    , m_statusTimer(new QTimer(this))
{
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &DockerService::onProcessFinished);
    connect(m_process, &QProcess::errorOccurred,
            this, &DockerService::onProcessError);

    // Check status every 30 seconds
    connect(m_statusTimer, &QTimer::timeout, this, &DockerService::checkDockerStatus);
    m_statusTimer->start(30000);

    // Initial check
    checkDockerStatus();
}

DockerService::~DockerService() {
    m_statusTimer->stop();
    if (m_process->state() != QProcess::NotRunning) {
        m_process->kill();
        m_process->waitForFinished(3000);
    }
}

void DockerService::checkDockerStatus() {
    QProcess checkProcess;
    checkProcess.start("docker", {"info"});
    checkProcess.waitForFinished(5000);

    bool wasDockerRunning = m_dockerRunning;
    m_dockerRunning = (checkProcess.exitCode() == 0);

    if (m_dockerRunning != wasDockerRunning) {
        emit dockerStatusChanged();
    }

    if (m_dockerRunning) {
        // Check if container is running
        QProcess containerCheck;
        containerCheck.start("docker", {"ps", "-q", "-f", QString("name=%1").arg(m_containerName)});
        containerCheck.waitForFinished(5000);

        bool wasContainerRunning = m_containerRunning;
        m_containerRunning = !containerCheck.readAllStandardOutput().trimmed().isEmpty();

        if (m_containerRunning != wasContainerRunning) {
            emit containerStatusChanged();
        }

        if (m_containerRunning) {
            updateStatus("OpenMoxie running");
        } else {
            updateStatus("Container stopped");
        }
    } else {
        m_containerRunning = false;
        emit containerStatusChanged();
        updateStatus("Docker not running");
    }
}

void DockerService::startContainer() {
    if (!m_dockerRunning) {
        emit errorOccurred("Docker is not running. Please start Docker Desktop first.");
        return;
    }

    updateStatus("Starting OpenMoxie...");

    QStringList args = {
        "run", "-d",
        "--name", m_containerName,
        "-p", "8000:8000",
        "-p", "1883:1883",
        "-v", "openmoxie-data:/app/data",
        "--restart", "unless-stopped",
        m_imageName
    };

    executeCommand(args);
}

void DockerService::stopContainer() {
    updateStatus("Stopping OpenMoxie...");
    executeCommand({"stop", m_containerName});
}

void DockerService::restartContainer() {
    updateStatus("Restarting OpenMoxie...");
    executeCommand({"restart", m_containerName});
}

void DockerService::pullImage() {
    updateStatus("Updating OpenMoxie...");
    executeCommand({"pull", m_imageName});
}

void DockerService::executeCommand(const QStringList &args) {
    if (m_process->state() != QProcess::NotRunning) {
        emit errorOccurred("Another Docker operation is in progress");
        return;
    }

    m_process->start("docker", args);
}

void DockerService::onProcessFinished(int exitCode, QProcess::ExitStatus status) {
    Q_UNUSED(status);

    QString output = m_process->readAllStandardOutput();
    QString error = m_process->readAllStandardError();

    if (exitCode == 0) {
        qDebug() << "Docker command succeeded:" << output;
        checkDockerStatus();

        if (m_containerRunning) {
            emit containerStarted();
        } else {
            emit containerStopped();
        }
    } else {
        qWarning() << "Docker command failed:" << error;
        emit errorOccurred(error.isEmpty() ? "Docker command failed" : error);
        checkDockerStatus();
    }
}

void DockerService::onProcessError(QProcess::ProcessError error) {
    QString errorMsg;
    switch (error) {
        case QProcess::FailedToStart:
            errorMsg = "Docker command failed to start. Is Docker installed?";
            break;
        case QProcess::Crashed:
            errorMsg = "Docker process crashed";
            break;
        case QProcess::Timedout:
            errorMsg = "Docker command timed out";
            break;
        default:
            errorMsg = "Unknown Docker error";
            break;
    }

    emit errorOccurred(errorMsg);
    checkDockerStatus();
}

void DockerService::updateStatus(const QString &newStatus) {
    if (m_status != newStatus) {
        m_status = newStatus;
        emit statusChanged();
    }
}

} // namespace SimpleMoxieSwitcher
