using System;
using System.Collections.Generic;

namespace SimpleMoxieSwitcher.Models
{
    // Feature types for categorizing AI usage
    public enum FeatureType
    {
        Chat,
        Story,
        Learning,
        Translation,
        Vocabulary,
        Creative,
        Games,
        Listening,
        Other
    }

    // Individual usage record for API calls
    public class UsageRecord
    {
        public Guid Id { get; set; }
        public DateTime Timestamp { get; set; }
        public string ModelName { get; set; }
        public FeatureType Feature { get; set; }
        public int InputTokens { get; set; }
        public int OutputTokens { get; set; }
        public int TotalTokens => InputTokens + OutputTokens;
        public double EstimatedCost { get; set; }
        public string ChildProfileId { get; set; }
        public string SessionId { get; set; }
        public TimeSpan ResponseTime { get; set; }
        public bool WasCached { get; set; }
        public Dictionary<string, object> Metadata { get; set; } = new();

        // Formatted properties for display
        public string FormattedTimestamp => Timestamp.ToString("yyyy-MM-dd HH:mm:ss");
        public string FormattedCost => $"${EstimatedCost:F4}";
        public string FormattedResponseTime => $"{ResponseTime.TotalSeconds:F2}s";
    }

    // Summary statistics for a period
    public class UsageSummary
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public double TotalCost { get; set; }
        public int RecordCount { get; set; }
        public int TotalInputTokens { get; set; }
        public int TotalOutputTokens { get; set; }
        public int TotalTokens => TotalInputTokens + TotalOutputTokens;
        public TimeSpan AverageResponseTime { get; set; }
        public Dictionary<string, UsageMetrics> ByModel { get; set; } = new();
        public Dictionary<FeatureType, UsageMetrics> ByFeature { get; set; } = new();
        public Dictionary<string, UsageMetrics> ByChild { get; set; } = new();

        // Formatted properties
        public string FormattedTotalCost => $"${TotalCost:F2}";
        public string FormattedAverageResponseTime => $"{AverageResponseTime.TotalSeconds:F2}s";
        public double AverageCostPerRequest => RecordCount > 0 ? TotalCost / RecordCount : 0;
        public string FormattedAverageCost => $"${AverageCostPerRequest:F4}";
    }

    // Metrics for grouped data
    public class UsageMetrics
    {
        public int Count { get; set; }
        public double Cost { get; set; }
        public int Tokens { get; set; }
        public TimeSpan TotalResponseTime { get; set; }
        public TimeSpan AverageResponseTime => Count > 0 ?
            TimeSpan.FromMilliseconds(TotalResponseTime.TotalMilliseconds / Count) :
            TimeSpan.Zero;
    }

    // Alert for unusual cost patterns
    public class CostAlert
    {
        public enum AlertType
        {
            UnusualSpike,
            HighCostModel,
            ExcessiveTokens,
            RapidUsage,
            BudgetExceeded,
            ProjectedOverage
        }

        public enum AlertSeverity
        {
            Info,
            Warning,
            Critical
        }

        public Guid Id { get; set; } = Guid.NewGuid();
        public DateTime Timestamp { get; set; }
        public AlertType Type { get; set; }
        public AlertSeverity Severity { get; set; }
        public string Title { get; set; }
        public string Message { get; set; }
        public double RelatedCost { get; set; }
        public Dictionary<string, object> Context { get; set; } = new();
        public bool IsRead { get; set; }
        public bool IsDismissed { get; set; }

        // Display helpers
        public string Icon => Severity switch
        {
            AlertSeverity.Info => "ℹ️",
            AlertSeverity.Warning => "⚠️",
            AlertSeverity.Critical => "🚨",
            _ => "📊"
        };

        public string FormattedTimestamp => Timestamp.ToString("yyyy-MM-dd HH:mm");
    }

    // Model pricing information
    public class ModelPricing
    {
        public string ModelId { get; set; }
        public string DisplayName { get; set; }
        public string Provider { get; set; }
        public double InputTokenPricePer1K { get; set; }
        public double OutputTokenPricePer1K { get; set; }
        public bool SupportsCaching { get; set; }
        public double? CachedInputTokenPricePer1K { get; set; }
        public DateTime LastUpdated { get; set; }

        // Calculate cost for tokens
        public double CalculateCost(int inputTokens, int outputTokens, bool wasCached = false)
        {
            var inputCost = wasCached && CachedInputTokenPricePer1K.HasValue
                ? (inputTokens / 1000.0) * CachedInputTokenPricePer1K.Value
                : (inputTokens / 1000.0) * InputTokenPricePer1K;

            var outputCost = (outputTokens / 1000.0) * OutputTokenPricePer1K;
            return inputCost + outputCost;
        }
    }

    // Budget configuration
    public class UsageBudget
    {
        public enum BudgetPeriod
        {
            Daily,
            Weekly,
            Monthly
        }

        public Guid Id { get; set; } = Guid.NewGuid();
        public string Name { get; set; }
        public double Amount { get; set; }
        public BudgetPeriod Period { get; set; }
        public bool IsActive { get; set; }
        public bool SendAlerts { get; set; }
        public double AlertThresholdPercent { get; set; } = 80; // Alert at 80% by default
        public string ChildProfileId { get; set; } // Optional: budget per child
        public FeatureType? FeatureType { get; set; } // Optional: budget per feature
        public DateTime CreatedAt { get; set; }
        public DateTime? ModifiedAt { get; set; }

        public string FormattedAmount => $"${Amount:F2}";
        public string DisplayPeriod => Period.ToString();
    }

    // Usage statistics for reporting
    public class UsageStatistics
    {
        public DateTime GeneratedAt { get; set; }
        public DateTimeOffset PeriodStart { get; set; }
        public DateTimeOffset PeriodEnd { get; set; }

        // Overall metrics
        public double TotalCost { get; set; }
        public int TotalRequests { get; set; }
        public long TotalTokens { get; set; }
        public TimeSpan TotalProcessingTime { get; set; }

        // Breakdowns
        public Dictionary<string, double> CostByModel { get; set; } = new();
        public Dictionary<FeatureType, double> CostByFeature { get; set; } = new();
        public Dictionary<DayOfWeek, double> CostByDayOfWeek { get; set; } = new();
        public Dictionary<int, double> CostByHourOfDay { get; set; } = new();

        // Trends
        public double DailyAverageCost { get; set; }
        public double WeeklyAverageCost { get; set; }
        public double MonthlyProjectedCost { get; set; }
        public double GrowthRatePercent { get; set; }

        // Top items
        public string MostUsedModel { get; set; }
        public FeatureType MostUsedFeature { get; set; }
        public string MostActiveChild { get; set; }
        public DayOfWeek BusiestDay { get; set; }
        public int BusiestHour { get; set; }

        // Efficiency metrics
        public double CacheHitRate { get; set; }
        public double AverageResponseTime { get; set; }
        public double AverageTokensPerRequest { get; set; }
        public double AverageCostPerRequest { get; set; }
    }
}