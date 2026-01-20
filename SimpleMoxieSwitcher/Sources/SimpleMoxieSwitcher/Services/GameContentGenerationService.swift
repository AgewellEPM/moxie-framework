import Foundation

// MARK: - Game Content Cache for Token Optimization
actor GameContentCache {
    static let shared = GameContentCache()

    private var triviaPool: [String: [TriviaQuestion]] = [:] // Key: "category|difficulty"
    private var spellingPool: [String: [SpellingWord]] = [:]
    private var movieQuotePool: [String: [MovieLineChallenge]] = [:]
    private var videoGamePool: [String: [VideoGameChallenge]] = [:]

    private let minPoolSize = 5 // Refetch when pool drops below this
    private let fetchBatchSize = 20 // Fetch this many at once to build pool

    private init() {}

    // MARK: - Trivia Cache

    func getTriviaQuestions(key: String, count: Int) -> [TriviaQuestion]? {
        guard let pool = triviaPool[key], pool.count >= count else {
            return nil
        }
        // Pull random questions from pool
        let shuffled = pool.shuffled()
        return Array(shuffled.prefix(count))
    }

    func addTriviaQuestions(key: String, questions: [TriviaQuestion]) {
        var existing = triviaPool[key] ?? []
        existing.append(contentsOf: questions)
        // Keep pool manageable - cap at 100 questions per key
        if existing.count > 100 {
            existing = Array(existing.suffix(100))
        }
        triviaPool[key] = existing
    }

    func consumeTriviaQuestions(key: String, questions: [TriviaQuestion]) {
        guard var pool = triviaPool[key] else { return }
        let usedIds = Set(questions.map { $0.id })
        pool.removeAll { usedIds.contains($0.id) }
        triviaPool[key] = pool
    }

    func triviaPoolNeedsRefill(key: String) -> Bool {
        return (triviaPool[key]?.count ?? 0) < minPoolSize
    }

    // MARK: - Spelling Cache

    func getSpellingWords(key: String, count: Int) -> [SpellingWord]? {
        guard let pool = spellingPool[key], pool.count >= count else {
            return nil
        }
        let shuffled = pool.shuffled()
        return Array(shuffled.prefix(count))
    }

    func addSpellingWords(key: String, words: [SpellingWord]) {
        var existing = spellingPool[key] ?? []
        existing.append(contentsOf: words)
        if existing.count > 100 {
            existing = Array(existing.suffix(100))
        }
        spellingPool[key] = existing
    }

    func spellingPoolNeedsRefill(key: String) -> Bool {
        return (spellingPool[key]?.count ?? 0) < minPoolSize
    }

    // MARK: - Movie Quote Cache

    func getMovieQuotes(key: String, count: Int) -> [MovieLineChallenge]? {
        guard let pool = movieQuotePool[key], pool.count >= count else {
            return nil
        }
        let shuffled = pool.shuffled()
        return Array(shuffled.prefix(count))
    }

    func addMovieQuotes(key: String, quotes: [MovieLineChallenge]) {
        var existing = movieQuotePool[key] ?? []
        existing.append(contentsOf: quotes)
        if existing.count > 100 {
            existing = Array(existing.suffix(100))
        }
        movieQuotePool[key] = existing
    }

    func movieQuotePoolNeedsRefill(key: String) -> Bool {
        return (movieQuotePool[key]?.count ?? 0) < minPoolSize
    }

    // MARK: - Video Game Cache

    func getVideoGameChallenges(key: String, count: Int) -> [VideoGameChallenge]? {
        guard let pool = videoGamePool[key], pool.count >= count else {
            return nil
        }
        let shuffled = pool.shuffled()
        return Array(shuffled.prefix(count))
    }

    func addVideoGameChallenges(key: String, challenges: [VideoGameChallenge]) {
        var existing = videoGamePool[key] ?? []
        existing.append(contentsOf: challenges)
        if existing.count > 100 {
            existing = Array(existing.suffix(100))
        }
        videoGamePool[key] = existing
    }

    func videoGamePoolNeedsRefill(key: String) -> Bool {
        return (videoGamePool[key]?.count ?? 0) < minPoolSize
    }

    // MARK: - Cache Management

    func clearAll() {
        triviaPool.removeAll()
        spellingPool.removeAll()
        movieQuotePool.removeAll()
        videoGamePool.removeAll()
    }

    func cacheStats() -> String {
        return """
        Cache Stats:
        - Trivia pools: \(triviaPool.count) categories, \(triviaPool.values.map { $0.count }.reduce(0, +)) total questions
        - Spelling pools: \(spellingPool.count) categories, \(spellingPool.values.map { $0.count }.reduce(0, +)) total words
        - Movie quote pools: \(movieQuotePool.count) categories, \(movieQuotePool.values.map { $0.count }.reduce(0, +)) total quotes
        - Video game pools: \(videoGamePool.count) categories, \(videoGamePool.values.map { $0.count }.reduce(0, +)) total challenges
        """
    }
}

