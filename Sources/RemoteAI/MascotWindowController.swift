import AppKit
import SwiftUI

@MainActor
final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    private var initialMouseLocation: NSPoint?
    private var initialWindowOrigin: NSPoint?
    private var hasDragged = false
    private let onPrimaryAction: () -> Void
    private let onPositionChanged: (NSPoint) -> Void

    init(
        rootView: Content,
        onPrimaryAction: @escaping () -> Void,
        onPositionChanged: @escaping (NSPoint) -> Void
    ) {
        self.onPrimaryAction = onPrimaryAction
        self.onPositionChanged = onPositionChanged
        super.init(rootView: rootView)
    }

    required init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }

    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func mouseDown(with event: NSEvent) {
        initialMouseLocation = NSEvent.mouseLocation
        initialWindowOrigin = window?.frame.origin
        hasDragged = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let initialMouse = initialMouseLocation,
              let initialOrigin = initialWindowOrigin,
              let window = self.window else {
            super.mouseDragged(with: event)
            return
        }

        let currentMouse = NSEvent.mouseLocation
        let deltaX = currentMouse.x - initialMouse.x
        let deltaY = currentMouse.y - initialMouse.y

        if !hasDragged && hypot(deltaX, deltaY) > 3.0 {
            hasDragged = true
            NSCursor.closedHand.push()
        }

        if hasDragged {
            let newOrigin = NSPoint(x: initialOrigin.x + deltaX, y: initialOrigin.y + deltaY)
            window.setFrameOrigin(newOrigin)
        }
    }

    override func mouseUp(with event: NSEvent) {
        if hasDragged {
            hasDragged = false
            NSCursor.pop()
            if let origin = window?.frame.origin {
                onPositionChanged(origin)
            }
        } else {
            onPrimaryAction()
        }
        initialMouseLocation = nil
        initialWindowOrigin = nil
    }
}

@MainActor
final class MascotWindowController {
    let panel: NSPanel
    private let originXKey = "RemoteAIMascotWindowOriginX"
    private let originYKey = "RemoteAIMascotWindowOriginY"

    var isVisible: Bool {
        panel.isVisible
    }

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
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = MascotView(model: model).padding(2)
        panel.contentView = DraggableHostingView(
            rootView: view,
            onPrimaryAction: { [weak model] in
                model?.primaryAction()
            },
            onPositionChanged: { [weak self] origin in
                self?.saveOrigin(origin)
            }
        )
    }

    func show() {
        if let saved = loadSavedOrigin(), isPointOnAnyScreen(saved) {
            panel.setFrameOrigin(saved)
        } else if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(
                x: frame.maxX - MascotDesign.Metric.panelWidth - 14,
                y: frame.maxY - MascotDesign.Metric.panelHeight - 14
            ))
        }
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    private func saveOrigin(_ origin: NSPoint) {
        UserDefaults.standard.set(Double(origin.x), forKey: originXKey)
        UserDefaults.standard.set(Double(origin.y), forKey: originYKey)
    }

    private func loadSavedOrigin() -> NSPoint? {
        guard UserDefaults.standard.object(forKey: originXKey) != nil,
              UserDefaults.standard.object(forKey: originYKey) != nil else {
            return nil
        }
        let x = UserDefaults.standard.double(forKey: originXKey)
        let y = UserDefaults.standard.double(forKey: originYKey)
        return NSPoint(x: x, y: y)
    }

    private func isPointOnAnyScreen(_ point: NSPoint) -> Bool {
        let rect = NSRect(origin: point, size: NSSize(width: MascotDesign.Metric.panelWidth, height: MascotDesign.Metric.panelHeight))
        return NSScreen.screens.contains { screen in
            screen.frame.intersects(rect)
        }
    }
}
