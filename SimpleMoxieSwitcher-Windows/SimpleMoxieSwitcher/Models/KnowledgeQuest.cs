using System;
using System.Collections.Generic;

namespace SimpleMoxieSwitcher.Models;

/// <summary>
/// Knowledge Quest RPG game system
/// </summary>
public class KnowledgeQuestGame
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string PlayerId { get; set; } = string.Empty;
    public QuestCharacter Character { get; set; } = new();
    public List<Quest> ActiveQuests { get; set; } = new();
    public List<Quest> CompletedQuests { get; set; } = new();
    public KnowledgeMap WorldMap { get; set; } = new();
    public Inventory PlayerInventory { get; set; } = new();
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime LastPlayedAt { get; set; } = DateTime.Now;
}

/// <summary>
/// Player character in Knowledge Quest
/// </summary>
public class QuestCharacter
{
    public string Name { get; set; } = string.Empty;
    public CharacterClass Class { get; set; }
    public int Level { get; set; } = 1;
    public int ExperiencePoints { get; set; }
    public int ExperienceToNextLevel { get; set; } = 100;
    public CharacterStats Stats { get; set; } = new();
    public List<Skill> Skills { get; set; } = new();
    public List<Achievement> Achievements { get; set; } = new();
    public string AvatarUrl { get; set; } = string.Empty;
}

/// <summary>
/// Character classes
/// </summary>
public enum CharacterClass
{
    Scholar,      // Bonus to trivia and knowledge
    Wordsmith,    // Bonus to spelling and language
    Explorer,     // Bonus to discovery and exploration
    Sage,         // Balanced character
    Inventor,     // Bonus to STEM challenges
    Storyteller,  // Bonus to creative challenges
    Detective     // Bonus to logic puzzles
}

/// <summary>
/// Character statistics
/// </summary>
public class CharacterStats
{
    public int Intelligence { get; set; } = 10;
    public int Wisdom { get; set; } = 10;
    public int Creativity { get; set; } = 10;
    public int Knowledge { get; set; } = 10;
    public int Focus { get; set; } = 10;
    public int Curiosity { get; set; } = 10;
}

/// <summary>
/// Character skill
/// </summary>
public class Skill
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int Level { get; set; } = 1;
    public int ExperiencePoints { get; set; }
    public SkillCategory Category { get; set; }
    public List<string> UnlockedAbilities { get; set; } = new();
}

/// <summary>
/// Skill categories
/// </summary>
public enum SkillCategory
{
    Mathematics,
    Science,
    History,
    Language,
    Arts,
    Logic,
    Technology,
    Nature
}

/// <summary>
/// Quest model
/// </summary>
public class Quest
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public QuestType Type { get; set; }
    public int RequiredLevel { get; set; } = 1;
    public List<QuestObjective> Objectives { get; set; } = new();
    public QuestRewards Rewards { get; set; } = new();
    public QuestStatus Status { get; set; } = QuestStatus.NotStarted;
    public DateTime? StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public string StoryText { get; set; } = string.Empty;
    public string CompletionText { get; set; } = string.Empty;
}

/// <summary>
/// Quest types
/// </summary>
public enum QuestType
{
    Main,         // Main story quests
    Side,         // Optional side quests
    Daily,        // Daily challenges
    Tutorial,     // Learning quests
    Boss,         // Major challenges
    Collection,   // Collect items or knowledge
    Exploration   // Explore new areas
}

/// <summary>
/// Quest objective
/// </summary>
public class QuestObjective
{
    public string Description { get; set; } = string.Empty;
    public ObjectiveType Type { get; set; }
    public int RequiredCount { get; set; } = 1;
    public int CurrentCount { get; set; }
    public bool IsCompleted { get; set; }
    public Dictionary<string, object> Parameters { get; set; } = new();
}

/// <summary>
/// Objective types
/// </summary>
public enum ObjectiveType
{
    AnswerQuestions,
    CompleteChallenge,
    CollectItems,
    ReachLocation,
    DefeatBoss,
    LearnSkill,
    AchieveScore,
    SolveRiddle
}

/// <summary>
/// Quest rewards
/// </summary>
public class QuestRewards
{
    public int ExperiencePoints { get; set; }
    public int Gold { get; set; }
    public List<Item> Items { get; set; } = new();
    public List<string> UnlockedSkills { get; set; } = new();
    public List<string> UnlockedAreas { get; set; } = new();
    public string SpecialReward { get; set; } = string.Empty;
}

/// <summary>
/// Quest status
/// </summary>
public enum QuestStatus
{
    NotStarted,
    InProgress,
    Completed,
    Failed,
    Abandoned
}

