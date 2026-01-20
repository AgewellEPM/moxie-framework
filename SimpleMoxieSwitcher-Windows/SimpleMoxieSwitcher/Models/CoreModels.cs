using Microsoft.UI.Xaml.Media;
using System;
using System.Collections.Generic;

namespace SimpleMoxieSwitcher.Models;

// Tile interfaces and implementations
public interface ITileItem
{
    string Id { get; }
    string DisplayName { get; }
    string Emoji { get; }
    int EmojiSize { get; }
    Brush BackgroundBrush { get; }
}

public class FeatureTile : ITileItem
{
    public string Id { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Emoji { get; set; } = string.Empty;
    public int EmojiSize { get; set; } = 50;
    public Brush BackgroundBrush { get; set; } = null!;
}

public class LearningTile : ITileItem
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string DisplayName { get; set; } = string.Empty;
    public string Emoji { get; set; } = "🧠";
    public int EmojiSize => 50;
    public Brush BackgroundBrush { get; set; } = null!;
    public string Topic { get; set; } = string.Empty;
    public string Difficulty { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public Dictionary<string, object> SessionData { get; set; } = new();
}

public class StoryTile : ITileItem
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string DisplayName { get; set; } = string.Empty;
    public string Emoji { get; set; } = "📚";
    public int EmojiSize => 50;
    public Brush BackgroundBrush { get; set; } = null!;
    public string Genre { get; set; } = string.Empty;
    public string Synopsis { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public Dictionary<string, object> StoryData { get; set; } = new();
}

// Language model
public class Language
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Flag { get; set; } = string.Empty;

    public static readonly List<Language> AllLanguages = new()
    {
        new() { Code = "en", Name = "English", Flag = "🇺🇸" },
        new() { Code = "es", Name = "Spanish", Flag = "🇪🇸" },
        new() { Code = "fr", Name = "French", Flag = "🇫🇷" },
        new() { Code = "de", Name = "German", Flag = "🇩🇪" },
        new() { Code = "it", Name = "Italian", Flag = "🇮🇹" },
        new() { Code = "pt", Name = "Portuguese", Flag = "🇵🇹" },
        new() { Code = "ru", Name = "Russian", Flag = "🇷🇺" },
        new() { Code = "ja", Name = "Japanese", Flag = "🇯🇵" },
        new() { Code = "ko", Name = "Korean", Flag = "🇰🇷" },
        new() { Code = "zh", Name = "Chinese", Flag = "🇨🇳" }
    };
}

// AI Settings
public class AISettings
{
    public string Provider { get; set; } = "openai";
    public string Model { get; set; } = "gpt-3.5-turbo";
    public double Temperature { get; set; } = 0.7;
    public int MaxTokens { get; set; } = 150;
    public double TopP { get; set; } = 1.0;
    public double FrequencyPenalty { get; set; } = 0.0;
    public double PresencePenalty { get; set; } = 0.0;
}

// Child Profile
public class ChildProfile
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public int Age { get; set; }
    public string Interests { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public ContentFilterLevel FilterLevel { get; set; } = ContentFilterLevel.Strict;
    public Dictionary<string, object> Preferences { get; set; } = new();
}

// Content Filter
public enum ContentFilterLevel
{
    Off,
    Minimal,
    Moderate,
    Strict
}

// Safety Log
public class SafetyLogEntry
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string UserId { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public bool WasFlagged { get; set; }
    public List<string> FlaggedWords { get; set; } = new();
    public DateTime Timestamp { get; set; } = DateTime.Now;
}

// Parent Notification
public class ParentNotification
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public NotificationPriority Priority { get; set; }
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;
}

public enum NotificationPriority
{
    Low,
    Medium,
    High,
    Critical
}

public class NotificationPreferences
{
    public bool EmailEnabled { get; set; }
    public bool InAppEnabled { get; set; } = true;
    public string EmailAddress { get; set; } = string.Empty;
    public NotificationPriority MinimumPriority { get; set; } = NotificationPriority.Medium;
}

// Conversation
public class ConversationLog
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string UserId { get; set; } = string.Empty;
    public string PersonalityUsed { get; set; } = string.Empty;
    public List<ConversationMessage> Messages { get; set; } = new();
    public DateTime StartTime { get; set; } = DateTime.Now;
    public DateTime? EndTime { get; set; }
    public Dictionary<string, object> Metadata { get; set; } = new();
}

public class ConversationMessage
{
    public string Role { get; set; } = string.Empty; // "user" or "assistant"
    public string Content { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.Now;
}

public class ConversationEventArgs : EventArgs
{
    public string Topic { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.Now;
}

// Memory
public class Memory
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Content { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public double Importance { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public Dictionary<string, object> Context { get; set; } = new();
}

// Games
public class TriviaQuestion
{
    public string Question { get; set; } = string.Empty;
    public List<string> Options { get; set; } = new();
    public int CorrectAnswerIndex { get; set; }
    public string Explanation { get; set; } = string.Empty;
    public string Difficulty { get; set; } = string.Empty;
    public string Topic { get; set; } = string.Empty;
}

public class SpellingChallenge
{
    public string Word { get; set; } = string.Empty;
    public string AudioUrl { get; set; } = string.Empty;
    public string Definition { get; set; } = string.Empty;
    public int GradeLevel { get; set; }
}

public class MathProblem
{
    public string Problem { get; set; } = string.Empty;
    public double Answer { get; set; }
    public string Solution { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public int Difficulty { get; set; }
}

public class StoryPrompt
{
    public string Title { get; set; } = string.Empty;
    public string OpeningLine { get; set; } = string.Empty;
    public List<string> Characters { get; set; } = new();
    public string Setting { get; set; } = string.Empty;
    public string Genre { get; set; } = string.Empty;
}

// Vocabulary
public class VocabularyWord
{
    public string Word { get; set; } = string.Empty;
    public string Language { get; set; } = string.Empty;
    public string Translation { get; set; } = string.Empty;
    public string Definition { get; set; } = string.Empty;
    public string PartOfSpeech { get; set; } = string.Empty;
    public List<string> ExampleSentences { get; set; } = new();
    public string Pronunciation { get; set; } = string.Empty;
}

// Parent Account
public class ParentAccount
{
    public string Email { get; set; } = string.Empty;
    public string SecurityQuestion { get; set; } = string.Empty;
    public string SecurityAnswerHash { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.Now;
}