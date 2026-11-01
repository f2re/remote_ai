import AppKit
import SwiftUI

@MainActor
final class MascotWindowController {
    private let panel: NSPanel

    init(model: AppModel) {
        panel = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: MascotDesign.Metric.panelWidth,
                height: MascotDesign.Metric.panelHeight
            ),
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
        panel.contentView = NSHostingView(rootView: MascotView(model: model).padding(2))
    }

    func show() {
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(
                x: frame.maxX - MascotDesign.Metric.panelWidth - 14,
                y: frame.maxY - MascotDesign.Metric.panelHeight - 14
            ))
        }
        panel.orderFrontRegardless()
    }
}
