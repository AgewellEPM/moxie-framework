using System;
using System.Collections.Generic;

namespace SimpleMoxieSwitcher.Models;

/// <summary>
/// Memory model for storing extracted information from conversations
/// </summary>
public class Memory
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string UserId { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public MemoryType Type { get; set; }
    public double Importance { get; set; } // 0.0 to 1.0
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime LastAccessedAt { get; set; } = DateTime.Now;
    public int AccessCount { get; set; }
    public Dictionary<string, object> Context { get; set; } = new();
    public List<string> RelatedMemoryIds { get; set; } = new();
    public List<string> Tags { get; set; } = new();
    public string SourceConversationId { get; set; } = string.Empty;
    public EmotionalContext EmotionalContext { get; set; } = new();
    public bool IsPinned { get; set; }
    public DateTime? ExpiresAt { get; set; }
}

/// <summary>
/// Types of memories
/// </summary>
public enum MemoryType
{
    Fact,           // Factual information
    Personal,       // Personal details about the user
    Preference,     // User preferences
    Experience,     // Past experiences
    Goal,           // User goals and aspirations
    Relationship,   // Information about relationships
    Interest,       // User interests and hobbies
    Learning,       // Things the user is learning
    Emotion,        // Emotional states and reactions
    Story,          // Stories and narratives
    Achievement,    // Accomplishments
    Problem         // Problems or challenges
}

/// <summary>
/// Emotional context associated with a memory
/// </summary>
public class EmotionalContext
{
    public EmotionType PrimaryEmotion { get; set; }
    public double Intensity { get; set; } // 0.0 to 1.0
    public Dictionary<EmotionType, double> EmotionScores { get; set; } = new();
    public string Mood { get; set; } = string.Empty;
}

/// <summary>
/// Memory cluster for related memories
/// </summary>
public class MemoryCluster
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public List<Memory> Memories { get; set; } = new();
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime LastUpdatedAt { get; set; } = DateTime.Now;
    public Dictionary<string, double> TopicWeights { get; set; } = new();
    public string Summary { get; set; } = string.Empty;
}

/// <summary>
/// Memory extraction result from conversation
/// </summary>
public class MemoryExtractionResult
{
    public string ConversationId { get; set; } = string.Empty;
    public List<Memory> ExtractedMemories { get; set; } = new();
    public List<string> UpdatedMemoryIds { get; set; } = new();
    public Dictionary<string, double> TopicAnalysis { get; set; } = new();
    public DateTime ProcessedAt { get; set; } = DateTime.Now;
    public int TotalMemoriesExtracted { get; set; }
}

/// <summary>
/// Knowledge graph node representing connected information
/// </summary>
public class KnowledgeNode
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Label { get; set; } = string.Empty;
    public NodeType Type { get; set; }
    public Dictionary<string, object> Properties { get; set; } = new();
    public List<KnowledgeEdge> Connections { get; set; } = new();
    public double Importance { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public int ReferenceCount { get; set; }
}

/// <summary>
/// Types of knowledge nodes
/// </summary>
public enum NodeType
{
    Person,
    Place,
    Thing,
    Concept,
    Event,
    Time,
    Activity,
    Emotion,
    Goal
}

/// <summary>
/// Edge connecting knowledge nodes
/// </summary>
public class KnowledgeEdge
{
    public string SourceId { get; set; } = string.Empty;
    public string TargetId { get; set; } = string.Empty;
    public string RelationType { get; set; } = string.Empty;
    public double Strength { get; set; } // 0.0 to 1.0
    public Dictionary<string, object> Properties { get; set; } = new();
}

/// <summary>
/// Memory search query
/// </summary>
public class MemorySearchQuery
{
    public string SearchText { get; set; } = string.Empty;
    public List<string> Categories { get; set; } = new();
    public List<MemoryType> Types { get; set; } = new();
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public double? MinImportance { get; set; }
    public List<string> Tags { get; set; } = new();
    public int MaxResults { get; set; } = 50;
    public MemorySortOrder SortOrder { get; set; } = MemorySortOrder.Relevance;
}

