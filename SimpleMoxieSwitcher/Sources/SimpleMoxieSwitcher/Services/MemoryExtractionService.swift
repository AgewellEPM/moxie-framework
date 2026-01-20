import Foundation

/// Service for extracting memories from conversations
@MainActor
class MemoryExtractionService {
    private let aiService: AIServiceProtocol

    init(aiService: AIServiceProtocol? = nil) {
        self.aiService = aiService ?? AIService()
    }

    // MARK: - Extract Memories from Conversation

    /// Extract structured memories from a conversation exchange
    func extractMemories(
        from conversation: [String: Any],
        conversationId: String
    ) async throws -> [ConversationMemory] {
        guard let userMessage = conversation["user"] as? String,
              let moxieMessage = conversation["moxie"] as? String,
              let timestampString = conversation["timestamp"] as? String,
              let timestamp = ISO8601DateFormatter().date(from: timestampString) else {
            return []
        }

        var memories: [ConversationMemory] = []

        // Use AI to extract structured information
        let extractionPrompt = buildExtractionPrompt(
            userMessage: userMessage,
            moxieMessage: moxieMessage
        )

        do {
            let response = try await aiService.sendMessage(
                extractionPrompt,
                personality: Personality.motivationalCoach,
                featureType: .other,
                conversationHistory: []
            )

            // Parse the AI response to extract memories
            memories = parseMemoryExtractionResponse(
                response.content,
                conversationId: conversationId,
                timestamp: timestamp
            )
        } catch {
            print("⚠️ AI extraction failed, falling back to rule-based extraction")
            // Fallback to rule-based extraction
            memories = extractMemoriesRuleBased(
                userMessage: userMessage,
                moxieMessage: moxieMessage,
                conversationId: conversationId,
                timestamp: timestamp
            )
        }

        return memories
    }

    // MARK: - AI-Based Extraction

    private func buildExtractionPrompt(userMessage: String, moxieMessage: String) -> String {
        return """
        Analyze this conversation and extract key information:

        User: \(userMessage)
        Moxie: \(moxieMessage)

        Extract the following information in JSON format:
        {
          "facts": ["User stated facts about themselves"],
          "preferences": ["User expressed preferences"],
          "emotions": ["User expressed emotions"],
          "topics": ["Main topics discussed"],
          "entities": ["People, places, things mentioned"],
          "questions": ["Questions the user asked"],
          "goals": ["Goals or aspirations mentioned"]
        }

        Only include information that is clearly stated. Return ONLY the JSON, nothing else.
        """
    }

    private func parseMemoryExtractionResponse(
        _ response: String,
        conversationId: String,
        timestamp: Date
    ) -> [ConversationMemory] {
        var memories: [ConversationMemory] = []

        // Try to parse JSON from AI response
        guard let jsonData = response.data(using: .utf8),
              let extracted = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return []
        }

        // Extract facts
        if let facts = extracted["facts"] as? [String] {
            for fact in facts {
                memories.append(ConversationMemory(
                    conversationId: conversationId,
                    timestamp: timestamp,
                    memoryType: .fact,
                    content: fact,
                    entities: [],
                    topics: [],
                    importance: 0.7
                ))
            }
        }

        // Extract preferences
        if let preferences = extracted["preferences"] as? [String] {
            for pref in preferences {
                memories.append(ConversationMemory(
                    conversationId: conversationId,
                    timestamp: timestamp,
                    memoryType: .preference,
                    content: pref,
                    entities: [],
                    topics: [],
                    importance: 0.8
                ))
            }
        }

        // Extract emotions
        if let emotions = extracted["emotions"] as? [String] {
            for emotion in emotions {
                memories.append(ConversationMemory(
                    conversationId: conversationId,
                    timestamp: timestamp,
                    memoryType: .emotion,
                    content: emotion,
                    entities: [],
                    topics: [],
                    sentiment: detectSentiment(emotion),
                    importance: 0.6
                ))
            }
        }

        // Extract goals
        if let goals = extracted["goals"] as? [String] {
            for goal in goals {
                memories.append(ConversationMemory(
                    conversationId: conversationId,
                    timestamp: timestamp,
                    memoryType: .goal,
                    content: goal,
                    entities: [],
                    topics: [],
                    importance: 0.9
                ))
            }
        }

        // Extract topics and entities
        let topics = extracted["topics"] as? [String] ?? []
        let entities = extracted["entities"] as? [String] ?? []

        // Add to all memories
        for i in 0..<memories.count {
            memories[i] = ConversationMemory(
                id: memories[i].id,
                conversationId: memories[i].conversationId,
                timestamp: memories[i].timestamp,
                memoryType: memories[i].memoryType,
                content: memories[i].content,
                entities: entities,
                topics: topics,
                sentiment: memories[i].sentiment,
                importance: memories[i].importance
            )
        }

