import Foundation
import SwiftUI

// MARK: - AI Provider Types
enum AIProvider: String, Codable, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case googleGemini = "Google Gemini"
    case deepseek = "DeepSeek"
    case groq = "Groq"
    case openRouter = "OpenRouter"
    case togetherAI = "Together AI"
    case cloudflareAI = "Cloudflare AI"
    case localOllama = "Local (Ollama)"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .openai: return "bolt.circle.fill"
        case .anthropic: return "brain.head.profile"
        case .googleGemini: return "sparkles"
        case .deepseek: return "scope"
        case .groq: return "hare.fill"
        case .openRouter: return "arrow.triangle.branch"
        case .togetherAI: return "person.3.fill"
        case .cloudflareAI: return "cloud.fill"
        case .localOllama: return "server.rack"
        }
    }

    var color: Color {
        switch self {
        case .openai: return .green
        case .anthropic: return .orange
        case .googleGemini: return .blue
        case .deepseek: return .red
        case .groq: return .cyan
        case .openRouter: return .indigo
        case .togetherAI: return .mint
        case .cloudflareAI: return .orange
        case .localOllama: return .purple
        }
    }

    var defaultBaseURL: String {
        // TODO: Configure your AI provider endpoints
        switch self {
        case .openai: return "YOUR_OPENAI_ENDPOINT"
        case .anthropic: return "YOUR_ANTHROPIC_ENDPOINT"
        case .googleGemini: return "YOUR_GEMINI_ENDPOINT"
        case .deepseek: return "YOUR_DEEPSEEK_ENDPOINT"
        case .groq: return "YOUR_GROQ_ENDPOINT"
        case .openRouter: return "YOUR_OPENROUTER_ENDPOINT"
        case .togetherAI: return "YOUR_TOGETHERAI_ENDPOINT"
        case .cloudflareAI: return "YOUR_CLOUDFLARE_ENDPOINT"
        case .localOllama: return AppConfig.localOllamaURL
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .localOllama: return false
        default: return true
        }
    }

    /// Whether this provider has a free tier
    var hasFreeTier: Bool {
        switch self {
        case .googleGemini, .groq, .openRouter, .togetherAI, .cloudflareAI, .localOllama:
            return true
        case .openai, .anthropic, .deepseek:
            return false
        }
    }

    /// Free tier description for UI
    var freeTierInfo: String? {
        switch self {
        case .googleGemini:
            return "FREE: 1M tokens/min with Gemini Flash"
        case .groq:
            return "FREE: 14,400 req/day, ultra-fast inference"
        case .openRouter:
            return "FREE: 50 req/day on 30+ models"
        case .togetherAI:
            return "FREE: $25 credits on signup"
        case .cloudflareAI:
            return "FREE: 10,000 neurons/day"
        case .localOllama:
            return "FREE: Run models locally"
        default:
            return nil
        }
    }

    /// Whether this provider is recommended for children's content
    var isChildFriendly: Bool {
        switch self {
        case .googleGemini, .groq, .openRouter, .togetherAI:
            return true // These have good content moderation
        default:
            return true // All can work, but some are better
        }
    }

    var defaultModels: [String] {
        // TODO: Configure available models for each provider
        switch self {
        case .openai:
            return ["model-1", "model-2"]
        case .anthropic:
            return ["model-1", "model-2"]
        case .googleGemini:
            return ["model-1", "model-2"]
        case .deepseek:
            return ["model-1", "model-2"]
        case .groq:
            return ["model-1", "model-2"]
        case .openRouter:
            return ["model-1", "model-2"]
        case .togetherAI:
            return ["model-1", "model-2"]
        case .cloudflareAI:
            return ["model-1", "model-2"]
        case .localOllama:
            return ["model-1", "model-2"]
        }
    }

    /// Models recommended for children's content (safer, faster)
    var childFriendlyModels: [String] {
        // TODO: Configure child-friendly models
        return defaultModels
    }

    var signupURL: String {
        switch self {
        case .openai: return "https://platform.openai.com/signup"
        case .anthropic: return "https://console.anthropic.com/"
        case .googleGemini: return "https://aistudio.google.com/app/apikey"
        case .deepseek: return "https://platform.deepseek.com/"
        case .groq: return "https://console.groq.com/"
        case .openRouter: return "https://openrouter.ai/keys"
        case .togetherAI: return "https://api.together.xyz/"
        case .cloudflareAI: return "https://dash.cloudflare.com/"
        case .localOllama: return "https://ollama.ai/"
        }
    }
}

