import AppKit
import SwiftUI

struct MascotView: View {
    @ObservedObject var model: AppModel

    @State private var hovering = false

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

                PixelCloudMascot(state: model.state)
                    .frame(width: MascotDesign.Metric.artWidth, height: MascotDesign.Metric.artHeight)
                    .opacity(isOffline ? 0.86 : 1)
            }
            .frame(width: MascotDesign.Metric.hitSize, height: MascotDesign.Metric.hitSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(MascotButtonStyle())
        .scaleEffect(hovering ? MascotDesign.Metric.hoverScale : 1)
        .animation(MascotDesign.Motion.hover, value: hovering)
        .animation(MascotDesign.Motion.state, value: model.state.accessibilityLabel)
        .onHover { hovering = $0 }
        .help(tooltipText)
        .accessibilityLabel(model.state.accessibilityLabel)
        .accessibilityHint(primaryActionHint)
        .contextMenu {
            Button("Выбрать проект…") { model.chooseProject() }
            Button("Запустить / переподключить") { model.start() }
                .disabled(model.workspace == nil)
            Button("Открыть обзор в Warp") { model.openWarp() }
                .disabled(model.workspace == nil)
            Button("Подключиться в Terminal") { model.openTerminal() }
                .disabled(model.workspace == nil)
            Divider()
            Button("Остановить") { model.stop() }
                .disabled(model.workspace == nil)
            Button("Настройки…") { model.showSettings() }
            Divider()
            Button("Завершить Remote AI") { NSApp.terminate(nil) }
        }
    }

    private var isOffline: Bool {
        if case .offline = model.state { return true }
        return false
    }

    private var tooltipText: String {
        if let detail = model.detail, !detail.isEmpty {
            return "\(model.state.accessibilityLabel). \(detail)"
        }
        return "\(model.state.accessibilityLabel). \(primaryActionHint)"
    }

    private var primaryActionHint: String {
        switch model.primaryActionIntent {
        case .openSettings:
            "Открыть настройки и указать удалённый сервер"
        case .chooseProject:
            "Выбрать локальную папку проекта для синхронизации"
        case .startOrReconnect:
            "Запустить или восстановить удалённое рабочее пространство Claude Code"
        case .openWarp:
            "Открыть локальный обзор и текущую сессию Claude Code в Warp"
        }
    }
}
