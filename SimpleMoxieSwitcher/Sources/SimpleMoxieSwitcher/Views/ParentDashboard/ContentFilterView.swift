import SwiftUI

// MARK: - Content Filter Settings
struct ContentFilterSettings: Codable {
    var filterLevel: FilterLevel = .moderate
    var blockedWords: [String] = []
    var blockedTopics: [BlockedTopic] = []
    var allowedExceptions: [String] = []
    var blockExternalLinks: Bool = true
    var blockPersonalQuestions: Bool = true
    var blockViolentContent: Bool = true
    var blockScaryContent: Bool = true
    var customRules: [CustomFilterRule] = []

    enum FilterLevel: String, Codable, CaseIterable {
        case strict = "strict"
        case moderate = "moderate"
        case relaxed = "relaxed"

        var displayName: String {
            switch self {
            case .strict: return "Strict"
            case .moderate: return "Moderate"
            case .relaxed: return "Relaxed"
            }
        }

        var description: String {
            switch self {
            case .strict: return "Maximum filtering. Blocks most sensitive topics."
            case .moderate: return "Balanced filtering. Recommended for most families."
            case .relaxed: return "Minimal filtering. For older, trusted children."
            }
        }

        var icon: String {
            switch self {
            case .strict: return "shield.fill"
            case .moderate: return "shield.lefthalf.filled"
            case .relaxed: return "shield"
            }
        }

        var color: Color {
            switch self {
            case .strict: return .red
            case .moderate: return .orange
            case .relaxed: return .green
            }
        }
    }

    struct BlockedTopic: Codable, Identifiable, Hashable {
        let id: UUID
        let name: String
        let category: String
        var isBlocked: Bool

        init(id: UUID = UUID(), name: String, category: String, isBlocked: Bool = true) {
            self.id = id
            self.name = name
            self.category = category
            self.isBlocked = isBlocked
        }
    }

    struct CustomFilterRule: Codable, Identifiable {
        let id: UUID
        var pattern: String
        var action: FilterAction
        var isEnabled: Bool

        enum FilterAction: String, Codable, CaseIterable {
            case block = "block"
            case warn = "warn"
            case redirect = "redirect"

            var displayName: String { rawValue.capitalized }
        }

        init(id: UUID = UUID(), pattern: String, action: FilterAction = .block, isEnabled: Bool = true) {
            self.id = id
            self.pattern = pattern
            self.action = action
            self.isEnabled = isEnabled
        }
    }
}

