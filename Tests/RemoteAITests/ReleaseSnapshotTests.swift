import AppKit
import SwiftUI
import XCTest
@testable import RemoteAI

@MainActor
final class ReleaseSnapshotTests: XCTestCase {
    private struct NamedState {
        let name: String
        let title: String
        let state: MascotState
    }

    private let states: [NamedState] = [
        .init(name: "offline", title: "Не в сети", state: .offline),
        .init(name: "connecting", title: "Подключение", state: .connecting),
        .init(name: "syncing", title: "Синхронизация", state: .syncing),
        .init(name: "thinking", title: "Claude Code работает", state: .thinking),
        .init(name: "waiting", title: "Ожидание ввода", state: .waiting),
        .init(name: "error", title: "Ошибка", state: .error("Пример ошибки подключения"))
    ]

    func testReleaseSnapshots() throws {
        guard let outputPath = ProcessInfo.processInfo.environment["REMOTE_AI_SNAPSHOT_DIR"],
              !outputPath.isEmpty else {
            throw XCTSkip("Укажите REMOTE_AI_SNAPSHOT_DIR для создания релизных снимков интерфейса.")
        }

        _ = NSApplication.shared
        let output = URL(fileURLWithPath: outputPath, isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

        for scheme in [ColorScheme.light, .dark] {
            let suffix = scheme == .light ? "light" : "dark"

            for named in states {
                try render(
                    MascotSnapshotSurface(state: named.state)
                        .environment(\.colorScheme, scheme),
                    size: CGSize(width: 176, height: 176),
                    to: output.appendingPathComponent("mascot-\(named.name)-\(suffix).png")
                )
            }

            try render(
                MascotStateSheet(states: states.map { ($0.title, $0.state) })
                    .environment(\.colorScheme, scheme),
                size: CGSize(width: 820, height: 560),
                to: output.appendingPathComponent("mascot-states-\(suffix).png")
            )

            let model = AppModel()
            model.config.host = "buildbox.example"
            model.config.user = "developer"
            model.config.port = 22
            model.config.sshKeyPath = ""
            model.config.remoteRoot = ".remote-ai/workspaces"
            model.config.pollIntervalSeconds = 3
            model.config.notifyWhenWaiting = true

            try render(
                SettingsSnapshotSurface(model: model)
                    .environment(\.colorScheme, scheme),
                size: CGSize(width: 760, height: 1080),
                to: output.appendingPathComponent("settings-\(suffix).png")
            )
        }
    }

    private func render<V: View>(_ view: V, size: CGSize, to url: URL) throws {
        let root = ZStack {
            Color(nsColor: .windowBackgroundColor)
            view
        }
        .frame(width: size.width, height: size.height)

        let hosting = NSHostingView(rootView: root)
        let rect = NSRect(origin: .zero, size: size)
        hosting.frame = rect

        let window = NSWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.backgroundColor = .windowBackgroundColor
        window.contentView = hosting
        window.orderFrontRegardless()
        defer {
            window.orderOut(nil)
            window.close()
        }

        hosting.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        guard let bitmap = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
            throw SnapshotError.renderFailed(url.lastPathComponent)
        }
        hosting.cacheDisplay(in: hosting.bounds, to: bitmap)

        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            throw SnapshotError.renderFailed(url.lastPathComponent)
        }

        try png.write(to: url, options: .atomic)
        print("СНИМОК \(url.path)")
    }
}

private enum SnapshotError: LocalizedError {
    case renderFailed(String)

    var errorDescription: String? {
        switch self {
        case .renderFailed(let name):
            return "Не удалось создать снимок \(name)"
        }
    }
}

private struct MascotSnapshotSurface: View {
    let state: MascotState

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            ZStack {
                PixelCloudMascot(state: state, blink: false)
                    .frame(
                        width: MascotDesign.Metric.artWidth,
                        height: MascotDesign.Metric.artHeight
                    )
                MascotStatusPixels(state: state, reduceMotion: true)
            }
            .frame(
                width: MascotDesign.Metric.hitSize,
                height: MascotDesign.Metric.hitSize
            )
            .padding(28)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct MascotStateSheet: View {
    let states: [(String, MascotState)]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Remote AI")
                    .font(.system(size: 22, weight: .semibold))
                Text("Состояния пиксельного облака")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(states.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 10) {
                        ZStack {
                            PixelCloudMascot(state: item.1, blink: false)
                                .frame(
                                    width: MascotDesign.Metric.artWidth,
                                    height: MascotDesign.Metric.artHeight
                                )
                            MascotStatusPixels(state: item.1, reduceMotion: true)
                        }
                        .frame(
                            width: MascotDesign.Metric.hitSize,
                            height: MascotDesign.Metric.hitSize
                        )

                        Text(item.0)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.quaternary.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct SettingsSnapshotSurface: View {
    @ObservedObject var model: AppModel

    var body: some View {
        SettingsView(model: model)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(20)
    }
}
