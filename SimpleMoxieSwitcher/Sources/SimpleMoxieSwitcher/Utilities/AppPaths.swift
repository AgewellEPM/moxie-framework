import Foundation

/// Central utility for managing application file paths
/// Uses Application Support directory following macOS best practices
enum AppPaths {

    // MARK: - Base Directories

    /// Main application support directory
    /// Returns: ~/Library/Application Support/SimpleMoxieSwitcher/
    static var applicationSupport: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportDir = paths[0].appendingPathComponent("SimpleMoxieSwitcher")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)

        return appSupportDir
    }

    // MARK: - Feature-Specific Directories

    /// Conversations directory
    /// Returns: ~/Library/Application Support/SimpleMoxieSwitcher/conversations/
    static var conversations: URL {
        let dir = applicationSupport.appendingPathComponent("conversations")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Stories directory
    /// Returns: ~/Library/Application Support/SimpleMoxieSwitcher/stories/
    static var stories: URL {
        let dir = applicationSupport.appendingPathComponent("stories")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Language learning directory
    /// Returns: ~/Library/Application Support/SimpleMoxieSwitcher/languages/
    static var languages: URL {
        let dir = applicationSupport.appendingPathComponent("languages")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Music/songs directory
    /// Returns: ~/Library/Application Support/SimpleMoxieSwitcher/music/
    static var music: URL {
        let dir = applicationSupport.appendingPathComponent("music")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Learning/educational content directory
    /// Returns: ~/Library/Application Support/SimpleMoxieSwitcher/learning/
    static var learning: URL {
        let dir = applicationSupport.appendingPathComponent("learning")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

/// Central configuration for network endpoints
enum AppConfig {

    // MARK: - OpenMoxie Server Configuration

    /// OpenMoxie server base URL (without trailing slash)
    /// Default: http://localhost:8001
    /// Can be customized via UserDefaults
    static var openMoxieBaseURL: String {
        if let configured = UserDefaults.standard.string(forKey: "openmoxie_base_url"), !configured.isEmpty {
            return configured.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        return "http://localhost:8001"
    }

    /// Set custom OpenMoxie server base URL
    static func setOpenMoxieBaseURL(_ url: String) {
        UserDefaults.standard.set(url.trimmingCharacters(in: CharacterSet(charactersIn: "/")), forKey: "openmoxie_base_url")
    }

    // MARK: - OpenMoxie Endpoint Builders

    /// Status/health check endpoint
    static var statusEndpoint: String {
        "\(openMoxieBaseURL)/hive/endpoint/"
    }

    /// Chat interaction endpoint (POST)
    static var interactEndpoint: String {
        "\(openMoxieBaseURL)/hive/interact_update"
    }

    /// Puppet API endpoint for making Moxie speak
    static func puppetEndpoint(speech: String, mood: String = "happy") -> String {
        let encodedSpeech = speech.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? speech
        return "\(openMoxieBaseURL)/hive/puppet_api/1?speech=\(encodedSpeech)&mood=\(mood)"
    }

    /// Browser chat URL
    static var browserChatURL: String {
        "\(openMoxieBaseURL)/hive/chat/1"
    }

    /// Face editing endpoint (POST)
    static var faceEditEndpoint: String {
        "\(openMoxieBaseURL)/hive/face_edit/1"
    }

    /// Face info endpoint (GET)
    static var faceInfoEndpoint: String {
        "\(openMoxieBaseURL)/hive/face/1"
    }

    /// Setup endpoint
    static var setupEndpoint: String {
        "\(openMoxieBaseURL)/hive/setup"
    }

    /// Puppet mode start endpoint
    static var puppetStartEndpoint: String {
        "\(openMoxieBaseURL)/api/puppet/start"
    }

    /// Puppet mode stop endpoint
    static var puppetStopEndpoint: String {
        "\(openMoxieBaseURL)/api/puppet/stop"
    }

    /// Root health check endpoint
    static var healthEndpoint: String {
        "\(openMoxieBaseURL)/"
    }

    // MARK: - Legacy API Configuration (kept for compatibility)

    /// Moxie brain API base URL
    /// Default: http://localhost:5001
    /// Can be customized via UserDefaults
    static var moxieAPIBaseURL: String {
        UserDefaults.standard.string(forKey: "moxie_api_base_url") ?? "http://localhost:5001"
    }

    /// Set custom Moxie API base URL
    static func setMoxieAPIBaseURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: "moxie_api_base_url")
    }

    // MARK: - MQTT Configuration

    /// MQTT broker host
    /// Default: localhost (assumes local Docker setup)
    /// Can be customized via UserDefaults
    static var mqttHost: String {
        UserDefaults.standard.string(forKey: "mqtt_host") ?? "localhost"
    }

    /// MQTT broker port
    /// Default: 1883
    static var mqttPort: Int {
        UserDefaults.standard.integer(forKey: "mqtt_port") != 0
            ? UserDefaults.standard.integer(forKey: "mqtt_port")
            : 1883
    }

    /// Use TLS for MQTT connection
    /// Default: false
    static var mqttUseTLS: Bool {
        if let value = UserDefaults.standard.object(forKey: "mqtt_tls") as? Bool {
            return value
        }
        return false
    }

    /// Set custom MQTT host
    static func setMQTTHost(_ host: String) {
        UserDefaults.standard.set(host, forKey: "mqtt_host")
    }

    /// Set custom MQTT port
    static func setMQTTPort(_ port: Int) {
        UserDefaults.standard.set(port, forKey: "mqtt_port")
    }

    /// Set MQTT TLS usage
    static func setMQTTUseTLS(_ useTLS: Bool) {
        UserDefaults.standard.set(useTLS, forKey: "mqtt_tls")
    }

    // MARK: - Local Ollama Configuration

    /// Local Ollama server URL (for local AI inference)
    static var localOllamaURL: String {
        UserDefaults.standard.string(forKey: "local_ollama_url") ?? "http://localhost:11434"
    }

    /// Set custom local Ollama URL
    static func setLocalOllamaURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: "local_ollama_url")
    }

    // MARK: - External Tool Paths

    /// Path to mosquitto_sub binary used by the conversation listener
    /// Can be customized via UserDefaults with key `mosquitto_sub_path`.
    /// Falls back to common Homebrew paths or `mosquitto_sub` on PATH.
    static var mosquittoSubPath: String {
        if let configured = UserDefaults.standard.string(forKey: "mosquitto_sub_path"), !configured.isEmpty {
            return configured
        }

        let fm = FileManager.default
        let candidates = [
            "/opt/homebrew/bin/mosquitto_sub",  // Apple Silicon Homebrew
            "/usr/local/bin/mosquitto_sub",     // Intel Homebrew
            "/usr/bin/mosquitto_sub"
        ]
        for path in candidates {
            if fm.fileExists(atPath: path) { return path }
        }
        // Fallback to env lookup at runtime
        return "mosquitto_sub"
    }

    /// Override mosquitto_sub path
    static func setMosquittoSubPath(_ path: String) {
        UserDefaults.standard.set(path, forKey: "mosquitto_sub_path")
    }

    // MARK: - Default Values Reset

    /// Reset all configuration to defaults
    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: "openmoxie_base_url")
        UserDefaults.standard.removeObject(forKey: "moxie_api_base_url")
        UserDefaults.standard.removeObject(forKey: "mqtt_host")
        UserDefaults.standard.removeObject(forKey: "mqtt_port")
        UserDefaults.standard.removeObject(forKey: "mqtt_tls")
        UserDefaults.standard.removeObject(forKey: "mosquitto_sub_path")
        UserDefaults.standard.removeObject(forKey: "local_ollama_url")
    }
}
