import SwiftUI

// MARK: - Age Content Level
enum AgeContentLevel: String, Codable, CaseIterable {
    case toddler = "toddler"       // 2-4 years
    case preschool = "preschool"   // 4-6 years
    case earlyElementary = "early_elementary" // 6-8 years
    case lateElementary = "late_elementary"   // 8-10 years
    case preteen = "preteen"       // 10-12 years

    var displayName: String {
        switch self {
        case .toddler: return "Toddler (2-4)"
        case .preschool: return "Preschool (4-6)"
        case .earlyElementary: return "Early Elementary (6-8)"
        case .lateElementary: return "Late Elementary (8-10)"
        case .preteen: return "Pre-Teen (10-12)"
        }
    }

    var description: String {
        switch self {
        case .toddler:
            return "Simple language, basic concepts, nursery rhymes, colors, shapes, animals"
        case .preschool:
            return "Expanded vocabulary, simple stories, basic counting, letters, simple science"
        case .earlyElementary:
            return "Chapter books level, basic math, beginning science, geography basics"
        case .lateElementary:
            return "Complex topics, history, deeper science, more nuanced conversations"
        case .preteen:
            return "Advanced topics, current events (filtered), complex problem-solving"
        }
    }

    var icon: String {
        switch self {
        case .toddler: return "figure.child"
        case .preschool: return "figure.child.circle"
        case .earlyElementary: return "book.closed.fill"
        case .lateElementary: return "graduationcap.fill"
        case .preteen: return "person.fill"
        }
    }

    var color: Color {
        switch self {
        case .toddler: return .pink
        case .preschool: return .orange
        case .earlyElementary: return .yellow
        case .lateElementary: return .green
        case .preteen: return .blue
        }
    }

    var features: [String] {
        switch self {
        case .toddler:
            return ["Simple words", "Lots of repetition", "Animated responses", "No complex topics"]
        case .preschool:
            return ["Simple sentences", "Basic stories", "ABC & counting", "Gentle corrections"]
        case .earlyElementary:
            return ["Full sentences", "Chapter-book level", "Basic facts", "Educational games"]
        case .lateElementary:
            return ["Complex explanations", "Research questions", "Math help", "Science topics"]
        case .preteen:
            return ["Nuanced discussions", "Critical thinking", "Current events", "Advanced learning"]
        }
    }
}

// MARK: - Age Content Settings
struct AgeContentSettings: Codable {
    var contentLevel: AgeContentLevel = .earlyElementary
    var autoDetectAge: Bool = true
    var vocabularyLevel: VocabularyLevel = .ageAppropriate
    var topicsAllowed: [TopicCategory] = TopicCategory.allCases
    var conversationSpeed: ConversationSpeed = .normal

    enum VocabularyLevel: String, Codable, CaseIterable {
        case simple = "simple"
        case ageAppropriate = "age_appropriate"
        case advanced = "advanced"

        var displayName: String {
            switch self {
            case .simple: return "Simple"
            case .ageAppropriate: return "Age-Appropriate"
            case .advanced: return "Advanced"
            }
        }
    }

    enum TopicCategory: String, Codable, CaseIterable {
        case animals = "animals"
        case science = "science"
        case space = "space"
        case history = "history"
        case art = "art"
        case music = "music"
        case sports = "sports"
        case nature = "nature"
        case technology = "technology"

        var displayName: String { rawValue.capitalized }
        var icon: String {
            switch self {
            case .animals: return "pawprint.fill"
            case .science: return "atom"
            case .space: return "moon.stars.fill"
            case .history: return "building.columns.fill"
            case .art: return "paintpalette.fill"
            case .music: return "music.note"
            case .sports: return "figure.run"
            case .nature: return "leaf.fill"
            case .technology: return "cpu.fill"
            }
        }
    }

    enum ConversationSpeed: String, Codable, CaseIterable {
        case slow = "slow"
        case normal = "normal"
        case fast = "fast"

        var displayName: String { rawValue.capitalized }
    }
}

