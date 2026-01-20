using System;
using System.Collections.Generic;
using System.Linq;

namespace SimpleMoxieSwitcher.Models
{
    /// <summary>
    /// Represents a knowledge-based RPG adventure with Moxie as Game Master
    /// </summary>
    public class KnowledgeQuest
    {
        public string Id { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public QuestTheme Theme { get; set; }
        public Difficulty Difficulty { get; set; }
        public List<Chapter> Chapters { get; set; }
        public int CurrentChapterIndex { get; set; }
        public PlayerStats PlayerStats { get; set; }
        public List<string> Inventory { get; set; }
        public bool IsCompleted { get; set; }
        public DateTime CreatedAt { get; set; }

        public enum QuestTheme
        {
            Science,
            History,
            Math,
            Geography,
            Literature,
            Nature,
            Space,
            Ocean
        }

        public enum Difficulty
        {
            Easy,
            Medium,
            Hard,
            Expert
        }

        public KnowledgeQuest(string title, QuestTheme theme, Difficulty difficulty)
        {
            Id = Guid.NewGuid().ToString();
            Title = title;
            Description = GetThemeDescription(theme);
            Theme = theme;
            Difficulty = difficulty;
            Chapters = new List<Chapter>();
            CurrentChapterIndex = 0;
            PlayerStats = new PlayerStats();
            Inventory = new List<string>();
            IsCompleted = false;
            CreatedAt = DateTime.Now;
        }

        public Chapter CurrentChapter =>
            CurrentChapterIndex < Chapters.Count ? Chapters[CurrentChapterIndex] : null;

        public double Progress =>
            Chapters.Count == 0 ? 0 : (double)CurrentChapterIndex / Chapters.Count;

        public static string GetThemeIcon(QuestTheme theme)
        {
            switch (theme)
            {
                case QuestTheme.Science: return "🔬";
                case QuestTheme.History: return "🏛️";
                case QuestTheme.Math: return "🔢";
                case QuestTheme.Geography: return "🗺️";
                case QuestTheme.Literature: return "📖";
                case QuestTheme.Nature: return "🌳";
                case QuestTheme.Space: return "🚀";
                case QuestTheme.Ocean: return "🌊";
                default: return "❓";
            }
        }

        public static string GetThemeDescription(QuestTheme theme)
        {
            switch (theme)
            {
                case QuestTheme.Science:
                    return "Dr. Moxie needs your help in the Science Lab to solve mysterious experiments!";
                case QuestTheme.History:
                    return "Travel through time with Moxie to uncover historical secrets!";
                case QuestTheme.Math:
                    return "Help Detective Moxie solve mathematical puzzles to crack the case!";
                case QuestTheme.Geography:
                    return "Explore the world with Explorer Moxie and discover new lands!";
                case QuestTheme.Literature:
                    return "Journey through magical story worlds with Librarian Moxie!";
                case QuestTheme.Nature:
                    return "Join Ranger Moxie on an adventure through the wilderness!";
                case QuestTheme.Space:
                    return "Blast off with Astronaut Moxie to explore the cosmos!";
                case QuestTheme.Ocean:
                    return "Dive deep with Captain Moxie to discover ocean mysteries!";
                default:
                    return "Adventure awaits!";
            }
        }

        public static int GetSkillCheckDifficulty(Difficulty difficulty)
        {
            switch (difficulty)
            {
                case Difficulty.Easy: return 5;
                case Difficulty.Medium: return 10;
                case Difficulty.Hard: return 15;
                case Difficulty.Expert: return 20;
                default: return 10;
            }
        }
    }

    /// <summary>
    /// Chapter in a Knowledge Quest
    /// </summary>
    public class Chapter
    {
        public string Id { get; set; }
        public string Title { get; set; }
        public string StoryText { get; set; }
        public string Location { get; set; }
        public List<Encounter> Encounters { get; set; }
        public int CurrentEncounterIndex { get; set; }
        public bool IsCompleted { get; set; }

