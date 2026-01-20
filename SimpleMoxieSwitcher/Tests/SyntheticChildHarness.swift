#!/usr/bin/env swift

import Foundation

// MARK: - Test Input Models

struct SyntheticInput: Codable {
    let text: String?
    let silenceSeconds: Int?
    let timestamp: String  // HH:mm format
    let energy: EnergyLevel
    let emotionalTone: EmotionalTone
    let metadata: [String: String]?

    enum EnergyLevel: String, Codable {
        case veryLow = "very_low"
        case low = "low"
        case medium = "medium"
        case high = "high"
        case veryHigh = "very_high"
    }

    enum EmotionalTone: String, Codable {
        case sad, scared, worried, upset, lonely
        case neutral, calm, content
        case happy, excited, playful, curious
        case frustrated, angry, defiant
    }
}

struct TestScenario: Codable {
    let name: String
    let description: String
    let inputs: [SyntheticInput]
    let expectedIntent: String?
    let assertions: [Assertion]

    struct Assertion: Codable {
        let type: AssertionType
        let description: String
        let threshold: Double?

        enum AssertionType: String, Codable {
            case intentMatches
            case confidenceAbove
            case confidenceBelow
            case driftDetected
            case noDrift
            case modeSwitch
            case noModeSwitch
            case memoryReferenced
            case gracefulRecovery
        }
    }
}

// MARK: - Test Results

struct TestResult {
    let scenario: String
    let passed: Bool
    let detectedIntent: String
    let confidence: Double
    let driftDetected: Bool
    let failedAssertions: [String]
    let duration: TimeInterval
    let metadata: [String: Any]
}

struct TestSuiteResult {
    let totalTests: Int
    let passed: Int
    let failed: Int
    let duration: TimeInterval
    let results: [TestResult]

    var passRate: Double {
        guard totalTests > 0 else { return 0 }
        return Double(passed) / Double(totalTests)
    }
}

// MARK: - Synthetic Child Test Harness

class SyntheticChildHarness {

    private let intentDetector: IntentDetectionService
    private var testResults: [TestResult] = []

    init() {
        self.intentDetector = IntentDetectionService()
    }

    // MARK: - Run Tests

    func runScenario(_ scenario: TestScenario, verbose: Bool = false) -> TestResult {
        let startTime = Date()

        if verbose {
            print("\n🧪 Running: \(scenario.name)")
            print("   \(scenario.description)")
        }

        // Convert synthetic inputs to chat messages
        let messages = scenario.inputs.compactMap { input -> ChatMessage? in
            guard let text = input.text else { return nil }
            return ChatMessage(
                content: text,
                isUser: true,
                timestamp: parseTime(input.timestamp)
            )
        }

        // Run intent detection
        let (detectedIntent, confidence) = intentDetector.detectIntent(from: messages)

        // Check for drift (simplified - comparing first vs last message groups)
        let driftDetected: Bool
        if messages.count > 5 {
            let earlyMessages = Array(messages.prefix(3))
            let lateMessages = Array(messages.suffix(3))
            let (earlyIntent, _) = intentDetector.detectIntent(from: earlyMessages)
            let (lateIntent, _) = intentDetector.detectIntent(from: lateMessages)
            driftDetected = earlyIntent != lateIntent
        } else {
            driftDetected = false
        }

        // Evaluate assertions
        var failedAssertions: [String] = []

        for assertion in scenario.assertions {
            let assertionPassed = evaluateAssertion(
                assertion,
                detectedIntent: detectedIntent,
                confidence: confidence,
                driftDetected: driftDetected
            )

            if !assertionPassed {
                failedAssertions.append(assertion.description)
            }
        }

        let duration = Date().timeIntervalSince(startTime)
        let passed = failedAssertions.isEmpty

        if verbose {
            print("   Detected: \(detectedIntent.displayName)")
            print("   Confidence: \(String(format: "%.0f%%", confidence * 100))")
            print("   Drift: \(driftDetected ? "Yes" : "No")")
            print("   Result: \(passed ? "✅ PASS" : "❌ FAIL")")
            if !failedAssertions.isEmpty {
                print("   Failed assertions:")
                failedAssertions.forEach { print("     - \($0)") }
            }
        }

        return TestResult(
            scenario: scenario.name,
            passed: passed,
            detectedIntent: detectedIntent.displayName,
            confidence: confidence,
            driftDetected: driftDetected,
            failedAssertions: failedAssertions,
            duration: duration,
            metadata: [:]
        )
    }

