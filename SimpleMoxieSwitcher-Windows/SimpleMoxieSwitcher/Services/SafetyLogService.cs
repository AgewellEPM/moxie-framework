using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for persisting and managing safety-related logs
    /// </summary>
    public class SafetyLogService : ISafetyLogService
    {
        private readonly string _logPath;
        private readonly int _maxLogEntries = 10000;
        private readonly IDockerService _dockerService;

        public SafetyLogService(IDockerService dockerService)
        {
            _dockerService = dockerService;
            var appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            var appFolder = Path.Combine(appData, "SimpleMoxieSwitcher");
            Directory.CreateDirectory(appFolder);
            _logPath = Path.Combine(appFolder, "safety_logs.json");
        }

        public async Task LogEntryAsync(SafetyLogEntry entry)
        {
            // Save locally
            await SaveLocalLogAsync(entry);

            // Save to OpenMoxie database
            await SaveToDatabaseLogAsync(entry);
        }

        public async Task LogContentFlagAsync(ContentFlag flag, ConversationLog conversationLog)
        {
            var entry = new SafetyLogEntry
            {
                Timestamp = flag.Timestamp,
                TriggerPattern = flag.Category.ToString(),
                OriginalContent = flag.MessageContent,
                Action = SafetyAction.Flagged
            };

            await LogEntryAsync(entry);

            // Send parent notification if severe
            if (flag.Severity.ShouldEmailParent())
            {
                var notificationService = new ParentNotificationService();
                await notificationService.NotifyContentFlagAsync(flag.Severity, flag.Category);
            }
        }

        public async Task<List<SafetyLogEntry>> GetRecentLogsAsync(int limit = 100)
        {
            try
            {
                if (!File.Exists(_logPath))
                    return new List<SafetyLogEntry>();

                var json = await File.ReadAllTextAsync(_logPath);
                var logs = JsonSerializer.Deserialize<List<SafetyLogEntry>>(json) ?? new List<SafetyLogEntry>();
                return logs.TakeLast(limit).Reverse().ToList();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading safety logs: {ex.Message}");
                return new List<SafetyLogEntry>();
            }
        }

        public async Task<List<SafetyLogEntry>> GetLogsByPatternAsync(string pattern)
        {
            var allLogs = await GetRecentLogsAsync(_maxLogEntries);
            return allLogs.Where(l => l.TriggerPattern.Contains(pattern, StringComparison.OrdinalIgnoreCase)).ToList();
        }

        public async Task<List<SafetyLogEntry>> GetLogsByDateRangeAsync(DateTime startDate, DateTime endDate)
        {
            var allLogs = await GetRecentLogsAsync(_maxLogEntries);
            return allLogs.Where(l => l.Timestamp >= startDate && l.Timestamp <= endDate).ToList();
        }

        public async Task<SafetyStatistics> GetSafetyStatisticsAsync()
        {
            var logs = await GetRecentLogsAsync(_maxLogEntries);

            var totalEntries = logs.Count;
            var filteredCount = logs.Count(l => l.Action == SafetyAction.Filtered);
            var flaggedCount = logs.Count(l => l.Action == SafetyAction.Flagged);
            var notifiedCount = logs.Count(l => l.Action == SafetyAction.Notified);

            var patternCounts = logs.GroupBy(l => l.TriggerPattern)
                .Select(g => new SafetyPattern { Pattern = g.Key, Count = g.Count() })
                .OrderByDescending(p => p.Count)
                .Take(10)
                .ToList();

            var sevenDaysAgo = DateTime.Now.AddDays(-7);
            var recentTrend = logs.Count(l => l.Timestamp >= sevenDaysAgo);

            return new SafetyStatistics
            {
                TotalEntries = totalEntries,
                FilteredCount = filteredCount,
                FlaggedCount = flaggedCount,
                NotifiedCount = notifiedCount,
                TopPatterns = patternCounts,
                RecentTrend = recentTrend,
                LastUpdated = DateTime.Now
            };
        }

        private async Task SaveLocalLogAsync(SafetyLogEntry entry)
        {
            try
            {
                var logs = new List<SafetyLogEntry>();

                if (File.Exists(_logPath))
                {
                    var json = await File.ReadAllTextAsync(_logPath);
                    logs = JsonSerializer.Deserialize<List<SafetyLogEntry>>(json) ?? new List<SafetyLogEntry>();
                }

                logs.Add(entry);

                if (logs.Count > _maxLogEntries)
                    logs = logs.TakeLast(_maxLogEntries).ToList();

                var options = new JsonSerializerOptions { WriteIndented = true };
                var newJson = JsonSerializer.Serialize(logs, options);
                await File.WriteAllTextAsync(_logPath, newJson);

                Console.WriteLine($"📝 Safety log saved: {entry.Action} - {entry.TriggerPattern}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error saving safety log: {ex.Message}");
            }
        }

        private async Task SaveToDatabaseLogAsync(SafetyLogEntry entry)
        {
            var jsonString = JsonSerializer.Serialize(entry);

            var pythonScript = $@"
import json
from django.utils import timezone
from hive.models import MoxieDevice, PersistentData

device = MoxieDevice.objects.filter(device_id='moxie_001').first()
if device:
    persist, created = PersistentData.objects.get_or_create(device=device, defaults={{'data': {{}}}})
    data = persist.data or {{}}

    if 'safety_logs' not in data:
        data['safety_logs'] = []

    log_entry = json.loads('''{jsonString}''')
    data['safety_logs'].append(log_entry)

    if len(data['safety_logs']) > 1000:
        data['safety_logs'] = data['safety_logs'][-1000:]

    persist.data = data
    persist.save()
    print(f'Safety log saved to database: {{log_entry[""action""]}}')
";

            try
            {
                await _dockerService.ExecutePythonScriptAsync(pythonScript);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to save safety log to database: {ex.Message}");
            }
        }

        public async Task CleanupOldLogsAsync(int days)
        {
            var cutoffDate = DateTime.Now.AddDays(-days);

            try
            {
                if (!File.Exists(_logPath)) return;

                var json = await File.ReadAllTextAsync(_logPath);
                var logs = JsonSerializer.Deserialize<List<SafetyLogEntry>>(json) ?? new List<SafetyLogEntry>();

                var beforeCount = logs.Count;
                logs.RemoveAll(l => l.Timestamp < cutoffDate);
                var afterCount = logs.Count;

                var options = new JsonSerializerOptions { WriteIndented = true };
                var newJson = JsonSerializer.Serialize(logs, options);
                await File.WriteAllTextAsync(_logPath, newJson);

                Console.WriteLine($"🧹 Cleaned up {beforeCount - afterCount} safety logs older than {days} days");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error cleaning up safety logs: {ex.Message}");
            }
        }
    }
}
