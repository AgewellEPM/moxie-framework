import Foundation
import SwiftUI

@MainActor
class QuestPlayerViewModel: ObservableObject {
    @Published var currentQuest: KnowledgeQuest?
    @Published var isLoading = false
    @Published var showHint = false
    @Published var errorMessage: String?

    private let theme: KnowledgeQuest.QuestTheme
    private let persistenceService: GamesPersistenceService

    init(theme: KnowledgeQuest.QuestTheme) {
        self.theme = theme
        let dockerService = DIContainer.shared.resolve(DockerServiceProtocol.self)
        self.persistenceService = GamesPersistenceService(dockerService: dockerService)
    }

    // MARK: - Quest Management

    func startQuest() async {
        isLoading = true

        // Generate quest content
        let quest = await generateQuest()
        currentQuest = quest

        // Save to database
        await saveQuest(quest)

        isLoading = false
    }

    func answerChallenge(answer: Int) async {
        guard var quest = currentQuest,
              var chapter = quest.currentChapter,
              var encounter = chapter.currentEncounter else {
            return
        }

        // Record the answer
        var challenge = encounter.challenge
        challenge.userAnswer = answer

        // Update encounter with result
        encounter.challenge = challenge
        encounter.isCompleted = true
        encounter.wasSuccessful = challenge.isCorrect ?? false

        // Update player stats
        quest.playerStats.gainExperience(challenge.experienceReward)

        // Update the encounter in the chapter
        chapter.encounters[chapter.currentEncounterIndex] = encounter

        // Update the chapter in the quest
        quest.chapters[quest.currentChapterIndex] = chapter

        // Save updated quest
        currentQuest = quest
        await saveQuest(quest)
    }

    func continueQuest() async {
        guard var quest = currentQuest,
              var chapter = quest.currentChapter else {
            return
        }

        // Move to next encounter
        chapter.currentEncounterIndex += 1

        // Check if chapter is complete
        if chapter.currentEncounterIndex >= chapter.encounters.count {
            chapter.isCompleted = true
        }

        // Update the chapter
        quest.chapters[quest.currentChapterIndex] = chapter
        currentQuest = quest

        await saveQuest(quest)
    }

    func nextChapter() async {
        guard var quest = currentQuest else { return }

        // Move to next chapter
        quest.currentChapterIndex += 1

        // Check if quest is complete
        if quest.currentChapterIndex >= quest.chapters.count {
            quest.isCompleted = true
            await recordQuestCompletion(quest)
        }

        currentQuest = quest
        await saveQuest(quest)
    }

    // MARK: - Quest Generation

    private func generateQuest() async -> KnowledgeQuest {
        // Get the template for this theme
        let template = QuestTemplate.template(for: theme)

        // Create quest
        var quest = KnowledgeQuest(
            title: theme.rawValue,
            theme: theme,
            difficulty: .medium
        )

        // Generate chapters
        for (index, chapterTitle) in template.chapterTitles.enumerated() {
            let location = template.locations[index]
            var chapter = Chapter(
                title: chapterTitle,
                storyText: await generateChapterStory(theme: theme, title: chapterTitle, location: location),
                location: location
            )

            // Generate encounters for this chapter (3 per chapter)
            for encounterIndex in 0..<3 {
                let encounterType = template.encounterTypes[encounterIndex % template.encounterTypes.count]
                let encounter = await generateEncounter(
                    type: encounterType,
                    theme: theme,
                    chapterTitle: chapterTitle,
                    location: location
                )
                chapter.encounters.append(encounter)
            }

            quest.chapters.append(chapter)
        }

        return quest
    }

    private func generateChapterStory(theme: KnowledgeQuest.QuestTheme, title: String, location: String) async -> String {
        // Generate story based on theme and location
        switch theme {
        case .science:
            return "Welcome to the \(location)! Strange scientific phenomena have been occurring here. Dr. Moxie needs your help to investigate and solve the mysteries using your scientific knowledge!"
        case .history:
            return "You've arrived at the \(location), a place rich with historical secrets. Historian Moxie guides you through time as you uncover the stories of the past!"
        case .math:
            return "The \(location) is filled with mathematical puzzles and number mysteries. Detective Moxie needs your calculation skills to crack the case!"
        case .geography:
            return "Explorer Moxie has brought you to the \(location)! Use your knowledge of the world to navigate this new terrain and discover its secrets!"
        case .literature:
            return "You've entered the \(location), where stories come to life! Librarian Moxie invites you to explore the magical world of words and tales!"
        case .nature:
            return "Ranger Moxie welcomes you to the \(location)! The natural world is full of wonders. Let's explore and learn about the ecosystem together!"
        case .space:
            return "Astronaut Moxie has brought you to the \(location)! Prepare for an adventure among the stars as we explore the cosmos!"
        case .ocean:
            return "Captain Moxie dives with you into the \(location)! The ocean depths hold many mysteries. Let's discover what lies beneath the waves!"
        }
    }

    private func generateEncounter(type: Encounter.EncounterType, theme: KnowledgeQuest.QuestTheme, chapterTitle: String, location: String) async -> Encounter {
        // Generate appropriate challenge based on theme and type
        let challenge = generateChallenge(theme: theme, type: type)

        let description: String
        switch type {
        case .obstacle:
            description = "A challenging obstacle blocks your path! You must use your knowledge to overcome it."
        case .puzzle:
            description = "You've discovered an intricate puzzle. Solve it to proceed on your quest!"
        case .riddle:
            description = "A mysterious riddle has appeared. Answer correctly to unlock the next part of your journey!"
        case .discovery:
            description = "You've made an exciting discovery! But first, prove your understanding of what you've found."
        case .conversation:
            description = "Someone needs your help! Answer their question using your knowledge."
        }

        return Encounter(
            type: type,
            description: description,
            challenge: challenge
        )
    }

