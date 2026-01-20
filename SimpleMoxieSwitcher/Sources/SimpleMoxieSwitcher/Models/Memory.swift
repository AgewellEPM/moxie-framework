import Foundation

// MARK: - Memory Models

/// Represents a single extracted memory from a conversation
struct ConversationMemory: Codable, Identifiable {
    let id: UUID
    let conversationId: String
    let timestamp: Date
    let memoryType: MemoryType
    let content: String
    let entities: [String] // People, places, things mentioned
    let topics: [String] // Main topics discussed
    let sentiment: MemorySentiment
    let importance: Double // 0.0 to 1.0

    init(
        id: UUID = UUID(),
        conversationId: String,
        timestamp: Date,
        memoryType: MemoryType,
        content: String,
        entities: [String] = [],
        topics: [String] = [],
        sentiment: MemorySentiment = .neutral,
        importance: Double = 0.5
    ) {
        self.id = id
        self.conversationId = conversationId
        self.timestamp = timestamp
        self.memoryType = memoryType
        self.content = content
        self.entities = entities
        self.topics = topics
        self.sentiment = sentiment
        self.importance = importance
    }
}

/// Types of memories that can be extracted
enum MemoryType: String, Codable {
    case fact = "fact" // "User likes dinosaurs"
    case preference = "preference" // "User prefers happy endings"
    case experience = "experience" // "User went to the park"
    case emotion = "emotion" // "User felt sad about..."
    case goal = "goal" // "User wants to learn piano"
    case relationship = "relationship" // "User has a sister named Sarah"
    case skill = "skill" // "User can draw well"
    case question = "question" // "User asked about space"
}

/// Memory sentiment analysis result
enum MemorySentiment: String, Codable {
    case positive
    case negative
    case neutral
    case mixed
}

// MARK: - Memory Session

/// Represents a consolidated memory session with context
struct MemorySession: Codable {
    let sessionId: UUID
    let startDate: Date
    let endDate: Date
    let conversationIds: [String]
    let summary: String
    let keyMemories: [ConversationMemory]
    let emotionalArc: [MemorySentiment] // Track emotional progression

    init(
        sessionId: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        conversationIds: [String],
        summary: String,
        keyMemories: [ConversationMemory],
        emotionalArc: [MemorySentiment] = []
    ) {
        self.sessionId = sessionId
        self.startDate = startDate
        self.endDate = endDate
        self.conversationIds = conversationIds
        self.summary = summary
        self.keyMemories = keyMemories
        self.emotionalArc = emotionalArc
    }
}

// MARK: - Frontal Cortex (Core Knowledge Base)

/// Represents consolidated core knowledge about the user
struct FrontalCortex: Codable {
    var userId: String
    var lastUpdated: Date

    // Core facts about the user
    var coreFacts: [String: String] // "favorite_color": "blue"
    var preferences: [String: String] // "story_type": "happy endings"
    var relationships: [String: String] // "sister": "Sarah"
    var goals: [String] // Long-term goals
    var skills: [String] // Known abilities
    var interests: [String] // Topics of interest

    // Emotional profile
    var emotionalProfile: EmotionalProfile

    // Conversation patterns
    var conversationPatterns: ConversationPatterns

    init(userId: String) {
        self.userId = userId
        self.lastUpdated = Date()
        self.coreFacts = [:]
        self.preferences = [:]
        self.relationships = [:]
        self.goals = []
        self.skills = []
        self.interests = []
        self.emotionalProfile = EmotionalProfile()
        self.conversationPatterns = ConversationPatterns()
    }

    /// Generate context string for AI prompts
    func generateContextForAI() -> String {
        var context = "## User Profile\n\n"

        // Core facts
        if !coreFacts.isEmpty {
            context += "**Core Facts:**\n"
            for (key, value) in coreFacts {
                context += "- \(key): \(value)\n"
            }
            context += "\n"
        }

        // Interests
        if !interests.isEmpty {
            context += "**Interests:** \(interests.joined(separator: ", "))\n\n"
        }

        // Goals
        if !goals.isEmpty {
            context += "**Goals:**\n"
            for goal in goals {
                context += "- \(goal)\n"
            }
            context += "\n"
        }

        // Relationships
        if !relationships.isEmpty {
            context += "**Important People:**\n"
            for (relation, name) in relationships {
                context += "- \(relation): \(name)\n"
            }
            context += "\n"
        }

        // Preferences
        if !preferences.isEmpty {
            context += "**Preferences:**\n"
            for (key, value) in preferences {
                context += "- \(key): \(value)\n"
            }
            context += "\n"
        }

        return context
    }
}

/// Emotional profile tracking
struct EmotionalProfile: Codable {
    var dominantEmotions: [MemorySentiment] = []
    var emotionalTriggers: [String: MemorySentiment] = [:] // "bedtime": .negative
    var comfortStrategies: [String] = [] // "singing helps calm down"

    init() {}
}

/// Conversation pattern analysis
struct ConversationPatterns: Codable {
    var commonTopics: [String: Int] = [:] // "dinosaurs": 15
    var averageConversationLength: Int = 0
    var preferredTimeOfDay: String? = nil
    var questionTypes: [String] = [] // "why", "how", "what"

    init() {}
}

// MARK: - Memory Query

/// Query parameters for memory retrieval
struct MemoryQuery {
    let keywords: [String]
    let timeRange: DateInterval?
    let memoryTypes: [MemoryType]
    let minImportance: Double
    let limit: Int

    init(
        keywords: [String] = [],
        timeRange: DateInterval? = nil,
        memoryTypes: [MemoryType] = [],
        minImportance: Double = 0.0,
        limit: Int = 10
    ) {
        self.keywords = keywords
        self.timeRange = timeRange
        self.memoryTypes = memoryTypes
        self.minImportance = minImportance
        self.limit = limit
    }
}

// MARK: - Memory Search Result

/// Result of a memory search with relevance score
struct MemorySearchResult {
    let memory: ConversationMemory
    let relevanceScore: Double // 0.0 to 1.0
    let recencyScore: Double // 0.0 to 1.0
    let combinedScore: Double // Weighted combination

    init(memory: ConversationMemory, relevanceScore: Double, recencyScore: Double) {
        self.memory = memory
        self.relevanceScore = relevanceScore
        self.recencyScore = recencyScore
        // Weight: 70% relevance, 30% recency
        self.combinedScore = (relevanceScore * 0.7) + (recencyScore * 0.3)
    }
}