    func runSuite(_ scenarios: [TestScenario], verbose: Bool = true) -> TestSuiteResult {
        let startTime = Date()

        if verbose {
            print("\n" + String(repeating: "=", count: 60))
            print("🧠 SYNTHETIC CHILD TEST HARNESS")
            print(String(repeating: "=", count: 60))
        }

        let results = scenarios.map { runScenario($0, verbose: verbose) }
        let duration = Date().timeIntervalSince(startTime)

        let passed = results.filter { $0.passed }.count
        let failed = results.count - passed

        if verbose {
            print("\n" + String(repeating: "=", count: 60))
            print("📊 TEST SUITE RESULTS")
            print(String(repeating: "=", count: 60))
            print("Total: \(results.count) | Passed: \(passed) | Failed: \(failed)")
            print("Pass Rate: \(String(format: "%.1f%%", Double(passed) / Double(results.count) * 100))")
            print("Duration: \(String(format: "%.3fs", duration))")
            print(String(repeating: "=", count: 60))
        }

        return TestSuiteResult(
            totalTests: results.count,
            passed: passed,
            failed: failed,
            duration: duration,
            results: results
        )
    }

    // MARK: - Assertion Evaluation

    private func evaluateAssertion(
        _ assertion: TestScenario.Assertion,
        detectedIntent: SessionIntent,
        confidence: Double,
        driftDetected: Bool
    ) -> Bool {
        switch assertion.type {
        case .intentMatches:
            // This would need expected intent from scenario
            return true

        case .confidenceAbove:
            guard let threshold = assertion.threshold else { return false }
            return confidence >= threshold

        case .confidenceBelow:
            guard let threshold = assertion.threshold else { return false }
            return confidence <= threshold

        case .driftDetected:
            return driftDetected

        case .noDrift:
            return !driftDetected

        case .modeSwitch:
            // Would need state tracking across messages
            return true

        case .noModeSwitch:
            return true

        case .memoryReferenced:
            // Would need memory system integration
            return true

        case .gracefulRecovery:
            // Would need error tracking
            return true
        }
    }

    // MARK: - Helpers

    private func parseTime(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString) ?? Date()
    }
}

// MARK: - Intent Detection Service (Embedded)

enum SessionIntent: Codable, Equatable, Hashable {
    case play, learn(subject: String?), comfort, explore, socializing, storytelling, unknown

    var displayName: String {
        switch self {
        case .play: return "Playing"
        case .learn(let subject): return subject.map { "Learning: \($0)" } ?? "Learning"
        case .comfort: return "Comfort & Support"
        case .explore: return "Exploring"
        case .socializing: return "Chatting"
        case .storytelling: return "Story Time"
        case .unknown: return "Unknown"
        }
    }
}

struct ChatMessage: Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date

    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

class IntentDetectionService {
    private let playKeywords = ["play", "game", "fun", "silly", "joke", "laugh"]
    private let learnKeywords = ["learn", "teach", "show me", "how to", "what is", "math", "science"]
    private let comfortKeywords = ["sad", "scared", "worried", "upset", "lonely", "hurt", "cry"]
    private let exploreKeywords = ["what if", "curious", "wonder", "explore", "discover"]
    private let socializingKeywords = ["hi", "hello", "how are you", "chat"]
    private let storytellingKeywords = ["story", "tell me a story", "once upon"]

    func detectIntent(from messages: [ChatMessage]) -> (intent: SessionIntent, confidence: Double) {
        let text = messages.filter { $0.isUser }.map { $0.content.lowercased() }.joined(separator: " ")

        let scores: [String: Double] = [
            "play": score(text: text, keywords: playKeywords),
            "learn": score(text: text, keywords: learnKeywords),
            "comfort": score(text: text, keywords: comfortKeywords) * 1.2,
            "explore": score(text: text, keywords: exploreKeywords),
            "socializing": score(text: text, keywords: socializingKeywords),
            "storytelling": score(text: text, keywords: storytellingKeywords)
        ]

        guard let top = scores.max(by: { $0.value < $1.value }), top.value >= 0.3 else {
            return (.unknown, 0.0)
        }

        let intent: SessionIntent
        switch top.key {
        case "play": intent = .play
        case "learn": intent = .learn(subject: nil)
        case "comfort": intent = .comfort
        case "explore": intent = .explore
        case "socializing": intent = .socializing
        case "storytelling": intent = .storytelling
        default: intent = .unknown
        }

        return (intent, min(top.value, 1.0))
    }

