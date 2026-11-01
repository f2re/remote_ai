import AppKit
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var state: MascotState = .offline
    @Published var config: RemoteAIConfig
    @Published private(set) var workspace: Workspace?
    @Published private(set) var detail: String?

    private let store = ConfigStore()
    private let mutagen = MutagenController()
    private let runtime = RemoteRuntimeController()
    private let notifications = NotificationService()
    private let runner = ProcessRunner()
    private let warp = WarpIntegration()

    private var monitorTask: Task<Void, Never>?

    init() {
        config = (try? store.loadConfig()) ?? RemoteAIConfig()
        workspace = try? store.loadWorkspace()
    }

    func requestNotificationPermission() {
        Task { await notifications.requestAuthorization() }
    }

    func chooseProject() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Project"
        if panel.runModal() == .OK, let url = panel.url {
            let newWorkspace = Workspace.make(localPath: url.path, remoteRoot: config.remoteRoot)
            workspace = newWorkspace
            try? store.saveWorkspace(newWorkspace)
            detail = newWorkspace.name
        }
    }

    func saveSettings() {
        do {
            try config.validate()
            try store.saveConfig(config)
            if let existing = workspace {
                let refreshed = Workspace.make(localPath: existing.localPath, remoteRoot: config.remoteRoot)
                workspace = refreshed
                try store.saveWorkspace(refreshed)
            }
            detail = "Settings saved"
        } catch {
            setError(error)
        }
    }

    func primaryAction() {
        switch state {
        case .offline, .error:
            start()
        case .waiting, .thinking, .syncing, .connecting:
            openWarp()
        }
    }

    func start() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            guard let self else { return }
            await self.startSequence()
        }
    }

    func stop() {
        monitorTask?.cancel()
        monitorTask = nil
        Task { [weak self] in
            guard let self, let workspace = self.workspace else { return }
            do {
                try await self.mutagen.flush(workspace: workspace)
                try await self.runtime.stopClaude(workspace: workspace, config: self.config)
                await self.mutagen.pause(workspace: workspace)
                self.detail = "Stopped"
                self.transition(to: .offline)
            } catch {
                self.setError(error)
            }
        }
    }

    func openWarp() {
        guard let workspace else {
            chooseProject()
            return
        }
        let command = runtime.attachCommand(workspace: workspace, config: config)
        do {
            try warp.open(workspace: workspace, config: config, attachCommand: command)
            detail = "Opened \(workspace.name) in Warp"
        } catch {
            detail = "Warp unavailable: \(error.localizedDescription). Opening Terminal instead."
            openTerminal()
        }
    }

    func openTerminal() {
        guard let workspace else {
            chooseProject()
            return
        }
        let command = runtime.attachCommand(workspace: workspace, config: config)
        let script = "tell application \"Terminal\"\nactivate\ndo script \"\(AppleScriptEscaping.stringLiteral(command))\"\nend tell"
        Task {
            _ = try? await runner.run(executable: "/usr/bin/osascript", arguments: ["-e", script])
        }
    }

    private func startSequence() async {
        guard let workspace else {
            chooseProject()
            return
        }
        do {
            try config.validate()
            try store.saveConfig(config)
            transition(to: .connecting)
            detail = "Connecting to \(config.host)"
            try await runtime.prepare(workspace: workspace, config: config)

            transition(to: .syncing)
            detail = "Preparing mirror"
            try await mutagen.ensureSession(workspace: workspace, config: config)
            try await mutagen.flush(workspace: workspace)

            try await runtime.startClaude(workspace: workspace, config: config)
            await refresh()
            beginPolling()
        } catch {
            setError(error)
        }
    }

    private func beginPolling() {
        let interval = max(1, config.pollIntervalSeconds)
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.refresh()
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    private func refresh() async {
        guard let workspace else {
            transition(to: .offline)
            return
        }

        let sync = await mutagen.status(workspace: workspace)
        switch sync {
        case .conflict(let message):
            detail = message
            transition(to: .error(message))
            return
        case .syncing(let message):
            detail = message
            transition(to: .syncing)
            return
        case .missing:
            detail = "Mirror is not configured"
            transition(to: .offline)
            return
        case .unavailable(let message):
            detail = message
            transition(to: .offline)
            return
        case .paused:
            detail = "Mirror paused"
            transition(to: .offline)
            return
        case .ready:
            break
        }

        do {
            let snapshot = try await runtime.poll(workspace: workspace, config: config)
            guard snapshot.sessionExists else {
                detail = "Claude session is not running"
                transition(to: .offline)
                return
            }
            detail = PaneStatusParser.lastMeaningfulLine(from: snapshot.pane)
            transition(to: snapshot.reportedState ?? PaneStatusParser.state(from: snapshot.pane))
        } catch {
            detail = error.localizedDescription
            transition(to: .offline)
        }
    }

    private func transition(to newState: MascotState) {
        let oldState = state
        state = newState

        if config.notifyWhenWaiting,
           newState == .waiting,
           oldState == .thinking,
           let workspace {
            let currentDetail = detail
            Task { await notifications.notifyWaiting(projectName: workspace.name, detail: currentDetail) }
        }
    }

    private func setError(_ error: Error) {
        let message = error.localizedDescription.isEmpty ? String(describing: error) : error.localizedDescription
        detail = message
        transition(to: .error(message))
    }
}
