import Foundation
import Security

// MARK: - PIN Service Protocol
protocol PINServiceProtocol {
    func createPIN(_ pin: String) throws
    func validatePIN(_ pin: String) throws -> Bool
    func deletePIN() throws
    func hasPIN() -> Bool
    func validatePINStrength(_ pin: String) -> PINStrength
}

// MARK: - PIN Service Implementation
class PINService: PINServiceProtocol {

    private let serviceName = "com.moxie.parentpin"
    private let accountName = "parent"

    // MARK: - PIN Creation

    func createPIN(_ pin: String) throws {
        // Validate PIN format
        guard pin.count == 6 else {
            throw PINError.invalidFormat
        }

        guard pin.allSatisfy({ $0.isNumber }) else {
            throw PINError.invalidFormat
        }

        // Check PIN strength
        let strength = validatePINStrength(pin)
        guard strength != .tooWeak else {
            throw PINError.tooWeak
        }

        // Store PIN in Keychain
        let pinData = pin.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: pinData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        // Delete old entry if exists
        SecItemDelete(query as CFDictionary)

        // Add new entry
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw PINError.storeFailed
        }
    }

    // MARK: - PIN Validation

    func validatePIN(_ pin: String) throws -> Bool {
        guard pin.count == 6 else {
            throw PINError.invalidFormat
        }

        let storedPIN = try retrievePIN()
        let isValid = pin == storedPIN

        // Record attempt in ModeContext
        ModeContext.shared.recordPINAttempt(success: isValid)

        return isValid
    }

    // MARK: - PIN Retrieval (Private)

    private func retrievePIN() throws -> String {
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

    // MARK: - PIN Deletion

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

    // MARK: - PIN Existence Check

    func hasPIN() -> Bool {
        do {
            _ = try retrievePIN()
            return true
        } catch {
            return false
        }
    }

    // MARK: - PIN Strength Validation

    func validatePINStrength(_ pin: String) -> PINStrength {
        guard pin.count == 6 else {
            return .invalid
        }

        guard pin.allSatisfy({ $0.isNumber }) else {
            return .invalid
        }

        // Check for weak patterns
        if isSequential(pin) {
            return .tooWeak
        }

        if isRepeating(pin) {
            return .tooWeak
        }

        if isCommonPIN(pin) {
            return .weak
        }

        // If it passes all checks, it's strong
        return .strong
    }

    // MARK: - Private Strength Checks

    private func isSequential(_ pin: String) -> Bool {
        let digits = pin.compactMap { Int(String($0)) }
        guard digits.count == 6 else { return false }

        // Check ascending sequence (123456, 234567, etc.)
        var isAscending = true
        for i in 0..<5 {
            if digits[i+1] != digits[i] + 1 {
                isAscending = false
                break
            }
        }

        // Check descending sequence (654321, 543210, etc.)
        var isDescending = true
        for i in 0..<5 {
            if digits[i+1] != digits[i] - 1 {
                isDescending = false
                break
            }
        }

        return isAscending || isDescending
    }

    private func isRepeating(_ pin: String) -> Bool {
        let firstChar = pin.first
        return pin.allSatisfy { $0 == firstChar }
    }

    private func isCommonPIN(_ pin: String) -> Bool {
        let commonPINs = [
            "123456", "654321", "111111", "000000",
            "121212", "112233", "123123", "696969",
            "101010", "123321", "131313"
        ]
        return commonPINs.contains(pin)
    }
}

// MARK: - PIN Errors
enum PINError: Error, LocalizedError {
    case storeFailed
    case retrieveFailed
    case deleteFailed
    case invalidFormat
    case tooWeak

    var errorDescription: String? {
        switch self {
        case .storeFailed:
            return "Failed to store PIN securely. Please try again."
        case .retrieveFailed:
            return "Failed to retrieve PIN. Please contact support."
        case .deleteFailed:
            return "Failed to delete PIN. Please contact support."
        case .invalidFormat:
            return "PIN must be exactly 6 digits."
        case .tooWeak:
            return "PIN is too weak. Avoid sequences (123456) or repeating digits (111111)."
        }
    }
}

// MARK: - PIN Strength
enum PINStrength {
    case invalid
    case tooWeak
    case weak
    case strong

    var displayName: String {
        switch self {
        case .invalid:
            return "Invalid"
        case .tooWeak:
            return "Too Weak"
        case .weak:
            return "Weak"
        case .strong:
            return "Strong"
        }
    }

    var color: String {
        switch self {
        case .invalid:
            return "#FF0000"  // Red
        case .tooWeak:
            return "#FF6B00"  // Orange
        case .weak:
            return "#FFD700"  // Yellow
        case .strong:
            return "#00FF00"  // Green
        }
    }

    var progress: Double {
        switch self {
        case .invalid:
            return 0.0
        case .tooWeak:
            return 0.33
        case .weak:
            return 0.66
        case .strong:
            return 1.0
        }
    }
}

// MARK: - Mock PIN Service (For Testing)
class MockPINService: PINServiceProtocol {
    var storedPIN: String?
    var shouldFailValidation = false

    func createPIN(_ pin: String) throws {
        guard pin.count == 6, pin.allSatisfy({ $0.isNumber }) else {
            throw PINError.invalidFormat
        }
        storedPIN = pin
    }

    func validatePIN(_ pin: String) throws -> Bool {
        if shouldFailValidation {
            throw PINError.retrieveFailed
        }
        return pin == storedPIN
    }

    func deletePIN() throws {
        storedPIN = nil
    }

    func hasPIN() -> Bool {
        storedPIN != nil
    }

    func validatePINStrength(_ pin: String) -> PINStrength {
        let service = PINService()
        return service.validatePINStrength(pin)
    }
}
