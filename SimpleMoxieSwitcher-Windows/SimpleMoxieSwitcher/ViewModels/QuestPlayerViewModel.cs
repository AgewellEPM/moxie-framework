using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Windows.Input;
using SimpleMoxieSwitcher.Models;
using SimpleMoxieSwitcher.Services;
using SimpleMoxieSwitcher.Services.Interfaces;

namespace SimpleMoxieSwitcher.ViewModels
{
    public class QuestPlayerViewModel : INotifyPropertyChanged
    {
        private readonly KnowledgeQuest.QuestTheme _theme;
        private readonly GamesPersistenceService _persistenceService;

        private KnowledgeQuest _currentQuest;
        private bool _isLoading = false;
        private bool _showHint = false;
        private string _errorMessage;

        public KnowledgeQuest CurrentQuest
        {
            get => _currentQuest;
            set
            {
                _currentQuest = value;
                OnPropertyChanged();
            }
        }

        public bool IsLoading
        {
            get => _isLoading;
            set
            {
                _isLoading = value;
                OnPropertyChanged();
            }
        }

        public bool ShowHint
        {
            get => _showHint;
            set
            {
                _showHint = value;
                OnPropertyChanged();
            }
        }

        public string ErrorMessage
        {
            get => _errorMessage;
            set
            {
                _errorMessage = value;
                OnPropertyChanged();
            }
        }

        // Commands
        public ICommand StartQuestCommand { get; }
        public ICommand AnswerChallengeCommand { get; }
        public ICommand ContinueQuestCommand { get; }
        public ICommand NextChapterCommand { get; }
        public ICommand ToggleHintCommand { get; }

        public QuestPlayerViewModel(KnowledgeQuest.QuestTheme theme)
        {
            _theme = theme;
            var dockerService = DIContainer.Instance.Resolve<IDockerService>();
            _persistenceService = new GamesPersistenceService(dockerService);

            // Initialize commands
            StartQuestCommand = new RelayCommand(async () => await StartQuest());
            AnswerChallengeCommand = new RelayCommand<int>(async (answer) => await AnswerChallenge(answer));
            ContinueQuestCommand = new RelayCommand(async () => await ContinueQuest());
            NextChapterCommand = new RelayCommand(async () => await NextChapter());
            ToggleHintCommand = new RelayCommand(() => ShowHint = !ShowHint);
        }

        // Quest Management
        public async Task StartQuest()
        {
            IsLoading = true;

            // Generate quest content
            var quest = await GenerateQuest();
            CurrentQuest = quest;

            // Save to database
            await SaveQuest(quest);

            IsLoading = false;
        }

        public async Task AnswerChallenge(int answer)
        {
            if (CurrentQuest == null || CurrentQuest.CurrentChapter == null ||
                CurrentQuest.CurrentChapter.CurrentEncounter == null)
                return;

            var quest = CurrentQuest;
            var chapter = quest.Chapters[quest.CurrentChapterIndex];
            var encounter = chapter.Encounters[chapter.CurrentEncounterIndex];

            // Record the answer
            var challenge = encounter.Challenge;
            challenge.UserAnswer = answer;

            // Update encounter with result
            encounter.Challenge = challenge;
            encounter.IsCompleted = true;
            encounter.WasSuccessful = challenge.IsCorrect ?? false;

            // Update player stats
            quest.PlayerStats.GainExperience(challenge.ExperienceReward);

            // Update the quest
            CurrentQuest = quest;
            await SaveQuest(quest);
        }

        public async Task ContinueQuest()
        {
            if (CurrentQuest == null || CurrentQuest.CurrentChapter == null)
                return;

            var quest = CurrentQuest;
            var chapter = quest.Chapters[quest.CurrentChapterIndex];

            // Move to next encounter
            chapter.CurrentEncounterIndex++;

            // Check if chapter is complete
            if (chapter.CurrentEncounterIndex >= chapter.Encounters.Count)
            {
                chapter.IsCompleted = true;
            }

            // Update the quest
            CurrentQuest = quest;
            await SaveQuest(quest);
        }

        public async Task NextChapter()
        {
            if (CurrentQuest == null)
                return;

            var quest = CurrentQuest;

            // Move to next chapter
            quest.CurrentChapterIndex++;

            // Check if quest is complete
            if (quest.CurrentChapterIndex >= quest.Chapters.Count)
            {
                quest.IsCompleted = true;
                await RecordQuestCompletion(quest);
            }

            CurrentQuest = quest;
            await SaveQuest(quest);
        }

