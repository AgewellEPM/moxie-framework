import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var isResetting = false

    private let personalityService: PersonalityServiceProtocol
    private let personalityRepository: PersonalityRepositoryProtocol

    init(personalityService: PersonalityServiceProtocol, personalityRepository: PersonalityRepositoryProtocol) {
        self.personalityService = personalityService
        self.personalityRepository = personalityRepository
    }

    func resetPersonalities() async {
        isResetting = true
        personalityRepository.resetToDefaults()
        isResetting = false
    }
}