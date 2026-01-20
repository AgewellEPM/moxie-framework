import Foundation

// MARK: - Usage Repository Protocol
protocol UsageRepositoryProtocol {
    func loadUsageRecords() async throws -> [UsageRecord]
    func saveUsageRecord(_ record: UsageRecord) async throws
    func saveUsageRecords(_ records: [UsageRecord]) async throws
    func getUsageRecords(from startDate: Date, to endDate: Date) async throws -> [UsageRecord]
    func getUsageRecordsByFeature(_ feature: FeatureType) async throws -> [UsageRecord]
    func getUsageRecordsByModel(_ model: String) async throws -> [UsageRecord]
    func calculateDailySummary(for date: Date) async throws -> UsageSummary
    func calculateWeeklySummary() async throws -> UsageSummary
    func calculateMonthlySummary() async throws -> UsageSummary
    func clearAllUsageRecords() async throws
    func getHighCostRecords(threshold: Double) async throws -> [UsageRecord]
    func getRecentRecords(limit: Int) async throws -> [UsageRecord]
    func getTotalSpentToday() async throws -> Double
    func getTotalSpentThisWeek() async throws -> Double
    func getTotalSpentThisMonth() async throws -> Double
    func calculateDailyTrend(days: Int) async throws -> [(date: Date, cost: Double)]
    func detectCostAnomalies() async throws -> [CostAlert]
}

