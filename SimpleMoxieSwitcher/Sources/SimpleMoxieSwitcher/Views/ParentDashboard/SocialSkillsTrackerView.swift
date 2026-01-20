import SwiftUI

// MARK: - Models

enum SocialSkillCategory: String, Codable, CaseIterable {
    case communication = "communication"
    case emotionalIntelligence = "emotional"
    case cooperation = "cooperation"
    case empathy = "empathy"
    case selfControl = "selfControl"
    case confidence = "confidence"
    case problemSolving = "problemSolving"
    case manners = "manners"

    var displayName: String {
        switch self {
        case .communication: return "Communication"
        case .emotionalIntelligence: return "Emotional Intelligence"
        case .cooperation: return "Cooperation"
        case .empathy: return "Empathy"
        case .selfControl: return "Self-Control"
        case .confidence: return "Confidence"
        case .problemSolving: return "Problem Solving"
        case .manners: return "Manners & Etiquette"
        }
    }

    var icon: String {
        switch self {
        case .communication: return "bubble.left.and.bubble.right.fill"
        case .emotionalIntelligence: return "heart.text.square.fill"
        case .cooperation: return "person.2.fill"
        case .empathy: return "heart.circle.fill"
        case .selfControl: return "brain.head.profile"
        case .confidence: return "star.fill"
        case .problemSolving: return "puzzlepiece.fill"
        case .manners: return "hand.wave.fill"
        }
    }

    var color: String {
        switch self {
        case .communication: return "#2196F3"
        case .emotionalIntelligence: return "#E91E63"
        case .cooperation: return "#4CAF50"
        case .empathy: return "#9C27B0"
        case .selfControl: return "#FF9800"
        case .confidence: return "#FFD700"
        case .problemSolving: return "#00BCD4"
        case .manners: return "#795548"
        }
    }

    var skills: [String] {
        switch self {
        case .communication:
            return ["Active listening", "Clear expression", "Asking questions", "Eye contact", "Taking turns in conversation", "Using polite words", "Non-verbal cues"]
        case .emotionalIntelligence:
            return ["Identifying feelings", "Expressing emotions", "Managing big feelings", "Understanding others' emotions", "Coping strategies", "Emotional vocabulary"]
        case .cooperation:
            return ["Sharing", "Taking turns", "Following group rules", "Compromising", "Working as a team", "Accepting different roles"]
        case .empathy:
            return ["Recognizing others' feelings", "Showing concern", "Helping others", "Considering perspectives", "Comforting friends", "Being kind"]
        case .selfControl:
            return ["Waiting patiently", "Following rules", "Controlling impulses", "Staying calm", "Accepting no", "Handling frustration"]
        case .confidence:
            return ["Speaking up", "Trying new things", "Accepting mistakes", "Asking for help", "Making decisions", "Standing up for self"]
        case .problemSolving:
            return ["Identifying problems", "Thinking of solutions", "Evaluating options", "Asking for help", "Learning from mistakes", "Flexibility"]
        case .manners:
            return ["Saying please/thank you", "Table manners", "Greeting others", "Respecting personal space", "Being a good guest", "Phone/screen etiquette"]
        }
    }
}

enum SkillLevel: Int, Codable, CaseIterable {
    case emerging = 1
    case developing = 2
    case practicing = 3
    case mastering = 4
    case mastered = 5

    var displayName: String {
        switch self {
        case .emerging: return "Emerging"
        case .developing: return "Developing"
        case .practicing: return "Practicing"
        case .mastering: return "Mastering"
        case .mastered: return "Mastered"
        }
    }

    var color: String {
        switch self {
        case .emerging: return "#FF5722"
        case .developing: return "#FF9800"
        case .practicing: return "#FFC107"
        case .mastering: return "#8BC34A"
        case .mastered: return "#4CAF50"
        }
    }
}

struct SkillProgress: Identifiable, Codable {
    let id: UUID
    let category: SocialSkillCategory
    let skillName: String
    var currentLevel: SkillLevel
    var notes: [SkillNote]
    var observations: [SkillObservation]
    var startedAt: Date
    var lastUpdatedAt: Date

    init(id: UUID = UUID(), category: SocialSkillCategory, skillName: String, currentLevel: SkillLevel = .emerging, notes: [SkillNote] = [], observations: [SkillObservation] = [], startedAt: Date = Date(), lastUpdatedAt: Date = Date()) {
        self.id = id
        self.category = category
        self.skillName = skillName
        self.currentLevel = currentLevel
        self.notes = notes
        self.observations = observations
        self.startedAt = startedAt
        self.lastUpdatedAt = lastUpdatedAt
    }
}

