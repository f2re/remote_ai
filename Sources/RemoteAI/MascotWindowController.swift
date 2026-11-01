import AppKit
import SwiftUI

@MainActor
final class MascotWindowController {
    private let panel: NSPanel

    init(model: AppModel) {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 76, height: 76),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: MascotView(model: model).padding(4))
    }

    func show() {
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.maxX - 92, y: frame.maxY - 92))
        }
        panel.orderFrontRegardless()
    }
}