        public Chapter(string title, string storyText, string location)
        {
            Id = Guid.NewGuid().ToString();
            Title = title;
            StoryText = storyText;
            Location = location;
            Encounters = new List<Encounter>();
            CurrentEncounterIndex = 0;
            IsCompleted = false;
        }

        public Encounter CurrentEncounter =>
            CurrentEncounterIndex < Encounters.Count ? Encounters[CurrentEncounterIndex] : null;
    }

    /// <summary>
    /// Encounter in a chapter
    /// </summary>
    public class Encounter
    {
        public string Id { get; set; }
        public EncounterType Type { get; set; }
        public string Description { get; set; }
        public Challenge Challenge { get; set; }
        public bool IsCompleted { get; set; }
        public bool? WasSuccessful { get; set; }

        public enum EncounterType
        {
            Obstacle,
            Puzzle,
            Riddle,
            Discovery,
            Conversation
        }

        public Encounter(EncounterType type, string description, Challenge challenge)
        {
            Id = Guid.NewGuid().ToString();
            Type = type;
            Description = description;
            Challenge = challenge;
            IsCompleted = false;
        }

        public static string GetEncounterIcon(EncounterType type)
        {
            switch (type)
            {
                case EncounterType.Obstacle: return "⚡";
                case EncounterType.Puzzle: return "🧩";
                case EncounterType.Riddle: return "❓";
                case EncounterType.Discovery: return "💎";
                case EncounterType.Conversation: return "💬";
                default: return "❓";
            }
        }
    }

    /// <summary>
    /// Challenge within an encounter
    /// </summary>
    public class Challenge
    {
        public string Question { get; set; }
        public string KnowledgeArea { get; set; }
        public string SkillRequired { get; set; }
        public List<string> Options { get; set; }
        public int CorrectAnswer { get; set; }
        public string SuccessOutcome { get; set; }
        public string FailureOutcome { get; set; }
        public string Hint { get; set; }
        public int? UserAnswer { get; set; }

        public bool? IsCorrect =>
            UserAnswer.HasValue ? UserAnswer == CorrectAnswer : (bool?)null;

        public int ExperienceReward =>
            IsCorrect == true ? 50 : 10;

        public Challenge(string question, string knowledgeArea, string skillRequired,
            List<string> options, int correctAnswer, string successOutcome,
            string failureOutcome, string hint = null)
        {
            Question = question;
            KnowledgeArea = knowledgeArea;
            SkillRequired = skillRequired;
            Options = options;
            CorrectAnswer = correctAnswer;
            SuccessOutcome = successOutcome;
            FailureOutcome = failureOutcome;
            Hint = hint;
        }
    }

    /// <summary>
    /// Player statistics
    /// </summary>
    public class PlayerStats
    {
        public int Level { get; set; }
        public int Experience { get; set; }
        public int Health { get; set; }
        public int MaxHealth { get; set; }
        public int Knowledge { get; set; }
        public int Wisdom { get; set; }
        public int Creativity { get; set; }

        public PlayerStats()
        {
            Level = 1;
            Experience = 0;
            Health = 100;
            MaxHealth = 100;
            Knowledge = 10;
            Wisdom = 10;
            Creativity = 10;
        }

        public int ExperienceToNextLevel => Level * 100;

        public void GainExperience(int amount)
        {
            Experience += amount;
            CheckLevelUp();
        }

        private void CheckLevelUp()
        {
            while (Experience >= ExperienceToNextLevel)
            {
                LevelUp();
            }
        }

        private void LevelUp()
        {
            Level++;
            MaxHealth += 20;
            Health = MaxHealth;
            Knowledge += 2;
            Wisdom += 2;
            Creativity += 2;
        }

        public void TakeDamage(int amount)
        {
            Health = Math.Max(0, Health - amount);
        }

        public void Heal(int amount)
        {
            Health = Math.Min(MaxHealth, Health + amount);
        }
    }

    /// <summary>
    /// Quest progress tracking
    /// </summary>
    public class QuestProgress
    {
        public int TotalQuestsCompleted { get; set; }
        public int TotalChallengesCompleted { get; set; }
        public int TotalExperienceEarned { get; set; }
        public int HighestLevel { get; set; }
        public HashSet<string> KnowledgeAreasExplored { get; set; }
        public List<QuestAchievement> Achievements { get; set; }

