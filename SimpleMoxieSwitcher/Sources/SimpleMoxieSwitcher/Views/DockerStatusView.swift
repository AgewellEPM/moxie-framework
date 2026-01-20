import SwiftUI
import AppKit

struct DockerStatusView<Content: View>: View {
    let content: Content
    @State private var dockerStatus: DockerHealthCheck.DockerStatus?
    @State private var showingAlert = false
    @State private var hasChecked = false
    private let healthCheck = DockerHealthCheck()

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
                .disabled(dockerStatus?.isHealthy == false)
                .blur(radius: showingAlert ? 3 : 0)

            if showingAlert, let status = dockerStatus, !status.isHealthy {
                DockerErrorOverlay(
                    message: status.userMessage,
                    onRetry: {
                        recheckDocker()
                    },
                    onQuit: {
                        NSApplication.shared.terminate(nil)
                    }
                )
            }
        }
        .onAppear {
            if !hasChecked {
                checkDocker()
            }
        }
    }

    private func checkDocker() {
        hasChecked = true
        dockerStatus = healthCheck.checkDockerStatus()

        if let status = dockerStatus, !status.isHealthy {
            showingAlert = true
        }
    }

    private func recheckDocker() {
        showingAlert = false
        dockerStatus = nil
        hasChecked = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            checkDocker()
        }
    }
}

struct DockerErrorOverlay: View {
    let message: String
    let onRetry: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Docker Required")
                .font(.title)
                .fontWeight(.bold)

            Text(message)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 15) {
                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://www.docker.com/products/docker-desktop")!)
                }) {
                    Text("Download Docker")
                        .frame(minWidth: 140)
                }
                .buttonStyle(.bordered)

                Button("Retry") {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
                .frame(minWidth: 100)

                Button("Quit") {
                    onQuit()
                }
                .buttonStyle(.bordered)
                .frame(minWidth: 100)
            }
            .padding(.top, 10)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.background)
                .shadow(radius: 20)
        )
        .padding(60)
    }
}

#Preview {
    DockerStatusView {
        ContentView()
    }
}
