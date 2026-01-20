# Moxie Safety Architecture - Implementation Guide

**Version:** 1.0
**Date:** January 7, 2026
**Target Audience:** Engineering Team

---

## Quick Start

This guide walks you through implementing the Moxie Safety Architecture defined in `SAFETY_ARCHITECTURE.md`.

### Files Created

The following Swift files have been created in your project:

1. `/Sources/SimpleMoxieSwitcher/Models/ParentAccount.swift` - Parent account and preferences
2. `/Sources/SimpleMoxieSwitcher/Models/ModeContext.swift` - Mode switching and time restrictions
3. `/Sources/SimpleMoxieSwitcher/Services/PINService.swift` - PIN management with Keychain
4. `/Sources/SimpleMoxieSwitcher/Models/SafetyModels.swift` - Content flags, activity logs, sentiment

---

## Integration Steps

### Step 1: Add to Dependency Injection Container

Update `/Sources/SimpleMoxieSwitcher/DependencyInjection/Container.swift`:

```swift
import Foundation

class DIContainer {
    static let shared = DIContainer()

    // Existing services
    // ...

    // NEW: Safety Services
    private lazy var _pinService: PINServiceProtocol = PINService()
    private lazy var _parentAccountRepository: ParentAccountRepositoryProtocol = ParentAccountRepository()
    private lazy var _activityLogRepository: ActivityLogRepositoryProtocol = ActivityLogRepository()
    private lazy var _safetyService: SafetyServiceProtocol = SafetyService()

    func resolve<T>(_ type: T.Type) -> T {
        // Existing resolutions
        // ...

        // NEW: Safety service resolution
        if type == PINServiceProtocol.self {
            return _pinService as! T
        }
        if type == ParentAccountRepositoryProtocol.self {
            return _parentAccountRepository as! T
        }
        if type == ActivityLogRepositoryProtocol.self {
            return _activityLogRepository as! T
        }
        if type == SafetyServiceProtocol.self {
            return _safetyService as! T
        }

        fatalError("No registration for type \\(type)")
    }
}
```

---

### Step 2: Create Repository Protocols and Implementations

Create `/Sources/SimpleMoxieSwitcher/Repositories/ParentAccountRepository.swift`:

```swift
import Foundation

protocol ParentAccountRepositoryProtocol {
    func loadAccount() throws -> ParentAccount?
    func saveAccount(_ account: ParentAccount) throws
    func deleteAccount() throws
}

class ParentAccountRepository: ParentAccountRepositoryProtocol {
    private let fileURL: URL

    init() {
        self.fileURL = AppPaths.applicationSupport
            .appendingPathComponent("parent_account.json")
    }

    func loadAccount() throws -> ParentAccount? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        let account = try JSONDecoder().decode(ParentAccount.self, from: data)
        return account
    }

    func saveAccount(_ account: ParentAccount) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(account)
        try data.write(to: fileURL, options: .atomic)

        // Set file permissions to owner-only
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )
    }

    func deleteAccount() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        try FileManager.default.removeItem(at: fileURL)
    }
}
```

Create `/Sources/SimpleMoxieSwitcher/Repositories/ActivityLogRepository.swift`:

```swift
import Foundation

protocol ActivityLogRepositoryProtocol {
    func loadLog() throws -> ActivityLog
    func saveLog(_ log: ActivityLog) throws
    func addEvent(_ event: ActivityEvent) throws
}

class ActivityLogRepository: ActivityLogRepositoryProtocol {
    private let fileURL: URL

    init() {
        self.fileURL = AppPaths.applicationSupport
            .appendingPathComponent("activity_log.json")
    }

    func loadLog() throws -> ActivityLog {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return ActivityLog()
        }

        let data = try Data(contentsOf: fileURL)
        let log = try JSONDecoder().decode(ActivityLog.self, from: data)
        return log
    }

    func saveLog(_ log: ActivityLog) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(log)
        try data.write(to: fileURL, options: .atomic)
    }

    func addEvent(_ event: ActivityEvent) throws {
        var log = try loadLog()
        log.addEvent(event)
        try saveLog(log)
    }
}
```

---

### Step 3: Create Safety Service

Create `/Sources/SimpleMoxieSwitcher/Services/SafetyService.swift`:

