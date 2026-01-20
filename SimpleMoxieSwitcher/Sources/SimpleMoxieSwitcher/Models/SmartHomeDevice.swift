import Foundation

enum DeviceType: String, Codable, CaseIterable {
    case light = "Light"
    case tv = "TV"
    case thermostat = "Thermostat"
    case fan = "Fan"
    case plug = "Smart Plug"
    case lock = "Smart Lock"
    case speaker = "Speaker"
    case bluetooth = "Bluetooth Device"
    case other = "Other"

    var icon: String {
        switch self {
        case .light: return "💡"
        case .tv: return "📺"
        case .thermostat: return "🌡️"
        case .fan: return "💨"
        case .plug: return "🔌"
        case .lock: return "🔒"
        case .speaker: return "🔊"
        case .bluetooth: return "📱"
        case .other: return "🏠"
        }
    }
}

enum VoiceAssistant: String, Codable {
    case alexa = "Alexa"
    case googleHome = "Google Home"
    case both = "Both"
    case bluetooth = "Bluetooth"
    case none = "None"

    var icon: String {
        switch self {
        case .alexa: return "🗣️"
        case .googleHome: return "🏠"
        case .both: return "🗣️🏠"
        case .bluetooth: return "📱"
        case .none: return "⚙️"
        }
    }
}

struct SmartHomeDevice: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: DeviceType
    var voiceAssistant: VoiceAssistant
    var voiceCommandName: String  // The name voice assistants know it by
    var bluetoothID: String?  // Bluetooth device identifier
    var isOn: Bool
    var isConnected: Bool  // For Bluetooth devices
    var brightness: Int?  // 0-100 for dimmable lights
    var temperature: Int?  // For thermostats
    var volume: Int?  // For speakers/TVs
    var signalStrength: Int?  // For Bluetooth devices (0-100)

    init(
        id: UUID = UUID(),
        name: String,
        type: DeviceType,
        voiceAssistant: VoiceAssistant = .alexa,
        voiceCommandName: String,
        bluetoothID: String? = nil,
        isOn: Bool = false,
        isConnected: Bool = true,
        brightness: Int? = nil,
        temperature: Int? = nil,
        volume: Int? = nil,
        signalStrength: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.voiceAssistant = voiceAssistant
        self.voiceCommandName = voiceCommandName
        self.bluetoothID = bluetoothID
        self.isOn = isOn
        self.isConnected = isConnected
        self.brightness = brightness
        self.temperature = temperature
        self.volume = volume
        self.signalStrength = signalStrength
    }
}

// Predefined common devices
extension SmartHomeDevice {
    static let sampleDevices = [
        SmartHomeDevice(name: "Living Room Light", type: .light, voiceAssistant: .alexa, voiceCommandName: "living room light", isOn: false, brightness: 100),
        SmartHomeDevice(name: "Bedroom Light", type: .light, voiceAssistant: .googleHome, voiceCommandName: "bedroom light", isOn: false, brightness: 75),
        SmartHomeDevice(name: "TV", type: .tv, voiceAssistant: .both, voiceCommandName: "TV", isOn: false, volume: 50),
        SmartHomeDevice(name: "Living Room Fan", type: .fan, voiceAssistant: .alexa, voiceCommandName: "living room fan", isOn: false),
        SmartHomeDevice(name: "Thermostat", type: .thermostat, voiceAssistant: .googleHome, voiceCommandName: "thermostat", isOn: true, temperature: 72),
        SmartHomeDevice(name: "Bluetooth Speaker", type: .bluetooth, voiceAssistant: .bluetooth, voiceCommandName: "", bluetoothID: "BT-SPEAKER-001", isOn: false, isConnected: false, volume: 50, signalStrength: 85)
    ]
}
