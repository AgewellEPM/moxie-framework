import SwiftUI
import AppKit

@main
struct SimpleMoxieSwitcherApp: App {
    @StateObject private var contentViewModel: ContentViewModel
    private let diContainer = DIContainer.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        _contentViewModel = StateObject(wrappedValue: DIContainer.shared.resolve(ContentViewModel.self))
    }

    var body: some Scene {
        WindowGroup {
            DockerStatusView {
                ContentView()
                    .environmentObject(contentViewModel)
                    .environment(\.diContainer, diContainer)
            }
            .onAppear {
                // Activate the app for keyboard input
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 700, height: 600)
    }
}

// MARK: - App Delegate for proper activation
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Make this a regular app that appears in Dock and can receive keyboard input
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
