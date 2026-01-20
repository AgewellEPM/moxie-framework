import SwiftUI

struct LearningWizardView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: LearningViewModel
    @State private var currentStep = 0
    @State private var learningTopic = ""
    @FocusState private var isTextFieldFocused: Bool

    let totalSteps = 5  // Removed learning style step since Moxie is conversational only

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.05),
                    Color(red: 0.08, green: 0.12, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with progress
                VStack(spacing: 12) {
                    HStack {
                        Text("🎓 Learning Wizard")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }

                    // Progress bar
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Step \(currentStep + 1) of \(totalSteps)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green)
                                    .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)

                // Step content
                ScrollView {
                    VStack(spacing: 24) {
                        stepContent
                    }
                    .padding(32)
                }

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: { withAnimation { currentStep -= 1 } }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Back")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Button(action: nextStep) {
                        HStack {
                            Text(currentStep == totalSteps - 1 ? "Start Learning!" : "Next")
                            if currentStep < totalSteps - 1 {
                                Image(systemName: "arrow.right")
                            } else {
                                Image(systemName: "sparkles")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(canProceed ? Color.green : Color.gray.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canProceed)
                }
                .padding()
                .background(Color.black.opacity(0.3))
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            welcomeStep
        case 1:
            subjectStep
        case 2:
            gradeLevelStep
        case 3:
            difficultyStep
        case 4:
            topicStep
        default:
            EmptyView()
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding(.top, 20)

            Text("Welcome to Learning Lab!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Let's create a personalized learning experience with Moxie")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                LearningFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Adaptive learning paths")
                LearningFeatureRow(icon: "questionmark.circle.fill", text: "Interactive quizzes")
                LearningFeatureRow(icon: "book.fill", text: "Comprehensive curriculums")
                LearningFeatureRow(icon: "sparkles", text: "Learn at your own pace")
            }
            .padding()
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var subjectStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Choose a Subject")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("What subject area interests you?")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Subject.allCases, id: \.self) { subject in
                    SubjectOption(
                        subject: subject,
                        isSelected: viewModel.subject == subject,
                        action: { viewModel.subject = subject }
                    )
                }
            }
        }
    }

    private var gradeLevelStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)

            Text("Select Grade Level")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Choose the appropriate learning level")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))

            VStack(spacing: 12) {
                ForEach(GradeLevel.allCases, id: \.self) { level in
                    GradeLevelOption(
                        level: level,
                        isSelected: viewModel.gradeLevel == level,
                        action: { viewModel.gradeLevel = level }
                    )
                }
            }
        }
    }

    private var difficultyStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Difficulty Level")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("How challenging should the content be?")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))

            VStack(spacing: 16) {
                ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                    DifficultyOption(
                        difficulty: difficulty,
                        isSelected: viewModel.difficulty == difficulty,
                        action: { viewModel.difficulty = difficulty }
                    )
                }
            }
        }
    }

    private var learningStyleStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)

            Text("Learning Style")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("How do you learn best?")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))

            VStack(spacing: 12) {
                ForEach(LearningStyle.allCases, id: \.self) { style in
                    LearningStyleOption(
                        style: style,
                        isSelected: viewModel.learningStyle == style,
                        action: { viewModel.learningStyle = style }
                    )
                }
            }

            // Lesson Length
            VStack(spacing: 8) {
                Text("Lesson Duration")
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    ForEach(LessonLength.allCases, id: \.self) { length in
                        LessonLengthButton(
                            length: length,
                            isSelected: viewModel.lessonLength == length,
                            action: { viewModel.lessonLength = length }
                        )
                    }
                }
            }
        }
    }

    private var topicStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.cyan)

            Text("What Do You Want to Learn?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Be specific about your learning goal")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))

            VStack(alignment: .leading, spacing: 12) {
                Text("Learning Topic")
                    .font(.headline)
                    .foregroundColor(.white)

                TextEditor(text: $learningTopic)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(height: 120)
                    .scrollContentBackground(.hidden)
                    .padding()
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if learningTopic.isEmpty {
                                Text(getTopicPlaceholder())
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding()
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
                    .focused($isTextFieldFocused)
            }

            // Summary card
            VStack(alignment: .leading, spacing: 12) {
                Text("📋 Your Learning Plan")
                    .font(.headline)
                    .foregroundColor(.white)

                LearningSummaryRow(label: "Subject", value: viewModel.subject.rawValue)
                LearningSummaryRow(label: "Grade Level", value: viewModel.gradeLevel.rawValue)
                LearningSummaryRow(label: "Difficulty", value: viewModel.difficulty.rawValue)
                LearningSummaryRow(label: "Duration", value: viewModel.lessonLength.rawValue)
            }
            .padding()
            .background(Color.green.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func getTopicPlaceholder() -> String {
        switch viewModel.subject {
        case .math:
            return "e.g., Solving quadratic equations, Understanding fractions, Calculus derivatives..."
        case .science:
            return "e.g., The water cycle, Photosynthesis, Newton's laws of motion, DNA structure..."
        case .english:
            return "e.g., Writing persuasive essays, Shakespeare's Romeo and Juliet, Grammar rules..."
        case .history:
            return "e.g., The American Revolution, Ancient Egypt, World War II causes..."
        case .coding:
            return "e.g., Python loops and functions, Building a website, Machine learning basics..."
        case .art:
            return "e.g., Color theory, Renaissance art, Playing the piano, Music composition..."
        case .language:
            return "e.g., Spanish conversation basics, French verb conjugation, Japanese writing..."
        case .general:
            return "e.g., Critical thinking, Study skills, Time management, Problem solving..."
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case 4:  // Topic step (now step 4 instead of 5)
            return !learningTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return true
        }
    }

    private func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
                if currentStep == 4 {  // Topic step is now step 4
                    // Set learning style to conversational automatically
                    viewModel.learningStyle = .conversational
                    isTextFieldFocused = true
                }
            }
        } else {
            // Start learning!
            Task {
                await viewModel.generateCurriculum(topic: learningTopic, fromWizard: true)
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

struct LearningFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.green)
                .frame(width: 32)
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)
            Spacer()
        }
    }
}