// MARK: - Age Content Settings View
struct AgeContentSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var settings = AgeContentSettings()
    @State private var showSaveSuccess = false

    private let settingsKey = "moxie_age_content_settings"

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
                        contentLevelSection
                        vocabularySection
                        topicCategoriesSection
                        conversationSpeedSection
                        previewSection
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear { loadSettings() }
        .overlay(saveSuccessOverlay)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("Age-Appropriate Content")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "9D4EDD"))
                }
                Text("Customize content complexity for your child's age")
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

    // MARK: - Content Level Section

    private var contentLevelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Content Level", systemImage: "person.crop.circle.fill")
                    .font(.headline)

                Spacer()

                Toggle(isOn: $settings.autoDetectAge) {
                    Text("Auto-detect from profile")
                        .font(.caption)
                }
                .toggleStyle(.switch)
            }

            ForEach(AgeContentLevel.allCases, id: \.self) { level in
                ContentLevelCard(
                    level: level,
                    isSelected: settings.contentLevel == level,
                    onSelect: { settings.contentLevel = level }
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Vocabulary Section

    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Vocabulary Complexity", systemImage: "textformat")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(AgeContentSettings.VocabularyLevel.allCases, id: \.self) { level in
                    VocabularyButton(
                        level: level,
                        isSelected: settings.vocabularyLevel == level,
                        onSelect: { settings.vocabularyLevel = level }
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Topic Categories Section

    private var topicCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Allowed Topics", systemImage: "tag.fill")
                .font(.headline)

            Text("Select which topics Moxie can discuss with your child")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AgeContentSettings.TopicCategory.allCases, id: \.self) { category in
                    TopicToggleCard(
                        category: category,
                        isEnabled: settings.topicsAllowed.contains(category),
                        onToggle: {
                            if settings.topicsAllowed.contains(category) {
                                settings.topicsAllowed.removeAll { $0 == category }
                            } else {
                                settings.topicsAllowed.append(category)
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

    // MARK: - Conversation Speed Section

    private var conversationSpeedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Response Speed", systemImage: "speedometer")
                .font(.headline)

            Text("How quickly Moxie speaks (for attention span)")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ForEach(AgeContentSettings.ConversationSpeed.allCases, id: \.self) { speed in
                    SpeedButton(
                        speed: speed,
                        isSelected: settings.conversationSpeed == speed,
                        onSelect: { settings.conversationSpeed = speed }
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Example Response Preview", systemImage: "bubble.left.fill")
                .font(.headline)

            Text("Here's how Moxie would explain \"Why is the sky blue?\" at your selected level:")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(previewResponse)
                .font(.subheadline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private var previewResponse: String {
        switch settings.contentLevel {
        case .toddler:
            return "The sky is blue like your blue crayon! It's so pretty! 💙 Blue blue sky!"
        case .preschool:
            return "The sky looks blue because of the sun's light! The sun sends light and it bounces around making the sky look blue. Isn't that cool?"
        case .earlyElementary:
            return "The sky is blue because sunlight has all the colors in it, like a rainbow! When sunlight hits the air, the blue color bounces around more than other colors, so that's what we see!"
        case .lateElementary:
            return "The sky appears blue because of how light interacts with our atmosphere. Sunlight contains all colors, but blue light has a shorter wavelength and scatters more when it hits gas molecules in the air. This is called Rayleigh scattering!"
        case .preteen:
            return "The blue color of the sky is due to Rayleigh scattering. When sunlight enters Earth's atmosphere, shorter wavelengths (blue/violet) scatter more than longer wavelengths (red/orange). Our eyes are more sensitive to blue, so that's the color we perceive. Fun fact: sunsets are red because light travels through more atmosphere at that angle!"
        }
    }

    // MARK: - Save Success Overlay

    private var saveSuccessOverlay: some View {
        Group {
            if showSaveSuccess {
                VStack {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Age settings saved")
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
           let decoded = try? JSONDecoder().decode(AgeContentSettings.self, from: data) {
            settings = decoded
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
}

// MARK: - Supporting Views

struct ContentLevelCard: View {
    let level: AgeContentLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: level.icon)
                    .font(.title2)
                    .foregroundColor(level.color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(level.features.prefix(2), id: \.self) { feature in
                        Text("• \(feature)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? level.color : .gray.opacity(0.3))
            }
            .padding()
            .background(isSelected ? level.color.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? level.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct VocabularyButton: View {
    let level: AgeContentSettings.VocabularyLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(level.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.green : Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct TopicToggleCard: View {
    let category: AgeContentSettings.TopicCategory
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isEnabled ? .white : .gray)

                Text(category.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isEnabled ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.purple : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct SpeedButton: View {
    let speed: AgeContentSettings.ConversationSpeed
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Image(systemName: speedIcon)
                    .font(.title2)
                Text(speed.displayName)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    var speedIcon: String {
        switch speed {
        case .slow: return "tortoise.fill"
        case .normal: return "figure.walk"
        case .fast: return "hare.fill"
        }
    }
}
