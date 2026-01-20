import SwiftUI

// MARK: - Conversation Starter
struct ConversationStarter: Identifiable, Codable {
    let id: UUID
    let prompt: String
    let category: StarterCategory
    let ageRange: AgeRange
    let tags: [String]
    var isFavorite: Bool
    var timesUsed: Int
    var isCustom: Bool

    enum StarterCategory: String, Codable, CaseIterable {
        case feelings = "Feelings & Emotions"
        case learning = "Learning & Curiosity"
        case creativity = "Creativity & Imagination"
        case social = "Friends & Family"
        case daily = "Daily Life"
        case fun = "Fun & Games"
        case growth = "Personal Growth"

        var icon: String {
            switch self {
            case .feelings: return "heart.fill"
            case .learning: return "lightbulb.fill"
            case .creativity: return "paintbrush.fill"
            case .social: return "person.2.fill"
            case .daily: return "sun.max.fill"
            case .fun: return "gamecontroller.fill"
            case .growth: return "leaf.fill"
            }
        }

        var color: Color {
            switch self {
            case .feelings: return .pink
            case .learning: return .yellow
            case .creativity: return .purple
            case .social: return .blue
            case .daily: return .orange
            case .fun: return .green
            case .growth: return .mint
            }
        }
    }

    enum AgeRange: String, Codable, CaseIterable {
        case toddler = "2-4"
        case preschool = "4-6"
        case elementary = "6-10"
        case preteen = "10-12"
        case all = "All Ages"
    }

    init(id: UUID = UUID(), prompt: String, category: StarterCategory, ageRange: AgeRange = .all, tags: [String] = [], isFavorite: Bool = false, timesUsed: Int = 0, isCustom: Bool = false) {
        self.id = id
        self.prompt = prompt
        self.category = category
        self.ageRange = ageRange
        self.tags = tags
        self.isFavorite = isFavorite
        self.timesUsed = timesUsed
        self.isCustom = isCustom
    }
}

// MARK: - Conversation Starters View
struct ConversationStartersView: View {
    @Environment(\.dismiss) var dismiss
    @State private var starters: [ConversationStarter] = []
    @State private var selectedCategory: ConversationStarter.StarterCategory?
    @State private var searchText = ""
    @State private var showAddStarter = false
    @State private var showOnlyFavorites = false

    private let settingsKey = "moxie_conversation_starters"

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

