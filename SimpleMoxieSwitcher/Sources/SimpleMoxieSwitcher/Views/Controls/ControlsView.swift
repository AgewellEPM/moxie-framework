import SwiftUI

struct ControlsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ControlsViewModel
    @State private var showCameraViewer = false

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(spacing: 25) {
                    audioSection
                    Divider()
                    cameraSection
                    Divider()
                    movementSection
                    Divider()
                    headSection
                    Divider()
                    armsSection
                }
                .padding(20)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .sheet(isPresented: $showCameraViewer) {
            CameraViewerView()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("🎮 Moxie Controls")
                .font(.title2)
                .bold()
            Spacer()
            Button("Done") {
                dismiss()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }

    // MARK: - Audio Section
    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔊 AUDIO & SOUND")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 15) {
                VolumeSlider(
                    volume: $viewModel.volume,
                    isMuted: viewModel.isMuted,
                    onVolumeChange: { newVolume in
                        Task {
                            await viewModel.setVolume(Int(newVolume))
                        }
                    }
                )

                HStack(spacing: 15) {
                    MuteButton(isMuted: $viewModel.isMuted) {
                        Task {
                            await viewModel.toggleMute(viewModel.isMuted)
                        }
                    }

                    ResetVolumeButton {
                        viewModel.volume = 50
                        Task {
                            await viewModel.setVolume(50)
                        }
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(10)
        }
    }

    // MARK: - Camera Section
    private var cameraSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📷 CAMERA")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 10) {
                Toggle(isOn: $viewModel.cameraEnabled) {
                    Text(viewModel.cameraEnabled ? "Camera ON" : "Camera OFF")
                        .font(.title3)
                        .bold()
                }
                .onChange(of: viewModel.cameraEnabled) { newValue in
                    Task {
                        await viewModel.toggleCamera(enabled: newValue)
                    }
                }
                .tint(.green)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                if viewModel.cameraEnabled {
                    ViewCameraButton {
                        showCameraViewer = true
                    }
                }
            }
        }
    }

    // MARK: - Movement Section
    private var movementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🚗 MOVEMENT")
                .font(.headline)
                .foregroundColor(.secondary)

            MovementControls { direction in
                Task {
                    await viewModel.move(direction)
                }
            }
        }
    }

    // MARK: - Head Section
    private var headSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("👀 HEAD")
                .font(.headline)
                .foregroundColor(.secondary)

            HeadControls { direction in
                Task {
                    await viewModel.lookAt(direction)
                }
            }
        }
    }

    // MARK: - Arms Section
    private var armsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💪 ARMS")
                .font(.headline)
                .foregroundColor(.secondary)

            ArmControls { side, position in
                Task {
                    await viewModel.setArm(side, position: position)
                }
            }
        }
    }
}

// MARK: - Sub Components
struct VolumeSlider: View {
    @Binding var volume: Double
    let isMuted: Bool
    let onVolumeChange: (Double) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(isMuted ? "🔇 Muted" : "🔊 Volume")
                    .font(.title3)
                    .bold()
                Spacer()
                Text("\(Int(volume))%")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.blue)
            }

            Slider(value: $volume, in: 0...100, step: 1)
                .tint(.blue)
                .disabled(isMuted)
                .onChange(of: volume) { newValue in
                    onVolumeChange(newValue)
                }
        }
    }
}

struct MuteButton: View {
    @Binding var isMuted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            isMuted.toggle()
            action()
        }) {
            Text(isMuted ? "🔇 Unmute" : "🔇 Mute")
                .frame(maxWidth: .infinity)
                .padding()
                .background(isMuted ? Color.red.opacity(0.8) : Color.orange.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

struct ResetVolumeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Reset Volume")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

struct ViewCameraButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "video.fill")
                Text("View Camera Feed")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}