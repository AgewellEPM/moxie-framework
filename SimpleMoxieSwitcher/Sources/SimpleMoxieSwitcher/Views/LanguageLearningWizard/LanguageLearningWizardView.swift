import SwiftUI

/// Comprehensive Language Learning Wizard with Moxie as tutor
struct LanguageLearningWizardView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = LanguageLearningWizardViewModel()
    @ObservedObject private var localization = LocalizationService.shared

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with progress
                wizardHeader

                Divider()

                // Content based on current step
                wizardContent
                    .frame(maxHeight: .infinity)

                Divider()

                // Navigation buttons
                navigationButtons
            }
        }
        .frame(minWidth: 900, minHeight: 700)
    }

    // MARK: - Header

    private var wizardHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🌍 Language Learning with Moxie")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    Circle()
                        .fill(index <= viewModel.currentStep ? Color.green : Color.white.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
            .padding(.bottom, 16)

            // Step title
            Text(viewModel.stepTitle)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .padding(.bottom, 12)
        }
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Content

    @ViewBuilder
    private var wizardContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                switch viewModel.currentStep {
                case 0:
                    languageSelectionStep
                case 1:
                    proficiencyLevelStep
                case 2:
                    learningGoalsStep
                case 3:
                    scheduleSetupStep
                case 4:
                    interestsSelectionStep
                case 5:
                    reviewAndConfirmStep
                case 6:
                    completionStep
                default:
                    EmptyView()
                }
            }
            .padding(32)
        }
    }

    // MARK: - Step 1: Language Selection

    private var languageSelectionStep: some View {
        VStack(spacing: 24) {
            // Moxie's introduction
            MoxieSpeechBubble(
                message: "Hi! I'm Moxie, your personal language tutor! 🎓 I'm so excited to help you learn a new language. Which language would you like to learn?",
                personality: "Teacher"
            )

            // Language grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(Language.allLanguages, id: \.code) { language in
                    LanguageCard(
                        language: language,
                        isSelected: viewModel.selectedLanguage?.code == language.code,
                        onSelect: {
                            viewModel.selectedLanguage = language
                        }
                    )
                }
            }
        }
    }

    // MARK: - Step 2: Proficiency Level

    private var proficiencyLevelStep: some View {
        VStack(spacing: 24) {
            MoxieSpeechBubble(
                message: "Great choice! Now, tell me about your current level in \(viewModel.selectedLanguage?.name ?? "this language"). Don't worry, we'll start exactly where you are! 🌱",
                personality: "Teacher"
            )

            VStack(spacing: 16) {
                ForEach(LanguageLearningSession.ProficiencyLevel.allCases, id: \.self) { level in
                    ProficiencyLevelCard(
                        level: level,
                        isSelected: viewModel.selectedProficiency == level,
                        onSelect: {
                            viewModel.selectedProficiency = level
                        }
                    )
                }
            }
        }
    }

    // MARK: - Step 3: Learning Goals

    private var learningGoalsStep: some View {
        VStack(spacing: 24) {
            MoxieSpeechBubble(
                message: "Awesome! What are your learning goals? Select all that apply - I'll create a personalized curriculum just for you! 🎯",
                personality: "Teacher"
            )

            VStack(spacing: 12) {
                GoalCheckbox(
                    title: "Daily Conversation",
                    description: "Learn to have everyday conversations",
                    icon: "💬",
                    isSelected: viewModel.selectedGoals.contains(.conversation)
                ) {
                    viewModel.toggleGoal(.conversation)
                }

                GoalCheckbox(
                    title: "Travel & Tourism",
                    description: "Phrases and vocabulary for traveling",
                    icon: "✈️",
                    isSelected: viewModel.selectedGoals.contains(.travel)
                ) {
                    viewModel.toggleGoal(.travel)
                }

                GoalCheckbox(
                    title: "Business & Professional",
                    description: "Professional communication skills",
                    icon: "💼",
                    isSelected: viewModel.selectedGoals.contains(.business)
                ) {
                    viewModel.toggleGoal(.business)
                }

                GoalCheckbox(
                    title: "Reading & Writing",
                    description: "Master reading comprehension and writing",
                    icon: "📚",
                    isSelected: viewModel.selectedGoals.contains(.reading)
                ) {
                    viewModel.toggleGoal(.reading)
                }

                GoalCheckbox(
                    title: "Cultural Understanding",
                    description: "Learn about culture and traditions",
                    icon: "🌍",
                    isSelected: viewModel.selectedGoals.contains(.culture)
                ) {
                    viewModel.toggleGoal(.culture)
                }

                GoalCheckbox(
                    title: "Academic & Exam Prep",
                    description: "Prepare for language exams",
                    icon: "🎓",
                    isSelected: viewModel.selectedGoals.contains(.academic)
                ) {
                    viewModel.toggleGoal(.academic)
                }
            }
        }
    }

    // MARK: - Step 4: Schedule Setup

    private var scheduleSetupStep: some View {
        VStack(spacing: 24) {
            MoxieSpeechBubble(
                message: "Perfect! Now let's plan your study schedule. Consistency is key! How much time can you dedicate each day? ⏰",
                personality: "Teacher"
            )

            VStack(spacing: 20) {
                // Study time selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Study Time")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        ForEach([5, 10, 15, 20, 30, 45, 60], id: \.self) { minutes in
                            Button(action: {
                                viewModel.dailyStudyMinutes = minutes
                            }) {
                                VStack(spacing: 4) {
                                    Text("\(minutes)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("min")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .frame(width: 80, height: 60)
                                .background(
                                    viewModel.dailyStudyMinutes == minutes ?
                                        Color.green.opacity(0.6) :
                                        Color.white.opacity(0.2)
                                )
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Preferred study times
                VStack(alignment: .leading, spacing: 12) {
                    Text("Best Time to Study")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        ForEach(["Morning", "Afternoon", "Evening", "Night"], id: \.self) { timeOfDay in
                            Button(action: {
                                if viewModel.preferredTimes.contains(timeOfDay) {
                                    viewModel.preferredTimes.remove(timeOfDay)
                                } else {
                                    viewModel.preferredTimes.insert(timeOfDay)
                                }
                            }) {
                                Text(timeOfDay)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        viewModel.preferredTimes.contains(timeOfDay) ?
                                            Color.blue.opacity(0.6) :
                                            Color.white.opacity(0.2)
                                    )
                                    .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Reminder toggle
                Toggle(isOn: $viewModel.enableReminders) {
                    HStack {
                        Text("🔔")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Daily Reminders")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("I'll remind you to practice every day")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .toggleStyle(.switch)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Step 5: Interests

    private var interestsSelectionStep: some View {
        VStack(spacing: 24) {
            MoxieSpeechBubble(
                message: "Excellent! Let's make learning fun by focusing on topics you love! Select your interests so I can personalize your lessons! 🎨",
                personality: "Teacher"
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
                ForEach(viewModel.availableInterests, id: \.self) { interest in
                    InterestCard(
                        interest: interest,
                        isSelected: viewModel.selectedInterests.contains(interest)
                    ) {
                        if viewModel.selectedInterests.contains(interest) {
                            viewModel.selectedInterests.remove(interest)
                        } else {
                            viewModel.selectedInterests.insert(interest)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Step 6: Review & Confirm

    private var reviewAndConfirmStep: some View {
        VStack(spacing: 24) {
            MoxieSpeechBubble(
                message: "Fantastic! Let's review your learning plan. Everything looks good? Let's start your language journey! 🚀",
                personality: "Teacher"
            )

            VStack(spacing: 16) {
                // Language & Level
                ReviewCard(title: "Language & Level") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(viewModel.selectedLanguage?.flag ?? "")
                                .font(.largeTitle)
                            VStack(alignment: .leading) {
                                Text(viewModel.selectedLanguage?.name ?? "")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text("\(viewModel.selectedProficiency?.emoji ?? "") \(viewModel.selectedProficiency?.rawValue ?? "")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Goals
                ReviewCard(title: "Learning Goals") {
                    LanguageWizardFlowLayout(spacing: 8) {
                        ForEach(Array(viewModel.selectedGoals), id: \.self) { goal in
                            Text(goal.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                }

                // Schedule
                ReviewCard(title: "Study Schedule") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.dailyStudyMinutes) minutes per day")
                            .font(.subheadline)
                        if !viewModel.preferredTimes.isEmpty {
                            Text("Preferred: \(viewModel.preferredTimes.sorted().joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if viewModel.enableReminders {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .font(.caption)
                                Text("Daily reminders enabled")
                                    .font(.caption)
                            }
                            .foregroundColor(.green)
                        }
                    }
                }

                // Interests
                if !viewModel.selectedInterests.isEmpty {
                    ReviewCard(title: "Your Interests") {
                        LanguageWizardFlowLayout(spacing: 8) {
                            ForEach(Array(viewModel.selectedInterests), id: \.self) { interest in
                                Text("\(interest.emoji) \(interest.title)")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.2))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Step 7: Completion

    private var completionStep: some View {
        VStack(spacing: 32) {
            // Success animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 200, height: 200)

                Text("🎉")
                    .font(.system(size: 100))
            }

            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Your personalized language learning journey starts now!")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            // Session summary
            VStack(spacing: 12) {
                LanguageWizardSummaryRow(icon: "🌍", title: "Language", value: viewModel.selectedLanguage?.name ?? "")
                LanguageWizardSummaryRow(icon: "📊", title: "Level", value: viewModel.selectedProficiency?.rawValue ?? "")
                LanguageWizardSummaryRow(icon: "⏱️", title: "Daily Practice", value: "\(viewModel.dailyStudyMinutes) minutes")
                LanguageWizardSummaryRow(icon: "🎯", title: "Goals", value: "\(viewModel.selectedGoals.count) selected")
                LanguageWizardSummaryRow(icon: "📚", title: "First Lesson", value: "Ready to start!")
            }
            .padding(24)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)

            Button(action: {
                Task {
                    await viewModel.createSession()
                    dismiss()
                }
            }) {
                HStack(spacing: 12) {
                    Text("Start Learning")
                        .font(.headline)
                    Image(systemName: "arrow.right.circle.fill")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: .green.opacity(0.5), radius: 10)
            }
            .buttonStyle(.plain)
        }
        .padding(32)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.currentStep > 0 && viewModel.currentStep < 6 {
                Button(action: {
                    withAnimation {
                        viewModel.previousStep()
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(25)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if viewModel.currentStep < 6 {
                Button(action: {
                    withAnimation {
                        viewModel.nextStep()
                    }
                }) {
                    HStack {
                        Text(viewModel.currentStep == 5 ? "Create Learning Plan" : "Continue")
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.canProceed ?
                            AnyShapeStyle(LinearGradient(colors: [Color.green, Color.blue], startPoint: .leading, endPoint: .trailing)) :
                            AnyShapeStyle(Color.gray.opacity(0.5))
                    )
                    .cornerRadius(25)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canProceed)
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Supporting Views

struct MoxieSpeechBubble: View {
    let message: String
    let personality: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Moxie avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Text("🎓")
                    .font(.system(size: 30))
            }

            // Speech bubble
            VStack(alignment: .leading, spacing: 8) {
                Text("Moxie (\(personality))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))

                Text(message)
                    .font(.body)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color.white.opacity(0.15))
            .cornerRadius(16)
            .overlay(
                // Speech bubble pointer
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 20))
                    path.addLine(to: CGPoint(x: -10, y: 15))
                    path.addLine(to: CGPoint(x: 0, y: 30))
                }
                .fill(Color.white.opacity(0.15))
                .offset(x: 0, y: 0),
                alignment: .leading
            )

            Spacer()
        }
    }
}

struct LanguageCard: View {
    let language: Language
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Text(language.flag)
                    .font(.system(size: 50))

                Text(language.name)
                    .font(.headline)
                    .foregroundColor(.white)

                if let nativeName = language.nativeName {
                    Text(nativeName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                isSelected ?
                    LinearGradient(colors: [Color.green, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 3)
            )
            .shadow(color: isSelected ? Color.green.opacity(0.5) : Color.clear, radius: 10)
        }
        .buttonStyle(.plain)
    }
}

struct ProficiencyLevelCard: View {
    let level: LanguageLearningSession.ProficiencyLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var description: String {
        switch level {
        case .beginner: return "Just starting out - I know very little"
        case .elementary: return "I know some basics and simple phrases"
        case .intermediate: return "I can have simple conversations"
        case .upperIntermediate: return "I'm comfortable with most topics"
        case .advanced: return "I'm fluent and want to perfect my skills"
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Text(level.emoji)
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding(16)
            .background(
                isSelected ?
                    Color.green.opacity(0.3) :
                    Color.white.opacity(0.1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct GoalCheckbox: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(isSelected ? .green : .white.opacity(0.5))
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct InterestCard: View {
    let interest: LearningInterest
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 8) {
                Text(interest.emoji)
                    .font(.system(size: 40))

                Text(interest.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                isSelected ?
                    Color.purple.opacity(0.4) :
                    Color.white.opacity(0.1)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ReviewCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct LanguageWizardSummaryRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(icon)
                .font(.title2)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// Simple flow layout for tags
struct LanguageWizardFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