        // Quest Generation
        private async Task<KnowledgeQuest> GenerateQuest()
        {
            // Get the template for this theme
            var template = QuestTemplate.GetTemplate(_theme);

            // Create quest
            var quest = new KnowledgeQuest(
                _theme.ToString(),
                _theme,
                KnowledgeQuest.Difficulty.Medium
            );

            // Generate chapters
            for (int index = 0; index < template.ChapterTitles.Count; index++)
            {
                var chapterTitle = template.ChapterTitles[index];
                var location = template.Locations[index];
                var chapter = new Chapter(
                    chapterTitle,
                    await GenerateChapterStory(_theme, chapterTitle, location),
                    location
                );

                // Generate encounters for this chapter (3 per chapter)
                for (int encounterIndex = 0; encounterIndex < 3; encounterIndex++)
                {
                    var encounterType = template.EncounterTypes[encounterIndex % template.EncounterTypes.Count];
                    var encounter = await GenerateEncounter(
                        encounterType,
                        _theme,
                        chapterTitle,
                        location
                    );
                    chapter.Encounters.Add(encounter);
                }

                quest.Chapters.Add(chapter);
            }

            return quest;
        }

        private Task<string> GenerateChapterStory(KnowledgeQuest.QuestTheme theme, string title, string location)
        {
            // Generate story based on theme and location
            string story;
            switch (theme)
            {
                case KnowledgeQuest.QuestTheme.Science:
                    story = $"Welcome to the {location}! Strange scientific phenomena have been occurring here. Dr. Moxie needs your help to investigate and solve the mysteries using your scientific knowledge!";
                    break;
                case KnowledgeQuest.QuestTheme.History:
                    story = $"You've arrived at the {location}, a place rich with historical secrets. Historian Moxie guides you through time as you uncover the stories of the past!";
                    break;
                case KnowledgeQuest.QuestTheme.Math:
                    story = $"The {location} is filled with mathematical puzzles and number mysteries. Detective Moxie needs your calculation skills to crack the case!";
                    break;
                case KnowledgeQuest.QuestTheme.Geography:
                    story = $"Explorer Moxie has brought you to the {location}! Use your knowledge of the world to navigate this new terrain and discover its secrets!";
                    break;
                case KnowledgeQuest.QuestTheme.Literature:
                    story = $"You've entered the {location}, where stories come to life! Librarian Moxie invites you to explore the magical world of words and tales!";
                    break;
                case KnowledgeQuest.QuestTheme.Nature:
                    story = $"Ranger Moxie welcomes you to the {location}! The natural world is full of wonders. Let's explore and learn about the ecosystem together!";
                    break;
                case KnowledgeQuest.QuestTheme.Space:
                    story = $"Astronaut Moxie has brought you to the {location}! Prepare for an adventure among the stars as we explore the cosmos!";
                    break;
                case KnowledgeQuest.QuestTheme.Ocean:
                    story = $"Captain Moxie dives with you into the {location}! The ocean depths hold many mysteries. Let's discover what lies beneath the waves!";
                    break;
                default:
                    story = $"Welcome to the {location}! An exciting adventure awaits!";
                    break;
            }
            return Task.FromResult(story);
        }

        private Task<Encounter> GenerateEncounter(Encounter.EncounterType type, KnowledgeQuest.QuestTheme theme, string chapterTitle, string location)
        {
            // Generate appropriate challenge based on theme and type
            var challenge = GenerateChallenge(theme, type);

            string description;
            switch (type)
            {
                case Encounter.EncounterType.Obstacle:
                    description = "A challenging obstacle blocks your path! You must use your knowledge to overcome it.";
                    break;
                case Encounter.EncounterType.Puzzle:
                    description = "You've discovered an intricate puzzle. Solve it to proceed on your quest!";
                    break;
                case Encounter.EncounterType.Riddle:
                    description = "A mysterious riddle has appeared. Answer correctly to unlock the next part of your journey!";
                    break;
                case Encounter.EncounterType.Discovery:
                    description = "You've made an exciting discovery! But first, prove your understanding of what you've found.";
                    break;
                case Encounter.EncounterType.Conversation:
                    description = "Someone needs your help! Answer their question using your knowledge.";
                    break;
                default:
                    description = "A challenge awaits!";
                    break;
            }

            var encounter = new Encounter(type, description, challenge);
            return Task.FromResult(encounter);
        }

