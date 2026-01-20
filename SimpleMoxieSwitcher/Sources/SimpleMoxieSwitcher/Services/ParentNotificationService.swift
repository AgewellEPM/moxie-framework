import Foundation
import UserNotifications

/// Service for sending notifications to parents about child's Moxie usage
@MainActor
class ParentNotificationService {
    static let shared = ParentNotificationService()

    private init() {}

    // MARK: - Notification Types

    enum NotificationType {
        case contentFlag(severity: FlagSeverity, category: FlagCategory)
        case highUsage(cost: Double)
        case budgetWarning(spent: Double, limit: Double)
        case timeRestriction(event: String)
        case modeSwitch(from: OperationalMode, to: OperationalMode)
        case emergencyOverride

        var title: String {
            switch self {
            case .contentFlag(let severity, let category):
                return "\(severity == .critical ? "⚠️ URGENT" : "ℹ️") Content Flag: \(category.rawValue.capitalized)"
            case .highUsage:
                return "💰 High Usage Alert"
            case .budgetWarning:
                return "💳 Budget Warning"
            case .timeRestriction:
                return "🕐 Time Restriction"
            case .modeSwitch:
                return "🔄 Mode Switch"
            case .emergencyOverride:
                return "🆘 Emergency Override Used"
            }
        }

        var body: String {
            switch self {
            case .contentFlag(let severity, let category):
                return "Your child's conversation contained \(severity == .critical ? "urgent" : "potential") content related to \(category.rawValue). Please review in Parent Console."
            case .highUsage(let cost):
                return String(format: "AI usage today: $%.2f. This is higher than usual. Consider reviewing usage in Parent Console.", cost)
            case .budgetWarning(let spent, let limit):
                return String(format: "You've used $%.2f of your $%.2f monthly budget (%.0f%%).", spent, limit, (spent/limit) * 100)
            case .timeRestriction(let event):
                return "Time restriction event: \(event)"
            case .modeSwitch(let from, let to):
                return "Moxie switched from \(from == .child ? "Child Mode" : "Parent Console") to \(to == .child ? "Child Mode" : "Parent Console")"
            case .emergencyOverride:
                return "Emergency override was activated to grant temporary access during restricted hours."
            }
        }

        var identifier: String {
            switch self {
            case .contentFlag: return "content-flag"
            case .highUsage: return "high-usage"
            case .budgetWarning: return "budget-warning"
            case .timeRestriction: return "time-restriction"
            case .modeSwitch: return "mode-switch"
            case .emergencyOverride: return "emergency-override"
            }
        }

        var shouldSendEmail: Bool {
            switch self {
            case .contentFlag(let severity, _):
                return severity == .high || severity == .critical
            case .budgetWarning:
                return true
            case .emergencyOverride:
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Request Permissions

    func requestNotificationPermissions() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Error requesting notification permissions: \(error)")
            return false
        }
    }

    // MARK: - Send Notification

    func sendNotification(_ type: NotificationType) async {
        // Send local notification
        await sendLocalNotification(type)

        // Send email if critical
        if type.shouldSendEmail {
            await sendEmailNotification(type)
        }

        // Log notification
        await logNotification(type)
    }

    private func sendLocalNotification(_ type: NotificationType) async {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = type.body
        content.sound = .default
        content.badge = 1

        // Add category for actions
        content.categoryIdentifier = type.identifier

        // Create trigger (deliver immediately)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        let center = UNUserNotificationCenter.current()
        do {
            try await center.add(request)
            print("📬 Notification sent: \(type.title)")
        } catch {
            print("Error sending notification: \(error)")
        }
    }

    private func sendEmailNotification(_ type: NotificationType) async {
        // Load parent account
        guard let parentAccount = loadParentAccount() else {
            print("No parent account found - cannot send email")
            return
        }

        guard !parentAccount.email.isEmpty else {
            print("No parent email configured")
            return
        }

        // In a production app, this would integrate with an email service
        // For now, we'll create a structured email payload
        let emailPayload: [String: Any] = [
            "to": parentAccount.email,
            "from": "moxie-safety@example.com",
            "subject": type.title,
            "body": createEmailBody(for: type, parentName: parentAccount.email),
            "timestamp": Date().ISO8601Format()
        ]

        // Log email for now (in production, send via email service API)
        print("📧 Email notification prepared:")
        print("   To: \(parentAccount.email)")
        print("   Subject: \(type.title)")
        print("   Would send via email service in production")

        // Save email to outbox for manual review
        saveEmailToOutbox(emailPayload)
    }

