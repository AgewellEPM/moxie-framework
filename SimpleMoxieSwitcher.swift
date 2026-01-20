import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        // Make sure window is key and accepts input
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
                // Don't force first responder, let the system handle it naturally
                window.makeMain()
                window.level = .normal
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct SimpleMoxieSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let diContainer = DIContainer.shared
    @StateObject private var conversationListener: ConversationListenerService

    init() {
        let listener = DIContainer.shared.resolve(ConversationListenerService.self)
        _conversationListener = StateObject(wrappedValue: listener)
    }

    var body: some Scene {
        WindowGroup {
            DockerStatusView {
                ContentView()
                    .environmentObject(diContainer.resolve(ContentViewModel.self))
                    .environment(\.diContainer, diContainer)
                    .frame(minWidth: 700, minHeight: 600)
                    .background(WindowAccessor(transparency: 0.80))
                    .onAppear {
                        // Start listening to Moxie conversations
                        conversationListener.startListening()
                    }
            }
        }
        .windowResizabilityContentSize()
    }
}

extension Scene {
    func windowResizabilityContentSize() -> some Scene {
        if #available(macOS 13.0, *) {
            return windowResizability(.contentSize)
        } else {
            return self
        }
    }
}