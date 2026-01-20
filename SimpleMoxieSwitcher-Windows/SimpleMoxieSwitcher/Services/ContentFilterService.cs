using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services;

/// <summary>
/// Service for filtering and moderating content for child safety
/// </summary>
public class ContentFilterService : IContentFilterService
{
    private readonly SafetyLogService _safetyLogService;
    private readonly ParentNotificationService _parentNotificationService;
    private ContentFilterConfig _currentConfig;

    // Default blocked words and phrases (would be loaded from a more comprehensive list)
    private readonly HashSet<string> _defaultBlockedWords = new()
    {
        // This would contain a comprehensive list of inappropriate words
        // Keeping it minimal for this implementation
        "inappropriate", "violence", "adult", "dangerous"
    };

    // Patterns for detecting personal information
    private readonly List<Regex> _personalInfoPatterns = new()
    {
        new Regex(@"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b", RegexOptions.IgnoreCase), // Phone numbers
        new Regex(@"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b", RegexOptions.IgnoreCase), // Email
        new Regex(@"\b\d{3}-\d{2}-\d{4}\b", RegexOptions.IgnoreCase), // SSN
        new Regex(@"\b\d{16}\b", RegexOptions.IgnoreCase), // Credit card
        new Regex(@"\b\d{1,5}\s+[\w\s]+(?:street|st|avenue|ave|road|rd|highway|hwy|lane|ln|drive|dr|court|ct|circle|cir|boulevard|blvd)", RegexOptions.IgnoreCase) // Addresses
    };

    public ContentFilterService(SafetyLogService safetyLogService, ParentNotificationService parentNotificationService)
    {
        _safetyLogService = safetyLogService;
        _parentNotificationService = parentNotificationService;
        _currentConfig = LoadDefaultConfig();
    }

    /// <summary>
    /// Filter content based on current configuration
    /// </summary>
    public async Task<ContentFilterResult> FilterContentAsync(string content, string userId, string sessionId)
    {
        var result = new ContentFilterResult
        {
            OriginalContent = content,
            FilteredContent = content,
            IsClean = true,
            Flags = new List<ContentFlag>()
        };

        // Check for inappropriate language
        if (_currentConfig.EnableProfanityFilter)
        {
            var profanityCheck = await CheckForProfanityAsync(content);
            if (profanityCheck.HasFlag)
            {
                result.Flags.Add(profanityCheck.Flag!);
                result.FilteredContent = profanityCheck.FilteredText;
                result.IsClean = false;
            }
        }

        // Check for personal information
        if (_currentConfig.EnablePersonalInfoDetection)
        {
            var personalInfoCheck = CheckForPersonalInfo(content);
            if (personalInfoCheck.HasFlag)
            {
                result.Flags.Add(personalInfoCheck.Flag!);
                result.FilteredContent = personalInfoCheck.FilteredText;
                result.IsClean = false;
            }
        }

        // Check blocked topics
        var topicCheck = CheckBlockedTopics(content);
        if (topicCheck.HasFlag)
        {
            result.Flags.Add(topicCheck.Flag!);
            result.IsClean = false;
        }

        // Log if content was flagged
        if (!result.IsClean)
        {
            foreach (var flag in result.Flags)
            {
                flag.UserId = userId;
                flag.SessionId = sessionId;
                await _safetyLogService.LogContentFlagAsync(flag);

                // Send parent notification for high/critical severity
                if (flag.Severity >= FlagSeverity.High)
                {
                    await _parentNotificationService.SendContentFlagNotificationAsync(flag);
                }
            }
        }

        return result;
    }

    /// <summary>
    /// Check content for profanity and inappropriate language
    /// </summary>
    private async Task<FilterCheckResult> CheckForProfanityAsync(string content)
    {
        var result = new FilterCheckResult
        {
            HasFlag = false,
            FilteredText = content
        };

        var lowerContent = content.ToLowerInvariant();
        var detectedWords = new List<string>();

        // Check against blocked words
        foreach (var word in _currentConfig.BlockedWords.Concat(_defaultBlockedWords))
        {
            if (lowerContent.Contains(word.ToLowerInvariant()))
            {
                detectedWords.Add(word);
                // Replace with asterisks
                var pattern = $@"\b{Regex.Escape(word)}\b";
                result.FilteredText = Regex.Replace(result.FilteredText, pattern, new string('*', word.Length), RegexOptions.IgnoreCase);
            }
        }

        if (detectedWords.Any())
        {
            result.HasFlag = true;
            result.Flag = new ContentFlag
            {
                Content = content,
                Type = FlagType.InappropriateLanguage,
                Severity = DetermineSeverity(detectedWords),
                Reason = "Inappropriate language detected",
                DetectedKeywords = detectedWords,
                ConfidenceScore = 0.95,
                WasBlocked = result.FilteredText != content,
                ActionTaken = "Content filtered",
                Timestamp = DateTime.Now
            };
        }

        return await Task.FromResult(result);
    }

