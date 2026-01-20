import Foundation

// MARK: - Cache Analytics Service
/// Tracks cache hit rates and token savings across all caching layers
actor CacheAnalyticsService {
    static let shared = CacheAnalyticsService()

    private var stats: CacheStats = CacheStats()
    private let statsFile = AppPaths.applicationSupport.appendingPathComponent("cache_stats.json")

    private init() {
        Task {
            await loadStats()
        }
    }

    // MARK: - Recording

    /// Record a cache hit (saved tokens)
    func recordCacheHit(category: CacheCategory, tokensSaved: Int) {
        stats.totalCacheHits += 1
        stats.totalTokensSaved += tokensSaved
        stats.hitsByCategory[category.rawValue, default: 0] += 1
        stats.tokensSavedByCategory[category.rawValue, default: 0] += tokensSaved
        stats.lastUpdated = Date()

        // Periodically save
        if stats.totalCacheHits % 10 == 0 {
            Task { await saveStats() }
        }
    }

    /// Record a cache miss (needed fresh generation)
    func recordCacheMiss(category: CacheCategory) {
        stats.totalCacheMisses += 1
        stats.missesByCategory[category.rawValue, default: 0] += 1
        stats.lastUpdated = Date()
    }

    /// Record a provider cache hit (Anthropic/DeepSeek internal caching)
    func recordProviderCacheHit(provider: String, tokensCached: Int) {
        stats.providerCacheHits[provider, default: 0] += 1
        stats.providerTokensCached[provider, default: 0] += tokensCached
        stats.lastUpdated = Date()
    }

    /// Record request deduplication hit
    func recordDeduplicationHit(tokensSaved: Int) {
        stats.deduplicationHits += 1
        stats.deduplicationTokensSaved += tokensSaved
        stats.lastUpdated = Date()
    }

    // MARK: - Reporting

    /// Get current cache statistics
    func getStats() -> CacheStats {
        return stats
    }

    /// Get formatted summary report
    func getSummaryReport() -> String {
        let hitRate = stats.totalCacheHits + stats.totalCacheMisses > 0
            ? Double(stats.totalCacheHits) / Double(stats.totalCacheHits + stats.totalCacheMisses) * 100
            : 0

        // Estimate cost savings (using gpt-4o-mini rate: $0.15/1M input + $0.60/1M output)
        let estimatedSavings = Double(stats.totalTokensSaved) / 1_000_000 * 0.375 // average rate

        return """
        === Cache Analytics Report ===

        Overall Hit Rate: \(String(format: "%.1f%%", hitRate))
        Total Cache Hits: \(stats.totalCacheHits)
        Total Cache Misses: \(stats.totalCacheMisses)
        Total Tokens Saved: \(formatNumber(stats.totalTokensSaved))
        Estimated Cost Savings: $\(String(format: "%.4f", estimatedSavings))

        By Category:
        \(categoryReport())

        Request Deduplication:
        - Hits: \(stats.deduplicationHits)
        - Tokens Saved: \(formatNumber(stats.deduplicationTokensSaved))

        Provider Caching:
        \(providerReport())

        Last Updated: \(formatDate(stats.lastUpdated))
        """
    }

    /// Get cache stats as dictionary for UI display
    func getStatsForDisplay() -> [String: Any] {
        let hitRate = stats.totalCacheHits + stats.totalCacheMisses > 0
            ? Double(stats.totalCacheHits) / Double(stats.totalCacheHits + stats.totalCacheMisses)
            : 0

        return [
            "hitRate": hitRate,
            "totalHits": stats.totalCacheHits,
            "totalMisses": stats.totalCacheMisses,
            "tokensSaved": stats.totalTokensSaved,
            "estimatedSavings": Double(stats.totalTokensSaved) / 1_000_000 * 0.375,
            "byCategory": stats.hitsByCategory,
            "deduplicationHits": stats.deduplicationHits
        ]
    }

    /// Reset all statistics
    func resetStats() {
        stats = CacheStats()
        Task { await saveStats() }
    }

    // MARK: - Persistence

    private func loadStats() async {
        do {
            let data = try Data(contentsOf: statsFile)
            stats = try JSONDecoder().decode(CacheStats.self, from: data)
            print("📊 Cache stats loaded: \(stats.totalCacheHits) hits, \(formatNumber(stats.totalTokensSaved)) tokens saved")
        } catch {
            // No existing stats file, start fresh
            print("📊 Starting fresh cache statistics")
        }
    }

    func saveStats() async {
        do {
            try? FileManager.default.createDirectory(at: AppPaths.applicationSupport, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(stats)
            try data.write(to: statsFile)
        } catch {
            print("⚠️ Failed to save cache stats: \(error)")
        }
    }

    // MARK: - Helpers

    private func categoryReport() -> String {
        var report = ""
        for category in CacheCategory.allCases {
            let hits = stats.hitsByCategory[category.rawValue] ?? 0
            let misses = stats.missesByCategory[category.rawValue] ?? 0
            let tokens = stats.tokensSavedByCategory[category.rawValue] ?? 0
            let rate = hits + misses > 0 ? Double(hits) / Double(hits + misses) * 100 : 0
            report += "  - \(category.rawValue): \(String(format: "%.1f%%", rate)) hit rate, \(formatNumber(tokens)) tokens saved\n"
        }
        return report
    }

    private func providerReport() -> String {
        var report = ""
        for (provider, hits) in stats.providerCacheHits {
            let tokens = stats.providerTokensCached[provider] ?? 0
            report += "  - \(provider): \(hits) hits, \(formatNumber(tokens)) tokens cached\n"
        }
        return report.isEmpty ? "  No provider caching data yet\n" : report
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        }
        return "\(number)"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Cache Statistics Model

struct CacheStats: Codable {
    var totalCacheHits: Int = 0
    var totalCacheMisses: Int = 0
    var totalTokensSaved: Int = 0

    var hitsByCategory: [String: Int] = [:]
    var missesByCategory: [String: Int] = [:]
    var tokensSavedByCategory: [String: Int] = [:]

    var deduplicationHits: Int = 0
    var deduplicationTokensSaved: Int = 0

    var providerCacheHits: [String: Int] = [:]
    var providerTokensCached: [String: Int] = [:]

    var lastUpdated: Date = Date()
}

// MARK: - Cache Categories

enum CacheCategory: String, CaseIterable, Codable {
    case trivia = "Trivia"
    case spelling = "Spelling"
    case movieQuotes = "Movie Quotes"
    case videoGames = "Video Games"
    case vocabulary = "Vocabulary"
    case story = "Story"
    case conversation = "Conversation"
    case request = "Request Dedup"
}
