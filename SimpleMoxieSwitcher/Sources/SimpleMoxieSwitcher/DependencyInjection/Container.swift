import Foundation
import SwiftUI

/// Dependency Injection Container using Service Locator pattern
final class DIContainer {
    @MainActor
    static let shared = DIContainer()

    private var services: [String: Any] = [:]

    @MainActor
    private init() {
        registerServices()
    }

    /// Register all services and dependencies
    @MainActor
    private func registerServices() {
        // Register Services
        register(MQTTServiceProtocol.self) { MQTTService() }
        register(DockerServiceProtocol.self) { DockerService() }
        register(PersonalityServiceProtocol.self) {
            PersonalityService(
                dockerService: self.resolve(DockerServiceProtocol.self),
                mqttService: self.resolve(MQTTServiceProtocol.self)
            )
        }
        register(ConversationServiceProtocol.self) {
            ConversationService()
        }
        register(AppearanceServiceProtocol.self) {
            AppearanceService(mqttService: self.resolve(MQTTServiceProtocol.self))
        }
        register(AlexaServiceProtocol.self) {
            AlexaService(mqttService: self.resolve(MQTTServiceProtocol.self))
        }
        register(IntentDetectionServiceProtocol.self) {
            IntentDetectionService()
        }

        // Register Child Profile Service as singleton
        let childProfileService = ChildProfileService(
            dockerService: self.resolve(DockerServiceProtocol.self)
        )
        registerSingleton(ChildProfileService.self, instance: childProfileService)

        // Register Conversation Listener as singleton
        let conversationListener = ConversationListenerService()
        registerSingleton(ConversationListenerService.self, instance: conversationListener)

        // Register Memory Services
        register(MemoryExtractionService.self) {
            MemoryExtractionService()
        }
        register(MemoryStorageService.self) {
            MemoryStorageService(dockerService: self.resolve(DockerServiceProtocol.self))
        }

        // Register Repositories
        register(PersonalityRepositoryProtocol.self) { PersonalityRepository() }
        register(ConversationRepositoryProtocol.self) {
            ConversationRepository()
        }
        register(TileRepositoryProtocol.self) { TileRepository() }

        // Register ViewModels
        register(ContentViewModel.self) {
            ContentViewModel(
                personalityService: self.resolve(PersonalityServiceProtocol.self),
                personalityRepository: self.resolve(PersonalityRepositoryProtocol.self),
                tileRepository: self.resolve(TileRepositoryProtocol.self)
            )
        }

        register(PersonalityViewModel.self) {
            PersonalityViewModel(
                personalityService: self.resolve(PersonalityServiceProtocol.self),
                personalityRepository: self.resolve(PersonalityRepositoryProtocol.self)
            )
        }

        register(ControlsViewModel.self) {
            ControlsViewModel(mqttService: self.resolve(MQTTServiceProtocol.self))
        }

        register(ConversationViewModel.self) {
            ConversationViewModel(
                conversationService: self.resolve(ConversationServiceProtocol.self),
                conversationRepository: self.resolve(ConversationRepositoryProtocol.self),
                intentDetectionService: self.resolve(IntentDetectionServiceProtocol.self)
            )
        }

        register(AppearanceViewModel.self) {
            AppearanceViewModel(
                appearanceService: self.resolve(AppearanceServiceProtocol.self),
                mqttService: self.resolve(MQTTServiceProtocol.self)
            )
        }

        register(SettingsViewModel.self) {
            SettingsViewModel(
                personalityService: self.resolve(PersonalityServiceProtocol.self),
                personalityRepository: self.resolve(PersonalityRepositoryProtocol.self)
            )
        }

        register(SmartHomeViewModel.self) {
            SmartHomeViewModel(alexaService: self.resolve(AlexaServiceProtocol.self))
        }
    }

    /// Register a service factory
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        services[key] = factory
    }

    /// Register a singleton instance
    func registerSingleton<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        services[key] = instance
    }

    /// Resolve a service
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)

        if let factory = services[key] as? () -> T {
            return factory()
        } else if let instance = services[key] as? T {
            return instance
        }

        fatalError("Service of type \(type) is not registered")
    }
}

/// Property wrapper for dependency injection
@MainActor
@propertyWrapper
struct Injected<T> {
    private var service: T

    init() {
        self.service = DIContainer.shared.resolve(T.self)
    }

    var wrappedValue: T {
        get { service }
        mutating set { service = newValue }
    }
}

/// Environment key for dependency injection in SwiftUI
struct DIContainerKey: EnvironmentKey {
    @MainActor static let defaultValue: DIContainer = .shared
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}