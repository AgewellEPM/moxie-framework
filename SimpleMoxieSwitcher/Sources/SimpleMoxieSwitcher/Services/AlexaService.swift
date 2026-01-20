import Foundation
import CoreBluetooth

protocol AlexaServiceProtocol {
    func sendVoiceCommand(_ command: String, assistant: VoiceAssistant) async throws
    func turnOnDevice(_ deviceName: String, assistant: VoiceAssistant) async throws
    func turnOffDevice(_ deviceName: String, assistant: VoiceAssistant) async throws
    func setDeviceBrightness(_ deviceName: String, brightness: Int, assistant: VoiceAssistant) async throws
    func setDeviceVolume(_ deviceName: String, volume: Int, assistant: VoiceAssistant) async throws
    func setTemperature(_ deviceName: String, temperature: Int, assistant: VoiceAssistant) async throws
    func scanForBluetoothDevices() async -> [SmartHomeDevice]
}

final class AlexaService: NSObject, AlexaServiceProtocol {
    private let mqttService: MQTTServiceProtocol
    private var centralManager: CBCentralManager?
    private var discoveredDevices: [SmartHomeDevice] = []

    init(mqttService: MQTTServiceProtocol) {
        self.mqttService = mqttService
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func sendVoiceCommand(_ command: String, assistant: VoiceAssistant) async throws {
        let prefix: String
        switch assistant {
        case .alexa:
            prefix = "Alexa"
        case .googleHome:
            prefix = "Hey Google"
        case .both:
            // Send to both
            try await sendVoiceCommand(command, assistant: .alexa)
            try await Task.sleep(nanoseconds: 500_000_000)
            try await sendVoiceCommand(command, assistant: .googleHome)
            return
        case .bluetooth, .none:
            return
        }

        let speech = "\(prefix), \(command)"
        mqttService.sendCommand("speak", speech: speech)

        // Give assistant time to process
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    func turnOnDevice(_ deviceName: String, assistant: VoiceAssistant) async throws {
        try await sendVoiceCommand("turn on \(deviceName)", assistant: assistant)
    }

    func turnOffDevice(_ deviceName: String, assistant: VoiceAssistant) async throws {
        try await sendVoiceCommand("turn off \(deviceName)", assistant: assistant)
    }

    func setDeviceBrightness(_ deviceName: String, brightness: Int, assistant: VoiceAssistant) async throws {
        try await sendVoiceCommand("set \(deviceName) to \(brightness) percent", assistant: assistant)
    }

    func setDeviceVolume(_ deviceName: String, volume: Int, assistant: VoiceAssistant) async throws {
        try await sendVoiceCommand("set \(deviceName) volume to \(volume)", assistant: assistant)
    }

    func setTemperature(_ deviceName: String, temperature: Int, assistant: VoiceAssistant) async throws {
        try await sendVoiceCommand("set \(deviceName) to \(temperature) degrees", assistant: assistant)
    }

    func scanForBluetoothDevices() async -> [SmartHomeDevice] {
        discoveredDevices = []
        centralManager?.scanForPeripherals(withServices: nil, options: nil)

        // Scan for 3 seconds
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        centralManager?.stopScan()

        return discoveredDevices
    }
}

// MARK: - CBCentralManagerDelegate
extension AlexaService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Bluetooth state updated
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? "Unknown Device"
        let signalStrength = min(100, max(0, Int((RSSI.intValue + 100) * 2)))

        let device = SmartHomeDevice(
            name: name,
            type: .bluetooth,
            voiceAssistant: .bluetooth,
            voiceCommandName: "",
            bluetoothID: peripheral.identifier.uuidString,
            isOn: false,
            isConnected: false,
            signalStrength: signalStrength
        )

        // Only add if not already in list
        if !discoveredDevices.contains(where: { $0.bluetoothID == device.bluetoothID }) {
            discoveredDevices.append(device)
        }
    }
}