    private func createEmailBody(for type: NotificationType, parentName: String) -> String {
        var body = "Dear \(parentName),\n\n"

        switch type {
        case .contentFlag(let severity, let category):
            body += "This is a \(severity == .critical ? "CRITICAL" : "important") safety alert from Moxie.\n\n"
            body += "Your child's conversation contained content flagged as \(category.rawValue).\n\n"
            body += "**Recommended Actions:**\n"
            body += "1. Review the conversation in your Parent Console\n"
            body += "2. Talk with your child about the topic if appropriate\n"
            body += "3. Adjust safety settings if needed\n\n"
            body += "Severity: \(severity.rawValue.capitalized)\n"
            body += "Category: \(category.rawValue.capitalized)\n\n"

        case .budgetWarning(let spent, let limit):
            body += "You're approaching your monthly AI usage budget.\n\n"
            body += String(format: "Spent: $%.2f / $%.2f (%.0f%%)\n\n", spent, limit, (spent/limit) * 100)
            body += "**Consider:**\n"
            body += "- Switching to DeepSeek (90% cheaper)\n"
            body += "- Reviewing usage patterns in Parent Console\n"
            body += "- Adjusting your budget if needed\n\n"

        case .emergencyOverride:
            body += "Emergency override was activated to grant your child access during restricted hours.\n\n"
            body += "This may indicate a genuine need or an attempt to bypass time restrictions.\n\n"
            body += "**Recommended Actions:**\n"
            body += "1. Check the conversation log to understand why override was needed\n"
            body += "2. Talk with your child about appropriate emergency use\n"
            body += "3. Review time restriction settings\n\n"

        default:
            body += type.body + "\n\n"
        }

        body += "---\n"
        body += "View full details in your Parent Console\n"
        body += "This is an automated safety notification from Moxie\n\n"
        body += "Timestamp: \(Date().formatted())\n"

        return body
    }

    private func saveEmailToOutbox(_ payload: [String: Any]) {
        let outboxPath = AppPaths.applicationSupport.appendingPathComponent("email_outbox.json")

        do {
            var outbox: [[String: Any]] = []

            // Load existing outbox
            if FileManager.default.fileExists(atPath: outboxPath.path) {
                let data = try Data(contentsOf: outboxPath)
                if let existing = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    outbox = existing
                }
            }

            // Add new email
            outbox.append(payload)

            // Save back
            let data = try JSONSerialization.data(withJSONObject: outbox, options: .prettyPrinted)
            try data.write(to: outboxPath)

            print("📬 Email saved to outbox: \(outboxPath.path)")
        } catch {
            print("Error saving email to outbox: \(error)")
        }
    }

    private func logNotification(_ type: NotificationType) async {
        let log: [String: Any] = [
            "type": type.identifier,
            "title": type.title,
            "body": type.body,
            "timestamp": Date().ISO8601Format(),
            "sentEmail": type.shouldSendEmail
        ]

        let logPath = AppPaths.applicationSupport.appendingPathComponent("notification_log.json")

        do {
            var logs: [[String: Any]] = []

            // Load existing logs
            if FileManager.default.fileExists(atPath: logPath.path) {
                let data = try Data(contentsOf: logPath)
                if let existing = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    logs = existing
                }
            }

            // Add new log
            logs.append(log)

            // Keep only last 1000 notifications
            if logs.count > 1000 {
                logs = Array(logs.suffix(1000))
            }

            // Save back
            let data = try JSONSerialization.data(withJSONObject: logs, options: .prettyPrinted)
            try data.write(to: logPath)
        } catch {
            print("Error logging notification: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func loadParentAccount() -> ParentAccount? {
        let accountPath = AppPaths.applicationSupport.appendingPathComponent("parent_account.json")

        guard FileManager.default.fileExists(atPath: accountPath.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: accountPath)
            let account = try JSONDecoder().decode(ParentAccount.self, from: data)
            return account
        } catch {
            print("Error loading parent account: \(error)")
            return nil
        }
    }

    // MARK: - Notification Categories

    func setupNotificationCategories() {
        let center = UNUserNotificationCenter.current()

        // Content flag actions
        let viewAction = UNNotificationAction(
            identifier: "VIEW_CONVERSATION",
            title: "View Conversation",
            options: .foreground
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: []
        )

        let contentFlagCategory = UNNotificationCategory(
            identifier: "content-flag",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        // Budget warning actions
        let viewUsageAction = UNNotificationAction(
            identifier: "VIEW_USAGE",
            title: "View Usage",
            options: .foreground
        )

        let budgetCategory = UNNotificationCategory(
            identifier: "budget-warning",
            actions: [viewUsageAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        // Set categories
        center.setNotificationCategories([contentFlagCategory, budgetCategory])
    }

    // MARK: - Public Helper Methods

    /// Send a content flag notification
    func notifyContentFlag(severity: FlagSeverity, category: FlagCategory) async {
        await sendNotification(.contentFlag(severity: severity, category: category))
    }

    /// Send a high usage alert
    func notifyHighUsage(cost: Double) async {
        await sendNotification(.highUsage(cost: cost))
    }

    /// Send a budget warning
    func notifyBudgetWarning(spent: Double, limit: Double) async {
        await sendNotification(.budgetWarning(spent: spent, limit: limit))
    }

    /// Send a mode switch notification
    func notifyModeSwitch(from: OperationalMode, to: OperationalMode) async {
        await sendNotification(.modeSwitch(from: from, to: to))
    }

    /// Send an emergency override notification
    func notifyEmergencyOverride() async {
        await sendNotification(.emergencyOverride)
    }
}