        private Challenge GenerateChallenge(KnowledgeQuest.QuestTheme theme, Encounter.EncounterType type)
        {
            // Generate challenge based on theme and encounter type
            switch (theme)
            {
                case KnowledgeQuest.QuestTheme.Science:
                    return new Challenge(
                        "What is the process by which plants make their own food using sunlight?",
                        "Science",
                        "Memory",
                        new List<string> { "Photosynthesis", "Respiration", "Digestion", "Fermentation" },
                        0,
                        "Excellent! Photosynthesis is indeed how plants create energy from sunlight. You've used your scientific knowledge well!",
                        "Not quite right. Remember, plants use photosynthesis to convert sunlight into energy. Let's keep learning!",
                        "Think about the word that means 'photo' (light) and 'synthesis' (making something)."
                    );
                case KnowledgeQuest.QuestTheme.History:
                    return new Challenge(
                        "Which ancient civilization built the Great Pyramids?",
                        "History",
                        "Memory",
                        new List<string> { "Ancient Egypt", "Ancient Greece", "Ancient Rome", "Ancient Babylon" },
                        0,
                        "Correct! The Ancient Egyptians built the magnificent pyramids. Your historical knowledge shines!",
                        "Not quite. The pyramids were built by the Ancient Egyptians thousands of years ago. A fascinating piece of history!",
                        "These pyramids are located along the Nile River in Africa."
                    );
                case KnowledgeQuest.QuestTheme.Math:
                    return new Challenge(
                        "If you have 3 groups of 4 apples, how many apples do you have in total?",
                        "Math",
                        "Calculation",
                        new List<string> { "7", "10", "12", "16" },
                        2,
                        "Perfect calculation! 3 × 4 = 12. Your math skills are sharp!",
                        "Let's think about this: 4 apples + 4 apples + 4 apples = 12 apples. Multiplication helps us count groups quickly!",
                        "This is a multiplication problem: 3 groups times 4 apples in each group."
                    );
                case KnowledgeQuest.QuestTheme.Geography:
                    return new Challenge(
                        "What is the largest ocean on Earth?",
                        "Geography",
                        "Memory",
                        new List<string> { "Pacific Ocean", "Atlantic Ocean", "Indian Ocean", "Arctic Ocean" },
                        0,
                        "Excellent! The Pacific Ocean is the largest and deepest ocean on Earth. You know your geography!",
                        "The Pacific Ocean is actually the largest. It covers about one-third of Earth's surface!",
                        "This ocean is between Asia and the Americas."
                    );
                case KnowledgeQuest.QuestTheme.Literature:
                    return new Challenge(
                        "What do we call a story that teaches a lesson, often using animals as characters?",
                        "Literature",
                        "Logic",
                        new List<string> { "Fable", "Biography", "Poem", "Dictionary" },
                        0,
                        "Wonderful! A fable is a story with a moral lesson, often featuring talking animals. You understand story types well!",
                        "The answer is a fable! Think of stories like 'The Tortoise and the Hare' - they teach us lessons.",
                        "Aesop wrote many of these types of stories."
                    );
                case KnowledgeQuest.QuestTheme.Nature:
                    return new Challenge(
                        "What do we call an animal that eats only plants?",
                        "Nature",
                        "Memory",
                        new List<string> { "Herbivore", "Carnivore", "Omnivore", "Predator" },
                        0,
                        "Correct! Herbivores eat only plants, like cows, deer, and rabbits. You know your animal classifications!",
                        "An herbivore eats only plants. 'Herb' means plant, and 'vore' means to eat!",
                        "The word contains 'herb' which relates to plants."
                    );
                case KnowledgeQuest.QuestTheme.Space:
                    return new Challenge(
                        "What is the name of Earth's natural satellite that we can see in the night sky?",
                        "Space",
                        "Memory",
                        new List<string> { "The Moon", "Mars", "Venus", "A Star" },
                        0,
                        "Perfect! The Moon is Earth's natural satellite. Your space knowledge is stellar!",
                        "It's the Moon! It orbits around Earth and reflects the Sun's light.",
                        "It changes shape in the sky throughout the month."
                    );
                case KnowledgeQuest.QuestTheme.Ocean:
                    return new Challenge(
                        "What is the largest animal in the ocean?",
                        "Ocean",
                        "Memory",
                        new List<string> { "Blue Whale", "Great White Shark", "Giant Squid", "Orca" },
                        0,
                        "Excellent! The Blue Whale is the largest animal not just in the ocean, but on the entire planet!",
                        "The Blue Whale is the largest! It can grow over 100 feet long and weigh as much as 200 tons!",
                        "This animal is a mammal that can grow over 100 feet long."
                    );
                default:
                    return new Challenge(
                        "What is 2 + 2?",
                        "Math",
                        "Calculation",
                        new List<string> { "3", "4", "5", "6" },
                        1,
                        "Correct! 2 + 2 = 4!",
                        "Not quite. 2 + 2 = 4. Let's try again!",
                        "Count on your fingers: 2 fingers plus 2 more fingers."
                    );
            }
        }

        // Database Operations
        private async Task SaveQuest(KnowledgeQuest quest)
        {
            try
            {
                await _persistenceService.SaveCurrentQuest(quest);
            }
            catch (Exception ex)
            {
                ErrorMessage = ex.Message;
            }
        }

        private async Task RecordQuestCompletion(KnowledgeQuest quest)
        {
            // Load current progress
            QuestProgress progress;
            try
            {
                progress = await _persistenceService.LoadQuestProgress() ?? new QuestProgress();
            }
            catch
            {
                progress = new QuestProgress();
            }

            // Record completion
            progress.RecordQuestCompletion(quest);

            // Save back to database
            try
            {
                await _persistenceService.SaveQuestProgress(progress);
            }
            catch (Exception ex)
            {
                ErrorMessage = ex.Message;
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}