                VStack(spacing: 16) {
                    // Search and Filter Bar
                    searchAndFilterBar
                        .padding(.horizontal)
                        .padding(.top)

                    // Category Pills
                    categoryPillsSection
                        .padding(.horizontal)

                    // Starters Grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(filteredStarters) { starter in
                                StarterCard(
                                    starter: starter,
                                    onToggleFavorite: { toggleFavorite(starter) },
                                    onUse: { useStarter(starter) },
                                    onDelete: starter.isCustom ? { deleteStarter(starter) } : nil
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear { loadStarters() }
        .sheet(isPresented: $showAddStarter) {
            AddStarterSheet(starters: $starters)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "text.bubble.fill")
                        .font(.title)
                        .foregroundColor(.cyan)
                    Text("Conversation Starters")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "9D4EDD"))
                }
                Text("Prompts to spark meaningful conversations with Moxie")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { showAddStarter = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Custom")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.cyan)
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

    // MARK: - Search and Filter Bar

    private var searchAndFilterBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search prompts...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            Toggle(isOn: $showOnlyFavorites) {
                HStack(spacing: 4) {
                    Image(systemName: showOnlyFavorites ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                    Text("Favorites")
                        .font(.subheadline)
                }
            }
            .toggleStyle(.button)
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(showOnlyFavorites ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(8)

            Text("\(filteredStarters.count) prompts")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Category Pills Section

    private var categoryPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryPill(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    color: .gray,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(ConversationStarter.StarterCategory.allCases, id: \.self) { category in
                    CategoryPill(
                        title: category.rawValue,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }

    private var filteredStarters: [ConversationStarter] {
        var filtered = starters

        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        if showOnlyFavorites {
            filtered = filtered.filter { $0.isFavorite }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter { $0.prompt.localizedCaseInsensitiveContains(searchText) }
        }

        return filtered.sorted { $0.isFavorite && !$1.isFavorite }
    }

    // MARK: - Helpers

    private func loadStarters() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode([ConversationStarter].self, from: data) {
            starters = decoded
        } else {
            starters = defaultStarters
            saveStarters()
        }
    }

    private func saveStarters() {
        if let encoded = try? JSONEncoder().encode(starters) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }

    private func toggleFavorite(_ starter: ConversationStarter) {
        if let index = starters.firstIndex(where: { $0.id == starter.id }) {
            starters[index].isFavorite.toggle()
            saveStarters()
        }
    }

    private func useStarter(_ starter: ConversationStarter) {
        if let index = starters.firstIndex(where: { $0.id == starter.id }) {
            starters[index].timesUsed += 1
            saveStarters()
        }
        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(starter.prompt, forType: .string)
    }

    private func deleteStarter(_ starter: ConversationStarter) {
        starters.removeAll { $0.id == starter.id }
        saveStarters()
    }

    // MARK: - Default Starters

    private var defaultStarters: [ConversationStarter] {
        [
            // Feelings & Emotions
            ConversationStarter(prompt: "How are you feeling today? Tell me about your day!", category: .feelings, tags: ["emotions", "check-in"]),
            ConversationStarter(prompt: "What made you smile today?", category: .feelings, tags: ["positive", "gratitude"]),
            ConversationStarter(prompt: "Is there anything that's worrying you? I'm here to listen.", category: .feelings, tags: ["support", "worries"]),
            ConversationStarter(prompt: "What's something that made you feel proud recently?", category: .feelings, tags: ["confidence", "achievement"]),
            ConversationStarter(prompt: "Tell me about a time you felt really brave.", category: .feelings, tags: ["courage", "growth"]),

            // Learning & Curiosity
            ConversationStarter(prompt: "What's something new you learned today?", category: .learning, tags: ["education", "curiosity"]),
            ConversationStarter(prompt: "If you could learn any superpower, what would it be?", category: .learning, tags: ["imagination", "fun"]),
            ConversationStarter(prompt: "What's a question you've always wanted to ask?", category: .learning, tags: ["curiosity", "wonder"]),
            ConversationStarter(prompt: "Can you teach me something you know really well?", category: .learning, tags: ["teaching", "confidence"]),
            ConversationStarter(prompt: "What do you want to be when you grow up and why?", category: .learning, tags: ["dreams", "future"]),

            // Creativity & Imagination
            ConversationStarter(prompt: "Let's make up a story together! You start with 'Once upon a time...'", category: .creativity, tags: ["storytelling", "fun"]),
            ConversationStarter(prompt: "If you could create any invention, what would it do?", category: .creativity, tags: ["invention", "imagination"]),
            ConversationStarter(prompt: "Describe your dream treehouse!", category: .creativity, tags: ["imagination", "play"]),
            ConversationStarter(prompt: "If animals could talk, which one would be your best friend?", category: .creativity, tags: ["animals", "imagination"]),
            ConversationStarter(prompt: "What would you do if you found a magic wand?", category: .creativity, tags: ["magic", "fantasy"]),

            // Friends & Family
            ConversationStarter(prompt: "Tell me about your best friend. What do you like doing together?", category: .social, tags: ["friendship", "relationships"]),
            ConversationStarter(prompt: "What's your favorite thing to do with your family?", category: .social, tags: ["family", "activities"]),
            ConversationStarter(prompt: "How do you make someone feel better when they're sad?", category: .social, tags: ["empathy", "kindness"]),
            ConversationStarter(prompt: "What makes someone a good friend?", category: .social, tags: ["values", "friendship"]),
            ConversationStarter(prompt: "Is there someone at school you'd like to be better friends with?", category: .social, tags: ["school", "relationships"]),

            // Daily Life
            ConversationStarter(prompt: "What's your favorite part of the day?", category: .daily, tags: ["routine", "preferences"]),
            ConversationStarter(prompt: "What did you eat for breakfast/lunch/dinner?", category: .daily, tags: ["food", "routine"]),
            ConversationStarter(prompt: "What's your favorite thing about your room?", category: .daily, tags: ["home", "comfort"]),
            ConversationStarter(prompt: "If you could change one rule at home, what would it be?", category: .daily, tags: ["rules", "opinions"]),
            ConversationStarter(prompt: "What's something you're looking forward to this week?", category: .daily, tags: ["anticipation", "planning"]),

            // Fun & Games
            ConversationStarter(prompt: "Let's play a guessing game! Think of an animal and I'll try to guess it.", category: .fun, tags: ["game", "animals"]),
            ConversationStarter(prompt: "What's your favorite game to play? Can you teach me?", category: .fun, tags: ["games", "teaching"]),
            ConversationStarter(prompt: "If you could have any pet, real or imaginary, what would it be?", category: .fun, tags: ["pets", "imagination"]),
            ConversationStarter(prompt: "What's the silliest thing you can think of?", category: .fun, tags: ["humor", "silly"]),
            ConversationStarter(prompt: "Would you rather fly or be invisible? Why?", category: .fun, tags: ["hypothetical", "fun"]),

            // Personal Growth
            ConversationStarter(prompt: "What's something you'd like to get better at?", category: .growth, tags: ["goals", "improvement"]),
            ConversationStarter(prompt: "Tell me about a mistake you learned from.", category: .growth, tags: ["learning", "resilience"]),
            ConversationStarter(prompt: "What's one kind thing you could do for someone today?", category: .growth, tags: ["kindness", "action"]),
            ConversationStarter(prompt: "What's something hard that you accomplished?", category: .growth, tags: ["achievement", "perseverance"]),
            ConversationStarter(prompt: "How do you calm yourself down when you feel upset?", category: .growth, tags: ["coping", "emotions"])
        ]
    }
}

// MARK: - Supporting Views

struct CategoryPill: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.1))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct StarterCard: View {
    let starter: ConversationStarter
    let onToggleFavorite: () -> Void
    let onUse: () -> Void
    let onDelete: (() -> Void)?

    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: starter.category.icon)
                    .foregroundColor(starter.category.color)
                Text(starter.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if starter.isCustom {
                    Text("Custom")
                        .font(.caption2)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(4)
                }
                Button(action: onToggleFavorite) {
                    Image(systemName: starter.isFavorite ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
                .buttonStyle(.plain)
            }

            // Prompt
            Text("\"\(starter.prompt)\"")
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(3)
                .italic()

            // Tags
            if !starter.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(starter.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Actions
            HStack {
                if starter.timesUsed > 0 {
                    Text("Used \(starter.timesUsed)x")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()

                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: {
                    onUse()
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopied = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        Text(showCopied ? "Copied!" : "Copy")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(showCopied ? Color.green : starter.category.color)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(height: 180)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AddStarterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var starters: [ConversationStarter]

    @State private var prompt = ""
    @State private var selectedCategory: ConversationStarter.StarterCategory = .feelings
    @State private var tagsText = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("Add Custom Starter")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                Text("Conversation Prompt:")
                    .font(.subheadline)
                TextEditor(text: $prompt)
                    .font(.body)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Category:")
                    .font(.subheadline)
                Picker("Category", selection: $selectedCategory) {
                    ForEach(ConversationStarter.StarterCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Tags (comma separated):")
                    .font(.subheadline)
                TextField("e.g., emotions, fun, learning", text: $tagsText)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)

                Button("Add Starter") {
                    addStarter()
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.cyan)
                .cornerRadius(8)
                .disabled(prompt.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 450)
    }

    private func addStarter() {
        let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let starter = ConversationStarter(
            prompt: prompt,
            category: selectedCategory,
            tags: tags,
            isCustom: true
        )
        starters.append(starter)

        // Save
        if let encoded = try? JSONEncoder().encode(starters) {
            UserDefaults.standard.set(encoded, forKey: "moxie_conversation_starters")
        }
    }
}
