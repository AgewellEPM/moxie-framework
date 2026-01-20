import Foundation
import SwiftUI

@MainActor
class LanguageLearningWizardViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var selectedLanguage: Language?
    @Published var selectedProficiency: LanguageLearningSession.ProficiencyLevel?
    @Published var selectedGoals: Set<WizardLearningGoal> = []
    @Published var dailyStudyMinutes = 15
    @Published var preferredTimes: Set<String> = []
    @Published var enableReminders = true
    @Published var selectedInterests: Set<LearningInterest> = []

    private let vocabularyService: VocabularyGenerationService

    init(vocabularyService: VocabularyGenerationService? = nil) {
        self.vocabularyService = vocabularyService ?? VocabularyGenerationService()
    }

    let availableInterests: [LearningInterest] = [
        LearningInterest(title: "Food & Cooking", emoji: "🍳"),
        LearningInterest(title: "Sports", emoji: "⚽"),
        LearningInterest(title: "Music", emoji: "🎵"),
        LearningInterest(title: "Movies & TV", emoji: "🎬"),
        LearningInterest(title: "Technology", emoji: "💻"),
        LearningInterest(title: "Science", emoji: "🔬"),
        LearningInterest(title: "Art & Design", emoji: "🎨"),
        LearningInterest(title: "Nature & Animals", emoji: "🌿"),
        LearningInterest(title: "History", emoji: "📜"),
        LearningInterest(title: "Fashion", emoji: "👗"),
        LearningInterest(title: "Gaming", emoji: "🎮"),
        LearningInterest(title: "Photography", emoji: "📸"),
    ]

    var stepTitle: String {
        switch currentStep {
        case 0: return "Step 1: Choose Your Language"
        case 1: return "Step 2: Select Your Level"
        case 2: return "Step 3: Define Your Goals"
        case 3: return "Step 4: Set Your Schedule"
        case 4: return "Step 5: Pick Your Interests"
        case 5: return "Step 6: Review Your Plan"
        case 6: return "All Done!"
        default: return ""
        }
    }

    var canProceed: Bool {
        switch currentStep {
        case 0: return selectedLanguage != nil
        case 1: return selectedProficiency != nil
        case 2: return !selectedGoals.isEmpty
        case 3: return dailyStudyMinutes > 0
        case 4: return true // Interests are optional
        case 5: return true
        default: return false
        }
    }

    func nextStep() {
        guard canProceed else { return }
        currentStep += 1
    }

    func previousStep() {
        currentStep = max(0, currentStep - 1)
    }

    func toggleGoal(_ goal: WizardLearningGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    func createSession() async {
        guard let language = selectedLanguage,
              let proficiency = selectedProficiency else {
            return
        }

        // Create the learning session
        var session = LanguageLearningSession(
            language: language.name,
            languageCode: language.code,
            languageFlag: language.flag,
            proficiencyLevel: proficiency
        )

        // Generate initial lessons based on proficiency and goals
        session.lessons = generateLessons(for: proficiency, goals: selectedGoals, interests: selectedInterests)

        // Generate vocabulary based on level
        session.vocabulary = await generateInitialVocabulary(for: proficiency, interests: selectedInterests)

        // Save to OpenMoxie database
        await saveToDatabase(session: session)

        // Set up daily reminders if enabled
        if enableReminders {
            scheduleReminders()
        }
    }

    // MARK: - Lesson Generation

    private func generateLessons(
        for level: LanguageLearningSession.ProficiencyLevel,
        goals: Set<WizardLearningGoal>,
        interests: Set<LearningInterest>
    ) -> [LanguageLesson] {
        var lessons: [LanguageLesson] = []

        // Essential lessons for all levels
        lessons.append(contentsOf: generateEssentialLessons(for: level))

        // Goal-specific lessons
        if goals.contains(.conversation) {
            lessons.append(contentsOf: generateConversationLessons(for: level))
        }

        if goals.contains(.travel) {
            lessons.append(contentsOf: generateTravelLessons(for: level))
        }

        if goals.contains(.business) {
            lessons.append(contentsOf: generateBusinessLessons(for: level))
        }

        if goals.contains(.reading) {
            lessons.append(contentsOf: generateReadingLessons(for: level))
        }

        if goals.contains(.culture) {
            lessons.append(contentsOf: generateCultureLessons(for: level))
        }

        if goals.contains(.academic) {
            lessons.append(contentsOf: generateAcademicLessons(for: level))
        }

        // Interest-based lessons
        for interest in interests {
            lessons.append(contentsOf: generateInterestLessons(for: interest, level: level))
        }

        return lessons
    }

    private func generateEssentialLessons(for level: LanguageLearningSession.ProficiencyLevel) -> [LanguageLesson] {
        switch level {
        case .beginner:
            return [
                LanguageLesson(
                    title: "Greetings & Introductions",
                    description: "Learn how to say hello and introduce yourself",
                    category: .conversation,
                    difficultyLevel: 1
                ),
                LanguageLesson(
                    title: "Numbers & Counting",
                    description: "Master numbers from 1 to 100",
                    category: .vocabulary,
                    difficultyLevel: 1
                ),
                LanguageLesson(
                    title: "Basic Pronunciation",
                    description: "Learn the sounds of the language",
                    category: .pronunciation,
                    difficultyLevel: 1
                ),
                LanguageLesson(
                    title: "Common Phrases",
                    description: "Essential daily expressions",
                    category: .vocabulary,
                    difficultyLevel: 1
                ),
            ]

        case .elementary:
            return [
                LanguageLesson(
                    title: "Present Tense Verbs",
                    description: "Learn to conjugate basic verbs in present tense",
                    category: .grammar,
                    difficultyLevel: 2
                ),
                LanguageLesson(
                    title: "Describing People & Things",
                    description: "Adjectives and descriptions",
                    category: .vocabulary,
                    difficultyLevel: 2
                ),
                LanguageLesson(
                    title: "Asking Questions",
                    description: "Form basic questions",
                    category: .grammar,
                    difficultyLevel: 2
                ),
            ]

        case .intermediate:
            return [
                LanguageLesson(
                    title: "Past & Future Tenses",
                    description: "Expand your time expressions",
                    category: .grammar,
                    difficultyLevel: 3
                ),
                LanguageLesson(
                    title: "Expressing Opinions",
                    description: "Share your thoughts and preferences",
                    category: .conversation,
                    difficultyLevel: 3
                ),
                LanguageLesson(
                    title: "Idiomatic Expressions",
                    description: "Common sayings and idioms",
                    category: .vocabulary,
                    difficultyLevel: 3
                ),
            ]

        case .upperIntermediate:
            return [
                LanguageLesson(
                    title: "Advanced Grammar Structures",
                    description: "Complex sentences and clauses",
                    category: .grammar,
                    difficultyLevel: 4
                ),
                LanguageLesson(
                    title: "Debate & Discussion",
                    description: "Express complex ideas and arguments",
                    category: .conversation,
                    difficultyLevel: 4
                ),
            ]

        case .advanced:
            return [
                LanguageLesson(
                    title: "Nuance & Subtlety",
                    description: "Master subtle meanings and contexts",
                    category: .grammar,
                    difficultyLevel: 5
                ),
                LanguageLesson(
                    title: "Literature & Poetry",
                    description: "Analyze literary texts",
                    category: .reading,
                    difficultyLevel: 5
                ),
            ]
        }
    }

    private func generateConversationLessons(for level: LanguageLearningSession.ProficiencyLevel) -> [LanguageLesson] {
        [
            LanguageLesson(
                title: "Daily Conversations",
                description: "Practice everyday chitchat",
                category: .conversation,
                difficultyLevel: level == .beginner ? 1 : (level == .elementary ? 2 : 3)
            ),
            LanguageLesson(
                title: "Making Friends",
                description: "Social expressions and small talk",
                category: .conversation,
                difficultyLevel: level == .beginner ? 2 : (level == .elementary ? 3 : 4)
            ),
        ]
    }

    private func generateTravelLessons(for level: LanguageLearningSession.ProficiencyLevel) -> [LanguageLesson] {
        [
            LanguageLesson(
                title: "At the Airport",
                description: "Navigate airports and check-in",
                category: .vocabulary,
                difficultyLevel: 2
            ),
            LanguageLesson(
                title: "Ordering Food",
                description: "Restaurant vocabulary and phrases",
                category: .conversation,
                difficultyLevel: 2
            ),
            LanguageLesson(
                title: "Asking for Directions",
                description: "Get around in a new city",
                category: .conversation,
                difficultyLevel: 2
            ),
        ]
    }

    private func generateBusinessLessons(for level: LanguageLearningSession.ProficiencyLevel) -> [LanguageLesson] {
        [
            LanguageLesson(
                title: "Professional Email Writing",
                description: "Formal business correspondence",
                category: .writing,
                difficultyLevel: 3
            ),
            LanguageLesson(
                title: "Meeting Language",
                description: "Phrases for business meetings",
                category: .conversation,
                difficultyLevel: 3
            ),
        ]
    }

    private func generateReadingLessons(for level: LanguageLearningSession.ProficiencyLevel) -> [LanguageLesson] {
        [
            LanguageLesson(
                title: "Reading Comprehension",
                description: "Understand written texts",
                category: .reading,
                difficultyLevel: level == .beginner ? 2 : 3
            ),
            LanguageLesson(
                title: "Writing Practice",
                description: "Express yourself in writing",
                category: .writing,
                difficultyLevel: level == .beginner ? 2 : 3
            ),
        ]
    }

    private func generateCultureLessons(for level: LanguageLearningSession.ProficiencyLevel) -> [LanguageLesson] {
        [
            LanguageLesson(
                title: "Cultural Customs",
                description: "Understand traditions and etiquette",
                category: .culture,
                difficultyLevel: 2
            ),
            LanguageLesson(
                title: "Holidays & Celebrations",
                description: "Learn about important cultural events",
                category: .culture,
                difficultyLevel: 2
            ),
        ]
    }

    private func generateAcademicLessons(for level: LanguageLearningSession.ProficiencyLevel) -> [LanguageLesson] {
        [
            LanguageLesson(
                title: "Academic Vocabulary",
                description: "Terms for academic contexts",
                category: .vocabulary,
                difficultyLevel: 4
            ),
            LanguageLesson(
                title: "Exam Strategies",
                description: "Prepare for language proficiency tests",
                category: .grammar,
                difficultyLevel: 4
            ),
        ]
    }

    private func generateInterestLessons(for interest: LearningInterest, level: LanguageLearningSession.ProficiencyLevel) -> [LanguageLesson] {
        [
            LanguageLesson(
                title: "\(interest.title) Vocabulary",
                description: "Words and phrases about \(interest.title.lowercased())",
                category: .vocabulary,
                difficultyLevel: level == .beginner ? 1 : 2
            )
        ]
    }

    // MARK: - Vocabulary Generation

    private func generateInitialVocabulary(
        for level: LanguageLearningSession.ProficiencyLevel,
        interests: Set<LearningInterest>
    ) async -> [VocabularyWord] {
        var vocabulary: [VocabularyWord] = []

        // Essential vocabulary for all levels
        vocabulary.append(contentsOf: await getEssentialVocabulary(for: level))

        // Add interest-based vocabulary
        for interest in interests {
            vocabulary.append(contentsOf: await getInterestVocabulary(for: interest))
        }

        return vocabulary
    }

    private func getEssentialVocabulary(for level: LanguageLearningSession.ProficiencyLevel) async -> [VocabularyWord] {
        guard let language = selectedLanguage else { return [] }

        do {
            // Generate vocabulary based on selected goals
            var vocabulary: [VocabularyWord] = []

            // Essential vocabulary
            let essential = try await vocabularyService.generateEssentialVocabulary(
                language: language.name,
                languageCode: language.code,
                proficiencyLevel: level,
                count: 50
            )
            vocabulary.append(contentsOf: essential)

            // Add goal-specific vocabulary
            if selectedGoals.contains(.travel) {
                let travel = try await vocabularyService.generateTravelVocabulary(
                    language: language.name,
                    languageCode: language.code,
                    proficiencyLevel: level
                )
                vocabulary.append(contentsOf: travel)
            }

            if selectedGoals.contains(.business) {
                let business = try await vocabularyService.generateBusinessVocabulary(
                    language: language.name,
                    languageCode: language.code,
                    proficiencyLevel: level
                )
                vocabulary.append(contentsOf: business)
            }

            return vocabulary
        } catch {
            print("❌ Failed to generate vocabulary: \(error)")
            return []
        }
    }

    private func getInterestVocabulary(for interest: LearningInterest) async -> [VocabularyWord] {
        guard let language = selectedLanguage,
              let proficiency = selectedProficiency else { return [] }

        do {
            return try await vocabularyService.generateInterestVocabulary(
                language: language.name,
                languageCode: language.code,
                interest: interest.title,
                proficiencyLevel: proficiency,
                count: 30
            )
        } catch {
            print("❌ Failed to generate interest vocabulary: \(error)")
            return []
        }
    }

    // MARK: - Database Integration

    private func saveToDatabase(session: LanguageLearningSession) async {
        let dockerService = DIContainer.shared.resolve(DockerServiceProtocol.self)

        // Convert session to JSON
        guard let jsonData = try? JSONEncoder().encode(session),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("Failed to encode session")
            return
        }

        let pythonScript = """
        import json
        from hive.models import MoxieDevice, PersistentData

        device = MoxieDevice.objects.filter(device_id='moxie_001').first()
        if device:
            persist, created = PersistentData.objects.get_or_create(device=device, defaults={'data': {}})
            data = persist.data or {}

            # Initialize language_sessions if it doesn't exist
            if 'language_sessions' not in data:
                data['language_sessions'] = []

            # Add the new session
            session_data = json.loads('''\(jsonString)''')
            data['language_sessions'].append(session_data)

            persist.data = data
            persist.save()
            print(f'Language learning session created for {session_data["language"]}')
        """

        do {
            _ = try await dockerService.executePythonScript(pythonScript)
            print("Language learning session saved successfully")
        } catch {
            print("Failed to save session: \(error)")
        }
    }

    private func scheduleReminders() {
        // TODO: Integrate with macOS notifications
        print("Daily reminders scheduled for language practice")
    }
}

// MARK: - Supporting Models

enum WizardLearningGoal: String, Hashable {
    case conversation = "Daily Conversation"
    case travel = "Travel & Tourism"
    case business = "Business & Professional"
    case reading = "Reading & Writing"
    case culture = "Cultural Understanding"
    case academic = "Academic & Exam Prep"
}

struct LearningInterest: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let emoji: String
}
