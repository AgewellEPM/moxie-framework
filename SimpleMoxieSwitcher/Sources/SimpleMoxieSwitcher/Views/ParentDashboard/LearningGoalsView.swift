import SwiftUI

// MARK: - Models

enum LearningSubject: String, Codable, CaseIterable {
    case reading = "reading"
    case math = "math"
    case science = "science"
    case socialStudies = "socialStudies"
    case language = "language"
    case arts = "arts"
    case music = "music"
    case physicalEd = "physicalEd"
    case lifeskills = "lifeskills"
    case technology = "technology"

    var displayName: String {
        switch self {
        case .reading: return "Reading"
        case .math: return "Math"
        case .science: return "Science"
        case .socialStudies: return "Social Studies"
        case .language: return "Language"
        case .arts: return "Arts"
        case .music: return "Music"
        case .physicalEd: return "Physical Education"
        case .lifeskills: return "Life Skills"
        case .technology: return "Technology"
        }
    }

    var icon: String {
        switch self {
        case .reading: return "book.fill"
        case .math: return "number"
        case .science: return "atom"
        case .socialStudies: return "globe.americas.fill"
        case .language: return "character.bubble.fill"
        case .arts: return "paintpalette.fill"
        case .music: return "music.note"
        case .physicalEd: return "figure.run"
        case .lifeskills: return "heart.fill"
        case .technology: return "laptopcomputer"
        }
    }

    var color: String {
        switch self {
        case .reading: return "#9C27B0"
        case .math: return "#2196F3"
        case .science: return "#4CAF50"
        case .socialStudies: return "#FF9800"
        case .language: return "#E91E63"
        case .arts: return "#F44336"
        case .music: return "#00BCD4"
        case .physicalEd: return "#FF5722"
        case .lifeskills: return "#795548"
        case .technology: return "#607D8B"
        }
    }
}

enum GoalPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var color: String {
        switch self {
        case .low: return "#4CAF50"
        case .medium: return "#FF9800"
        case .high: return "#F44336"
        }
    }
}

enum GoalTimeframe: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
}

struct ParentLearningGoal: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var subject: LearningSubject
    var priority: GoalPriority
    var timeframe: GoalTimeframe
    var targetValue: Int
    var currentValue: Int
    var unit: String
    var startDate: Date
    var targetDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var milestones: [GoalMilestone]
    var notes: [GoalNote]
    let createdAt: Date

    init(id: UUID = UUID(), title: String, description: String = "", subject: LearningSubject, priority: GoalPriority = .medium, timeframe: GoalTimeframe = .weekly, targetValue: Int = 1, currentValue: Int = 0, unit: String = "times", startDate: Date = Date(), targetDate: Date? = nil, isCompleted: Bool = false, completedAt: Date? = nil, milestones: [GoalMilestone] = [], notes: [GoalNote] = [], createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.subject = subject
        self.priority = priority
        self.timeframe = timeframe
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.startDate = startDate
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.milestones = milestones
        self.notes = notes
        self.createdAt = createdAt
    }

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentValue) / Double(targetValue), 1.0)
    }
}

struct GoalMilestone: Identifiable, Codable {
    let id: UUID
    var title: String
    var targetValue: Int
    var isCompleted: Bool
    var completedAt: Date?

    init(id: UUID = UUID(), title: String, targetValue: Int, isCompleted: Bool = false, completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.targetValue = targetValue
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

struct GoalNote: Identifiable, Codable {
    let id: UUID
    let content: String
    let createdAt: Date

    init(id: UUID = UUID(), content: String, createdAt: Date = Date()) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }
}

struct LearningGoalsSettings: Codable {
    var goals: [ParentLearningGoal] = []
    var focusSubjects: [LearningSubject] = []
    var showCompletedGoals: Bool = false
    var defaultTimeframe: GoalTimeframe = .weekly
}

// MARK: - Main View

struct LearningGoalsView: View {
    @State private var settings = LearningGoalsSettings()
    @State private var selectedSubject: LearningSubject?
    @State private var selectedPriority: GoalPriority?
    @State private var showingAddGoal = false
    @State private var showingGoalDetail: ParentLearningGoal?
    @State private var searchText = ""

