import Foundation

/// ViewModel for managing memory extraction and retrieval
@MainActor
class MemoryViewModel: ObservableObject {
    @Published var isExtracting = false
    @Published var extractionProgress: Double = 0.0
    @Published var extractionStatus = ""
    @Published var totalMemoriesExtracted = 0
    @Published var frontalCortex: FrontalCortex?
    @Published var errorMessage: String?

    private let memoryExtractionService: MemoryExtractionService
    private let memoryStorageService: MemoryStorageService

    init(
        memoryExtractionService: MemoryExtractionService? = nil,
        memoryStorageService: MemoryStorageService? = nil
    ) {
        self.memoryExtractionService = memoryExtractionService ?? DIContainer.shared.resolve(MemoryExtractionService.self)
        self.memoryStorageService = memoryStorageService ?? DIContainer.shared.resolve(MemoryStorageService.self)
    }

    // MARK: - Extract Memories from Conversations

    /// Extract memories from all loaded conversations
    func extractMemoriesFromConversations(_ conversations: [ConversationFile]) async {
        isExtracting = true
        extractionProgress = 0.0
        totalMemoriesExtracted = 0
        errorMessage = nil

        defer {
            isExtracting = false
            extractionProgress = 1.0
        }

        // Convert ConversationFile format to expected format
        var allConversations: [[String: Any]] = []

        for conversation in conversations {
            // Each conversation.messages is already an array of message dictionaries
            if let messages = conversation.messages {
                allConversations.append(contentsOf: messages)
            }
        }

        extractionStatus = "Extracting memories from \(allConversations.count) conversations..."

        do {
            // Extract memories in batches
            let batchSize = 10
            var allExtractedMemories: [ConversationMemory] = []

            for (batchIndex, batch) in allConversations.chunked(into: batchSize).enumerated() {
                extractionStatus = "Processing batch \(batchIndex + 1)..."

                let batchMemories = await memoryExtractionService.extractMemoriesFromBatch(
                    conversations: batch,
                    startingId: batchIndex * batchSize
                )

                allExtractedMemories.append(contentsOf: batchMemories)
                totalMemoriesExtracted = allExtractedMemories.count

                // Update progress
                let processedCount = (batchIndex + 1) * batchSize
                extractionProgress = min(Double(processedCount) / Double(allConversations.count), 0.9)
            }

            // Save memories to database
            extractionStatus = "Saving \(allExtractedMemories.count) memories to database..."
            try await memoryStorageService.saveMemories(allExtractedMemories)

            // Build frontal cortex from memories
            extractionStatus = "Building frontal cortex..."
            let cortex = await buildFrontalCortex(from: allExtractedMemories)

            // Save frontal cortex
            try await memoryStorageService.saveFrontalCortex(cortex)
            self.frontalCortex = cortex

            extractionProgress = 1.0
            extractionStatus = "✅ Extraction complete! \(totalMemoriesExtracted) memories extracted"

            print("🧠 Memory extraction complete:")
            print("   - Total memories: \(totalMemoriesExtracted)")
            print("   - Frontal cortex saved with \(cortex.interests.count) interests")

        } catch {
            errorMessage = "Failed to extract memories: \(error.localizedDescription)"
            extractionStatus = "❌ Extraction failed"
            print("❌ Memory extraction error: \(error)")
        }
    }

    // MARK: - Build Frontal Cortex

