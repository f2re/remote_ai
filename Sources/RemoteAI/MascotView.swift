import AppKit
import SwiftUI

struct MascotView: View {
    @ObservedObject var model: AppModel
    @State private var pulse = false

    var body: some View {
        Button(action: model.primaryAction) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.primary.opacity(0.12), lineWidth: 1)
                    }

                HStack(spacing: 9) {
                    Circle().frame(width: 7, height: 9)
                    Circle().frame(width: 7, height: 9)
                }
                .foregroundStyle(.primary.opacity(model.state == .offline ? 0.45 : 0.82))
                .offset(y: -2)

                Image(systemName: model.state.systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .offset(x: 22, y: -22)
                    .rotationEffect(.degrees(model.state == .syncing && pulse ? 180 : 0))
            }
            .frame(width: 68, height: 68)
            .scaleEffect((model.state == .thinking || model.state == .connecting) && pulse ? 1.055 : 1)
            .opacity(model.state == .offline ? 0.72 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(model.detail ?? model.state.accessibilityLabel)
        .accessibilityLabel(model.state.accessibilityLabel)
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
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
