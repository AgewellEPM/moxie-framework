using System;
using System.Collections.Generic;

namespace SimpleMoxieSwitcher.Models;

/// <summary>
/// Content flag for inappropriate content detection
/// </summary>
public class ContentFlag
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string SessionId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.Now;
    public string Content { get; set; } = string.Empty;
    public FlagType Type { get; set; }
    public FlagSeverity Severity { get; set; }
    public string Reason { get; set; } = string.Empty;
    public List<string> DetectedKeywords { get; set; } = new();
    public double ConfidenceScore { get; set; }
    public bool WasBlocked { get; set; }
    public string ActionTaken { get; set; } = string.Empty;
    public bool ParentNotified { get; set; }
}

/// <summary>
/// Types of content flags
/// </summary>
public enum FlagType
{
    InappropriateLanguage,
    Violence,
    AdultContent,
    Bullying,
    PersonalInformation,
    DangerousBehavior,
    Harassment,
    HateSpeech,
    SelfHarm,
    Spam,
    Other
}

/// <summary>
/// Severity levels for content flags
/// </summary>
public enum FlagSeverity
{
    Low,      // Minor concern, logged only
    Medium,   // Moderate concern, content modified
    High,     // Serious concern, content blocked
    Critical  // Immediate intervention required
}

/// <summary>
/// Sentiment analysis result
/// </summary>
public class SentimentAnalysis
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string ConversationId { get; set; } = string.Empty;
    public string Text { get; set; } = string.Empty;
    public SentimentType Sentiment { get; set; }
    public double PositiveScore { get; set; }
    public double NegativeScore { get; set; }
    public double NeutralScore { get; set; }
    public List<EmotionScore> Emotions { get; set; } = new();
    public DateTime AnalyzedAt { get; set; } = DateTime.Now;
}

/// <summary>
/// Types of sentiment
/// </summary>
public enum SentimentType
{
    VeryPositive,
    Positive,
    Neutral,
    Negative,
    VeryNegative,
    Mixed
}

/// <summary>
/// Emotion detection score
/// </summary>
public class EmotionScore
{
    public EmotionType Emotion { get; set; }
    public double Score { get; set; } // 0.0 to 1.0
}

/// <summary>
/// Types of emotions
/// </summary>
public enum EmotionType
{
    Joy,
    Sadness,
    Anger,
    Fear,
    Surprise,
    Disgust,
    Trust,
    Anticipation,
    Love,
    Confusion,
    Frustration,
    Excitement
}

/// <summary>
/// Safety activity event for monitoring
/// </summary>
public class ActivityEvent
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string UserId { get; set; } = string.Empty;
    public EventType Type { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.Now;
    public Dictionary<string, object> Metadata { get; set; } = new();
    public string IpAddress { get; set; } = string.Empty;
    public string DeviceInfo { get; set; } = string.Empty;
}

/// <summary>
/// Types of activity events
/// </summary>
public enum EventType
{
    Login,
    Logout,
    ModeSwitch,
    PersonalityChange,
    GameStart,
    GameEnd,
    ConversationStart,
    ConversationEnd,
    ContentFlagged,
    ParentAccess,
    SettingsChanged,
    ProfileUpdated,
    AchievementUnlocked,
    ErrorOccurred
}

/// <summary>
/// Content filter configuration
/// </summary>
public class ContentFilterConfig
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string ProfileId { get; set; } = string.Empty;
    public ContentFilterLevel FilterLevel { get; set; } = ContentFilterLevel.Strict;
    public List<string> BlockedWords { get; set; } = new();
    public List<string> AllowedDomains { get; set; } = new();
    public List<string> BlockedTopics { get; set; } = new();
    public bool EnableProfanityFilter { get; set; } = true;
    public bool EnablePersonalInfoDetection { get; set; } = true;
    public bool EnableSentimentMonitoring { get; set; } = true;
    public bool RequireParentApproval { get; set; } = false;
    public TimeRestrictions TimeRestrictions { get; set; } = new();
}

/// <summary>
/// Time-based access restrictions
/// </summary>
public class TimeRestrictions
{
    public bool Enabled { get; set; }
    public List<TimeWindow> AllowedWindows { get; set; } = new();
    public int MaxMinutesPerDay { get; set; } = 120;
    public int MaxMinutesPerSession { get; set; } = 30;
    public bool BlockDuringSchoolHours { get; set; } = true;
    public bool BlockAfterBedtime { get; set; } = true;
    public TimeOnly BedtimeStart { get; set; } = new TimeOnly(20, 0); // 8:00 PM
    public TimeOnly BedtimeEnd { get; set; } = new TimeOnly(7, 0); // 7:00 AM
}

