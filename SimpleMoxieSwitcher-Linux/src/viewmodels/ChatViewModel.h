#pragma once
#include <QObject>
#include <QAbstractListModel>
#include "../models/Conversation.h"
#include "../services/AIProviderService.h"

class ChatViewModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QString currentMessage READ currentMessage WRITE setCurrentMessage NOTIFY currentMessageChanged)
    Q_PROPERTY(bool isProcessing READ isProcessing NOTIFY isProcessingChanged)
    Q_PROPERTY(QString selectedModel READ selectedModel WRITE setSelectedModel NOTIFY selectedModelChanged)
    Q_PROPERTY(double temperature READ temperature WRITE setTemperature NOTIFY temperatureChanged)

public:
    enum ChatRoles {
        RoleRole = Qt::UserRole + 1,
        ContentRole,
        TimestampRole,
        IsUserRole
    };

    explicit ChatViewModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString currentMessage() const { return m_currentMessage; }
    void setCurrentMessage(const QString &msg);

    bool isProcessing() const { return m_isProcessing; }

    QString selectedModel() const { return m_selectedModel; }
    void setSelectedModel(const QString &model);

    double temperature() const { return m_temperature; }
    void setTemperature(double temp);

public slots:
    void sendMessage();
    void clearConversation();
    void regenerateLastResponse();
    void exportConversation();
    void loadConversation(const QString &id);

signals:
    void currentMessageChanged();
    void isProcessingChanged();
    void selectedModelChanged();
    void temperatureChanged();
    void errorOccurred(const QString &error);

private:
    Conversation m_conversation;
    QString m_currentMessage;
    bool m_isProcessing = false;
    QString m_selectedModel = "gpt-3.5-turbo";
    double m_temperature = 0.7;
    AIProviderService *m_aiService;

    void processAIResponse(const QString &response);
};