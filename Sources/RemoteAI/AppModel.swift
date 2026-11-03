import AppKit
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var state: MascotState = .offline
    @Published var config: RemoteAIConfig
    @Published var workspaces: [Workspace] = []
    @Published var activeWorkspaceID: String?
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
        let collection = (try? store.loadWorkspaces()) ?? WorkspaceCollection(activeWorkspaceID: nil, workspaces: [])
        workspaces = collection.workspaces
        activeWorkspaceID = collection.activeWorkspaceID ?? workspaces.first?.id
    }

    var workspace: Workspace? {
        get {
            workspaces.first { $0.id == activeWorkspaceID } ?? workspaces.first
        }
        set {
            if let newValue {
                if let idx = workspaces.firstIndex(where: { $0.id == newValue.id }) {
                    workspaces[idx] = newValue
                } else {
                    workspaces.append(newValue)
                }
                activeWorkspaceID = newValue.id
            } else {
                activeWorkspaceID = nil
            }
            saveWorkspaces()
        }
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

    func saveWorkspaces() {
        let collection = WorkspaceCollection(activeWorkspaceID: activeWorkspaceID, workspaces: workspaces)
        try? store.saveWorkspaces(collection)
    }

    func selectWorkspace(id: String) {
        guard activeWorkspaceID != id else { return }
        if state != .offline {
            stop()
        }
        activeWorkspaceID = id
        saveWorkspaces()
        setupChecks = []
        if let current = workspace {
            detail = "Выбрана сессия: \(current.name)"
        }
    }

    func createWorkspace(name: String? = nil, initialPath: String? = nil) {
        let paths = initialPath.map { [$0] } ?? []
        let newWorkspace = Workspace.make(name: name, localPaths: paths, remoteRoot: config.remoteRoot)
        workspaces.append(newWorkspace)
        activeWorkspaceID = newWorkspace.id
        saveWorkspaces()
        setupChecks = []
        detail = "Создана сессия: \(newWorkspace.name)"
    }

    func deleteWorkspace(id: String) {
        if activeWorkspaceID == id, state != .offline {
            stop()
        }
        workspaces.removeAll { $0.id == id }
        if activeWorkspaceID == id {
            activeWorkspaceID = workspaces.first?.id
        }
        saveWorkspaces()
        setupChecks = []
        detail = "Сессия удалена"
    }

    func renameWorkspace(id: String, newName: String) {
        guard let idx = workspaces.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        workspaces[idx].name = trimmed
        saveWorkspaces()
    }

    func addFolder(to workspaceID: String, localPath: String) {
        guard let idx = workspaces.firstIndex(where: { $0.id == workspaceID }) else { return }
        let standardized = URL(fileURLWithPath: localPath).standardizedFileURL.path
        guard !workspaces[idx].folders.contains(where: { $0.localPath == standardized }) else { return }
        workspaces[idx].folders.append(WorkspaceFolder(localPath: standardized))
        saveWorkspaces()
        setupChecks = []
        detail = "Добавлена папка в сессию: \(URL(fileURLWithPath: standardized).lastPathComponent)"
    }

    func removeFolder(from workspaceID: String, folderID: String) {
        guard let idx = workspaces.firstIndex(where: { $0.id == workspaceID }) else { return }
        workspaces[idx].folders.removeAll { $0.id == folderID }
        saveWorkspaces()
        setupChecks = []
        detail = "Папка удалена из сессии"
    }

    func addFolderToActiveSession() {
        guard let active = workspace else {
            chooseProject()
            return
        }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Добавить в проект"
        if panel.runModal() == .OK {
            for url in panel.urls {
                addFolder(to: active.id, localPath: url.path)
            }
        }
    }

    func chooseProject() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Выбрать папки проекта"
        if panel.runModal() == .OK, !panel.urls.isEmpty {
            let paths = panel.urls.map(\.path)
            let firstName = panel.urls.first?.lastPathComponent ?? "project"
            let newWorkspace = Workspace.make(name: firstName, localPaths: paths, remoteRoot: config.remoteRoot)
            workspaces.append(newWorkspace)
            activeWorkspaceID = newWorkspace.id
            saveWorkspaces()
            setupChecks = []
            detail = "Создана сессия: \(newWorkspace.name) (\(paths.count) папок)"
        }
    }

    func saveSettings() {
        do {
            try config.validate()
            try store.saveConfig(config)
            saveWorkspaces()
            setupChecks = []
            detail = "Настройки сохранены"
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
                self.detail = "Настройка работоспособна, но требует внимания"
            } else {
                self.detail = "Настройка готова к работе"
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
            self.detail = "Проверяем существующую удалённую сессию"
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
                try await self.mutagen.flush(workspace: workspace, config: self.config)
                try await self.runtime.stopClaude(workspace: workspace, config: self.config)
                await self.mutagen.pause(workspace: workspace, config: self.config)
                self.detail = "Сессия остановлена после успешной синхронизации"
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
            detail = "Проект \(workspace.name) открыт в Warp"
        } catch {
            detail = "Warp недоступен: \(error.localizedDescription). Открываем Terminal."
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
            saveWorkspaces()

            transition(to: .connecting)
            detail = "Проверяем локальные и удалённые зависимости"
            let checks = await diagnostics.run(config: config, workspace: workspace)
            setupChecks = checks
            if let failure = checks.first(where: { $0.status == .failed }) {
                throw RemoteAIError.preflightFailed("\(failure.title): \(failure.detail)")
            }

            detail = "Подключаемся к \(config.host)"
            try await runtime.prepare(workspace: workspace, config: config)

            transition(to: .syncing)
            detail = "Подготавливаем зеркало проекта"
            try await mutagen.ensureSession(workspace: workspace, config: config)
            try await mutagen.flush(workspace: workspace, config: config)

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

        let sync = await mutagen.status(workspace: workspace, config: config)
        switch sync {
        case .conflict(let message):
            detail = message
            transition(to: .error(message))
            return false
        case .syncing(let message):
            detail = message
            transition(to: .syncing)
            return true
        case .paused:
            detail = "Синхронизация Mutagen приостановлена"
            transition(to: .offline)
            return false
        case .unavailable(let message):
            detail = message
            transition(to: .error(message))
            return false
        case .missing:
            detail = "Сессия Mutagen не найдена"
            transition(to: .offline)
            return false
        case .ready:
            break
        }

        do {
            let snapshot = try await runtime.poll(workspace: workspace, config: config)
            guard snapshot.sessionExists else {
                detail = "Удалённая сессия tmux не найдена"
                transition(to: .offline)
                return false
            }

            let resolvedState = snapshot.reportedState ?? PaneStatusParser.state(from: snapshot.pane)
            detail = statusDetail(for: resolvedState)
            transition(to: resolvedState)
            return true
        } catch {
            detail = error.localizedDescription
            transition(to: .offline)
            return false
        }
    }

    private func statusDetail(for state: MascotState) -> String {
        switch state {
        case .offline:
            "Удалённая сессия не запущена"
        case .connecting:
            "Подключаемся к удалённому серверу"
        case .syncing:
            "Синхронизируем файлы проекта"
        case .thinking:
            "Claude Code выполняет задачу"
        case .waiting:
            "Claude Code ожидает ввода"
        case .error(let message):
            message
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