/// Service for generating game content using AI
@MainActor
class GameContentGenerationService {
    private let aiService: AIServiceProtocol
    private let childProfileService: ChildProfileService
    private let fetchBatchSize = 20 // Number of items to fetch when building pool

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
        context += "The child you're creating content for:\n"
        context += "- Name: \(profile.name)\n"

        if let age = profile.age {
            context += "- Age: \(age) years old\n"
        }

        if !profile.interests.isEmpty {
            context += "- Interests: \(profile.interests.joined(separator: ", "))\n"
        }

        context += "\nPlease tailor the difficulty, examples, and topics to be appropriate and engaging for this child.\n"

        return context
    }

    // MARK: - Trivia Generation

    /// Generate age-appropriate trivia questions (uses caching for token optimization)
    func generateTriviaQuestions(
        category: String? = nil,
        difficulty: TriviaQuestion.Difficulty,
        count: Int = 10
    ) async throws -> [TriviaQuestion] {
        let cacheKey = "\(category ?? "general")|\(difficulty.rawValue)"

        // Try to get from cache first
        if let cached = await GameContentCache.shared.getTriviaQuestions(key: cacheKey, count: count) {
            print("📦 Trivia cache hit: returning \(cached.count) questions from pool")
            // Track analytics - estimate ~100 tokens per question
            await CacheAnalyticsService.shared.recordCacheHit(category: .trivia, tokensSaved: count * 100)
            // Mark questions as used (they'll be removed from pool)
            await GameContentCache.shared.consumeTriviaQuestions(key: cacheKey, questions: cached)

            // Background refill if pool is getting low
            if await GameContentCache.shared.triviaPoolNeedsRefill(key: cacheKey) {
                Task {
                    try? await self.refillTriviaPool(category: category, difficulty: difficulty)
                }
            }

            return cached
        }

        // Cache miss - generate new questions and build pool
        print("📦 Trivia cache miss: generating new pool for \(cacheKey)")
        await CacheAnalyticsService.shared.recordCacheMiss(category: .trivia)
        let questions = try await fetchTriviaFromAI(category: category, difficulty: difficulty, count: fetchBatchSize)

        // Add to cache
        await GameContentCache.shared.addTriviaQuestions(key: cacheKey, questions: questions)

        // Return requested count
        let result = Array(questions.prefix(count))
        await GameContentCache.shared.consumeTriviaQuestions(key: cacheKey, questions: result)
        return result
    }

    /// Fetch trivia questions directly from AI (no caching)
    private func fetchTriviaFromAI(
        category: String?,
        difficulty: TriviaQuestion.Difficulty,
        count: Int
    ) async throws -> [TriviaQuestion] {
        let categoryPrompt = category != nil ? "about \(category!)" : "on various topics"

        let childContext = getChildContext()

        let prompt = """
        Generate \(count) fun, age-appropriate trivia questions \(categoryPrompt) for a \(difficulty.rawValue) difficulty level.

        Return ONLY a JSON array in this exact format:
        [
          {
            "category": "Science/History/Geography/etc",
            "question": "The question text",
            "options": ["option1", "option2", "option3", "option4"],
            "correctAnswer": 0
          }
        ]

        Make sure questions are engaging, educational, and appropriate for children.
        The correctAnswer is the index (0-3) of the correct option in the options array.
        Vary the categories across questions.
        \(childContext)
        """

        let response = try await aiService.sendMessage(
            prompt,
            personality: Personality.motivationalCoach,
            featureType: .learning,
            conversationHistory: []
        )

        return parseTriviaJSON(response.content, difficulty: difficulty)
    }

    /// Refill trivia pool in background
    private func refillTriviaPool(category: String?, difficulty: TriviaQuestion.Difficulty) async throws {
        let cacheKey = "\(category ?? "general")|\(difficulty.rawValue)"
        print("📦 Refilling trivia pool for \(cacheKey)")
        let newQuestions = try await fetchTriviaFromAI(category: category, difficulty: difficulty, count: fetchBatchSize)
        await GameContentCache.shared.addTriviaQuestions(key: cacheKey, questions: newQuestions)
    }

    // MARK: - Spelling Generation

    /// Generate spelling words appropriate for age/grade level (uses caching)
    func generateSpellingWords(
        gradeLevel: String,
        category: String? = nil,
        difficulty: TriviaQuestion.Difficulty,
        count: Int = 10
    ) async throws -> [SpellingWord] {
        let cacheKey = "\(gradeLevel)|\(category ?? "general")|\(difficulty.rawValue)"

        // Try cache first
        if let cached = await GameContentCache.shared.getSpellingWords(key: cacheKey, count: count) {
            print("📦 Spelling cache hit: returning \(cached.count) words from pool")

            if await GameContentCache.shared.spellingPoolNeedsRefill(key: cacheKey) {
                Task {
                    try? await self.refillSpellingPool(gradeLevel: gradeLevel, category: category, difficulty: difficulty)
                }
            }

            return cached
        }

        // Cache miss - generate new
        print("📦 Spelling cache miss: generating new pool for \(cacheKey)")
        let words = try await fetchSpellingFromAI(gradeLevel: gradeLevel, category: category, difficulty: difficulty, count: fetchBatchSize)
        await GameContentCache.shared.addSpellingWords(key: cacheKey, words: words)
        return Array(words.prefix(count))
    }

    private func fetchSpellingFromAI(
        gradeLevel: String,
        category: String?,
        difficulty: TriviaQuestion.Difficulty,
        count: Int
    ) async throws -> [SpellingWord] {
        let categoryPrompt = category != nil ? "related to \(category!)" : "common words"

        let childContext = getChildContext()

        let prompt = """
        Generate \(count) spelling words \(categoryPrompt) appropriate for \(gradeLevel) grade level at \(difficulty.rawValue) difficulty.

        Return ONLY a JSON array in this exact format:
        [
          {
            "word": "the word to spell",
            "definition": "simple definition",
            "audioHint": "phonetic pronunciation (e.g., frend, byoo-tuh-fuhl)"
          }
        ]

        Words should be age-appropriate and educational.
        \(childContext)
        """

        let response = try await aiService.sendMessage(
            prompt,
            personality: Personality.motivationalCoach,
            featureType: .learning,
            conversationHistory: []
        )

        return parseSpellingJSON(response.content, difficulty: difficulty)
    }

    private func refillSpellingPool(gradeLevel: String, category: String?, difficulty: TriviaQuestion.Difficulty) async throws {
        let cacheKey = "\(gradeLevel)|\(category ?? "general")|\(difficulty.rawValue)"
        print("📦 Refilling spelling pool for \(cacheKey)")
        let newWords = try await fetchSpellingFromAI(gradeLevel: gradeLevel, category: category, difficulty: difficulty, count: fetchBatchSize)
        await GameContentCache.shared.addSpellingWords(key: cacheKey, words: newWords)
    }

    // MARK: - Movie Quote Generation

    /// Generate family-friendly movie quotes (uses caching)
    func generateMovieQuotes(
        genre: String? = nil,
        difficulty: TriviaQuestion.Difficulty,
        count: Int = 8
    ) async throws -> [MovieLineChallenge] {
        let cacheKey = "\(genre ?? "general")|\(difficulty.rawValue)"

        // Try cache first
        if let cached = await GameContentCache.shared.getMovieQuotes(key: cacheKey, count: count) {
            print("📦 Movie quote cache hit: returning \(cached.count) quotes from pool")

            if await GameContentCache.shared.movieQuotePoolNeedsRefill(key: cacheKey) {
                Task {
                    try? await self.refillMovieQuotePool(genre: genre, difficulty: difficulty)
                }
            }

            return cached
        }

        // Cache miss - generate new
        print("📦 Movie quote cache miss: generating new pool for \(cacheKey)")
        let quotes = try await fetchMovieQuotesFromAI(genre: genre, difficulty: difficulty, count: fetchBatchSize)
        await GameContentCache.shared.addMovieQuotes(key: cacheKey, quotes: quotes)
        return Array(quotes.prefix(count))
    }

    private func fetchMovieQuotesFromAI(
        genre: String?,
        difficulty: TriviaQuestion.Difficulty,
        count: Int
    ) async throws -> [MovieLineChallenge] {
        let genrePrompt = genre != nil ? "from \(genre!) movies" : "from family-friendly movies"

        let childContext = getChildContext()

        let prompt = """
        Generate \(count) famous movie quotes \(genrePrompt) at \(difficulty.rawValue) difficulty.

        Return ONLY a JSON array in this exact format:
        [
          {
            "movieLine": "The movie quote",
            "correctMovie": "Correct Movie title",
            "options": ["Movie1", "Movie2", "Movie3", "Movie4"],
            "year": "Release year"
          }
        ]

        Only include quotes from G, PG, or PG-13 rated family-friendly movies.
        Quotes should be memorable and recognizable.
        The options array should include the correct movie and 3 plausible wrong answers.
        \(childContext)
        """

        let response = try await aiService.sendMessage(
            prompt,
            personality: Personality.motivationalCoach,
            featureType: .learning,
            conversationHistory: []
        )

        return parseMovieQuoteJSON(response.content, difficulty: difficulty)
    }

    private func refillMovieQuotePool(genre: String?, difficulty: TriviaQuestion.Difficulty) async throws {
        let cacheKey = "\(genre ?? "general")|\(difficulty.rawValue)"
        print("📦 Refilling movie quote pool for \(cacheKey)")
        let newQuotes = try await fetchMovieQuotesFromAI(genre: genre, difficulty: difficulty, count: fetchBatchSize)
        await GameContentCache.shared.addMovieQuotes(key: cacheKey, quotes: newQuotes)
    }

    // MARK: - Video Game Challenge Generation

    /// Generate video game trivia/challenges (uses caching)
    func generateVideoGameChallenges(
        category: String? = nil,
        difficulty: TriviaQuestion.Difficulty,
        count: Int = 8
    ) async throws -> [VideoGameChallenge] {
        let cacheKey = "\(category ?? "general")|\(difficulty.rawValue)"

        // Try cache first
        if let cached = await GameContentCache.shared.getVideoGameChallenges(key: cacheKey, count: count) {
            print("📦 Video game cache hit: returning \(cached.count) challenges from pool")

            if await GameContentCache.shared.videoGamePoolNeedsRefill(key: cacheKey) {
                Task {
                    try? await self.refillVideoGamePool(category: category, difficulty: difficulty)
                }
            }

            return cached
        }

        // Cache miss - generate new
        print("📦 Video game cache miss: generating new pool for \(cacheKey)")
        let challenges = try await fetchVideoGameChallengesFromAI(category: category, difficulty: difficulty, count: fetchBatchSize)
        await GameContentCache.shared.addVideoGameChallenges(key: cacheKey, challenges: challenges)
        return Array(challenges.prefix(count))
    }

    private func fetchVideoGameChallengesFromAI(
        category: String?,
        difficulty: TriviaQuestion.Difficulty,
        count: Int
    ) async throws -> [VideoGameChallenge] {
        let categoryPrompt = category != nil ? "about \(category!)" : "about popular video games"

        let childContext = getChildContext()

        let prompt = """
        Generate \(count) video game trivia questions or challenges \(categoryPrompt) at \(difficulty.rawValue) difficulty.

        Return ONLY a JSON array in this exact format:
        [
          {
            "clue": "The clue or description",
            "correctGame": "Correct game title",
            "options": ["Game1", "Game2", "Game3", "Game4"],
            "franchise": "Game franchise (optional, can be null)"
          }
        ]

        Focus on family-friendly games (E or E10+ rated).
        The options array should include the correct game and 3 plausible wrong answers.
        Clues can be about game mechanics, characters, history, or fun facts.
        \(childContext)
        """

        let response = try await aiService.sendMessage(
            prompt,
            personality: Personality.motivationalCoach,
            featureType: .learning,
            conversationHistory: []
        )

        return parseVideoGameChallengeJSON(response.content, difficulty: difficulty)
    }

    private func refillVideoGamePool(category: String?, difficulty: TriviaQuestion.Difficulty) async throws {
        let cacheKey = "\(category ?? "general")|\(difficulty.rawValue)"
        print("📦 Refilling video game pool for \(cacheKey)")
        let newChallenges = try await fetchVideoGameChallengesFromAI(category: category, difficulty: difficulty, count: fetchBatchSize)
        await GameContentCache.shared.addVideoGameChallenges(key: cacheKey, challenges: newChallenges)
    }

    // MARK: - JSON Parsing

    private func parseTriviaJSON(_ jsonString: String, difficulty: TriviaQuestion.Difficulty) -> [TriviaQuestion] {
        guard let jsonStart = jsonString.firstIndex(of: "["),
              let jsonEnd = jsonString.lastIndex(of: "]") else {
            print("⚠️ No JSON array found in trivia response")
            return []
        }

        let jsonSubstring = jsonString[jsonStart...jsonEnd]
        guard let jsonData = String(jsonSubstring).data(using: .utf8) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            let items = try decoder.decode([TriviaJSON].self, from: jsonData)
            return items.map { item in
                TriviaQuestion(
                    category: item.category,
                    question: item.question,
                    options: item.options,
                    correctAnswer: item.correctAnswer,
                    difficulty: difficulty
                )
            }
        } catch {
            print("⚠️ Failed to decode trivia JSON: \(error)")
            return []
        }
    }

    private func parseSpellingJSON(_ jsonString: String, difficulty: TriviaQuestion.Difficulty) -> [SpellingWord] {
        guard let jsonStart = jsonString.firstIndex(of: "["),
              let jsonEnd = jsonString.lastIndex(of: "]") else {
            print("⚠️ No JSON array found in spelling response")
            return []
        }

        let jsonSubstring = jsonString[jsonStart...jsonEnd]
        guard let jsonData = String(jsonSubstring).data(using: .utf8) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            let items = try decoder.decode([SpellingJSON].self, from: jsonData)
            return items.map { item in
                SpellingWord(
                    word: item.word,
                    definition: item.definition,
                    difficulty: difficulty,
                    audioHint: item.audioHint
                )
            }
        } catch {
            print("⚠️ Failed to decode spelling JSON: \(error)")
            return []
        }
    }

    private func parseMovieQuoteJSON(_ jsonString: String, difficulty: TriviaQuestion.Difficulty) -> [MovieLineChallenge] {
        guard let jsonStart = jsonString.firstIndex(of: "["),
              let jsonEnd = jsonString.lastIndex(of: "]") else {
            print("⚠️ No JSON array found in movie quote response")
            return []
        }

        let jsonSubstring = jsonString[jsonStart...jsonEnd]
        guard let jsonData = String(jsonSubstring).data(using: .utf8) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            let items = try decoder.decode([MovieQuoteJSON].self, from: jsonData)
            return items.map { item in
                MovieLineChallenge(
                    movieLine: item.movieLine,
                    correctMovie: item.correctMovie,
                    options: item.options,
                    year: item.year,
                    difficulty: difficulty
                )
            }
        } catch {
            print("⚠️ Failed to decode movie quote JSON: \(error)")
            return []
        }
    }

    private func parseVideoGameChallengeJSON(_ jsonString: String, difficulty: TriviaQuestion.Difficulty) -> [VideoGameChallenge] {
        guard let jsonStart = jsonString.firstIndex(of: "["),
              let jsonEnd = jsonString.lastIndex(of: "]") else {
            print("⚠️ No JSON array found in video game challenge response")
            return []
        }

        let jsonSubstring = jsonString[jsonStart...jsonEnd]
        guard let jsonData = String(jsonSubstring).data(using: .utf8) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            let items = try decoder.decode([VideoGameChallengeJSON].self, from: jsonData)
            return items.map { item in
                VideoGameChallenge(
                    clue: item.clue,
                    correctGame: item.correctGame,
                    options: item.options,
                    franchise: item.franchise,
                    difficulty: difficulty
                )
            }
        } catch {
            print("⚠️ Failed to decode video game challenge JSON: \(error)")
            return []
        }
    }
}

// MARK: - JSON Decoding Models

private struct TriviaJSON: Codable {
    let category: String
    let question: String
    let options: [String]
    let correctAnswer: Int
}

private struct SpellingJSON: Codable {
    let word: String
    let definition: String
    let audioHint: String
}

private struct MovieQuoteJSON: Codable {
    let movieLine: String
    let correctMovie: String
    let options: [String]
    let year: String
}

private struct VideoGameChallengeJSON: Codable {
    let clue: String
    let correctGame: String
    let options: [String]
    let franchise: String?
}
