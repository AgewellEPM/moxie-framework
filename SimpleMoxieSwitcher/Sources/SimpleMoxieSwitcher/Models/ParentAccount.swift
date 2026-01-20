import Foundation
import SwiftUI

// MARK: - Parent Account Model
struct ParentAccount: Codable, Identifiable {
    let id: UUID
    var email: String
    var emailVerified: Bool
    var securityQuestion: String
    var securityAnswerHash: String  // Hashed, never plaintext
    var notificationPreferences: NotificationPreferences
    var loggingPreferences: LoggingPreferences
    var createdAt: Date
    var lastLoginAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        email: String,
        emailVerified: Bool = false,
        securityQuestion: String,
        securityAnswerHash: String
    ) {
        self.id = id
        self.email = email
        self.emailVerified = emailVerified
        self.securityQuestion = securityQuestion
        self.securityAnswerHash = securityAnswerHash
        self.notificationPreferences = NotificationPreferences()
        self.loggingPreferences = LoggingPreferences()
        self.createdAt = Date()
        self.lastLoginAt = Date()
        self.updatedAt = Date()
    }

    // Hash security answer for secure storage
    static func hashSecurityAnswer(_ answer: String) -> String {
        // Normalize answer (lowercase, trim whitespace)
        let normalized = answer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // SHA-256 hash
        guard let data = normalized.data(using: .utf8) else { return "" }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // Verify security answer
    func verifySecurityAnswer(_ answer: String) -> Bool {
        let hashedAnswer = Self.hashSecurityAnswer(answer)
        return hashedAnswer == securityAnswerHash
    }

    // Update email and mark as unverified
    mutating func updateEmail(_ newEmail: String) {
        email = newEmail
        emailVerified = false
        updatedAt = Date()
    }

    // Mark email as verified
    mutating func markEmailVerified() {
        emailVerified = true
        updatedAt = Date()
    }

    // Update last login timestamp
    mutating func recordLogin() {
        lastLoginAt = Date()
        updatedAt = Date()
    }
}

// MARK: - Notification Preferences
struct NotificationPreferences: Codable {
    var emailOnFlaggedContent: Bool = true
    var emailOnPINFailures: Bool = true
    var emailOnTimeExtensionRequests: Bool = true
    var dailySummaryEmail: Bool = false
    var weeklyReportEmail: Bool = true

    mutating func updatePreference(for key: NotificationKey, enabled: Bool) {
        switch key {
        case .flaggedContent:
            emailOnFlaggedContent = enabled
        case .pinFailures:
            emailOnPINFailures = enabled
        case .timeExtensionRequests:
            emailOnTimeExtensionRequests = enabled
        case .dailySummary:
            dailySummaryEmail = enabled
        case .weeklyReport:
            weeklyReportEmail = enabled
        }
    }

    enum NotificationKey {
        case flaggedContent
        case pinFailures
        case timeExtensionRequests
        case dailySummary
        case weeklyReport
    }
}

// MARK: - Logging Preferences
struct LoggingPreferences: Codable {
    var level: LoggingLevel = .balanced
    var retentionDays: Int = 90
    var intelligentSummaries: Bool = true
    var sentimentAnalysis: Bool = true
    var contentFlagging: Bool = true
    var customFlaggingKeywords: [String] = []

    mutating func addCustomKeyword(_ keyword: String) {
        let normalized = keyword.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if !customFlaggingKeywords.contains(normalized) {
            customFlaggingKeywords.append(normalized)
        }
    }

    mutating func removeCustomKeyword(_ keyword: String) {
        customFlaggingKeywords.removeAll { $0 == keyword.lowercased() }
    }
}

// MARK: - Logging Level
enum LoggingLevel: String, Codable, CaseIterable {
    case highPrivacy = "high_privacy"
    case balanced = "balanced"
    case fullTransparency = "full_transparency"
    case institutional = "institutional"

    var displayName: String {
        switch self {
        case .highPrivacy:
            return "High Privacy"
        case .balanced:
            return "Balanced"
        case .fullTransparency:
            return "Full Transparency"
        case .institutional:
            return "Institutional"
        }
    }

    var description: String {
        switch self {
        case .highPrivacy:
            return "Logs only timestamps and session duration. Best for older children with earned trust."
        case .balanced:
            return "Logs timestamps, topics, and flagged content. Recommended for most families."
        case .fullTransparency:
            return "Logs complete conversation transcripts. Best for young children or special needs."
        case .institutional:
            return "Full logs plus AI safety scoring. Required for schools and therapeutic settings."
        }
    }

    var logsFullTranscripts: Bool {
        self == .fullTransparency || self == .institutional
    }

    var logsTopicSummaries: Bool {
        self != .highPrivacy
    }

    var logsFlags: Bool {
        true  // All levels log safety flags
    }

    var performsSentimentAnalysis: Bool {
        self == .balanced || self == .fullTransparency || self == .institutional
    }

    var performsAISafetyScoring: Bool {
        self == .institutional
    }

    var icon: String {
        switch self {
        case .highPrivacy: return "lock.shield.fill"
        case .balanced: return "scale.3d"
        case .fullTransparency: return "eye.fill"
        case .institutional: return "building.columns.fill"
        }
    }

    var color: Color {
        switch self {
        case .highPrivacy: return .green
        case .balanced: return .blue
        case .fullTransparency: return .orange
        case .institutional: return .purple
        }
    }
}

// MARK: - CryptoKit Import for SHA-256
import CryptoKit
