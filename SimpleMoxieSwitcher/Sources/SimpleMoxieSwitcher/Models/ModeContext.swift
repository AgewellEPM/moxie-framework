import Foundation

// MARK: - Operational Mode
enum OperationalMode: String, Codable {
    case child = "child"
    case adult = "adult"

    var displayName: String {
        switch self {
        case .child:
            return "Child Mode"
        case .adult:
            return "Parent Console"
        }
    }

    var badgeText: String {
        switch self {
        case .child:
            return "👋 Hi"
        case .adult:
            return "🔒 Parent Console"
        }
    }

    var primaryColor: String {
        switch self {
        case .child:
            return "#00D4FF"  // Cyan
        case .adult:
            return "#9D4EDD"  // Purple
        }
    }
}

// MARK: - Mode Context
class ModeContext: ObservableObject, Codable {
    @Published var currentMode: OperationalMode
    @Published var sessionStartedAt: Date
    @Published var lastActivityAt: Date
    @Published var pinAttempts: [PINAttempt]
    @Published var autoLockSchedule: AutoLockSchedule?
    @Published var emergencyMode: Bool
    @Published var emergencyExpiresAt: Date?

    static let shared = ModeContext()

    enum CodingKeys: String, CodingKey {
        case currentMode
        case sessionStartedAt
        case lastActivityAt
        case pinAttempts
        case autoLockSchedule
        case emergencyMode
        case emergencyExpiresAt
    }

    init() {
        self.currentMode = .child  // Default to child mode
        self.sessionStartedAt = Date()
        self.lastActivityAt = Date()
        self.pinAttempts = []
        self.autoLockSchedule = nil
        self.emergencyMode = false
        self.emergencyExpiresAt = nil
    }

    // MARK: - Session Management

    // Update activity timestamp
    func recordActivity() {
        lastActivityAt = Date()
    }

    // Check if session should timeout (30 min inactivity in adult mode)
    var shouldTimeout: Bool {
        guard currentMode == .adult else { return false }
        let inactiveSeconds = Date().timeIntervalSince(lastActivityAt)
        return inactiveSeconds > 1800  // 30 minutes
    }

