import Foundation

// MARK: - Vocabulary Cache for Token Optimization
actor VocabularyCache {
    static let shared = VocabularyCache()

    // Cache pools keyed by "language|level|category"
    private var vocabularyPool: [String: [VocabularyWord]] = [:]
    private let minPoolSize = 10
    private let fetchBatchSize = 100 // Fetch more at once for vocab

    private init() {}

    func getVocabulary(key: String, count: Int) -> [VocabularyWord]? {
        guard let pool = vocabularyPool[key], pool.count >= count else {
            return nil
        }
        // Return random subset from pool
        let shuffled = pool.shuffled()
        return Array(shuffled.prefix(count))
    }

    func addVocabulary(key: String, words: [VocabularyWord]) {
        var existing = vocabularyPool[key] ?? []
        // Deduplicate by word text
        let existingWords = Set(existing.map { $0.word.lowercased() })
        let newWords = words.filter { !existingWords.contains($0.word.lowercased()) }
        existing.append(contentsOf: newWords)
        // Cap at 500 words per key
        if existing.count > 500 {
            existing = Array(existing.suffix(500))
        }
        vocabularyPool[key] = existing
    }

    func poolNeedsRefill(key: String) -> Bool {
        return (vocabularyPool[key]?.count ?? 0) < minPoolSize
    }

    func poolCount(key: String) -> Int {
        return vocabularyPool[key]?.count ?? 0
    }

    func clearAll() {
        vocabularyPool.removeAll()
    }

    func cacheStats() -> String {
        let totalWords = vocabularyPool.values.map { $0.count }.reduce(0, +)
        return "Vocabulary cache: \(vocabularyPool.count) language/level combos, \(totalWords) total words"
    }
}

/// Service for generating language learning vocabulary using AI
@MainActor
class VocabularyGenerationService {
    private let aiService: AIServiceProtocol
    private let childProfileService: ChildProfileService
    private let fetchBatchSize = 100

    init(aiService: AIServiceProtocol? = nil, childProfileService: ChildProfileService? = nil) {
        self.aiService = aiService ?? AIService()
        self.childProfileService = childProfileService ?? ChildProfileService()
    }

    // MARK: - Helper Methods

    private func getChildContext() -> String {
        guard let profile = childProfileService.loadActiveProfile() else {
            return ""
        }

        var context = "\n\nPERSONALIZATION CONTEXT:\n"
        context += "The learner:\n"
        context += "- Name: \(profile.name)\n"

        if let age = profile.age {
            context += "- Age: \(age) years old\n"
        }

        if !profile.interests.isEmpty {
            context += "- Interests: \(profile.interests.joined(separator: ", "))\n"
        }

        context += "\nPlease select vocabulary and examples that will be especially engaging and relevant for this learner.\n"

        return context
    }

    // MARK: - Vocabulary Generation

    /// Generate essential vocabulary for a given language and proficiency level (uses caching)
    func generateEssentialVocabulary(
        language: String,
        languageCode: String,
        proficiencyLevel: LanguageLearningSession.ProficiencyLevel,
        count: Int = 50
    ) async throws -> [VocabularyWord] {
        let cacheKey = "\(languageCode)|\(proficiencyLevel.rawValue)|essential"

        // Try cache first
        if let cached = await VocabularyCache.shared.getVocabulary(key: cacheKey, count: count) {
            print("📦 Vocabulary cache hit: returning \(cached.count) words from pool (\(await VocabularyCache.shared.poolCount(key: cacheKey)) remaining)")

            // Background refill if pool is getting low
            if await VocabularyCache.shared.poolNeedsRefill(key: cacheKey) {
                Task {
                    try? await self.refillEssentialVocabulary(language: language, languageCode: languageCode, proficiencyLevel: proficiencyLevel)
                }
            }

            return cached
        }

        // Cache miss - generate and cache
        print("📦 Vocabulary cache miss: generating new pool for \(cacheKey)")
        let words = try await fetchEssentialVocabularyFromAI(language: language, proficiencyLevel: proficiencyLevel, count: fetchBatchSize)
        await VocabularyCache.shared.addVocabulary(key: cacheKey, words: words)
        return Array(words.prefix(count))
    }

    private func fetchEssentialVocabularyFromAI(
        language: String,
        proficiencyLevel: LanguageLearningSession.ProficiencyLevel,
        count: Int
    ) async throws -> [VocabularyWord] {
        let difficulty = getLevelDescription(proficiencyLevel)

        let childContext = getChildContext()

        let prompt = """
        Generate \(count) essential vocabulary words for learning \(language) at the \(difficulty) level.

        Return ONLY a JSON array of vocabulary items in this exact format:
        [
          {
            "word": "native word",
            "translation": "English translation",
            "pronunciation": "phonetic pronunciation",
            "partOfSpeech": "noun/verb/adjective/etc",
            "exampleSentence": "example using the word in \(language)",
            "exampleTranslation": "English translation of example"
          }
        ]

        Focus on the most commonly used and practical words for everyday communication.
        Include a good mix of nouns, verbs, and adjectives.
        Make sure pronunciations are accurate and helpful for English speakers.
        \(childContext)
        """

        let response = try await aiService.sendMessage(
            prompt,
            personality: Personality.motivationalCoach,
            featureType: .learning,
            conversationHistory: []
        )

        return parseVocabularyJSON(response.content)
    }

