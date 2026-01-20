using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    // Interface for usage data repository
    public interface IUsageRepository
    {
        Task<UsageSummary> CalculateDailySummaryAsync(DateTime date);
        Task<UsageSummary> CalculateWeeklySummaryAsync();
        Task<UsageSummary> CalculateMonthlySummaryAsync();
        Task<List<UsageRecord>> GetRecentRecordsAsync(int limit);
        Task<List<(DateTime date, double cost)>> CalculateDailyTrendAsync(int days);
        Task<List<CostAlert>> DetectCostAnomaliesAsync();
        Task<List<UsageRecord>> GetUsageRecordsAsync(DateTime startDate, DateTime endDate);
        Task SaveUsageRecordAsync(UsageRecord record);
        Task<UsageStatistics> GenerateStatisticsAsync(DateTime startDate, DateTime endDate);
        Task<List<UsageBudget>> GetActiveBudgetsAsync();
        Task SaveBudgetAsync(UsageBudget budget);
        Task<Dictionary<string, ModelPricing>> GetModelPricingAsync();
    }

    // Implementation of usage repository
    public class UsageRepository : IUsageRepository
    {
        private readonly List<UsageRecord> _records = new();
        private readonly List<CostAlert> _alerts = new();
        private readonly List<UsageBudget> _budgets = new();
        private readonly Dictionary<string, ModelPricing> _modelPricing;

        public UsageRepository()
        {
            InitializeModelPricing();
            GenerateSampleData(); // For demonstration
        }

        private void InitializeModelPricing()
        {
            _modelPricing = new Dictionary<string, ModelPricing>
            {
                ["gpt-4o"] = new ModelPricing
                {
                    ModelId = "gpt-4o",
                    DisplayName = "GPT-4o",
                    Provider = "OpenAI",
                    InputTokenPricePer1K = 0.0025,
                    OutputTokenPricePer1K = 0.01,
                    SupportsCaching = true,
                    CachedInputTokenPricePer1K = 0.00125,
                    LastUpdated = DateTime.Now
                },
                ["gpt-4o-mini"] = new ModelPricing
                {
                    ModelId = "gpt-4o-mini",
                    DisplayName = "GPT-4o Mini",
                    Provider = "OpenAI",
                    InputTokenPricePer1K = 0.00015,
                    OutputTokenPricePer1K = 0.0006,
                    SupportsCaching = true,
                    CachedInputTokenPricePer1K = 0.000075,
                    LastUpdated = DateTime.Now
                },
                ["claude-3-5-sonnet"] = new ModelPricing
                {
                    ModelId = "claude-3-5-sonnet",
                    DisplayName = "Claude 3.5 Sonnet",
                    Provider = "Anthropic",
                    InputTokenPricePer1K = 0.003,
                    OutputTokenPricePer1K = 0.015,
                    SupportsCaching = true,
                    CachedInputTokenPricePer1K = 0.0003,
                    LastUpdated = DateTime.Now
                },
                ["claude-3-5-haiku"] = new ModelPricing
                {
                    ModelId = "claude-3-5-haiku",
                    DisplayName = "Claude 3.5 Haiku",
                    Provider = "Anthropic",
                    InputTokenPricePer1K = 0.001,
                    OutputTokenPricePer1K = 0.005,
                    SupportsCaching = false,
                    LastUpdated = DateTime.Now
                },
                ["deepseek-chat"] = new ModelPricing
                {
                    ModelId = "deepseek-chat",
                    DisplayName = "DeepSeek Chat",
                    Provider = "DeepSeek",
                    InputTokenPricePer1K = 0.00014,
                    OutputTokenPricePer1K = 0.00028,
                    SupportsCaching = true,
                    CachedInputTokenPricePer1K = 0.000014,
                    LastUpdated = DateTime.Now
                },
                ["deepseek-reasoner"] = new ModelPricing
                {
                    ModelId = "deepseek-reasoner",
                    DisplayName = "DeepSeek Reasoner",
                    Provider = "DeepSeek",
                    InputTokenPricePer1K = 0.00055,
                    OutputTokenPricePer1K = 0.0022,
                    SupportsCaching = false,
                    LastUpdated = DateTime.Now
                }
            };
        }

        public async Task<UsageSummary> CalculateDailySummaryAsync(DateTime date)
        {
            return await Task.Run(() =>
            {
                var startOfDay = date.Date;
                var endOfDay = startOfDay.AddDays(1);

                var dayRecords = _records.Where(r =>
                    r.Timestamp >= startOfDay && r.Timestamp < endOfDay).ToList();

                return CalculateSummary(dayRecords, startOfDay, endOfDay);
            });
        }

        public async Task<UsageSummary> CalculateWeeklySummaryAsync()
        {
            return await Task.Run(() =>
            {
                var today = DateTime.Today;
                var startOfWeek = today.AddDays(-(int)today.DayOfWeek);
                var endOfWeek = startOfWeek.AddDays(7);

                var weekRecords = _records.Where(r =>
                    r.Timestamp >= startOfWeek && r.Timestamp < endOfWeek).ToList();

                return CalculateSummary(weekRecords, startOfWeek, endOfWeek);
            });
        }

        public async Task<UsageSummary> CalculateMonthlySummaryAsync()
        {
            return await Task.Run(() =>
            {
                var today = DateTime.Today;
                var startOfMonth = new DateTime(today.Year, today.Month, 1);
                var endOfMonth = startOfMonth.AddMonths(1);

                var monthRecords = _records.Where(r =>
                    r.Timestamp >= startOfMonth && r.Timestamp < endOfMonth).ToList();

                return CalculateSummary(monthRecords, startOfMonth, endOfMonth);
            });
        }

        private UsageSummary CalculateSummary(List<UsageRecord> records, DateTime startDate, DateTime endDate)
        {
            var summary = new UsageSummary
            {
                StartDate = startDate,
                EndDate = endDate,
                RecordCount = records.Count,
                TotalCost = records.Sum(r => r.EstimatedCost),
                TotalInputTokens = records.Sum(r => r.InputTokens),
                TotalOutputTokens = records.Sum(r => r.OutputTokens)
            };

            if (records.Any())
            {
                var totalResponseTimeMs = records.Sum(r => r.ResponseTime.TotalMilliseconds);
                summary.AverageResponseTime = TimeSpan.FromMilliseconds(totalResponseTimeMs / records.Count);

                // Group by model
                summary.ByModel = records.GroupBy(r => r.ModelName)
                    .ToDictionary(
                        g => g.Key,
                        g => new UsageMetrics
                        {
                            Count = g.Count(),
                            Cost = g.Sum(r => r.EstimatedCost),
                            Tokens = g.Sum(r => r.TotalTokens),
                            TotalResponseTime = TimeSpan.FromMilliseconds(g.Sum(r => r.ResponseTime.TotalMilliseconds))
                        });

                // Group by feature
                summary.ByFeature = records.GroupBy(r => r.Feature)
                    .ToDictionary(
                        g => g.Key,
                        g => new UsageMetrics
                        {
                            Count = g.Count(),
                            Cost = g.Sum(r => r.EstimatedCost),
                            Tokens = g.Sum(r => r.TotalTokens),
                            TotalResponseTime = TimeSpan.FromMilliseconds(g.Sum(r => r.ResponseTime.TotalMilliseconds))
                        });

                // Group by child profile
                summary.ByChild = records.Where(r => !string.IsNullOrEmpty(r.ChildProfileId))
                    .GroupBy(r => r.ChildProfileId)
                    .ToDictionary(
                        g => g.Key,
                        g => new UsageMetrics
                        {
                            Count = g.Count(),
                            Cost = g.Sum(r => r.EstimatedCost),
                            Tokens = g.Sum(r => r.TotalTokens),
                            TotalResponseTime = TimeSpan.FromMilliseconds(g.Sum(r => r.ResponseTime.TotalMilliseconds))
                        });
            }

            return summary;
        }

        public async Task<List<UsageRecord>> GetRecentRecordsAsync(int limit)
        {
            return await Task.Run(() =>
                _records.OrderByDescending(r => r.Timestamp)
                    .Take(limit)
                    .ToList());
        }

        public async Task<List<(DateTime date, double cost)>> CalculateDailyTrendAsync(int days)
        {
            return await Task.Run(() =>
            {
                var trend = new List<(DateTime, double)>();
                var today = DateTime.Today;

                for (int i = days - 1; i >= 0; i--)
                {
                    var date = today.AddDays(-i);
                    var dayRecords = _records.Where(r =>
                        r.Timestamp >= date && r.Timestamp < date.AddDays(1));
                    var dayCost = dayRecords.Sum(r => r.EstimatedCost);
                    trend.Add((date, dayCost));
                }

                return trend;
            });
        }

        public async Task<List<CostAlert>> DetectCostAnomaliesAsync()
        {
            return await Task.Run(() =>
            {
                var alerts = new List<CostAlert>();
                var today = DateTime.Today;

                // Check for unusual daily spike
                var todayCost = _records.Where(r => r.Timestamp >= today)
                    .Sum(r => r.EstimatedCost);
                var yesterdayCost = _records.Where(r =>
                    r.Timestamp >= today.AddDays(-1) && r.Timestamp < today)
                    .Sum(r => r.EstimatedCost);

                if (yesterdayCost > 0 && todayCost > yesterdayCost * 1.5)
                {
                    alerts.Add(new CostAlert
                    {
                        Timestamp = DateTime.Now,
                        Type = CostAlert.AlertType.UnusualSpike,
                        Severity = CostAlert.AlertSeverity.Warning,
                        Title = "Unusual Cost Spike Detected",
                        Message = $"Today's usage (${todayCost:F2}) is {((todayCost / yesterdayCost - 1) * 100):F0}% higher than yesterday",
                        RelatedCost = todayCost
                    });
                }

                // Check for high-cost model usage
                var recentHighCostRecords = _records
                    .Where(r => r.Timestamp >= DateTime.Now.AddHours(-1) &&
                               r.EstimatedCost > 0.10) // More than 10 cents per request
                    .ToList();

                if (recentHighCostRecords.Any())
                {
                    var totalHighCost = recentHighCostRecords.Sum(r => r.EstimatedCost);
                    alerts.Add(new CostAlert
                    {
                        Timestamp = DateTime.Now,
                        Type = CostAlert.AlertType.HighCostModel,
                        Severity = CostAlert.AlertSeverity.Info,
                        Title = "High-Cost Model Usage",
                        Message = $"{recentHighCostRecords.Count} high-cost requests in the last hour (${totalHighCost:F2} total)",
                        RelatedCost = totalHighCost
                    });
                }

                // Check budget exceeded
                foreach (var budget in _budgets.Where(b => b.IsActive))
                {
                    var periodCost = GetPeriodCost(budget.Period);
                    if (periodCost > budget.Amount)
                    {
                        alerts.Add(new CostAlert
                        {
                            Timestamp = DateTime.Now,
                            Type = CostAlert.AlertType.BudgetExceeded,
                            Severity = CostAlert.AlertSeverity.Critical,
                            Title = $"{budget.Name} Budget Exceeded",
                            Message = $"Current {budget.Period} spending (${periodCost:F2}) exceeds budget of ${budget.Amount:F2}",
                            RelatedCost = periodCost
                        });
                    }
                    else if (periodCost > budget.Amount * (budget.AlertThresholdPercent / 100))
                    {
                        alerts.Add(new CostAlert
                        {
                            Timestamp = DateTime.Now,
                            Type = CostAlert.AlertType.ProjectedOverage,
                            Severity = CostAlert.AlertSeverity.Warning,
                            Title = $"{budget.Name} Budget Warning",
                            Message = $"Current {budget.Period} spending (${periodCost:F2}) is at {(periodCost / budget.Amount * 100):F0}% of budget",
                            RelatedCost = periodCost
                        });
                    }
                }

                return alerts;
            });
        }

        private double GetPeriodCost(UsageBudget.BudgetPeriod period)
        {
            var now = DateTime.Now;
            DateTime startDate = period switch
            {
                UsageBudget.BudgetPeriod.Daily => now.Date,
                UsageBudget.BudgetPeriod.Weekly => now.Date.AddDays(-(int)now.DayOfWeek),
                UsageBudget.BudgetPeriod.Monthly => new DateTime(now.Year, now.Month, 1),
                _ => now.Date
            };

            return _records.Where(r => r.Timestamp >= startDate).Sum(r => r.EstimatedCost);
        }

        public async Task<List<UsageRecord>> GetUsageRecordsAsync(DateTime startDate, DateTime endDate)
        {
            return await Task.Run(() =>
                _records.Where(r => r.Timestamp >= startDate && r.Timestamp <= endDate)
                    .OrderBy(r => r.Timestamp)
                    .ToList());
        }

        public async Task SaveUsageRecordAsync(UsageRecord record)
        {
            await Task.Run(() => _records.Add(record));
        }

        public async Task<UsageStatistics> GenerateStatisticsAsync(DateTime startDate, DateTime endDate)
        {
            return await Task.Run(() =>
            {
                var records = _records.Where(r =>
                    r.Timestamp >= startDate && r.Timestamp <= endDate).ToList();

                if (!records.Any())
                    return new UsageStatistics
                    {
                        GeneratedAt = DateTime.Now,
                        PeriodStart = new DateTimeOffset(startDate),
                        PeriodEnd = new DateTimeOffset(endDate)
                    };

                var stats = new UsageStatistics
                {
                    GeneratedAt = DateTime.Now,
                    PeriodStart = new DateTimeOffset(startDate),
                    PeriodEnd = new DateTimeOffset(endDate),
                    TotalCost = records.Sum(r => r.EstimatedCost),
                    TotalRequests = records.Count,
                    TotalTokens = records.Sum(r => (long)r.TotalTokens),
                    TotalProcessingTime = TimeSpan.FromMilliseconds(records.Sum(r => r.ResponseTime.TotalMilliseconds))
                };

                // Calculate breakdowns
                stats.CostByModel = records.GroupBy(r => r.ModelName)
                    .ToDictionary(g => g.Key, g => g.Sum(r => r.EstimatedCost));

                stats.CostByFeature = records.GroupBy(r => r.Feature)
                    .ToDictionary(g => g.Key, g => g.Sum(r => r.EstimatedCost));

                stats.CostByDayOfWeek = records.GroupBy(r => r.Timestamp.DayOfWeek)
                    .ToDictionary(g => g.Key, g => g.Sum(r => r.EstimatedCost));

                stats.CostByHourOfDay = records.GroupBy(r => r.Timestamp.Hour)
                    .ToDictionary(g => g.Key, g => g.Sum(r => r.EstimatedCost));

                // Calculate averages and projections
                var days = (endDate - startDate).TotalDays;
                stats.DailyAverageCost = stats.TotalCost / Math.Max(days, 1);
                stats.WeeklyAverageCost = stats.DailyAverageCost * 7;
                stats.MonthlyProjectedCost = stats.DailyAverageCost * 30;

                // Find top items
                stats.MostUsedModel = stats.CostByModel.OrderByDescending(kvp => kvp.Value)
                    .FirstOrDefault().Key ?? "None";
                stats.MostUsedFeature = stats.CostByFeature.OrderByDescending(kvp => kvp.Value)
                    .FirstOrDefault().Key;
                stats.BusiestDay = stats.CostByDayOfWeek.OrderByDescending(kvp => kvp.Value)
                    .FirstOrDefault().Key;
                stats.BusiestHour = stats.CostByHourOfDay.OrderByDescending(kvp => kvp.Value)
                    .FirstOrDefault().Key;

                // Calculate efficiency metrics
                var cachedRecords = records.Count(r => r.WasCached);
                stats.CacheHitRate = records.Any() ? (double)cachedRecords / records.Count * 100 : 0;
                stats.AverageResponseTime = stats.TotalProcessingTime.TotalSeconds / Math.Max(stats.TotalRequests, 1);
                stats.AverageTokensPerRequest = (double)stats.TotalTokens / Math.Max(stats.TotalRequests, 1);
                stats.AverageCostPerRequest = stats.TotalCost / Math.Max(stats.TotalRequests, 1);

                return stats;
            });
        }

        public async Task<List<UsageBudget>> GetActiveBudgetsAsync()
        {
            return await Task.Run(() => _budgets.Where(b => b.IsActive).ToList());
        }

        public async Task SaveBudgetAsync(UsageBudget budget)
        {
            await Task.Run(() =>
            {
                var existing = _budgets.FirstOrDefault(b => b.Id == budget.Id);
                if (existing != null)
                {
                    _budgets.Remove(existing);
                }
                budget.ModifiedAt = DateTime.Now;
                _budgets.Add(budget);
            });
        }

        public async Task<Dictionary<string, ModelPricing>> GetModelPricingAsync()
        {
            return await Task.Run(() => new Dictionary<string, ModelPricing>(_modelPricing));
        }

        // Generate sample data for demonstration
        private void GenerateSampleData()
        {
            var random = new Random(42);
            var models = new[] { "gpt-4o-mini", "claude-3-5-haiku", "deepseek-chat" };
            var features = Enum.GetValues<FeatureType>();

            // Generate records for the past 30 days
            for (int daysAgo = 30; daysAgo >= 0; daysAgo--)
            {
                var date = DateTime.Today.AddDays(-daysAgo);
                var recordCount = random.Next(5, 20); // 5-20 records per day

                for (int i = 0; i < recordCount; i++)
                {
                    var hour = random.Next(8, 22); // Between 8 AM and 10 PM
                    var model = models[random.Next(models.Length)];
                    var feature = features[random.Next(features.Length)];
                    var inputTokens = random.Next(100, 2000);
                    var outputTokens = random.Next(50, 1000);

                    var record = new UsageRecord
                    {
                        Id = Guid.NewGuid(),
                        Timestamp = date.AddHours(hour).AddMinutes(random.Next(60)),
                        ModelName = model,
                        Feature = feature,
                        InputTokens = inputTokens,
                        OutputTokens = outputTokens,
                        ResponseTime = TimeSpan.FromMilliseconds(random.Next(500, 3000)),
                        WasCached = random.NextDouble() > 0.7, // 30% cache hit rate
                        SessionId = Guid.NewGuid().ToString(),
                        ChildProfileId = random.NextDouble() > 0.5 ? "child-1" : "child-2"
                    };

                    // Calculate cost based on model pricing
                    if (_modelPricing.ContainsKey(model))
                    {
                        var pricing = _modelPricing[model];
                        record.EstimatedCost = pricing.CalculateCost(
                            record.InputTokens,
                            record.OutputTokens,
                            record.WasCached);
                    }

                    _records.Add(record);
                }
            }

            // Add a sample budget
            _budgets.Add(new UsageBudget
            {
                Name = "Monthly AI Budget",
                Amount = 20.00,
                Period = UsageBudget.BudgetPeriod.Monthly,
                IsActive = true,
                SendAlerts = true,
                AlertThresholdPercent = 80,
                CreatedAt = DateTime.Now.AddMonths(-1)
            });
        }
    }
}