        return memories
    }

    // MARK: - Rule-Based Extraction (Fallback)

    private func extractMemoriesRuleBased(
        userMessage: String,
        moxieMessage: String,
        conversationId: String,
        timestamp: Date
    ) -> [ConversationMemory] {
        var memories: [ConversationMemory] = []

        let lowerUser = userMessage.lowercased()

        // Detect preferences
        if lowerUser.contains("i like") || lowerUser.contains("i love") || lowerUser.contains("i prefer") {
            memories.append(ConversationMemory(
                conversationId: conversationId,
                timestamp: timestamp,
                memoryType: .preference,
                content: userMessage,
                topics: extractTopics(from: userMessage),
                importance: 0.7
            ))
        }

        // Detect emotions
        let emotionKeywords = ["sad", "happy", "angry", "excited", "scared", "worried", "frustrated"]
        for keyword in emotionKeywords {
            if lowerUser.contains(keyword) {
                memories.append(ConversationMemory(
                    conversationId: conversationId,
                    timestamp: timestamp,
                    memoryType: .emotion,
                    content: userMessage,
                    sentiment: mapKeywordToSentiment(keyword),
                    importance: 0.6
                ))
                break
            }
        }

        // Detect goals
        if lowerUser.contains("i want to") || lowerUser.contains("i need to") || lowerUser.contains("i hope to") {
            memories.append(ConversationMemory(
                conversationId: conversationId,
                timestamp: timestamp,
                memoryType: .goal,
                content: userMessage,
                importance: 0.8
            ))
        }

        // Detect relationships
        let relationshipKeywords = ["my mom", "my dad", "my sister", "my brother", "my friend"]
        for keyword in relationshipKeywords {
            if lowerUser.contains(keyword) {
                memories.append(ConversationMemory(
                    conversationId: conversationId,
                    timestamp: timestamp,
                    memoryType: .relationship,
                    content: userMessage,
                    entities: extractNames(from: userMessage),
                    importance: 0.9
                ))
                break
            }
        }

        return memories
    }

    // MARK: - Helper Methods

    private func detectSentiment(_ text: String) -> MemorySentiment {
        let lower = text.lowercased()
        let positiveWords = ["happy", "excited", "love", "great", "wonderful", "amazing"]
        let negativeWords = ["sad", "angry", "hate", "terrible", "awful", "scared"]

        var positiveCount = 0
        var negativeCount = 0

        for word in positiveWords {
            if lower.contains(word) { positiveCount += 1 }
        }

        for word in negativeWords {
            if lower.contains(word) { negativeCount += 1 }
        }

        if positiveCount > negativeCount {
            return .positive
        } else if negativeCount > positiveCount {
            return .negative
        } else if positiveCount > 0 && negativeCount > 0 {
            return .mixed
        } else {
            return .neutral
        }
    }

    private func mapKeywordToSentiment(_ keyword: String) -> MemorySentiment {
        switch keyword {
        case "happy", "excited":
            return .positive
        case "sad", "angry", "scared", "worried", "frustrated":
            return .negative
        default:
            return .neutral
        }
    }

    private func extractTopics(from text: String) -> [String] {
        // Simple topic extraction based on common words
        let commonTopics = [
            "dinosaurs", "space", "animals", "music", "art", "reading", "games",
            "school", "friends", "family", "sports", "food", "nature"
        ]

        let lower = text.lowercased()
        return commonTopics.filter { lower.contains($0) }
    }

    private func extractNames(from text: String) -> [String] {
        // Simple name extraction (looks for capitalized words)
        let words = text.components(separatedBy: .whitespaces)
        return words.filter { word in
            guard !word.isEmpty else { return false }
            let first = word.first!
            return first.isUppercase && word.count > 1
        }
    }

    // MARK: - Batch Processing

    /// Process multiple conversations in batch
    func extractMemoriesFromBatch(
        conversations: [[String: Any]],
        startingId: Int = 0
    ) async -> [ConversationMemory] {
        var allMemories: [ConversationMemory] = []

        for (index, conversation) in conversations.enumerated() {
            let conversationId = String(startingId + index)

            do {
                let memories = try await extractMemories(
                    from: conversation,
                    conversationId: conversationId
                )
                allMemories.append(contentsOf: memories)

                // Small delay to avoid overwhelming the AI service
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            } catch {
                print("⚠️ Failed to extract memories from conversation \(conversationId): \(error)")
            }
        }

        return allMemories
    }
}
