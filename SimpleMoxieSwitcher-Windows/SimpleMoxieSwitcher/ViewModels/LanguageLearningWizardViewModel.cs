using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;
using SimpleMoxieSwitcher.Services;

namespace SimpleMoxieSwitcher.ViewModels
{
    public class LanguageLearningWizardViewModel : INotifyPropertyChanged
    {
        private readonly VocabularyGenerationService _vocabularyService;
        private readonly IDockerService _dockerService;

        private int _currentStep;
        private Language _selectedLanguage;
        private LanguageLearningSession.ProficiencyLevel? _selectedProficiency;
        private HashSet<WizardLearningGoal> _selectedGoals = new();
        private int _dailyStudyMinutes = 15;
        private HashSet<string> _preferredTimes = new();
        private bool _enableReminders = true;
        private HashSet<LearningInterest> _selectedInterests = new();

        public LanguageLearningWizardViewModel(
            VocabularyGenerationService vocabularyService = null,
            IDockerService dockerService = null)
        {
            _vocabularyService = vocabularyService ?? new VocabularyGenerationService();
            _dockerService = dockerService ?? DIContainer.Instance.Resolve<IDockerService>();
            InitializeAvailableInterests();
        }

        // Properties
        public int CurrentStep
        {
            get => _currentStep;
            set
            {
                if (_currentStep != value)
                {
                    _currentStep = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(StepTitle));
                    OnPropertyChanged(nameof(CanProceed));
                }
            }
        }