/// <summary>
/// Knowledge map (game world)
/// </summary>
public class KnowledgeMap
{
    public List<MapArea> Areas { get; set; } = new();
    public MapArea CurrentArea { get; set; } = new();
    public List<string> UnlockedAreaIds { get; set; } = new();
    public Dictionary<string, bool> DiscoveredLocations { get; set; } = new();
}

/// <summary>
/// Map area
/// </summary>
public class MapArea
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public AreaTheme Theme { get; set; }
    public int RequiredLevel { get; set; } = 1;
    public List<Location> Locations { get; set; } = new();
    public List<NPC> NPCs { get; set; } = new();
    public string BackgroundImageUrl { get; set; } = string.Empty;
}

/// <summary>
/// Area themes
/// </summary>
public enum AreaTheme
{
    MathematicalMountains,
    ScienceStation,
    HistoryHalls,
    LanguageLands,
    ArtisticArchipelago,
    LogicLabyrinth,
    TechnoTowers,
    NatureNexus
}

/// <summary>
/// Location within an area
/// </summary>
public class Location
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public LocationType Type { get; set; }
    public List<Challenge> Challenges { get; set; } = new();
    public List<Item> AvailableItems { get; set; } = new();
    public bool IsUnlocked { get; set; }
}

/// <summary>
/// Location types
/// </summary>
public enum LocationType
{
    Town,
    Dungeon,
    Library,
    Laboratory,
    Museum,
    Observatory,
    Workshop,
    Garden
}

/// <summary>
/// Non-player character
/// </summary>
public class NPC
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public NPCRole Role { get; set; }
    public List<string> Dialogue { get; set; } = new();
    public List<Quest> AvailableQuests { get; set; } = new();
    public string ImageUrl { get; set; } = string.Empty;
}

/// <summary>
/// NPC roles
/// </summary>
public enum NPCRole
{
    QuestGiver,
    Merchant,
    Teacher,
    Guardian,
    Helper,
    Boss
}

/// <summary>
/// Challenge (combat/puzzle equivalent)
/// </summary>
public class Challenge
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public ChallengeType Type { get; set; }
    public string Category { get; set; } = string.Empty;
    public int Difficulty { get; set; } = 1;
    public List<Question> Questions { get; set; } = new();
    public ChallengeRewards Rewards { get; set; } = new();
    public int TimeLimit { get; set; } // In seconds, 0 for no limit
    public bool IsCompleted { get; set; }
}

/// <summary>
/// Challenge types
/// </summary>
public enum ChallengeType
{
    Quiz,
    Puzzle,
    BossBattle,
    TimeTrial,
    Survival,
    Collection
}

/// <summary>
/// Question for challenges
/// </summary>
public class Question
{
    public string Text { get; set; } = string.Empty;
    public List<string> Options { get; set; } = new();
    public int CorrectAnswerIndex { get; set; }
    public string Explanation { get; set; } = string.Empty;
    public int Points { get; set; } = 10;
}

/// <summary>
/// Challenge rewards
/// </summary>
public class ChallengeRewards
{
    public int ExperiencePoints { get; set; }
    public int Gold { get; set; }
    public List<Item> Items { get; set; } = new();
}

/// <summary>
/// Player inventory
/// </summary>
public class Inventory
{
    public int Gold { get; set; }
    public List<Item> Items { get; set; } = new();
    public List<Item> EquippedItems { get; set; } = new();
    public int MaxCapacity { get; set; } = 50;
}

/// <summary>
/// Item model
/// </summary>
public class Item
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public ItemType Type { get; set; }
    public ItemRarity Rarity { get; set; }
    public Dictionary<string, int> Stats { get; set; } = new();
    public int Value { get; set; }
    public string IconUrl { get; set; } = string.Empty;
    public bool IsEquippable { get; set; }
    public bool IsConsumable { get; set; }
}

/// <summary>
/// Item types
/// </summary>
public enum ItemType
{
    Equipment,
    Consumable,
    QuestItem,
    Collectible,
    Currency,
    Book,
    Tool
}

/// <summary>
/// Item rarity levels
/// </summary>
public enum ItemRarity
{
    Common,
    Uncommon,
    Rare,
    Epic,
    Legendary
}

/// <summary>
/// Achievement in Knowledge Quest
/// </summary>
public class Achievement
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public AchievementCategory Category { get; set; }
    public int Points { get; set; }
    public string IconUrl { get; set; } = string.Empty;
    public DateTime UnlockedAt { get; set; }
    public double Progress { get; set; } // 0.0 to 1.0
}

/// <summary>
/// Achievement categories
/// </summary>
public enum AchievementCategory
{
    Exploration,
    Combat,
    Collection,
    Knowledge,
    Social,
    Special
}