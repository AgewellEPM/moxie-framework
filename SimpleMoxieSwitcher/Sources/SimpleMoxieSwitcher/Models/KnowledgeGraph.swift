import Foundation

// MARK: - Knowledge Graph Models
struct KnowledgeGraph: Codable {
    var facts: [Fact] = []
    var relationships: [Relationship] = []
    var topics: [Topic] = []
    var preferences: [Preference] = []
    var memories: [Memory] = []
    var lastUpdated: Date = Date()

    mutating func addFact(_ fact: Fact) {
        // Remove duplicates
        facts.removeAll { $0.key == fact.key }
        facts.append(fact)
        lastUpdated = Date()
    }

    mutating func addRelationship(_ relationship: Relationship) {
        relationships.append(relationship)
        lastUpdated = Date()
    }

    mutating func addTopic(_ topic: Topic) {
        if let index = topics.firstIndex(where: { $0.name == topic.name }) {
            topics[index].mentions += 1
            topics[index].lastMentioned = Date()
        } else {
            topics.append(topic)
        }
        lastUpdated = Date()
    }

    mutating func addPreference(_ preference: Preference) {
        preferences.removeAll { $0.category == preference.category }
        preferences.append(preference)
        lastUpdated = Date()
    }

    mutating func addMemory(_ memory: Memory) {
        memories.append(memory)
        lastUpdated = Date()
    }

    func search(query: String) -> [Fact] {
        let lowercased = query.lowercased()
        return facts.filter {
            $0.key.lowercased().contains(lowercased) ||
            $0.value.lowercased().contains(lowercased) ||
            $0.category.lowercased().contains(lowercased)
        }
    }

    func getRecentMemories(limit: Int = 10) -> [Memory] {
        Array(memories.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
    }

    func getSummary() -> String {
        var summary = "Knowledge Graph Summary:\n"
        summary += "- \(facts.count) facts\n"
        summary += "- \(relationships.count) relationships\n"
        summary += "- \(topics.count) topics discussed\n"
        summary += "- \(preferences.count) preferences\n"
        summary += "- \(memories.count) memories\n"
        summary += "Last updated: \(lastUpdated.formatted())"
        return summary
    }
}

struct Fact: Codable, Identifiable {
    let id: UUID
    let key: String // e.g., "name", "favorite_color", "occupation"
    let value: String
    let category: String // e.g., "personal", "preference", "technical"
    let confidence: Double // 0.0 to 1.0
    let source: String // Which conversation this came from
    let timestamp: Date

    init(key: String, value: String, category: String, confidence: Double = 1.0, source: String = "conversation") {
        self.id = UUID()
        self.key = key
        self.value = value
        self.category = category
        self.confidence = confidence
        self.source = source
        self.timestamp = Date()
    }
}

struct Relationship: Codable, Identifiable {
    let id: UUID
    let subject: String
    let predicate: String // "likes", "dislikes", "knows", "works_with"
    let object: String
    let timestamp: Date

    init(subject: String, predicate: String, object: String) {
        self.id = UUID()
        self.subject = subject
        self.predicate = predicate
        self.object = object
        self.timestamp = Date()
    }
}

struct Topic: Codable, Identifiable {
    let id: UUID
    let name: String
    var mentions: Int
    var lastMentioned: Date
    let firstMentioned: Date

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.mentions = 1
        self.lastMentioned = Date()
        self.firstMentioned = Date()
    }
}

struct Preference: Codable, Identifiable {
    let id: UUID
    let category: String // "music", "food", "hobbies", etc.
    let value: String
    let strength: Double // 0.0 to 1.0
    let timestamp: Date

    init(category: String, value: String, strength: Double = 1.0) {
        self.id = UUID()
        self.category = category
        self.value = value
        self.strength = strength
        self.timestamp = Date()
    }
}

struct Memory: Codable, Identifiable {
    let id: UUID
    let content: String
    let emotional_tone: String // "positive", "neutral", "negative"
    let importance: Double // 0.0 to 1.0
    let tags: [String]
    let timestamp: Date
    let conversationId: String

    init(content: String, emotional_tone: String = "neutral", importance: Double = 0.5, tags: [String] = [], conversationId: String) {
        self.id = UUID()
        self.content = content
        self.emotional_tone = emotional_tone
        self.importance = importance
        self.tags = tags
        self.timestamp = Date()
        self.conversationId = conversationId
    }
}

// MARK: - Knowledge Graph Service
@MainActor
class KnowledgeGraphService: ObservableObject {
    @Published var knowledgeGraph: KnowledgeGraph

    private let saveURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("SimpleMoxieSwitcher")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        saveURL = appDir.appendingPathComponent("knowledge_graph.json")