        public Language SelectedLanguage
        {
            get => _selectedLanguage;
            set
            {
                if (_selectedLanguage != value)
                {
                    _selectedLanguage = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(CanProceed));
                }
            }
        }

        public LanguageLearningSession.ProficiencyLevel? SelectedProficiency
        {
            get => _selectedProficiency;
            set
            {
                if (_selectedProficiency != value)
                {
                    _selectedProficiency = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(CanProceed));
                }
            }
        }

        public HashSet<WizardLearningGoal> SelectedGoals
        {
            get => _selectedGoals;
            set
            {
                if (_selectedGoals != value)
                {
                    _selectedGoals = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(CanProceed));
                }
            }
        }

        public int DailyStudyMinutes
        {
            get => _dailyStudyMinutes;
            set
            {
                if (_dailyStudyMinutes != value)
                {
                    _dailyStudyMinutes = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(CanProceed));
                }
            }
        }

        public HashSet<string> PreferredTimes
        {
            get => _preferredTimes;
            set
            {
                if (_preferredTimes != value)
                {
                    _preferredTimes = value;
                    OnPropertyChanged();
                }
            }
        }

        public bool EnableReminders
        {
            get => _enableReminders;
            set
            {
                if (_enableReminders != value)
                {
                    _enableReminders = value;
                    OnPropertyChanged();
                }
            }
        }

        public HashSet<LearningInterest> SelectedInterests
        {
            get => _selectedInterests;
            set
            {
                if (_selectedInterests != value)
                {
                    _selectedInterests = value;
                    OnPropertyChanged();
                }
            }
        }

        public ObservableCollection<LearningInterest> AvailableInterests { get; } = new();

        public string StepTitle
        {
            get
            {
                return CurrentStep switch
                {
                    0 => "Step 1: Choose Your Language",
                    1 => "Step 2: Select Your Level",
                    2 => "Step 3: Define Your Goals",
                    3 => "Step 4: Set Your Schedule",
                    4 => "Step 5: Pick Your Interests",
                    5 => "Step 6: Review Your Plan",
                    6 => "All Done!",
                    _ => ""
                };
            }
        }

        public bool CanProceed
        {
            get
            {
                return CurrentStep switch
                {
                    0 => SelectedLanguage != null,
                    1 => SelectedProficiency.HasValue,
                    2 => SelectedGoals.Count > 0,
                    3 => DailyStudyMinutes > 0,
                    4 => true, // Interests are optional
                    5 => true,
                    _ => false
                };
            }
        }

        // Methods
        public void NextStep()
        {
            if (!CanProceed) return;
            CurrentStep++;
        }

        public void PreviousStep()
        {
            CurrentStep = Math.Max(0, CurrentStep - 1);
        }

        public void ToggleGoal(WizardLearningGoal goal)
        {
            if (_selectedGoals.Contains(goal))
            {
                _selectedGoals.Remove(goal);
            }
            else
            {
                _selectedGoals.Add(goal);
            }
            OnPropertyChanged(nameof(SelectedGoals));
            OnPropertyChanged(nameof(CanProceed));
        }

        public async Task CreateSessionAsync()
        {
            if (SelectedLanguage == null || !SelectedProficiency.HasValue)
                return;

            // Create the learning session
            var session = new LanguageLearningSession
            {
                Language = SelectedLanguage.Name,
                LanguageCode = SelectedLanguage.Code,
                LanguageFlag = SelectedLanguage.Flag,
                ProficiencyLevel = SelectedProficiency.Value,
                Lessons = new List<LanguageLesson>(),
                Vocabulary = new List<VocabularyWord>()
            };

            // Generate initial lessons based on proficiency and goals
            session.Lessons = GenerateLessons(SelectedProficiency.Value, SelectedGoals, SelectedInterests);

            // Generate vocabulary based on level
            session.Vocabulary = await GenerateInitialVocabularyAsync(SelectedProficiency.Value, SelectedInterests);

            // Save to OpenMoxie database
            await SaveToDatabaseAsync(session);

            // Set up daily reminders if enabled
            if (EnableReminders)
            {
                ScheduleReminders();
            }
        }

        // Lesson Generation
        private List<LanguageLesson> GenerateLessons(
            LanguageLearningSession.ProficiencyLevel level,
            HashSet<WizardLearningGoal> goals,
            HashSet<LearningInterest> interests)
        {
            var lessons = new List<LanguageLesson>();

            // Essential lessons for all levels
            lessons.AddRange(GenerateEssentialLessons(level));

            // Goal-specific lessons
            if (goals.Contains(WizardLearningGoal.Conversation))
            {
                lessons.AddRange(GenerateConversationLessons(level));
            }

            if (goals.Contains(WizardLearningGoal.Travel))
            {
                lessons.AddRange(GenerateTravelLessons(level));
            }

            if (goals.Contains(WizardLearningGoal.Business))
            {
                lessons.AddRange(GenerateBusinessLessons(level));
            }

            if (goals.Contains(WizardLearningGoal.Reading))
            {
                lessons.AddRange(GenerateReadingLessons(level));
            }

            if (goals.Contains(WizardLearningGoal.Culture))
            {
                lessons.AddRange(GenerateCultureLessons(level));
            }

            if (goals.Contains(WizardLearningGoal.Academic))
            {
                lessons.AddRange(GenerateAcademicLessons(level));
            }

            // Interest-based lessons
            foreach (var interest in interests)
            {
                lessons.AddRange(GenerateInterestLessons(interest, level));
            }

            return lessons;
        }

        private List<LanguageLesson> GenerateEssentialLessons(LanguageLearningSession.ProficiencyLevel level)
        {
            return level switch
            {
                LanguageLearningSession.ProficiencyLevel.Beginner => new List<LanguageLesson>
                {
                    new LanguageLesson
                    {
                        Title = "Greetings & Introductions",
                        Description = "Learn how to say hello and introduce yourself",
                        Category = LessonCategory.Conversation,
                        DifficultyLevel = 1
                    },
                    new LanguageLesson
                    {
                        Title = "Numbers & Counting",
                        Description = "Master numbers from 1 to 100",
                        Category = LessonCategory.Vocabulary,
                        DifficultyLevel = 1
                    },
                    new LanguageLesson
                    {
                        Title = "Basic Pronunciation",
                        Description = "Learn the sounds of the language",
                        Category = LessonCategory.Pronunciation,
                        DifficultyLevel = 1
                    },
                    new LanguageLesson
                    {
                        Title = "Common Phrases",
                        Description = "Essential daily expressions",
                        Category = LessonCategory.Vocabulary,
                        DifficultyLevel = 1
                    }
                },

                LanguageLearningSession.ProficiencyLevel.Elementary => new List<LanguageLesson>
                {
                    new LanguageLesson
                    {
                        Title = "Present Tense Verbs",
                        Description = "Learn to conjugate basic verbs in present tense",
                        Category = LessonCategory.Grammar,
                        DifficultyLevel = 2
                    },
                    new LanguageLesson
                    {
                        Title = "Describing People & Things",
                        Description = "Adjectives and descriptions",
                        Category = LessonCategory.Vocabulary,
                        DifficultyLevel = 2
                    },
                    new LanguageLesson
                    {
                        Title = "Asking Questions",
                        Description = "Form basic questions",
                        Category = LessonCategory.Grammar,
                        DifficultyLevel = 2
                    }
                },

                LanguageLearningSession.ProficiencyLevel.Intermediate => new List<LanguageLesson>
                {
                    new LanguageLesson
                    {
                        Title = "Past & Future Tenses",
                        Description = "Expand your time expressions",
                        Category = LessonCategory.Grammar,
                        DifficultyLevel = 3
                    },
                    new LanguageLesson
                    {
                        Title = "Expressing Opinions",
                        Description = "Share your thoughts and preferences",
                        Category = LessonCategory.Conversation,
                        DifficultyLevel = 3
                    },
                    new LanguageLesson
                    {
                        Title = "Idiomatic Expressions",
                        Description = "Common sayings and idioms",
                        Category = LessonCategory.Vocabulary,
                        DifficultyLevel = 3
                    }
                },

                LanguageLearningSession.ProficiencyLevel.UpperIntermediate => new List<LanguageLesson>
                {
                    new LanguageLesson
                    {
                        Title = "Advanced Grammar Structures",
                        Description = "Complex sentences and clauses",
                        Category = LessonCategory.Grammar,
                        DifficultyLevel = 4
                    },
                    new LanguageLesson
                    {
                        Title = "Debate & Discussion",
                        Description = "Express complex ideas and arguments",
                        Category = LessonCategory.Conversation,
                        DifficultyLevel = 4
                    }
                },

                LanguageLearningSession.ProficiencyLevel.Advanced => new List<LanguageLesson>
                {
                    new LanguageLesson
                    {
                        Title = "Nuance & Subtlety",
                        Description = "Master subtle meanings and contexts",
                        Category = LessonCategory.Grammar,
                        DifficultyLevel = 5
                    },
                    new LanguageLesson
                    {
                        Title = "Literature & Poetry",
                        Description = "Analyze literary texts",
                        Category = LessonCategory.Reading,
                        DifficultyLevel = 5
                    }
                },

                _ => new List<LanguageLesson>()
            };
        }

        private List<LanguageLesson> GenerateConversationLessons(LanguageLearningSession.ProficiencyLevel level)
        {
            return new List<LanguageLesson>
            {
                new LanguageLesson
                {
                    Title = "Daily Conversations",
                    Description = "Practice everyday chitchat",
                    Category = LessonCategory.Conversation,
                    DifficultyLevel = level == LanguageLearningSession.ProficiencyLevel.Beginner ? 1 :
                                     level == LanguageLearningSession.ProficiencyLevel.Elementary ? 2 : 3
                },
                new LanguageLesson
                {
                    Title = "Making Friends",
                    Description = "Social expressions and small talk",
                    Category = LessonCategory.Conversation,
                    DifficultyLevel = level == LanguageLearningSession.ProficiencyLevel.Beginner ? 2 :
                                     level == LanguageLearningSession.ProficiencyLevel.Elementary ? 3 : 4
                }
            };
        }

        private List<LanguageLesson> GenerateTravelLessons(LanguageLearningSession.ProficiencyLevel level)
        {
            return new List<LanguageLesson>
            {
                new LanguageLesson
                {
                    Title = "At the Airport",
                    Description = "Navigate airports and check-in",
                    Category = LessonCategory.Vocabulary,
                    DifficultyLevel = 2
                },
                new LanguageLesson
                {
                    Title = "Ordering Food",
                    Description = "Restaurant vocabulary and phrases",
                    Category = LessonCategory.Conversation,
                    DifficultyLevel = 2
                },
                new LanguageLesson
                {
                    Title = "Asking for Directions",
                    Description = "Get around in a new city",
                    Category = LessonCategory.Conversation,
                    DifficultyLevel = 2
                }
            };
        }

        private List<LanguageLesson> GenerateBusinessLessons(LanguageLearningSession.ProficiencyLevel level)
        {
            return new List<LanguageLesson>
            {
                new LanguageLesson
                {
                    Title = "Professional Email Writing",
                    Description = "Formal business correspondence",
                    Category = LessonCategory.Writing,
                    DifficultyLevel = 3
                },
                new LanguageLesson
                {
                    Title = "Meeting Language",
                    Description = "Phrases for business meetings",
                    Category = LessonCategory.Conversation,
                    DifficultyLevel = 3
                }
            };
        }

        private List<LanguageLesson> GenerateReadingLessons(LanguageLearningSession.ProficiencyLevel level)
        {
            return new List<LanguageLesson>
            {
                new LanguageLesson
                {
                    Title = "Reading Comprehension",
                    Description = "Understand written texts",
                    Category = LessonCategory.Reading,
                    DifficultyLevel = level == LanguageLearningSession.ProficiencyLevel.Beginner ? 2 : 3
                },
                new LanguageLesson
                {
                    Title = "Writing Practice",
                    Description = "Express yourself in writing",
                    Category = LessonCategory.Writing,
                    DifficultyLevel = level == LanguageLearningSession.ProficiencyLevel.Beginner ? 2 : 3
                }
            };
        }

        private List<LanguageLesson> GenerateCultureLessons(LanguageLearningSession.ProficiencyLevel level)
        {
            return new List<LanguageLesson>
            {
                new LanguageLesson
                {
                    Title = "Cultural Customs",
                    Description = "Understand traditions and etiquette",
                    Category = LessonCategory.Culture,
                    DifficultyLevel = 2
                },
                new LanguageLesson
                {
                    Title = "Holidays & Celebrations",
                    Description = "Learn about important cultural events",
                    Category = LessonCategory.Culture,
                    DifficultyLevel = 2
                }
            };
        }

        private List<LanguageLesson> GenerateAcademicLessons(LanguageLearningSession.ProficiencyLevel level)
        {
            return new List<LanguageLesson>
            {
                new LanguageLesson
                {
                    Title = "Academic Vocabulary",
                    Description = "Terms for academic contexts",
                    Category = LessonCategory.Vocabulary,
                    DifficultyLevel = 4
                },
                new LanguageLesson
                {
                    Title = "Exam Strategies",
                    Description = "Prepare for language proficiency tests",
                    Category = LessonCategory.Grammar,
                    DifficultyLevel = 4
                }
            };
        }

        private List<LanguageLesson> GenerateInterestLessons(LearningInterest interest, LanguageLearningSession.ProficiencyLevel level)
        {
            return new List<LanguageLesson>
            {
                new LanguageLesson
                {
                    Title = $"{interest.Title} Vocabulary",
                    Description = $"Words and phrases about {interest.Title.ToLowerInvariant()}",
                    Category = LessonCategory.Vocabulary,
                    DifficultyLevel = level == LanguageLearningSession.ProficiencyLevel.Beginner ? 1 : 2
                }
            };
        }

        // Vocabulary Generation
        private async Task<List<VocabularyWord>> GenerateInitialVocabularyAsync(
            LanguageLearningSession.ProficiencyLevel level,
            HashSet<LearningInterest> interests)
        {
            var vocabulary = new List<VocabularyWord>();

            // Essential vocabulary for all levels
            var essential = await GetEssentialVocabularyAsync(level);
            vocabulary.AddRange(essential);

            // Add interest-based vocabulary
            foreach (var interest in interests)
            {
                var interestVocab = await GetInterestVocabularyAsync(interest);
                vocabulary.AddRange(interestVocab);
            }

            return vocabulary;
        }

        private async Task<List<VocabularyWord>> GetEssentialVocabularyAsync(LanguageLearningSession.ProficiencyLevel level)
        {
            if (SelectedLanguage == null) return new List<VocabularyWord>();

            try
            {
                var vocabulary = new List<VocabularyWord>();

                // Generate essential vocabulary
                var essential = await _vocabularyService.GenerateEssentialVocabularyAsync(
                    SelectedLanguage.Name,
                    SelectedLanguage.Code,
                    level,
                    50);
                vocabulary.AddRange(essential);

                // Add goal-specific vocabulary
                if (SelectedGoals.Contains(WizardLearningGoal.Travel))
                {
                    var travel = await _vocabularyService.GenerateTravelVocabularyAsync(
                        SelectedLanguage.Name,
                        SelectedLanguage.Code,
                        level);
                    vocabulary.AddRange(travel);
                }

                if (SelectedGoals.Contains(WizardLearningGoal.Business))
                {
                    var business = await _vocabularyService.GenerateBusinessVocabularyAsync(
                        SelectedLanguage.Name,
                        SelectedLanguage.Code,
                        level);
                    vocabulary.AddRange(business);
                }

                return vocabulary;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to generate vocabulary: {ex}");
                return new List<VocabularyWord>();
            }
        }

        private async Task<List<VocabularyWord>> GetInterestVocabularyAsync(LearningInterest interest)
        {
            if (SelectedLanguage == null || !SelectedProficiency.HasValue)
                return new List<VocabularyWord>();

            try
            {
                return await _vocabularyService.GenerateInterestVocabularyAsync(
                    SelectedLanguage.Name,
                    SelectedLanguage.Code,
                    interest.Title,
                    SelectedProficiency.Value,
                    30);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to generate interest vocabulary: {ex}");
                return new List<VocabularyWord>();
            }
        }

        // Database Integration
        private async Task SaveToDatabaseAsync(LanguageLearningSession session)
        {
            var jsonOptions = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                WriteIndented = false
            };

            var jsonString = JsonSerializer.Serialize(session, jsonOptions);

            var pythonScript = $@"
