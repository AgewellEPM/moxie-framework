using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Threading;
using SimpleMoxieSwitcher.Models;
using SimpleMoxieSwitcher.Services;

namespace SimpleMoxieSwitcher.ViewModels
{
    public class UsageViewModel : INotifyPropertyChanged
    {
        private readonly IUsageRepository _usageRepository;
        private DispatcherTimer _refreshTimer;

        // Published Properties
        private UsageSummary _todaySummary;
        private UsageSummary _weekSummary;
        private UsageSummary _monthSummary;
        private ObservableCollection<UsageRecord> _recentRecords = new();
        private ObservableCollection<DailyTrendData> _dailyTrend = new();
        private ObservableCollection<CostAlert> _alerts = new();
        private bool _isLoading;
        private string _errorMessage;

        // Comparison data
        private double _yesterdayCost;
        private double _lastWeekCost;
        private double _lastMonthCost;

        // Model comparison data
        private ObservableCollection<ModelComparisonData> _modelComparison = new();
        private ObservableCollection<FeatureBreakdownData> _featureBreakdown = new();

        public UsageViewModel(IUsageRepository usageRepository = null)
        {
            _usageRepository = usageRepository ?? new UsageRepository();
        }

        // Properties
        public UsageSummary TodaySummary
        {
            get => _todaySummary;
            set
            {
                if (_todaySummary != value)
                {
                    _todaySummary = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(TodayVsYesterday));
                    OnPropertyChanged(nameof(ProjectedMonthlyCost));
                }
            }
        }