// MARK: - Usage Repository Implementation
class UsageRepository: UsageRepositoryProtocol {
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                              in: .userDomainMask).first!
    private var usageFile: URL {
        documentsDirectory.appendingPathComponent("MoxieUsageRecords.json")
    }

    // Thread-safe queue for file operations
    private let fileQueue = DispatchQueue(label: "com.moxie.usagerepository", attributes: .concurrent)

    // MARK: - Load & Save Operations

    func loadUsageRecords() async throws -> [UsageRecord] {
        return try await withCheckedThrowingContinuation { continuation in
            fileQueue.async {
                guard FileManager.default.fileExists(atPath: self.usageFile.path) else {
                    continuation.resume(returning: [])
                    return
                }

                do {
                    let data = try Data(contentsOf: self.usageFile)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let records = try decoder.decode([UsageRecord].self, from: data)
                    continuation.resume(returning: records.sorted { $0.timestamp > $1.timestamp })
                } catch {
                    print("Error loading usage records: \(error)")
                    // Return empty array on error to not break the app
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func saveUsageRecord(_ record: UsageRecord) async throws {
        var records = try await loadUsageRecords()
        records.insert(record, at: 0) // Add new record at the beginning

        // Keep only last 90 days of records to prevent file from growing too large
        let ninetyDaysAgo = Date().addingTimeInterval(-90 * 24 * 60 * 60)
        records = records.filter { $0.timestamp > ninetyDaysAgo }

        try await saveAllRecords(records)
    }

    func saveUsageRecords(_ newRecords: [UsageRecord]) async throws {
        var records = try await loadUsageRecords()
        records.append(contentsOf: newRecords)
        records.sort { $0.timestamp > $1.timestamp }

        // Keep only last 90 days of records
        let ninetyDaysAgo = Date().addingTimeInterval(-90 * 24 * 60 * 60)
        records = records.filter { $0.timestamp > ninetyDaysAgo }

        try await saveAllRecords(records)
    }

    private func saveAllRecords(_ records: [UsageRecord]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            fileQueue.async(flags: .barrier) {
                do {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    let data = try encoder.encode(records)
                    try data.write(to: self.usageFile)
                    continuation.resume()
                } catch {
                    print("Error saving usage records: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Query Operations

    func getUsageRecords(from startDate: Date, to endDate: Date) async throws -> [UsageRecord] {
        let allRecords = try await loadUsageRecords()
        return allRecords.filter { record in
            record.timestamp >= startDate && record.timestamp <= endDate
        }
    }

    func getUsageRecordsByFeature(_ feature: FeatureType) async throws -> [UsageRecord] {
        let allRecords = try await loadUsageRecords()
        return allRecords.filter { $0.featureType == feature }
    }

    func getUsageRecordsByModel(_ model: String) async throws -> [UsageRecord] {
        let allRecords = try await loadUsageRecords()
        return allRecords.filter { $0.modelUsed == model }
    }

    // MARK: - Summary Calculations

    func calculateDailySummary(for date: Date) async throws -> UsageSummary {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let records = try await getUsageRecords(from: startOfDay, to: endOfDay)
        return calculateSummary(for: records, period: "Today")
    }

    func calculateWeeklySummary() async throws -> UsageSummary {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now.addingTimeInterval(-7 * 24 * 60 * 60)

        let records = try await getUsageRecords(from: startOfWeek, to: now)
        return calculateSummary(for: records, period: "This Week")
    }

    func calculateMonthlySummary() async throws -> UsageSummary {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now.addingTimeInterval(-30 * 24 * 60 * 60)

        let records = try await getUsageRecords(from: startOfMonth, to: now)
        return calculateSummary(for: records, period: "This Month")
    }

    private func calculateSummary(for records: [UsageRecord], period: String) -> UsageSummary {
        let totalCost = records.reduce(0.0) { $0 + $1.estimatedCost }
        let totalTokens = records.reduce(0) { $0 + $1.totalTokens }

        // Group by feature
        var byFeature: [FeatureType: (cost: Double, count: Int)] = [:]
        for feature in FeatureType.allCases {
            let featureRecords = records.filter { $0.featureType == feature }
            if !featureRecords.isEmpty {
                let cost = featureRecords.reduce(0.0) { $0 + $1.estimatedCost }
                byFeature[feature] = (cost: cost, count: featureRecords.count)
            }
        }

        // Group by model
        var byModel: [String: (cost: Double, count: Int)] = [:]
        let modelGroups = Dictionary(grouping: records, by: { $0.modelUsed })
        for (model, modelRecords) in modelGroups {
            let cost = modelRecords.reduce(0.0) { $0 + $1.estimatedCost }
            byModel[model] = (cost: cost, count: modelRecords.count)
        }

        // Calculate average response time
        let responseTimes = records.compactMap { $0.responseTime }
        let averageResponseTime = responseTimes.isEmpty ? nil :
            responseTimes.reduce(0.0, +) / Double(responseTimes.count)

        return UsageSummary(
            period: period,
            totalCost: totalCost,
            totalTokens: totalTokens,
            recordCount: records.count,
            byFeature: byFeature,
            byModel: byModel,
            averageResponseTime: averageResponseTime
        )
    }

    // MARK: - Maintenance Operations

    func clearAllUsageRecords() async throws {
        try await saveAllRecords([])
    }

    // MARK: - Analytics Operations

    func getHighCostRecords(threshold: Double = 0.10) async throws -> [UsageRecord] {
        let records = try await loadUsageRecords()
        return records.filter { $0.estimatedCost >= threshold }
    }

    func getRecentRecords(limit: Int = 100) async throws -> [UsageRecord] {
        let records = try await loadUsageRecords()
        return Array(records.prefix(limit))
    }

    func getTotalSpentToday() async throws -> Double {
        let summary = try await calculateDailySummary(for: Date())
        return summary.totalCost
    }

    func getTotalSpentThisWeek() async throws -> Double {
        let summary = try await calculateWeeklySummary()
        return summary.totalCost
    }

    func getTotalSpentThisMonth() async throws -> Double {
        let summary = try await calculateMonthlySummary()
        return summary.totalCost
    }

    // MARK: - Cost Trend Analysis

    func calculateDailyTrend(days: Int = 7) async throws -> [(date: Date, cost: Double)] {
        let calendar = Calendar.current
        var trends: [(date: Date, cost: Double)] = []

        for dayOffset in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let summary = try await calculateDailySummary(for: date)
            trends.append((date: date, cost: summary.totalCost))
        }

        return trends
    }

    func detectCostAnomalies() async throws -> [CostAlert] {
        var alerts: [CostAlert] = []

        // Get this week's and last week's data
        let thisWeekSummary = try await calculateWeeklySummary()
        let lastWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
        let lastWeekEnd = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.dateInterval(of: .weekOfYear, for: Date())!.start)!
        let lastWeekRecords = try await getUsageRecords(from: lastWeekStart, to: lastWeekEnd)
        let lastWeekSummary = calculateSummary(for: lastWeekRecords, period: "Last Week")

        // Check for significant cost increase
        if thisWeekSummary.totalCost > lastWeekSummary.totalCost * 1.5 && thisWeekSummary.totalCost > 1.0 {
            let increase = ((thisWeekSummary.totalCost / lastWeekSummary.totalCost - 1) * 100)
            alerts.append(CostAlert(
                type: .costIncrease,
                message: String(format: "Your costs this week are %.0f%% higher than last week", increase),
                severity: increase > 100 ? .critical : .warning
            ))
        }

        // Check for high daily usage
        let todaySummary = try await calculateDailySummary(for: Date())
        if todaySummary.totalCost > 5.0 {
            alerts.append(CostAlert(
                type: .highUsage,
                message: String(format: "High usage today: %@", todaySummary.formattedTotalCost),
                severity: todaySummary.totalCost > 10.0 ? .critical : .warning
            ))
        }

        // Suggest cheaper models if using expensive ones frequently
        if let mostUsedModel = thisWeekSummary.byModel.max(by: { $0.value.count < $1.value.count }) {
            if mostUsedModel.key.contains("gpt-4o") && !mostUsedModel.key.contains("mini") {
                alerts.append(CostAlert(
                    type: .modelSuggestion,
                    message: "Consider using GPT-4o-mini or DeepSeek for conversations to save up to 90% on costs",
                    severity: .info
                ))
            } else if mostUsedModel.key.contains("claude-3-opus") {
                alerts.append(CostAlert(
                    type: .modelSuggestion,
                    message: "Claude 3 Opus is very expensive. Consider Claude 3.5 Sonnet for better value",
                    severity: .warning
                ))
            }
        }

        // Budget warning if monthly cost is high
        let monthlySummary = try await calculateMonthlySummary()
        if monthlySummary.totalCost > 20.0 {
            alerts.append(CostAlert(
                type: .budgetWarning,
                message: String(format: "Monthly spending: %@ - consider setting a budget limit", monthlySummary.formattedTotalCost),
                severity: monthlySummary.totalCost > 50.0 ? .critical : .warning
            ))
        }

        return alerts
    }
}