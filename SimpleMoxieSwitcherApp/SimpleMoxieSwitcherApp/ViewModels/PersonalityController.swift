//
//  PersonalityController.swift
//  SimpleMoxieSwitcherApp
//
//  Created on 2026-01-06.
//

import SwiftUI
import AppKit

class PersonalityController: ObservableObject {
    @Published var isUpdating = false
    @Published var statusMessage: String?

    func switchPersonality(_ personality: Personality) async {
        isUpdating = true
        statusMessage = "Switching to \(personality.name)..."

        do {
            try await updatePersonality(personality)
            statusMessage = "🔄 Restarting server..."
            try await restartServer()
            statusMessage = "✅ SUCCESS! Moxie is now \(personality.emoji) \(personality.name)!"
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
        }

        isUpdating = false
    }

    private func updatePersonality(_ personality: Personality) async throws {
        let pythonScript = """
        from hive.models import SinglePromptChat
        chat = SinglePromptChat.objects.get(pk=1)
        chat.prompt = '''\(personality.prompt)'''
        chat.opener = '''\(personality.opener)'''
        chat.temperature = \(personality.temperature)
        chat.max_tokens = \(personality.maxTokens)
        chat.save()
        print('Updated!')
        """

        let dockerCommand = "/usr/local/bin/docker exec -w /app/site openmoxie-server python3 manage.py shell -c \"\(pythonScript)\""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", dockerCommand]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(domain: "MoxieAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Docker update failed"])
        }
    }

    private func restartServer() async throws {
        // Restart in background and wait for it to be healthy
        let restartCommand = """
        docker restart openmoxie-server && sleep 5
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", restartCommand]

        try process.run()
        process.waitUntilExit()
    }

    private func awakeMoxie() async throws {
        // Send wake command via MQTT through Docker container
        let mqttCommand = """
        docker exec openmoxie-server mosquitto_pub -h localhost -t moxie/wake -m "wake" -q 1
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", mqttCommand]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(domain: "MoxieAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Wake command failed"])
        }
    }

    func setFace(_ emotion: MoxieEmotion) async {
        isUpdating = true
        statusMessage = "Setting face to \(emotion.emoji) \(emotion.displayName)..."

        do {
            try await sendEmotionCommand(emotion)
            statusMessage = "✅ Face changed to \(emotion.emoji) \(emotion.displayName)!"

            // Clear message after 2 seconds
            try await Task.sleep(nanoseconds: 2_000_000_000)
            statusMessage = nil
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
        }

        isUpdating = false
    }

    private func sendEmotionCommand(_ emotion: MoxieEmotion) async throws {
        // Send emotion command via MQTT through Docker container
        let mqttCommand = """
        docker exec openmoxie-server mosquitto_pub -h localhost -t moxie/wake -m "[emotion:\(emotion.rawValue)]" -q 1
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", mqttCommand]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MoxieAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Emotion command failed: \(output)"])
        }
    }

    func toggleCamera(enabled: Bool) async {
        statusMessage = enabled ? "📷 Turning camera ON..." : "📷 Turning camera OFF..."

        do {
            try await sendMQTTCommand("[camera:\(enabled)]")
            statusMessage = enabled ? "✅ Camera is ON" : "✅ Camera is OFF"
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
        }
    }

    func move(_ direction: MoveDirection) async {
        statusMessage = "Moving \(direction.rawValue)..."

        do {
            try await sendMQTTCommand("[move:\(direction.rawValue)]")
            statusMessage = nil
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
        }
    }

    func lookAt(_ direction: LookDirection) async {
        statusMessage = "Looking \(direction.rawValue)..."

        do {
            try await sendMQTTCommand("[look:\(direction.rawValue)]")
            statusMessage = nil
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
        }
    }

    func setArm(_ side: ArmSide, position: ArmPosition) async {
        statusMessage = "Setting \(side.rawValue) arm \(position.rawValue)..."

        do {
            try await sendMQTTCommand("[arm:\(side.rawValue):\(position.rawValue)]")
            statusMessage = nil
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
        }
    }

    private func sendMQTTCommand(_ message: String) async throws {
        // Use Docker exec to send MQTT command directly through the OpenMoxie container
        // This ensures the command reaches the MQTT broker that Moxie is connected to
        let mqttCommand = """
        docker exec openmoxie-server mosquitto_pub -h localhost -t moxie/wake -m "\(message)" -q 1
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", mqttCommand]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        // Check if command was successful
        guard process.terminationStatus == 0 else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MoxieAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "MQTT command failed: \(output)"])
        }
    }

    // MARK: - Audio Controls
    func setVolume(_ volume: Int) async {
        statusMessage = "Setting volume to \(volume)%..."

        do {
            try await sendMQTTCommand("[volume:\(volume)]")
            statusMessage = "Volume set to \(volume)%"
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    func toggleMute(_ muted: Bool) async {
        statusMessage = muted ? "Muting audio..." : "Unmuting audio..."

        do {
            try await sendMQTTCommand("[mute:\(muted)]")
            statusMessage = muted ? "Audio muted" : "Audio unmuted"
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Appearance Customization
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
        isUpdating = true
        statusMessage = "Applying appearance customization..."

        do {
            try await submitFaceCustomization(
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
            statusMessage = "Appearance updated successfully!"
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }

        isUpdating = false
    }

    private func submitFaceCustomization(
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
    ) async throws {
        // Build form data
        var formData: [String: String] = [:]

        func addAsset(_ value: String, key: String, prefix: String) {
            if value == "Default" {
                formData[key] = "--"
            } else {
                formData[key] = prefix + value
            }
        }

        addAsset(eyes, key: "asset_Eyes", prefix: "MX_010_Eyes_")
        addAsset(faceColors, key: "asset_Face_Colors", prefix: "MX_020_Face_Colors_")
        addAsset(eyeDesigns, key: "asset_Eye_Designs", prefix: "MX_030_Eye_Designs_")
        addAsset(faceDesigns, key: "asset_Face_Designs", prefix: "MX_040_Face_Designs_")
        addAsset(eyelidDesigns, key: "asset_Eyelid_Designs", prefix: "MX_050_Eyelid_Designs_")
        addAsset(mouth, key: "asset_Mouth", prefix: "MX_060_Mouth_")
        addAsset(headHair, key: "asset_Head_Hair", prefix: "MX_080_Head_Hair_")
        addAsset(facialHair, key: "asset_Facial_Hair", prefix: "MX_090_Facial_Hair_")
        addAsset(brows, key: "asset_Brows", prefix: "MX_100_Brows_")
        addAsset(glasses, key: "asset_Glasses", prefix: "MX_120_Glasses_")
        addAsset(nose, key: "asset_Nose", prefix: "MX_130_Nose_")

        // Create URL-encoded form body
        var bodyComponents: [String] = []
        for (key, value) in formData {
            if let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                bodyComponents.append("\(key)=\(encodedValue)")
            }
        }
        let bodyString = bodyComponents.joined(separator: "&")

        // Make HTTP POST request to OpenMoxie
        guard let url = URL(string: "http://localhost:8003/hive/face_edit/1") else {
            throw NSError(domain: "MoxieAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyString.data(using: .utf8)

        // Get CSRF token first
        let csrfToken = try await getCSRFToken()
        let finalBodyString = "csrfmiddlewaretoken=\(csrfToken)&" + bodyString
        request.httpBody = finalBodyString.data(using: .utf8)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "MoxieAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "HTTP request failed"])
        }
    }

    private func getCSRFToken() async throws -> String {
        // Fetch the face customization page to get CSRF token
        guard let url = URL(string: "http://localhost:8003/hive/face/1") else {
            throw NSError(domain: "MoxieAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "MoxieAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse HTML"])
        }

        // Extract CSRF token from HTML
        if let range = html.range(of: "name=\"csrfmiddlewaretoken\" value=\"") {
            let startIndex = range.upperBound
            if let endRange = html[startIndex...].range(of: "\"") {
                let token = String(html[startIndex..<endRange.lowerBound])
                return token
            }
        }

        throw NSError(domain: "MoxieAPI", code: 4, userInfo: [NSLocalizedDescriptionKey: "CSRF token not found"])
    }
}