        // Load existing knowledge graph
        if let data = try? Data(contentsOf: saveURL),
           let loaded = try? JSONDecoder().decode(KnowledgeGraph.self, from: data) {
            self.knowledgeGraph = loaded
        } else {
            self.knowledgeGraph = KnowledgeGraph()
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(knowledgeGraph)
            try data.write(to: saveURL)
        } catch {
            print("Failed to save knowledge graph: \(error)")
        }
    }

    func extractKnowledge(from userMessage: String, assistantMessage: String, conversationId: String) {
        // Simple keyword-based extraction (can be enhanced with AI later)

        // Extract personal facts
        if userMessage.lowercased().contains("my name is") {
            if let name = extractValue(from: userMessage, pattern: "my name is ([a-zA-Z]+)") {
                knowledgeGraph.addFact(Fact(key: "user_name", value: name, category: "personal", source: conversationId))
            }
        }

        if userMessage.lowercased().contains("i love") || userMessage.lowercased().contains("i like") {
            if let preference = extractValue(from: userMessage, pattern: "i (?:love|like) ([^.,!?]+)") {
                knowledgeGraph.addPreference(Preference(category: "likes", value: preference.trimmingCharacters(in: .whitespaces)))
            }
        }

        if userMessage.lowercased().contains("i hate") || userMessage.lowercased().contains("i dislike") {
            if let preference = extractValue(from: userMessage, pattern: "i (?:hate|dislike) ([^.,!?]+)") {
                knowledgeGraph.addPreference(Preference(category: "dislikes", value: preference.trimmingCharacters(in: .whitespaces)))
            }
        }

        // Extract topics
        let commonTopics = ["coding", "programming", "ai", "robots", "moxie", "docker", "swift", "technology", "music", "art", "learning"]
        for topic in commonTopics {
            if userMessage.lowercased().contains(topic) || assistantMessage.lowercased().contains(topic) {
                knowledgeGraph.addTopic(Topic(name: topic))
            }
        }

        // Create memory of important exchanges
        if userMessage.count > 50 || assistantMessage.count > 100 {
            let memory = Memory(
                content: "User: \(userMessage)\nAssistant: \(assistantMessage)",
                emotional_tone: detectTone(userMessage),
                importance: calculateImportance(userMessage, assistantMessage),
                tags: extractTopics(from: userMessage + " " + assistantMessage),
                conversationId: conversationId
            )
            knowledgeGraph.addMemory(memory)
        }

        save()
    }

    private func extractValue(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, range: range),
           let matchRange = Range(match.range(at: 1), in: text) {
            return String(text[matchRange])
        }
        return nil
    }

    private func detectTone(_ text: String) -> String {
        let positive = ["love", "great", "awesome", "happy", "excited", "wonderful", "amazing", "excellent"]
        let negative = ["hate", "terrible", "awful", "sad", "angry", "frustrated", "bad", "horrible"]

        let lowercased = text.lowercased()
        let positiveCount = positive.filter { lowercased.contains($0) }.count
        let negativeCount = negative.filter { lowercased.contains($0) }.count

        if positiveCount > negativeCount {
            return "positive"
        } else if negativeCount > positiveCount {
            return "negative"
        }
        return "neutral"
    }

    private func calculateImportance(_ userMessage: String, _ assistantMessage: String) -> Double {
        // Longer messages = more important
        // Questions = more important
        // Personal information = more important

        var importance = 0.5

        if userMessage.contains("?") {
            importance += 0.2
        }

        if userMessage.count > 100 {
            importance += 0.1
        }

        let personalKeywords = ["my", "i am", "i have", "my name", "i work", "i live"]
        if personalKeywords.contains(where: { userMessage.lowercased().contains($0) }) {
            importance += 0.2
        }

        return min(importance, 1.0)
    }

    private func extractTopics(from text: String) -> [String] {
        let allTopics = ["coding", "programming", "ai", "robots", "moxie", "docker", "swift", "technology", "music", "art", "learning", "work", "family", "hobbies", "food"]
        return allTopics.filter { text.lowercased().contains($0) }
    }

    func getContext(for conversationId: String, limit: Int = 5) -> String {
        let recentMemories = knowledgeGraph.memories
            .filter { $0.conversationId == conversationId }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)

        if recentMemories.isEmpty {
            return ""
        }

        var context = "Previous conversation context:\n"
        for memory in recentMemories.reversed() {
            context += "- \(memory.content)\n"
        }
        return context
    }

    func getPersonalContext() -> String {
        var context = "What I know about you:\n"

        // Add facts
        for fact in knowledgeGraph.facts.prefix(10) {
            context += "- \(fact.key): \(fact.value)\n"
        }

        // Add preferences
        for pref in knowledgeGraph.preferences.prefix(5) {
            context += "- You \(pref.category): \(pref.value)\n"
        }

        // Add top topics
        let topTopics = knowledgeGraph.topics.sorted { $0.mentions > $1.mentions }.prefix(5)
        if !topTopics.isEmpty {
            context += "\nWe often discuss: \(topTopics.map { $0.name }.joined(separator: ", "))\n"
        }

        return context
    }
}