    var filteredGoals: [ParentLearningGoal] {
        var goals = settings.goals

        if !settings.showCompletedGoals {
            goals = goals.filter { !$0.isCompleted }
        }

        if let subject = selectedSubject {
            goals = goals.filter { $0.subject == subject }
        }

        if let priority = selectedPriority {
            goals = goals.filter { $0.priority == priority }
        }

        if !searchText.isEmpty {
            goals = goals.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return goals.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                overviewSection
                quickActionsSection
                goalsListSection
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
        .sheet(isPresented: $showingAddGoal) {
            AddGoalSheet(defaultTimeframe: settings.defaultTimeframe, onSave: { goal in
                settings.goals.append(goal)
                saveSettings()
            })
        }
        .sheet(item: $showingGoalDetail) { goal in
            GoalDetailSheet(goal: goal, onUpdate: { updated in
                if let index = settings.goals.firstIndex(where: { $0.id == updated.id }) {
                    settings.goals[index] = updated
                    saveSettings()
                }
            }, onDelete: { goalId in
                settings.goals.removeAll { $0.id == goalId }
                saveSettings()
            })
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Learning Goals")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Set and track educational milestones")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Button(action: { showingAddGoal = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("New Goal")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
                .foregroundColor(.white)
            }
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)

            HStack(spacing: 20) {
                GoalStatBox(title: "Active Goals", value: "\(settings.goals.filter { !$0.isCompleted }.count)", icon: "target", color: "#2196F3")

                GoalStatBox(title: "Completed", value: "\(settings.goals.filter { $0.isCompleted }.count)", icon: "checkmark.circle.fill", color: "#4CAF50")

                GoalStatBox(title: "High Priority", value: "\(settings.goals.filter { $0.priority == .high && !$0.isCompleted }.count)", icon: "exclamationmark.triangle.fill", color: "#F44336")

                GoalStatBox(title: "Subjects", value: "\(Set(settings.goals.map { $0.subject }).count)", icon: "square.grid.2x2.fill", color: "#9C27B0")
            }

            // Progress by subject
            if !settings.goals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Progress by Subject")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    let subjectsWithGoals = Set(settings.goals.map { $0.subject })
                    ForEach(Array(subjectsWithGoals), id: \.self) { subject in
                        let subjectGoals = settings.goals.filter { $0.subject == subject && !$0.isCompleted }
                        if !subjectGoals.isEmpty {
                            let avgProgress = subjectGoals.reduce(0.0) { $0 + $1.progress } / Double(subjectGoals.count)
                            SubjectProgressRow(subject: subject, progress: avgProgress, goalCount: subjectGoals.count)
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

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                // Quick goal templates
                QuickGoalButton(title: "Read 5 Books", subject: .reading, onTap: {
                    let goal = ParentLearningGoal(title: "Read 5 Books", description: "Complete 5 books this month", subject: .reading, timeframe: .monthly, targetValue: 5, unit: "books")
                    settings.goals.append(goal)
                    saveSettings()
                })

                QuickGoalButton(title: "Math Practice", subject: .math, onTap: {
                    let goal = ParentLearningGoal(title: "Daily Math Practice", description: "Practice math problems every day", subject: .math, timeframe: .daily, targetValue: 10, unit: "problems")
                    settings.goals.append(goal)
                    saveSettings()
                })

                QuickGoalButton(title: "Learn New Words", subject: .language, onTap: {
                    let goal = ParentLearningGoal(title: "Learn 10 New Words", description: "Expand vocabulary with new words", subject: .language, timeframe: .weekly, targetValue: 10, unit: "words")
                    settings.goals.append(goal)
                    saveSettings()
                })

                QuickGoalButton(title: "Science Project", subject: .science, onTap: {
                    let goal = ParentLearningGoal(title: "Complete Science Project", description: "Finish a science experiment", subject: .science, timeframe: .monthly, targetValue: 1, unit: "project")
                    settings.goals.append(goal)
                    saveSettings()
                })
            }

            // Settings row
            HStack {
                Toggle("Show Completed Goals", isOn: $settings.showCompletedGoals)
                    .onChange(of: settings.showCompletedGoals) { _ in saveSettings() }

                Spacer()

                HStack {
                    Text("Default Timeframe:")
                        .font(.subheadline)
                    Picker("Timeframe", selection: $settings.defaultTimeframe) {
                        ForEach(GoalTimeframe.allCases, id: \.self) { tf in
                            Text(tf.displayName).tag(tf)
                        }
                    }
                    .frame(width: 120)
                    .onChange(of: settings.defaultTimeframe) { _ in saveSettings() }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var goalsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Goals")
                    .font(.headline)

                Spacer()

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search...", text: $searchText)
                        .frame(width: 120)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }

            // Filters
            HStack(spacing: 12) {
                // Subject filter
                Menu {
                    Button("All Subjects") {
                        selectedSubject = nil
                    }
                    Divider()
                    ForEach(LearningSubject.allCases, id: \.self) { subject in
                        Button(action: { selectedSubject = subject }) {
                            Label(subject.displayName, systemImage: subject.icon)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedSubject?.icon ?? "square.grid.2x2")
                        Text(selectedSubject?.displayName ?? "Subject")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                // Priority filter
                Menu {
                    Button("All Priorities") {
                        selectedPriority = nil
                    }
                    Divider()
                    ForEach(GoalPriority.allCases, id: \.self) { priority in
                        Button(priority.displayName) {
                            selectedPriority = priority
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "flag")
                        Text(selectedPriority?.displayName ?? "Priority")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                Spacer()

                Text("\(filteredGoals.count) goals")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Goals list
            if filteredGoals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No goals found")
                        .font(.headline)
                    Text("Create a new learning goal to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button(action: { showingAddGoal = true }) {
                        Text("Create Goal")
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
                    ForEach(filteredGoals) { goal in
                        GoalCard(goal: goal, onTap: { showingGoalDetail = goal }, onQuickProgress: {
                            if let index = settings.goals.firstIndex(where: { $0.id == goal.id }) {
                                settings.goals[index].currentValue = min(settings.goals[index].currentValue + 1, settings.goals[index].targetValue)
                                if settings.goals[index].currentValue >= settings.goals[index].targetValue {
                                    settings.goals[index].isCompleted = true
                                    settings.goals[index].completedAt = Date()
                                }
                                saveSettings()
                            }
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

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "learningGoalsSettings"),
           let decoded = try? JSONDecoder().decode(LearningGoalsSettings.self, from: data) {
            settings = decoded
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "learningGoalsSettings")
        }
    }
}

// MARK: - Supporting Views

struct GoalStatBox: View {
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

struct SubjectProgressRow: View {
    let subject: LearningSubject
    let progress: Double
    let goalCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: subject.icon)
                .foregroundColor(Color(hex: subject.color))
                .frame(width: 24)

            Text(subject.displayName)
                .font(.subheadline)
                .frame(width: 120, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: subject.color))
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)

            Text("\(goalCount) goals")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct QuickGoalButton: View {
    let title: String
    let subject: LearningSubject
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: subject.icon)
                    .foregroundColor(Color(hex: subject.color))
                Text(title)
                    .font(.caption)
                Image(systemName: "plus.circle")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: subject.color).opacity(0.1))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct GoalCard: View {
    let goal: ParentLearningGoal
    let onTap: () -> Void
    let onQuickProgress: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: goal.subject.icon)
                        .foregroundColor(Color(hex: goal.subject.color))

                    Text(goal.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    // Priority badge
                    Text(goal.priority.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: goal.priority.color).opacity(0.2))
                        .foregroundColor(Color(hex: goal.priority.color))
                        .cornerRadius(8)
                }

                if !goal.description.isEmpty {
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(goal.isCompleted ? Color(hex: "#4CAF50") : Color(hex: goal.subject.color))
                                .frame(width: geo.size.width * goal.progress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(goal.currentValue)/\(goal.targetValue) \(goal.unit)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(goal.timeframe.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                // Quick action
                if !goal.isCompleted {
                    Button(action: { onQuickProgress() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Progress")
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(hex: goal.subject.color).opacity(0.1))
                        .foregroundColor(Color(hex: goal.subject.color))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "#4CAF50"))
                        Text("Completed!")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#4CAF50"))
                        if let completedAt = goal.completedAt {
                            Text(completedAt, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .background(goal.isCompleted ? Color.green.opacity(0.05) : Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Goal Sheet

struct AddGoalSheet: View {
    let defaultTimeframe: GoalTimeframe
    let onSave: (ParentLearningGoal) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var subject: LearningSubject = .reading
    @State private var priority: GoalPriority = .medium
    @State private var timeframe: GoalTimeframe = .weekly
    @State private var targetValue = 1
    @State private var unit = "times"
    @State private var hasTargetDate = false
    @State private var targetDate = Date().addingTimeInterval(30 * 24 * 60 * 60)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Create Learning Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Title")
                            .font(.headline)
                        TextField("e.g., Read 5 books this month", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.headline)
                        TextField("Add more details...", text: $description)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Subject
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subject")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                            ForEach(LearningSubject.allCases, id: \.self) { sub in
                                Button(action: { subject = sub }) {
                                    HStack {
                                        Image(systemName: sub.icon)
                                        Text(sub.displayName)
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(subject == sub ? Color(hex: sub.color) : Color.gray.opacity(0.1))
                                    .foregroundColor(subject == sub ? .white : .primary)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Priority and Timeframe
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(.headline)

                            HStack {
                                ForEach(GoalPriority.allCases, id: \.self) { p in
                                    Button(action: { priority = p }) {
                                        Text(p.displayName)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(priority == p ? Color(hex: p.color) : Color.gray.opacity(0.1))
                                            .foregroundColor(priority == p ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Timeframe")
                                .font(.headline)

                            Picker("Timeframe", selection: $timeframe) {
                                ForEach(GoalTimeframe.allCases, id: \.self) { tf in
                                    Text(tf.displayName).tag(tf)
                                }
                            }
                        }
                    }

                    // Target
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target")
                            .font(.headline)

                        HStack {
                            Stepper("Target: \(targetValue)", value: $targetValue, in: 1...100)

                            TextField("Unit", text: $unit)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                    }

                    // Target date
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Set Target Date", isOn: $hasTargetDate)

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
                    let goal = ParentLearningGoal(
                        title: title,
                        description: description,
                        subject: subject,
                        priority: priority,
                        timeframe: timeframe,
                        targetValue: targetValue,
                        unit: unit,
                        targetDate: hasTargetDate ? targetDate : nil
                    )
                    onSave(goal)
                    dismiss()
                }
                .disabled(title.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 600)
        .onAppear {
            timeframe = defaultTimeframe
        }
    }
}

// MARK: - Goal Detail Sheet

struct GoalDetailSheet: View {
    let goal: ParentLearningGoal
    let onUpdate: (ParentLearningGoal) -> Void
    let onDelete: (UUID) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var currentGoal: ParentLearningGoal
    @State private var newNote = ""
    @State private var progressIncrement = 1

    init(goal: ParentLearningGoal, onUpdate: @escaping (ParentLearningGoal) -> Void, onDelete: @escaping (UUID) -> Void) {
        self.goal = goal
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _currentGoal = State(initialValue: goal)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: currentGoal.subject.icon)
                            .foregroundColor(Color(hex: currentGoal.subject.color))
                        Text(currentGoal.subject.displayName)
                            .font(.subheadline)
                            .foregroundColor(Color(hex: currentGoal.subject.color))
                    }
                    Text(currentGoal.title)
                        .font(.title)
                        .fontWeight(.bold)
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
                    // Description
                    if !currentGoal.description.isEmpty {
                        Text(currentGoal.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    // Progress section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Progress")
                            .font(.headline)

                        // Progress bar
                        VStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 20)

                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(currentGoal.isCompleted ? Color(hex: "#4CAF50") : Color(hex: currentGoal.subject.color))
                                        .frame(width: geo.size.width * currentGoal.progress, height: 20)
                                }
                            }
                            .frame(height: 20)

                            HStack {
                                Text("\(currentGoal.currentValue) / \(currentGoal.targetValue) \(currentGoal.unit)")
                                    .font(.subheadline)

                                Spacer()

                                Text("\(Int(currentGoal.progress * 100))%")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: currentGoal.subject.color))
                            }
                        }

                        // Update progress
                        if !currentGoal.isCompleted {
                            HStack {
                                Text("Add Progress:")
                                    .font(.subheadline)

                                Stepper("\(progressIncrement)", value: $progressIncrement, in: 1...10)

                                Button(action: {
                                    currentGoal.currentValue = min(currentGoal.currentValue + progressIncrement, currentGoal.targetValue)
                                    if currentGoal.currentValue >= currentGoal.targetValue {
                                        currentGoal.isCompleted = true
                                        currentGoal.completedAt = Date()
                                    }
                                    onUpdate(currentGoal)
                                }) {
                                    Text("Add")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(Color(hex: currentGoal.subject.color))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                // Manual value adjustment
                                Button(action: {
                                    if currentGoal.currentValue > 0 {
                                        currentGoal.currentValue -= 1
                                        currentGoal.isCompleted = false
                                        currentGoal.completedAt = nil
                                        onUpdate(currentGoal)
                                    }
                                }) {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "#4CAF50"))
                                Text("Goal Completed!")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#4CAF50"))
                                if let completedAt = currentGoal.completedAt {
                                    Spacer()
                                    Text("on \(completedAt, style: .date)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)

                            Button(action: {
                                currentGoal.isCompleted = false
                                currentGoal.completedAt = nil
                                onUpdate(currentGoal)
                            }) {
                                Text("Mark as Incomplete")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    // Goal info
                    HStack(spacing: 30) {
                        VStack(alignment: .leading) {
                            Text("Priority")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(currentGoal.priority.displayName)
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: currentGoal.priority.color).opacity(0.2))
                                .cornerRadius(8)
                        }

                        VStack(alignment: .leading) {
                            Text("Timeframe")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(currentGoal.timeframe.displayName)
                                .font(.subheadline)
                        }

                        VStack(alignment: .leading) {
                            Text("Started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(currentGoal.startDate, style: .date)
                                .font(.subheadline)
                        }

                        if let targetDate = currentGoal.targetDate {
                            VStack(alignment: .leading) {
                                Text("Target Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(targetDate, style: .date)
                                    .font(.subheadline)
                            }
                        }
                    }

                    Divider()

                    // Notes section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)

                        HStack {
                            TextField("Add a note...", text: $newNote)
                                .textFieldStyle(.roundedBorder)

                            Button(action: {
                                guard !newNote.isEmpty else { return }
                                let note = GoalNote(content: newNote)
                                currentGoal.notes.insert(note, at: 0)
                                onUpdate(currentGoal)
                                newNote = ""
                            }) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(newNote.isEmpty)
                        }

                        if !currentGoal.notes.isEmpty {
                            ForEach(currentGoal.notes) { note in
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
                                        currentGoal.notes.removeAll { $0.id == note.id }
                                        onUpdate(currentGoal)
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
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Button(role: .destructive, action: {
                    onDelete(goal.id)
                    dismiss()
                }) {
                    Label("Delete Goal", systemImage: "trash")
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

#Preview {
    LearningGoalsView()
        .frame(width: 900, height: 700)
}