    private func generateChallenge(theme: KnowledgeQuest.QuestTheme, type: Encounter.EncounterType) -> Challenge {
        // Generate challenge based on theme and encounter type
        switch theme {
        case .science:
            return Challenge(
                question: "What is the process by which plants make their own food using sunlight?",
                knowledgeArea: "Science",
                skillRequired: "Memory",
                options: ["Photosynthesis", "Respiration", "Digestion", "Fermentation"],
                correctAnswer: 0,
                successOutcome: "Excellent! Photosynthesis is indeed how plants create energy from sunlight. You've used your scientific knowledge well!",
                failureOutcome: "Not quite right. Remember, plants use photosynthesis to convert sunlight into energy. Let's keep learning!",
                hint: "Think about the word that means 'photo' (light) and 'synthesis' (making something)."
            )
        case .history:
            return Challenge(
                question: "Which ancient civilization built the Great Pyramids?",
                knowledgeArea: "History",
                skillRequired: "Memory",
                options: ["Ancient Egypt", "Ancient Greece", "Ancient Rome", "Ancient Babylon"],
                correctAnswer: 0,
                successOutcome: "Correct! The Ancient Egyptians built the magnificent pyramids. Your historical knowledge shines!",
                failureOutcome: "Not quite. The pyramids were built by the Ancient Egyptians thousands of years ago. A fascinating piece of history!",
                hint: "These pyramids are located along the Nile River in Africa."
            )
        case .math:
            return Challenge(
                question: "If you have 3 groups of 4 apples, how many apples do you have in total?",
                knowledgeArea: "Math",
                skillRequired: "Calculation",
                options: ["7", "10", "12", "16"],
                correctAnswer: 2,
                successOutcome: "Perfect calculation! 3 × 4 = 12. Your math skills are sharp!",
                failureOutcome: "Let's think about this: 4 apples + 4 apples + 4 apples = 12 apples. Multiplication helps us count groups quickly!",
                hint: "This is a multiplication problem: 3 groups times 4 apples in each group."
            )
        case .geography:
            return Challenge(
                question: "What is the largest ocean on Earth?",
                knowledgeArea: "Geography",
                skillRequired: "Memory",
                options: ["Pacific Ocean", "Atlantic Ocean", "Indian Ocean", "Arctic Ocean"],
                correctAnswer: 0,
                successOutcome: "Excellent! The Pacific Ocean is the largest and deepest ocean on Earth. You know your geography!",
                failureOutcome: "The Pacific Ocean is actually the largest. It covers about one-third of Earth's surface!",
                hint: "This ocean is between Asia and the Americas."
            )
        case .literature:
            return Challenge(
                question: "What do we call a story that teaches a lesson, often using animals as characters?",
                knowledgeArea: "Literature",
                skillRequired: "Logic",
                options: ["Fable", "Biography", "Poem", "Dictionary"],
                correctAnswer: 0,
                successOutcome: "Wonderful! A fable is a story with a moral lesson, often featuring talking animals. You understand story types well!",
                failureOutcome: "The answer is a fable! Think of stories like 'The Tortoise and the Hare' - they teach us lessons.",
                hint: "Aesop wrote many of these types of stories."
            )
        case .nature:
            return Challenge(
                question: "What do we call an animal that eats only plants?",
                knowledgeArea: "Nature",
                skillRequired: "Memory",
                options: ["Herbivore", "Carnivore", "Omnivore", "Predator"],
                correctAnswer: 0,
                successOutcome: "Correct! Herbivores eat only plants, like cows, deer, and rabbits. You know your animal classifications!",
                failureOutcome: "An herbivore eats only plants. 'Herb' means plant, and 'vore' means to eat!",
                hint: "The word contains 'herb' which relates to plants."
            )
        case .space:
            return Challenge(
                question: "What is the name of Earth's natural satellite that we can see in the night sky?",
                knowledgeArea: "Space",
                skillRequired: "Memory",
                options: ["The Moon", "Mars", "Venus", "A Star"],
                correctAnswer: 0,
                successOutcome: "Perfect! The Moon is Earth's natural satellite. Your space knowledge is stellar!",
                failureOutcome: "It's the Moon! It orbits around Earth and reflects the Sun's light.",
                hint: "It changes shape in the sky throughout the month."
            )
        case .ocean:
            return Challenge(
                question: "What is the largest animal in the ocean?",
                knowledgeArea: "Ocean",
                skillRequired: "Memory",
                options: ["Blue Whale", "Great White Shark", "Giant Squid", "Orca"],
                correctAnswer: 0,
                successOutcome: "Excellent! The Blue Whale is the largest animal not just in the ocean, but on the entire planet!",
                failureOutcome: "The Blue Whale is the largest! It can grow over 100 feet long and weigh as much as 200 tons!",
                hint: "This animal is a mammal that can grow over 100 feet long."
            )
        }
    }

    // MARK: - Database Operations

    private func saveQuest(_ quest: KnowledgeQuest) async {
        let result = await persistenceService.saveCurrentQuest(quest)

        switch result {
        case .success:
            break
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func recordQuestCompletion(_ quest: KnowledgeQuest) async {
        // Load current progress
        let loadResult = await persistenceService.loadQuestProgress()

        var progress: QuestProgress
        switch loadResult {
        case .success(let loadedProgress):
            progress = loadedProgress
        case .failure:
            progress = QuestProgress()
        }

        // Record completion
        progress.recordQuestCompletion(quest: quest)

        // Save back to database
        let saveResult = await persistenceService.saveQuestProgress(progress)

        switch saveResult {
        case .success:
            break
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
