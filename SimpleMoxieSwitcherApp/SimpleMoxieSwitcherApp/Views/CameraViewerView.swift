//
//  CameraViewerView.swift
//  SimpleMoxieSwitcherApp
//
//  Created on 2026-01-06.
//

import SwiftUI
import AppKit

struct CameraViewerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var cameraImage: NSImage?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("📷 Moxie Camera Feed")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Close") {
                    timer?.invalidate()
                    dismiss()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            // Camera Feed Display
            ZStack {
                Color.black

                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Connecting to camera...")
                            .foregroundColor(.white)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            loadCameraFeed()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                } else if let image = cameraImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No camera feed available")
                            .foregroundColor(.white)
                    }
                }
            }

            // Status Bar
            HStack {
                Text(isLoading ? "Loading..." : errorMessage != nil ? "Error" : "Live Feed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if !isLoading && errorMessage == nil {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Connected")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
        }
        .frame(minWidth: 640, minHeight: 480)
        .onAppear {
            loadCameraFeed()
            // Refresh camera feed every 2 seconds
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                if errorMessage == nil {
                    loadCameraFeed()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func loadCameraFeed() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Try to fetch the latest camera image from OpenMoxie
                // The camera stream might be available at http://localhost:8003/camera/feed or similar
                guard let url = URL(string: "http://localhost:8003/camera/latest.jpg") else {
                    await MainActor.run {
                        errorMessage = "Invalid camera URL"
                        isLoading = false
                    }
                    return
                }

                let (data, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    await MainActor.run {
                        errorMessage = "Camera feed not available. Make sure the camera is enabled and OpenMoxie is running."
                        isLoading = false
                    }
                    return
                }

                if let image = NSImage(data: data) {
                    await MainActor.run {
                        cameraImage = image
                        isLoading = false
                        errorMessage = nil
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Failed to decode camera image"
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Camera connection error: \(error.localizedDescription)\n\nNote: Camera viewing requires OpenMoxie camera service to be running."
                    isLoading = false
                }
            }
        }
    }
}