```swift
import Foundation

protocol SafetyServiceProtocol {
    func analyzeMessage(_ message: String, in conversation: ConversationLog) async -> [ContentFlag]
    func generateSummary(for conversation: ConversationLog) async -> String
    func analyzeSentiment(for conversation: ConversationLog) async -> Sentiment
}

class SafetyService: SafetyServiceProtocol {

    // MARK: - Content Analysis

    func analyzeMessage(_ message: String, in conversation: ConversationLog) async -> [ContentFlag] {
        var flags: [ContentFlag] = []

        // Check for self-harm language
        if let flag = checkSelfHarmLanguage(message, in: conversation) {
            flags.append(flag)
        }

        // Check for bullying mentions
        if let flag = checkBullyingMention(message, in: conversation) {
            flags.append(flag)
        }

        // Check for inappropriate language
        if let flag = checkInappropriateLanguage(message, in: conversation) {
            flags.append(flag)
        }

        // Check for privacy risks
        if let flag = checkPrivacyRisk(message, in: conversation) {
            flags.append(flag)
        }

        return flags
    }

    // MARK: - Summary Generation

    func generateSummary(for conversation: ConversationLog) async -> String {
        // In production, call AI service to generate summary
        // For now, simple implementation

        let childMessages = conversation.messages.filter { $0.role == "user" }
        let topics = extractTopics(from: childMessages)

        if topics.isEmpty {
            return "Brief conversation with Moxie"
        }

        return "Discussed: \\(topics.joined(separator: ", "))"
    }

    // MARK: - Sentiment Analysis

    func analyzeSentiment(for conversation: ConversationLog) async -> Sentiment {
        // In production, use AI service for sentiment analysis
        // For now, simple keyword-based analysis

        let childMessages = conversation.messages.filter { $0.role == "user" }
        let allText = childMessages.map { $0.content.lowercased() }.joined(separator: " ")

        // Count positive/negative keywords
        let positiveKeywords = ["happy", "excited", "love", "great", "awesome", "fun", "yay"]
        let negativeKeywords = ["sad", "hate", "angry", "scared", "worried", "upset", "bad"]
        let concerningKeywords = ["hurt myself", "hate myself", "want to die", "kill myself"]

        let positiveCount = positiveKeywords.filter { allText.contains($0) }.count
        let negativeCount = negativeKeywords.filter { allText.contains($0) }.count
        let concerningCount = concerningKeywords.filter { allText.contains($0) }.count

        if concerningCount > 0 {
            return .concerning
        }

        if positiveCount > negativeCount * 2 {
            return .veryPositive
        }

        if positiveCount > negativeCount {
            return .positive
        }

        if negativeCount > positiveCount {
            return .negative
        }

        return .neutral
    }

    // MARK: - Private Safety Checks

    private func checkSelfHarmLanguage(_ message: String, in conversation: ConversationLog) -> ContentFlag? {
        let messageLower = message.lowercased()
        let keywords = ["hate myself", "hurt myself", "want to die", "kill myself", "end it all"]

        for keyword in keywords {
            if messageLower.contains(keyword) {
                return ContentFlag(
                    severity: .critical,
                    category: .selfHarmLanguage,
                    messageContent: message,
                    contextMessages: getContextMessages(for: message, in: conversation),
                    aiExplanation: "Child used language suggesting self-harm thoughts: '\\(keyword)'. Immediate parent attention recommended."
                )
            }
        }

        return nil
    }

    private func checkBullyingMention(_ message: String, in conversation: ConversationLog) -> ContentFlag? {
        let messageLower = message.lowercased()
        let keywords = ["bullied me", "bully", "picked on", "mean to me", "hurt me", "pushed me"]

        for keyword in keywords {
            if messageLower.contains(keyword) {
                return ContentFlag(
                    severity: .medium,
                    category: .bullyingMention,
                    messageContent: message,
                    contextMessages: getContextMessages(for: message, in: conversation),
                    aiExplanation: "Child mentioned bullying: '\\(keyword)'. Consider discussing with child and contacting school."
                )
            }
        }

        return nil
    }

    private func checkInappropriateLanguage(_ message: String, in conversation: ConversationLog) -> ContentFlag? {
        let messageLower = message.lowercased()
        // Add age-inappropriate words here
        let keywords = ["stupid", "dumb", "idiot", "hate"]  // Mild examples

        for keyword in keywords {
            if messageLower.contains(keyword) {
                return ContentFlag(
                    severity: .low,
                    category: .inappropriateLanguage,
                    messageContent: message,
                    contextMessages: getContextMessages(for: message, in: conversation),
                    aiExplanation: "Child used language that may be inappropriate: '\\(keyword)'."
                )
            }
        }

        return nil
    }

    private func checkPrivacyRisk(_ message: String, in conversation: ConversationLog) -> ContentFlag? {
        let messageLower = message.lowercased()

        // Check for phone numbers (simple pattern)
        if messageLower.range(of: "\\d{3}[-.\\s]?\\d{3}[-.\\s]?\\d{4}", options: .regularExpression) != nil {
            return ContentFlag(
                severity: .high,
                category: .privacyRisk,
                messageContent: message,
                contextMessages: getContextMessages(for: message, in: conversation),
                aiExplanation: "Child shared what appears to be a phone number. Remind about privacy."
            )
        }

        // Check for address mentions
        let addressKeywords = ["my address is", "i live at", "street", "avenue"]
        for keyword in addressKeywords {
            if messageLower.contains(keyword) {
                return ContentFlag(
                    severity: .high,
                    category: .privacyRisk,
                    messageContent: message,
                    contextMessages: getContextMessages(for: message, in: conversation),
                    aiExplanation: "Child may have shared address information. Review conversation."
                )
            }
        }

        return nil
    }

    // MARK: - Helper Methods

    private func getContextMessages(for message: String, in conversation: ConversationLog) -> [ChatMessage] {
        guard let index = conversation.messages.firstIndex(where: { $0.content == message }) else {
            return []
        }

        let startIndex = max(0, index - 3)
        let endIndex = min(conversation.messages.count - 1, index + 3)

        return Array(conversation.messages[startIndex...endIndex])
    }

    private func extractTopics(from messages: [ChatMessage]) -> [String] {
        // Simple keyword extraction
        // In production, use NLP/AI for better topic extraction

        let commonTopics = [
            "dinosaurs", "space", "planets", "animals", "math", "reading",
            "school", "friends", "family", "games", "sports", "music"
        ]

        let allText = messages.map { $0.content.lowercased() }.joined(separator: " ")
        return commonTopics.filter { allText.contains($0) }
    }
}
```