struct SubjectOption: View {
    let subject: Subject
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch subject {
        case .math: return "🔢"
        case .science: return "🔬"
        case .english: return "📖"
        case .history: return "🏛️"
        case .coding: return "💻"
        case .art: return "🎨"
        case .language: return "🌍"
        case .general: return "🧠"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 32))
                Text(subject.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct GradeLevelOption: View {
    let level: GradeLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(level.rawValue)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(
                isSelected ? Color.purple.opacity(0.3) : Color.white.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct DifficultyOption: View {
    let difficulty: DifficultyLevel
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch difficulty {
        case .beginner: return "🌱"
        case .intermediate: return "🌿"
        case .advanced: return "🌳"
        }
    }

    private var description: String {
        switch difficulty {
        case .beginner: return "Start with the basics"
        case .intermediate: return "Build on existing knowledge"
        case .advanced: return "Challenge yourself"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(difficulty.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(
                isSelected ? Color.orange.opacity(0.3) : Color.white.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct LearningStyleOption: View {
    let style: LearningStyle
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch style {
        case .visual: return "👁️"
        case .handson: return "🙌"
        case .reading: return "📚"
        case .conversational: return "💬"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(icon)
                    .font(.system(size: 20))
                Text(style.rawValue)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.yellow)
                }
            }
            .padding()
            .background(
                isSelected ? Color.yellow.opacity(0.3) : Color.white.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.yellow : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct LessonLengthButton: View {
    let length: LessonLength
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(length.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.cyan : Color.white.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
        .buttonStyle(.plain)
    }
}

struct LearningSummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}