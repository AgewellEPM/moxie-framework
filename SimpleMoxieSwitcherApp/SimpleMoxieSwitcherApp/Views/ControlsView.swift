//
//  ControlsView.swift
//  SimpleMoxieSwitcherApp
//
//  Created on 2026-01-06.
//

import SwiftUI
import AppKit

struct ControlsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var controller: PersonalityController
    @State private var cameraEnabled = false
    @State private var volume: Double = 50
    @State private var isMuted = false
    @State private var showCameraViewer = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
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

            ScrollView {
                VStack(spacing: 25) {
                    // Audio/Sound Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔊 AUDIO & SOUND")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 15) {
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
                                    Task {
                                        await controller.setVolume(Int(newValue))
                                    }
                                }

                            HStack(spacing: 15) {
                                Button(action: {
                                    isMuted.toggle()
                                    Task {
                                        await controller.toggleMute(isMuted)
                                    }
                                }) {
                                    Text(isMuted ? "🔇 Unmute" : "🔇 Mute")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(isMuted ? Color.red.opacity(0.8) : Color.orange.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                Button(action: {
                                    volume = 50
                                    Task {
                                        await controller.setVolume(50)
                                    }
                                }) {
                                    Text("Reset Volume")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(10)
                    }

                    Divider()

                    // Camera Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📷 CAMERA")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 10) {
                            Toggle(isOn: $cameraEnabled) {
                                Text(cameraEnabled ? "Camera ON" : "Camera OFF")
                                    .font(.title3)
                                    .bold()
                            }
                            .onChange(of: cameraEnabled) { newValue in
                                Task {
                                    await controller.toggleCamera(enabled: newValue)
                                }
                            }
                            .tint(.green)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)

                            if cameraEnabled {
                                Button(action: {
                                    showCameraViewer = true
                                }) {
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
                    }

                    Divider()

                    // Movement Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🚗 MOVEMENT")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 10) {
                            Button(action: { Task { await controller.move(.forward) } }) {
                                Text("⬆️ Forward")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }

                            HStack(spacing: 10) {
                                Button(action: { Task { await controller.move(.left) } }) {
                                    Text("⬅️ Left")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                Button(action: { Task { await controller.move(.right) } }) {
                                    Text("➡️ Right")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }

                            Button(action: { Task { await controller.move(.backward) } }) {
                                Text("⬇️ Backward")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }

                    Divider()

                    // Head Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("👀 HEAD")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 10) {
                            Button(action: { Task { await controller.lookAt(.up) } }) {
                                Text("⬆️ Look Up")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }

                            HStack(spacing: 10) {
                                Button(action: { Task { await controller.lookAt(.left) } }) {
                                    Text("⬅️ Look Left")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.purple.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                Button(action: { Task { await controller.lookAt(.center) } }) {
                                    Text("🎯 Center")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.purple.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                Button(action: { Task { await controller.lookAt(.right) } }) {
                                    Text("➡️ Look Right")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.purple.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }

                            Button(action: { Task { await controller.lookAt(.down) } }) {
                                Text("⬇️ Look Down")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }

                    Divider()

                    // Arms Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("💪 ARMS")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 15) {
                            // Left Arm
                            VStack(spacing: 8) {
                                Text("Left Arm")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Button(action: { Task { await controller.setArm(.left, position: .up) } }) {
                                    Text("⬆️ Up")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.orange.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                Button(action: { Task { await controller.setArm(.left, position: .down) } }) {
                                    Text("⬇️ Down")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.orange.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }

                            // Right Arm
                            VStack(spacing: 8) {
                                Text("Right Arm")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Button(action: { Task { await controller.setArm(.right, position: .up) } }) {
                                    Text("⬆️ Up")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.orange.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                Button(action: { Task { await controller.setArm(.right, position: .down) } }) {
                                    Text("⬇️ Down")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.orange.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .sheet(isPresented: $showCameraViewer) {
            CameraViewerView()
        }
    }
}
