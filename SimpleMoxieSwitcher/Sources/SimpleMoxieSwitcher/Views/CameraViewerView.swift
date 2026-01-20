import SwiftUI
import AVKit

struct CameraViewerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("📷 Camera Viewer")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            // Camera feed
            if cameraManager.isAvailable {
                CameraPreview(cameraManager: cameraManager)
                    .cornerRadius(10)
                    .padding()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "camera.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Camera not available")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Please check camera permissions in System Preferences")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(50)
            }

            // Controls
            HStack {
                Button(action: {
                    cameraManager.toggleCamera()
                }) {
                    HStack {
                        Image(systemName: cameraManager.isRecording ? "stop.circle" : "record.circle")
                        Text(cameraManager.isRecording ? "Stop" : "Start")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(cameraManager.isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Button(action: {
                    cameraManager.captureSnapshot()
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Snapshot")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            cameraManager.checkPermissions()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: NSViewRepresentable {
    let cameraManager: CameraManager

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer = cameraManager.previewLayer
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Camera Manager
@MainActor
class CameraManager: ObservableObject {
    @Published var isAvailable = false
    @Published var isRecording = false

    lazy var previewLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = NSColor.black.cgColor
        return layer
    }()

    func checkPermissions() {
        // Check camera permissions
        isAvailable = true  // Simplified for now
    }

    func toggleCamera() {
        isRecording.toggle()
    }

    func captureSnapshot() {
        // Capture a snapshot
    }

    func stopSession() {
        isRecording = false
    }
}