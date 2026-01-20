# Moxie Safety and Trust Architecture
## Production-Ready Specification for Families, Schools, and Regulators

**Version:** 1.0
**Date:** January 7, 2026
**Status:** Production Specification
**Compliance:** COPPA, FERPA, GDPR-compliant design

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Feature Specifications](#feature-specifications)
3. [Data Models](#data-models)
4. [User Flows](#user-flows)
5. [UX Guidelines](#ux-guidelines)
6. [Privacy Policy](#privacy-policy)
7. [Edge Cases and Error Handling](#edge-cases)
8. [Implementation Roadmap](#implementation-roadmap)

---

## Executive Summary

This document defines a comprehensive safety and trust architecture for Moxie, a children's AI companion. The architecture balances three critical stakeholder needs:

- **Parents:** Control, visibility, and peace of mind
- **Children:** Safe exploration, privacy, and trust
- **Institutions:** Compliance, auditability, and accountability

### Core Design Principles

1. **Transparent by Default:** Children know what is logged and why
2. **Empowering, Not Restrictive:** Safety feels supportive, not punitive
3. **Privacy-First:** Minimal data collection with maximum protection
4. **Age-Appropriate:** Different controls for different developmental stages
5. **Emergency-Aware:** Safety overrides when children need help

---

## Feature Specifications

### Feature 1: PIN-Protected Adult Mode

#### Overview
Two distinct operational modes with explicit permission boundaries. Adult mode requires PIN authentication and provides access to configuration, logs, and sensitive features.

#### User Story
**As a parent**, I want to access advanced settings without my child being able to modify safety controls, so that I can ensure age-appropriate experiences.

#### Functional Requirements

**FR-1.1: PIN Creation During Setup**
- During initial setup wizard, parent creates a 6-digit PIN
- PIN must not be sequential (123456) or repetitive (111111)
- PIN strength indicator shown in real-time
- Optional: Biometric unlock (Touch ID/Face ID) for parent convenience
- PIN stored securely using macOS Keychain

**FR-1.2: Mode Switching**
- Default mode on app launch: Child Mode
- Adult Mode accessible via settings icon + PIN entry
- Visual distinction between modes (color scheme, badge, header)
- Mode persists until manually switched back or time-based auto-lock triggers

**FR-1.3: Feature Access Control**
| Feature | Child Mode | Adult Mode |
|---------|------------|------------|
| Personality Selection | Curated list only | Full access + custom creation |
| Conversation History | Own conversations only | All conversations + analytics |
| Chat with Moxie | Yes (filtered) | Yes (unfiltered) |
| System Settings | No | Yes |
| Time Restrictions | No | Yes |
| Export Data | No | Yes |
| Child Profile Editing | No | Yes |
| Smart Home Control | Limited (approved devices) | Full access |

**FR-1.4: PIN Reset Flow**
- "Forgot PIN" option sends reset link to parent email
- Email must be verified during setup
- Reset link expires in 1 hour
- Security question as fallback (configured during setup)

#### Non-Functional Requirements

**NFR-1.1: Security**
- PIN attempts rate-limited (3 failed attempts = 5-minute lockout)
- Keychain encryption for PIN storage (no plaintext)
- Session timeout after 30 minutes of inactivity in Adult Mode
- No PIN visible in logs or crash reports

**NFR-1.2: Performance**
- Mode switching completes in < 500ms
- PIN validation in < 100ms
- No impact on child mode interaction latency

#### Acceptance Criteria

```gherkin
Given the parent has set a PIN during setup
When the parent clicks the settings icon in Child Mode
Then the PIN entry screen appears
And the parent enters the correct 6-digit PIN
Then Adult Mode activates within 500ms
And the UI updates to show Adult Mode badge
And previously restricted features become accessible

Given the user has entered an incorrect PIN 3 times
When they attempt a 4th entry
Then the app locks PIN entry for 5 minutes
And displays "Too many attempts. Try again in 5:00"
And a notification email is sent to the parent email address
```

---

### Feature 2: Time-Based Adult Unlock

#### Overview
Automatically restricts access to Child Mode during specified hours (e.g., bedtime, school hours) and switches to Adult Mode or locks entirely.

#### User Story
**As a parent**, I want Moxie to automatically lock after my child's bedtime so that late-night unsupervised interactions don't occur.

#### Functional Requirements

**FR-2.1: Time Window Configuration**
- Parent sets allowed interaction windows (e.g., 7 AM - 8 PM)
- Supports multiple windows per day (e.g., after school: 3-5 PM, evening: 6-8 PM)
- Different schedules for weekdays vs. weekends
- Timezone awareness (auto-adjusts for travel)

**FR-2.2: Automatic Mode Switching**
- At restriction time (e.g., 8 PM), Child Mode locks automatically
- Three locking behaviors (parent-configurable):
  1. **Lock Completely:** App requires PIN to open
  2. **Switch to Adult Mode:** Parent can still access
  3. **Notify Only:** Log the attempt but allow access (learning mode)

**FR-2.3: Override Mechanism**
- "Request More Time" button in Child Mode
- Sends notification to parent's phone (if mobile companion app exists)
- Parent can approve/deny remotely or via PIN entry
- Configurable: Auto-approve, auto-deny, or manual review

**FR-2.4: School Mode**
- Preset template: Lock during school hours (8 AM - 3 PM weekdays)
- Exception for "homework help" mode (limited Q&A personality)
- Audit log of all school-hours interactions for teacher/parent review

#### Non-Functional Requirements

**NFR-2.1: Reliability**
- Time checks run every 60 seconds
- Graceful degradation if system time unavailable (default to most restrictive)
- Persistent across app restarts

**NFR-2.2: User Experience**
- 5-minute warning before auto-lock ("Moxie will go to sleep in 5 minutes!")
- Child-friendly messaging (not punitive tone)
- Visual countdown timer during final minute

#### Acceptance Criteria

```gherkin
Given bedtime is configured for 8:00 PM
And current time is 7:55 PM
When a child is interacting with Moxie in Child Mode
Then at 7:55 PM, a friendly warning appears: "Moxie will go to sleep in 5 minutes!"
And at 7:59 PM, a countdown appears
And at 8:00 PM, Child Mode locks
And the screen shows "Moxie is sleeping. See you tomorrow at 7:00 AM!"
And Adult Mode remains accessible via PIN

Given school hours are 8 AM - 3 PM on weekdays
And the child attempts to open Moxie at 10 AM on Tuesday
Then the app shows "Moxie is at school too! Focus on learning!"
And the interaction is logged but blocked
And an exception button appears: "Need homework help?"
And clicking it enables limited Q&A mode with logging
```

---

### Feature 3: Memory Isolation (Dual Conversation Context)

#### Overview
Child Mode conversations and Adult Mode conversations are stored separately, ensuring parents can discuss parenting strategies without children seeing those conversations.

#### User Story
**As a parent**, I want to ask Moxie for advice about handling my child's behavior challenges without my child seeing those discussions in their chat history.

#### Functional Requirements

**FR-3.1: Context Separation**
- Two distinct conversation databases:
  - `child_conversations/` - Child's interactions with Moxie
  - `adult_conversations/` - Parent's discussions with Moxie
- Child Mode **never** sees Adult Mode conversations
- Adult Mode **can** see Child Mode conversations (for monitoring)

**FR-3.2: Personality Adaptation**
- **Child Mode Personality Context:**
  - Uses child profile (age, interests, goals)
  - Child-friendly language and tone
  - Developmentally appropriate responses
  - Emotion expressions (happy, excited, curious)

- **Adult Mode Personality Context:**
  - Professional, informative tone
  - Parenting advice and strategies
  - No emotional expressions
  - References to child without cutesy language

**FR-3.3: Visual Indicators**
- Child Mode: Playful header with child's name ("Chatting with Emma")
- Adult Mode: Professional header ("Parent Console - Discussing Emma")
- Color coding: Child Mode (cyan/blue), Adult Mode (purple/gray)
- Badge: "Parent View" always visible in Adult Mode

**FR-3.4: Conversation Export**
- Child Mode: Cannot export
- Adult Mode: Can export both child and adult conversations
- Export formats: PDF (formatted), JSON (structured), TXT (plain)
- Exported files include timestamps, mode, and metadata

#### Example Conversation Scenarios

**Child Mode Conversation:**
```
Child: "I'm sad because my friend didn't want to play today."
Moxie: [emotion:sad] "That sounds really hard. It's okay to feel sad when that happens.
Did you tell your friend how you felt?"
```

**Adult Mode Conversation:**
```
Parent: "My child seems withdrawn after conflicts with friends. What should I do?"
Moxie: "Social conflicts at this developmental stage are normal. Consider these strategies:
1. Validate their feelings without immediately problem-solving
2. Ask open-ended questions about what happened
3. Role-play different responses for next time
Would you like specific conversation starters to use?"
```

#### Non-Functional Requirements

**NFR-3.1: Data Integrity**
- Conversation databases encrypted at rest
- Child conversation DB has read-only permissions from Adult Mode
- No cross-contamination of context in AI prompts

**NFR-3.2: Performance**
- Context loading adds < 200ms to response time
- Conversation history limited to last 50 messages per session for performance

#### Acceptance Criteria

```gherkin
Given the parent is in Adult Mode
And has asked Moxie "How do I help my child with anger management?"
When the child later opens Moxie in Child Mode
Then the child does NOT see the parent's question in conversation history
And Moxie's personality is age-appropriate and playful
And the conversation context includes child profile data, not parent discussions

Given the parent is in Adult Mode reviewing conversations
When they open the conversation history
Then they see both:
  - "Emma's Conversations" (child mode)
  - "Parent Discussions" (adult mode)
And child conversations are marked with timestamps and personality used
And adult conversations are visually distinct (different color)
```

---

### Feature 4: Parent-Only Logging and Audit Trail

#### Overview
Comprehensive activity logging with privacy-conscious controls. Parents can review what their child discussed without invasive surveillance.

#### User Story
**As a parent**, I want to review my child's conversations to ensure they're safe and appropriate, while also respecting their developmental need for privacy.

**As a school administrator**, I want audit logs showing compliance with educational safety standards and COPPA requirements.

#### Functional Requirements

**FR-4.1: Activity Logging**

Logged events include:
- **Conversation Events:**
  - Timestamp of conversation start/end
  - Personality used
  - Number of messages exchanged
  - Topics discussed (AI-generated summary)
  - Flagged content (if inappropriate language detected)

- **Mode Switching Events:**
  - Timestamp of Adult Mode entry/exit
  - PIN entry attempts (success/failure)
  - Time-based lockouts triggered

- **Feature Usage:**
  - Stories accessed
  - Learning activities completed
  - Smart home commands issued
  - Camera/microphone access

**FR-4.2: Log Retention**
- Rolling 90-day retention by default
- Extended retention (up to 2 years) for institutional users
- Auto-deletion after retention period
- Manual deletion option in Adult Mode

**FR-4.3: Log Privacy Controls**
Parent chooses logging level:

| Level | What's Logged | Use Case |
|-------|---------------|----------|
| **High Privacy** | Only timestamps and session duration | Older children (10+) with earned trust |
| **Balanced** | Timestamps, topics, flagged content | Default for most families |
| **Full Transparency** | Complete conversation transcripts | Young children (5-7) or special needs |
| **Institutional** | Full logs + AI safety scoring | Schools, therapeutic settings |

**FR-4.4: Intelligent Summaries**
- AI-generated daily summaries: "Emma talked about space, asked 3 math questions, and discussed feelings about school"
- Sentiment analysis: Overall mood (happy, neutral, frustrated)
- Flag triggers: Concerning language, repeated negative themes, safety keywords
- Proactive alerts: "Emma mentioned feeling sad 5 times this week. Review conversations?"

**FR-4.5: Export and Compliance**
- Export logs as PDF (human-readable) or JSON (machine-readable)
- Include metadata: Moxie version, personality settings, child age
- Optional: Anonymize data for research sharing (PII removed)
- COPPA-compliant data deletion request support

#### Non-Functional Requirements

**NFR-4.1: Privacy**
- Logs encrypted at rest and in transit
- No cloud storage without explicit parent consent
- Local-first storage (macOS Application Support)
- Compliant with COPPA, FERPA, GDPR

**NFR-4.2: Performance**
- Log writes asynchronous (no blocking)
- Summary generation runs nightly at 2 AM
- Log viewer loads < 1 second for 30-day history

#### Acceptance Criteria

```gherkin
Given the parent has set logging level to "Balanced"
And the child had a 15-minute conversation about dinosaurs
When the parent opens the Activity Log in Adult Mode
Then they see:
  - Date/time: "Jan 7, 2026 at 3:45 PM"
  - Duration: "15 minutes"
  - Personality: "Default Moxie"
  - Topic Summary: "Discussed dinosaurs, favorite was T-Rex, asked about extinction"
  - Sentiment: "Curious and engaged"
  - No flagged content
And the parent does NOT see the full transcript
But can click "View Full Conversation" if needed

Given the child used concerning language: "I hate myself"
And logging level is any level
When Moxie detects the phrase
Then an immediate flag is created in the log
And a notification is sent to parent email
And the flag includes context (3 messages before/after)
And Moxie responds appropriately: "That sounds really hard. Would you like to talk to a grown-up about how you're feeling?"
```

---

### Feature 5: Personality Shift Between Modes

#### Overview
Moxie's personality, tone, and conversation style adapts based on who it's talking to: child or parent.

#### User Story
**As a child**, I want Moxie to feel like a fun friend who's on my level.

**As a parent**, I want Moxie to communicate professionally and provide useful parenting insights.

#### Functional Requirements

**FR-5.1: Child Mode Personality Traits**
- Playful and encouraging tone
- Age-appropriate vocabulary
- Frequent emotion expressions (e.g., `[emotion:happy]`)
- Short responses (30-50 words)
- Question-driven (engages curiosity)
- Uses child's name frequently
- References child profile (interests, goals)

**FR-5.2: Adult Mode Personality Traits**
- Professional and informative tone
- Expert vocabulary (parenting, development, education)
- No emotion expressions
- Longer, detailed responses (100-200 words)
- Evidence-based suggestions
- Third-person references to child
- Contextual awareness of child's recent activities

**FR-5.3: Transition Messaging**
When switching from Child to Adult Mode:
```
Child sees: "Moxie is going to rest now. See you soon!"
Parent sees: "Switched to Parent Console. How can I help you today?"
```

When switching from Adult to Child Mode:
```
Parent sees: "Exiting Parent Console. Child Mode will activate."
Child sees: "[emotion:happy] Hi Emma! What should we talk about?"
```

**FR-5.4: Voice Tone (If TTS Available)**
- Child Mode: Higher pitch, energetic inflection
- Adult Mode: Neutral pitch, measured pace
- Seamless transition (no jarring changes)

#### Example Personality Comparison

**Scenario: Child struggling with homework**

**Child Mode:**
```
Emma: "I don't understand my math homework."
Moxie: [emotion:curious] "Math can be tricky! What part is confusing you?
Let's figure it out together. Is it addition, subtraction, or something else?"
```

**Adult Mode:**
```
Parent: "My child is frustrated with math homework. How should I help?"
Moxie: "Homework frustration at age 7 is common. Here's a structured approach:

1. Validate feelings: 'Math can be hard. It's okay to feel stuck.'
2. Break problems into smaller steps
3. Use physical objects (blocks, fingers) for visualization
4. Take breaks every 10 minutes
5. Praise effort, not just correct answers

Would you like specific strategies for [addition/subtraction/word problems]?"
```

#### Non-Functional Requirements

**NFR-5.1: Consistency**
- Personality shift must be immediate (same message)
- No residual "child voice" in adult responses
- Personality traits defined in system prompts

**NFR-5.2: Quality Assurance**
- Pre-launch: Test 100+ scenarios in both modes
- Ongoing: Flag responses that don't match mode tone
- User feedback: "Was this response appropriate?" button

#### Acceptance Criteria

```gherkin
Given the parent has just entered Adult Mode via PIN
When they send a message "How is Emma doing socially?"
Then Moxie responds in professional tone
And uses third-person reference "Emma"
And provides developmental context
And does NOT use emotion tags like [emotion:happy]
And response is evidence-based with specific suggestions

Given the parent exits Adult Mode
And the child opens Moxie 10 minutes later
When Moxie greets the child
Then Moxie uses playful tone
And includes emotion tag [emotion:excited] or [emotion:happy]
And addresses child by name
And references child's interests
```

---

## Data Models

### Model 1: ParentAccount

Stores parent authentication and contact information.

```swift
struct ParentAccount: Codable, Identifiable {
    let id: UUID
    var email: String
    var emailVerified: Bool
    var securityQuestion: String
    var securityAnswerHash: String  // Hashed, never plaintext
    var notificationPreferences: NotificationPreferences
    var createdAt: Date
    var lastLoginAt: Date

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
        self.createdAt = Date()
        self.lastLoginAt = Date()
    }
}

struct NotificationPreferences: Codable {
    var emailOnFlaggedContent: Bool = true
    var emailOnPINFailures: Bool = true
    var emailOnTimeExtensionRequests: Bool = true
    var dailySummaryEmail: Bool = false
    var weeklyReportEmail: Bool = true
}
```

**Storage:** `~/Library/Application Support/SimpleMoxieSwitcher/parent_account.json`

**Security:** File permissions 600 (read/write owner only)

---

### Model 2: PINCredential

Securely stores PIN using macOS Keychain.

```swift
struct PINCredential {
    let serviceName: String = "com.moxie.parentpin"
    let accountName: String = "parent"

    // Store PIN in Keychain
    func storePIN(_ pin: String) throws {
        let pinData = pin.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: pinData
        ]

        // Delete old entry if exists
        SecItemDelete(query as CFDictionary)

        // Add new entry
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw PINError.storeFailed
        }
    }

    // Retrieve PIN from Keychain
    func retrievePIN() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let pinData = result as? Data,
              let pin = String(data: pinData, encoding: .utf8) else {
            throw PINError.retrieveFailed
        }

        return pin
    }

    // Validate PIN attempt
    func validatePIN(_ attempt: String) throws -> Bool {
        let storedPIN = try retrievePIN()
        return attempt == storedPIN
    }

    // Delete PIN (for reset)
    func deletePIN() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PINError.deleteFailed
        }
    }
}

enum PINError: Error {
    case storeFailed
    case retrieveFailed
    case deleteFailed
    case invalidFormat
    case tooWeak
}
```

**Storage:** macOS Keychain (system-managed, encrypted)

---

### Model 3: ModeContext

Tracks current operational mode and session state.

```swift
enum OperationalMode: String, Codable {
    case child = "child"
    case adult = "adult"
}

struct ModeContext: Codable {
    var currentMode: OperationalMode
    var sessionStartedAt: Date
    var lastActivityAt: Date
    var pinAttempts: [PINAttempt]
    var autoLockSchedule: AutoLockSchedule?

    init() {
        self.currentMode = .child  // Default to child mode
        self.sessionStartedAt = Date()
        self.lastActivityAt = Date()
        self.pinAttempts = []
        self.autoLockSchedule = nil
    }

    // Check if session should timeout (30 min inactivity in adult mode)
    var shouldTimeout: Bool {
        guard currentMode == .adult else { return false }
        let inactiveSeconds = Date().timeIntervalSince(lastActivityAt)
        return inactiveSeconds > 1800  // 30 minutes
    }

    // Check if PIN entry is locked (3 failed attempts)
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
        guard let firstFailed = recentAttempts.first else { return nil }
        let lockoutEnd = firstFailed.timestamp.addingTimeInterval(300)
        return lockoutEnd.timeIntervalSince(Date())
    }
}

struct PINAttempt: Codable {
    let timestamp: Date
    let success: Bool
    let ipAddress: String?  // For institutional deployments
}

struct AutoLockSchedule: Codable {
    var enabled: Bool
    var weekdayWindows: [TimeWindow]
    var weekendWindows: [TimeWindow]
    var lockBehavior: LockBehavior
    var schoolMode: SchoolMode?

    enum LockBehavior: String, Codable {
        case lockCompletely = "lock_completely"
        case switchToAdult = "switch_to_adult"
        case notifyOnly = "notify_only"
    }
}

struct TimeWindow: Codable, Identifiable {
    let id: UUID
    var startTime: TimeComponents  // e.g., 07:00
    var endTime: TimeComponents    // e.g., 20:00
    var enabled: Bool

    init(id: UUID = UUID(), startTime: TimeComponents, endTime: TimeComponents, enabled: Bool = true) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.enabled = enabled
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
}

struct TimeComponents: Codable {
    var hour: Int    // 0-23
    var minute: Int  // 0-59
}

struct SchoolMode: Codable {
    var enabled: Bool
    var weekdayStartTime: TimeComponents
    var weekdayEndTime: TimeComponents
    var allowHomeworkHelp: Bool  // Limited Q&A mode during school hours
}
```

**Storage:** In-memory during session, persisted to `mode_context.json` on changes

---

### Model 4: ConversationLog

Enhanced conversation model with mode awareness.

```swift
struct ConversationLog: Codable, Identifiable {
    let id: UUID
    let mode: OperationalMode  // NEW: child or adult
    let sessionID: UUID        // Groups messages in same session
    let childProfileID: UUID?  // Reference to child (nil for adult mode)
    let personality: String
    let messages: [ChatMessage]
    let summary: String?       // AI-generated summary
    let sentiment: Sentiment?  // AI-analyzed sentiment
    let flags: [ContentFlag]   // Safety flags
    let createdAt: Date
    let updatedAt: Date

    // Computed properties
    var duration: TimeInterval {
        guard let first = messages.first, let last = messages.last else { return 0 }
        return last.timestamp.timeIntervalSince(first.timestamp)
    }

    var messageCount: Int {
        messages.count
    }

    var hasFlaggedContent: Bool {
        !flags.isEmpty
    }
}

enum Sentiment: String, Codable {
    case veryPositive = "very_positive"
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
    case concerning = "concerning"  // Triggers parent notification
}

struct ContentFlag: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let severity: FlagSeverity
    let category: FlagCategory
    let messageContent: String
    let contextMessages: [ChatMessage]  // 3 before, 3 after for context
    let aiExplanation: String
    let reviewed: Bool  // Parent has reviewed this flag

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        severity: FlagSeverity,
        category: FlagCategory,
        messageContent: String,
        contextMessages: [ChatMessage] = [],
        aiExplanation: String,
        reviewed: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.severity = severity
        self.category = category
        self.messageContent = messageContent
        self.contextMessages = contextMessages
        self.aiExplanation = aiExplanation
        self.reviewed = reviewed
    }
}

enum FlagSeverity: String, Codable {
    case low = "low"           // Mild language, needs review
    case medium = "medium"     // Concerning theme, notify parent
    case high = "high"         // Safety risk, immediate alert
    case critical = "critical" // Emergency (self-harm, abuse), alert + resources
}

enum FlagCategory: String, Codable {
    case inappropriateLanguage = "inappropriate_language"
    case bullyingMention = "bullying_mention"
    case sadnessRepeated = "sadness_repeated"
    case angerRepeated = "anger_repeated"
    case selfHarmLanguage = "self_harm_language"
    case abuseIndicators = "abuse_indicators"
    case privacyRisk = "privacy_risk"  // Child sharing address, etc.
}
```

**Storage:**
- Child conversations: `~/Library/Application Support/SimpleMoxieSwitcher/conversations/child/`
- Adult conversations: `~/Library/Application Support/SimpleMoxieSwitcher/conversations/adult/`
- Separate directories ensure isolation

---

### Model 5: ActivityLog

Comprehensive audit trail.

```swift
struct ActivityLog: Codable {
    let events: [ActivityEvent]

    func getEvents(
        from startDate: Date,
        to endDate: Date,
        mode: OperationalMode? = nil,
        eventType: EventType? = nil
    ) -> [ActivityEvent] {
        events.filter { event in
            var matches = event.timestamp >= startDate && event.timestamp <= endDate
            if let mode = mode {
                matches = matches && event.mode == mode
            }
            if let eventType = eventType {
                matches = matches && event.type == eventType
            }
            return matches
        }
    }
}

struct ActivityEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let mode: OperationalMode
    let type: EventType
    let details: [String: String]  // Flexible metadata

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        mode: OperationalMode,
        type: EventType,
        details: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mode = mode
        self.type = type
        self.details = details
    }
}

enum EventType: String, Codable {
    // Mode events
    case modeSwitchToAdult = "mode_switch_to_adult"
    case modeSwitchToChild = "mode_switch_to_child"
    case pinEntrySuccess = "pin_entry_success"
    case pinEntryFailure = "pin_entry_failure"
    case pinLockoutTriggered = "pin_lockout_triggered"
    case sessionTimeout = "session_timeout"

    // Conversation events
    case conversationStarted = "conversation_started"
    case conversationEnded = "conversation_ended"
    case contentFlagged = "content_flagged"

    // Time restriction events
    case autoLockTriggered = "auto_lock_triggered"
    case timeExtensionRequested = "time_extension_requested"
    case timeExtensionGranted = "time_extension_granted"
    case timeExtensionDenied = "time_extension_denied"

    // Feature usage
    case storyAccessed = "story_accessed"
    case learningActivityCompleted = "learning_activity_completed"
    case smartHomeCommandIssued = "smart_home_command_issued"
    case cameraAccessed = "camera_accessed"

    // Data management
    case conversationExported = "conversation_exported"
    case dataDeleted = "data_deleted"
    case settingsChanged = "settings_changed"
}
```

**Storage:** `~/Library/Application Support/SimpleMoxieSwitcher/activity_log.json`

**Retention:** Auto-prune events older than configured retention period (default 90 days)

---

### Model 6: LoggingPreferences

Parent-controlled privacy settings.

```swift
struct LoggingPreferences: Codable {
    var level: LoggingLevel
    var retentionDays: Int
    var intelligentSummaries: Bool
    var sentimentAnalysis: Bool
    var contentFlagging: Bool
    var flaggingKeywords: [String]  // Custom keywords to flag

    init() {
        self.level = .balanced
        self.retentionDays = 90
        self.intelligentSummaries = true
        self.sentimentAnalysis = true
        self.contentFlagging = true
        self.flaggingKeywords = []
    }
}

enum LoggingLevel: String, Codable {
    case highPrivacy = "high_privacy"
    case balanced = "balanced"
    case fullTransparency = "full_transparency"
    case institutional = "institutional"

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
}
```

**Storage:** Part of `ParentAccount` or separate `logging_preferences.json`

---

## User Flows

### Flow 1: First-Time Setup with PIN Creation

**Actors:** Parent
**Precondition:** App installed, first launch
**Postcondition:** PIN created, parent email verified, child profile created

```
┌─────────────────────────────────────────────────────────────────┐
│                    MOXIE SETUP WIZARD                           │
└─────────────────────────────────────────────────────────────────┘

STEP 1: WELCOME
┌─────────────────────────────────────────────────────────────────┐
│  Welcome to Moxie!                                              │
│                                                                 │
│  Before your child starts chatting, let's set up parental      │
│  controls to keep them safe.                                   │
│                                                                 │
│  This will take about 3 minutes.                               │
│                                                                 │
│                    [Get Started]                                │
└─────────────────────────────────────────────────────────────────┘

STEP 2: PARENT EMAIL
┌─────────────────────────────────────────────────────────────────┐
│  What's your email address?                                     │
│                                                                 │
│  We'll use this to:                                            │
│  • Send safety alerts if needed                               │
│  • Reset your PIN if you forget it                            │
│  • Send optional weekly summaries                             │
│                                                                 │
│  Email: [___________________________]                          │
│                                                                 │
│  We never share your email. See Privacy Policy.               │
│                                                                 │
│                [Back]              [Continue]                   │
└─────────────────────────────────────────────────────────────────┘

STEP 3: EMAIL VERIFICATION
┌─────────────────────────────────────────────────────────────────┐
│  Check your email                                               │
│                                                                 │
│  We sent a verification code to:                               │
│  parent@example.com                                            │
│                                                                 │
│  Enter the 6-digit code:                                       │
│  [___] [___] [___] [___] [___] [___]                          │
│                                                                 │
│  Didn't receive it? [Resend Code]                             │
│                                                                 │
│                [Back]              [Verify]                     │
└─────────────────────────────────────────────────────────────────┘

STEP 4: CREATE PIN
┌─────────────────────────────────────────────────────────────────┐
│  Create a 6-digit PIN                                          │
│                                                                 │
│  This PIN protects settings and gives you access to:          │
│  ✓ Conversation logs                                          │
│  ✓ Time restrictions                                          │
│  ✓ Advanced features                                          │
│                                                                 │
│  Enter PIN: [●] [●] [●] [●] [●] [●]                           │
│                                                                 │
│  PIN Strength: [████████░░] Strong                             │
│                                                                 │
│  ⚠ Avoid: 123456, 111111, or your child's birthday           │
│                                                                 │
│                [Back]              [Continue]                   │
└─────────────────────────────────────────────────────────────────┘

STEP 5: CONFIRM PIN
┌─────────────────────────────────────────────────────────────────┐
│  Confirm your PIN                                              │
│                                                                 │
│  Enter your PIN again:                                         │
│  [_] [_] [_] [_] [_] [_]                                      │
│                                                                 │
│  ✗ PINs don't match. Try again.                               │
│                                                                 │
│                [Back]              [Continue]                   │
└─────────────────────────────────────────────────────────────────┘

STEP 6: SECURITY QUESTION
┌─────────────────────────────────────────────────────────────────┐
│  Set a security question                                       │
│                                                                 │
│  If you forget your PIN, we'll ask this question:             │
│                                                                 │
│  Question: [What city were you born in?    ▼]                 │
│                                                                 │
│  Answer: [___________________________]                         │
│                                                                 │
│  Note: Keep this answer private from your child.              │
│                                                                 │
│                [Back]              [Continue]                   │
└─────────────────────────────────────────────────────────────────┘

STEP 7: CHILD PROFILE
┌─────────────────────────────────────────────────────────────────┐
│  Tell us about your child                                      │
│                                                                 │
│  Name: [Emma                    ]                              │
│                                                                 │
│  Birthday: [01/15/2019          ]  (Age: 7)                   │
│                                                                 │
│  Interests: [+ Add Interest]                                   │
│    • Space  ✕                                                 │
│    • Dinosaurs  ✕                                             │
│                                                                 │
│  This helps Moxie personalize conversations!                   │
│                                                                 │
│                [Back]              [Continue]                   │
└─────────────────────────────────────────────────────────────────┘

STEP 8: TIME RESTRICTIONS (OPTIONAL)
┌─────────────────────────────────────────────────────────────────┐
│  Set bedtime auto-lock? (Optional)                             │
│                                                                 │
│  Moxie can automatically lock at bedtime to prevent late-      │
│  night unsupervised use.                                       │
│                                                                 │
│  □ Enable bedtime lock                                        │
│                                                                 │
│  Bedtime: [8:00 PM ▼]                                         │
│  Wake time: [7:00 AM ▼]                                       │
│                                                                 │
│  You can change this anytime in settings.                     │
│                                                                 │
│          [Skip]        [Back]        [Enable & Continue]       │
└─────────────────────────────────────────────────────────────────┘

STEP 9: LOGGING PREFERENCES
┌─────────────────────────────────────────────────────────────────┐
│  Choose privacy level                                          │
│                                                                 │
│  How much detail should we log?                                │
│                                                                 │
│  ○ High Privacy (Timestamps only)                             │
│    Best for older children (10+)                              │
│                                                                 │
│  ● Balanced (Topics + Flags)  [RECOMMENDED]                   │
│    See what they discussed without full transcripts           │
│                                                                 │
│  ○ Full Transparency (Complete Transcripts)                   │
│    Best for young children (5-7)                              │
│                                                                 │
│  You can change this anytime.                                 │
│                                                                 │
│                [Back]              [Continue]                   │
└─────────────────────────────────────────────────────────────────┘

STEP 10: COMPLETE
┌─────────────────────────────────────────────────────────────────┐
│  All set!                                                      │
│                                                                 │
│  ✓ PIN created                                                │
│  ✓ Email verified                                             │
│  ✓ Emma's profile created                                     │
│  ✓ Bedtime lock enabled (8 PM - 7 AM)                        │
│  ✓ Privacy settings configured                                │
│                                                                 │
│  Moxie is ready for Emma to start chatting!                   │
│                                                                 │
│  Tip: Access Parent Console anytime by clicking the           │
│  settings icon and entering your PIN.                         │
│                                                                 │
│                    [Start Chatting!]                           │
└─────────────────────────────────────────────────────────────────┘
```

---

### Flow 2: Child Attempting to Access During Restricted Time

**Actors:** Child
**Precondition:** Bedtime lock enabled (8 PM - 7 AM), current time is 9 PM
**Postcondition:** Child sees friendly lock message, option to request more time

```
┌─────────────────────────────────────────────────────────────────┐
│                    MOXIE IS SLEEPING                            │
└─────────────────────────────────────────────────────────────────┘

SCENARIO A: CHILD OPENS APP DURING LOCKED HOURS
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                        🌙                                       │
│                                                                 │
│              Moxie is sleeping right now!                      │
│                                                                 │
│         I'll wake up tomorrow morning at 7:00 AM.              │
│                                                                 │
│              Sweet dreams! See you soon! 💤                     │
│                                                                 │
│                                                                 │
│              [Need to Ask Something?]                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

IF CHILD CLICKS "Need to Ask Something?"
┌─────────────────────────────────────────────────────────────────┐
│              Request More Time                                  │
│                                                                 │
│  Do you need help with something important?                    │
│                                                                 │
│  I can ask your parent for permission to wake up.              │
│                                                                 │
│  What do you need help with?                                   │
│  [___________________________________________]                 │
│  (Example: homework, feeling worried, question)                │
│                                                                 │
│                                                                 │
│          [Cancel]              [Ask Permission]                 │
└─────────────────────────────────────────────────────────────────┘

IF CHILD CLICKS "Ask Permission"
┌─────────────────────────────────────────────────────────────────┐
│              Request Sent!                                      │
│                                                                 │
│                        📨                                       │
│                                                                 │
│         Your parent has been notified.                         │
│                                                                 │
│         They can unlock Moxie if it's important.               │
│                                                                 │
│         Please wait for their response.                        │
│                                                                 │
│                                                                 │
│                    [Okay]                                       │
└─────────────────────────────────────────────────────────────────┘

PARENT RECEIVES EMAIL:
┌─────────────────────────────────────────────────────────────────┐
│  From: Moxie <notifications@moxie.app>                         │
│  Subject: Emma requested to unlock Moxie                       │
│                                                                 │
│  Hi,                                                            │
│                                                                 │
│  Emma tried to use Moxie during bedtime (9:15 PM) and          │
│  requested more time.                                          │
│                                                                 │
│  Reason: "Need help with homework"                             │
│                                                                 │
│  [Approve for 30 Minutes]  [Deny]  [Unlock Until Morning]     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

IF PARENT APPROVES:
┌─────────────────────────────────────────────────────────────────┐
│              Permission Granted!                                │
│                                                                 │
│                        ✓                                        │
│                                                                 │
│         Your parent said I can help!                           │
│                                                                 │
│         You have 30 minutes to chat.                           │
│                                                                 │
│         What do you need help with?                            │
│                                                                 │
│                                                                 │
│                    [Start Chatting]                            │
└─────────────────────────────────────────────────────────────────┘

IF PARENT DENIES:
┌─────────────────────────────────────────────────────────────────┐
│              Back to Sleep                                      │
│                                                                 │
│                        🌙                                       │
│                                                                 │
│         Your parent said it's time to rest.                    │
│                                                                 │
│         I'll see you tomorrow morning at 7:00 AM!              │
│                                                                 │
│         If you need help tonight, ask your parent.             │
│                                                                 │
│                                                                 │
│                    [Okay]                                       │
└─────────────────────────────────────────────────────────────────┘
```

---

### Flow 3: Parent Entering Adult Mode to Review Conversations

**Actors:** Parent
**Precondition:** Child has had conversations, parent wants to review
**Postcondition:** Parent views conversation summaries, can drill into details

```
┌─────────────────────────────────────────────────────────────────┐
│                PARENT CONSOLE ACCESS                            │
└─────────────────────────────────────────────────────────────────┘

STEP 1: INITIATE MODE SWITCH
┌─────────────────────────────────────────────────────────────────┐
│  MOXIE CONTROLLER                           [Settings ⚙]       │
│                                                                 │
│  [Parent clicks Settings icon]                                 │
└─────────────────────────────────────────────────────────────────┘

STEP 2: PIN ENTRY
┌─────────────────────────────────────────────────────────────────┐
│              Enter Parent PIN                                   │
│                                                                 │
│  Access to parental controls and conversation logs.            │
│                                                                 │
│              [●] [●] [●] [●] [●] [●]                           │
│                                                                 │
│                 [Forgot PIN?]                                  │
│                                                                 │
│                                                                 │
│          [Cancel]              [Unlock]                         │
└─────────────────────────────────────────────────────────────────┘

STEP 3: ADULT MODE HOME
┌─────────────────────────────────────────────────────────────────┐
│  PARENT CONSOLE                             [Exit 🚪]          │
│  Viewing data for: Emma (Age 7)                                │
└─────────────────────────────────────────────────────────────────┘
│                                                                 │
│  TODAY'S SUMMARY (Jan 7, 2026)                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  💬 3 conversations (45 minutes total)                  │   │
│  │  📚 Topics: Space, dinosaurs, math homework             │   │
│  │  😊 Mood: Curious and engaged                          │   │
│  │  ⚠ 0 flags                                             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  QUICK ACTIONS                                                  │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐           │
│  │ 📋 Activity  │ │ ⚙ Settings   │ │ 📊 Reports   │           │
│  │    Logs      │ │              │ │              │           │
│  └──────────────┘ └──────────────┘ └──────────────┘           │
│                                                                 │
│  RECENT CONVERSATIONS                                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 🕐 3:45 PM (15 min) - Default Moxie                    │   │
│  │ Topics: Dinosaurs, T-Rex, extinction                   │   │
│  │ Sentiment: Curious 😊                                  │   │
│  │                                    [View Details →]    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  │ 🕐 2:20 PM (18 min) - Default Moxie                    │   │
│  │ Topics: Math homework, addition, frustration           │   │
│  │ Sentiment: Frustrated → Relieved 😅                    │   │
│  │                                    [View Details →]    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  │ 🕐 10:30 AM (12 min) - Default Moxie                   │   │
│  │ Topics: Space, planets, astronauts                     │   │
│  │ Sentiment: Excited 🚀                                  │   │
│  │                                    [View Details →]    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

STEP 4: VIEW CONVERSATION DETAILS
[Parent clicks "View Details" on dinosaur conversation]

┌─────────────────────────────────────────────────────────────────┐
│  ← Back to Dashboard                        [Export PDF]       │
│                                                                 │
│  CONVERSATION DETAILS                                           │
│  Date: Jan 7, 2026 at 3:45 PM                                  │
│  Duration: 15 minutes                                          │
│  Personality: Default Moxie                                    │
│  Messages: 18                                                  │
│  Sentiment: Curious and engaged 😊                             │
└─────────────────────────────────────────────────────────────────┘
│                                                                 │
│  AI SUMMARY                                                     │
│  Emma asked about dinosaurs, especially T-Rex. Moxie shared    │
│  facts about dinosaur size, diet, and extinction. Emma showed  │
│  strong curiosity and asked follow-up questions. No concerns.  │
│                                                                 │
│  TOPICS DISCUSSED                                               │
│  • Tyrannosaurus Rex characteristics                           │
│  • Dinosaur extinction theories                                │
│  • Paleontology as a career                                    │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  CONVERSATION TRANSCRIPT                                        │
│  (Based on logging level: Balanced - Showing summaries)        │
│                                                                 │
│  [Want full transcript? Change logging to "Full Transparency"] │
│                                                                 │
│  3:45 PM - Emma: Asked about T-Rex                             │
│  3:46 PM - Moxie: Shared facts about T-Rex size and diet       │
│  3:47 PM - Emma: Asked why dinosaurs went extinct              │
│  3:48 PM - Moxie: Explained asteroid theory                    │
│  3:50 PM - Emma: Asked if she could be a paleontologist        │
│  3:51 PM - Moxie: Encouraged interest, explained career path   │
│  [... 12 more exchanges ...]                                   │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  SAFETY ANALYSIS                                                │
│  ✓ No inappropriate content detected                           │
│  ✓ Age-appropriate topics                                      │
│  ✓ Positive sentiment maintained                               │
│  ✓ Educational value: High                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

STEP 5: ACTIVITY LOG VIEW
[Parent clicks "Activity Logs" from dashboard]

┌─────────────────────────────────────────────────────────────────┐
│  ← Back to Dashboard                                           │
│                                                                 │
│  ACTIVITY LOG                                                   │
│  Filter: [Last 7 Days ▼] [All Events ▼]        [Export CSV]   │
└─────────────────────────────────────────────────────────────────┘
│                                                                 │
│  TODAY (Jan 7, 2026)                                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 3:45 PM  💬 Conversation Started                        │   │
│  │          Mode: Child | Personality: Default Moxie       │   │
│  │          Duration: 15 min | Topic: Dinosaurs            │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  │ 2:20 PM  💬 Conversation Started                        │   │
│  │          Mode: Child | Personality: Default Moxie       │   │
│  │          Duration: 18 min | Topic: Math homework        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  │ 10:30 AM 💬 Conversation Started                        │   │
│  │          Mode: Child | Personality: Default Moxie       │   │
│  │          Duration: 12 min | Topic: Space                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  │ 9:45 AM  🔐 Parent Console Accessed                     │   │
│  │          PIN entry successful                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  YESTERDAY (Jan 6, 2026)                                       │
│  │ 7:30 PM  ⏰ Auto-lock Triggered                         │   │
│  │          Bedtime lock activated (8:00 PM)               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  │ 4:15 PM  📚 Story Accessed                              │   │
│  │          Title: "The Three Little Pigs"                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

### Flow 4: Flagged Content Alert

**Actors:** System (AI), Parent
**Precondition:** Child uses concerning language in conversation
**Postcondition:** Parent alerted, conversation context provided, resources offered

```
┌─────────────────────────────────────────────────────────────────┐
│                SAFETY FLAG WORKFLOW                             │
└─────────────────────────────────────────────────────────────────┘

SCENARIO: Child says "I hate myself" during conversation

STEP 1: AI DETECTION (Real-Time)
┌─────────────────────────────────────────────────────────────────┐
│  [SYSTEM PROCESSING]                                            │
│                                                                 │
│  Message: "I hate myself"                                      │
│  Analysis: CRITICAL FLAG - Self-harm language                  │
│  Severity: High                                                │
│  Action: Alert parent + provide supportive response            │
└─────────────────────────────────────────────────────────────────┘

STEP 2: MOXIE'S RESPONSE TO CHILD
┌─────────────────────────────────────────────────────────────────┐
│  Emma: "I hate myself"                                         │
│                                                                 │
│  Moxie: [emotion:concerned] I'm sorry you're feeling that way. │
│  Those feelings are really hard. It's important to talk to a   │
│  grown-up when you feel like this. Would you like to talk to   │
│  your parent or another adult you trust?                       │
│                                                                 │
│  Remember: You matter, and there are people who care about you.│
│                                                                 │
│  [Talk to grown-up] [Keep talking to Moxie] [I'm okay now]    │
└─────────────────────────────────────────────────────────────────┘

STEP 3: IMMEDIATE EMAIL TO PARENT
┌─────────────────────────────────────────────────────────────────┐
│  From: Moxie Safety Alerts <safety@moxie.app>                  │
│  Subject: 🚨 IMPORTANT: Emma needs your attention              │
│  Priority: High                                                │
│                                                                 │
│  Hi,                                                            │
│                                                                 │
│  Emma used language that may indicate distress during a        │
│  conversation with Moxie at 4:22 PM today.                     │
│                                                                 │
│  What was said: "I hate myself"                                │
│                                                                 │
│  This may be serious. We recommend checking in with Emma       │
│  soon to understand what's going on.                           │
│                                                                 │
│  [View Full Context]  [Get Help Resources]                     │
│                                                                 │
│  Moxie responded with support and encouraged Emma to talk to   │
│  a trusted adult.                                              │
│                                                                 │
│  If you're concerned, here are resources:                      │
│  • National Suicide Prevention Lifeline: 988                   │
│  • Crisis Text Line: Text HOME to 741741                       │
│  • Talk to your pediatrician                                   │
│                                                                 │
│  You're not alone in this. We're here to help.                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

STEP 4: PARENT CLICKS "View Full Context"
┌─────────────────────────────────────────────────────────────────┐
│  SAFETY FLAG DETAILS                                            │
│  Date: Jan 7, 2026 at 4:22 PM                                  │
│  Severity: HIGH                                                │
│  Category: Self-harm language                                  │
└─────────────────────────────────────────────────────────────────┘
│                                                                 │
│  CONVERSATION CONTEXT                                           │
│  (3 messages before and after for full context)                │
│                                                                 │
│  4:18 PM - Emma: "I got a bad grade on my spelling test"      │
│  4:19 PM - Moxie: [emotion:concerned] "That can feel           │
│              disappointing. What happened?"                    │
│  4:20 PM - Emma: "I studied but still got it wrong"           │
│  4:21 PM - Moxie: "Making mistakes is how we learn. What do   │
│              you think you could do differently next time?"    │
│                                                                 │
│  4:22 PM - Emma: "I hate myself"  ⚠ FLAGGED                   │
│                                                                 │
│  4:22 PM - Moxie: [emotion:concerned] "I'm sorry you're        │
│              feeling that way. Those feelings are really hard. │
│              It's important to talk to a grown-up when you     │
│              feel like this..."                                │
│  4:23 PM - Emma: [Selected "Talk to grown-up"]                │
│  4:23 PM - Moxie: "That's a good choice. I'm proud of you     │
│              for deciding to talk about it."                   │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  AI ANALYSIS                                                    │
│  This appears to be self-criticism triggered by academic       │
│  disappointment (spelling test). While concerning, the context │
│  suggests frustration rather than immediate danger. However,   │
│  we recommend:                                                 │
│                                                                 │
│  1. Talk to Emma about the spelling test and her feelings     │
│  2. Validate her emotions without dismissing them              │
│  3. Help her develop healthier self-talk strategies           │
│  4. Monitor for repeated patterns of negative self-talk       │
│                                                                 │
│  If this language continues or escalates, consider consulting  │
│  a child therapist or school counselor.                        │
│                                                                 │
│  [Mark as Reviewed] [Get Professional Resources] [Export]     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

STEP 5: FLAG APPEARS IN PARENT CONSOLE
[When parent next logs into Parent Console]

┌─────────────────────────────────────────────────────────────────┐
│  PARENT CONSOLE                             [Exit 🚪]          │
│                                                                 │
│  🚨 UNREVIEWED SAFETY FLAG                                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ ⚠ HIGH SEVERITY - Self-harm language                   │   │
│  │ Jan 7, 2026 at 4:22 PM                                 │   │
│  │ "I hate myself"                                        │   │
│  │                                                        │   │
│  │ [Review Now →]                      [Already Handled]  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

### Flow 5: PIN Reset (Forgot PIN)

**Actors:** Parent
**Precondition:** Parent forgot PIN, has access to email
**Postcondition:** PIN successfully reset

```
┌─────────────────────────────────────────────────────────────────┐
│                    PIN RESET FLOW                               │
└─────────────────────────────────────────────────────────────────┘

STEP 1: FORGOT PIN CLICK
┌─────────────────────────────────────────────────────────────────┐
│              Enter Parent PIN                                   │
│                                                                 │
│              [_] [_] [_] [_] [_] [_]                           │
│                                                                 │
│                 [Forgot PIN?]  ← CLICK                         │
└─────────────────────────────────────────────────────────────────┘

STEP 2: CHOOSE RESET METHOD
┌─────────────────────────────────────────────────────────────────┐
│              Reset Your PIN                                     │
│                                                                 │
│  Choose how you'd like to reset your PIN:                      │
│                                                                 │
│  ○ Email me a reset link                                      │
│    We'll send a link to: p***t@example.com                    │
│                                                                 │
│  ○ Answer my security question                                │
│    "What city were you born in?"                              │
│                                                                 │
│                                                                 │
│          [Cancel]              [Continue]                       │
└─────────────────────────────────────────────────────────────────┘

OPTION A: EMAIL RESET
┌─────────────────────────────────────────────────────────────────┐
│              Check Your Email                                   │
│                                                                 │
│  We sent a PIN reset link to:                                 │
│  parent@example.com                                            │
│                                                                 │
│  The link expires in 1 hour for security.                     │
│                                                                 │
│  Didn't receive it?                                            │
│  • Check your spam folder                                     │
│  • [Resend Email]                                             │
│  • [Try Security Question Instead]                            │
│                                                                 │
│                                                                 │
│                    [Okay]                                       │
└─────────────────────────────────────────────────────────────────┘

EMAIL RECEIVED:
┌─────────────────────────────────────────────────────────────────┐
│  From: Moxie Security <security@moxie.app>                     │
│  Subject: Reset Your Moxie PIN                                 │
│                                                                 │
│  Hi,                                                            │
│                                                                 │
│  You requested to reset your Moxie Parent PIN.                 │
│                                                                 │
│  Click the link below to create a new PIN:                     │
│  [Reset My PIN]                                                │
│  (Link expires in 1 hour)                                      │
│                                                                 │
│  If you didn't request this, please ignore this email.         │
│  Your current PIN is still active.                             │
│                                                                 │
│  For help, reply to this email.                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

PARENT CLICKS LINK → Opens in browser:
┌─────────────────────────────────────────────────────────────────┐
│  MOXIE - Reset Your PIN                                        │
│                                                                 │
│  Create a new 6-digit PIN                                      │
│                                                                 │
│  New PIN: [_] [_] [_] [_] [_] [_]                             │
│                                                                 │
│  PIN Strength: [████████░░] Strong                             │
│                                                                 │
│  Confirm PIN: [_] [_] [_] [_] [_] [_]                         │
│                                                                 │
│                                                                 │
│                    [Reset PIN]                                  │
└─────────────────────────────────────────────────────────────────┘

SUCCESS:
┌─────────────────────────────────────────────────────────────────┐
│              PIN Reset Successfully!                            │
│                                                                 │
│                        ✓                                        │
│                                                                 │
│         Your PIN has been updated.                             │
│                                                                 │
│         Return to Moxie and use your new PIN to access         │
│         the Parent Console.                                    │
│                                                                 │
│                                                                 │
│                    [Done]                                       │
└─────────────────────────────────────────────────────────────────┘

OPTION B: SECURITY QUESTION
┌─────────────────────────────────────────────────────────────────┐
│              Answer Security Question                           │
│                                                                 │
│  What city were you born in?                                   │
│                                                                 │
│  Answer: [___________________________]                         │
│                                                                 │
│  (Case-insensitive)                                            │
│                                                                 │
│                                                                 │
│          [Cancel]              [Verify]                         │
└─────────────────────────────────────────────────────────────────┘

IF CORRECT:
┌─────────────────────────────────────────────────────────────────┐
│              Create New PIN                                     │
│                                                                 │
│  New PIN: [_] [_] [_] [_] [_] [_]                             │
│                                                                 │
│  Confirm: [_] [_] [_] [_] [_] [_]                             │
│                                                                 │
│                                                                 │
│          [Cancel]              [Reset PIN]                      │
└─────────────────────────────────────────────────────────────────┘

IF INCORRECT (3 attempts allowed):
┌─────────────────────────────────────────────────────────────────┐
│              Incorrect Answer                                   │
│                                                                 │
│  That answer doesn't match our records.                        │
│                                                                 │
│  Attempts remaining: 2                                         │
│                                                                 │
│                                                                 │
│          [Try Again]        [Use Email Instead]                 │
└─────────────────────────────────────────────────────────────────┘

AFTER 3 FAILED ATTEMPTS:
┌─────────────────────────────────────────────────────────────────┐
│              Too Many Failed Attempts                           │
│                                                                 │
│  For security, you must use email reset.                       │
│                                                                 │
│  We'll send a reset link to:                                   │
│  parent@example.com                                            │
│                                                                 │
│                                                                 │
│          [Cancel]        [Send Reset Email]                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## UX Guidelines

### Guideline 1: Communicating Safety Without Fear

**Principle:** Safety features should feel supportive, not punitive. Children should understand boundaries without feeling surveilled or distrusted.

#### Voice and Tone

**Child-Facing Messages:**
- Use warm, friendly language
- Focus on care and safety, not rules and consequences
- Explain "why" in age-appropriate terms
- Celebrate good choices

**Examples:**

❌ **Avoid (Punitive):**
"Your parents are watching everything you say."
"You're not allowed to use Moxie right now."
"This conversation has been reported."

✅ **Prefer (Supportive):**
"I help keep you safe by remembering what we talk about."
"Moxie is resting now. See you in the morning!"
"I noticed you're feeling sad. Would you like to talk to a grown-up?"

**Parent-Facing Messages:**
- Be clear and direct
- Provide actionable information
- Acknowledge complexity (parenting is hard)
- Offer resources and context

**Examples:**

❌ **Avoid (Judgmental):**
"Your child violated safety rules."
"You must review this immediately."
"This is a serious problem."

✅ **Prefer (Supportive):**
"Emma used language that may indicate distress. Here's what happened and how to help."
"We noticed a pattern worth discussing with Emma."
"You're doing a great job staying involved. Here are some resources that might help."

---

### Guideline 2: Visual Indicators for Mode Distinction

**Goal:** Users should instantly know which mode they're in without reading text.

#### Color Scheme

| Element | Child Mode | Adult Mode |
|---------|------------|------------|
| Primary Color | Cyan (#00D4FF) | Purple (#9D4EDD) |
| Background | Gradient (cyan/blue) | Gradient (purple/gray) |
| Accent | Green (#00FF88) | Dark Gray (#4A4A4A) |
| Text | White | White |

#### Visual Elements

**Child Mode:**
- Badge: "👋 Hi Emma!" (top-left corner)
- Playful fonts (rounded, friendly)
- Emoji in headings
- Animated hover effects
- Bright, energetic colors

**Adult Mode:**
- Badge: "🔒 Parent Console" (top-left corner)
- Professional fonts (clean, readable)
- No emoji in headings (except flags/alerts)
- Minimal animations
- Muted, serious colors

#### Mode Transition Animation

```
Child → Adult Mode:
1. Screen fades to black (300ms)
2. Badge changes from "Hi Emma!" to "Parent Console"
3. Color scheme shifts (cyan → purple) with gradient blend (500ms)
4. Content loads with slide-up animation (400ms)

Adult → Child Mode:
1. Screen fades to white (300ms)
2. Badge changes from "Parent Console" to "Hi Emma!"
3. Color scheme shifts (purple → cyan) with gradient blend (500ms)
4. Moxie greeting appears with bounce animation (400ms)
```

---

### Guideline 3: Age-Appropriate Transparency

**Principle:** Children have a right to know what's being logged, but explanations must match their developmental stage.

#### Ages 5-7 (Concrete Thinkers)

**What to say:**
"Moxie remembers what we talk about so I can help you better next time. Your parents can see what we talked about to keep you safe, just like they know what you do at school."

**Visual:**
Show a simple icon: 💬📋 (conversation → memory book)

#### Ages 8-10 (Rule-Oriented)

**What to say:**
"Our conversations are saved so Moxie can remember your interests and help you learn. Your parents can review conversations to make sure everything is safe and appropriate, like how teachers check homework."

**Visual:**
Show a progress bar of "Things Moxie Remembers About You" with positive framing

#### Ages 11-13 (Privacy-Conscious)

**What to say:**
"You have privacy, and your parents respect that. They can see conversation summaries and topics, but only read full details if they're concerned about your safety. You can talk to them about adjusting privacy settings together."

**Visual:**
Settings page showing privacy level with parent/child collaboration framing

#### For All Ages

**Empowering Statement:**
"If you ever feel uncomfortable or need to talk about something private, you can always tell Moxie to help you talk to a trusted grown-up instead."

---

### Guideline 4: Avoiding Surveillance Language

**Replace These Terms:**

| ❌ Surveillance Frame | ✅ Safety Frame |
|---------------------|----------------|
| "Monitor your child" | "Stay connected with your child" |
| "Track conversations" | "Review conversations" |
| "Parental surveillance" | "Parental guidance tools" |
| "Spy on activity" | "Stay informed about activity" |
| "Child compliance" | "Child safety" |
| "Restricted access" | "Guided access" |
| "Lockdown mode" | "Rest time" / "Sleep mode" |

**In Marketing/Docs:**
Focus on partnership, trust, and development—not control and oversight.

---

### Guideline 5: Error Messages and Edge Cases

#### PIN Entry Errors

**Incorrect PIN (1st attempt):**
"That PIN doesn't match. Try again. (2 attempts remaining)"

**Incorrect PIN (3rd attempt):**
"Too many incorrect attempts. For security, please wait 5 minutes before trying again. Forgot your PIN? We can help reset it."

**PIN Lockout Active:**
"For security, PIN entry is locked. Try again in 3:42."

#### Time Restriction Errors

**Child tries to access during bedtime:**
"Moxie is sleeping right now! I'll wake up tomorrow morning at 7:00 AM. Sweet dreams! 🌙"

**Child tries to access during school:**
"Moxie is at school too! Focus on learning, and we'll chat later! 📚"

#### Connectivity Errors

**MQTT disconnected during mode switch:**
"Connection lost. Some features may be unavailable. You can still access local settings."

**API unavailable during conversation:**
"Moxie is having trouble thinking right now. Please try again in a moment."

---

## Privacy Policy

### Introduction

Moxie is a children's AI companion designed with privacy and safety as our highest priorities. This policy explains what data we collect, how we use it, and how we protect it.

**Last Updated:** January 7, 2026
**Effective Date:** January 7, 2026

---

### 1. Information We Collect

#### 1.1 Parent-Provided Information
When you set up Moxie, we collect:
- Parent email address (for verification, alerts, and PIN reset)
- Security question and answer (hashed, for PIN recovery)
- Child's first name
- Child's birthday (to calculate age for age-appropriate responses)
- Child's interests and goals (to personalize conversations)
- Notification preferences

#### 1.2 Automatically Collected Information
During app usage, we collect:
- Conversation transcripts (child mode and adult mode, stored separately)
- Timestamps of interactions
- Personality modes used
- Session durations
- PIN entry attempts (timestamp, success/failure)
- Mode switching events
- Feature usage (stories, learning activities, smart home commands)
- System information (macOS version, app version)

#### 1.3 AI-Generated Information
Our AI systems generate:
- Conversation summaries
- Sentiment analysis
- Topic categorization
- Safety flags for concerning content

---

### 2. How We Use Information

#### 2.1 Core Functionality
- Provide personalized AI conversations for your child
- Remember context across sessions for better interactions
- Adapt responses based on child's age and interests

#### 2.2 Safety and Security
- Detect and flag potentially concerning language
- Alert parents to safety risks
- Enforce time restrictions and access controls
- Secure parental controls via PIN

#### 2.3 Parental Transparency
- Provide conversation logs and activity summaries
- Generate weekly/daily reports (if opted in)
- Support informed parenting decisions

#### 2.4 Product Improvement
- Improve AI response quality (only with explicit consent)
- Fix bugs and technical issues
- Develop new features

**We NEVER:**
- Sell or share your child's data with third parties
- Use conversations for advertising or marketing
- Share data with schools without explicit consent
- Train AI models on your data without permission

---

### 3. Data Storage and Security

#### 3.1 Local-First Architecture
By default, all data is stored locally on your macOS device:
- Location: `~/Library/Application Support/SimpleMoxieSwitcher/`
- Encryption: FileVault encryption (if enabled on your Mac)
- Access: Only your user account can access these files

#### 3.2 Optional Cloud Backup
If you enable cloud backup (opt-in):
- Data encrypted in transit (TLS 1.3)
- Data encrypted at rest (AES-256)
- Servers located in the United States
- Regular security audits
- COPPA-compliant infrastructure

#### 3.3 PIN Security
- Parent PIN stored in macOS Keychain (system-level encryption)
- Never stored in plaintext
- Never logged or transmitted
- Secure deletion upon PIN reset

---

### 4. Data Retention

#### 4.1 Automatic Deletion
- Conversation logs: Deleted after retention period (default 90 days)
- Activity logs: Deleted after retention period (default 90 days)
- Flagged content: Retained until reviewed + 30 days
- Account data: Retained until account deletion

#### 4.2 Manual Deletion
Parents can delete:
- Individual conversations
- Date ranges of logs
- All child data (irreversible)
- Entire account

#### 4.3 Extended Retention (Institutional Users)
Schools and therapy practices may configure extended retention (up to 2 years) for compliance purposes. Parents will be notified of retention policies.

---

### 5. Children's Privacy (COPPA Compliance)

We comply with the Children's Online Privacy Protection Act (COPPA):

#### 5.1 Parental Consent
- Verifiable parental consent required during setup
- Email verification confirms parent identity
- PIN system ensures only parents access sensitive data

#### 5.2 Minimal Data Collection
- We collect only information necessary for functionality
- No tracking cookies or advertising IDs
- No geolocation data
- No contact list access
- No camera/microphone data stored (used only for live interaction)

#### 5.3 Data Rights
Parents can:
- Review all data collected about their child
- Request data deletion at any time
- Export data in human-readable format
- Withdraw consent (deletes all data within 30 days)

#### 5.4 Age Verification
- App requires parent authentication before child access
- Age-gating based on child's birthday in profile
- Personality filtering for age-appropriate content

---

### 6. Third-Party Services

#### 6.1 AI Providers
Moxie uses third-party AI services (OpenAI, Anthropic, etc.):
- Conversations sent to AI providers for response generation
- Data processing agreements in place (COPPA-compliant)
- No training on your data without consent
- Conversation data not retained by AI providers (per agreements)

#### 6.2 Email Service
We use a transactional email service for:
- Email verification during setup
- Safety alerts to parents
- PIN reset links
- Weekly summaries (if opted in)

Provider: [To be determined]
Privacy Policy: [Link]

#### 6.3 No Other Third Parties
We do not share data with:
- Advertisers
- Data brokers
- Analytics companies (beyond basic crash reporting)
- Social media platforms

---

### 7. Your Rights

#### 7.1 Access
- View all data collected about your child via Parent Console
- Export conversations, logs, and account data

#### 7.2 Correction
- Update child profile information anytime
- Correct inaccurate data in Parent Console

#### 7.3 Deletion
- Delete individual conversations
- Delete account (removes all data within 30 days)
- Request data deletion via email: privacy@moxie.app

#### 7.4 Portability
- Export data in JSON, PDF, or TXT format
- Download via Parent Console or email request

---

### 8. International Users

#### 8.1 GDPR Compliance (EU Users)
For users in the European Union:
- Lawful basis: Parental consent
- Right to be forgotten: Full data deletion within 30 days
- Data portability: Standard export formats
- Supervisory authority: [To be determined based on EU presence]

#### 8.2 Data Transfers
If data leaves your device:
- Transfers use Standard Contractual Clauses (SCCs)
- Encryption in transit and at rest
- Adequacy decisions respected

---

### 9. Changes to This Policy

We will notify you of material changes via:
- Email to parent account
- In-app notification
- Updated "Last Modified" date

Continued use after notification constitutes acceptance. If you disagree, you may delete your account.

---

### 10. Contact Us

**Privacy Questions:**
Email: privacy@moxie.app
Response time: Within 5 business days

**Data Deletion Requests:**
Email: privacy@moxie.app with subject "Data Deletion Request"
Include: Child's name, parent email, reason (optional)

**Mailing Address:**
[Company Name]
[Street Address]
[City, State ZIP]

**Designated COPPA Contact:**
[Name, Title]
Email: coppa@moxie.app

---

### 11. Compliance Certifications

- COPPA Compliant (Children's Online Privacy Protection Act)
- FERPA Compliant (Family Educational Rights and Privacy Act) for school deployments
- GDPR Compliant (General Data Protection Regulation) for EU users
- SOC 2 Type II Certified (if cloud backup enabled)

---

## Edge Cases and Error Handling

### Edge Case 1: PIN Forgotten During Initial Setup

**Scenario:** Parent creates PIN during setup, closes app before completing, reopens app, can't remember PIN.

**Problem:** No email verified yet, no security question set, no way to reset.

**Solution:**
1. Detect incomplete setup state (PIN exists but email unverified)
2. Show special recovery screen:
   ```
   Setup Incomplete

   You started setting up Moxie but didn't finish.
   If you forgot your PIN, you can restart setup.

   ⚠ This will erase your current PIN.

   [Complete Setup]  [Restart Setup]
   ```
3. "Restart Setup" deletes PIN from Keychain and clears setup progress
4. No data loss (child profile not created yet)

**Implementation:**
```swift
struct SetupState: Codable {
    var pinCreated: Bool = false
    var emailVerified: Bool = false
    var securityQuestionSet: Bool = false
    var childProfileCreated: Bool = false

    var isComplete: Bool {
        pinCreated && emailVerified && securityQuestionSet && childProfileCreated
    }

    var isPartial: Bool {
        pinCreated && !isComplete
    }
}
```

---

### Edge Case 2: Time Zone Changes (Travel)

**Scenario:** Family travels from EST to PST. Bedtime is 8 PM EST, but it's now 5 PM PST (8 PM EST). Should Moxie lock?

**Problem:** Child loses 3 hours of access time OR gets extra 3 hours depending on implementation.

**Solution:**
1. **Option A (Conservative):** Use device timezone, auto-adjust schedule
   - 8 PM bedtime becomes "8 PM in current timezone"
   - Child gets same hours of access regardless of travel

2. **Option B (Flexible):** Detect timezone change, ask parent
   ```
   Timezone Changed

   Looks like you're in a different timezone (Pacific Time).

   Current bedtime schedule: 8:00 PM Eastern Time

   Would you like to:
   ○ Keep Eastern Time (locks at 5:00 PM Pacific)
   ○ Update to Pacific Time (locks at 8:00 PM Pacific)
   ○ Temporarily disable bedtime lock (1 week)

   [Save Choice]
   ```

**Recommended:** Option B (ask parent)

**Implementation:**
```swift
struct TimeRestrictionManager {
    func checkTimezoneChange() {
        let currentTZ = TimeZone.current.identifier
        let savedTZ = UserDefaults.standard.string(forKey: "last_timezone")

        if currentTZ != savedTZ {
            // Show timezone change prompt to parent
            notifyTimezoneChange(from: savedTZ, to: currentTZ)
        }
    }
}
```

---

### Edge Case 3: System Clock Manipulation

**Scenario:** Tech-savvy child changes macOS system clock to bypass time restrictions.

**Problem:** Child gains unauthorized access by setting clock to 10 AM when it's actually 9 PM.

**Solution:**
1. **Detection:**
   - Track last known time on app close
   - On app open, check if clock jumped backward > 1 hour (suspicious)
   - Cross-reference with NTP server (network time)

2. **Response:**
   ```
   Time Mismatch Detected

   Your device clock appears to be incorrect.

   For safety, Moxie requires accurate time.
   Please check your system time settings.

   [Check System Time]  [Contact Parent]
   ```

3. **Fallback:**
   - If offline (no NTP), use most restrictive policy (lock)
   - Log event in activity log for parent review
   - Email parent: "Possible time manipulation detected"

**Implementation:**
```swift
struct TimeVerification {
    func verifySystemTime() async -> Bool {
        let systemTime = Date()
        let lastKnownTime = UserDefaults.standard.object(forKey: "last_known_time") as? Date

        // Check for backward jumps > 1 hour
        if let lastTime = lastKnownTime {
            let timeDiff = systemTime.timeIntervalSince(lastTime)
            if timeDiff < -3600 {
                // Suspicious backward jump
                return false
            }
        }

        // Verify with NTP if online
        if let ntpTime = await fetchNTPTime() {
            let drift = abs(systemTime.timeIntervalSince(ntpTime))
            if drift > 300 {  // > 5 minutes off
                return false
            }
        }

        // Update last known time
        UserDefaults.standard.set(systemTime, forKey: "last_known_time")
        return true
    }
}
```

---

### Edge Case 4: Parent Lock-Out (Lost Email Access + Forgot PIN)

**Scenario:** Parent forgot PIN, no longer has access to email (old job email, deleted account, etc.), can't answer security question.

**Problem:** Permanent lock-out from parental controls.

**Solution:**
1. **Ultimate Reset (Nuclear Option):**
   ```
   Can't Access Your Account?

   If you've lost access to your email AND forgotten your PIN
   AND can't answer your security question, you can reset
   everything.

   ⚠ WARNING: This will DELETE ALL DATA including:
   • All conversation logs
   • Child profile
   • Settings and preferences
   • You'll start setup from scratch

   This cannot be undone.

   Type "DELETE ALL DATA" to confirm:
   [_______________________________]

   [Cancel]  [Reset Everything]
   ```

2. **Support Escalation:**
   - Provide support email: support@moxie.app
   - Manual verification process (proof of purchase, identity verification)
   - Support can issue one-time reset code

**Implementation:**
```swift
func ultimateReset() {
    // Show scary confirmation dialog
    showConfirmation(
        title: "Delete All Data?",
        message: "Type DELETE ALL DATA to confirm.",
        destructiveAction: {
            // Delete all app data
            try? PINCredential().deletePIN()
            try? FileManager.default.removeItem(at: AppPaths.applicationSupport)
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)

            // Restart app to setup wizard
            restartToSetup()
        }
    )
}
```

---

### Edge Case 5: Child in Distress During Locked Hours

**Scenario:** Child wakes up at 2 AM having a nightmare, needs Moxie for comfort, but app is locked for bedtime.

**Problem:** Safety feature creates accessibility barrier during genuine need.

**Solution:**
1. **Emergency Override:**
   ```
   Moxie is Sleeping

   I'll wake up at 7:00 AM.

   If you need help right now, I can wake up.

   [I Need Help Now]  [I'm Okay]
   ```

2. **If child clicks "I Need Help Now":**
   ```
   What's Wrong?

   I'm here if you need me. Are you:

   ○ Scared or worried
   ○ Feeling sick
   ○ Having trouble sleeping
   ○ Need to ask a question

   [Continue]
   ```

3. **Limited Emergency Mode:**
   - Moxie unlocks for 15 minutes
   - Conversation flagged as "Emergency Override"
   - Parent receives email immediately:
     ```
     Emma needed Moxie during bedtime (2:14 AM).
     Reason: Scared or worried

     Emergency mode was activated for 15 minutes.

     [View Conversation]
     ```
   - Moxie provides comfort but also suggests: "Would you like me to wake up your parent?"

**Implementation:**
```swift
struct EmergencyOverride {
    func activateEmergency(reason: String) {
        // Log event
        ActivityLog.log(
            type: .emergencyOverride,
            details: ["reason": reason, "time": Date()]
        )

        // Unlock for 15 minutes
        ModeContext.shared.emergencyMode = true
        ModeContext.shared.emergencyExpiresAt = Date().addingTimeInterval(900)

        // Alert parent
        EmailService.send(
            to: ParentAccount.shared.email,
            subject: "Emergency: \(childName) needed Moxie during bedtime",
            body: generateEmergencyEmail(reason: reason)
        )
    }
}
```

---

### Edge Case 6: App Crashes During Adult Mode Session

**Scenario:** Parent reviewing sensitive conversation logs, app crashes, child reopens app.

**Problem:** Does app reopen in Adult Mode (exposing logs) or Child Mode (losing parent's work)?

**Solution:**
1. **Safe Default:** Always reopen in Child Mode
2. **Session Recovery:**
   ```
   Welcome Back!

   [For Emma:]
   Hi Emma! Ready to chat?

   [For Parents:]
   Were you using Parent Console?
   [Enter PIN to Resume]
   ```

3. **Auto-logout on crash:**
   - Detect abnormal termination (crash vs. clean exit)
   - If crash, clear mode context
   - Require PIN re-entry

**Implementation:**
```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check if previous session ended cleanly
        let cleanExit = UserDefaults.standard.bool(forKey: "clean_exit")

        if !cleanExit {
            // Previous session crashed
            ModeContext.shared.currentMode = .child
            ModeContext.shared.sessionStartedAt = Date()
            print("Recovered from crash: Defaulted to Child Mode")
        }

        // Mark this launch as not clean (will be set to true on clean exit)
        UserDefaults.standard.set(false, forKey: "clean_exit")
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Mark clean exit
        UserDefaults.standard.set(true, forKey: "clean_exit")
    }
}
```

---

### Edge Case 7: Multiple Children, One Device

**Scenario:** Family has two children (Emma, 7) and (Noah, 10) sharing one Mac. Both use Moxie.

**Problem:** Mixed conversation logs, inappropriate age filtering, privacy violations.

**Solution:**
1. **Multi-Profile Support:**
   ```
   Who's Using Moxie?

   [Emma, Age 7]    [Noah, Age 10]    [+ Add Child]
   ```

2. **Profile Switching:**
   - Each child gets separate conversation database
   - Age-appropriate personality filtering
   - Individual time restrictions
   - Separate logging preferences per child

3. **Parent View:**
   ```
   Parent Console

   Select child to review:
   ○ Emma (Age 7) - Last active: 3:45 PM
   ○ Noah (Age 10) - Last active: 5:20 PM
   ```

**Implementation:**
```swift
struct ChildProfileManager {
    static var profiles: [ChildProfile] = []
    static var activeProfile: ChildProfile?

    func switchProfile(_ profile: ChildProfile) {
        // Save current session
        saveCurrentSession()

        // Switch active profile
        ChildProfileManager.activeProfile = profile

        // Load profile-specific data
        loadConversations(for: profile.id)
        loadTimeRestrictions(for: profile.id)

        // Update AI context
        ConversationService.updateContext(profile.contextForAI)
    }
}
```

---

### Edge Case 8: Offline Mode (No Internet)

**Scenario:** Family on road trip, no internet, child wants to use Moxie.

**Problem:** AI providers require internet. Time verification requires NTP. Email alerts can't send.

**Solution:**
1. **Offline Mode Detection:**
   ```
   No Internet Connection

   Moxie needs internet to chat.

   While offline, you can:
   • Read saved stories
   • Review past conversations
   • Play offline learning games

   [Browse Offline Content]
   ```

2. **Cached Responses (Limited):**
   - Pre-cache common questions/responses
   - Simple fallback personality (rule-based, not AI)
   - "I can't think of a good answer without internet. Ask me when we're back online!"

3. **Deferred Actions:**
   - Queue email alerts for when online
   - Log activity locally, sync later
   - Time restrictions use last-known-good time

**Implementation:**
```swift
struct OfflineManager {
    func handleOfflineMode() {
        if !NetworkMonitor.isConnected {
            // Disable AI features
            AIService.enabled = false

            // Enable offline content
            OfflineContentView.show()

            // Queue pending actions
            ActionQueue.enqueue(.sendPendingEmails)
            ActionQueue.enqueue(.syncActivityLogs)

            // Show offline banner
            showBanner("Offline Mode: Limited features available")
        }
    }
}
```

---

### Edge Case 9: Inappropriate Personality for Child Age

**Scenario:** Parent creates custom "Roast Mode" personality with edgy humor. Child (age 6) selects it.

**Problem:** Content may be inappropriate for young child.

**Solution:**
1. **Age-Gating Personalities:**
   ```swift
   struct Personality {
       var name: String
       var prompt: String
       var minAge: Int?  // NEW: Minimum age requirement
       var parentApprovalRequired: Bool = false  // NEW
   }

   // Example:
   static let roastMode = Personality(
       name: "Roast Mode",
       prompt: "...",
       minAge: 10,  // Only for ages 10+
       parentApprovalRequired: true
   )
   ```

2. **Child View (Age 6):**
   - Roast Mode appears grayed out
   - Tooltip: "Ask your parent about this personality"

3. **If Child Clicks:**
   ```
   Ask Your Parent

   "Roast Mode" is for older kids.

   Your parent can unlock it if they think it's okay.

   [Okay]
   ```

4. **Parent Approval Flow:**
   ```
   Parent Console > Personality Settings

   Roast Mode (Ages 10+)
   ○ Allow Emma to use (she's 7)
   ○ Keep age-restricted

   Note: This personality uses sarcasm and edgy humor.
   Review the prompt before allowing.
   ```

---

### Edge Case 10: Data Export Requested by School/Court

**Scenario:** School requests all conversation logs for bullying investigation. OR: Court subpoena for divorce/custody case.

**Problem:** Legal/ethical obligation vs. privacy.

**Solution:**
1. **Institutional Deployment (Schools):**
   - Clear data ownership terms in agreement
   - Parent consent for school access during enrollment
   - School admin can access logs for students under their domain
   - Compliance with FERPA

2. **Legal Request (Court):**
   - Require valid subpoena or court order
   - Notify parent immediately
   - Provide data in structured format (JSON + PDF)
   - Include metadata (timestamps, AI analysis, flags)

3. **Parent Control:**
   ```
   Data Request Received

   [School Name] has requested Emma's conversation logs
   for the period Jan 1-7, 2026.

   Reason: Bullying investigation

   You can:
   ○ Approve (release data to school)
   ○ Deny (require legal process)
   ○ Review data first before deciding

   [Review Data]  [Approve]  [Deny]
   ```

**Implementation:**
```swift
struct DataRequest {
    let requestor: String
    let reason: String
    let dateRange: ClosedRange<Date>
    let legalBasis: LegalBasis?

    enum LegalBasis {
        case parentConsent
        case subpoena
        case courtOrder
        case ferpaCompliance
    }

    func requiresParentApproval() -> Bool {
        legalBasis == nil || legalBasis == .parentConsent
    }
}
```

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)

**Goal:** Core data models and security infrastructure

**Deliverables:**
- [ ] `ParentAccount` model with email verification
- [ ] `PINCredential` Keychain integration
- [ ] `ModeContext` state management
- [ ] PIN creation/validation service
- [ ] Email service integration (transactional)

**Testing:**
- Unit tests for PIN strength validation
- Keychain storage/retrieval tests
- Email verification flow tests

---

### Phase 2: Mode Switching (Weeks 3-4)

**Goal:** Adult/Child mode separation with visual indicators

**Deliverables:**
- [ ] Mode switching UI (PIN entry screen)
- [ ] Adult Mode dashboard skeleton
- [ ] Child Mode home screen updates
- [ ] Color scheme transitions
- [ ] Mode badge components

**Testing:**
- UI tests for mode switching
- Session timeout tests
- PIN lockout tests

---

### Phase 3: Conversation Isolation (Weeks 5-6)

**Goal:** Separate conversation contexts for child and adult modes

**Deliverables:**
- [ ] `ConversationLog` model with mode field
- [ ] Separate conversation repositories (`child/`, `adult/`)
- [ ] Context isolation in AI prompts
- [ ] Personality adaptation based on mode
- [ ] Parent view of child conversations

**Testing:**
- Data isolation tests (child can't see adult convos)
- Context switching tests
- AI response quality tests (manual QA)

---

### Phase 4: Activity Logging (Weeks 7-8)

**Goal:** Comprehensive audit trail with privacy controls

**Deliverables:**
- [ ] `ActivityLog` model and repository
- [ ] Event logging service
- [ ] Activity viewer UI (Parent Console)
- [ ] `LoggingPreferences` model
- [ ] Log retention and auto-deletion

**Testing:**
- Log write performance tests
- Retention policy tests
- Privacy level filtering tests

---

### Phase 5: Time Restrictions (Weeks 9-10)

**Goal:** Bedtime locks and time-based access control

**Deliverables:**
- [ ] `AutoLockSchedule` model
- [ ] Time window configuration UI
- [ ] Auto-lock service (background timer)
- [ ] Warning notifications (5 min, 1 min)
- [ ] Time extension request flow

**Testing:**
- Time window calculation tests
- Timezone change handling tests
- Clock manipulation detection tests

---

### Phase 6: Safety Features (Weeks 11-12)

**Goal:** Content flagging and parent alerts

**Deliverables:**
- [ ] `ContentFlag` model
- [ ] AI safety detection service
- [ ] Flag creation and storage
- [ ] Parent email alerts
- [ ] Flag review UI (Parent Console)
- [ ] Safety resource links

**Testing:**
- Flag detection accuracy tests
- Email delivery tests
- Severity classification tests

---

### Phase 7: Parent Console (Weeks 13-14)

**Goal:** Full-featured parent dashboard

**Deliverables:**
- [ ] Dashboard with daily summaries
- [ ] Conversation viewer with drill-down
- [ ] Activity log viewer with filters
- [ ] Settings management UI
- [ ] Data export functionality (PDF, JSON)

**Testing:**
- End-to-end parent workflows
- Export format validation
- Accessibility tests

---

### Phase 8: Setup Wizard (Weeks 15-16)

**Goal:** Smooth onboarding with PIN creation

**Deliverables:**
- [ ] Multi-step setup wizard UI
- [ ] Email verification flow
- [ ] PIN creation with strength indicator
- [ ] Security question setup
- [ ] Child profile creation
- [ ] Time restriction quick setup
- [ ] Logging preference selection

**Testing:**
- Wizard completion tests
- Abandonment/recovery tests
- Email delivery tests

---

### Phase 9: Edge Cases and Polish (Weeks 17-18)

**Goal:** Handle all documented edge cases

**Deliverables:**
- [ ] PIN reset flow (email + security question)
- [ ] Timezone change detection
- [ ] Multi-profile support (multiple children)
- [ ] Offline mode handling
- [ ] Emergency override during locked hours
- [ ] Age-gated personality filtering

**Testing:**
- Edge case coverage tests
- Error message UX review
- Accessibility audit

---

### Phase 10: Documentation and Compliance (Weeks 19-20)

**Goal:** Legal compliance and user documentation

**Deliverables:**
- [ ] Privacy policy finalized
- [ ] COPPA compliance verification
- [ ] FERPA documentation (for schools)
- [ ] Parent user guide
- [ ] School administrator guide
- [ ] Data deletion process
- [ ] Support email setup (privacy@, coppa@, support@)

**Testing:**
- Legal review
- Privacy policy acceptance flow
- Data deletion tests

---

## Success Metrics

### Parental Trust
- **Goal:** 90%+ parent satisfaction with safety features
- **Measure:** Post-setup survey: "Do you feel confident in Moxie's safety?"

### Child Privacy Balance
- **Goal:** 80%+ children report feeling trusted
- **Measure:** Age-appropriate survey: "Do you feel safe talking to Moxie?"

### Safety Effectiveness
- **Goal:** 95%+ of concerning content flagged correctly
- **Measure:** Manual review of flagged vs. missed content

### Usability
- **Goal:** 85%+ parents complete setup without help
- **Measure:** Setup completion rate without support tickets

### Compliance
- **Goal:** 100% compliance with COPPA, FERPA, GDPR
- **Measure:** Third-party audit pass

---

## Conclusion

This safety and trust architecture transforms Moxie from a simple AI companion into a **comprehensive, compliant, and trustworthy platform** for families, schools, and institutions.

**Key Differentiators:**
1. **Transparency without surveillance:** Children know what's logged
2. **Empowerment, not restriction:** Safety feels supportive
3. **Privacy-first:** Local storage, minimal data collection
4. **Flexible controls:** Adapts to family values and child maturity
5. **Regulation-ready:** COPPA, FERPA, GDPR compliant by design

**Next Steps:**
1. Review this specification with legal team
2. Prioritize features based on launch requirements
3. Begin Phase 1 implementation
4. Establish testing protocols
5. Plan beta program with 10-20 families for feedback

**Questions for Stakeholders:**
- Which features are MVP vs. nice-to-have?
- Do we need institutional features (schools) at launch?
- What's the appetite for cloud backup (increases complexity)?
- Should we support multi-child profiles in V1?

---

**Document Owner:** Product Team
**Contributors:** Engineering, Legal, Design, Child Development Advisors
**Review Cycle:** Quarterly or after major regulatory changes
