import Foundation

// MARK: - Feature Types
enum FeatureType: String, Codable, CaseIterable {
    case conversation = "conversation"
    case story = "story"
    case learning = "learning"
    case music = "music"
    case language = "language"
    case other = "other"

    var displayName: String {
        switch self {
        case .conversation: return "Conversation"
        case .story: return "Story Time"
        case .learning: return "Learning Session"
        case .music: return "Music Lookup"
        case .language: return "Language Practice"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .conversation: return "💬"
        case .story: return "📚"
        case .learning: return "🎓"
        case .music: return "🎤"
        case .language: return "🌍"
        case .other: return "✨"
        }
    }
}

// MARK: - Usage Record
struct UsageRecord: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let featureType: FeatureType
    let modelUsed: String // "gpt-4o", "gpt-4o-mini", "deepseek-chat", "claude-3-5-sonnet", etc.
    let provider: String // "OpenAI", "Anthropic", "DeepSeek"
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    let estimatedCost: Double // in USD
    let conversationId: UUID?
    let personalityName: String?
    let personalityEmoji: String?
    let messageContent: String? // Optionally store message for context
    let responseTime: TimeInterval? // Time taken for API response
    let cacheHit: Bool // For providers like DeepSeek that have cache pricing

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        featureType: FeatureType,
        modelUsed: String,
        provider: String,
        promptTokens: Int,
        completionTokens: Int,
        totalTokens: Int? = nil,
        estimatedCost: Double? = nil,
        conversationId: UUID? = nil,
        personalityName: String? = nil,
        personalityEmoji: String? = nil,
        messageContent: String? = nil,
        responseTime: TimeInterval? = nil,
        cacheHit: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.featureType = featureType
        self.modelUsed = modelUsed
        self.provider = provider
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens ?? (promptTokens + completionTokens)
        self.estimatedCost = estimatedCost ?? UsageRecord.calculateCost(
            model: modelUsed,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            cacheHit: cacheHit
        )
        self.conversationId = conversationId
        self.personalityName = personalityName
        self.personalityEmoji = personalityEmoji
        self.messageContent = messageContent
        self.responseTime = responseTime
        self.cacheHit = cacheHit
    }

    // MARK: - Cost Calculation
    static func calculateCost(model: String, promptTokens: Int, completionTokens: Int, cacheHit: Bool = false) -> Double {
        // Prices as of January 2025 (per 1M tokens)
        let pricing: [String: (input: Double, output: Double, cache: Double?)] = [
            // OpenAI
            "gpt-4o": (input: 2.50, output: 10.00, cache: nil),
            "gpt-4o-mini": (input: 0.15, output: 0.60, cache: nil),
            "gpt-4-turbo": (input: 10.00, output: 30.00, cache: nil),
            "gpt-3.5-turbo": (input: 0.50, output: 1.50, cache: nil),

            // Anthropic
            "claude-3-5-sonnet-20241022": (input: 3.00, output: 15.00, cache: nil),
            "claude-3-opus-20240229": (input: 15.00, output: 75.00, cache: nil),
            "claude-3-haiku-20240307": (input: 0.25, output: 1.25, cache: nil),

            // DeepSeek
            "deepseek-chat": (input: 0.28, output: 0.42, cache: 0.028),
            "deepseek-coder": (input: 0.28, output: 0.42, cache: 0.028),

            // Google Gemini
            "gemini-1.5-pro": (input: 3.50, output: 10.50, cache: nil),
            "gemini-1.5-flash": (input: 0.075, output: 0.30, cache: nil),
            "gemini-pro": (input: 0.50, output: 1.50, cache: nil)
        ]

        guard let modelPricing = pricing[model] else {
            // Default to a conservative estimate if model not found
            return Double(promptTokens + completionTokens) / 1_000_000 * 1.00
        }

        let inputCost: Double
        if cacheHit, let cachePrice = modelPricing.cache {
            inputCost = Double(promptTokens) / 1_000_000 * cachePrice
        } else {
            inputCost = Double(promptTokens) / 1_000_000 * modelPricing.input
        }

        let outputCost = Double(completionTokens) / 1_000_000 * modelPricing.output

        return inputCost + outputCost
    }

    // MARK: - Formatted Properties
    var formattedCost: String {
        if estimatedCost < 0.001 {
            return String(format: "$%.4f", estimatedCost)
        } else if estimatedCost < 0.01 {
            return String(format: "$%.3f", estimatedCost)
        } else {
            return String(format: "$%.2f", estimatedCost)
        }
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var formattedResponseTime: String {
        guard let responseTime = responseTime else { return "N/A" }
        if responseTime < 1 {
            return String(format: "%.0fms", responseTime * 1000)
        } else {
            return String(format: "%.1fs", responseTime)
        }
    }
}

// MARK: - Usage Summary
struct UsageSummary {
    let period: String
    let totalCost: Double
    let totalTokens: Int
    let recordCount: Int
    let byFeature: [FeatureType: (cost: Double, count: Int)]
    let byModel: [String: (cost: Double, count: Int)]
    let averageResponseTime: TimeInterval?

    var formattedTotalCost: String {
        if totalCost < 0.01 {
            return String(format: "$%.3f", totalCost)
        } else if totalCost < 1 {
            return String(format: "$%.2f", totalCost)
        } else {
            return String(format: "$%.2f", totalCost)
        }
    }

    var formattedAverageResponseTime: String {
        guard let avgTime = averageResponseTime else { return "N/A" }
        if avgTime < 1 {
            return String(format: "%.0fms", avgTime * 1000)
        } else {
            return String(format: "%.1fs", avgTime)
        }
    }
}

// MARK: - Cost Alert
struct CostAlert: Identifiable {
    let id = UUID()
    let type: AlertType
    let message: String
    let severity: AlertSeverity
    let timestamp: Date = Date()

    enum AlertType {
        case highUsage
        case costIncrease
        case modelSuggestion
        case budgetWarning
    }

    enum AlertSeverity {
        case info
        case warning
        case critical

        var color: String {
            switch self {
            case .info: return "blue"
            case .warning: return "orange"
            case .critical: return "red"
            }
        }

        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }
    }
}