        public QuestProgress()
        {
            TotalQuestsCompleted = 0;
            TotalChallengesCompleted = 0;
            TotalExperienceEarned = 0;
            HighestLevel = 1;
            KnowledgeAreasExplored = new HashSet<string>();
            Achievements = new List<QuestAchievement>();
        }

        public void RecordQuestCompletion(KnowledgeQuest quest)
        {
            TotalQuestsCompleted++;
            HighestLevel = Math.Max(HighestLevel, quest.PlayerStats.Level);
            TotalExperienceEarned += quest.PlayerStats.Experience;

            // Track knowledge areas
            foreach (var chapter in quest.Chapters)
            {
                foreach (var encounter in chapter.Encounters)
                {
                    KnowledgeAreasExplored.Add(encounter.Challenge.KnowledgeArea);
                }
            }

            CheckAchievements();
        }

        private void CheckAchievements()
        {
            if (TotalQuestsCompleted == 1 && !HasAchievement("first_quest"))
            {
                Achievements.Add(new QuestAchievement(
                    "first_quest",
                    "Adventurer",
                    "Completed your first Knowledge Quest!",
                    "🗡️"
                ));
            }

            if (TotalQuestsCompleted >= 5 && !HasAchievement("veteran"))
            {
                Achievements.Add(new QuestAchievement(
                    "veteran",
                    "Veteran Quester",
                    "Completed 5 Knowledge Quests!",
                    "🏆"
                ));
            }

            if (KnowledgeAreasExplored.Count >= 5 && !HasAchievement("scholar"))
            {
                Achievements.Add(new QuestAchievement(
                    "scholar",
                    "Scholar",
                    "Explored 5 different knowledge areas!",
                    "📚"
                ));
            }

            if (HighestLevel >= 5 && !HasAchievement("master"))
            {
                Achievements.Add(new QuestAchievement(
                    "master",
                    "Knowledge Master",
                    "Reached level 5!",
                    "🌟"
                ));
            }
        }

        private bool HasAchievement(string id)
        {
            return Achievements.Any(a => a.Id == id);
        }
    }

    public class QuestAchievement
    {
        public string Id { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string Icon { get; set; }
        public DateTime UnlockedAt { get; set; }

        public QuestAchievement(string id, string title, string description, string icon)
        {
            Id = id;
            Title = title;
            Description = description;
            Icon = icon;
            UnlockedAt = DateTime.Now;
        }
    }

    /// <summary>
    /// Quest template helper for generating quests
    /// </summary>
    public class QuestTemplate
    {
        public KnowledgeQuest.QuestTheme Theme { get; set; }
        public List<string> ChapterTitles { get; set; }
        public List<string> Locations { get; set; }
        public List<Encounter.EncounterType> EncounterTypes { get; set; }