    private func refillEssentialVocabulary(
        language: String,
        languageCode: String,
        proficiencyLevel: LanguageLearningSession.ProficiencyLevel
    ) async throws {
        let cacheKey = "\(languageCode)|\(proficiencyLevel.rawValue)|essential"
        print("📦 Refilling vocabulary pool for \(cacheKey)")
        let newWords = try await fetchEssentialVocabularyFromAI(language: language, proficiencyLevel: proficiencyLevel, count: fetchBatchSize)
        await VocabularyCache.shared.addVocabulary(key: cacheKey, words: newWords)
    }

    /// Generate vocabulary related to specific interests (uses caching)
    func generateInterestVocabulary(
        language: String,
        languageCode: String,
        interest: String,
        proficiencyLevel: LanguageLearningSession.ProficiencyLevel,
        count: Int = 30
    ) async throws -> [VocabularyWord] {
        let cacheKey = "\(languageCode)|\(proficiencyLevel.rawValue)|interest_\(interest.lowercased())"

        // Try cache first
        if let cached = await VocabularyCache.shared.getVocabulary(key: cacheKey, count: count) {
            print("📦 Interest vocabulary cache hit for \(interest)")
            return cached
        }

        // Cache miss - generate and cache
        print("📦 Interest vocabulary cache miss for \(interest)")
        let words = try await fetchInterestVocabularyFromAI(language: language, interest: interest, proficiencyLevel: proficiencyLevel, count: 50)
        await VocabularyCache.shared.addVocabulary(key: cacheKey, words: words)
        return Array(words.prefix(count))
    }

    private func fetchInterestVocabularyFromAI(
        language: String,
        interest: String,
        proficiencyLevel: LanguageLearningSession.ProficiencyLevel,
        count: Int
    ) async throws -> [VocabularyWord] {
        let difficulty = getLevelDescription(proficiencyLevel)

        let childContext = getChildContext()

        let prompt = """
        Generate \(count) vocabulary words in \(language) related to "\(interest)" at the \(difficulty) level.

        Return ONLY a JSON array of vocabulary items in this exact format:
        [
          {
            "word": "native word",
            "translation": "English translation",
            "pronunciation": "phonetic pronunciation",
            "partOfSpeech": "noun/verb/adjective/etc",
            "exampleSentence": "example using the word in \(language)",
            "exampleTranslation": "English translation of example"
          }
        ]

        Focus on vocabulary specific to \(interest) that would be useful and engaging.
        Include verbs, nouns, and descriptive words relevant to this topic.
        \(childContext)
        """

        let response = try await aiService.sendMessage(
            prompt,
            personality: Personality.motivationalCoach,
            featureType: .learning,
            conversationHistory: []
        )

        return parseVocabularyJSON(response.content)
    }

    /// Generate travel-specific vocabulary (uses caching)
    func generateTravelVocabulary(
        language: String,
        languageCode: String,
        proficiencyLevel: LanguageLearningSession.ProficiencyLevel
    ) async throws -> [VocabularyWord] {
        let cacheKey = "\(languageCode)|\(proficiencyLevel.rawValue)|travel"

        // Try cache first
        if let cached = await VocabularyCache.shared.getVocabulary(key: cacheKey, count: 40) {
            print("📦 Travel vocabulary cache hit")
            return cached
        }

        // Cache miss - generate and cache
        print("📦 Travel vocabulary cache miss")
        let words = try await fetchTravelVocabularyFromAI(language: language, proficiencyLevel: proficiencyLevel)
        await VocabularyCache.shared.addVocabulary(key: cacheKey, words: words)
        return words
    }

    private func fetchTravelVocabularyFromAI(
        language: String,
        proficiencyLevel: LanguageLearningSession.ProficiencyLevel
    ) async throws -> [VocabularyWord] {
        let difficulty = getLevelDescription(proficiencyLevel)

        let childContext = getChildContext()

        let prompt = """
        Generate 60 essential travel vocabulary words and phrases in \(language) at the \(difficulty) level.

        Include words/phrases for:
        - Airport and transportation
        - Hotels and accommodation
        - Restaurants and food ordering
        - Shopping and money
        - Emergency situations
        - Asking for directions

        Return ONLY a JSON array of vocabulary items in this exact format:
        [
          {
            "word": "native word or phrase",
            "translation": "English translation",
            "pronunciation": "phonetic pronunciation",
            "partOfSpeech": "phrase/noun/verb/etc",
            "exampleSentence": "example situation in \(language)",
            "exampleTranslation": "English translation of example"
          }
        ]
        \(childContext)
        """

        let response = try await aiService.sendMessage(
            prompt,
            personality: Personality.motivationalCoach,
            featureType: .learning,
            conversationHistory: []
        )

        return parseVocabularyJSON(response.content)
    }