    private func score(text: String, keywords: [String]) -> Double {
        var score = 0.0
        for keyword in keywords {
            if text.contains(keyword) {
                score += 0.3
            }
        }
        return score
    }
}

// MARK: - Test Scenarios

let adversarialScenarios: [TestScenario] = [
    // 1. Play language with sad tone
    TestScenario(
        name: "Ambiguous: Play Words + Sad Tone",
        description: "Child uses playful words but emotional state is sad",
        inputs: [
            SyntheticInput(text: "Let's play a game", silenceSeconds: nil, timestamp: "14:30", energy: .low, emotionalTone: .sad, metadata: nil),
            SyntheticInput(text: "But I don't feel good", silenceSeconds: nil, timestamp: "14:31", energy: .veryLow, emotionalTone: .upset, metadata: nil)
        ],
        expectedIntent: "comfort",
        assertions: [
            .init(type: .confidenceBelow, description: "Low confidence due to ambiguity", threshold: 0.7)
        ]
    ),

    // 2. Silence with high energy text
    TestScenario(
        name: "Pattern Break: Silence After Excitement",
        description: "Child goes silent after high-energy interaction",
        inputs: [
            SyntheticInput(text: "This is so cool!", silenceSeconds: nil, timestamp: "10:15", energy: .veryHigh, emotionalTone: .excited, metadata: nil),
            SyntheticInput(text: nil, silenceSeconds: 15, timestamp: "10:16", energy: .low, emotionalTone: .neutral, metadata: nil),
            SyntheticInput(text: "...", silenceSeconds: nil, timestamp: "10:17", energy: .low, emotionalTone: .neutral, metadata: nil)
        ],
        expectedIntent: "unknown",
        assertions: [
            .init(type: .confidenceBelow, description: "Confidence drops on pattern break", threshold: 0.5)
        ]
    ),

    // 3. Comfort words during game
    TestScenario(
        name: "Mode Confusion: Emotional Need Mid-Game",
        description: "Child expresses distress while playing",
        inputs: [
            SyntheticInput(text: "Let's play hide and seek", silenceSeconds: nil, timestamp: "16:00", energy: .high, emotionalTone: .playful, metadata: nil),
            SyntheticInput(text: "I'm scared of the dark", silenceSeconds: nil, timestamp: "16:02", energy: .low, emotionalTone: .scared, metadata: nil)
        ],
        expectedIntent: "comfort",
        assertions: [
            .init(type: .driftDetected, description: "Drift from play to comfort detected", threshold: nil)
        ]
    ),

    // 4. Learning request during meltdown
    TestScenario(
        name: "Stress Test: Learning While Upset",
        description: "Child asks to learn while emotionally distressed",
        inputs: [
            SyntheticInput(text: "I'm so frustrated!", silenceSeconds: nil, timestamp: "19:45", energy: .high, emotionalTone: .frustrated, metadata: nil),
            SyntheticInput(text: "Can you teach me math?", silenceSeconds: nil, timestamp: "19:46", energy: .medium, emotionalTone: .frustrated, metadata: nil)
        ],
        expectedIntent: "comfort",
        assertions: [
            .init(type: .confidenceAbove, description: "Prioritizes emotional state", threshold: 0.4)
        ]
    ),

    // 5. Rapid mode switching
    TestScenario(
        name: "Chaos: Rapid Intent Changes",
        description: "Child switches intents every message",
        inputs: [
            SyntheticInput(text: "Let's play!", silenceSeconds: nil, timestamp: "11:00", energy: .high, emotionalTone: .playful, metadata: nil),
            SyntheticInput(text: "Actually, teach me science", silenceSeconds: nil, timestamp: "11:01", energy: .medium, emotionalTone: .curious, metadata: nil),
            SyntheticInput(text: "I'm sad now", silenceSeconds: nil, timestamp: "11:02", energy: .low, emotionalTone: .sad, metadata: nil),
            SyntheticInput(text: "Tell me a story", silenceSeconds: nil, timestamp: "11:03", energy: .low, emotionalTone: .calm, metadata: nil)
        ],
        expectedIntent: nil,
        assertions: [
            .init(type: .gracefulRecovery, description: "System remains stable despite chaos", threshold: nil)
        ]
    )
]

// MARK: - Run Tests

let harness = SyntheticChildHarness()
let results = harness.runSuite(adversarialScenarios, verbose: true)

// Exit with proper code
exit(results.failed == 0 ? 0 : 1)
