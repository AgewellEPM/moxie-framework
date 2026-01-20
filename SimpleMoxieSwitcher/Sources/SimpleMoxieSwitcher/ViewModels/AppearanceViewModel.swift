import SwiftUI
import Combine

@MainActor
class AppearanceViewModel: ObservableObject {
    @Published var isApplying = false
    @Published var statusMessage: String?

    private let appearanceService: AppearanceServiceProtocol
    private let mqttService: MQTTServiceProtocol

    init(appearanceService: AppearanceServiceProtocol, mqttService: MQTTServiceProtocol) {
        self.appearanceService = appearanceService
        self.mqttService = mqttService
    }

    func applyAppearance(
        eyes: String,
        faceColors: String,
        eyeDesigns: String,
        faceDesigns: String,
        eyelidDesigns: String,
        mouth: String,
        headHair: String,
        facialHair: String,
        brows: String,
        glasses: String,
        nose: String
    ) async {
        isApplying = true
        statusMessage = "Applying appearance changes..."

        let appearance = AppearanceSettings(
            eyes: eyes,
            faceColors: faceColors,
            eyeDesigns: eyeDesigns,
            faceDesigns: faceDesigns,
            eyelidDesigns: eyelidDesigns,
            mouth: mouth,
            headHair: headHair,
            facialHair: facialHair,
            brows: brows,
            glasses: glasses,
            nose: nose
        )

        await appearanceService.applyAppearance(appearance)

        isApplying = false
        statusMessage = "Appearance updated successfully!"
    }
}

// MARK: - Appearance Settings Model
struct AppearanceSettings {
    let eyes: String
    let faceColors: String
    let eyeDesigns: String
    let faceDesigns: String
    let eyelidDesigns: String
    let mouth: String
    let headHair: String
    let facialHair: String
    let brows: String
    let glasses: String
    let nose: String
}