import json
from hive.models import MoxieDevice, PersistentData

device = MoxieDevice.objects.filter(device_id='moxie_001').first()
if device:
    persist, created = PersistentData.objects.get_or_create(device=device, defaults={{'data': {{}}}})
    data = persist.data or {{}}

    # Initialize language_sessions if it doesn't exist
    if 'language_sessions' not in data:
        data['language_sessions'] = []

    # Add the new session
    session_data = json.loads('''{jsonString}''')
    data['language_sessions'].append(session_data)

    persist.data = data
    persist.save()
    print(f'Language learning session created for {{session_data[""language""]}}')
";

            try
            {
                await _dockerService.ExecutePythonScriptAsync(pythonScript);
                Console.WriteLine("Language learning session saved successfully");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to save session: {ex}");
            }
        }

        private void ScheduleReminders()
        {
            // TODO: Integrate with Windows notifications
            Console.WriteLine("Daily reminders scheduled for language practice");
        }

        private void InitializeAvailableInterests()
        {
            var interests = new[]
            {
                new LearningInterest { Title = "Food & Cooking", Emoji = "🍳" },
                new LearningInterest { Title = "Sports", Emoji = "⚽" },
                new LearningInterest { Title = "Music", Emoji = "🎵" },
                new LearningInterest { Title = "Movies & TV", Emoji = "🎬" },
                new LearningInterest { Title = "Technology", Emoji = "💻" },
                new LearningInterest { Title = "Science", Emoji = "🔬" },
                new LearningInterest { Title = "Art & Design", Emoji = "🎨" },
                new LearningInterest { Title = "Nature & Animals", Emoji = "🌿" },
                new LearningInterest { Title = "History", Emoji = "📜" },
                new LearningInterest { Title = "Fashion", Emoji = "👗" },
                new LearningInterest { Title = "Gaming", Emoji = "🎮" },
                new LearningInterest { Title = "Photography", Emoji = "📸" }
            };

            foreach (var interest in interests)
            {
                AvailableInterests.Add(interest);
            }
        }

        // INotifyPropertyChanged Implementation
        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    // Supporting Models
    public enum WizardLearningGoal
    {
        [Description("Daily Conversation")]
        Conversation,
        [Description("Travel & Tourism")]
        Travel,
        [Description("Business & Professional")]
        Business,
        [Description("Reading & Writing")]
        Reading,
        [Description("Cultural Understanding")]
        Culture,
        [Description("Academic & Exam Prep")]
        Academic
    }

    public class LearningInterest : IEquatable<LearningInterest>
    {
        public Guid Id { get; } = Guid.NewGuid();
        public string Title { get; set; }
        public string Emoji { get; set; }

        public override bool Equals(object obj) => Equals(obj as LearningInterest);
        public bool Equals(LearningInterest other) => other != null && Id.Equals(other.Id);
        public override int GetHashCode() => Id.GetHashCode();
    }

    public enum LessonCategory
    {
        Conversation,
        Vocabulary,
        Grammar,
        Pronunciation,
        Reading,
        Writing,
        Culture
    }

    public class LanguageLesson
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public LessonCategory Category { get; set; }
        public int DifficultyLevel { get; set; }
        public bool IsCompleted { get; set; }
        public DateTime? CompletedDate { get; set; }
    }
}