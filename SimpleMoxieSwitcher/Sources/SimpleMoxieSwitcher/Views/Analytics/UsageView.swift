import SwiftUI
import Charts

/// Usage analytics dashboard matching Windows version
struct UsageView: View {
    @StateObject private var viewModel = UsageViewModel()
    @State private var selectedTimeRange: TimeRange = .thisMonth
    @State private var showExportSheet = false

    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case allTime = "All Time"
    }

    var body: some View {
        ZStack {
            // Background gradient matching Windows
            LinearGradient(
                colors: [
                    Color(hex: "1A1A1A"),
                    Color(hex: "0F3460"),
                    Color(hex: "1A1A1A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            } else {
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        headerSection

                        // Summary Cards
                        summaryCardsSection

                        // Charts
                        chartsSection

                        // Detailed Statistics
                        detailedStatsSection
                    }
                    .padding(30)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            Task {
                await viewModel.loadAllData()
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportReportView(reportText: viewModel.exportUsageReport())
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("📊 Usage Analytics")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text("Track and analyze Moxie interactions")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "AAAAAA"))
            }

            Spacer()

            HStack {
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)

                Button(action: { showExportSheet = true }) {
                    Text("Export Report")
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(30)
        .background(Color.black.opacity(0.3))
        .cornerRadius(20)
    }

    // MARK: - Summary Cards

    private var summaryCardsSection: some View {
        HStack(spacing: 10) {
            summaryCard(
                icon: "⏱️",
                value: formatTime(viewModel.todaySummary?.recordCount ?? 0),
                label: "Total Time",
                change: viewModel.todayVsYesterday,
                color: Color(hex: "00CED1")
            )

            summaryCard(
                icon: "💬",
                value: "\(viewModel.weekSummary?.recordCount ?? 0)",
                label: "Sessions",
                change: viewModel.weekVsLastWeek,
                color: Color(hex: "9B59B6")
            )

            summaryCard(
                icon: "🎯",
                value: "\(viewModel.monthSummary?.recordCount ?? 0)",
                label: "Activities",
                change: viewModel.monthVsLastMonth,
                color: Color(hex: "FFD700")
            )

            summaryCard(
                icon: "⭐",
                value: String(format: "$%.2f", viewModel.monthSummary?.totalCost ?? 0),
                label: "AI Cost",
                change: viewModel.monthVsLastMonth,
                color: Color(hex: "2ECC71")
            )
        }
    }

    private func summaryCard(icon: String, value: String, label: String, change: Double, color: Color) -> some View {
        VStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 32))

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(Color(hex: "AAAAAA"))

            if change != 0 {
                Text(change > 0 ? "+\(Int(change))%" : "\(Int(change))%")
                    .font(.caption)
                    .foregroundColor(change > 0 ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white.opacity(0.15))
        .cornerRadius(15)
    }

    // MARK: - Charts Section

    private var chartsSection: some View {
        HStack(spacing: 15) {
            // Daily Usage Chart
            VStack(alignment: .leading, spacing: 15) {
                Text("Daily Usage")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                if !viewModel.dailyTrend.isEmpty {
                    Chart {
                        ForEach(viewModel.dailyTrend, id: \.date) { dataPoint in
                            BarMark(
                                x: .value("Day", dataPoint.date, unit: .day),
                                y: .value("Cost", dataPoint.cost)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "00CED1"), Color(hex: "9B59B6")],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                        }
                    }
                    .frame(height: 250)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "AAAAAA"))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .foregroundStyle(Color(hex: "AAAAAA"))
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.black.opacity(0.2))
                        .frame(height: 250)
                        .overlay(
                            Text("No data available")
                                .foregroundColor(Color(hex: "AAAAAA"))
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.white.opacity(0.15))
            .cornerRadius(15)

            // Activity Breakdown
            VStack(alignment: .leading, spacing: 15) {
                Text("Activity Breakdown")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                ForEach(viewModel.featureBreakdown.prefix(5)) { feature in
                    activityBreakdownRow(feature: feature)
                }
            }
            .frame(width: 350)
            .padding(20)
            .background(Color.white.opacity(0.15))
            .cornerRadius(15)
        }
    }

    private func activityBreakdownRow(feature: FeatureBreakdownData) -> some View {
        HStack(spacing: 10) {
            Text(feature.icon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 5) {
                Text(feature.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(hex: "333333"))
                            .frame(height: 6)
                            .cornerRadius(3)

                        Rectangle()
                            .fill(Color(hex: "00CED1"))
                            .frame(width: geometry.size.width * (feature.totalCost / (viewModel.monthSummary?.totalCost ?? 1)), height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }

            Text(feature.formattedCost)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "00CED1"))
        }
        .padding(15)
        .background(Color.black.opacity(0.2))
        .cornerRadius(10)
    }

    // MARK: - Detailed Statistics

    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Model Comparison")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 20) {
                ForEach(viewModel.modelComparison.prefix(3)) { model in
                    modelStatsColumn(model: model)
                }
            }

            // Cost Saving Recommendations
            if !viewModel.generateSavingRecommendations().isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("💡 Cost Saving Recommendations")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .padding(.top, 10)

                    ForEach(viewModel.generateSavingRecommendations(), id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.white)
                            Text(recommendation)
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "AAAAAA"))
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.15))
        .cornerRadius(15)
    }

    private func modelStatsColumn(model: ModelComparisonData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.modelName)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "00CED1"))

            VStack(alignment: .leading, spacing: 5) {
                statRow(label: "Total Cost", value: model.formattedTotalCost)
                statRow(label: "Usage Count", value: "\(model.usageCount)")
                statRow(label: "Avg Cost", value: model.formattedAverageCost)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(Color(hex: "AAAAAA"))
            Spacer()
            Text(value)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }

    // MARK: - Helper Functions

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Export Report View

struct ExportReportView: View {
    let reportText: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Usage Report")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding()

            ScrollView {
                Text(reportText)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            Button(action: copyToClipboard) {
                Label("Copy to Clipboard", systemImage: "doc.on.doc")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(width: 600, height: 500)
    }

    private func copyToClipboard() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(reportText, forType: .string)
        #endif
    }
}

// Color extension is defined in ModeColors.swift
