#include "AIProviderService.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonArray>
#include <QDebug>
#include <QUrlQuery>

AIProviderService::AIProviderService(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this)) {

    connect(m_networkManager, &QNetworkAccessManager::finished,
            this, &AIProviderService::handleNetworkReply);

    // Default to Ollama (free, no API key required)
    m_currentProvider = "Ollama";
}

void AIProviderService::setCurrentProvider(const QString &provider) {
    if (m_currentProvider != provider) {
        m_currentProvider = provider;
        emit currentProviderChanged();
    }
}

QStringList AIProviderService::availableProviders() const {
    return {
        "Ollama",      // Free - local
        "GroqCloud",   // Free tier
        "Gemini",      // Free tier
        "DeepSeek",    // Budget-friendly
        "OpenAI",      // Paid
        "Anthropic"    // Paid
    };
}

bool AIProviderService::providerRequiresApiKey(const QString &provider) const {
    return provider != "Ollama";  // Only Ollama doesn't need an API key
}

QString AIProviderService::getProviderInfo(const QString &provider) const {
    if (provider == "Ollama") {
        return "100% FREE - Runs locally on your computer. Install from https://ollama.ai";
    } else if (provider == "GroqCloud") {
        return "FREE tier: 14,400 requests/day. Ultra-fast inference. Get key at https://console.groq.com";
    } else if (provider == "Gemini") {
        return "FREE tier: 15 requests/minute. Get key at https://aistudio.google.com/apikey";
    } else if (provider == "DeepSeek") {
        return "Very affordable pricing. Get key at https://platform.deepseek.com";
    } else if (provider == "OpenAI") {
        return "Industry standard. Pay-as-you-go. Get key at https://platform.openai.com/api-keys";
    } else if (provider == "Anthropic") {
        return "Claude models. Pay-as-you-go. Get key at https://console.anthropic.com";
    }
    return "";
}

QString AIProviderService::getDefaultModel() const {
    if (m_currentProvider == "Ollama") {
        return "llama3.2";
    } else if (m_currentProvider == "GroqCloud") {
        return "llama-3.3-70b-versatile";
    } else if (m_currentProvider == "Gemini") {
        return "gemini-1.5-flash";
    } else if (m_currentProvider == "DeepSeek") {
        return "deepseek-chat";
    } else if (m_currentProvider == "OpenAI") {
        return "gpt-4o";
    } else if (m_currentProvider == "Anthropic") {
        return "claude-3-5-sonnet-20241022";
    }
    return "llama3.2";
}

void AIProviderService::sendRequest(const QString &prompt, const QString &model, double temperature) {
    if (m_isProcessing) {
        emit errorOccurred("Already processing a request");
        return;
    }

    // Check if API key is required
    if (providerRequiresApiKey(m_currentProvider) && m_apiKey.isEmpty()) {
        emit errorOccurred("API key not configured for " + m_currentProvider);
        return;
    }

    m_isProcessing = true;
    emit isProcessingChanged();

    QString actualModel = model.isEmpty() ? getDefaultModel() : model;
    QNetworkRequest request;
    QJsonObject json;

    if (m_currentProvider == "OpenAI") {
        request.setUrl(QUrl("https://api.openai.com/v1/chat/completions"));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("Authorization", QString("Bearer %1").arg(m_apiKey).toUtf8());
        json = createOpenAIRequest(prompt, actualModel, temperature);
    } else if (m_currentProvider == "Anthropic") {
        request.setUrl(QUrl("https://api.anthropic.com/v1/messages"));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("x-api-key", m_apiKey.toUtf8());
        request.setRawHeader("anthropic-version", "2023-06-01");
        json = createAnthropicRequest(prompt, actualModel, temperature);
    } else if (m_currentProvider == "Gemini") {
        QString url = QString("https://generativelanguage.googleapis.com/v1beta/models/%1:generateContent?key=%2")
            .arg(actualModel).arg(m_apiKey);
        request.setUrl(QUrl(url));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        json = createGeminiRequest(prompt, actualModel, temperature);
    } else if (m_currentProvider == "DeepSeek" || m_currentProvider == "GroqCloud") {
        QString endpoint = (m_currentProvider == "DeepSeek")
            ? "https://api.deepseek.com/v1/chat/completions"
            : "https://api.groq.com/openai/v1/chat/completions";
        request.setUrl(QUrl(endpoint));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("Authorization", QString("Bearer %1").arg(m_apiKey).toUtf8());
        json = createOpenAIRequest(prompt, actualModel, temperature);  // OpenAI-compatible
    } else if (m_currentProvider == "Ollama") {
        request.setUrl(QUrl("http://localhost:11434/api/chat"));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        json = createOllamaRequest(prompt, actualModel, temperature);
    } else {
        m_isProcessing = false;
        emit isProcessingChanged();
        emit errorOccurred("Unsupported provider: " + m_currentProvider);
        return;
    }

    QJsonDocument doc(json);
    m_currentReply = m_networkManager->post(request, doc.toJson());
}