// MARK: - Content Filter View
struct ContentFilterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var settings = ContentFilterSettings()
    @State private var showAddWord = false
    @State private var showAddRule = false
    @State private var newWord = ""
    @State private var newException = ""
    @State private var showSaveSuccess = false
    @State private var selectedCategory: String = "All"

    private let settingsKey = "moxie_content_filter_settings"

    private let defaultTopics: [ContentFilterSettings.BlockedTopic] = [
        // Violence
        .init(name: "Weapons", category: "Violence", isBlocked: true),
        .init(name: "Fighting", category: "Violence", isBlocked: true),
        .init(name: "War", category: "Violence", isBlocked: true),
        .init(name: "Gore", category: "Violence", isBlocked: true),
        // Mature
        .init(name: "Dating", category: "Mature", isBlocked: true),
        .init(name: "Romantic Relationships", category: "Mature", isBlocked: false),
        .init(name: "Adult Content", category: "Mature", isBlocked: true),
        // Scary
        .init(name: "Monsters", category: "Scary", isBlocked: false),
        .init(name: "Ghosts", category: "Scary", isBlocked: false),
        .init(name: "Horror Stories", category: "Scary", isBlocked: true),
        .init(name: "Nightmares", category: "Scary", isBlocked: false),
        // Sensitive
        .init(name: "Death", category: "Sensitive", isBlocked: false),
        .init(name: "Illness", category: "Sensitive", isBlocked: false),
        .init(name: "Divorce", category: "Sensitive", isBlocked: false),
        .init(name: "Politics", category: "Sensitive", isBlocked: true),
        .init(name: "Religion", category: "Sensitive", isBlocked: false),
        // Safety
        .init(name: "Personal Information", category: "Safety", isBlocked: true),
        .init(name: "Strangers", category: "Safety", isBlocked: true),
        .init(name: "Secrets", category: "Safety", isBlocked: true)
    ]

    private var categories: [String] {
        ["All"] + Array(Set(settings.blockedTopics.map { $0.category })).sorted()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "9D4EDD").opacity(0.05),
                    Color(hex: "7B2CBF").opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                    .padding()
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                ScrollView {
                    VStack(spacing: 24) {
                        filterLevelSection
                        quickSettingsSection
                        blockedTopicsSection
                        blockedWordsSection
                        exceptionsSection
                        customRulesSection
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear { loadSettings() }
        .overlay(saveSuccessOverlay)
        .sheet(isPresented: $showAddRule) {
            AddCustomRuleSheet(settings: $settings)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text("Content Filters")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "9D4EDD"))
                }
                Text("Customize what content Moxie can discuss")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: saveSettings) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Filter Level Section

    private var filterLevelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Filter Level", systemImage: "slider.horizontal.3")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(ContentFilterSettings.FilterLevel.allCases, id: \.self) { level in
                    FilterLevelCard(
                        level: level,
                        isSelected: settings.filterLevel == level,
                        onSelect: { settings.filterLevel = level }
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Quick Settings Section

    private var quickSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Quick Settings", systemImage: "bolt.fill")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickSettingToggle(
                    title: "Block External Links",
                    description: "Prevent sharing URLs or website references",
                    icon: "link.badge.plus",
                    isOn: $settings.blockExternalLinks
                )

                QuickSettingToggle(
                    title: "Block Personal Questions",
                    description: "Don't ask for address, school name, etc.",
                    icon: "person.fill.questionmark",
                    isOn: $settings.blockPersonalQuestions
                )

                QuickSettingToggle(
                    title: "Block Violent Content",
                    description: "Filter out violence-related discussions",
                    icon: "exclamationmark.triangle.fill",
                    isOn: $settings.blockViolentContent
                )

                QuickSettingToggle(
                    title: "Block Scary Content",
                    description: "Filter out potentially frightening topics",
                    icon: "moon.stars.fill",
                    isOn: $settings.blockScaryContent
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Blocked Topics Section

    private var blockedTopicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Topic Filters", systemImage: "tag.fill")
                    .font(.headline)
                Spacer()
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
            }

            let filteredTopics = selectedCategory == "All"
                ? settings.blockedTopics
                : settings.blockedTopics.filter { $0.category == selectedCategory }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(filteredTopics) { topic in
                    TopicFilterChip(
                        topic: topic,
                        onToggle: {
                            if let index = settings.blockedTopics.firstIndex(where: { $0.id == topic.id }) {
                                settings.blockedTopics[index].isBlocked.toggle()
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Blocked Words Section

    private var blockedWordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Blocked Words", systemImage: "text.badge.xmark")
                    .font(.headline)
                Spacer()
                Text("\(settings.blockedWords.count) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                TextField("Add a word to block...", text: $newWord)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Button(action: addBlockedWord) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .disabled(newWord.isEmpty)
            }

            if !settings.blockedWords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(settings.blockedWords, id: \.self) { word in
                            BlockedWordChip(word: word) {
                                settings.blockedWords.removeAll { $0 == word }
                            }
                        }
                    }
                }
            } else {
                Text("No custom blocked words. Add words that should never appear.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Exceptions Section

    private var exceptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Allowed Exceptions", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                Spacer()
            }

            Text("Words or topics that are allowed even if they match a filter")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                TextField("Add an exception...", text: $newException)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Button(action: addException) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                .disabled(newException.isEmpty)
            }

            if !settings.allowedExceptions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(settings.allowedExceptions, id: \.self) { word in
                            ExceptionChip(word: word) {
                                settings.allowedExceptions.removeAll { $0 == word }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Custom Rules Section

    private var customRulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Custom Rules", systemImage: "gearshape.2.fill")
                    .font(.headline)
                Spacer()
                Button(action: { showAddRule = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Rule")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            if settings.customRules.isEmpty {
                Text("No custom rules. Add advanced filtering patterns.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(settings.customRules) { rule in
                    CustomRuleRow(rule: rule) {
                        settings.customRules.removeAll { $0.id == rule.id }
                    } onToggle: {
                        if let index = settings.customRules.firstIndex(where: { $0.id == rule.id }) {
                            settings.customRules[index].isEnabled.toggle()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Save Success Overlay

    private var saveSuccessOverlay: some View {
        Group {
            if showSaveSuccess {
                VStack {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Content filters saved")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.green.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                    Spacer()
                }
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Helpers

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(ContentFilterSettings.self, from: data) {
            settings = decoded
        } else {
            settings.blockedTopics = defaultTopics
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }

        withAnimation {
            showSaveSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaveSuccess = false
            }
        }
    }

    private func addBlockedWord() {
        let word = newWord.trimmingCharacters(in: .whitespaces).lowercased()
        if !word.isEmpty && !settings.blockedWords.contains(word) {
            settings.blockedWords.append(word)
            newWord = ""
        }
    }

    private func addException() {
        let word = newException.trimmingCharacters(in: .whitespaces).lowercased()
        if !word.isEmpty && !settings.allowedExceptions.contains(word) {
            settings.allowedExceptions.append(word)
            newException = ""
        }
    }
}

// MARK: - Supporting Views

struct FilterLevelCard: View {
    let level: ContentFilterSettings.FilterLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Image(systemName: level.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : level.color)

                Text(level.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(level.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? level.color : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct QuickSettingToggle: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isOn ? .orange : .gray)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(isOn ? Color.orange.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct TopicFilterChip: View {
    let topic: ContentFilterSettings.BlockedTopic
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                Image(systemName: topic.isBlocked ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.caption)
                Text(topic.name)
                    .font(.caption)
            }
            .foregroundColor(topic.isBlocked ? .red : .green)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(topic.isBlocked ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct BlockedWordChip: View {
    let word: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(word)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(.red)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.1))
        .cornerRadius(16)
    }
}

struct ExceptionChip: View {
    let word: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(word)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(.green)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }
}

struct CustomRuleRow: View {
    let rule: ContentFilterSettings.CustomFilterRule
    let onRemove: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: .constant(rule.isEnabled))
                .labelsHidden()
                .onTapGesture { onToggle() }

            VStack(alignment: .leading, spacing: 4) {
                Text(rule.pattern)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(rule.isEnabled ? .primary : .secondary)
                Text("Action: \(rule.action.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct AddCustomRuleSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var settings: ContentFilterSettings
    @State private var pattern = ""
    @State private var action: ContentFilterSettings.CustomFilterRule.FilterAction = .block

    var body: some View {
        VStack(spacing: 24) {
            Text("Add Custom Rule")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                Text("Pattern to match:")
                    .font(.subheadline)
                TextField("Enter word or phrase...", text: $pattern)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Action when matched:")
                    .font(.subheadline)
                Picker("Action", selection: $action) {
                    ForEach(ContentFilterSettings.CustomFilterRule.FilterAction.allCases, id: \.self) { action in
                        Text(action.displayName).tag(action)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)

                Button("Add Rule") {
                    let rule = ContentFilterSettings.CustomFilterRule(
                        pattern: pattern,
                        action: action
                    )
                    settings.customRules.append(rule)
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.purple)
                .cornerRadius(8)
                .disabled(pattern.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}
