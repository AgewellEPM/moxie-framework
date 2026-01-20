using System;
using System.Collections.Generic;

namespace SimpleMoxieSwitcher.Models;

/// <summary>
/// Conversation model representing a chat session
/// </summary>
public class Conversation
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string UserId { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public ConversationType Type { get; set; }
    public List<ConversationMessage> Messages { get; set; } = new();
    public DateTime StartedAt { get; set; } = DateTime.Now;
    public DateTime? EndedAt { get; set; }
    public DateTime LastMessageAt { get; set; } = DateTime.Now;
    public string PersonalityUsed { get; set; } = string.Empty;
    public ConversationMetadata Metadata { get; set; } = new();
    public ConversationStatus Status { get; set; } = ConversationStatus.Active;
    public List<string> Participants { get; set; } = new();
    public ConversationSummary Summary { get; set; } = new();
    public List<string> ExtractedMemoryIds { get; set; } = new();
    public Dictionary<string, object> Context { get; set; } = new();
}

/// <summary>
/// Types of conversations
/// </summary>
public enum ConversationType
{
    General,
    Learning,
    Story,
    Game,
    Help,
    Creative,
    Emotional,
    Task,
    Social
}

/// <summary>
/// Conversation status
/// </summary>
public enum ConversationStatus
{
    Active,
    Paused,
    Completed,
    Archived,
    Flagged
}

/// <summary>
/// Conversation metadata
/// </summary>
public class ConversationMetadata
{
    public int MessageCount { get; set; }
    public int WordCount { get; set; }
    public TimeSpan Duration { get; set; }
    public double AverageSentiment { get; set; }
    public List<string> Topics { get; set; } = new();
    public List<string> DetectedLanguages { get; set; } = new();
    public int InteractionCount { get; set; }
    public double EngagementScore { get; set; }
    public Dictionary<string, int> EmotionCounts { get; set; } = new();
}

/// <summary>
/// Conversation summary
/// </summary>
public class ConversationSummary
{
    public string Brief { get; set; } = string.Empty;
    public List<string> KeyPoints { get; set; } = new();
    public List<string> ActionItems { get; set; } = new();
    public List<string> LearnedFacts { get; set; } = new();
    public string Conclusion { get; set; } = string.Empty;
    public DateTime GeneratedAt { get; set; } = DateTime.Now;
}

/// <summary>
/// Conversation turn representing a back-and-forth exchange
/// </summary>
public class ConversationTurn
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public ConversationMessage UserMessage { get; set; } = new();
    public ConversationMessage AssistantMessage { get; set; } = new();
    public TimeSpan ResponseTime { get; set; }
    public TurnMetrics Metrics { get; set; } = new();
}

/// <summary>
/// Metrics for a conversation turn
/// </summary>
public class TurnMetrics
{
    public double Relevance { get; set; } // 0.0 to 1.0
    public double Coherence { get; set; } // 0.0 to 1.0
    public double Helpfulness { get; set; } // 0.0 to 1.0
    public double Creativity { get; set; } // 0.0 to 1.0
    public double Appropriateness { get; set; } // 0.0 to 1.0
}

/// <summary>
/// Conversation context for maintaining state
/// </summary>
public class ConversationContext
{
    public string ConversationId { get; set; } = string.Empty;
    public string CurrentPersonality { get; set; } = string.Empty;
    public List<ConversationMessage> RecentMessages { get; set; } = new();
    public Dictionary<string, object> SessionVariables { get; set; } = new();
    public List<string> ActiveTopics { get; set; } = new();
    public ModeContext ModeContext { get; set; } = new();
    public Dictionary<string, string> UserPreferences { get; set; } = new();
    public EmotionalState EmotionalState { get; set; } = new();
}

/// <summary>
/// Mode context for child/adult modes
/// </summary>
public class ModeContext
{
    public AppMode CurrentMode { get; set; } = AppMode.Child;
    public string ActiveChildProfileId { get; set; } = string.Empty;
    public ContentFilterLevel FilterLevel { get; set; } = ContentFilterLevel.Strict;
    public bool IsParentPresent { get; set; }
    public DateTime? ParentAuthenticatedAt { get; set; }
    public TimeSpan? RemainingTime { get; set; }
}

/// <summary>
/// Application modes
/// </summary>
public enum AppMode
{
    Child,
    Adult,
    Parent,
    Demo
}

/// <summary>
/// Conversation thread for grouped conversations
/// </summary>
public class ConversationThread
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Title { get; set; } = string.Empty;
    public List<Conversation> Conversations { get; set; } = new();
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime LastActivityAt { get; set; } = DateTime.Now;
    public string UserId { get; set; } = string.Empty;
    public ThreadCategory Category { get; set; }
    public bool IsPinned { get; set; }
    public List<string> Tags { get; set; } = new();
}

