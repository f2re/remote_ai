import AppKit
import Combine

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let model: AppModel
    private weak var mascotWindowController: MascotWindowController?
    private var cancellables = Set<AnyCancellable>()

    init(model: AppModel, mascotWindowController: MascotWindowController?) {
        self.model = model
        self.mascotWindowController = mascotWindowController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        setupSubscriptions()
        updateStatusItem()
    }

    private func setupSubscriptions() {
        model.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateStatusItem()
                }
            }
            .store(in: &cancellables)
    }

    func updateStatusItem() {
        updateIcon()
        rebuildMenu()
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }

        let asset = MascotAsset(state: model.state)
        if let cgImage = asset.cgImage {
            let image = NSImage(cgImage: cgImage, size: NSSize(width: 18, height: 18))
            button.image = image
            button.imagePosition = .imageOnly
        } else {
            let image = NSImage(systemSymbolName: "icloud.fill", accessibilityDescription: "Remote AI")
            button.image = image
        }

        button.toolTip = "Remote AI: \(model.state.accessibilityLabel)"
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        // 1. Current state header
        let stateTitle = "Remote AI: \(model.state.accessibilityLabel)"
        let stateItem = NSMenuItem(title: stateTitle, action: nil, keyEquivalent: "")
        stateItem.isEnabled = false
        menu.addItem(stateItem)

        if let workspace = model.workspace {
            let folderInfo = workspace.folders.count > 1 ? " (\(workspace.folders.count) папок)" : ""
            let projectItem = NSMenuItem(title: "Проект: \(workspace.name)\(folderInfo)", action: nil, keyEquivalent: "")
            projectItem.isEnabled = false
            menu.addItem(projectItem)
        }

        menu.addItem(.separator())

        // Sessions submenu
        if !model.workspaces.isEmpty {
            let sessionsItem = NSMenuItem(title: "Сессии", action: nil, keyEquivalent: "")
            let sessionsSubmenu = NSMenu()
            for ws in model.workspaces {
                let countSuffix = ws.folders.count > 1 ? " (\(ws.folders.count) папок)" : ""
                let item = NSMenuItem(title: ws.name + countSuffix, action: #selector(switchWorkspaceAction(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = ws.id
                item.state = (ws.id == model.activeWorkspaceID) ? .on : .off
                sessionsSubmenu.addItem(item)
            }
            sessionsSubmenu.addItem(.separator())
            let newSessionItem = NSMenuItem(title: "Добавить сессию…", action: #selector(chooseProject), keyEquivalent: "")
            newSessionItem.target = self
            sessionsSubmenu.addItem(newSessionItem)

            sessionsItem.submenu = sessionsSubmenu
            menu.addItem(sessionsItem)
        }

        // 2. Mascot visibility toggle
        let isMascotVisible = mascotWindowController?.isVisible ?? true
        let toggleMascotTitle = isMascotVisible ? "Скрыть маскот" : "Показать маскот"
        let toggleMascotItem = NSMenuItem(title: toggleMascotTitle, action: #selector(toggleMascot), keyEquivalent: "")
        toggleMascotItem.target = self
        menu.addItem(toggleMascotItem)

        menu.addItem(.separator())

        // 3. Project & Session actions
        let chooseItem = NSMenuItem(title: "Выбрать проект…", action: #selector(chooseProject), keyEquivalent: "")
        chooseItem.target = self
        menu.addItem(chooseItem)

        let startItem = NSMenuItem(title: "Запустить / переподключить", action: #selector(startSession), keyEquivalent: "")
        startItem.target = self
        startItem.isEnabled = (model.workspace != nil)
        menu.addItem(startItem)

        let warpItem = NSMenuItem(title: "Открыть обзор в Warp", action: #selector(openWarp), keyEquivalent: "")
        warpItem.target = self
        warpItem.isEnabled = (model.workspace != nil)
        menu.addItem(warpItem)

        let terminalItem = NSMenuItem(title: "Подключиться в Terminal", action: #selector(openTerminal), keyEquivalent: "")
        terminalItem.target = self
        terminalItem.isEnabled = (model.workspace != nil)
        menu.addItem(terminalItem)

        menu.addItem(.separator())

        // 4. Stop action
        let stopItem = NSMenuItem(title: "Остановить", action: #selector(stopSession), keyEquivalent: "")
        stopItem.target = self
        stopItem.isEnabled = (model.workspace != nil)
        menu.addItem(stopItem)

        // 5. Settings
        let settingsItem = NSMenuItem(title: "Настройки…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        // 6. Terminate
        let quitItem = NSMenuItem(title: "Завершить Remote AI", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleMascot() {
        mascotWindowController?.toggle()
        rebuildMenu()
    }

    @objc private func switchWorkspaceAction(_ sender: NSMenuItem) {
        if let id = sender.representedObject as? String {
            model.selectWorkspace(id: id)
            rebuildMenu()
        }
    }

    @objc private func chooseProject() {
        model.chooseProject()
    }

    @objc private func startSession() {
        model.start()
    }

    @objc private func openWarp() {
        model.openWarp()
    }

    @objc private func openTerminal() {
        model.openTerminal()
    }

    @objc private func stopSession() {
        model.stop()
    }

    @objc private func openSettings() {
        model.showSettings()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