    /// <summary>
    /// Check for personal information in content
    /// </summary>
    private FilterCheckResult CheckForPersonalInfo(string content)
    {
        var result = new FilterCheckResult
        {
            HasFlag = false,
            FilteredText = content
        };

        var detectedTypes = new List<string>();

        foreach (var pattern in _personalInfoPatterns)
        {
            if (pattern.IsMatch(content))
            {
                detectedTypes.Add(GetPersonalInfoType(pattern));
                // Replace with [REDACTED]
                result.FilteredText = pattern.Replace(result.FilteredText, "[REDACTED]");
            }
        }

        if (detectedTypes.Any())
        {
            result.HasFlag = true;
            result.Flag = new ContentFlag
            {
                Content = content,
                Type = FlagType.PersonalInformation,
                Severity = FlagSeverity.High,
                Reason = $"Personal information detected: {string.Join(", ", detectedTypes)}",
                DetectedKeywords = detectedTypes,
                ConfidenceScore = 0.9,
                WasBlocked = true,
                ActionTaken = "Personal information redacted",
                Timestamp = DateTime.Now
            };
        }

        return result;
    }

    /// <summary>
    /// Check for blocked topics
    /// </summary>
    private FilterCheckResult CheckBlockedTopics(string content)
    {
        var result = new FilterCheckResult
        {
            HasFlag = false,
            FilteredText = content
        };

        var lowerContent = content.ToLowerInvariant();
        var detectedTopics = new List<string>();

        foreach (var topic in _currentConfig.BlockedTopics)
        {
            if (lowerContent.Contains(topic.ToLowerInvariant()))
            {
                detectedTopics.Add(topic);
            }
        }

        if (detectedTopics.Any())
        {
            result.HasFlag = true;
            result.Flag = new ContentFlag
            {
                Content = content,
                Type = FlagType.Other,
                Severity = FlagSeverity.Medium,
                Reason = $"Blocked topic detected: {string.Join(", ", detectedTopics)}",
                DetectedKeywords = detectedTopics,
                ConfidenceScore = 0.8,
                WasBlocked = false,
                ActionTaken = "Topic flagged for review",
                Timestamp = DateTime.Now
            };
        }

        return result;
    }

    /// <summary>
    /// Analyze sentiment of content
    /// </summary>
    public async Task<SentimentAnalysis> AnalyzeSentimentAsync(string content, string conversationId)
    {
        // Simple sentiment analysis (would use ML model in production)
        var analysis = new SentimentAnalysis
        {
            ConversationId = conversationId,
            Text = content,
            AnalyzedAt = DateTime.Now
        };

        // Simple keyword-based sentiment detection
        var positiveWords = new[] { "happy", "good", "great", "love", "excellent", "wonderful", "amazing", "fun" };
        var negativeWords = new[] { "sad", "bad", "hate", "terrible", "awful", "horrible", "angry", "upset" };

        var lowerContent = content.ToLowerInvariant();
        var positiveCount = positiveWords.Count(w => lowerContent.Contains(w));
        var negativeCount = negativeWords.Count(w => lowerContent.Contains(w));

        var total = positiveCount + negativeCount;
        if (total == 0)
        {
            analysis.Sentiment = SentimentType.Neutral;
            analysis.NeutralScore = 1.0;
        }
        else
        {
            analysis.PositiveScore = (double)positiveCount / total;
            analysis.NegativeScore = (double)negativeCount / total;
            analysis.NeutralScore = 1.0 - (analysis.PositiveScore + analysis.NegativeScore);

            if (analysis.PositiveScore > 0.6)
                analysis.Sentiment = analysis.PositiveScore > 0.8 ? SentimentType.VeryPositive : SentimentType.Positive;
            else if (analysis.NegativeScore > 0.6)
                analysis.Sentiment = analysis.NegativeScore > 0.8 ? SentimentType.VeryNegative : SentimentType.Negative;
            else
                analysis.Sentiment = SentimentType.Mixed;
        }

        // Detect emotions
        analysis.Emotions = DetectEmotions(content);

        if (_currentConfig.EnableSentimentMonitoring && analysis.Sentiment == SentimentType.VeryNegative)
        {
            await _safetyLogService.LogSentimentAnalysisAsync(analysis);
        }

        return analysis;
    }

    /// <summary>
    /// Update filter configuration
    /// </summary>
    public void UpdateConfiguration(ContentFilterConfig config)
    {
        _currentConfig = config;
        SaveConfiguration();
    }

    /// <summary>
    /// Get current filter configuration
    /// </summary>
    public ContentFilterConfig GetConfiguration() => _currentConfig;

