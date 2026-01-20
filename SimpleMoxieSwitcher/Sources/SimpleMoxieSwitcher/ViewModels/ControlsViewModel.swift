import Foundation
import SwiftUI

@MainActor
final class ControlsViewModel: ObservableObject {
    @Published var cameraEnabled = false
    @Published var volume: Double = 50
    @Published var isMuted = false
    @Published var statusMessage: String?
    @Published var isLoading = false

    private let mqttService: MQTTServiceProtocol

    init(mqttService: MQTTServiceProtocol) {
        self.mqttService = mqttService
    }

    // MARK: - Audio Controls
    func setVolume(_ newVolume: Int) async {
        statusMessage = "Setting volume to \(newVolume)%..."
        sendMQTTCommand("[volume:\(newVolume)]")
        statusMessage = "Volume set to \(newVolume)%"

        await clearStatusMessage()
    }

    func toggleMute(_ muted: Bool) async {
        statusMessage = muted ? "Muting audio..." : "Unmuting audio..."
        sendMQTTCommand("[mute:\(muted)]")
        statusMessage = muted ? "Audio muted" : "Audio unmuted"

        await clearStatusMessage()
    }

    // MARK: - Camera Controls
    func toggleCamera(enabled: Bool) async {
        statusMessage = enabled ? "📷 Turning camera ON..." : "📷 Turning camera OFF..."
        sendMQTTCommand("[camera:\(enabled)]")
        statusMessage = enabled ? "✅ Camera is ON" : "✅ Camera is OFF"

        await clearStatusMessage()
    }

    // MARK: - Movement Controls
    func move(_ direction: MoveDirection) async {
        statusMessage = "Moving \(direction.rawValue)..."
        sendMQTTCommand("[move:\(direction.rawValue)]")
        statusMessage = nil
    }

    func lookAt(_ direction: LookDirection) async {
        statusMessage = "Looking \(direction.rawValue)..."
        sendMQTTCommand("[look:\(direction.rawValue)]")
        statusMessage = nil
    }

    func setArm(_ side: ArmSide, position: ArmPosition) async {
        statusMessage = "Setting \(side.rawValue) arm \(position.rawValue)..."
        sendMQTTCommand("[arm:\(side.rawValue):\(position.rawValue)]")
        statusMessage = nil
    }

    // MARK: - Face Emotions
    func setFace(_ emotion: MoxieEmotion) async {
        isLoading = true
        statusMessage = "Setting face to \(emotion.emoji) \(emotion.displayName)..."

        sendMQTTCommand("[emotion:\(emotion.rawValue)]")
        statusMessage = "✅ Face changed to \(emotion.emoji) \(emotion.displayName)!"

        await clearStatusMessage()
        isLoading = false
    }

    // MARK: - Private Methods
    private func sendMQTTCommand(_ message: String) {
        mqttService.sendCommand("control", speech: message)
    }

    private func clearStatusMessage() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        statusMessage = nil
    }
}