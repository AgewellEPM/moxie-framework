using System;
using System.Collections.Generic;

namespace SimpleMoxieSwitcher.Models;

/// <summary>
/// Language learning session model
/// </summary>
public class LanguageLearningSession
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string UserId { get; set; } = string.Empty;
    public string TargetLanguage { get; set; } = string.Empty;
    public string SourceLanguage { get; set; } = "English";
    public LessonType Type { get; set; }
    public ProficiencyLevel Level { get; set; }
    public DateTime StartedAt { get; set; } = DateTime.Now;
    public DateTime? CompletedAt { get; set; }
    public List<LessonModule> Modules { get; set; } = new();
    public SessionProgress Progress { get; set; } = new();
    public List<VocabularyWord> LearnedWords { get; set; } = new();
    public List<Grammar> LearnedGrammar { get; set; } = new();
    public double CompletionRate { get; set; }
    public int StreakDays { get; set; }
}

/// <summary>
/// Lesson types
/// </summary>
public enum LessonType
{
    Vocabulary,
    Grammar,
    Conversation,
    Pronunciation,
    Reading,
    Writing,
    Listening,
    Culture,
    Mixed
}

/// <summary>
/// Proficiency levels
/// </summary>
public enum ProficiencyLevel
{
    Beginner,
    Elementary,
    PreIntermediate,
    Intermediate,
    UpperIntermediate,
    Advanced,
    Fluent
}

/// <summary>
/// Lesson module within a session
/// </summary>
public class LessonModule
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public ModuleType Type { get; set; }
    public List<Exercise> Exercises { get; set; } = new();
    public int EstimatedMinutes { get; set; }
    public bool IsCompleted { get; set; }
    public double Score { get; set; }
}

/// <summary>
/// Module types
/// </summary>
public enum ModuleType
{
    Introduction,
    Practice,
    Review,
    Quiz,
    Game,
    Conversation,
    Story
}

/// <summary>
/// Exercise within a module
/// </summary>
public class Exercise
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public ExerciseType Type { get; set; }
    public string Instructions { get; set; } = string.Empty;
    public string Question { get; set; } = string.Empty;
    public List<string> Options { get; set; } = new();
    public string CorrectAnswer { get; set; } = string.Empty;
    public string UserAnswer { get; set; } = string.Empty;
    public bool IsCorrect { get; set; }
    public string Explanation { get; set; } = string.Empty;
    public string AudioUrl { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public int Points { get; set; } = 10;
}

/// <summary>
/// Exercise types
/// </summary>
public enum ExerciseType
{
    MultipleChoice,
    FillInBlank,
    Translation,
    Matching,
    Speaking,
    Listening,
    Writing,
    Reordering,
    TrueFalse,
    Flashcard
}

/// <summary>
/// Session progress tracker
/// </summary>
public class SessionProgress
{
    public int TotalExercises { get; set; }
    public int CompletedExercises { get; set; }
    public int CorrectAnswers { get; set; }
    public double Accuracy { get; set; }
    public TimeSpan TimeSpent { get; set; }
    public int PointsEarned { get; set; }
    public int ExperienceGained { get; set; }
    public List<string> UnlockedAchievements { get; set; } = new();
}

/// <summary>
/// Grammar concept
/// </summary>
public class Grammar
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Concept { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty; // Tense, Article, Pronoun, etc.
    public string Explanation { get; set; } = string.Empty;
    public List<GrammarRule> Rules { get; set; } = new();
    public List<string> Examples { get; set; } = new();
    public List<string> CommonMistakes { get; set; } = new();
    public ProficiencyLevel Level { get; set; }
}

/// <summary>
/// Grammar rule
/// </summary>
public class GrammarRule
{
    public string Description { get; set; } = string.Empty;
    public string Pattern { get; set; } = string.Empty;
    public List<string> Examples { get; set; } = new();
    public List<string> Exceptions { get; set; } = new();
}

/// <summary>
/// Language course
/// </summary>
public class LanguageCourse
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Language { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public ProficiencyLevel Level { get; set; }
    public List<CourseUnit> Units { get; set; } = new();
    public int TotalHours { get; set; }
    public string InstructorName { get; set; } = string.Empty;
    public double Rating { get; set; }
    public bool IsPremium { get; set; }
}

/// <summary>
/// Course unit
/// </summary>
public class CourseUnit
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public int Number { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Topic { get; set; } = string.Empty;
    public List<LanguageLearningSession> Lessons { get; set; } = new();
    public bool IsUnlocked { get; set; }
    public bool IsCompleted { get; set; }
    public double Progress { get; set; }
}

/// <summary>
/// Conversation practice
/// </summary>
public class ConversationPractice
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Scenario { get; set; } = string.Empty; // Restaurant, Airport, Shopping, etc.
    public string TargetLanguage { get; set; } = string.Empty;
    public ProficiencyLevel Level { get; set; }
    public List<DialogueLine> Dialogue { get; set; } = new();
    public List<string> KeyPhrases { get; set; } = new();
    public List<string> CulturalNotes { get; set; } = new();
    public int EstimatedMinutes { get; set; } = 10;
}