void AIProviderService::sendChatRequest(const QList<QJsonObject> &messages, const QString &model) {
    if (m_isProcessing) {
        emit errorOccurred("Already processing a request");
        return;
    }

    if (providerRequiresApiKey(m_currentProvider) && m_apiKey.isEmpty()) {
        emit errorOccurred("API key not configured for " + m_currentProvider);
        return;
    }

    m_isProcessing = true;
    emit isProcessingChanged();

    QString actualModel = model.isEmpty() ? getDefaultModel() : model;
    QNetworkRequest request;

    // Build messages array
    QJsonArray messagesArray;
    for (const auto &msg : messages) {
        messagesArray.append(msg);
    }

    QJsonObject json;

    if (m_currentProvider == "Ollama") {
        request.setUrl(QUrl("http://localhost:11434/api/chat"));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        json["model"] = actualModel;
        json["messages"] = messagesArray;
        json["stream"] = false;
    } else if (m_currentProvider == "OpenAI" || m_currentProvider == "DeepSeek" || m_currentProvider == "GroqCloud") {
        QString endpoint;
        if (m_currentProvider == "OpenAI") {
            endpoint = "https://api.openai.com/v1/chat/completions";
        } else if (m_currentProvider == "DeepSeek") {
            endpoint = "https://api.deepseek.com/v1/chat/completions";
        } else {
            endpoint = "https://api.groq.com/openai/v1/chat/completions";
        }
        request.setUrl(QUrl(endpoint));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("Authorization", QString("Bearer %1").arg(m_apiKey).toUtf8());
        json["model"] = actualModel;
        json["messages"] = messagesArray;
        json["temperature"] = 0.7;
    } else if (m_currentProvider == "Anthropic") {
        request.setUrl(QUrl("https://api.anthropic.com/v1/messages"));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("x-api-key", m_apiKey.toUtf8());
        request.setRawHeader("anthropic-version", "2023-06-01");
        json["model"] = actualModel;
        json["messages"] = messagesArray;
        json["max_tokens"] = 4096;
    } else if (m_currentProvider == "Gemini") {
        QString url = QString("https://generativelanguage.googleapis.com/v1beta/models/%1:generateContent?key=%2")
            .arg(actualModel).arg(m_apiKey);
        request.setUrl(QUrl(url));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

        // Convert to Gemini format
        QJsonArray contents;
        for (const auto &msg : messages) {
            QJsonObject content;
            QString role = msg["role"].toString();
            content["role"] = (role == "assistant") ? "model" : "user";
            QJsonArray parts;
            QJsonObject textPart;
            textPart["text"] = msg["content"].toString();
            parts.append(textPart);
            content["parts"] = parts;
            contents.append(content);
        }
        json["contents"] = contents;
    }

    QJsonDocument doc(json);
    m_currentReply = m_networkManager->post(request, doc.toJson());
}

QString AIProviderService::getApiKey() const {
    return m_apiKey;
}

void AIProviderService::setApiKey(const QString &key) {
    m_apiKey = key;
}