struct SkillNote: Identifiable, Codable {
    let id: UUID
    let content: String
    let createdAt: Date

    init(id: UUID = UUID(), content: String, createdAt: Date = Date()) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }
}

struct SkillObservation: Identifiable, Codable {
    let id: UUID
    let description: String
    let context: String
    let wasPositive: Bool
    let createdAt: Date

    init(id: UUID = UUID(), description: String, context: String, wasPositive: Bool, createdAt: Date = Date()) {
        self.id = id
        self.description = description
        self.context = context
        self.wasPositive = wasPositive
        self.createdAt = createdAt
    }
}

struct SocialSkillsGoal: Identifiable, Codable {
    let id: UUID
    let skillProgressId: UUID
    let targetLevel: SkillLevel
    let targetDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    let createdAt: Date

    init(id: UUID = UUID(), skillProgressId: UUID, targetLevel: SkillLevel, targetDate: Date? = nil, isCompleted: Bool = false, completedAt: Date? = nil, createdAt: Date = Date()) {
        self.id = id
        self.skillProgressId = skillProgressId
        self.targetLevel = targetLevel
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
}

struct SocialSkillsSettings: Codable {
    var skillProgress: [SkillProgress] = []
    var goals: [SocialSkillsGoal] = []
    var focusCategories: [SocialSkillCategory] = []
    var showCompletedGoals: Bool = false
}

// MARK: - Main View

struct SocialSkillsTrackerView: View {
    @State private var settings = SocialSkillsSettings()
    @State private var selectedCategory: SocialSkillCategory?
    @State private var showingAddSkill = false
    @State private var showingSkillDetail: SkillProgress?
    @State private var showingAddGoal = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                overviewSection
                categoriesSection
                goalsSection
                recentProgressSection
            }
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "#667eea"), Color(hex: "#764ba2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear(perform: loadSettings)
        .sheet(isPresented: $showingAddSkill) {
            AddSkillSheet(selectedCategory: selectedCategory, onSave: { skill in
                settings.skillProgress.append(skill)
                saveSettings()
            })
        }
        .sheet(item: $showingSkillDetail) { skill in
            SkillDetailSheet(skill: skill, onUpdate: { updated in
                if let index = settings.skillProgress.firstIndex(where: { $0.id == updated.id }) {
                    settings.skillProgress[index] = updated
                    saveSettings()
                }
            }, onDelete: { skillId in
                settings.skillProgress.removeAll { $0.id == skillId }
                settings.goals.removeAll { $0.skillProgressId == skillId }
                saveSettings()
            })
        }
        .sheet(isPresented: $showingAddGoal) {
            AddSocialSkillsGoalSheet(skills: settings.skillProgress, onSave: { goal in
                settings.goals.append(goal)
                saveSettings()
            })
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Social Skills Tracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Track your child's social development")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: { showingAddGoal = true }) {
                    HStack {
                        Image(systemName: "target")
                        Text("Add Goal")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .foregroundColor(.white)
                }

                Button(action: { showingAddSkill = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Track Skill")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .foregroundColor(.white)
                }
            }
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)

            HStack(spacing: 20) {
                StatBox(title: "Skills Tracked", value: "\(settings.skillProgress.count)", icon: "chart.bar.fill", color: "#2196F3")
                StatBox(title: "Goals Active", value: "\(settings.goals.filter { !$0.isCompleted }.count)", icon: "target", color: "#FF9800")
                StatBox(title: "Goals Completed", value: "\(settings.goals.filter { $0.isCompleted }.count)", icon: "checkmark.circle.fill", color: "#4CAF50")
                StatBox(title: "Categories", value: "\(Set(settings.skillProgress.map { $0.category }).count)/\(SocialSkillCategory.allCases.count)", icon: "square.grid.2x2.fill", color: "#9C27B0")
            }

            // Overall progress by category
            if !settings.skillProgress.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category Progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(SocialSkillCategory.allCases, id: \.self) { category in
                        let categorySkills = settings.skillProgress.filter { $0.category == category }
                        if !categorySkills.isEmpty {
                            let avgLevel = Double(categorySkills.reduce(0) { $0 + $1.currentLevel.rawValue }) / Double(categorySkills.count)
                            CategoryProgressRow(category: category, progress: avgLevel / 5.0, skillCount: categorySkills.count)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Skills by Category")
                    .font(.headline)

                Spacer()

                if selectedCategory != nil {
                    Button("Show All") {
                        selectedCategory = nil
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#667eea"))
                }
            }

            // Category pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SocialSkillCategory.allCases, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color(hex: category.color) : Color.gray.opacity(0.1))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Skills list
            let filteredSkills = selectedCategory == nil ? settings.skillProgress : settings.skillProgress.filter { $0.category == selectedCategory }

            if filteredSkills.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No skills being tracked")
                        .font(.headline)
                    Text("Start tracking a social skill to see progress here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button(action: { showingAddSkill = true }) {
                        Text("Track First Skill")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#667eea"))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 12) {
                    ForEach(filteredSkills) { skill in
                        SkillCard(skill: skill, onTap: { showingSkillDetail = skill })
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Goals")
                    .font(.headline)

                Spacer()

                Toggle("Show Completed", isOn: $settings.showCompletedGoals)
                    .toggleStyle(.switch)
                    .onChange(of: settings.showCompletedGoals) { _ in saveSettings() }
            }

            let filteredGoals = settings.showCompletedGoals ? settings.goals : settings.goals.filter { !$0.isCompleted }

            if filteredGoals.isEmpty {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.secondary)
                    Text("No active goals. Set a goal to work towards!")
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                ForEach(filteredGoals) { goal in
                    if let skill = settings.skillProgress.first(where: { $0.id == goal.skillProgressId }) {
                        GoalRow(goal: goal, skill: skill, onToggleComplete: {
                            if let index = settings.goals.firstIndex(where: { $0.id == goal.id }) {
                                settings.goals[index].isCompleted.toggle()
                                if settings.goals[index].isCompleted {
                                    settings.goals[index].completedAt = Date()
                                } else {
                                    settings.goals[index].completedAt = nil
                                }
                                saveSettings()
                            }
                        }, onDelete: {
                            settings.goals.removeAll { $0.id == goal.id }
                            saveSettings()
                        })
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var recentProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Progress")
                .font(.headline)

            let recentSkills = settings.skillProgress
                .sorted { $0.lastUpdatedAt > $1.lastUpdatedAt }
                .prefix(5)

            if recentSkills.isEmpty {
                Text("No recent updates")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(Array(recentSkills)) { skill in
                    HStack {
                        Image(systemName: skill.category.icon)
                            .foregroundColor(Color(hex: skill.category.color))
                            .frame(width: 30)

                        VStack(alignment: .leading) {
                            Text(skill.skillName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(skill.category.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(skill.currentLevel.displayName)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: skill.currentLevel.color).opacity(0.2))
                            .foregroundColor(Color(hex: skill.currentLevel.color))
                            .cornerRadius(10)

                        Text(skill.lastUpdatedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)

                    if skill.id != recentSkills.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "socialSkillsSettings"),
           let decoded = try? JSONDecoder().decode(SocialSkillsSettings.self, from: data) {
            settings = decoded
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "socialSkillsSettings")
        }
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: color))

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(hex: color).opacity(0.1))
        .cornerRadius(12)
    }
}

struct CategoryProgressRow: View {
    let category: SocialSkillCategory
    let progress: Double
    let skillCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .foregroundColor(Color(hex: category.color))
                .frame(width: 24)

            Text(category.displayName)
                .font(.subheadline)
                .frame(width: 150, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: category.color))
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(skillCount) skills")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
    }
}

struct SkillCard: View {
    let skill: SkillProgress
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: skill.category.icon)
                        .foregroundColor(Color(hex: skill.category.color))

                    Text(skill.skillName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                // Level indicator
                HStack(spacing: 4) {
                    ForEach(SkillLevel.allCases, id: \.self) { level in
                        Circle()
                            .fill(level.rawValue <= skill.currentLevel.rawValue ? Color(hex: skill.currentLevel.color) : Color.gray.opacity(0.2))
                            .frame(width: 12, height: 12)
                    }

                    Spacer()

                    Text(skill.currentLevel.displayName)
                        .font(.caption)
                        .foregroundColor(Color(hex: skill.currentLevel.color))
                }

                HStack {
                    if !skill.observations.isEmpty {
                        Label("\(skill.observations.count) observations", systemImage: "eye")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !skill.notes.isEmpty {
                        Label("\(skill.notes.count) notes", systemImage: "note.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("Updated \(skill.lastUpdatedAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct GoalRow: View {
    let goal: SocialSkillsGoal
    let skill: SkillProgress
    let onToggleComplete: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggleComplete) {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(goal.isCompleted ? Color(hex: "#4CAF50") : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading) {
                Text(skill.skillName)
                    .font(.subheadline)
                    .strikethrough(goal.isCompleted)

                HStack {
                    Text("Target: \(goal.targetLevel.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let targetDate = goal.targetDate {
                        Text("by \(targetDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Current vs target
            HStack(spacing: 4) {
                Text(skill.currentLevel.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: skill.currentLevel.color).opacity(0.2))
                    .cornerRadius(8)

                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(goal.targetLevel.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: goal.targetLevel.color).opacity(0.2))
                    .cornerRadius(8)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(goal.isCompleted ? Color.green.opacity(0.05) : Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Add Skill Sheet

struct AddSkillSheet: View {
    let selectedCategory: SocialSkillCategory?
    let onSave: (SkillProgress) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var category: SocialSkillCategory = .communication
    @State private var selectedSkill: String?
    @State private var customSkillName = ""
    @State private var initialLevel: SkillLevel = .emerging

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Track New Skill")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                            ForEach(SocialSkillCategory.allCases, id: \.self) { cat in
                                Button(action: {
                                    category = cat
                                    selectedSkill = nil
                                }) {
                                    HStack {
                                        Image(systemName: cat.icon)
                                        Text(cat.displayName)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(category == cat ? Color(hex: cat.color) : Color.gray.opacity(0.1))
                                    .foregroundColor(category == cat ? .white : .primary)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Skill selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skill")
                            .font(.headline)

                        ForEach(category.skills, id: \.self) { skill in
                            Button(action: { selectedSkill = skill }) {
                                HStack {
                                    Image(systemName: selectedSkill == skill ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedSkill == skill ? Color(hex: category.color) : .secondary)
                                    Text(skill)
                                    Spacer()
                                }
                                .padding()
                                .background(selectedSkill == skill ? Color(hex: category.color).opacity(0.1) : Color.gray.opacity(0.05))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }

                        Divider()

                        Text("Or add custom skill:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("Custom skill name", text: $customSkillName)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: customSkillName) { newValue in
                                if !newValue.isEmpty {
                                    selectedSkill = nil
                                }
                            }
                    }

                    // Initial level
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Level")
                            .font(.headline)

                        HStack(spacing: 8) {
                            ForEach(SkillLevel.allCases, id: \.self) { level in
                                Button(action: { initialLevel = level }) {
                                    Text(level.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(initialLevel == level ? Color(hex: level.color) : Color.gray.opacity(0.1))
                                        .foregroundColor(initialLevel == level ? .white : .primary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Start Tracking") {
                    let skillName = customSkillName.isEmpty ? (selectedSkill ?? "") : customSkillName
                    guard !skillName.isEmpty else { return }

                    let skill = SkillProgress(
                        category: category,
                        skillName: skillName,
                        currentLevel: initialLevel
                    )
                    onSave(skill)
                    dismiss()
                }
                .disabled(selectedSkill == nil && customSkillName.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 500)
        .onAppear {
            if let cat = selectedCategory {
                category = cat
            }
        }
    }
}

// MARK: - Skill Detail Sheet

struct SkillDetailSheet: View {
    let skill: SkillProgress
    let onUpdate: (SkillProgress) -> Void
    let onDelete: (UUID) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var currentSkill: SkillProgress
    @State private var newNote = ""
    @State private var newObservation = ""
    @State private var observationContext = ""
    @State private var wasPositive = true

    init(skill: SkillProgress, onUpdate: @escaping (SkillProgress) -> Void, onDelete: @escaping (UUID) -> Void) {
        self.skill = skill
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _currentSkill = State(initialValue: skill)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: currentSkill.category.icon)
                            .foregroundColor(Color(hex: currentSkill.category.color))
                        Text(currentSkill.skillName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text(currentSkill.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Level adjustment
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Level")
                            .font(.headline)

                        HStack(spacing: 8) {
                            ForEach(SkillLevel.allCases, id: \.self) { level in
                                Button(action: {
                                    currentSkill.currentLevel = level
                                    currentSkill.lastUpdatedAt = Date()
                                    onUpdate(currentSkill)
                                }) {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(level.rawValue <= currentSkill.currentLevel.rawValue ? Color(hex: level.color) : Color.gray.opacity(0.2))
                                            .frame(width: 24, height: 24)
                                        Text(level.displayName)
                                            .font(.caption2)
                                    }
                                    .padding(8)
                                    .background(currentSkill.currentLevel == level ? Color(hex: level.color).opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text("Tracking since \(currentSkill.startedAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Add observation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Observation")
                            .font(.headline)

                        TextField("What did you observe?", text: $newObservation)
                            .textFieldStyle(.roundedBorder)

                        TextField("Context (where/when)", text: $observationContext)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            Picker("Type", selection: $wasPositive) {
                                Text("Positive").tag(true)
                                Text("Needs Work").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)

                            Spacer()

                            Button(action: {
                                guard !newObservation.isEmpty else { return }
                                let observation = SkillObservation(
                                    description: newObservation,
                                    context: observationContext,
                                    wasPositive: wasPositive
                                )
                                currentSkill.observations.insert(observation, at: 0)
                                currentSkill.lastUpdatedAt = Date()
                                onUpdate(currentSkill)
                                newObservation = ""
                                observationContext = ""
                            }) {
                                Text("Add Observation")
                            }
                            .disabled(newObservation.isEmpty)
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    // Observations list
                    if !currentSkill.observations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Observations (\(currentSkill.observations.count))")
                                .font(.headline)

                            ForEach(currentSkill.observations) { observation in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: observation.wasPositive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .foregroundColor(observation.wasPositive ? Color(hex: "#4CAF50") : Color(hex: "#FF9800"))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(observation.description)
                                            .font(.subheadline)
                                        if !observation.context.isEmpty {
                                            Text(observation.context)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Text(observation.createdAt, style: .relative)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Button(action: {
                                        currentSkill.observations.removeAll { $0.id == observation.id }
                                        onUpdate(currentSkill)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding()
                                .background(observation.wasPositive ? Color.green.opacity(0.05) : Color.orange.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }

                    Divider()

                    // Add note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)

                        HStack {
                            TextField("Add a note...", text: $newNote)
                                .textFieldStyle(.roundedBorder)

                            Button(action: {
                                guard !newNote.isEmpty else { return }
                                let note = SkillNote(content: newNote)
                                currentSkill.notes.insert(note, at: 0)
                                currentSkill.lastUpdatedAt = Date()
                                onUpdate(currentSkill)
                                newNote = ""
                            }) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(newNote.isEmpty)
                        }

                        ForEach(currentSkill.notes) { note in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(note.content)
                                        .font(.subheadline)
                                    Text(note.createdAt, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: {
                                    currentSkill.notes.removeAll { $0.id == note.id }
                                    onUpdate(currentSkill)
                                }) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Button(role: .destructive, action: {
                    onDelete(skill.id)
                    dismiss()
                }) {
                    Label("Delete Skill", systemImage: "trash")
                }

                Spacer()

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 600)
    }
}

// MARK: - Add Social Skills Goal Sheet

struct AddSocialSkillsGoalSheet: View {
    let skills: [SkillProgress]
    let onSave: (SocialSkillsGoal) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var selectedSkillId: UUID?
    @State private var targetLevel: SkillLevel = .practicing
    @State private var hasTargetDate = false
    @State private var targetDate = Date().addingTimeInterval(30 * 24 * 60 * 60)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Set a Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Skill selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Skill")
                            .font(.headline)

                        if skills.isEmpty {
                            Text("Start tracking a skill first before setting goals.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(skills) { skill in
                                Button(action: { selectedSkillId = skill.id }) {
                                    HStack {
                                        Image(systemName: selectedSkillId == skill.id ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedSkillId == skill.id ? Color(hex: skill.category.color) : .secondary)

                                        Image(systemName: skill.category.icon)
                                            .foregroundColor(Color(hex: skill.category.color))

                                        Text(skill.skillName)

                                        Spacer()

                                        Text("Currently: \(skill.currentLevel.displayName)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(selectedSkillId == skill.id ? Color(hex: skill.category.color).opacity(0.1) : Color.gray.opacity(0.05))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Target level
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Level")
                            .font(.headline)

                        HStack(spacing: 8) {
                            ForEach(SkillLevel.allCases, id: \.self) { level in
                                Button(action: { targetLevel = level }) {
                                    Text(level.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(targetLevel == level ? Color(hex: level.color) : Color.gray.opacity(0.1))
                                        .foregroundColor(targetLevel == level ? .white : .primary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Target date
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Set target date", isOn: $hasTargetDate)

                        if hasTargetDate {
                            DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                        }
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Create Goal") {
                    guard let skillId = selectedSkillId else { return }
                    let goal = SocialSkillsGoal(
                        skillProgressId: skillId,
                        targetLevel: targetLevel,
                        targetDate: hasTargetDate ? targetDate : nil
                    )
                    onSave(goal)
                    dismiss()
                }
                .disabled(selectedSkillId == nil)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    SocialSkillsTrackerView()
        .frame(width: 900, height: 700)
}