    /// <summary>
    /// Check if content is allowed based on time restrictions
    /// </summary>
    public bool IsTimeAllowed(TimeRestrictions restrictions)
    {
        if (!restrictions.Enabled) return true;

        var now = DateTime.Now;
        var currentTime = TimeOnly.FromDateTime(now);

        // Check bedtime restrictions
        if (restrictions.BlockAfterBedtime)
        {
            if (restrictions.BedtimeStart < restrictions.BedtimeEnd)
            {
                // Bedtime doesn't cross midnight
                if (currentTime >= restrictions.BedtimeStart && currentTime < restrictions.BedtimeEnd)
                    return false;
            }
            else
            {
                // Bedtime crosses midnight
                if (currentTime >= restrictions.BedtimeStart || currentTime < restrictions.BedtimeEnd)
                    return false;
            }
        }

        // Check allowed windows
        var todayWindow = restrictions.AllowedWindows.FirstOrDefault(w => w.Day == now.DayOfWeek);
        if (todayWindow != null)
        {
            if (currentTime < todayWindow.StartTime || currentTime > todayWindow.EndTime)
                return false;
        }

        return true;
    }

    /// <summary>
    /// Detect emotions in content
    /// </summary>
    private List<EmotionScore> DetectEmotions(string content)
    {
        var emotions = new List<EmotionScore>();
        var lowerContent = content.ToLowerInvariant();

        // Simple keyword-based emotion detection
        var emotionKeywords = new Dictionary<EmotionType, string[]>
        {
            { EmotionType.Joy, new[] { "happy", "joy", "excited", "thrilled", "delighted" } },
            { EmotionType.Sadness, new[] { "sad", "unhappy", "depressed", "crying", "tears" } },
            { EmotionType.Anger, new[] { "angry", "mad", "furious", "rage", "annoyed" } },
            { EmotionType.Fear, new[] { "scared", "afraid", "frightened", "terrified", "worried" } },
            { EmotionType.Surprise, new[] { "surprised", "shocked", "amazed", "astonished" } },
            { EmotionType.Love, new[] { "love", "adore", "cherish", "affection" } }
        };

        foreach (var kvp in emotionKeywords)
        {
            var count = kvp.Value.Count(w => lowerContent.Contains(w));
            if (count > 0)
            {
                emotions.Add(new EmotionScore
                {
                    Emotion = kvp.Key,
                    Score = Math.Min(1.0, count * 0.3)
                });
            }
        }

        return emotions;
    }

    /// <summary>
    /// Determine severity based on detected words
    /// </summary>
    private FlagSeverity DetermineSeverity(List<string> detectedWords)
    {
        // This would use a more sophisticated categorization in production
        if (detectedWords.Count >= 3) return FlagSeverity.High;
        if (detectedWords.Count >= 2) return FlagSeverity.Medium;
        return FlagSeverity.Low;
    }

    /// <summary>
    /// Get personal info type from regex pattern
    /// </summary>
    private string GetPersonalInfoType(Regex pattern)
    {
        var patternString = pattern.ToString();
        if (patternString.Contains("@")) return "Email Address";
        if (patternString.Contains("\\d{3}-\\d{2}-\\d{4}")) return "Social Security Number";
        if (patternString.Contains("\\d{16}")) return "Credit Card Number";
        if (patternString.Contains("\\d{3}")) return "Phone Number";
        if (patternString.Contains("street|ave|road")) return "Physical Address";
        return "Personal Information";
    }

    /// <summary>
    /// Load default filter configuration
    /// </summary>
    private ContentFilterConfig LoadDefaultConfig()
    {
        return new ContentFilterConfig
        {
            FilterLevel = ContentFilterLevel.Strict,
            BlockedWords = new List<string>(_defaultBlockedWords),
            BlockedTopics = new List<string> { "violence", "drugs", "adult content" },
            EnableProfanityFilter = true,
            EnablePersonalInfoDetection = true,
            EnableSentimentMonitoring = true,
            TimeRestrictions = new TimeRestrictions
            {
                Enabled = true,
                MaxMinutesPerDay = 120,
                MaxMinutesPerSession = 30,
                BlockAfterBedtime = true,
                BedtimeStart = new TimeOnly(20, 0),
                BedtimeEnd = new TimeOnly(7, 0)
            }
        };
    }

    /// <summary>
    /// Save configuration to storage
    /// </summary>
    private void SaveConfiguration()
    {
        // Implementation would save to persistent storage
    }
}

/// <summary>
/// Result of content filtering
/// </summary>
public class ContentFilterResult
{
    public string OriginalContent { get; set; } = string.Empty;
    public string FilteredContent { get; set; } = string.Empty;
    public bool IsClean { get; set; }
    public List<ContentFlag> Flags { get; set; } = new();
}

/// <summary>
/// Result of a filter check
/// </summary>
internal class FilterCheckResult
{
    public bool HasFlag { get; set; }
    public ContentFlag? Flag { get; set; }
    public string FilteredText { get; set; } = string.Empty;
}

/// <summary>
/// Interface for content filter service
/// </summary>
public interface IContentFilterService
{
    Task<ContentFilterResult> FilterContentAsync(string content, string userId, string sessionId);
    Task<SentimentAnalysis> AnalyzeSentimentAsync(string content, string conversationId);
    void UpdateConfiguration(ContentFilterConfig config);
    ContentFilterConfig GetConfiguration();
    bool IsTimeAllowed(TimeRestrictions restrictions);
}