import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: SettingsViewModel
    @StateObject private var providerManager = AIProviderManager()
    @StateObject private var usageViewModel = UsageViewModel()
    @State private var showResetConfirmation = false
    @State private var selectedTab = 0
    @State private var apiKeys: [AIProvider: String] = [:]
    @State private var selectedModels: [AIProvider: String] = [:]
    @State private var moxieEndpoint: String = UserDefaults.standard.string(forKey: "moxieEndpoint") ?? AppConfig.statusEndpoint
    @State private var showMigrationQR = false
    @State private var showWiFiQR = false
    @State private var wifiSSID: String = UserDefaults.standard.string(forKey: "wifiSSID") ?? ""
    @State private var wifiPassword: String = UserDefaults.standard.string(forKey: "wifiPassword") ?? ""
    @State private var wifiEncryption: String = UserDefaults.standard.string(forKey: "wifiEncryption") ?? "WPA"
    @State private var dockerStatus: String = ""
    @State private var isLaunchingDocker: Bool = false
    @State private var showParentAuth = false
    @State private var parentAccessGranted = false
    @State private var showConversationLogs = false
    @State private var showTimeRestrictions = false
    @State private var showPINSetup = false
    // New Parent Console Views
    @State private var showPrivacySettings = false
    @State private var showSafetyAlerts = false
    @State private var showScreenTimeDashboard = false
    @State private var showWeeklyReport = false
    @State private var showInsightsDashboard = false
    @State private var showMoodTrends = false
    @State private var showTopicAnalysis = false
    @State private var showAgeContentSettings = false
    @State private var showEducationTracker = false
    @State private var showRewardsSystem = false
    // New Parent Features (Batch 2)
    @State private var showContentFilter = false
    @State private var showQuietHours = false
    @State private var showVoiceSettings = false
    @State private var showConversationStarters = false
    @State private var showChildProfiles = false
    @State private var showActivitySuggestions = false
    @State private var showSocialSkillsTracker = false
    @State private var showBedtimeStories = false
    @State private var showLearningGoals = false
    @State private var showParentalNotes = false

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(.ultraThinMaterial)

                // Tab Selector
                HStack(spacing: 12) {
                    TabButton(icon: "key.fill", title: "API Keys", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }

                    TabButton(icon: "dollarsign.circle.fill", title: "Usage & Costs", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }

                    TabButton(icon: "qrcode.viewfinder", title: "Moxie Sync", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }

                    TabButton(icon: "lock.shield.fill", title: "Parent Console", isSelected: selectedTab == 3) {
                        selectedTab = 3
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.2))

                // Content
                if selectedTab == 0 {
                    apiKeysView
                } else if selectedTab == 1 {
                    usageCostsView
                } else if selectedTab == 2 {
                    moxieSyncView
                } else {
                    parentConsoleView
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .preferredColorScheme(.dark)
        .onAppear {
            loadApiKeys()
            if selectedTab == 1 {
                Task {
                    await usageViewModel.loadAllData()
                    usageViewModel.startAutoRefresh()
                }
            }
        }
        .onDisappear {
            usageViewModel.stopAutoRefresh()
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == 1 {
                Task {
                    await usageViewModel.loadAllData()
                    usageViewModel.startAutoRefresh()
                }
            } else {
                usageViewModel.stopAutoRefresh()
            }
        }
        .alert("Reset Personalities", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task {
                    await viewModel.resetPersonalities()
                }
            }
        } message: {
            Text("This will remove all custom personalities. Built-in personalities will remain unchanged. This action cannot be undone.")
        }
    }

    // MARK: - API Keys View
    private var apiKeysView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Info
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("AI Model Integration")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text("Connect your preferred AI model providers to power Moxie's conversations")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 30)

                // Provider Cards
                ForEach(AIProvider.allCases) { provider in
                    ProviderCard(
                        provider: provider,
                        apiKey: Binding(
                            get: {
                                // Always read from providerManager as source of truth
                                if let config = providerManager.providers.first(where: { $0.provider == provider }) {
                                    return config.apiKey
                                }
                                return ""
                            },
                            set: { newValue in
                                // Update local state
                                apiKeys[provider] = newValue
                                // Update provider manager (this is the important part)
                                if var config = providerManager.providers.first(where: { $0.provider == provider }) {
                                    config.apiKey = newValue
                                    providerManager.updateProvider(config)
                                }
                            }
                        ),
                        selectedModel: Binding(
                            get: {
                                // Always read from providerManager as source of truth
                                if let config = providerManager.providers.first(where: { $0.provider == provider }) {
                                    return config.selectedModel
                                }
                                return provider.defaultModels.first ?? ""
                            },
                            set: { newValue in
                                // Update local state
                                selectedModels[provider] = newValue
                                // Update provider manager
                                if var config = providerManager.providers.first(where: { $0.provider == provider }) {
                                    config.selectedModel = newValue
                                    providerManager.updateProvider(config)
                                }
                            }
                        ),
                        isActive: providerManager.activeProvider == provider,
                        providerManager: providerManager,
                        onSelect: {}
                    )
                }

                // Help Text
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Quick Start Guide")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        BulletPoint(text: "Click 'Get API Key' to sign up for a provider")
                        BulletPoint(text: "Copy your API key and paste it in the secure field")
                        BulletPoint(text: "Select your preferred model from the dropdown")
                        BulletPoint(text: "Click 'Set as Active' to use this provider")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Personality Management View
    private var personalityManagementView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Moxie Icon
                Text("🤖")
                    .font(.system(size: 100))
                    .padding(.top, 30)

                VStack(spacing: 20) {
                    Text("Personality Management")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("Reset all custom personalities to restore the default library. Built-in personalities will remain unchanged.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Reset Button
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                            Text("Reset to Defaults")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: 300)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }

    // MARK: - Usage & Costs View
    private var usageCostsView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 30)

                    Text("Real-Time Usage & Costs")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Track your actual AI usage and costs across all features")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Smart Alerts
                if !usageViewModel.alerts.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(usageViewModel.alerts) { alert in
                            HStack(spacing: 12) {
                                Image(systemName: alert.severity.icon)
                                    .foregroundColor(Color(alert.severity.color))
                                    .font(.title3)

                                Text(alert.message)
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                Spacer()
                            }
                            .padding()
                            .background(Color(alert.severity.color).opacity(0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(alert.severity.color).opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                }

                // Real Usage Dashboard
                VStack(spacing: 20) {
                    Text("Your Actual Usage")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40)

                    // Usage Cards Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // Today Card
                        UsageCard(
                            title: "Today",
                            amount: usageViewModel.todaySummary?.formattedTotalCost ?? "$0.00",
                            subtitle: "\(usageViewModel.todaySummary?.recordCount ?? 0) requests",
                            trend: usageViewModel.todayVsYesterday,
                            color: .blue
                        )

                        // This Week Card
                        UsageCard(
                            title: "This Week",
                            amount: usageViewModel.weekSummary?.formattedTotalCost ?? "$0.00",
                            subtitle: "\(usageViewModel.weekSummary?.recordCount ?? 0) requests",
                            trend: usageViewModel.weekVsLastWeek,
                            color: .purple
                        )

                        // This Month Card
                        UsageCard(
                            title: "This Month",
                            amount: usageViewModel.monthSummary?.formattedTotalCost ?? "$0.00",
                            subtitle: "\(usageViewModel.monthSummary?.recordCount ?? 0) requests",
                            trend: usageViewModel.monthVsLastMonth,
                            color: .green
                        )
                    }
                    .padding(.horizontal, 40)

                    // Projected Monthly Cost
                    if usageViewModel.projectedMonthlyCost > 0 {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title3)
                                .foregroundColor(.orange)
                            Text("Projected monthly cost:")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            Text(String(format: "$%.2f", usageViewModel.projectedMonthlyCost))
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                    }
                }

                // Feature Breakdown
                if !usageViewModel.featureBreakdown.isEmpty {
                    VStack(spacing: 16) {
                        Text("Usage by Feature")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 40)

                        VStack(spacing: 8) {
                            ForEach(usageViewModel.featureBreakdown) { feature in
                                HStack {
                                    Text(feature.icon)
                                        .font(.title3)
                                    Text(feature.name)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text("\(feature.usageCount)")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(feature.formattedCost)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                    }
                }

                // Model Comparison
                if !usageViewModel.modelComparison.isEmpty {
                    VStack(spacing: 16) {
                        Text("Usage by Model")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 40)

                        VStack(spacing: 8) {
                            ForEach(usageViewModel.modelComparison) { model in
                                HStack {
                                    Text(model.modelName)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(model.usageCount) uses")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(model.formattedTotalCost)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                    }
                }

                // Cost Saving Recommendations
                if !usageViewModel.generateSavingRecommendations().isEmpty {
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Cost Saving Tips")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(usageViewModel.generateSavingRecommendations(), id: \.self) { tip in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .padding(.top, 2)
                                    Text(tip)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                    }
                }

                // Model Pricing Cards
                VStack(spacing: 16) {
                    Text("Cost per Feature by Model")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40)

                    // GPT-4o
                    ModelCostCard(
                        modelName: "GPT-4o",
                        provider: "OpenAI",
                        color: .green,
                        conversationCost: "$0.01-0.03",
                        storyCost: "$0.03-0.08",
                        learningCost: "$0.05-0.15",
                        languageCost: "$0.02-0.05",
                        musicCost: "$0.01-0.02",
                        strengths: ["Best overall quality", "Great at creative stories", "Excellent for learning"]
                    )

                    // GPT-4o-mini
                    ModelCostCard(
                        modelName: "GPT-4o-mini",
                        provider: "OpenAI",
                        color: .blue,
                        conversationCost: "$0.001-0.003",
                        storyCost: "$0.005-0.02",
                        learningCost: "$0.01-0.05",
                        languageCost: "$0.003-0.01",
                        musicCost: "$0.001-0.005",
                        strengths: ["Very affordable", "Fast responses", "Good for conversations", "Default model"]
                    )

                    // DeepSeek
                    ModelCostCard(
                        modelName: "DeepSeek",
                        provider: "DeepSeek",
                        color: .purple,
                        conversationCost: "$0.0001-0.0005",
                        storyCost: "$0.001-0.003",
                        learningCost: "$0.002-0.008",
                        languageCost: "$0.0005-0.002",
                        musicCost: "$0.0001-0.001",
                        strengths: ["Extremely cheap", "Great for high-volume use", "Good at technical topics"]
                    )

                    // Claude
                    ModelCostCard(
                        modelName: "Claude 3.5 Sonnet",
                        provider: "Anthropic",
                        color: .orange,
                        conversationCost: "$0.02-0.05",
                        storyCost: "$0.05-0.12",
                        learningCost: "$0.08-0.20",
                        languageCost: "$0.03-0.08",
                        musicCost: "$0.02-0.04",
                        strengths: ["Best at creative writing", "Excellent safety", "Great for complex topics"]
                    )
                }
                .padding(.horizontal, 40)

                // Daily Cost Estimator
                VStack(spacing: 16) {
                    Text("Daily Cost Calculator")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 12) {
                        Text("If your child uses Moxie daily with GPT-4o-mini (default):")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        UsageRow(activity: "10 conversations", cost: "$0.01-0.03")
                        UsageRow(activity: "2 stories", cost: "$0.01-0.04")
                        UsageRow(activity: "1 learning session", cost: "$0.01-0.05")
                        UsageRow(activity: "5 language practice", cost: "$0.02-0.05")

                        Divider()
                            .background(Color.white.opacity(0.3))

                        HStack {
                            Text("Estimated Daily Total:")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Text("$0.05-0.17")
                                .font(.headline)
                                .foregroundColor(.green)
                        }

                        Text("Monthly estimate: ~$1.50-5.00")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)

                // Comparison with DeepSeek
                VStack(spacing: 16) {
                    Text("💡 Save Money with DeepSeek")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 12) {
                        Text("Same daily usage with DeepSeek:")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        HStack {
                            Text("Estimated Daily Total:")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Text("$0.005-0.02")
                                .font(.headline)
                                .foregroundColor(.green)
                        }

                        Text("Monthly estimate: ~$0.15-0.60 (90% cheaper!)")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .padding(.horizontal, 40)

                // Info Box
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Important Notes")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Costs are estimates based on average token usage")
                        BulletPoint(text: "Actual costs depend on conversation length and complexity")
                        BulletPoint(text: "All models are pay-as-you-go (no subscriptions)")
                        BulletPoint(text: "You can switch models anytime in API Keys tab")
                        BulletPoint(text: "DeepSeek offers 90%+ savings for high-volume use")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: - Moxie Sync View
    private var moxieSyncView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan, .green],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 30)

                    Text("Sync with Moxie Backend")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Scan the QR code from your Moxie Docker instance to connect to the database and sync your robot")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Current Endpoint Display
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Endpoint:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    HStack {
                        Image(systemName: moxieEndpoint.isEmpty ? "link.slash" : "link")
                            .foregroundColor(moxieEndpoint.isEmpty ? .red : .green)

                        Text(moxieEndpoint.isEmpty ? "Not connected" : moxieEndpoint)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.white)

                        Spacer()

                        if !moxieEndpoint.isEmpty {
                            Button(action: {
                                moxieEndpoint = ""
                                UserDefaults.standard.removeObject(forKey: "moxieEndpoint")
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)

                // QR Code Buttons
                HStack(spacing: 20) {
                    // Migration QR Code Button
                    Button(action: {
                        showMigrationQR = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "qrcode")
                                .font(.title2)
                            Text("Migration QR Code")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)

                    // WiFi QR Code Button
                    Button(action: {
                        showWiFiQR = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "wifi")
                                .font(.title2)
                            Text("WiFi Scanner QR")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)

                Text("Click to view QR codes for syncing")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                // Manual Entry - Endpoint
                VStack(alignment: .leading, spacing: 12) {
                    Text("Endpoint URL:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    HStack {
                        TextField("Enter OpenMoxie endpoint URL", text: $moxieEndpoint)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                        Button(action: {
                            UserDefaults.standard.set(moxieEndpoint, forKey: "moxieEndpoint")
                        }) {
                            Text("Save")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.green, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 40)

                // WiFi Credentials Entry
                VStack(alignment: .leading, spacing: 12) {
                    Text("WiFi Credentials:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    VStack(spacing: 10) {
                        TextField("WiFi Network Name (SSID)", text: $wifiSSID)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                        SecureField("WiFi Password", text: $wifiPassword)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                        HStack {
                            Picker("Encryption", selection: $wifiEncryption) {
                                Text("WPA/WPA2").tag("WPA")
                                Text("WEP").tag("WEP")
                                Text("None").tag("nopass")
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                            Spacer()

                            Button(action: {
                                UserDefaults.standard.set(wifiSSID, forKey: "wifiSSID")
                                UserDefaults.standard.set(wifiPassword, forKey: "wifiPassword")
                                UserDefaults.standard.set(wifiEncryption, forKey: "wifiEncryption")
                            }) {
                                Text("Save WiFi")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.green, in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 40)

                // Docker Launcher
                VStack(spacing: 12) {
                    Button(action: {
                        launchDocker()
                    }) {
                        HStack(spacing: 12) {
                            if isLaunchingDocker {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "shippingbox.fill")
                                    .font(.title2)
                            }
                            Text(isLaunchingDocker ? "Starting..." : "Launch Moxie Docker")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: 400)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: isLaunchingDocker ? [.gray, .gray.opacity(0.8)] : [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLaunchingDocker)

                    if !dockerStatus.isEmpty {
                        Text(dockerStatus)
                            .font(.caption)
                            .foregroundColor(dockerStatus.contains("✅") ? .green : dockerStatus.contains("❌") ? .red : .blue)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    } else {
                        Text("One-click setup: Start Docker and launch Moxie backend")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 40)

                // Connection Info
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Connection Guide")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Click 'Launch Moxie Docker' to start automatically")
                        BulletPoint(text: "Or manually start your Moxie Docker container")
                        BulletPoint(text: "Navigate to your OpenMoxie server endpoint (Settings > Connection)")
                        BulletPoint(text: "Scan the QR code displayed on screen")
                        BulletPoint(text: "The app will sync with your Moxie database")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)

                Spacer()
            }
        }
        .sheet(isPresented: $showMigrationQR) {
            MigrationQRCodeView(endpoint: moxieEndpoint)
        }
        .sheet(isPresented: $showWiFiQR) {
            WiFiQRCodeView(ssid: wifiSSID, password: wifiPassword, encryption: wifiEncryption)
        }
        .sheet(isPresented: $showParentAuth) {
            ParentAuthView {
                // Successfully authenticated
                parentAccessGranted = true
            }
        }
        .sheet(isPresented: $showConversationLogs) {
            ConversationLogView()
        }
        .sheet(isPresented: $showTimeRestrictions) {
            TimeRestrictionView()
        }
        .sheet(isPresented: $showPINSetup) {
            PINSetupView {
                // PIN setup complete
            }
        }
        // New Parent Console Sheets
        .sheet(isPresented: $showPrivacySettings) {
            PrivacySettingsView()
        }
        .sheet(isPresented: $showSafetyAlerts) {
            SafetyAlertsView()
        }
        .sheet(isPresented: $showScreenTimeDashboard) {
            ScreenTimeDashboardView()
        }
        .sheet(isPresented: $showWeeklyReport) {
            WeeklyReportCardView()
        }
        .sheet(isPresented: $showInsightsDashboard) {
            ParentInsightsDashboardView()
        }
        .sheet(isPresented: $showMoodTrends) {
            MoodTrendsView()
        }
        .sheet(isPresented: $showTopicAnalysis) {
            TopicAnalysisView()
        }
        .sheet(isPresented: $showAgeContentSettings) {
            AgeContentSettingsView()
        }
        .sheet(isPresented: $showEducationTracker) {
            EducationTrackerView()
        }
        .sheet(isPresented: $showRewardsSystem) {
            RewardsSystemView()
        }
        // New Parent Features (Batch 2)
        .sheet(isPresented: $showContentFilter) {
            ContentFilterView()
        }
        .sheet(isPresented: $showQuietHours) {
            QuietHoursView()
        }
        .sheet(isPresented: $showVoiceSettings) {
            VoiceSettingsView()
        }
        .sheet(isPresented: $showConversationStarters) {
            ConversationStartersView()
        }
        .sheet(isPresented: $showChildProfiles) {
            ChildProfilesView()
        }
        .sheet(isPresented: $showActivitySuggestions) {
            ActivitySuggestionsView()
        }
        .sheet(isPresented: $showSocialSkillsTracker) {
            SocialSkillsTrackerView()
        }
        .sheet(isPresented: $showBedtimeStories) {
            BedtimeStoriesQueueView()
        }
        .sheet(isPresented: $showLearningGoals) {
            LearningGoalsView()
        }
        .sheet(isPresented: $showParentalNotes) {
            ParentalNotesView()
        }
    }

    // MARK: - Parent Console View
    private var parentConsoleView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 30)

                    Text("Parent Console")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Access parental controls and monitoring features")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Access status
                if parentAccessGranted {
                    // Parent console options
                    VStack(spacing: 16) {
                        // Quick Insights Dashboard
                        ConsoleOptionCard(
                            icon: "sparkles.rectangle.stack.fill",
                            title: "Quick Insights",
                            description: "At-a-glance dashboard for busy parents",
                            color: .cyan,
                            action: {
                                showInsightsDashboard = true
                            }
                        )

                        // Weekly Report Card
                        ConsoleOptionCard(
                            icon: "doc.text.fill",
                            title: "Weekly Report Card",
                            description: "Comprehensive weekly digest of your child's activity",
                            color: .mint,
                            action: {
                                showWeeklyReport = true
                            }
                        )

                        // Conversation Logs
                        ConsoleOptionCard(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "Conversation Logs",
                            description: "View all child conversations with sentiment analysis",
                            color: .blue,
                            action: {
                                showConversationLogs = true
                            }
                        )

                        // Mood Trends
                        ConsoleOptionCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Mood Trends",
                            description: "Track emotional patterns over time",
                            color: .pink,
                            action: {
                                showMoodTrends = true
                            }
                        )

                        // Topic Analysis
                        ConsoleOptionCard(
                            icon: "text.bubble.fill",
                            title: "Topic Analysis",
                            description: "Discover what your child talks about most",
                            color: .purple,
                            action: {
                                showTopicAnalysis = true
                            }
                        )

                        // Screen Time Dashboard
                        ConsoleOptionCard(
                            icon: "clock.fill",
                            title: "Screen Time",
                            description: "Monitor and manage daily usage",
                            color: .teal,
                            action: {
                                showScreenTimeDashboard = true
                            }
                        )

                        // Time Restrictions
                        ConsoleOptionCard(
                            icon: "clock.badge.checkmark.fill",
                            title: "Time Restrictions",
                            description: "Set when your child can access Moxie",
                            color: .orange,
                            action: {
                                showTimeRestrictions = true
                            }
                        )

                        // Education Tracker
                        ConsoleOptionCard(
                            icon: "graduationcap.fill",
                            title: "Learning Progress",
                            description: "Track educational achievements and goals",
                            color: .green,
                            action: {
                                showEducationTracker = true
                            }
                        )

                        // Rewards System
                        ConsoleOptionCard(
                            icon: "medal.fill",
                            title: "Rewards & Achievements",
                            description: "View and manage earned achievements",
                            color: .yellow,
                            action: {
                                showRewardsSystem = true
                            }
                        )

                        // Age Content Settings
                        ConsoleOptionCard(
                            icon: "slider.horizontal.3",
                            title: "Age-Appropriate Content",
                            description: "Customize content level for your child's age",
                            color: .indigo,
                            action: {
                                showAgeContentSettings = true
                            }
                        )

                        // Privacy Settings
                        ConsoleOptionCard(
                            icon: "eye.slash.fill",
                            title: "Privacy Settings",
                            description: "Control data collection and logging levels",
                            color: .gray,
                            action: {
                                showPrivacySettings = true
                            }
                        )

                        // Safety Alerts
                        ConsoleOptionCard(
                            icon: "bell.badge.fill",
                            title: "Safety Alerts",
                            description: "Configure notifications for concerning content",
                            color: .red,
                            action: {
                                showSafetyAlerts = true
                            }
                        )

                        // Usage Reports
                        ConsoleOptionCard(
                            icon: "chart.bar.fill",
                            title: "Cost & Usage Reports",
                            description: "View detailed usage statistics and API costs",
                            color: .brown,
                            action: {
                                selectedTab = 1 // Switch to usage tab
                            }
                        )

                        // PIN Management
                        ConsoleOptionCard(
                            icon: "lock.rotation",
                            title: "Change PIN",
                            description: "Update your Parent Console access PIN",
                            color: .secondary,
                            action: {
                                showPINSetup = true
                            }
                        )

                        // NEW PARENT FEATURES (Batch 2)

                        // Content Filter
                        ConsoleOptionCard(
                            icon: "line.3.horizontal.decrease.circle.fill",
                            title: "Content Filter",
                            description: "Customize content filtering and blocked topics",
                            color: .orange,
                            action: {
                                showContentFilter = true
                            }
                        )

                        // Quiet Hours
                        ConsoleOptionCard(
                            icon: "moon.zzz.fill",
                            title: "Quiet Hours",
                            description: "Schedule times when Moxie stays quiet",
                            color: .indigo,
                            action: {
                                showQuietHours = true
                            }
                        )

                        // Voice Settings
                        ConsoleOptionCard(
                            icon: "speaker.wave.3.fill",
                            title: "Voice Settings",
                            description: "Adjust voice, speed, and audio preferences",
                            color: .cyan,
                            action: {
                                showVoiceSettings = true
                            }
                        )

                        // Conversation Starters
                        ConsoleOptionCard(
                            icon: "text.bubble.fill",
                            title: "Conversation Starters",
                            description: "Browse prompts to help children engage",
                            color: .mint,
                            action: {
                                showConversationStarters = true
                            }
                        )

                        // Child Profiles
                        ConsoleOptionCard(
                            icon: "person.2.fill",
                            title: "Child Profiles",
                            description: "Manage multiple child profiles",
                            color: .blue,
                            action: {
                                showChildProfiles = true
                            }
                        )

                        // Activity Suggestions
                        ConsoleOptionCard(
                            icon: "figure.2.and.child.holdinghands",
                            title: "Activity Suggestions",
                            description: "Fun parent-child activities to do together",
                            color: .green,
                            action: {
                                showActivitySuggestions = true
                            }
                        )

                        // Social Skills Tracker
                        ConsoleOptionCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Social Skills",
                            description: "Track social and emotional development",
                            color: .purple,
                            action: {
                                showSocialSkillsTracker = true
                            }
                        )

                        // Bedtime Stories Queue
                        ConsoleOptionCard(
                            icon: "moon.stars.fill",
                            title: "Bedtime Stories",
                            description: "Queue and manage bedtime story selections",
                            color: .blue,
                            action: {
                                showBedtimeStories = true
                            }
                        )

                        // Learning Goals
                        ConsoleOptionCard(
                            icon: "target",
                            title: "Learning Goals",
                            description: "Set and track educational milestones",
                            color: .teal,
                            action: {
                                showLearningGoals = true
                            }
                        )

                        // Parental Notes
                        ConsoleOptionCard(
                            icon: "note.text",
                            title: "Parental Journal",
                            description: "Journal your child's special moments",
                            color: .pink,
                            action: {
                                showParentalNotes = true
                            }
                        )
                    }
                    .padding(.horizontal, 40)
                } else {
                    // Require authentication
                    VStack(spacing: 20) {
                        Text("Authentication Required")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Enter your PIN to access Parent Console features")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)

                        Button(action: {
                            showParentAuth = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.open.fill")
                                Text("Enter PIN")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .purple.opacity(0.3), radius: 10)
                        }
                        .buttonStyle(.plain)

                        // No PIN setup yet
                        if !PINService().hasPIN() {
                            VStack(spacing: 12) {
                                Divider()
                                    .background(Color.white.opacity(0.3))
                                    .padding(.vertical)

                                Text("First time?")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))

                                Button(action: {
                                    showPINSetup = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Set up PIN")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.cyan)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(30)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal, 40)
                }

                Spacer(minLength: 50)
            }
        }
    }

    // MARK: - Helper Functions
    func loadApiKeys() {
        for provider in AIProvider.allCases {
            if let config = providerManager.providers.first(where: { $0.provider == provider }) {
                apiKeys[provider] = config.apiKey
                selectedModels[provider] = config.selectedModel
            } else {
                apiKeys[provider] = ""
                selectedModels[provider] = provider.defaultModels.first ?? ""
            }
        }
    }

    func launchDocker() {
        Task { @MainActor in
            isLaunchingDocker = true
            dockerStatus = "🔍 Checking Docker installation..."

            let workspace = NSWorkspace.shared

            // Step 1: Check if Docker Desktop is installed
            guard let dockerURL = workspace.urlForApplication(withBundleIdentifier: "com.docker.docker") else {
                dockerStatus = "❌ Docker Desktop not found. Please install Docker Desktop first."
                isLaunchingDocker = false
                return
            }

            // Step 2: Check if Docker is running
            dockerStatus = "🔍 Checking if Docker is running..."
            let runningApps = workspace.runningApplications
            let dockerRunning = runningApps.contains { $0.localizedName == "Docker" || $0.bundleIdentifier == "com.docker.docker" }

            if !dockerRunning {
                dockerStatus = "🚀 Starting Docker Desktop..."
                do {
                    try await workspace.openApplication(at: dockerURL, configuration: NSWorkspace.OpenConfiguration())

                    // Wait for Docker to fully start (15 seconds)
                    for i in 1...15 {
                        dockerStatus = "⏳ Waiting for Docker to start... (\(i)/15)"
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    }
                } catch {
                    dockerStatus = "❌ Failed to start Docker Desktop: \(error.localizedDescription)"
                    isLaunchingDocker = false
                    return
                }
            }

            // Step 3: Check if docker command is available
            dockerStatus = "🔍 Verifying Docker CLI..."
            let dockerPath = "/usr/local/bin/docker"
            guard FileManager.default.fileExists(atPath: dockerPath) else {
                dockerStatus = "❌ Docker CLI not found. Please ensure Docker is properly installed."
                isLaunchingDocker = false
                return
            }

            // Step 4: Check if Moxie container exists
            dockerStatus = "🔍 Looking for Moxie container..."
            let checkProcess = Process()
            checkProcess.executableURL = URL(fileURLWithPath: dockerPath)
            checkProcess.arguments = ["ps", "-a", "--filter", "name=moxie", "--format", "{{.Names}}"]

            let checkPipe = Pipe()
            checkProcess.standardOutput = checkPipe
            checkProcess.standardError = Pipe()

            do {
                try checkProcess.run()
                checkProcess.waitUntilExit()

                let checkData = checkPipe.fileHandleForReading.readDataToEndOfFile()
                let checkOutput = String(data: checkData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if checkOutput.isEmpty {
                    dockerStatus = "❌ Moxie container not found. Please create the container first using:\ndocker run --name moxie ..."
                    isLaunchingDocker = false
                    return
                }
            } catch {
                dockerStatus = "❌ Failed to check for Moxie container: \(error.localizedDescription)"
                isLaunchingDocker = false
                return
            }

            // Step 5: Start the Moxie container
            dockerStatus = "🚀 Starting Moxie container..."
            let startProcess = Process()
            startProcess.executableURL = URL(fileURLWithPath: dockerPath)
            startProcess.arguments = ["start", "moxie"]

            let startPipe = Pipe()
            let errorPipe = Pipe()
            startProcess.standardOutput = startPipe
            startProcess.standardError = errorPipe

            do {
                try startProcess.run()
                startProcess.waitUntilExit()

                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if startProcess.terminationStatus != 0 && !errorOutput.isEmpty {
                    if errorOutput.contains("already started") {
                        dockerStatus = "ℹ️ Moxie container is already running!"
                    } else {
                        dockerStatus = "❌ Failed to start container: \(errorOutput)"
                        isLaunchingDocker = false
                        return
                    }
                } else {
                    dockerStatus = "⏳ Waiting for Moxie backend to be ready..."
                    // Wait for the backend to be ready
                    for i in 1...5 {
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        dockerStatus = "⏳ Waiting for backend... (\(i)/5)"
                    }
                }
            } catch {
                dockerStatus = "❌ Failed to start Moxie: \(error.localizedDescription)"
                isLaunchingDocker = false
                return
            }

            // Step 6: Open the Moxie endpoint in browser
            dockerStatus = "🌐 Opening Moxie dashboard..."
            if let url = URL(string: AppConfig.statusEndpoint) {
                workspace.open(url)
            }

            // Success!
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            dockerStatus = "✅ Moxie is ready! Dashboard opened in your browser."

            // Clear status after 10 seconds
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            dockerStatus = ""
            isLaunchingDocker = false
        }
    }

    func generateQRCode(from string: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return NSImage(cgImage: cgImage, size: NSSize(width: scaledImage.extent.width, height: scaledImage.extent.height))
            }
        }

        return nil
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                isSelected ? Color.blue.opacity(0.3) : Color.clear,
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bullet Point
struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.blue)
                .font(.system(size: 14, weight: .bold))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
    }
}