// MARK: - Provider Configuration
struct ProviderConfig: Codable, Identifiable {
    var id = UUID()
    var provider: AIProvider
    var apiKey: String
    var baseURL: String
    var isActive: Bool
    var selectedModel: String
    var lastValidated: Date?
    var validationStatus: ValidationStatus

    enum ValidationStatus: String, Codable {
        case unknown = "Not Tested"
        case valid = "Valid"
        case invalid = "Invalid"
        case testing = "Testing..."
    }

    var statusColor: Color {
        switch validationStatus {
        case .unknown: return .gray
        case .valid: return .green
        case .invalid: return .red
        case .testing: return .orange
        }
    }

    var statusIcon: String {
        switch validationStatus {
        case .unknown: return "questionmark.circle"
        case .valid: return "checkmark.circle.fill"
        case .invalid: return "xmark.circle.fill"
        case .testing: return "clock.fill"
        }
    }
}

// MARK: - AI Provider Manager
@MainActor
class AIProviderManager: ObservableObject {
    @Published var providers: [ProviderConfig] = []
    @Published var activeProvider: AIProvider = .openai
    @Published var isValidating = false
    @Published var errorMessage: String?

    private let storageKey = "moxie_ai_providers"

    init() {
        loadProviders()
    }

    // MARK: - Storage

    func loadProviders() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ProviderConfig].self, from: data) {
            providers = decoded
            // Set the active provider based on saved data
            if let activeConfig = providers.first(where: { $0.isActive }) {
                activeProvider = activeConfig.provider
            }
        } else {
            // Initialize with default providers
            providers = AIProvider.allCases.map { provider in
                ProviderConfig(
                    provider: provider,
                    apiKey: "",
                    baseURL: provider.defaultBaseURL,
                    isActive: provider == .openai,
                    selectedModel: provider.defaultModels.first ?? "",
                    validationStatus: .unknown
                )
            }
        }
    }

    func saveProviders() {
        if let encoded = try? JSONEncoder().encode(providers) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    // MARK: - Provider Management

    func getConfig(for provider: AIProvider) -> ProviderConfig? {
        providers.first { $0.provider == provider }
    }

    func updateProvider(_ config: ProviderConfig) {
        if let index = providers.firstIndex(where: { $0.id == config.id }) {
            providers[index] = config
            // Update activeProvider if this is the active one
            if config.isActive {
                activeProvider = config.provider
            }
            saveProviders()
            objectWillChange.send()
        }
    }

    func setActiveProvider(_ provider: AIProvider) {
        activeProvider = provider
        // Mark as active
        for i in providers.indices {
            providers[i].isActive = (providers[i].provider == provider)
        }
        saveProviders()
        objectWillChange.send()
    }

    func getActiveConfig() -> ProviderConfig? {
        // First try to find the provider marked as active
        if let activeConfig = providers.first(where: { $0.isActive && !$0.apiKey.isEmpty }) {
            return activeConfig
        }
        // Fallback to the selected provider
        return providers.first(where: { $0.provider == activeProvider && !$0.apiKey.isEmpty })
    }

    // MARK: - Model Selection

    func getModelsForProvider(_ provider: AIProvider) -> [String] {
        provider.defaultModels
    }

    func getActiveModels() -> [String] {
        getModelsForProvider(activeProvider)
    }
}
