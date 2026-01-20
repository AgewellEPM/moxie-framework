import SwiftUI
import Combine

@MainActor
class UsageViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var todaySummary: UsageSummary?
    @Published var weekSummary: UsageSummary?
    @Published var monthSummary: UsageSummary?
    @Published var recentRecords: [UsageRecord] = []
    @Published var dailyTrend: [(date: Date, cost: Double)] = []
    @Published var alerts: [CostAlert] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Yesterday's data for comparison
    @Published var yesterdayCost: Double = 0.0
    @Published var lastWeekCost: Double = 0.0
    @Published var lastMonthCost: Double = 0.0

    // Model comparison data
    @Published var modelComparison: [ModelComparisonData] = []
    @Published var featureBreakdown: [FeatureBreakdownData] = []

    private let usageRepository: UsageRepositoryProtocol
    private var refreshTimer: Timer?

    // MARK: - Initialization
    init(usageRepository: UsageRepositoryProtocol = UsageRepository()) {
        self.usageRepository = usageRepository
    }

    // MARK: - Data Loading
    func loadAllData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load summaries
            async let today = usageRepository.calculateDailySummary(for: Date())
            async let week = usageRepository.calculateWeeklySummary()
            async let month = usageRepository.calculateMonthlySummary()

            // Load recent records
            async let recent = usageRepository.getRecentRecords(limit: 50)

            // Load daily trend
            async let trend = usageRepository.calculateDailyTrend(days: 7)

            // Load alerts
            async let alertsData = usageRepository.detectCostAnomalies()

            // Load yesterday's data
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            async let yesterdaySummary = usageRepository.calculateDailySummary(for: yesterday)

            // Wait for all data
            todaySummary = try await today
            weekSummary = try await week
            monthSummary = try await month
            recentRecords = try await recent
            dailyTrend = try await trend
            alerts = try await alertsData
            yesterdayCost = try await yesterdaySummary.totalCost

            // Calculate last week and last month costs for comparison
            await calculateComparisons()

            // Build model comparison data
            buildModelComparison()

            // Build feature breakdown
            buildFeatureBreakdown()

        } catch {
            errorMessage = "Failed to load usage data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func calculateComparisons() async {
        do {
            // Last week
            let lastWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
            let lastWeekEnd = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.dateInterval(of: .weekOfYear, for: Date())!.start)!
            let lastWeekRecords = try await usageRepository.getUsageRecords(from: lastWeekStart, to: lastWeekEnd)
            lastWeekCost = lastWeekRecords.reduce(0.0) { $0 + $1.estimatedCost }

            // Last month
            let lastMonthStart = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            let lastMonthEnd = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.dateInterval(of: .month, for: Date())!.start)!
            let lastMonthRecords = try await usageRepository.getUsageRecords(from: lastMonthStart, to: lastMonthEnd)
            lastMonthCost = lastMonthRecords.reduce(0.0) { $0 + $1.estimatedCost }
        } catch {
            print("Failed to calculate comparisons: \(error)")
        }
    }

    private func buildModelComparison() {
        guard let monthSummary = monthSummary else { return }

        modelComparison = monthSummary.byModel.map { model, data in
            ModelComparisonData(
                modelName: model,
                totalCost: data.cost,
                usageCount: data.count,
                averageCost: data.cost / Double(max(data.count, 1))
            )
        }.sorted { $0.totalCost > $1.totalCost }
    }

    private func buildFeatureBreakdown() {
        guard let monthSummary = monthSummary else { return }

        featureBreakdown = monthSummary.byFeature.map { feature, data in
            FeatureBreakdownData(
                feature: feature,
                totalCost: data.cost,
                usageCount: data.count,
                icon: feature.icon,
                name: feature.displayName
            )
        }.sorted { $0.totalCost > $1.totalCost }
    }

    // MARK: - Auto Refresh
    func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                await self.loadAllData()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Computed Properties
    var todayVsYesterday: Double {
        guard yesterdayCost > 0, let today = todaySummary else { return 0 }
        return ((today.totalCost - yesterdayCost) / yesterdayCost) * 100
    }

    var weekVsLastWeek: Double {
        guard lastWeekCost > 0, let week = weekSummary else { return 0 }
        return ((week.totalCost - lastWeekCost) / lastWeekCost) * 100
    }

    var monthVsLastMonth: Double {
        guard lastMonthCost > 0, let month = monthSummary else { return 0 }
        return ((month.totalCost - lastMonthCost) / lastMonthCost) * 100
    }

    var projectedMonthlyCost: Double {
        guard todaySummary != nil else { return 0 }
        let dayOfMonth = Calendar.current.component(.day, from: Date())
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        let averageDailyCost = (monthSummary?.totalCost ?? 0) / Double(dayOfMonth)
        return averageDailyCost * Double(daysInMonth)
    }

    var mostUsedModel: String? {
        monthSummary?.byModel.max { $0.value.count < $1.value.count }?.key
    }

    var mostExpensiveFeature: FeatureType? {
        monthSummary?.byFeature.max { $0.value.cost < $1.value.cost }?.key
    }

    // MARK: - Cost Saving Recommendations
    func generateSavingRecommendations() -> [String] {
        var recommendations: [String] = []

        // Check if using expensive models
        if let mostUsed = mostUsedModel {
            if mostUsed.contains("gpt-4o") && !mostUsed.contains("mini") {
                let potentialSaving = (monthSummary?.totalCost ?? 0) * 0.9
                recommendations.append(String(format: "Switch to GPT-4o-mini to save ~$%.2f/month", potentialSaving))
            } else if mostUsed.contains("claude-3-opus") {
                let potentialSaving = (monthSummary?.totalCost ?? 0) * 0.8
                recommendations.append(String(format: "Switch to Claude 3.5 Sonnet to save ~$%.2f/month", potentialSaving))
            }
        }

        // Suggest DeepSeek for high volume
        if (monthSummary?.recordCount ?? 0) > 500 {
            recommendations.append("Consider DeepSeek for high-volume usage - 90% cheaper than GPT-4o")
        }

        // Feature-specific recommendations
        if let expensiveFeature = mostExpensiveFeature {
            switch expensiveFeature {
            case .story:
                recommendations.append("Story generation uses more tokens - consider shorter stories")
            case .learning:
                recommendations.append("Learning sessions can be optimized with more concise prompts")
            default:
                break
            }
        }

        return recommendations
    }

    // MARK: - Export Functions
    func exportUsageReport() -> String {
        var report = "Moxie AI Usage Report\n"
        report += "Generated: \(Date().formatted())\n\n"

        if let today = todaySummary {
            report += "Today: \(today.formattedTotalCost) (\(today.recordCount) requests)\n"
        }

        if let week = weekSummary {
            report += "This Week: \(week.formattedTotalCost) (\(week.recordCount) requests)\n"
        }

        if let month = monthSummary {
            report += "This Month: \(month.formattedTotalCost) (\(month.recordCount) requests)\n\n"

            report += "By Model:\n"
            for (model, data) in month.byModel.sorted(by: { $0.value.cost > $1.value.cost }) {
                report += "  \(model): $\(String(format: "%.2f", data.cost)) (\(data.count) uses)\n"
            }

            report += "\nBy Feature:\n"
            for (feature, data) in month.byFeature.sorted(by: { $0.value.cost > $1.value.cost }) {
                report += "  \(feature.displayName): $\(String(format: "%.2f", data.cost)) (\(data.count) uses)\n"
            }
        }

        report += "\nRecommendations:\n"
        for recommendation in generateSavingRecommendations() {
            report += "• \(recommendation)\n"
        }

        return report
    }

}

// MARK: - Supporting Data Models

struct ModelComparisonData: Identifiable {
    let id = UUID()
    let modelName: String
    let totalCost: Double
    let usageCount: Int
    let averageCost: Double

    var formattedTotalCost: String {
        String(format: "$%.2f", totalCost)
    }

    var formattedAverageCost: String {
        String(format: "$%.4f", averageCost)
    }
}

struct FeatureBreakdownData: Identifiable {
    let id = UUID()
    let feature: FeatureType
    let totalCost: Double
    let usageCount: Int
    let icon: String
    let name: String

    var formattedCost: String {
        String(format: "$%.2f", totalCost)
    }

    var percentage: Double {
        // This will be calculated relative to total in the view
        0
    }
}