QStringList AIProviderService::availableModels() const {
    if (m_currentProvider == "OpenAI") {
        return {"gpt-4o", "gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"};
    } else if (m_currentProvider == "Anthropic") {
        return {"claude-3-5-sonnet-20241022", "claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307"};
    } else if (m_currentProvider == "Gemini") {
        return {"gemini-2.0-flash-exp", "gemini-1.5-pro", "gemini-1.5-flash"};
    } else if (m_currentProvider == "DeepSeek") {
        return {"deepseek-chat", "deepseek-coder", "deepseek-reasoner"};
    } else if (m_currentProvider == "Ollama") {
        return {"llama3.2", "llama3.1", "mistral", "phi3", "gemma2", "qwen2.5"};
    } else if (m_currentProvider == "GroqCloud") {
        return {"llama-3.3-70b-versatile", "llama-3.1-8b-instant", "mixtral-8x7b-32768", "gemma2-9b-it"};
    }
    return {};
}

double AIProviderService::estimateCost(int tokens, const QString &model) const {
    // Rough estimates per 1K tokens
    if (model.contains("gpt-4")) {
        return (tokens / 1000.0) * 0.03;
    } else if (model.contains("gpt-3.5")) {
        return (tokens / 1000.0) * 0.002;
    } else if (model.contains("claude-3-opus")) {
        return (tokens / 1000.0) * 0.015;
    } else if (model.contains("claude-3-sonnet") || model.contains("claude-3-5")) {
        return (tokens / 1000.0) * 0.003;
    } else if (model.contains("deepseek")) {
        return (tokens / 1000.0) * 0.0002;  // Very cheap
    } else if (model.contains("llama") || model.contains("ollama") || model.contains("groq")) {
        return 0.0;  // Free
    } else if (model.contains("gemini")) {
        return 0.0;  // Free tier
    }
    return 0.0;
}

void AIProviderService::handleNetworkReply(QNetworkReply *reply) {
    reply->deleteLater();

    if (reply != m_currentReply) {
        return;
    }

    m_isProcessing = false;
    emit isProcessingChanged();

    if (reply->error() != QNetworkReply::NoError) {
        QString errorMsg = reply->errorString();
        if (m_currentProvider == "Ollama" && reply->error() == QNetworkReply::ConnectionRefusedError) {
            errorMsg = "Cannot connect to Ollama. Please ensure Ollama is installed and running (https://ollama.ai)";
        }
        emit errorOccurred("Network error: " + errorMsg);
        return;
    }

    QByteArray data = reply->readAll();

    if (m_currentProvider == "OpenAI" || m_currentProvider == "DeepSeek" || m_currentProvider == "GroqCloud") {
        parseOpenAIResponse(data);
    } else if (m_currentProvider == "Anthropic") {
        parseAnthropicResponse(data);
    } else if (m_currentProvider == "Gemini") {
        parseGeminiResponse(data);
    } else if (m_currentProvider == "Ollama") {
        parseOllamaResponse(data);
    }
}

void AIProviderService::handleStreamingReply() {
    // TODO: Implement streaming support
}

QJsonObject AIProviderService::createOpenAIRequest(const QString &prompt, const QString &model, double temperature) {
    QJsonObject json;
    json["model"] = model;

    QJsonArray messages;
    QJsonObject userMessage;
    userMessage["role"] = "user";
    userMessage["content"] = prompt;
    messages.append(userMessage);

    json["messages"] = messages;
    json["temperature"] = temperature;
    json["stream"] = false;

    return json;
}

QJsonObject AIProviderService::createAnthropicRequest(const QString &prompt, const QString &model, double temperature) {
    QJsonObject json;
    json["model"] = model;

    QJsonArray messages;
    QJsonObject userMessage;
    userMessage["role"] = "user";
    userMessage["content"] = prompt;
    messages.append(userMessage);

    json["messages"] = messages;
    json["max_tokens"] = 4096;
    json["temperature"] = temperature;

    return json;
}

