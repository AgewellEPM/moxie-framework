import SwiftUI

struct SmartHomeView: View {
    @EnvironmentObject var viewModel: SmartHomeViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.opacity(0.80)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                headerView

                if let status = viewModel.statusMessage {
                    statusView(status)
                }

                devicesScrollView

                Spacer()

                closeButton
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 500)
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🏠 Smart Home")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)

                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: {
                    viewModel.scanForBluetoothDevices()
                }) {
                    HStack {
                        if viewModel.isScanning {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        }
                        Text(viewModel.isScanning ? "Scanning..." : "Scan for Bluetooth")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isScanning)

                Spacer()
            }
        }
    }

    private func statusView(_ status: String) -> some View {
        Text(status)
            .foregroundColor(status.contains("✓") ? .green : .red)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
    }

    private var devicesScrollView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 15) {
                ForEach(viewModel.devices) { device in
                    DeviceCardView(device: device, viewModel: viewModel)
                }
            }
        }
    }

    private var closeButton: some View {
        Button("Close") {
            dismiss()
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
    }
}

struct DeviceCardView: View {
    let device: SmartHomeDevice
    @ObservedObject var viewModel: SmartHomeViewModel
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(device.type.icon)
                    .font(.system(size: 40))

                Spacer()

                Toggle("", isOn: Binding(
                    get: { device.isOn },
                    set: { _ in viewModel.toggleDevice(device) }
                ))
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Text(device.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    Text(device.voiceAssistant.icon)
                        .font(.caption)

                    if let signal = device.signalStrength {
                        Text("• \(signal)%")
                            .font(.caption)
                            .foregroundColor(signalColor(signal))
                    }

                    if !device.isConnected && device.type == .bluetooth {
                        Text("• Disconnected")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Additional controls based on device type
            if let brightness = device.brightness, device.type == .light {
                brightnessSlider(brightness)
            }

            if let volume = device.volume, device.type == .tv || device.type == .speaker {
                volumeSlider(volume)
            }

            if let temperature = device.temperature, device.type == .thermostat {
                temperatureSlider(temperature)
            }
        }
        .padding()
        .background(plasticBackground)
        .cornerRadius(18)
        .overlay(glossyOverlay)
        .shadow(color: device.isOn ? .green.opacity(0.6) : .gray.opacity(0.3), radius: isHovered ? 20 : 15, x: 0, y: isHovered ? 12 : 8)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func brightnessSlider(_ brightness: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Brightness: \(brightness)%")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            Slider(
                value: Binding(
                    get: { Double(brightness) },
                    set: { viewModel.setBrightness(device, brightness: Int($0)) }
                ),
                in: 0...100,
                step: 10
            )
            .tint(.yellow)
        }
    }

    private func volumeSlider(_ volume: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Volume: \(volume)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            Slider(
                value: Binding(
                    get: { Double(volume) },
                    set: { viewModel.setVolume(device, volume: Int($0)) }
                ),
                in: 0...100,
                step: 5
            )
            .tint(.blue)
        }
    }

    private func temperatureSlider(_ temperature: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Temperature: \(temperature)°F")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            Slider(
                value: Binding(
                    get: { Double(temperature) },
                    set: { viewModel.setTemperature(device, temperature: Int($0)) }
                ),
                in: 60...85,
                step: 1
            )
            .tint(.orange)
        }
    }

    private var plasticBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.9),
                    Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.6),
                    Color.white.opacity(0.0)
                ]),
                startPoint: .top,
                endPoint: .center
            )
        }
    }

    private var glossyOverlay: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(Color.white.opacity(0.6), lineWidth: 2)
            .blur(radius: 1)
    }

    private func signalColor(_ strength: Int) -> Color {
        switch strength {
        case 75...100:
            return .green
        case 50..<75:
            return .yellow
        default:
            return .red
        }
    }
}