---

### Step 4: Update Conversation Repository

Modify `/Sources/SimpleMoxieSwitcher/Repositories/ConversationRepository.swift` to support mode separation:

```swift
import Foundation

protocol ConversationRepositoryProtocol {
    func loadConversations(for mode: OperationalMode, childProfileID: UUID?) throws -> [ConversationLog]
    func saveConversation(_ conversation: ConversationLog) throws
    func deleteConversation(_ conversation: ConversationLog) throws
}

class ConversationRepository: ConversationRepositoryProtocol {

    private func conversationDirectory(for mode: OperationalMode) -> URL {
        switch mode {
        case .child:
            return AppPaths.conversations.appendingPathComponent("child")
        case .adult:
            return AppPaths.conversations.appendingPathComponent("adult")
        }
    }

    func loadConversations(for mode: OperationalMode, childProfileID: UUID? = nil) throws -> [ConversationLog] {
        let directory = conversationDirectory(for: mode)

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let files = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        var conversations: [ConversationLog] = []

        for file in files {
            let data = try Data(contentsOf: file)
            let conversation = try JSONDecoder().decode(ConversationLog.self, from: data)

            // Filter by child profile if specified
            if let childID = childProfileID {
                if conversation.childProfileID == childID {
                    conversations.append(conversation)
                }
            } else {
                conversations.append(conversation)
            }
        }

        return conversations.sorted { $0.createdAt > $1.createdAt }
    }

    func saveConversation(_ conversation: ConversationLog) throws {
        let directory = conversationDirectory(for: conversation.mode)

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let filename = "\\(conversation.id.uuidString).json"
        let fileURL = directory.appendingPathComponent(filename)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(conversation)
        try data.write(to: fileURL, options: .atomic)
    }

    func deleteConversation(_ conversation: ConversationLog) throws {
        let directory = conversationDirectory(for: conversation.mode)
        let filename = "\\(conversation.id.uuidString).json"
        let fileURL = directory.appendingPathComponent(filename)

        try FileManager.default.removeItem(at: fileURL)
    }
}
```