/// <summary>
/// Memory search sort order
/// </summary>
public enum MemorySortOrder
{
    Relevance,
    Recency,
    Importance,
    AccessFrequency
}

/// <summary>
/// Memory analytics data
/// </summary>
public class MemoryAnalytics
{
    public string UserId { get; set; } = string.Empty;
    public int TotalMemories { get; set; }
    public Dictionary<MemoryType, int> MemoriesByType { get; set; } = new();
    public Dictionary<string, int> MemoriesByCategory { get; set; } = new();
    public List<string> TopTags { get; set; } = new();
    public List<string> TopTopics { get; set; } = new();
    public double AverageImportance { get; set; }
    public int MemoriesThisWeek { get; set; }
    public int MemoriesThisMonth { get; set; }
    public DateTime OldestMemory { get; set; }
    public DateTime NewestMemory { get; set; }
}

/// <summary>
/// Memory retention policy
/// </summary>
public class MemoryRetentionPolicy
{
    public Dictionary<MemoryType, int> RetentionDaysByType { get; set; } = new()
    {
        { MemoryType.Fact, 365 },
        { MemoryType.Personal, -1 }, // Never expire
        { MemoryType.Preference, -1 },
        { MemoryType.Experience, 180 },
        { MemoryType.Goal, 90 },
        { MemoryType.Relationship, -1 },
        { MemoryType.Interest, 180 },
        { MemoryType.Learning, 90 },
        { MemoryType.Emotion, 30 },
        { MemoryType.Story, 180 },
        { MemoryType.Achievement, -1 },
        { MemoryType.Problem, 60 }
    };

    public double MinImportanceToRetain { get; set; } = 0.3;
    public int MaxMemoriesPerUser { get; set; } = 10000;
    public bool EnableAutoCleanup { get; set; } = true;
}

/// <summary>
/// Memory context for personality responses
/// </summary>
public class MemoryContext
{
    public List<Memory> RecentMemories { get; set; } = new();
    public List<Memory> RelevantMemories { get; set; } = new();
    public Dictionary<string, object> UserProfile { get; set; } = new();
    public List<string> CurrentGoals { get; set; } = new();
    public List<string> Interests { get; set; } = new();
    public Dictionary<string, string> Preferences { get; set; } = new();
    public EmotionalState CurrentEmotionalState { get; set; } = new();
}

/// <summary>
/// Emotional state tracking
/// </summary>
public class EmotionalState
{
    public string UserId { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.Now;
    public EmotionType DominantEmotion { get; set; }
    public double Valence { get; set; } // -1.0 (negative) to 1.0 (positive)
    public double Arousal { get; set; } // 0.0 (calm) to 1.0 (excited)
    public Dictionary<EmotionType, double> EmotionScores { get; set; } = new();
    public string TriggerEvent { get; set; } = string.Empty;
    public TimeSpan Duration { get; set; }
}

/// <summary>
/// Memory reinforcement for important information
/// </summary>
public class MemoryReinforcement
{
    public string MemoryId { get; set; } = string.Empty;
    public int ReinforcementCount { get; set; }
    public DateTime LastReinforced { get; set; }
    public double CurrentStrength { get; set; } // 0.0 to 1.0
    public List<DateTime> ReinforcementHistory { get; set; } = new();
    public string ReinforcementMethod { get; set; } = string.Empty;
}

/// <summary>
/// Memory merge operation for duplicate/similar memories
/// </summary>
public class MemoryMergeOperation
{
    public List<string> SourceMemoryIds { get; set; } = new();
    public Memory MergedMemory { get; set; } = new();
    public DateTime MergedAt { get; set; } = DateTime.Now;
    public string MergeReason { get; set; } = string.Empty;
    public double SimilarityScore { get; set; }
}