    /// Generate business/professional vocabulary (uses caching)
    func generateBusinessVocabulary(
        language: String,
        languageCode: String,
        proficiencyLevel: LanguageLearningSession.ProficiencyLevel
    ) async throws -> [VocabularyWord] {
        let cacheKey = "\(languageCode)|\(proficiencyLevel.rawValue)|business"

        // Try cache first
        if let cached = await VocabularyCache.shared.getVocabulary(key: cacheKey, count: 40) {
            print("📦 Business vocabulary cache hit")
            return cached
        }

        // Cache miss - generate and cache
        print("📦 Business vocabulary cache miss")
        let words = try await fetchBusinessVocabularyFromAI(language: language, proficiencyLevel: proficiencyLevel)
        await VocabularyCache.shared.addVocabulary(key: cacheKey, words: words)
        return words
    }

    private func fetchBusinessVocabularyFromAI(
        language: String,
        proficiencyLevel: LanguageLearningSession.ProficiencyLevel
    ) async throws -> [VocabularyWord] {
        let difficulty = getLevelDescription(proficiencyLevel)

        let childContext = getChildContext()

        let prompt = """
        Generate 60 business and professional vocabulary words in \(language) at the \(difficulty) level.

        Include words/phrases for:
        - Office and workplace
        - Meetings and presentations
        - Email and correspondence
        - Business negotiations
        - Professional relationships

        Return ONLY a JSON array of vocabulary items in this exact format:
        [
          {
            "word": "native word or phrase",
            "translation": "English translation",
            "pronunciation": "phonetic pronunciation",
            "partOfSpeech": "phrase/noun/verb/etc",
            "exampleSentence": "professional example in \(language)",
            "exampleTranslation": "English translation of example"
          }
        ]
        \(childContext)
        """

        let response = try await aiService.sendMessage(
            prompt,
            personality: Personality.motivationalCoach,
            featureType: .learning,
            conversationHistory: []
        )

        return parseVocabularyJSON(response.content)
    }

    // MARK: - Helper Methods

    private func getLevelDescription(_ level: LanguageLearningSession.ProficiencyLevel) -> String {
        switch level {
        case .beginner: return "beginner (A1)"
        case .elementary: return "elementary (A2)"
        case .intermediate: return "intermediate (B1)"
        case .upperIntermediate: return "upper intermediate (B2)"
        case .advanced: return "advanced (C1-C2)"
        }
    }

    private func parsePartOfSpeech(_ posString: String) -> VocabularyWord.PartOfSpeech {
        let lower = posString.lowercased()
        if lower.contains("noun") { return .noun }
        if lower.contains("verb") { return .verb }
        if lower.contains("adjective") || lower.contains("adj") { return .adjective }
        if lower.contains("adverb") || lower.contains("adv") { return .adverb }
        if lower.contains("preposition") || lower.contains("prep") { return .preposition }
        if lower.contains("conjunction") || lower.contains("conj") { return .conjunction }
        if lower.contains("pronoun") || lower.contains("pron") { return .pronoun }
        if lower.contains("interjection") || lower.contains("interj") { return .interjection }
        return .noun // default fallback
    }

    private func parseVocabularyJSON(_ jsonString: String) -> [VocabularyWord] {
        // Extract JSON from response (AI might add text before/after)
        guard let jsonStart = jsonString.firstIndex(of: "["),
              let jsonEnd = jsonString.lastIndex(of: "]") else {
            print("⚠️ No JSON array found in response")
            return []
        }

        let jsonSubstring = jsonString[jsonStart...jsonEnd]
        guard let jsonData = String(jsonSubstring).data(using: .utf8) else {
            print("⚠️ Failed to convert JSON string to data")
            return []
        }

        do {
            let decoder = JSONDecoder()
            let vocabItems = try decoder.decode([VocabularyJSON].self, from: jsonData)

            return vocabItems.map { item in
                VocabularyWord(
                    word: item.word,
                    translation: item.translation,
                    pronunciation: item.pronunciation,
                    partOfSpeech: parsePartOfSpeech(item.partOfSpeech),
                    exampleSentence: item.exampleSentence ?? "",
                    exampleTranslation: item.exampleTranslation ?? ""
                )
            }
        } catch {
            print("⚠️ Failed to decode vocabulary JSON: \(error)")
            print("JSON content: \(String(jsonSubstring))")
            return []
        }
    }
}

// MARK: - JSON Decoding Models

private struct VocabularyJSON: Codable {
    let word: String
    let translation: String
    let pronunciation: String
    let partOfSpeech: String
    let exampleSentence: String?
    let exampleTranslation: String?
}
