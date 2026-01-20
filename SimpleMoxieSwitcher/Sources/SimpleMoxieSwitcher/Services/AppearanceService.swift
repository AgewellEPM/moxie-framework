import Foundation

// MARK: - Appearance Service Protocol
protocol AppearanceServiceProtocol {
    func applyAppearance(_ settings: AppearanceSettings) async
    func getCurrentAppearance() -> AppearanceSettings?
}

// MARK: - Appearance Service Implementation
class AppearanceService: AppearanceServiceProtocol {
    private let mqttService: MQTTServiceProtocol
    private var currentAppearance: AppearanceSettings?

    init(mqttService: MQTTServiceProtocol) {
        self.mqttService = mqttService
    }

    func applyAppearance(_ settings: AppearanceSettings) async {
        do {
            try await submitFaceCustomization(
                eyes: settings.eyes,
                faceColors: settings.faceColors,
                eyeDesigns: settings.eyeDesigns,
                faceDesigns: settings.faceDesigns,
                eyelidDesigns: settings.eyelidDesigns,
                mouth: settings.mouth,
                headHair: settings.headHair,
                facialHair: settings.facialHair,
                brows: settings.brows,
                glasses: settings.glasses,
                nose: settings.nose
            )
            currentAppearance = settings
        } catch {
            print("Error applying appearance: \(error)")
        }
    }

    func getCurrentAppearance() -> AppearanceSettings? {
        return currentAppearance
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
        guard let url = URL(string: AppConfig.faceEditEndpoint) else {
            throw NSError(domain: "MoxieAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

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
        guard let url = URL(string: AppConfig.faceInfoEndpoint) else {
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