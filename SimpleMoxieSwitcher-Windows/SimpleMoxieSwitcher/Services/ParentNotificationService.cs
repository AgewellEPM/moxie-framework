using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Toolkit.Uwp.Notifications;
using SimpleMoxieSwitcher.Models;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Service for sending notifications to parents about child's Moxie usage
    /// </summary>
    public class ParentNotificationService : IParentNotificationService
    {
        private readonly string _outboxPath;
        private readonly string _logPath;

        public ParentNotificationService()
        {
            var appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            var appFolder = Path.Combine(appData, "SimpleMoxieSwitcher");
            Directory.CreateDirectory(appFolder);
            _outboxPath = Path.Combine(appFolder, "email_outbox.json");
            _logPath = Path.Combine(appFolder, "notification_log.json");
        }

        public async Task NotifyContentFlagAsync(FlagSeverity severity, FlagCategory category)
        {
            var notification = new ParentNotificationData
            {
                Type = NotificationType.ContentFlag,
                Severity = severity,
                Category = category
            };
            await SendNotificationAsync(notification);
        }

        public async Task NotifyHighUsageAsync(double cost)
        {
            var notification = new ParentNotificationData
            {
                Type = NotificationType.HighUsage,
                Cost = cost
            };
            await SendNotificationAsync(notification);
        }

        public async Task NotifyBudgetWarningAsync(double spent, double limit)
        {
            var notification = new ParentNotificationData
            {
                Type = NotificationType.BudgetWarning,
                Spent = spent,
                Limit = limit
            };
            await SendNotificationAsync(notification);
        }

        public async Task NotifyModeSwitchAsync(OperationalMode from, OperationalMode to)
        {
            var notification = new ParentNotificationData
            {
                Type = NotificationType.ModeSwitch,
                FromMode = from,
                ToMode = to
            };
            await SendNotificationAsync(notification);
        }

        public async Task NotifyEmergencyOverrideAsync()
        {
            var notification = new ParentNotificationData
            {
                Type = NotificationType.EmergencyOverride
            };
            await SendNotificationAsync(notification);
        }

        private async Task SendNotificationAsync(ParentNotificationData notification)
        {
            // Send Windows notification
            SendWindowsNotification(notification);

            // Send email if critical
            if (notification.ShouldSendEmail)
            {
                await SendEmailNotificationAsync(notification);
            }

            // Log notification
            await LogNotificationAsync(notification);
        }

        private void SendWindowsNotification(ParentNotificationData notification)
        {
            try
            {
                new ToastContentBuilder()
                    .AddText(notification.Title)
                    .AddText(notification.Body)
                    .Show();

                Console.WriteLine($"📬 Notification sent: {notification.Title}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error sending Windows notification: {ex.Message}");
            }
        }

        private async Task SendEmailNotificationAsync(ParentNotificationData notification)
        {
            var parentAccount = LoadParentAccount();
            if (parentAccount == null || string.IsNullOrEmpty(parentAccount.Email))
            {
                Console.WriteLine("No parent email configured");
                return;
            }

            var emailPayload = new Dictionary<string, object>
            {
                ["to"] = parentAccount.Email,
                ["from"] = "moxie-safety@example.com",
                ["subject"] = notification.Title,
                ["body"] = CreateEmailBody(notification, parentAccount.Email),
                ["timestamp"] = DateTime.Now.ToString("O")
            };

            Console.WriteLine($"📧 Email notification prepared:");
            Console.WriteLine($"   To: {parentAccount.Email}");
            Console.WriteLine($"   Subject: {notification.Title}");
            Console.WriteLine($"   Would send via email service in production");

            await SaveEmailToOutboxAsync(emailPayload);
        }

        private string CreateEmailBody(ParentNotificationData notification, string parentEmail)
        {
            var body = $"Dear {parentEmail},\n\n";

            switch (notification.Type)
            {
                case NotificationType.ContentFlag:
                    body += $"This is a {(notification.Severity == FlagSeverity.Critical ? "CRITICAL" : "important")} safety alert from Moxie.\n\n";
                    body += $"Your child's conversation contained content flagged as {notification.Category}.\n\n";
                    body += "**Recommended Actions:**\n";
                    body += "1. Review the conversation in your Parent Console\n";
                    body += "2. Talk with your child about the topic if appropriate\n";
                    body += "3. Adjust safety settings if needed\n\n";
                    break;

                case NotificationType.BudgetWarning:
                    body += "You're approaching your monthly AI usage budget.\n\n";
                    body += $"Spent: ${notification.Spent:F2} / ${notification.Limit:F2} ({notification.Spent / notification.Limit * 100:F0}%)\n\n";
                    body += "**Consider:**\n";
                    body += "- Switching to DeepSeek (90% cheaper)\n";
                    body += "- Reviewing usage patterns in Parent Console\n";
                    body += "- Adjusting your budget if needed\n\n";
                    break;

                case NotificationType.EmergencyOverride:
                    body += "Emergency override was activated to grant your child access during restricted hours.\n\n";
                    body += "**Recommended Actions:**\n";
                    body += "1. Check the conversation log to understand why override was needed\n";
                    body += "2. Talk with your child about appropriate emergency use\n";
                    body += "3. Review time restriction settings\n\n";
                    break;

                default:
                    body += notification.Body + "\n\n";
                    break;
            }

            body += "---\n";
            body += "View full details in your Parent Console\n";
            body += "This is an automated safety notification from Moxie\n\n";
            body += $"Timestamp: {DateTime.Now}\n";

            return body;
        }

        private async Task SaveEmailToOutboxAsync(Dictionary<string, object> payload)
        {
            try
            {
                var outbox = new List<Dictionary<string, object>>();

                if (File.Exists(_outboxPath))
                {
                    var json = await File.ReadAllTextAsync(_outboxPath);
                    outbox = JsonSerializer.Deserialize<List<Dictionary<string, object>>>(json) ?? new List<Dictionary<string, object>>();
                }

                outbox.Add(payload);

                var options = new JsonSerializerOptions { WriteIndented = true };
                var newJson = JsonSerializer.Serialize(outbox, options);
                await File.WriteAllTextAsync(_outboxPath, newJson);

                Console.WriteLine($"📬 Email saved to outbox: {_outboxPath}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error saving email to outbox: {ex.Message}");
            }
        }

        private async Task LogNotificationAsync(ParentNotificationData notification)
        {
            var log = new Dictionary<string, object>
            {
                ["type"] = notification.Type.ToString(),
                ["title"] = notification.Title,
                ["body"] = notification.Body,
                ["timestamp"] = DateTime.Now.ToString("O"),
                ["sentEmail"] = notification.ShouldSendEmail
            };

            try
            {
                var logs = new List<Dictionary<string, object>>();

                if (File.Exists(_logPath))
                {
                    var json = await File.ReadAllTextAsync(_logPath);
                    logs = JsonSerializer.Deserialize<List<Dictionary<string, object>>>(json) ?? new List<Dictionary<string, object>>();
                }

                logs.Add(log);

                if (logs.Count > 1000)
                    logs = logs.TakeLast(1000).ToList();

                var options = new JsonSerializerOptions { WriteIndented = true };
                var newJson = JsonSerializer.Serialize(logs, options);
                await File.WriteAllTextAsync(_logPath, newJson);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error logging notification: {ex.Message}");
            }
        }

        private ParentAccount LoadParentAccount()
        {
            var appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            var accountPath = Path.Combine(appData, "SimpleMoxieSwitcher", "parent_account.json");

            if (!File.Exists(accountPath))
                return null;

            try
            {
                var json = File.ReadAllText(accountPath);
                return JsonSerializer.Deserialize<ParentAccount>(json);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading parent account: {ex.Message}");
                return null;
            }
        }
    }

    public class ParentNotificationData
    {
        public NotificationType Type { get; set; }
        public FlagSeverity Severity { get; set; }
        public FlagCategory Category { get; set; }
        public double Cost { get; set; }
        public double Spent { get; set; }
        public double Limit { get; set; }
        public OperationalMode FromMode { get; set; }
        public OperationalMode ToMode { get; set; }

        public string Title => Type switch
        {
            NotificationType.ContentFlag => $"{(Severity == FlagSeverity.Critical ? "⚠️ URGENT" : "ℹ️")} Content Flag: {Category}",
            NotificationType.HighUsage => "💰 High Usage Alert",
            NotificationType.BudgetWarning => "💳 Budget Warning",
            NotificationType.TimeRestriction => "🕐 Time Restriction",
            NotificationType.ModeSwitch => "🔄 Mode Switch",
            NotificationType.EmergencyOverride => "🆘 Emergency Override Used",
            _ => "Moxie Notification"
        };

        public string Body => Type switch
        {
            NotificationType.ContentFlag => $"Your child's conversation contained {(Severity == FlagSeverity.Critical ? "urgent" : "potential")} content related to {Category}. Please review in Parent Console.",
            NotificationType.HighUsage => $"AI usage today: ${Cost:F2}. This is higher than usual.",
            NotificationType.BudgetWarning => $"You've used ${Spent:F2} of your ${Limit:F2} monthly budget ({Spent / Limit * 100:F0}%).",
            NotificationType.ModeSwitch => $"Moxie switched from {(FromMode == OperationalMode.Child ? "Child Mode" : "Parent Console")} to {(ToMode == OperationalMode.Child ? "Child Mode" : "Parent Console")}",
            NotificationType.EmergencyOverride => "Emergency override was activated to grant temporary access during restricted hours.",
            _ => ""
        };

        public bool ShouldSendEmail => Type switch
        {
            NotificationType.ContentFlag => Severity == FlagSeverity.High || Severity == FlagSeverity.Critical,
            NotificationType.BudgetWarning => true,
            NotificationType.EmergencyOverride => true,
            _ => false
        };
    }

    public enum NotificationType
    {
        ContentFlag,
        HighUsage,
        BudgetWarning,
        TimeRestriction,
        ModeSwitch,
        EmergencyOverride
    }
}