// MARK: - Migration QR Code View
struct MigrationQRCodeView: View {
    let endpoint: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Dark background like OpenMoxie
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                // Header
                HStack {
                    Text("Migration QR Code")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                Spacer()

                // QR Code Display
                VStack(spacing: 20) {
                    if let qrImage = generateQRCode(from: endpoint) {
                        Image(nsImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 450, height: 450)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: .cyan.opacity(0.5), radius: 20, x: 0, y: 10)
                    }

                    Text("Scan this QR code to sync with Moxie")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(endpoint)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }

                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 700)
    }

    func generateQRCode(from string: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return NSImage(cgImage: cgImage, size: NSSize(width: scaledImage.extent.width, height: scaledImage.extent.height))
            }
        }

        return nil
    }
}

// MARK: - Model Cost Card
struct ModelCostCard: View {
    let modelName: String
    let provider: String
    let color: Color
    let conversationCost: String
    let storyCost: String
    let learningCost: String
    let languageCost: String
    let musicCost: String
    let strengths: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(modelName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(provider)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "cpu.fill")
                    .font(.title)
                    .foregroundColor(color)
            }

            Divider()
                .background(Color.white.opacity(0.3))

            // Cost Breakdown
            VStack(spacing: 8) {
                CostRow(feature: "💬 Conversation", cost: conversationCost)
                CostRow(feature: "📚 Story Time", cost: storyCost)
                CostRow(feature: "🎓 Learning Session", cost: learningCost)
                CostRow(feature: "🌍 Language Practice", cost: languageCost)
                CostRow(feature: "🎤 Music Lookup", cost: musicCost)
            }

            Divider()
                .background(Color.white.opacity(0.3))

            // Strengths
            VStack(alignment: .leading, spacing: 6) {
                Text("Best For:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))

                ForEach(strengths, id: \.self) { strength in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(color)
                        Text(strength)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [color.opacity(0.15), color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Cost Row
struct CostRow: View {
    let feature: String
    let cost: String

    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(cost)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
    }
}

// MARK: - Usage Row
struct UsageRow: View {
    let activity: String
    let cost: String

    var body: some View {
        HStack {
            Text(activity)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(cost)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Usage Card
struct UsageCard: View {
    let title: String
    let amount: String
    let subtitle: String
    let trend: Double
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                if trend != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(String(format: "%.1f%%", abs(trend)))
                            .font(.caption)
                    }
                    .foregroundColor(trend > 0 ? .red : .green)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(amount)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [color.opacity(0.2), color.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Console Option Card
struct ConsoleOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.2))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - WiFi QR Code View
struct WiFiQRCodeView: View {
    let ssid: String
    let password: String
    let encryption: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                // Header
                HStack {
                    Text("WiFi Scanner QR Code")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                Spacer()

                // QR Code Display
                VStack(spacing: 20) {
                    if let qrImage = generateWiFiQRCode() {
                        Image(nsImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 450, height: 450)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: .green.opacity(0.5), radius: 20, x: 0, y: 10)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Please configure WiFi credentials in Settings")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 450, height: 450)
                    }

                    Text("Scan to connect Moxie to WiFi")
                        .font(.headline)
                        .foregroundColor(.white)

                    if !ssid.isEmpty {
                        VStack(spacing: 8) {
                            Text("Network: \(ssid)")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Encryption: \(encryption)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    }
                }

                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 700)
    }

    func generateWiFiQRCode() -> NSImage? {
        guard !ssid.isEmpty else { return nil }

        // WiFi QR code format: WIFI:T:WPA;S:MyNetwork;P:MyPassword;;
        let wifiString = "WIFI:T:\(encryption);S:\(ssid);P:\(password);;"

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(wifiString.utf8)
        filter.correctionLevel = "M"

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return NSImage(cgImage: cgImage, size: NSSize(width: scaledImage.extent.width, height: scaledImage.extent.height))
            }
        }

        return nil
    }
}
