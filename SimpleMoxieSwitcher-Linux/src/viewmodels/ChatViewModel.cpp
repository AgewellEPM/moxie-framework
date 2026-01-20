#include "ChatViewModel.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonArray>

ChatViewModel::ChatViewModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_aiService(new AIProviderService(this)) {

    connect(m_aiService, &AIProviderService::responseReceived,
            this, &ChatViewModel::processAIResponse);
    connect(m_aiService, &AIProviderService::errorOccurred,
            this, &ChatViewModel::errorOccurred);
}

int ChatViewModel::rowCount(const QModelIndex &parent) const {
    Q_UNUSED(parent)
    return m_conversation.messages.size();
}

QVariant ChatViewModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_conversation.messages.size())
        return QVariant();

    const Message &msg = m_conversation.messages[index.row()];

    switch (role) {
        case RoleRole:
            return static_cast<int>(msg.role);
        case ContentRole:
            return msg.content;
        case TimestampRole:
            return msg.timestamp.toString("hh:mm:ss");
        case IsUserRole:
            return msg.role == ConversationRole::User;
        default:
            return QVariant();
    }
}

QHash<int, QByteArray> ChatViewModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[RoleRole] = "role";
    roles[ContentRole] = "content";
    roles[TimestampRole] = "timestamp";
    roles[IsUserRole] = "isUser";
    return roles;
}

void ChatViewModel::setCurrentMessage(const QString &msg) {
    if (m_currentMessage != msg) {
        m_currentMessage = msg;
        emit currentMessageChanged();
    }
}

void ChatViewModel::setSelectedModel(const QString &model) {
    if (m_selectedModel != model) {
        m_selectedModel = model;
        emit selectedModelChanged();
    }
}

void ChatViewModel::setTemperature(double temp) {
    if (m_temperature != temp) {
        m_temperature = temp;
        emit temperatureChanged();
    }
}

void ChatViewModel::sendMessage() {
    if (m_currentMessage.isEmpty() || m_isProcessing)
        return;

    // Add user message
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    Message userMsg{ConversationRole::User, m_currentMessage, QDateTime::currentDateTime()};
    m_conversation.addMessage(userMsg);
    endInsertRows();

    // Clear input and set processing
    m_isProcessing = true;
    emit isProcessingChanged();

    QString temp = m_currentMessage;
    setCurrentMessage("");

    // Send to AI
    m_aiService->sendRequest(temp, m_selectedModel, m_temperature);
}

void ChatViewModel::clearConversation() {
    beginResetModel();
    m_conversation.messages.clear();
    endResetModel();
}

void ChatViewModel::regenerateLastResponse() {
    if (m_conversation.messages.isEmpty())
        return;

    // Find last user message
    for (int i = m_conversation.messages.size() - 1; i >= 0; --i) {
        if (m_conversation.messages[i].role == ConversationRole::User) {
            // Remove all messages after this user message
            beginRemoveRows(QModelIndex(), i + 1, m_conversation.messages.size() - 1);
            while (m_conversation.messages.size() > i + 1) {
                m_conversation.messages.removeLast();
            }
            endRemoveRows();

            // Resend the user message
            m_isProcessing = true;
            emit isProcessingChanged();
            m_aiService->sendRequest(m_conversation.messages[i].content, m_selectedModel, m_temperature);
            break;
        }
    }
}

void ChatViewModel::exportConversation() {
    QJsonArray messages;
    for (const auto &msg : m_conversation.messages) {
        messages.append(msg.toJson());
    }

    QJsonDocument doc(messages);
    QString json = doc.toJson(QJsonDocument::Indented);

    qDebug() << "Exported conversation:" << json;
    // TODO: Save to file
}

void ChatViewModel::loadConversation(const QString &id) {
    // TODO: Load from database
    qDebug() << "Loading conversation:" << id;
}

void ChatViewModel::processAIResponse(const QString &response) {
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    Message aiMsg{ConversationRole::Assistant, response, QDateTime::currentDateTime()};
    m_conversation.addMessage(aiMsg);
    endInsertRows();

    m_isProcessing = false;
    emit isProcessingChanged();
}