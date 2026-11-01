import AppKit
import SwiftUI

struct MascotView: View {
    @ObservedObject var model: AppModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false
    @State private var blink = false

    var body: some View {
        Button(action: model.primaryAction) {
            ZStack {
                if hovering {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: MascotDesign.Metric.haloSize, height: MascotDesign.Metric.haloSize)
                        .opacity(MascotDesign.Metric.haloOpacity)
                        .transition(.opacity)
                }

                PixelCloudMascot(state: model.state, blink: blink)
                    .frame(width: MascotDesign.Metric.artWidth, height: MascotDesign.Metric.artHeight)
                    .opacity(isOffline ? 0.72 : 1)

                MascotStatusPixels(state: model.state, reduceMotion: reduceMotion)
                    .id(model.state.accessibilityLabel)
            }
            .frame(width: MascotDesign.Metric.hitSize, height: MascotDesign.Metric.hitSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(MascotButtonStyle())
        .scaleEffect(hovering ? MascotDesign.Metric.hoverScale : 1)
        .animation(MascotDesign.Motion.hover, value: hovering)
        .animation(MascotDesign.Motion.state, value: model.state.accessibilityLabel)
        .onHover { hovering = $0 }
        .help(model.detail ?? model.state.accessibilityLabel)
        .accessibilityLabel(model.state.accessibilityLabel)
        .accessibilityHint(primaryActionHint)
        .contextMenu {
            Button("Choose Project…") { model.chooseProject() }
            Button("Start / Reconnect") { model.start() }
                .disabled(model.workspace == nil)
            Button("Open Review in Warp") { model.openWarp() }
                .disabled(model.workspace == nil)
            Button("Attach in Terminal") { model.openTerminal() }
                .disabled(model.workspace == nil)
            Divider()
            Button("Stop") { model.stop() }
                .disabled(model.workspace == nil)
            Button("Settings…") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Quit") { NSApp.terminate(nil) }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4.2))
                guard !Task.isCancelled, !reduceMotion, !isOffline else { continue }
                blink = true
                try? await Task.sleep(for: .milliseconds(110))
                blink = false
            }
        }
    }

    private var isOffline: Bool {
        if case .offline = model.state { return true }
        return false
    }

    private var primaryActionHint: String {
        switch model.state {
        case .offline, .error:
            "Start or reconnect the remote Claude Code workspace"
        case .connecting, .syncing, .thinking, .waiting:
            "Open the local review and live Claude Code session in Warp"
        }
    }
}