        public static QuestTemplate GetTemplate(KnowledgeQuest.QuestTheme theme)
        {
            switch (theme)
            {
                case KnowledgeQuest.QuestTheme.Science:
                    return new QuestTemplate
                    {
                        Theme = KnowledgeQuest.QuestTheme.Science,
                        ChapterTitles = new List<string> { "The Mysterious Lab", "Chemical Reactions", "The Final Experiment" },
                        Locations = new List<string> { "Science Laboratory", "Testing Chamber", "Research Library" },
                        EncounterTypes = new List<Encounter.EncounterType> { Encounter.EncounterType.Puzzle, Encounter.EncounterType.Discovery, Encounter.EncounterType.Obstacle }
                    };
                case KnowledgeQuest.QuestTheme.History:
                    return new QuestTemplate
                    {
                        Theme = KnowledgeQuest.QuestTheme.History,
                        ChapterTitles = new List<string> { "Ancient Civilizations", "Medieval Times", "Modern Era" },
                        Locations = new List<string> { "Ancient Temple", "Castle Keep", "Modern Museum" },
                        EncounterTypes = new List<Encounter.EncounterType> { Encounter.EncounterType.Conversation, Encounter.EncounterType.Riddle, Encounter.EncounterType.Discovery }
                    };
                case KnowledgeQuest.QuestTheme.Math:
                    return new QuestTemplate
                    {
                        Theme = KnowledgeQuest.QuestTheme.Math,
                        ChapterTitles = new List<string> { "Number Mystery", "Geometric Patterns", "The Final Equation" },
                        Locations = new List<string> { "Number Kingdom", "Shape Valley", "Equation Tower" },
                        EncounterTypes = new List<Encounter.EncounterType> { Encounter.EncounterType.Puzzle, Encounter.EncounterType.Obstacle, Encounter.EncounterType.Riddle }
                    };
                case KnowledgeQuest.QuestTheme.Geography:
                    return new QuestTemplate
                    {
                        Theme = KnowledgeQuest.QuestTheme.Geography,
                        ChapterTitles = new List<string> { "Continental Journey", "Island Discovery", "Mountain Peak" },
                        Locations = new List<string> { "World Map Room", "Tropical Island", "Summit Vista" },
                        EncounterTypes = new List<Encounter.EncounterType> { Encounter.EncounterType.Discovery, Encounter.EncounterType.Conversation, Encounter.EncounterType.Puzzle }
                    };
                case KnowledgeQuest.QuestTheme.Literature:
                    return new QuestTemplate
                    {
                        Theme = KnowledgeQuest.QuestTheme.Literature,
                        ChapterTitles = new List<string> { "Story Beginning", "Plot Twist", "Grand Finale" },
                        Locations = new List<string> { "Enchanted Library", "Story Forest", "Chapter Castle" },
                        EncounterTypes = new List<Encounter.EncounterType> { Encounter.EncounterType.Riddle, Encounter.EncounterType.Conversation, Encounter.EncounterType.Discovery }
                    };
                case KnowledgeQuest.QuestTheme.Nature:
                    return new QuestTemplate
                    {
                        Theme = KnowledgeQuest.QuestTheme.Nature,
                        ChapterTitles = new List<string> { "Forest Entrance", "Wildlife Wonder", "Nature's Balance" },
                        Locations = new List<string> { "Dense Forest", "Animal Haven", "Ecosystem Peak" },
                        EncounterTypes = new List<Encounter.EncounterType> { Encounter.EncounterType.Discovery, Encounter.EncounterType.Puzzle, Encounter.EncounterType.Conversation }
                    };
                case KnowledgeQuest.QuestTheme.Space:
                    return new QuestTemplate
                    {
                        Theme = KnowledgeQuest.QuestTheme.Space,
                        ChapterTitles = new List<string> { "Launch Sequence", "Orbit Adventure", "Stellar Discovery" },
                        Locations = new List<string> { "Space Station", "Asteroid Field", "Distant Planet" },
                        EncounterTypes = new List<Encounter.EncounterType> { Encounter.EncounterType.Puzzle, Encounter.EncounterType.Discovery, Encounter.EncounterType.Obstacle }
                    };
                case KnowledgeQuest.QuestTheme.Ocean:
                    return new QuestTemplate
                    {
                        Theme = KnowledgeQuest.QuestTheme.Ocean,
                        ChapterTitles = new List<string> { "Shallow Waters", "Deep Dive", "Ocean Floor" },
                        Locations = new List<string> { "Coral Reef", "Kelp Forest", "Trench Depths" },
                        EncounterTypes = new List<Encounter.EncounterType> { Encounter.EncounterType.Discovery, Encounter.EncounterType.Conversation, Encounter.EncounterType.Puzzle }
                    };
                default:
                    return new QuestTemplate
                    {
                        Theme = theme,
                        ChapterTitles = new List<string> { "Chapter 1", "Chapter 2", "Chapter 3" },
                        Locations = new List<string> { "Location 1", "Location 2", "Location 3" },
                        EncounterTypes = new List<Encounter.EncounterType> { Encounter.EncounterType.Puzzle, Encounter.EncounterType.Discovery, Encounter.EncounterType.Conversation }
                    };
            }
        }
    }
}