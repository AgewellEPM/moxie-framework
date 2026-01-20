import Foundation

// MARK: - Story Prefetch Service
/// Pre-generates story continuations to reduce wait times
/// When a user views a segment with choices, this service pre-fetches the next segments
@MainActor
class StoryPrefetchService {
    static let shared = StoryPrefetchService()

    // Cache of pre-generated continuations
    // Key: hash of (storyContext + choice)
    // Value: (storyText, nextChoices)
    private var prefetchCache: [String: PrefetchedContinuation] = [:]
    private var pendingPrefetches: Set<String> = []
    private let maxCacheSize = 50
    private let aiService: AIServiceProtocol = AIService()

    private init() {}

    // MARK: - Prefetch API

    /// Trigger prefetch for all choices after user views a story segment
    func prefetchContinuations(
        storyContext: [String],
        choices: [String],
        genre: String,
        authorStyle: String,
        readingLevel: String
    ) async {
        for choice in choices {
            let key = generateKey(storyContext: storyContext, choice: choice)

            // Skip if already cached or being fetched
            if prefetchCache[key] != nil || pendingPrefetches.contains(key) {
                continue
            }

            pendingPrefetches.insert(key)

            // Fire and forget - don't await
            Task {
                await self.fetchContinuation(
                    key: key,
                    storyContext: storyContext,
                    choice: choice,
                    genre: genre,
                    authorStyle: authorStyle,
                    readingLevel: readingLevel
                )
            }
        }
    }

    /// Get prefetched continuation if available
    func getContinuation(storyContext: [String], choice: String) -> PrefetchedContinuation? {
        let key = generateKey(storyContext: storyContext, choice: choice)
        return prefetchCache[key]
    }

    /// Check if a continuation is being prefetched
    func isPrefetching(storyContext: [String], choice: String) -> Bool {
        let key = generateKey(storyContext: storyContext, choice: choice)
        return pendingPrefetches.contains(key)
    }

    /// Clear all prefetched content
    func clearCache() {
        prefetchCache.removeAll()
        pendingPrefetches.removeAll()
    }

    // MARK: - Internal

    private func fetchContinuation(
        key: String,
        storyContext: [String],
        choice: String,
        genre: String,
        authorStyle: String,
        readingLevel: String
    ) async {
        let contextText = storyContext.joined(separator: "\n\n")

        let prompt = """
        Continue this \(genre) story in the style of \(authorStyle) based on the choice: "\(choice)"

        Reading Level: \(readingLevel)

        Previous story:
        \(contextText)

        Write the next paragraph (3-5 sentences) that follows from this choice.
        Then provide exactly 3 new choices for what happens next.

        Format your response as JSON:
        {
            "story": "The continuation text here...",
            "choices": ["Choice 1", "Choice 2", "Choice 3"]
        }
        """

        do {
            let response = try await aiService.sendMessage(
                prompt,
                personality: nil,
                featureType: .story,
                conversationHistory: []
            )

            if let data = response.content.data(using: .utf8),
               let json = try? JSONDecoder().decode(StoryPrefetchResponse.self, from: data) {

                let continuation = PrefetchedContinuation(
                    storyText: json.story,
                    nextChoices: json.choices,
                    generatedAt: Date()
                )

                // Store in cache
                prefetchCache[key] = continuation

                // Track in analytics
                await CacheAnalyticsService.shared.recordCacheHit(
                    category: .story,
                    tokensSaved: response.totalTokens
                )

                print("📖 Prefetched story continuation for choice: \(String(choice.prefix(30)))...")

                // Cleanup old entries if cache too large
                if prefetchCache.count > maxCacheSize {
                    cleanupOldEntries()
                }
            }
        } catch {
            print("⚠️ Story prefetch failed: \(error.localizedDescription)")
        }

        pendingPrefetches.remove(key)
    }

    private func generateKey(storyContext: [String], choice: String) -> String {
        let contextHash = storyContext.joined().hashValue
        return "\(contextHash)_\(choice.hashValue)"
    }

    private func cleanupOldEntries() {
        // Remove oldest half of entries
        let sortedKeys = prefetchCache.keys.sorted { key1, key2 in
            let date1 = prefetchCache[key1]?.generatedAt ?? Date.distantPast
            let date2 = prefetchCache[key2]?.generatedAt ?? Date.distantPast
            return date1 < date2
        }

        let keysToRemove = sortedKeys.prefix(maxCacheSize / 2)
        for key in keysToRemove {
            prefetchCache.removeValue(forKey: key)
        }
    }
}

// MARK: - Models

struct PrefetchedContinuation {
    let storyText: String
    let nextChoices: [String]
    let generatedAt: Date
}

struct StoryPrefetchResponse: Codable {
    let story: String
    let choices: [String]
}
