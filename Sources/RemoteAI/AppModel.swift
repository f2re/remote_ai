import AppKit
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var state: MascotState = .offline
    @Published var config: RemoteAIConfig
    @Published private(set) var workspace: Workspace?
    @Published private(set) var detail: String?
    @Published private(set) var setupChecks: [SetupCheck] = []
    @Published private(set) var isTestingSetup = false

    private let store = ConfigStore()
    private let mutagen = MutagenController()
    private let runtime = RemoteRuntimeController()
    private let notifications = NotificationService()
    private let diagnostics = SetupDiagnostics()
    private let runner = ProcessRunner()
    private let warp = WarpIntegration()

    private var actionTask: Task<Void, Never>?
    private var pollingTask: Task<Void, Never>?

    init() {
        config = (try? store.loadConfig()) ?? RemoteAIConfig()
        workspace = try? store.loadWorkspace()
    }

    var primaryActionIntent: MascotPrimaryAction {
        state.primaryAction(
            hasConfiguredHost: !config.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            hasWorkspace: workspace != nil
        )
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
            setupChecks = []
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
            setupChecks = []
            detail = "Settings saved"
        } catch {
            setError(error)
        }
    }

    func testSetup() {
        guard !isTestingSetup else { return }
        isTestingSetup = true
        Task { [weak self] in
            guard let self else { return }
            let checks = await self.diagnostics.run(config: self.config, workspace: self.workspace)
            self.setupChecks = checks
            self.isTestingSetup = false
            if let failure = checks.first(where: { $0.status == .failed }) {
                self.detail = "\(failure.title): \(failure.detail)"
            } else if checks.contains(where: { $0.status == .warning }) {
                self.detail = "Setup is usable with warnings"
            } else {
                self.detail = "Setup is ready"
            }
        }
    }

    func showSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func primaryAction() {
        switch primaryActionIntent {
        case .openSettings:
            showSettings()
        case .chooseProject:
            chooseProject()
        case .startOrReconnect:
            start()
        case .openWarp:
            openWarp()
        }
    }

    func restoreExistingSession() {
        guard workspace != nil else { return }
        guard (try? config.validate()) != nil else { return }

        actionTask?.cancel()
        actionTask = Task { [weak self] in
            guard let self else { return }
            self.transition(to: .connecting)
            self.detail = "Checking existing remote session"
            let shouldPoll = await self.refresh()
            if shouldPoll {
                self.beginPolling()
            }
        }
    }

    func start() {
        actionTask?.cancel()
        pollingTask?.cancel()
        actionTask = Task { [weak self] in
            guard let self else { return }
            await self.startSequence()
        }
    }

    func stop() {
        actionTask?.cancel()
        actionTask = nil
        pollingTask?.cancel()
        pollingTask = nil
        Task { [weak self] in
            guard let self, let workspace = self.workspace else { return }
            do {
                try await self.mutagen.flush(workspace: workspace)
                try await self.runtime.stopClaude(workspace: workspace, config: self.config)
                await self.mutagen.pause(workspace: workspace)
                self.detail = "Stopped after a successful sync flush"
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
            detail = "Testing local and remote prerequisites"
            let checks = await diagnostics.run(config: config, workspace: workspace)
            setupChecks = checks
            if let failure = checks.first(where: { $0.status == .failed }) {
                throw RemoteAIError.preflightFailed("\(failure.title): \(failure.detail)")
            }

            detail = "Connecting to \(config.host)"
            try await runtime.prepare(workspace: workspace, config: config)

            transition(to: .syncing)
            detail = "Preparing mirror"
            try await mutagen.ensureSession(workspace: workspace, config: config)
            try await mutagen.flush(workspace: workspace)

            try await runtime.startClaude(workspace: workspace, config: config)
            _ = await refresh()
            beginPolling()
        } catch {
            setError(error)
        }
    }

    private func beginPolling() {
        let interval = max(1, config.pollIntervalSeconds)
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                _ = await self.refresh()
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    @discardableResult
    private func refresh() async -> Bool {
        guard let workspace else {
            transition(to: .offline)
            return false
        }

        let sync = await mutagen.status(workspace: workspace)
        switch sync {
        case .conflict(let message):
            detail = message
            transition(to: .error(message))
            return false
        case .syncing(let message):
            detail = message
            transition(to: .syncing)
            return true
        case .missing:
            detail = "Mirror is not configured for this workspace"
            transition(to: .offline)
            return false
        case .unavailable(let message):
            detail = message
            transition(to: .offline)
            return false
        case .paused:
            detail = "Mirror paused"
            transition(to: .offline)
            return false
        case .ready:
            break
        }

        do {
            let snapshot = try await runtime.poll(workspace: workspace, config: config)
            guard snapshot.sessionExists else {
                detail = "Claude session is not running"
                transition(to: .offline)
                return false
            }
            detail = PaneStatusParser.lastMeaningfulLine(from: snapshot.pane)
            transition(to: snapshot.reportedState ?? PaneStatusParser.state(from: snapshot.pane))
            return true
        } catch {
            detail = error.localizedDescription
            transition(to: .offline)
            return false
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
            Task { await notifications.notifyWaiting(workspace: workspace, detail: currentDetail) }
        }
    }

    private func setError(_ error: Error) {
        let message = error.localizedDescription.isEmpty ? String(describing: error) : error.localizedDescription
        detail = message
        transition(to: .error(message))
    }
}