/// <summary>
/// Allowed time window
/// </summary>
public class TimeWindow
{
    public DayOfWeek Day { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
}

/// <summary>
/// Safety report for parents
/// </summary>
public class SafetyReport
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string ChildId { get; set; } = string.Empty;
    public DateTime ReportDate { get; set; } = DateTime.Now;
    public ReportPeriod Period { get; set; }
    public SafetyMetrics Metrics { get; set; } = new();
    public List<ContentFlag> Flags { get; set; } = new();
    public List<ActivityHighlight> Highlights { get; set; } = new();
    public List<string> Recommendations { get; set; } = new();
    public OverallSafetyScore SafetyScore { get; set; } = new();
}

/// <summary>
/// Report period types
/// </summary>
public enum ReportPeriod
{
    Daily,
    Weekly,
    Monthly,
    Custom
}

/// <summary>
/// Safety metrics for reporting
/// </summary>
public class SafetyMetrics
{
    public int TotalSessions { get; set; }
    public TimeSpan TotalTime { get; set; }
    public int ConversationCount { get; set; }
    public int GameSessionCount { get; set; }
    public int FlaggedContentCount { get; set; }
    public int BlockedAttempts { get; set; }
    public double AverageSentimentScore { get; set; }
    public Dictionary<string, int> ActivityBreakdown { get; set; } = new();
    public List<string> MostUsedFeatures { get; set; } = new();
    public List<string> TopConversationTopics { get; set; } = new();
}

/// <summary>
/// Activity highlight for reports
/// </summary>
public class ActivityHighlight
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public HighlightType Type { get; set; }
    public DateTime Timestamp { get; set; }
    public string IconName { get; set; } = string.Empty;
}

/// <summary>
/// Types of activity highlights
/// </summary>
public enum HighlightType
{
    Achievement,
    Milestone,
    Learning,
    Creative,
    Social,
    Concern,
    Progress
}

/// <summary>
/// Overall safety score
/// </summary>
public class OverallSafetyScore
{
    public int Score { get; set; } // 0-100
    public string Grade { get; set; } = string.Empty; // A+, A, B, etc.
    public string Summary { get; set; } = string.Empty;
    public List<string> PositivePoints { get; set; } = new();
    public List<string> AreasOfConcern { get; set; } = new();
    public SafetyTrend Trend { get; set; }
}

/// <summary>
/// Safety trend direction
/// </summary>
public enum SafetyTrend
{
    Improving,
    Stable,
    Declining,
    NewUser
}

/// <summary>
/// Moderation action taken on content
/// </summary>
public class ModerationAction
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string ContentId { get; set; } = string.Empty;
    public ActionType Action { get; set; }
    public string Reason { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.Now;
    public string ModeratorId { get; set; } = string.Empty; // "System" for auto-moderation
    public bool IsAutomated { get; set; } = true;
    public string OriginalContent { get; set; } = string.Empty;
    public string ModifiedContent { get; set; } = string.Empty;
}

/// <summary>
/// Types of moderation actions
/// </summary>
public enum ActionType
{
    None,
    Warning,
    ContentModified,
    ContentBlocked,
    SessionTerminated,
    AccountRestricted,
    ParentNotified
}

/// <summary>
/// Trust and safety settings
/// </summary>
public class TrustAndSafetySettings
{
    public bool EnableContentFiltering { get; set; } = true;
    public bool EnableRealTimeMonitoring { get; set; } = true;
    public bool RequireParentConsent { get; set; } = true;
    public bool LogAllConversations { get; set; } = true;
    public bool EnableEmergencyShutdown { get; set; } = true;
    public List<string> EmergencyKeywords { get; set; } = new();
    public List<string> TrustedContacts { get; set; } = new();
    public int MaxReportRetentionDays { get; set; } = 90;
    public bool EnableAnonymousReporting { get; set; } = false;
}

/// <summary>
/// Blocked content entry
/// </summary>
public class BlockedContent
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Content { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public DateTime BlockedAt { get; set; } = DateTime.Now;
    public string UserId { get; set; } = string.Empty;
    public string SessionId { get; set; } = string.Empty;
    public int AttemptCount { get; set; } = 1;
}

/// <summary>
/// Safety alert for immediate parent notification
/// </summary>
public class SafetyAlert
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public AlertLevel Level { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string ChildId { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.Now;
    public bool IsAcknowledged { get; set; }
    public DateTime? AcknowledgedAt { get; set; }
    public string ActionRequired { get; set; } = string.Empty;
    public Dictionary<string, object> Context { get; set; } = new();
}

/// <summary>
/// Alert severity levels
/// </summary>
public enum AlertLevel
{
    Information,
    Warning,
    Urgent,
    Critical
}