/// <summary>
/// Dialogue line in conversation
/// </summary>
public class DialogueLine
{
    public string Speaker { get; set; } = string.Empty; // User, AI, NPC
    public string Text { get; set; } = string.Empty;
    public string Translation { get; set; } = string.Empty;
    public string AudioUrl { get; set; } = string.Empty;
    public List<string> AlternativeResponses { get; set; } = new();
    public string GrammarNote { get; set; } = string.Empty;
}

/// <summary>
/// Pronunciation practice
/// </summary>
public class PronunciationPractice
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Word { get; set; } = string.Empty;
    public string Phonetic { get; set; } = string.Empty; // IPA notation
    public string AudioUrl { get; set; } = string.Empty;
    public List<string> CommonMistakes { get; set; } = new();
    public string TonguePlacement { get; set; } = string.Empty;
    public List<string> SimilarWords { get; set; } = new();
    public double UserScore { get; set; }
    public string RecordedAudioUrl { get; set; } = string.Empty;
}

/// <summary>
/// Language learner profile
/// </summary>
public class LanguageLearnerProfile
{
    public string UserId { get; set; } = string.Empty;
    public Dictionary<string, LanguageProgress> Languages { get; set; } = new();
    public List<string> NativeLanguages { get; set; } = new();
    public LearningGoals Goals { get; set; } = new();
    public LearningPreferences Preferences { get; set; } = new();
    public List<LanguageAchievement> Achievements { get; set; } = new();
    public int TotalLearningDays { get; set; }
    public int CurrentStreak { get; set; }
    public int LongestStreak { get; set; }
    public DateTime LastPracticeDate { get; set; }
}

/// <summary>
/// Progress in a specific language
/// </summary>
public class LanguageProgress
{
    public string Language { get; set; } = string.Empty;
    public ProficiencyLevel CurrentLevel { get; set; }
    public double ProgressToNextLevel { get; set; } // 0.0 to 1.0
    public int TotalWordsLearned { get; set; }
    public int TotalLessonsCompleted { get; set; }
    public TimeSpan TotalTimeSpent { get; set; }
    public Dictionary<string, SkillProgress> Skills { get; set; } = new();
    public List<string> CompletedCourseIds { get; set; } = new();
}

/// <summary>
/// Progress in a specific skill
/// </summary>
public class SkillProgress
{
    public string SkillName { get; set; } = string.Empty; // Speaking, Listening, Reading, Writing
    public int Level { get; set; } = 1;
    public double Progress { get; set; } // 0.0 to 1.0
    public int ExercisesCompleted { get; set; }
    public double AverageScore { get; set; }
}

/// <summary>
/// Learning goals
/// </summary>
public class LearningGoals
{
    public string PrimaryGoal { get; set; } = string.Empty; // Travel, Business, Education, Culture
    public int MinutesPerDay { get; set; } = 15;
    public int DaysPerWeek { get; set; } = 5;
    public DateTime TargetDate { get; set; }
    public ProficiencyLevel TargetLevel { get; set; }
}

/// <summary>
/// Learning preferences
/// </summary>
public class LearningPreferences
{
    public bool EnableSpeaking { get; set; } = true;
    public bool EnableListening { get; set; } = true;
    public bool EnableGrammarFocus { get; set; } = true;
    public bool EnableGamification { get; set; } = true;
    public string PreferredTime { get; set; } = "Morning"; // Morning, Afternoon, Evening
    public bool EnableReminders { get; set; } = true;
    public int ReminderHour { get; set; } = 9;
}

/// <summary>
/// Language learning achievement
/// </summary>
public class LanguageAchievement
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Language { get; set; } = string.Empty;
    public string BadgeUrl { get; set; } = string.Empty;
    public DateTime EarnedAt { get; set; }
    public int Points { get; set; }
}

/// <summary>
/// Flashcard for vocabulary practice
/// </summary>
public class Flashcard
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Front { get; set; } = string.Empty; // Word or phrase
    public string Back { get; set; } = string.Empty; // Translation or definition
    public string Language { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public string AudioUrl { get; set; } = string.Empty;
    public string Context { get; set; } = string.Empty;
    public int ReviewCount { get; set; }
    public DateTime LastReviewed { get; set; }
    public double MemoryStrength { get; set; } // 0.0 to 1.0
    public DateTime NextReviewDate { get; set; }
}

/// <summary>
/// Spaced repetition system for flashcards
/// </summary>
public class SpacedRepetitionData
{
    public string CardId { get; set; } = string.Empty;
    public int Interval { get; set; } = 1; // Days until next review
    public double EaseFactor { get; set; } = 2.5; // Difficulty multiplier
    public int RepetitionNumber { get; set; }
    public DateTime LastReviewDate { get; set; }
    public PerformanceRating LastRating { get; set; }
}

/// <summary>
/// Performance rating for spaced repetition
/// </summary>
public enum PerformanceRating
{
    Again = 0,
    Hard = 1,
    Good = 2,
    Easy = 3
}