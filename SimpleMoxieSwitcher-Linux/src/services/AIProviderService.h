#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>

class AIProviderService : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isProcessing READ isProcessing NOTIFY isProcessingChanged)
    Q_PROPERTY(QString currentProvider READ currentProvider WRITE setCurrentProvider NOTIFY currentProviderChanged)

public:
    enum AIProvider {
        OpenAI,
        Anthropic,
        Gemini,      // Google - free tier available
        DeepSeek,    // Budget-friendly
        Ollama,      // 100% free - runs locally
        GroqCloud    // Free tier with fast inference
    };
    Q_ENUM(AIProvider)

    explicit AIProviderService(QObject *parent = nullptr);

    bool isProcessing() const { return m_isProcessing; }

    QString currentProvider() const { return m_currentProvider; }
    void setCurrentProvider(const QString &provider);

    Q_INVOKABLE void sendRequest(const QString &prompt, const QString &model = "", double temperature = 0.7);
    Q_INVOKABLE void sendChatRequest(const QList<QJsonObject> &messages, const QString &model = "");

    Q_INVOKABLE QString getApiKey() const;
    Q_INVOKABLE void setApiKey(const QString &key);

    Q_INVOKABLE QStringList availableModels() const;
    Q_INVOKABLE QStringList availableProviders() const;
    Q_INVOKABLE bool providerRequiresApiKey(const QString &provider) const;
    Q_INVOKABLE QString getProviderInfo(const QString &provider) const;
    double estimateCost(int tokens, const QString &model) const;

signals:
    void responseReceived(const QString &response);
    void errorOccurred(const QString &error);
    void isProcessingChanged();
    void currentProviderChanged();
    void tokensUsed(int inputTokens, int outputTokens);
    void streamingData(const QString &chunk);

private slots:
    void handleNetworkReply(QNetworkReply *reply);
    void handleStreamingReply();

private:
    QNetworkAccessManager *m_networkManager;
    bool m_isProcessing = false;
    QString m_currentProvider = "Ollama";  // Default to free local option
    QString m_apiKey;
    QNetworkReply *m_currentReply = nullptr;

    QJsonObject createOpenAIRequest(const QString &prompt, const QString &model, double temperature);
    QJsonObject createAnthropicRequest(const QString &prompt, const QString &model, double temperature);
    QJsonObject createGeminiRequest(const QString &prompt, const QString &model, double temperature);
    QJsonObject createOllamaRequest(const QString &prompt, const QString &model, double temperature);
    void parseOpenAIResponse(const QByteArray &data);
    void parseAnthropicResponse(const QByteArray &data);
    void parseGeminiResponse(const QByteArray &data);
    void parseOllamaResponse(const QByteArray &data);

    QString getDefaultModel() const;
};