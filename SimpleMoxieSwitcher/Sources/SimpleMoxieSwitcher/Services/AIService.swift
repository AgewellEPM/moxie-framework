import Foundation
import CryptoKit

// MARK: - Request Cache for Token Optimization
actor RequestCache {
    static let shared = RequestCache()

    private var cache: [String: (response: AIServiceResponse, timestamp: Date)] = [:]
    private let ttl: TimeInterval = 300 // 5 minutes TTL

    private init() {}

    func get(key: String) -> AIServiceResponse? {
        guard let entry = cache[key] else { return nil }
        if Date().timeIntervalSince(entry.timestamp) > ttl {
            cache.removeValue(forKey: key)
            return nil
        }
        return entry.response
    }

    func set(key: String, response: AIServiceResponse) {
        cache[key] = (response, Date())
        // Cleanup old entries periodically
        if cache.count > 100 {
            let cutoff = Date().addingTimeInterval(-ttl)
            cache = cache.filter { $0.value.timestamp > cutoff }
        }
    }

    func generateKey(message: String, personality: String?, featureType: String) -> String {
        let input = "\(message)|\(personality ?? "none")|\(featureType)"
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - AI Service Response
struct AIServiceResponse {
    let content: String
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    let model: String
    let provider: String
    let responseTime: TimeInterval
    let cacheHit: Bool
}

// MARK: - AI Service Protocol
protocol AIServiceProtocol {
    func sendMessage(
        _ message: String,
        personality: Personality?,
        featureType: FeatureType,
        conversationHistory: [ChatMessage]?
    ) async throws -> AIServiceResponse
}

// MARK: - AI Service Implementation
@MainActor
class AIService: AIServiceProtocol {
    private let providerManager: AIProviderManager
    private let usageRepository: UsageRepositoryProtocol

    init(providerManager: AIProviderManager? = nil,
         usageRepository: UsageRepositoryProtocol = UsageRepository()) {
        self.providerManager = providerManager ?? AIProviderManager()
        self.usageRepository = usageRepository
    }

    func sendMessage(
        _ message: String,
        personality: Personality? = nil,
        featureType: FeatureType = .conversation,
        conversationHistory: [ChatMessage]? = nil
    ) async throws -> AIServiceResponse {
        guard let config = providerManager.getActiveConfig() else {
            throw AIServiceError.noActiveProvider
        }

        // Check request cache first (only for cacheable requests without conversation history)
        let shouldCache = conversationHistory == nil || conversationHistory!.isEmpty
        if shouldCache {
            let cacheKey = await RequestCache.shared.generateKey(
                message: message,
                personality: personality?.name,
                featureType: featureType.rawValue
            )

            if let cachedResponse = await RequestCache.shared.get(key: cacheKey) {
                print("Cache hit for request: \(String(message.prefix(50)))...")
                // Track deduplication analytics
                await CacheAnalyticsService.shared.recordDeduplicationHit(
                    tokensSaved: cachedResponse.promptTokens + cachedResponse.completionTokens
                )
                return AIServiceResponse(
                    content: cachedResponse.content,
                    promptTokens: 0, // Cached, no new tokens used
                    completionTokens: 0,
                    totalTokens: 0,
                    model: cachedResponse.model,
                    provider: cachedResponse.provider,
                    responseTime: 0,
                    cacheHit: true
                )
            }
        }

        let startTime = Date()
        var response: AIServiceResponse

        switch config.provider {
        case .openai:
            response = try await sendToOpenAI(
                message: message,
                config: config,
                personality: personality,
                featureType: featureType,
                conversationHistory: conversationHistory,
                startTime: startTime
            )

        case .anthropic:
            response = try await sendToAnthropic(
                message: message,
                config: config,
                personality: personality,
                featureType: featureType,
                conversationHistory: conversationHistory,
                startTime: startTime
            )

        case .deepseek:
            response = try await sendToDeepSeek(
                message: message,
                config: config,
                personality: personality,
                featureType: featureType,
                conversationHistory: conversationHistory,
                startTime: startTime
            )

        case .googleGemini:
            response = try await sendToGemini(
                message: message,
                config: config,
                personality: personality,
                featureType: featureType,
                conversationHistory: conversationHistory,
                startTime: startTime
            )

        case .groq:
            response = try await sendToGroq(
                message: message,
                config: config,
                personality: personality,
                featureType: featureType,
                conversationHistory: conversationHistory,
                startTime: startTime
            )

        case .openRouter:
            response = try await sendToOpenRouter(
                message: message,
                config: config,
                personality: personality,
                featureType: featureType,
                conversationHistory: conversationHistory,
                startTime: startTime
            )

        case .togetherAI:
            response = try await sendToTogetherAI(
                message: message,
                config: config,
                personality: personality,
                featureType: featureType,
                conversationHistory: conversationHistory,
                startTime: startTime
            )

        case .cloudflareAI:
            response = try await sendToCloudflareAI(
                message: message,
                config: config,
                personality: personality,
                featureType: featureType,
                conversationHistory: conversationHistory,
                startTime: startTime
            )

        case .localOllama:
            response = try await sendToOllama(
                message: message,
                config: config,
                personality: personality,
                featureType: featureType,
                conversationHistory: conversationHistory,
                startTime: startTime
            )
        }

        // Cache the response for future identical requests
        if shouldCache {
            let cacheKey = await RequestCache.shared.generateKey(
                message: message,
                personality: personality?.name,
                featureType: featureType.rawValue
            )
            await RequestCache.shared.set(key: cacheKey, response: response)
        }

        return response
    }

    // MARK: - OpenAI Implementation

    private func sendToOpenAI(
        message: String,
        config: ProviderConfig,
        personality: Personality?,
        featureType: FeatureType,
        conversationHistory: [ChatMessage]?,
        startTime: Date
    ) async throws -> AIServiceResponse {
        let url = URL(string: "\(config.baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build messages array
        var messages: [[String: String]] = []

        // Add system prompt
        let systemPrompt = buildSystemPrompt(personality: personality, featureType: featureType)
        messages.append(["role": "system", "content": systemPrompt])

        // Add conversation history if provided
        if let history = conversationHistory {
            for msg in history.suffix(10) { // Keep last 10 messages for context
                messages.append([
                    "role": msg.role == "user" ? "user" : "assistant",
                    "content": msg.content
                ])
            }
        }

        // Add current message
        messages.append(["role": "user", "content": message])

        let body: [String: Any] = [
            "model": config.selectedModel.isEmpty ? "gpt-4o-mini" : config.selectedModel,
            "messages": messages,
            "temperature": getTemperature(for: featureType),
            "max_tokens": getMaxTokens(for: featureType)
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw AIServiceError.invalidAPIKey
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIServiceError.apiError(message)
            }
            throw AIServiceError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let messageData = firstChoice["message"] as? [String: Any],
              let content = messageData["content"] as? String,
              let usage = json["usage"] as? [String: Any],
              let promptTokens = usage["prompt_tokens"] as? Int,
              let completionTokens = usage["completion_tokens"] as? Int,
              let totalTokens = usage["total_tokens"] as? Int else {
            throw AIServiceError.parsingError
        }

        let responseTime = Date().timeIntervalSince(startTime)

        // Save usage record
        let usageRecord = UsageRecord(
            featureType: featureType,
            modelUsed: config.selectedModel.isEmpty ? "gpt-4o-mini" : config.selectedModel,
            provider: "OpenAI",
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            conversationId: nil,
            personalityName: personality?.name,
            personalityEmoji: personality?.emoji,
            messageContent: String(message.prefix(100)),
            responseTime: responseTime,
            cacheHit: false
        )

        try? await usageRepository.saveUsageRecord(usageRecord)

        return AIServiceResponse(
            content: content,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            model: config.selectedModel,
            provider: "OpenAI",
            responseTime: responseTime,
            cacheHit: false
        )
    }

    // MARK: - Anthropic Implementation

    private func sendToAnthropic(
        message: String,
        config: ProviderConfig,
        personality: Personality?,
        featureType: FeatureType,
        conversationHistory: [ChatMessage]?,
        startTime: Date
    ) async throws -> AIServiceResponse {
        let url = URL(string: "\(config.baseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        // Enable prompt caching for token savings
        request.setValue("prompt-caching-2024-07-31", forHTTPHeaderField: "anthropic-beta")

        // Build messages array
        var messages: [[String: Any]] = []

        // Add conversation history if provided
        if let history = conversationHistory {
            for msg in history.suffix(10) {
                messages.append([
                    "role": msg.role == "user" ? "user" : "assistant",
                    "content": msg.content
                ])
            }
        }

        // Add current message
        messages.append(["role": "user", "content": message])

        let systemPrompt = buildSystemPrompt(personality: personality, featureType: featureType)

        // Use cache_control for system prompt to enable caching
        let systemWithCache: [[String: Any]] = [
            [
                "type": "text",
                "text": systemPrompt,
                "cache_control": ["type": "ephemeral"]
            ]
        ]

        let body: [String: Any] = [
            "model": config.selectedModel.isEmpty ? "claude-3-5-sonnet-20241022" : config.selectedModel,
            "messages": messages,
            "system": systemWithCache,
            "max_tokens": getMaxTokens(for: featureType),
            "temperature": getTemperature(for: featureType)
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw AIServiceError.invalidAPIKey
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIServiceError.apiError(message)
            }
            throw AIServiceError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String,
              let usage = json["usage"] as? [String: Any],
              let inputTokens = usage["input_tokens"] as? Int,
              let outputTokens = usage["output_tokens"] as? Int else {
            throw AIServiceError.parsingError
        }

        // Check for Anthropic cache usage
        let cacheReadTokens = usage["cache_read_input_tokens"] as? Int ?? 0
        let cacheCreationTokens = usage["cache_creation_input_tokens"] as? Int ?? 0
        let anthropicCacheHit = cacheReadTokens > 0

        let totalTokens = inputTokens + outputTokens
        let responseTime = Date().timeIntervalSince(startTime)

        if anthropicCacheHit {
            print("Anthropic cache hit: \(cacheReadTokens) tokens read from cache")
            // Track provider caching analytics
            await CacheAnalyticsService.shared.recordProviderCacheHit(
                provider: "Anthropic",
                tokensCached: cacheReadTokens
            )
        }

        // Save usage record
        let usageRecord = UsageRecord(
            featureType: featureType,
            modelUsed: config.selectedModel.isEmpty ? "claude-3-5-sonnet-20241022" : config.selectedModel,
            provider: "Anthropic",
            promptTokens: inputTokens,
            completionTokens: outputTokens,
            totalTokens: totalTokens,
            conversationId: nil,
            personalityName: personality?.name,
            personalityEmoji: personality?.emoji,
            messageContent: String(message.prefix(100)),
            responseTime: responseTime,
            cacheHit: anthropicCacheHit
        )

        try? await usageRepository.saveUsageRecord(usageRecord)

        return AIServiceResponse(
            content: text,
            promptTokens: inputTokens,
            completionTokens: outputTokens,
            totalTokens: totalTokens,
            model: config.selectedModel,
            provider: "Anthropic",
            responseTime: responseTime,
            cacheHit: false
        )
    }

    // MARK: - DeepSeek Implementation

    private func sendToDeepSeek(
        message: String,
        config: ProviderConfig,
        personality: Personality?,
        featureType: FeatureType,
        conversationHistory: [ChatMessage]?,
        startTime: Date
    ) async throws -> AIServiceResponse {
        let url = URL(string: "\(config.baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build messages array (similar to OpenAI format)
        var messages: [[String: String]] = []

        let systemPrompt = buildSystemPrompt(personality: personality, featureType: featureType)
        messages.append(["role": "system", "content": systemPrompt])

        if let history = conversationHistory {
            for msg in history.suffix(10) {
                messages.append([
                    "role": msg.role == "user" ? "user" : "assistant",
                    "content": msg.content
                ])
            }
        }

        messages.append(["role": "user", "content": message])

        let body: [String: Any] = [
            "model": config.selectedModel.isEmpty ? "deepseek-chat" : config.selectedModel,
            "messages": messages,
            "temperature": getTemperature(for: featureType),
            "max_tokens": getMaxTokens(for: featureType),
            "enable_cache": true // Enable caching for cost savings
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw AIServiceError.invalidAPIKey
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AIServiceError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let messageData = firstChoice["message"] as? [String: Any],
              let content = messageData["content"] as? String,
              let usage = json["usage"] as? [String: Any],
              let promptTokens = usage["prompt_tokens"] as? Int,
              let completionTokens = usage["completion_tokens"] as? Int,
              let totalTokens = usage["total_tokens"] as? Int else {
            throw AIServiceError.parsingError
        }

        // Check if cache was hit (DeepSeek specific)
        let cacheHit = usage["cache_hit"] as? Bool ?? false
        let responseTime = Date().timeIntervalSince(startTime)

        // Save usage record
        let usageRecord = UsageRecord(
            featureType: featureType,
            modelUsed: config.selectedModel.isEmpty ? "deepseek-chat" : config.selectedModel,
            provider: "DeepSeek",
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            conversationId: nil,
            personalityName: personality?.name,
            personalityEmoji: personality?.emoji,
            messageContent: String(message.prefix(100)),
            responseTime: responseTime,
            cacheHit: cacheHit
        )

        try? await usageRepository.saveUsageRecord(usageRecord)

        return AIServiceResponse(
            content: content,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            model: config.selectedModel,
            provider: "DeepSeek",
            responseTime: responseTime,
            cacheHit: cacheHit
        )
    }

    // MARK: - Google Gemini Implementation

    private func sendToGemini(
        message: String,
        config: ProviderConfig,
        personality: Personality?,
        featureType: FeatureType,
        conversationHistory: [ChatMessage]?,
        startTime: Date
    ) async throws -> AIServiceResponse {
        let model = config.selectedModel.isEmpty ? "gemini-1.5-flash" : config.selectedModel
        let url = URL(string: "\(config.baseURL)/models/\(model):generateContent?key=\(config.apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build contents array for Gemini
        var contents: [[String: Any]] = []

        // Add system instruction
        let systemPrompt = buildSystemPrompt(personality: personality, featureType: featureType)

        // Add conversation history
        if let history = conversationHistory {
            for msg in history.suffix(10) {
                contents.append([
                    "role": msg.role == "user" ? "user" : "model",
                    "parts": [["text": msg.content]]
                ])
            }
        }

        // Add current message
        contents.append([
            "role": "user",
            "parts": [["text": message]]
        ])

        let body: [String: Any] = [
            "contents": contents,
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "generationConfig": [
                "temperature": getTemperature(for: featureType),
                "maxOutputTokens": getMaxTokens(for: featureType)
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AIServiceError.invalidAPIKey
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AIServiceError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw AIServiceError.parsingError
        }

        // Gemini doesn't provide token counts directly, so we estimate
        let promptTokens = estimateTokens(message)
        let completionTokens = estimateTokens(text)
        let totalTokens = promptTokens + completionTokens
        let responseTime = Date().timeIntervalSince(startTime)

        // Save usage record
        let usageRecord = UsageRecord(
            featureType: featureType,
            modelUsed: model,
            provider: "Google",
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            conversationId: nil,
            personalityName: personality?.name,
            personalityEmoji: personality?.emoji,
            messageContent: String(message.prefix(100)),
            responseTime: responseTime,
            cacheHit: false
        )

        try? await usageRepository.saveUsageRecord(usageRecord)

        return AIServiceResponse(
            content: text,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            model: model,
            provider: "Google",
            responseTime: responseTime,
            cacheHit: false
        )
    }

    // MARK: - Groq Implementation (OpenAI-compatible, FREE tier)

    private func sendToGroq(
        message: String,
        config: ProviderConfig,
        personality: Personality?,
        featureType: FeatureType,
        conversationHistory: [ChatMessage]?,
        startTime: Date
    ) async throws -> AIServiceResponse {
        let url = URL(string: "\(config.baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var messages: [[String: String]] = []

        let systemPrompt = buildSystemPrompt(personality: personality, featureType: featureType)
        messages.append(["role": "system", "content": systemPrompt])

        if let history = conversationHistory {
            for msg in history.suffix(10) {
                messages.append([
                    "role": msg.role == "user" ? "user" : "assistant",
                    "content": msg.content
                ])
            }
        }

        messages.append(["role": "user", "content": message])

        let model = config.selectedModel.isEmpty ? "llama-3.1-8b-instant" : config.selectedModel
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": getTemperature(for: featureType),
            "max_tokens": getMaxTokens(for: featureType)
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw AIServiceError.invalidAPIKey
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIServiceError.apiError(message)
            }
            throw AIServiceError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let messageData = firstChoice["message"] as? [String: Any],
              let content = messageData["content"] as? String,
              let usage = json["usage"] as? [String: Any],
              let promptTokens = usage["prompt_tokens"] as? Int,
              let completionTokens = usage["completion_tokens"] as? Int,
              let totalTokens = usage["total_tokens"] as? Int else {
            throw AIServiceError.parsingError
        }

        let responseTime = Date().timeIntervalSince(startTime)

        let usageRecord = UsageRecord(
            featureType: featureType,
            modelUsed: model,
            provider: "Groq",
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            conversationId: nil,
            personalityName: personality?.name,
            personalityEmoji: personality?.emoji,
            messageContent: String(message.prefix(100)),
            responseTime: responseTime,
            cacheHit: false
        )

        try? await usageRepository.saveUsageRecord(usageRecord)

        return AIServiceResponse(
            content: content,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            model: model,
            provider: "Groq",
            responseTime: responseTime,
            cacheHit: false
        )
    }

    // MARK: - OpenRouter Implementation (OpenAI-compatible, FREE models available)

    private func sendToOpenRouter(
        message: String,
        config: ProviderConfig,
        personality: Personality?,
        featureType: FeatureType,
        conversationHistory: [ChatMessage]?,
        startTime: Date
    ) async throws -> AIServiceResponse {
        let url = URL(string: "\(config.baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // OpenRouter-specific headers
        request.setValue("SimpleMoxieSwitcher", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Moxie Robot Controller", forHTTPHeaderField: "X-Title")

        var messages: [[String: String]] = []

        let systemPrompt = buildSystemPrompt(personality: personality, featureType: featureType)
        messages.append(["role": "system", "content": systemPrompt])

        if let history = conversationHistory {
            for msg in history.suffix(10) {
                messages.append([
                    "role": msg.role == "user" ? "user" : "assistant",
                    "content": msg.content
                ])
            }
        }

        messages.append(["role": "user", "content": message])

        // Default to a free model
        let model = config.selectedModel.isEmpty ? "google/gemma-2-9b-it:free" : config.selectedModel
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": getTemperature(for: featureType),
            "max_tokens": getMaxTokens(for: featureType)
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw AIServiceError.invalidAPIKey
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIServiceError.apiError(message)
            }
            throw AIServiceError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let messageData = firstChoice["message"] as? [String: Any],
              let content = messageData["content"] as? String else {
            throw AIServiceError.parsingError
        }

        // OpenRouter may not always provide usage stats for free models
        let usage = json["usage"] as? [String: Any]
        let promptTokens = usage?["prompt_tokens"] as? Int ?? estimateTokens(message)
        let completionTokens = usage?["completion_tokens"] as? Int ?? estimateTokens(content)
        let totalTokens = promptTokens + completionTokens

        let responseTime = Date().timeIntervalSince(startTime)

        let usageRecord = UsageRecord(
            featureType: featureType,
            modelUsed: model,
            provider: "OpenRouter",
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            conversationId: nil,
            personalityName: personality?.name,
            personalityEmoji: personality?.emoji,
            messageContent: String(message.prefix(100)),
            responseTime: responseTime,
            cacheHit: false
        )

        try? await usageRepository.saveUsageRecord(usageRecord)

        return AIServiceResponse(
            content: content,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            model: model,
            provider: "OpenRouter",
            responseTime: responseTime,
            cacheHit: false
        )
    }

    // MARK: - Together AI Implementation (OpenAI-compatible, $25 FREE credits)

    private func sendToTogetherAI(
        message: String,
        config: ProviderConfig,
        personality: Personality?,
        featureType: FeatureType,
        conversationHistory: [ChatMessage]?,
        startTime: Date
    ) async throws -> AIServiceResponse {
        let url = URL(string: "\(config.baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var messages: [[String: String]] = []

        let systemPrompt = buildSystemPrompt(personality: personality, featureType: featureType)
        messages.append(["role": "system", "content": systemPrompt])

        if let history = conversationHistory {
            for msg in history.suffix(10) {
                messages.append([
                    "role": msg.role == "user" ? "user" : "assistant",
                    "content": msg.content
                ])
            }
        }

        messages.append(["role": "user", "content": message])

        let model = config.selectedModel.isEmpty ? "meta-llama/Llama-3.2-3B-Instruct-Turbo" : config.selectedModel
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": getTemperature(for: featureType),
            "max_tokens": getMaxTokens(for: featureType)
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw AIServiceError.invalidAPIKey
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIServiceError.apiError(message)
            }
            throw AIServiceError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let messageData = firstChoice["message"] as? [String: Any],
              let content = messageData["content"] as? String,
              let usage = json["usage"] as? [String: Any],
              let promptTokens = usage["prompt_tokens"] as? Int,
              let completionTokens = usage["completion_tokens"] as? Int,
              let totalTokens = usage["total_tokens"] as? Int else {
            throw AIServiceError.parsingError
        }

        let responseTime = Date().timeIntervalSince(startTime)

        let usageRecord = UsageRecord(
            featureType: featureType,
            modelUsed: model,
            provider: "Together AI",
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            conversationId: nil,
            personalityName: personality?.name,
            personalityEmoji: personality?.emoji,
            messageContent: String(message.prefix(100)),
            responseTime: responseTime,
            cacheHit: false
        )

        try? await usageRepository.saveUsageRecord(usageRecord)

        return AIServiceResponse(
            content: content,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            model: model,
            provider: "Together AI",
            responseTime: responseTime,
            cacheHit: false
        )
    }

    // MARK: - Cloudflare AI Implementation (FREE 10,000 neurons/day)

    private func sendToCloudflareAI(
        message: String,
        config: ProviderConfig,
        personality: Personality?,
        featureType: FeatureType,
        conversationHistory: [ChatMessage]?,
        startTime: Date
    ) async throws -> AIServiceResponse {
        // Cloudflare AI requires account ID in the URL
        // baseURL format: https://api.cloudflare.com/client/v4/accounts/{account_id}/ai/run
        let model = config.selectedModel.isEmpty ? "@cf/meta/llama-3.1-8b-instruct" : config.selectedModel
        let url = URL(string: "\(config.baseURL)/ai/run/\(model)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build messages for Cloudflare AI
        var messages: [[String: String]] = []

        let systemPrompt = buildSystemPrompt(personality: personality, featureType: featureType)
        messages.append(["role": "system", "content": systemPrompt])

        if let history = conversationHistory {
            for msg in history.suffix(10) {
                messages.append([
                    "role": msg.role == "user" ? "user" : "assistant",
                    "content": msg.content
                ])
            }
        }

        messages.append(["role": "user", "content": message])

        let body: [String: Any] = [
            "messages": messages,
            "max_tokens": getMaxTokens(for: featureType)
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw AIServiceError.invalidAPIKey
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errors = errorData["errors"] as? [[String: Any]],
               let firstError = errors.first,
               let message = firstError["message"] as? String {
                throw AIServiceError.apiError(message)
            }
            throw AIServiceError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let content = result["response"] as? String else {
            throw AIServiceError.parsingError
        }

        // Cloudflare doesn't provide token counts, estimate them
        let promptTokens = estimateTokens(message)
        let completionTokens = estimateTokens(content)
        let totalTokens = promptTokens + completionTokens
        let responseTime = Date().timeIntervalSince(startTime)

        let usageRecord = UsageRecord(
            featureType: featureType,
            modelUsed: model,
            provider: "Cloudflare AI",
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            conversationId: nil,
            personalityName: personality?.name,
            personalityEmoji: personality?.emoji,
            messageContent: String(message.prefix(100)),
            responseTime: responseTime,
            cacheHit: false
        )

        try? await usageRepository.saveUsageRecord(usageRecord)

        return AIServiceResponse(
            content: content,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            model: model,
            provider: "Cloudflare AI",
            responseTime: responseTime,
            cacheHit: false
        )
    }

    // MARK: - Local Ollama Implementation (FREE, runs locally)

    private func sendToOllama(
        message: String,
        config: ProviderConfig,
        personality: Personality?,
        featureType: FeatureType,
        conversationHistory: [ChatMessage]?,
        startTime: Date
    ) async throws -> AIServiceResponse {
        let url = URL(string: "\(config.baseURL)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build messages for Ollama
        var messages: [[String: String]] = []

        let systemPrompt = buildSystemPrompt(personality: personality, featureType: featureType)
        messages.append(["role": "system", "content": systemPrompt])

        if let history = conversationHistory {
            for msg in history.suffix(10) {
                messages.append([
                    "role": msg.role == "user" ? "user" : "assistant",
                    "content": msg.content
                ])
            }
        }

        messages.append(["role": "user", "content": message])

        let model = config.selectedModel.isEmpty ? "llama3.2" : config.selectedModel
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "stream": false,
            "options": [
                "temperature": getTemperature(for: featureType),
                "num_predict": getMaxTokens(for: featureType)
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AIServiceError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let messageData = json["message"] as? [String: Any],
              let content = messageData["content"] as? String else {
            throw AIServiceError.parsingError
        }

        // Ollama provides token counts in the response
        let promptTokens = json["prompt_eval_count"] as? Int ?? estimateTokens(message)
        let completionTokens = json["eval_count"] as? Int ?? estimateTokens(content)
        let totalTokens = promptTokens + completionTokens
        let responseTime = Date().timeIntervalSince(startTime)

        let usageRecord = UsageRecord(
            featureType: featureType,
            modelUsed: model,
            provider: "Ollama",
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            conversationId: nil,
            personalityName: personality?.name,
            personalityEmoji: personality?.emoji,
            messageContent: String(message.prefix(100)),
            responseTime: responseTime,
            cacheHit: false
        )

        try? await usageRepository.saveUsageRecord(usageRecord)

        return AIServiceResponse(
            content: content,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            model: model,
            provider: "Ollama",
            responseTime: responseTime,
            cacheHit: false
        )
    }

    // MARK: - Helper Methods

    private func buildSystemPrompt(personality: Personality?, featureType: FeatureType) -> String {
        // Get current mode from ModeContext
        let currentMode = ModeContext.shared.currentMode

        // Get child profile if available
        // TODO: Integrate with profile service when implemented
        let childProfile: ChildProfile? = loadChildProfile()

        // Build mode-aware system prompt using PersonalityShiftService
        return PersonalityShiftService.buildSystemPrompt(
            mode: currentMode,
            personality: personality,
            childProfile: childProfile,
            featureType: featureType
        )
    }

    private func loadChildProfile() -> ChildProfile? {
        // Try to load the child profile from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "childProfile") else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ChildProfile.self, from: data)
        } catch {
            print("Failed to load child profile: \(error)")
            return nil
        }
    }

    private func getTemperature(for featureType: FeatureType) -> Double {
        switch featureType {
        case .story: return 0.8
        case .music: return 0.7
        case .conversation: return 0.7
        case .learning: return 0.3
        case .language: return 0.5
        case .other: return 0.6
        }
    }

    private func getMaxTokens(for featureType: FeatureType) -> Int {
        switch featureType {
        case .story: return 1000
        case .learning: return 800
        case .conversation: return 500
        case .music: return 300
        case .language: return 400
        case .other: return 500
        }
    }

    private func estimateTokens(_ text: String) -> Int {
        // Rough estimation: 1 token ≈ 4 characters
        return text.count / 4
    }
}

// MARK: - AI Service Errors

enum AIServiceError: LocalizedError {
    case noActiveProvider
    case invalidAPIKey
    case invalidResponse
    case parsingError
    case httpError(Int)
    case apiError(String)
    case unsupportedProvider(String)

    var errorDescription: String? {
        switch self {
        case .noActiveProvider:
            return "No AI provider is configured. Please set up an API key in Settings."
        case .invalidAPIKey:
            return "Invalid API key. Please check your API key in Settings."
        case .invalidResponse:
            return "Invalid response from AI provider."
        case .parsingError:
            return "Failed to parse AI response."
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .unsupportedProvider(let message):
            return message
        }
    }
}