    /// Build consolidated frontal cortex from extracted memories
    private func buildFrontalCortex(from memories: [ConversationMemory]) async -> FrontalCortex {
        var cortex = FrontalCortex(userId: "moxie_001")

        // Extract core facts
        let facts = memories.filter { $0.memoryType == .fact }
        for fact in facts {
            // Extract key-value pairs from facts
            let content = fact.content
            // Simple heuristic: "User likes dinosaurs" -> key: "likes", value: "dinosaurs"
            if content.lowercased().contains("user") {
                let cleaned = content.replacingOccurrences(of: "User ", with: "")
                    .replacingOccurrences(of: "user ", with: "")
                cortex.coreFacts[UUID().uuidString] = cleaned
            }
        }

        // Extract preferences
        let preferences = memories.filter { $0.memoryType == .preference }
        for pref in preferences {
            cortex.preferences[UUID().uuidString] = pref.content
        }

        // Extract relationships
        let relationships = memories.filter { $0.memoryType == .relationship }
        for rel in relationships {
            if let firstEntity = rel.entities.first {
                cortex.relationships[firstEntity] = rel.content
            }
        }

        // Extract goals
        let goals = memories.filter { $0.memoryType == .goal }
        cortex.goals = goals.map { $0.content }

        // Extract skills
        let skills = memories.filter { $0.memoryType == .skill }
        cortex.skills = skills.map { $0.content }

        // Extract interests from topics
        var interestCounts: [String: Int] = [:]
        for memory in memories {
            for topic in memory.topics {
                interestCounts[topic, default: 0] += 1
            }
        }

        // Take top interests (mentioned at least 2 times)
        cortex.interests = interestCounts
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .map { $0.key }

        // Build emotional profile
        let emotions = memories.filter { $0.memoryType == .emotion }
        var sentimentCounts: [MemorySentiment: Int] = [:]
        var emotionalTriggers: [String: MemorySentiment] = [:]

        for emotion in emotions {
            sentimentCounts[emotion.sentiment, default: 0] += 1

            // Extract triggers from topics
            for topic in emotion.topics {
                emotionalTriggers[topic] = emotion.sentiment
            }
        }

        cortex.emotionalProfile.dominantEmotions = sentimentCounts
            .sorted { $0.value > $1.value }
            .map { $0.key }
        cortex.emotionalProfile.emotionalTriggers = emotionalTriggers

        // Build conversation patterns
        var topicCounts: [String: Int] = [:]
        for memory in memories {
            for topic in memory.topics {
                topicCounts[topic, default: 0] += 1
            }
        }
        cortex.conversationPatterns.commonTopics = topicCounts

        // Calculate average conversation length
        let conversationIds = Set(memories.map { $0.conversationId })
        if !conversationIds.isEmpty {
            cortex.conversationPatterns.averageConversationLength = memories.count / conversationIds.count
        }

        // Detect question types
        let questions = memories.filter { $0.memoryType == .question }
        var questionTypes: Set<String> = []
        for question in questions {
            let content = question.content.lowercased()
            if content.contains("why") { questionTypes.insert("why") }
            if content.contains("how") { questionTypes.insert("how") }
            if content.contains("what") { questionTypes.insert("what") }
            if content.contains("when") { questionTypes.insert("when") }
            if content.contains("where") { questionTypes.insert("where") }
            if content.contains("who") { questionTypes.insert("who") }
        }
        cortex.conversationPatterns.questionTypes = Array(questionTypes)

        cortex.lastUpdated = Date()

        return cortex
    }

    // MARK: - Load Existing Memories

    /// Load existing memories and frontal cortex from database
    func loadExistingMemories() async {
        do {
            let memories = try await memoryStorageService.loadMemories()
            totalMemoriesExtracted = memories.count

            if let cortex = try await memoryStorageService.loadFrontalCortex() {
                self.frontalCortex = cortex
                extractionStatus = "Loaded \(memories.count) existing memories"
            } else {
                extractionStatus = "No existing memories found"
            }
        } catch {
            errorMessage = "Failed to load memories: \(error.localizedDescription)"
            print("❌ Failed to load memories: \(error)")
        }
    }

    // MARK: - Query Memories

    /// Generate AI context from relevant memories based on keywords
    func generateContextForAI(keywords: [String]) async -> String {
        do {
            // Get memory context
            let memoryContext = try await memoryStorageService.generateContextForAI(
                keywords: keywords,
                limit: 5
            )

            // Get frontal cortex context
            var cortexContext = ""
            if let cortex = frontalCortex {
                cortexContext = cortex.generateContextForAI()
            }

            // Combine both contexts
            if !cortexContext.isEmpty && !memoryContext.isEmpty {
                return cortexContext + "\n\n" + memoryContext
            } else if !cortexContext.isEmpty {
                return cortexContext
            } else {
                return memoryContext
            }
        } catch {
            print("❌ Failed to generate context: \(error)")
            return ""
        }
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