        public UsageSummary WeekSummary
        {
            get => _weekSummary;
            set
            {
                if (_weekSummary != value)
                {
                    _weekSummary = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(WeekVsLastWeek));
                }
            }
        }

        public UsageSummary MonthSummary
        {
            get => _monthSummary;
            set
            {
                if (_monthSummary != value)
                {
                    _monthSummary = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(MonthVsLastMonth));
                    OnPropertyChanged(nameof(MostUsedModel));
                    OnPropertyChanged(nameof(MostExpensiveFeature));
                    OnPropertyChanged(nameof(ProjectedMonthlyCost));
                }
            }
        }

        public ObservableCollection<UsageRecord> RecentRecords
        {
            get => _recentRecords;
            set
            {
                if (_recentRecords != value)
                {
                    _recentRecords = value;
                    OnPropertyChanged();
                }
            }
        }

        public ObservableCollection<DailyTrendData> DailyTrend
        {
            get => _dailyTrend;
            set
            {
                if (_dailyTrend != value)
                {
                    _dailyTrend = value;
                    OnPropertyChanged();
                }
            }
        }

        public ObservableCollection<CostAlert> Alerts
        {
            get => _alerts;
            set
            {
                if (_alerts != value)
                {
                    _alerts = value;
                    OnPropertyChanged();
                }
            }
        }

        public bool IsLoading
        {
            get => _isLoading;
            set
            {
                if (_isLoading != value)
                {
                    _isLoading = value;
                    OnPropertyChanged();
                }
            }
        }

        public string ErrorMessage
        {
            get => _errorMessage;
            set
            {
                if (_errorMessage != value)
                {
                    _errorMessage = value;
                    OnPropertyChanged();
                }
            }
        }

        public double YesterdayCost
        {
            get => _yesterdayCost;
            set
            {
                if (_yesterdayCost != value)
                {
                    _yesterdayCost = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(TodayVsYesterday));
                }
            }
        }

        public double LastWeekCost
        {
            get => _lastWeekCost;
            set
            {
                if (_lastWeekCost != value)
                {
                    _lastWeekCost = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(WeekVsLastWeek));
                }
            }
        }

        public double LastMonthCost
        {
            get => _lastMonthCost;
            set
            {
                if (_lastMonthCost != value)
                {
                    _lastMonthCost = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(MonthVsLastMonth));
                }
            }
        }

        public ObservableCollection<ModelComparisonData> ModelComparison
        {
            get => _modelComparison;
            set
            {
                if (_modelComparison != value)
                {
                    _modelComparison = value;
                    OnPropertyChanged();
                }
            }
        }

        public ObservableCollection<FeatureBreakdownData> FeatureBreakdown
        {
            get => _featureBreakdown;
            set
            {
                if (_featureBreakdown != value)
                {
                    _featureBreakdown = value;
                    OnPropertyChanged();
                }
            }
        }

        // Computed Properties
        public double TodayVsYesterday
        {
            get
            {
                if (YesterdayCost <= 0 || TodaySummary == null) return 0;
                return ((TodaySummary.TotalCost - YesterdayCost) / YesterdayCost) * 100;
            }
        }

        public double WeekVsLastWeek
        {
            get
            {
                if (LastWeekCost <= 0 || WeekSummary == null) return 0;
                return ((WeekSummary.TotalCost - LastWeekCost) / LastWeekCost) * 100;
            }
        }

        public double MonthVsLastMonth
        {
            get
            {
                if (LastMonthCost <= 0 || MonthSummary == null) return 0;
                return ((MonthSummary.TotalCost - LastMonthCost) / LastMonthCost) * 100;
            }
        }

        public double ProjectedMonthlyCost
        {
            get
            {
                if (TodaySummary == null) return 0;
                var dayOfMonth = DateTime.Now.Day;
                var daysInMonth = DateTime.DaysInMonth(DateTime.Now.Year, DateTime.Now.Month);
                var averageDailyCost = (MonthSummary?.TotalCost ?? 0) / dayOfMonth;
                return averageDailyCost * daysInMonth;
            }
        }

        public string MostUsedModel
        {
            get
            {
                if (MonthSummary?.ByModel == null || !MonthSummary.ByModel.Any())
                    return null;
                return MonthSummary.ByModel.OrderByDescending(kvp => kvp.Value.Count).FirstOrDefault().Key;
            }
        }

        public FeatureType? MostExpensiveFeature
        {
            get
            {
                if (MonthSummary?.ByFeature == null || !MonthSummary.ByFeature.Any())
                    return null;
                return MonthSummary.ByFeature.OrderByDescending(kvp => kvp.Value.Cost).FirstOrDefault().Key;
            }
        }

        // Data Loading Methods
        public async Task LoadAllDataAsync()
        {
            IsLoading = true;
            ErrorMessage = null;

            try
            {
                // Create tasks for concurrent loading
                var todayTask = _usageRepository.CalculateDailySummaryAsync(DateTime.Today);
                var weekTask = _usageRepository.CalculateWeeklySummaryAsync();
                var monthTask = _usageRepository.CalculateMonthlySummaryAsync();
                var recentTask = _usageRepository.GetRecentRecordsAsync(50);
                var trendTask = _usageRepository.CalculateDailyTrendAsync(7);
                var alertsTask = _usageRepository.DetectCostAnomaliesAsync();

                var yesterday = DateTime.Today.AddDays(-1);
                var yesterdayTask = _usageRepository.CalculateDailySummaryAsync(yesterday);

                // Wait for all tasks
                await Task.WhenAll(todayTask, weekTask, monthTask, recentTask, trendTask, alertsTask, yesterdayTask);

                // Update properties
                TodaySummary = todayTask.Result;
                WeekSummary = weekTask.Result;
                MonthSummary = monthTask.Result;

                // Update collections
                RecentRecords.Clear();
                foreach (var record in recentTask.Result)
                {
                    RecentRecords.Add(record);
                }

                DailyTrend.Clear();
                foreach (var trend in trendTask.Result)
                {
                    DailyTrend.Add(new DailyTrendData { Date = trend.date, Cost = trend.cost });
                }

                Alerts.Clear();
                foreach (var alert in alertsTask.Result)
                {
                    Alerts.Add(alert);
                }

                YesterdayCost = yesterdayTask.Result.TotalCost;

                // Calculate comparison periods
                await CalculateComparisonsAsync();

                // Build model comparison data
                BuildModelComparison();

                // Build feature breakdown
                BuildFeatureBreakdown();
            }
            catch (Exception ex)
            {
                ErrorMessage = $"Failed to load usage data: {ex.Message}";
            }
            finally
            {
                IsLoading = false;
            }
        }

        private async Task CalculateComparisonsAsync()
        {
            try
            {
                // Last week
                var lastWeekStart = DateTime.Today.AddDays(-((int)DateTime.Today.DayOfWeek + 7));
                var lastWeekEnd = lastWeekStart.AddDays(6);
                var lastWeekRecords = await _usageRepository.GetUsageRecordsAsync(lastWeekStart, lastWeekEnd);
                LastWeekCost = lastWeekRecords.Sum(r => r.EstimatedCost);

                // Last month
                var lastMonthStart = new DateTime(DateTime.Today.Year, DateTime.Today.Month, 1).AddMonths(-1);
                var lastMonthEnd = lastMonthStart.AddMonths(1).AddDays(-1);
                var lastMonthRecords = await _usageRepository.GetUsageRecordsAsync(lastMonthStart, lastMonthEnd);
                LastMonthCost = lastMonthRecords.Sum(r => r.EstimatedCost);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to calculate comparisons: {ex}");
            }
        }

        private void BuildModelComparison()
        {
            if (MonthSummary == null) return;

            ModelComparison.Clear();
            var sortedModels = MonthSummary.ByModel.OrderByDescending(kvp => kvp.Value.Cost);

            foreach (var kvp in sortedModels)
            {
                ModelComparison.Add(new ModelComparisonData
                {
                    ModelName = kvp.Key,
                    TotalCost = kvp.Value.Cost,
                    UsageCount = kvp.Value.Count,
                    AverageCost = kvp.Value.Cost / Math.Max(kvp.Value.Count, 1)
                });
            }
        }

        private void BuildFeatureBreakdown()
        {
            if (MonthSummary == null) return;

            FeatureBreakdown.Clear();
            var sortedFeatures = MonthSummary.ByFeature.OrderByDescending(kvp => kvp.Value.Cost);

            foreach (var kvp in sortedFeatures)
            {
                FeatureBreakdown.Add(new FeatureBreakdownData
                {
                    Feature = kvp.Key,
                    TotalCost = kvp.Value.Cost,
                    UsageCount = kvp.Value.Count,
                    Icon = kvp.Key.GetIcon(),
                    Name = kvp.Key.GetDisplayName()
                });
            }
        }

        // Auto Refresh Methods
        public void StartAutoRefresh()
        {
            StopAutoRefresh(); // Stop any existing timer

            _refreshTimer = new DispatcherTimer
            {
                Interval = TimeSpan.FromSeconds(60)
            };
            _refreshTimer.Tick += async (sender, e) => await LoadAllDataAsync();
            _refreshTimer.Start();
        }

        public void StopAutoRefresh()
        {
            _refreshTimer?.Stop();
            _refreshTimer = null;
        }

        // Cost Saving Recommendations
        public List<string> GenerateSavingRecommendations()
        {
            var recommendations = new List<string>();

            // Check if using expensive models
            if (!string.IsNullOrEmpty(MostUsedModel))
            {
                if (MostUsedModel.Contains("gpt-4o") && !MostUsedModel.Contains("mini"))
                {
                    var potentialSaving = (MonthSummary?.TotalCost ?? 0) * 0.9;
                    recommendations.Add($"Switch to GPT-4o-mini to save ~${potentialSaving:F2}/month");
                }
                else if (MostUsedModel.Contains("claude-3-opus"))
                {
                    var potentialSaving = (MonthSummary?.TotalCost ?? 0) * 0.8;
                    recommendations.Add($"Switch to Claude 3.5 Sonnet to save ~${potentialSaving:F2}/month");
                }
            }

            // Suggest DeepSeek for high volume
            if ((MonthSummary?.RecordCount ?? 0) > 500)
            {
                recommendations.Add("Consider DeepSeek for high-volume usage - 90% cheaper than GPT-4o");
            }

            // Feature-specific recommendations
            if (MostExpensiveFeature.HasValue)
            {
                switch (MostExpensiveFeature.Value)
                {
                    case FeatureType.Story:
                        recommendations.Add("Story generation uses more tokens - consider shorter stories");
                        break;
                    case FeatureType.Learning:
                        recommendations.Add("Learning sessions can be optimized with more concise prompts");
                        break;
                    default:
                        break;
                }
            }

            return recommendations;
        }

        // Export Functions
        public string ExportUsageReport()
        {
            var report = new StringBuilder();
            report.AppendLine("Moxie AI Usage Report");
            report.AppendLine($"Generated: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
            report.AppendLine();

            if (TodaySummary != null)
            {
                report.AppendLine($"Today: {TodaySummary.FormattedTotalCost} ({TodaySummary.RecordCount} requests)");
            }

            if (WeekSummary != null)
            {
                report.AppendLine($"This Week: {WeekSummary.FormattedTotalCost} ({WeekSummary.RecordCount} requests)");
            }

            if (MonthSummary != null)
            {
                report.AppendLine($"This Month: {MonthSummary.FormattedTotalCost} ({MonthSummary.RecordCount} requests)");
                report.AppendLine();

                report.AppendLine("By Model:");
                foreach (var kvp in MonthSummary.ByModel.OrderByDescending(x => x.Value.Cost))
                {
                    report.AppendLine($"  {kvp.Key}: ${kvp.Value.Cost:F2} ({kvp.Value.Count} uses)");
                }

                report.AppendLine();
                report.AppendLine("By Feature:");
                foreach (var kvp in MonthSummary.ByFeature.OrderByDescending(x => x.Value.Cost))
                {
                    report.AppendLine($"  {kvp.Key.GetDisplayName()}: ${kvp.Value.Cost:F2} ({kvp.Value.Count} uses)");
                }
            }

            report.AppendLine();
            report.AppendLine("Recommendations:");
            foreach (var recommendation in GenerateSavingRecommendations())
            {
                report.AppendLine($"• {recommendation}");
            }

            return report.ToString();
        }

        // Cleanup
        public void Dispose()
        {
            StopAutoRefresh();
        }

        // INotifyPropertyChanged Implementation
        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    // Supporting Data Models
    public class DailyTrendData
    {
        public DateTime Date { get; set; }
        public double Cost { get; set; }
    }

    public class ModelComparisonData
    {
        public Guid Id { get; } = Guid.NewGuid();
        public string ModelName { get; set; }
        public double TotalCost { get; set; }
        public int UsageCount { get; set; }
        public double AverageCost { get; set; }

        public string FormattedTotalCost => $"${TotalCost:F2}";
        public string FormattedAverageCost => $"${AverageCost:F4}";
    }

    public class FeatureBreakdownData
    {
        public Guid Id { get; } = Guid.NewGuid();
        public FeatureType Feature { get; set; }
        public double TotalCost { get; set; }
        public int UsageCount { get; set; }
        public string Icon { get; set; }
        public string Name { get; set; }

        public string FormattedCost => $"${TotalCost:F2}";

        public double Percentage { get; set; } // This will be calculated relative to total in the view
    }

    // Extension methods for FeatureType
    public static class FeatureTypeExtensions
    {
        public static string GetIcon(this FeatureType featureType)
        {
            return featureType switch
            {
                FeatureType.Chat => "💬",
                FeatureType.Story => "📖",
                FeatureType.Learning => "🎓",
                FeatureType.Translation => "🌍",
                FeatureType.Vocabulary => "📚",
                FeatureType.Creative => "✨",
                FeatureType.Games => "🎮",
                FeatureType.Listening => "👂",
                _ => "❓"
            };
        }

        public static string GetDisplayName(this FeatureType featureType)
        {
            return featureType switch
            {
                FeatureType.Chat => "Chat",
                FeatureType.Story => "Story Generation",
                FeatureType.Learning => "Language Learning",
                FeatureType.Translation => "Translation",
                FeatureType.Vocabulary => "Vocabulary",
                FeatureType.Creative => "Creative Writing",
                FeatureType.Games => "Games",
                FeatureType.Listening => "Listening Practice",
                _ => "Other"
            };
        }
    }
}