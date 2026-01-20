import Foundation

/// Manages the global language preference from Language Lab
/// All Moxie personalities will speak in this language
class LanguagePreferenceManager {
    static let shared = LanguagePreferenceManager()

    private let defaults = UserDefaults.standard
    private let languageCodeKey = "MoxieLanguageCode"
    private let languageNameKey = "MoxieLanguageName"

    private init() {}

    /// Get the current Moxie language preference
    var currentLanguage: (code: String, name: String) {
        let code = defaults.string(forKey: languageCodeKey) ?? "en"
        let name = defaults.string(forKey: languageNameKey) ?? "English"
        return (code, name)
    }

    /// Set the Moxie language preference
    func setLanguage(code: String, name: String) {
        defaults.set(code, forKey: languageCodeKey)
        defaults.set(name, forKey: languageNameKey)
        defaults.synchronize()

        // Post notification so views can update
        NotificationCenter.default.post(name: .moxieLanguageChanged, object: nil)
    }

    /// Check if a language preference has been set
    var hasLanguagePreference: Bool {
        return defaults.string(forKey: languageCodeKey) != nil
    }
}

// Notification name for language changes
extension Notification.Name {
    static let moxieLanguageChanged = Notification.Name("MoxieLanguageChanged")
}
