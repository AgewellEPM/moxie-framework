import Foundation
import SwiftUI

@MainActor
final class SmartHomeViewModel: ObservableObject {
    @Published var devices: [SmartHomeDevice] = []
    @Published var isLoading = false
    @Published var isScanning = false
    @Published var statusMessage: String?
    @Published var showAddDevice = false

    private let alexaService: AlexaServiceProtocol
    private let userDefaults = UserDefaults.standard
    private let devicesKey = "smart_home_devices"

    init(alexaService: AlexaServiceProtocol) {
        self.alexaService = alexaService
        loadDevices()
    }

    func scanForBluetoothDevices() {
        isScanning = true
        statusMessage = "🔍 Scanning for Bluetooth devices..."

        Task {
            do {
                let discoveredDevices = await alexaService.scanForBluetoothDevices()

                // Add new devices that aren't already in the list
                for device in discoveredDevices {
                    if !devices.contains(where: { $0.bluetoothID == device.bluetoothID }) {
                        devices.append(device)
                    }
                }

                saveDevices()
                statusMessage = "✓ Found \(discoveredDevices.count) Bluetooth device(s)"

                try await Task.sleep(nanoseconds: 3_000_000_000)
                statusMessage = nil
            } catch {
                statusMessage = "✗ Failed to scan for Bluetooth devices"
                print("Bluetooth scan error: \(error)")
            }
            isScanning = false
        }
    }

    func loadDevices() {
        if let data = userDefaults.data(forKey: devicesKey),
           let decoded = try? JSONDecoder().decode([SmartHomeDevice].self, from: data) {
            devices = decoded
        } else {
            // Load sample devices if no saved devices
            devices = SmartHomeDevice.sampleDevices
            saveDevices()
        }
    }

    func saveDevices() {
        if let encoded = try? JSONEncoder().encode(devices) {
            userDefaults.set(encoded, forKey: devicesKey)
        }
    }

    func toggleDevice(_ device: SmartHomeDevice) {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }

        isLoading = true
        Task {
            do {
                if devices[index].isOn {
                    try await alexaService.turnOffDevice(device.voiceCommandName, assistant: device.voiceAssistant)
                    devices[index].isOn = false
                    statusMessage = "✓ Turned off \(device.name)"
                } else {
                    try await alexaService.turnOnDevice(device.voiceCommandName, assistant: device.voiceAssistant)
                    devices[index].isOn = true
                    statusMessage = "✓ Turned on \(device.name)"
                }
                saveDevices()

                // Clear status after 3 seconds
                try await Task.sleep(nanoseconds: 3_000_000_000)
                statusMessage = nil
            } catch {
                statusMessage = "✗ Failed to control \(device.name)"
                print("Error toggling device: \(error)")
            }
            isLoading = false
        }
    }

    func setBrightness(_ device: SmartHomeDevice, brightness: Int) {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }

        Task {
            do {
                try await alexaService.setDeviceBrightness(device.voiceCommandName, brightness: brightness, assistant: device.voiceAssistant)
                devices[index].brightness = brightness
                saveDevices()
                statusMessage = "✓ Set \(device.name) brightness to \(brightness)%"

                try await Task.sleep(nanoseconds: 2_000_000_000)
                statusMessage = nil
            } catch {
                statusMessage = "✗ Failed to set brightness"
                print("Error setting brightness: \(error)")
            }
        }
    }

    func setVolume(_ device: SmartHomeDevice, volume: Int) {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }

        Task {
            do {
                try await alexaService.setDeviceVolume(device.voiceCommandName, volume: volume, assistant: device.voiceAssistant)
                devices[index].volume = volume
                saveDevices()
                statusMessage = "✓ Set \(device.name) volume to \(volume)"

                try await Task.sleep(nanoseconds: 2_000_000_000)
                statusMessage = nil
            } catch {
                statusMessage = "✗ Failed to set volume"
                print("Error setting volume: \(error)")
            }
        }
    }

    func setTemperature(_ device: SmartHomeDevice, temperature: Int) {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }

        Task {
            do {
                try await alexaService.setTemperature(device.voiceCommandName, temperature: temperature, assistant: device.voiceAssistant)
                devices[index].temperature = temperature
                saveDevices()
                statusMessage = "✓ Set \(device.name) to \(temperature)°"

                try await Task.sleep(nanoseconds: 2_000_000_000)
                statusMessage = nil
            } catch {
                statusMessage = "✗ Failed to set temperature"
                print("Error setting temperature: \(error)")
            }
        }
    }

    func addDevice(_ device: SmartHomeDevice) {
        devices.append(device)
        saveDevices()
    }

    func deleteDevice(_ device: SmartHomeDevice) {
        devices.removeAll { $0.id == device.id }
        saveDevices()
    }

    func sendCustomCommand(_ command: String, assistant: VoiceAssistant = .alexa) {
        isLoading = true
        Task {
            do {
                try await alexaService.sendVoiceCommand(command, assistant: assistant)
                statusMessage = "✓ Sent command: \(command)"

                try await Task.sleep(nanoseconds: 2_000_000_000)
                statusMessage = nil
            } catch {
                statusMessage = "✗ Failed to send command"
                print("Error sending command: \(error)")
            }
            isLoading = false
        }
    }
}