    // Get session duration
    var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartedAt)
    }

    // MARK: - PIN Lockout Management

    // Check if PIN entry is locked (3 failed attempts in 5 minutes)
    var isPINLocked: Bool {
        let recentAttempts = pinAttempts.filter {
            Date().timeIntervalSince($0.timestamp) < 300  // Last 5 minutes
        }
        let failedAttempts = recentAttempts.filter { !$0.success }.count
        return failedAttempts >= 3
    }

    // Time remaining in PIN lockout
    var pinLockoutTimeRemaining: TimeInterval? {
        guard isPINLocked else { return nil }
        let recentAttempts = pinAttempts.filter {
            Date().timeIntervalSince($0.timestamp) < 300
        }
        guard let firstFailed = recentAttempts.first(where: { !$0.success }) else { return nil }
        let lockoutEnd = firstFailed.timestamp.addingTimeInterval(300)
        return max(0, lockoutEnd.timeIntervalSince(Date()))
    }

    // Record PIN attempt
    func recordPINAttempt(success: Bool) {
        let attempt = PINAttempt(timestamp: Date(), success: success)
        pinAttempts.append(attempt)

        // Keep only last 10 attempts
        if pinAttempts.count > 10 {
            pinAttempts.removeFirst()
        }
    }

    // Clear old PIN attempts
    func clearOldPINAttempts() {
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        pinAttempts.removeAll { $0.timestamp < fiveMinutesAgo }
    }

    // MARK: - Mode Switching

    func switchMode(to mode: OperationalMode) {
        currentMode = mode
        sessionStartedAt = Date()
        lastActivityAt = Date()
    }

    // MARK: - Emergency Override

    func activateEmergencyMode(duration: TimeInterval = 900) {
        emergencyMode = true
        emergencyExpiresAt = Date().addingTimeInterval(duration)
    }

    func deactivateEmergencyMode() {
        emergencyMode = false
        emergencyExpiresAt = nil
    }

    var isEmergencyModeActive: Bool {
        guard emergencyMode, let expiresAt = emergencyExpiresAt else { return false }
        return Date() < expiresAt
    }

    // MARK: - Time Restrictions

    func isCurrentlyLocked() -> Bool {
        // Emergency mode overrides locks
        if isEmergencyModeActive {
            return false
        }

        guard let schedule = autoLockSchedule, schedule.enabled else {
            return false
        }

        let now = Date()
        let calendar = Calendar.current
        let isWeekend = calendar.isDateInWeekend(now)

        let windows = isWeekend ? schedule.weekendWindows : schedule.weekdayWindows
        let enabledWindows = windows.filter { $0.enabled }

        // If any enabled window contains current time, NOT locked
        for window in enabledWindows {
            if window.contains(now) {
                return false
            }
        }

        // No window contains current time = locked
        return true
    }

    func timeUntilNextUnlock() -> TimeInterval? {
        guard isCurrentlyLocked() else { return nil }
        guard let schedule = autoLockSchedule else { return nil }

        let now = Date()
        let calendar = Calendar.current
        let isWeekend = calendar.isDateInWeekend(now)

        let windows = isWeekend ? schedule.weekendWindows : schedule.weekdayWindows
        let enabledWindows = windows.filter { $0.enabled }

        // Find next window start time
        var nearestUnlock: Date?

        for window in enabledWindows {
            let components = calendar.dateComponents([.year, .month, .day], from: now)
            var startComponents = components
            startComponents.hour = window.startTime.hour
            startComponents.minute = window.startTime.minute

            if let windowStart = calendar.date(from: startComponents) {
                if windowStart > now {
                    if nearestUnlock == nil || windowStart < nearestUnlock! {
                        nearestUnlock = windowStart
                    }
                } else {
                    // Try tomorrow
                    if let tomorrow = calendar.date(byAdding: .day, value: 1, to: windowStart) {
                        if nearestUnlock == nil || tomorrow < nearestUnlock! {
                            nearestUnlock = tomorrow
                        }
                    }
                }
            }
        }

        return nearestUnlock?.timeIntervalSince(now)
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentMode = try container.decode(OperationalMode.self, forKey: .currentMode)
        sessionStartedAt = try container.decode(Date.self, forKey: .sessionStartedAt)
        lastActivityAt = try container.decode(Date.self, forKey: .lastActivityAt)
        pinAttempts = try container.decode([PINAttempt].self, forKey: .pinAttempts)
        autoLockSchedule = try container.decodeIfPresent(AutoLockSchedule.self, forKey: .autoLockSchedule)
        emergencyMode = try container.decode(Bool.self, forKey: .emergencyMode)
        emergencyExpiresAt = try container.decodeIfPresent(Date.self, forKey: .emergencyExpiresAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentMode, forKey: .currentMode)
        try container.encode(sessionStartedAt, forKey: .sessionStartedAt)
        try container.encode(lastActivityAt, forKey: .lastActivityAt)
        try container.encode(pinAttempts, forKey: .pinAttempts)
        try container.encodeIfPresent(autoLockSchedule, forKey: .autoLockSchedule)
        try container.encode(emergencyMode, forKey: .emergencyMode)
        try container.encodeIfPresent(emergencyExpiresAt, forKey: .emergencyExpiresAt)
    }
}

// MARK: - PIN Attempt
struct PINAttempt: Codable {
    let timestamp: Date
    let success: Bool
    let ipAddress: String?  // For institutional deployments

    init(timestamp: Date, success: Bool, ipAddress: String? = nil) {
        self.timestamp = timestamp
        self.success = success
        self.ipAddress = ipAddress
    }
}