/// <summary>
/// Thread categories
/// </summary>
public enum ThreadCategory
{
    Daily,
    Learning,
    Creative,
    Games,
    Stories,
    Help,
    General
}

/// <summary>
/// Conversation analytics
/// </summary>
public class ConversationAnalytics
{
    public string UserId { get; set; } = string.Empty;
    public DateTime PeriodStart { get; set; }
    public DateTime PeriodEnd { get; set; }
    public int TotalConversations { get; set; }
    public int TotalMessages { get; set; }
    public TimeSpan TotalDuration { get; set; }
    public double AverageSessionLength { get; set; }
    public Dictionary<ConversationType, int> ConversationsByType { get; set; } = new();
    public Dictionary<string, int> TopicsFrequency { get; set; } = new();
    public List<PeakActivityTime> PeakTimes { get; set; } = new();
    public double EngagementScore { get; set; }
    public double SatisfactionScore { get; set; }
}

/// <summary>
/// Peak activity time
/// </summary>
public class PeakActivityTime
{
    public DayOfWeek Day { get; set; }
    public int Hour { get; set; }
    public int MessageCount { get; set; }
    public double AverageEngagement { get; set; }
}

/// <summary>
/// Conversation export format
/// </summary>
public class ConversationExport
{
    public Conversation Conversation { get; set; } = new();
    public ExportFormat Format { get; set; }
    public bool IncludeMetadata { get; set; }
    public bool IncludeAnalytics { get; set; }
    public string ExportedContent { get; set; } = string.Empty;
    public DateTime ExportedAt { get; set; } = DateTime.Now;
}

/// <summary>
/// Export format types
/// </summary>
public enum ExportFormat
{
    JSON,
    Markdown,
    PDF,
    Text,
    HTML,
    CSV
}

/// <summary>
/// Conversation search parameters
/// </summary>
public class ConversationSearchParams
{
    public string SearchText { get; set; } = string.Empty;
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public List<ConversationType> Types { get; set; } = new();
    public List<string> Personalities { get; set; } = new();
    public List<string> Topics { get; set; } = new();
    public double? MinSentiment { get; set; }
    public double? MaxSentiment { get; set; }
    public int? MinMessageCount { get; set; }
    public ConversationStatus? Status { get; set; }
    public int MaxResults { get; set; } = 100;
    public ConversationSortOrder SortBy { get; set; } = ConversationSortOrder.Recency;
}

/// <summary>
/// Conversation sort order
/// </summary>
public enum ConversationSortOrder
{
    Recency,
    Duration,
    MessageCount,
    Engagement,
    Sentiment
}

/// <summary>
/// Real-time conversation event
/// </summary>
public class ConversationEvent
{
    public string ConversationId { get; set; } = string.Empty;
    public ConversationEventType Type { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.Now;
    public string UserId { get; set; } = string.Empty;
    public Dictionary<string, object> Data { get; set; } = new();
}

/// <summary>
/// Conversation event types
/// </summary>
public enum ConversationEventType
{
    Started,
    MessageSent,
    MessageReceived,
    PersonalityChanged,
    TopicChanged,
    UserJoined,
    UserLeft,
    Paused,
    Resumed,
    Ended,
    Flagged,
    Archived
}

/// <summary>
/// Conversation template for guided conversations
/// </summary>
public class ConversationTemplate
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public ConversationType Type { get; set; }
    public List<string> OpeningMessages { get; set; } = new();
    public List<string> SuggestedTopics { get; set; } = new();
    public List<string> PromptTemplates { get; set; } = new();
    public string RecommendedPersonality { get; set; } = string.Empty;
    public int EstimatedMinutes { get; set; }
    public string Category { get; set; } = string.Empty;
    public bool IsAgeAppropriate { get; set; } = true;
}

/// <summary>
/// Conversation feedback from user
/// </summary>
public class ConversationFeedback
{
    public string ConversationId { get; set; } = string.Empty;
    public int Rating { get; set; } // 1-5 stars
    public string Comment { get; set; } = string.Empty;
    public List<FeedbackTag> Tags { get; set; } = new();
    public DateTime ProvidedAt { get; set; } = DateTime.Now;
    public string UserId { get; set; } = string.Empty;
}

/// <summary>
/// Feedback tags
/// </summary>
public enum FeedbackTag
{
    Helpful,
    Engaging,
    Educational,
    Fun,
    Confusing,
    Inappropriate,
    Repetitive,
    TooSimple,
    TooComplex,
    Boring
}