QJsonObject AIProviderService::createGeminiRequest(const QString &prompt, const QString &model, double temperature) {
    Q_UNUSED(model);

    QJsonObject json;
    QJsonArray contents;
    QJsonObject content;
    content["role"] = "user";

    QJsonArray parts;
    QJsonObject textPart;
    textPart["text"] = prompt;
    parts.append(textPart);
    content["parts"] = parts;
    contents.append(content);

    json["contents"] = contents;

    QJsonObject generationConfig;
    generationConfig["temperature"] = temperature;
    generationConfig["maxOutputTokens"] = 4096;
    json["generationConfig"] = generationConfig;

    return json;
}

QJsonObject AIProviderService::createOllamaRequest(const QString &prompt, const QString &model, double temperature) {
    QJsonObject json;
    json["model"] = model;

    QJsonArray messages;
    QJsonObject userMessage;
    userMessage["role"] = "user";
    userMessage["content"] = prompt;
    messages.append(userMessage);

    json["messages"] = messages;
    json["stream"] = false;

    QJsonObject options;
    options["temperature"] = temperature;
    json["options"] = options;

    return json;
}

void AIProviderService::parseOpenAIResponse(const QByteArray &data) {
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
        emit errorOccurred("Invalid response format");
        return;
    }

    QJsonObject obj = doc.object();

    if (obj.contains("error")) {
        QJsonObject error = obj["error"].toObject();
        emit errorOccurred("API Error: " + error["message"].toString());
        return;
    }

    if (obj.contains("choices")) {
        QJsonArray choices = obj["choices"].toArray();
        if (!choices.isEmpty()) {
            QJsonObject choice = choices[0].toObject();
            QJsonObject message = choice["message"].toObject();
            QString content = message["content"].toString();
            emit responseReceived(content);

            // Extract token usage
            if (obj.contains("usage")) {
                QJsonObject usage = obj["usage"].toObject();
                int promptTokens = usage["prompt_tokens"].toInt();
                int completionTokens = usage["completion_tokens"].toInt();
                emit tokensUsed(promptTokens, completionTokens);
            }
        }
    }
}

void AIProviderService::parseAnthropicResponse(const QByteArray &data) {
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
        emit errorOccurred("Invalid response format");
        return;
    }

    QJsonObject obj = doc.object();

    if (obj.contains("error")) {
        QJsonObject error = obj["error"].toObject();
        emit errorOccurred("API Error: " + error["message"].toString());
        return;
    }

    if (obj.contains("content")) {
        QJsonArray content = obj["content"].toArray();
        if (!content.isEmpty()) {
            QJsonObject contentObj = content[0].toObject();
            QString text = contentObj["text"].toString();
            emit responseReceived(text);
        }
    }

    // Extract token usage
    if (obj.contains("usage")) {
        QJsonObject usage = obj["usage"].toObject();
        int inputTokens = usage["input_tokens"].toInt();
        int outputTokens = usage["output_tokens"].toInt();
        emit tokensUsed(inputTokens, outputTokens);
    }
}

void AIProviderService::parseGeminiResponse(const QByteArray &data) {
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
        emit errorOccurred("Invalid response format");
        return;
    }

    QJsonObject obj = doc.object();

    if (obj.contains("error")) {
        QJsonObject error = obj["error"].toObject();
        emit errorOccurred("API Error: " + error["message"].toString());
        return;
    }

    if (obj.contains("candidates")) {
        QJsonArray candidates = obj["candidates"].toArray();
        if (!candidates.isEmpty()) {
            QJsonObject candidate = candidates[0].toObject();
            QJsonObject content = candidate["content"].toObject();
            QJsonArray parts = content["parts"].toArray();
            if (!parts.isEmpty()) {
                QString text = parts[0].toObject()["text"].toString();
                emit responseReceived(text);
            }
        }
    }
}

void AIProviderService::parseOllamaResponse(const QByteArray &data) {
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
        emit errorOccurred("Invalid response format from Ollama");
        return;
    }

    QJsonObject obj = doc.object();

    if (obj.contains("error")) {
        emit errorOccurred("Ollama Error: " + obj["error"].toString());
        return;
    }

    if (obj.contains("message")) {
        QJsonObject message = obj["message"].toObject();
        QString content = message["content"].toString();
        emit responseReceived(content);
    }
}