// MARK: - Auto Lock Schedule
struct AutoLockSchedule: Codable {
    var enabled: Bool
    var weekdayWindows: [TimeWindow]
    var weekendWindows: [TimeWindow]
    var lockBehavior: LockBehavior
    var schoolMode: SchoolMode?

    init() {
        self.enabled = false
        self.weekdayWindows = [TimeWindow.defaultWeekday]
        self.weekendWindows = [TimeWindow.defaultWeekend]
        self.lockBehavior = .lockCompletely
        self.schoolMode = nil
    }

    enum LockBehavior: String, Codable {
        case lockCompletely = "lock_completely"
        case switchToAdult = "switch_to_adult"
        case notifyOnly = "notify_only"

        var displayName: String {
            switch self {
            case .lockCompletely:
                return "Lock Completely"
            case .switchToAdult:
                return "Switch to Adult Mode"
            case .notifyOnly:
                return "Notify Only"
            }
        }

        var description: String {
            switch self {
            case .lockCompletely:
                return "Moxie requires PIN to access during locked hours"
            case .switchToAdult:
                return "Child mode locks, but parent can still access"
            case .notifyOnly:
                return "Log the attempt but allow access (for learning/trust building)"
            }
        }
    }
}

// MARK: - Time Window
struct TimeWindow: Codable, Identifiable {
    let id: UUID
    var startTime: TimeComponents
    var endTime: TimeComponents
    var enabled: Bool

    init(
        id: UUID = UUID(),
        startTime: TimeComponents,
        endTime: TimeComponents,
        enabled: Bool = true
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.enabled = enabled
    }

    static var defaultWeekday: TimeWindow {
        TimeWindow(
            startTime: TimeComponents(hour: 7, minute: 0),
            endTime: TimeComponents(hour: 20, minute: 0)
        )
    }

    static var defaultWeekend: TimeWindow {
        TimeWindow(
            startTime: TimeComponents(hour: 8, minute: 0),
            endTime: TimeComponents(hour: 21, minute: 0)
        )
    }

    // Check if current time falls within this window
    func contains(_ date: Date) -> Bool {
        guard enabled else { return false }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return false }

        let currentMinutes = hour * 60 + minute
        let startMinutes = startTime.hour * 60 + startTime.minute
        let endMinutes = endTime.hour * 60 + endTime.minute

        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }

    var displayString: String {
        "\(startTime.displayString) - \(endTime.displayString)"
    }
}

// MARK: - Time Components
struct TimeComponents: Codable, Equatable {
    var hour: Int    // 0-23
    var minute: Int  // 0-59

    init(hour: Int, minute: Int) {
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
    }

    var displayString: String {
        let hourString = hour == 0 ? "12" : (hour > 12 ? "\(hour - 12)" : "\(hour)")
        let minuteString = String(format: "%02d", minute)
        let period = hour < 12 ? "AM" : "PM"
        return "\(hourString):\(minuteString) \(period)"
    }

    var totalMinutes: Int {
        hour * 60 + minute
    }
}

// MARK: - School Mode
struct SchoolMode: Codable {
    var enabled: Bool
    var weekdayStartTime: TimeComponents
    var weekdayEndTime: TimeComponents
    var allowHomeworkHelp: Bool

    init() {
        self.enabled = false
        self.weekdayStartTime = TimeComponents(hour: 8, minute: 0)
        self.weekdayEndTime = TimeComponents(hour: 15, minute: 0)
        self.allowHomeworkHelp = false
    }

    func isSchoolHours(_ date: Date) -> Bool {
        guard enabled else { return false }

        let calendar = Calendar.current
        let isWeekday = !calendar.isDateInWeekend(date)
        guard isWeekday else { return false }

        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return false }

        let currentMinutes = hour * 60 + minute
        let startMinutes = weekdayStartTime.totalMinutes
        let endMinutes = weekdayEndTime.totalMinutes

        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }
}