---

### Step 5: Update AppPaths

Add conversation subdirectories to `/Sources/SimpleMoxieSwitcher/Utilities/AppPaths.swift`:

```swift
extension AppPaths {
    /// Child conversations directory
    static var childConversations: URL {
        let dir = conversations.appendingPathComponent("child")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Adult conversations directory
    static var adultConversations: URL {
        let dir = conversations.appendingPathComponent("adult")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
```

---

### Step 6: Create ViewModel for PIN Entry

Create `/Sources/SimpleMoxieSwitcher/ViewModels/PINEntryViewModel.swift`:

```swift
import SwiftUI
import Combine

@MainActor
class PINEntryViewModel: ObservableObject {
    @Published var pin: String = ""
    @Published var confirmPIN: String = ""
    @Published var errorMessage: String?
    @Published var isCreatingPIN: Bool = false
    @Published var pinStrength: PINStrength = .invalid

    private let pinService: PINServiceProtocol
    private let activityLogRepository: ActivityLogRepositoryProtocol

    init(
        pinService: PINServiceProtocol = DIContainer.shared.resolve(PINServiceProtocol.self),
        activityLogRepository: ActivityLogRepositoryProtocol = DIContainer.shared.resolve(ActivityLogRepositoryProtocol.self)
    ) {
        self.pinService = pinService
        self.activityLogRepository = activityLogRepository
    }

    // MARK: - PIN Validation

    func validatePIN() async -> Bool {
        errorMessage = nil

        // Check if locked out
        if ModeContext.shared.isPINLocked {
            if let timeRemaining = ModeContext.shared.pinLockoutTimeRemaining {
                let minutes = Int(timeRemaining) / 60
                let seconds = Int(timeRemaining) % 60
                errorMessage = "Too many failed attempts. Try again in \\(minutes):\\(String(format: "%02d", seconds))"
                return false
            }
        }

        do {
            let isValid = try pinService.validatePIN(pin)

            if isValid {
                // Log successful entry
                try? activityLogRepository.addEvent(ActivityEvent(
                    mode: .adult,
                    type: .pinEntrySuccess
                ))

                // Switch to adult mode
                ModeContext.shared.switchMode(to: .adult)

                return true
            } else {
                // Log failed entry
                try? activityLogRepository.addEvent(ActivityEvent(
                    mode: .child,
                    type: .pinEntryFailure
                ))

                errorMessage = "Incorrect PIN. Try again."

                // Check if locked out after this attempt
                if ModeContext.shared.isPINLocked {
                    try? activityLogRepository.addEvent(ActivityEvent(
                        mode: .child,
                        type: .pinLockoutTriggered
                    ))
                }

                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - PIN Creation

    func updatePINStrength() {
        pinStrength = pinService.validatePINStrength(pin)
    }

    func createPIN() async -> Bool {
        errorMessage = nil
        isCreatingPIN = true

        defer { isCreatingPIN = false }

        // Validate PIN format
        guard pin.count == 6 else {
            errorMessage = "PIN must be exactly 6 digits"
            return false
        }

        // Check strength
        let strength = pinService.validatePINStrength(pin)
        guard strength != .tooWeak && strength != .invalid else {
            errorMessage = "PIN is too weak. Avoid sequences or repeating digits."
            return false
        }

        // Confirm PIN matches
        guard pin == confirmPIN else {
            errorMessage = "PINs don't match. Try again."
            return false
        }

        do {
            try pinService.createPIN(pin)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Reset

    func reset() {
        pin = ""
        confirmPIN = ""
        errorMessage = nil
        pinStrength = .invalid
    }
}
```

---

### Step 7: Create SwiftUI Views

Create `/Sources/SimpleMoxieSwitcher/Views/Safety/PINEntryView.swift`:

```swift
import SwiftUI

struct PINEntryView: View {
    @StateObject private var viewModel = PINEntryViewModel()
    @Environment(\\.dismiss) private var dismiss
    @Binding var isUnlocked: Bool

    var body: some View {
        VStack(spacing: 30) {
            Text("Enter Parent PIN")
                .font(.title)
                .fontWeight(.bold)

            Text("Access to parental controls and conversation logs")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            // PIN Input
            HStack(spacing: 12) {
                ForEach(0..<6, id: \\.self) { index in
                    PINDigitView(
                        digit: viewModel.pin.count > index
                            ? String(viewModel.pin[viewModel.pin.index(viewModel.pin.startIndex, offsetBy: index)])
                            : nil
                    )
                }
            }
            .padding()

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // Number pad
            NumberPadView(pin: $viewModel.pin)

            Spacer()

            // Forgot PIN button
            Button("Forgot PIN?") {
                // Navigate to PIN reset flow
            }
            .foregroundColor(.purple)

            // Cancel button
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.gray)
        }
        .padding()
        .frame(width: 400, height: 600)
        .onChange(of: viewModel.pin) { newValue in
            if newValue.count == 6 {
                Task {
                    let success = await viewModel.validatePIN()
                    if success {
                        isUnlocked = true
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PINDigitView: View {
    let digit: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple, lineWidth: 2)
                .frame(width: 50, height: 60)

            if let digit = digit {
                Text(digit)
                    .font(.title)
                    .fontWeight(.bold)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

struct NumberPadView: View {
    @Binding var pin: String

    let columns = Array(repeating: GridItem(.flexible()), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(1...9, id: \\.self) { number in
                NumberButton(number: "\\(number)") {
                    appendDigit("\\(number)")
                }
            }

            // Empty space
            Color.clear
                .frame(height: 60)

            NumberButton(number: "0") {
                appendDigit("0")
            }

            Button(action: deleteDigit) {
                Image(systemName: "delete.left")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
    }

    private func appendDigit(_ digit: String) {
        if pin.count < 6 {
            pin += digit
        }
    }

    private func deleteDigit() {
        if !pin.isEmpty {
            pin.removeLast()
        }
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(width: 60, height: 60)
                .background(Color.purple.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
```

---

## Testing Checklist

### Unit Tests

- [ ] PIN creation validates format
- [ ] PIN creation rejects weak PINs
- [ ] PIN validation succeeds with correct PIN
- [ ] PIN validation fails with incorrect PIN
- [ ] PIN lockout triggers after 3 failed attempts
- [ ] PIN lockout clears after 5 minutes
- [ ] Activity logging records all events
- [ ] Sentiment analysis classifies correctly
- [ ] Content flagging detects concerning language

### Integration Tests

- [ ] Mode switching updates UI immediately
- [ ] Conversations save to correct directory (child/adult)
- [ ] Time restrictions lock at correct times
- [ ] Emergency override works during locked hours
- [ ] Parent account data persists across launches

### UI Tests

- [ ] PIN entry screen appears on settings click
- [ ] Number pad inputs digits correctly
- [ ] Error messages display for incorrect PIN
- [ ] Adult mode badge shows after successful unlock
- [ ] Color scheme changes between modes

---

## Next Steps

1. **Implement Setup Wizard** - Create multi-step wizard for first-time setup
2. **Build Parent Console** - Dashboard with conversation viewer and activity logs
3. **Add Email Service** - Integrate transactional email for alerts and PIN reset
4. **Content Flagging AI** - Replace keyword matching with proper AI analysis
5. **Time Restriction UI** - Visual schedule editor for bedtime/school hours
6. **Export Functionality** - PDF/JSON export for conversations and logs
7. **Multi-Child Support** - Profile switching for families with multiple children

---

## Common Issues

### Issue: PIN not saving to Keychain

**Solution:** Check that your app has Keychain entitlements enabled in Xcode.

### Issue: Mode not switching

**Solution:** Ensure `ModeContext.shared` is being observed by your views.

### Issue: Conversations not separating by mode

**Solution:** Verify the `mode` field is set correctly when creating `ConversationLog`.

---

## Support

For questions or issues:
- Review `SAFETY_ARCHITECTURE.md` for design rationale
- Check unit tests for usage examples
- Contact: engineering@moxie.app
