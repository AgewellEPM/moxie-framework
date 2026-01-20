import SwiftUI

/// NSViewRepresentable to customize the window appearance
struct WindowAccessor: NSViewRepresentable {
    let transparency: Double

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
                window.backgroundColor = NSColor.white.withAlphaComponent(transparency)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            window.isOpaque = false
            window.backgroundColor = NSColor.white.withAlphaComponent(transparency)
        }
    }
}