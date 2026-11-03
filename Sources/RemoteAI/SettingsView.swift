import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case sessions = "Сессии"
    case connection = "Подключение"
    case diagnostics = "Диагностика"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .sessions: "folder.badge.gear"
        case .connection: "network"
        case .diagnostics: "stethoscope"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var selectedTab: SettingsTab = .sessions
    @State private var selectedSessionID: String = ""
    @State private var newSessionName: String = ""

    private var currentSession: Workspace? {
        if !selectedSessionID.isEmpty, let found = model.workspaces.first(where: { $0.id == selectedSessionID }) {
            return found
        }
        return model.workspace ?? model.workspaces.first
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Раздел", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            Form {
                switch selectedTab {
                case .sessions:
                    sessionsTab
                case .connection:
                    connectionTab
                case .diagnostics:
                    diagnosticsTab
                }

                Section {
                    HStack {
                        Button("Сохранить настройки") { model.saveSettings() }
                        Spacer()
                        Button("Запустить / переподключить") { model.start() }
                            .keyboardShortcut(.defaultAction)
                    }
                } footer: {
                    Text("Remote AI синхронизирует проект через Mutagen two-way-safe и управляет сессией Claude Code в tmux на сервере.")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 640)
        .frame(minHeight: 700)
        .onAppear {
            if let active = model.workspace {
                selectedSessionID = active.id
            } else if let first = model.workspaces.first {
                selectedSessionID = first.id
            }
        }
    }

    // MARK: - Вкладка «Сессии»
    @ViewBuilder
    private var sessionsTab: some View {
        Section {
            if model.workspaces.isEmpty {
                VStack(spacing: 12) {
                    Text("Сессии не настроены")
                        .font(.headline)
                    Text("Создайте первую сессию, выбрав папку проекта.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Выбрать проект…") {
                        model.chooseProject()
                        if let current = model.workspace {
                            selectedSessionID = current.id
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
            } else {
                HStack(spacing: 10) {
                    Picker("Сессия", selection: Binding(
                        get: {
                            if model.workspaces.contains(where: { $0.id == selectedSessionID }) {
                                return selectedSessionID
                            }
                            return model.workspace?.id ?? model.workspaces.first?.id ?? ""
                        },
                        set: { selectedSessionID = $0 }
                    )) {
                        ForEach(model.workspaces) { ws in
                            HStack {
                                Text(ws.name + (ws.id == model.activeWorkspaceID ? " ★" : ""))
                            }
                            .tag(ws.id)
                        }
                    }

                    Button("Новая…") {
                        model.chooseProject()
                        if let current = model.workspace {
                            selectedSessionID = current.id
                        }
                    }

                    if let current = currentSession, model.workspaces.count > 1 {
                        Button(role: .destructive) {
                            model.deleteWorkspace(id: current.id)
                            selectedSessionID = model.workspace?.id ?? model.workspaces.first?.id ?? ""
                        } label: {
                            Image(systemName: "trash")
                        }
                        .help("Удалить текущую сессию")
                    }
                }

                if let current = currentSession {
                    HStack {
                        TextField("Название сессии", text: Binding(
                            get: { current.name },
                            set: { model.renameWorkspace(id: current.id, newName: $0) }
                        ))

                        Spacer()

                        if current.id == model.activeWorkspaceID {
                            Label("Активная сессия", systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.green)
                        } else {
                            Button("Сделать активной") {
                                model.selectWorkspace(id: current.id)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        } header: {
            Text("Управление сессиями")
        } footer: {
            Text("Переключайтесь между сессиями проектов. Активная сессия отслеживается маскотом и доступна в Warp.")
        }

        if let current = currentSession {
            Section {
                if current.folders.isEmpty {
                    Text("В сессии пока нет папок проекта. Добавьте одну или несколько папок.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(current.folders) { folder in
                        HStack(spacing: 10) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(folder.name)
                                    .font(.body.weight(.medium))
                                Text(folder.localPath)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                model.removeFolder(from: current.id, folderID: folder.id)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                            .help("Удалить папку из сессии")
                        }
                        .padding(.vertical, 2)
                    }
                }

                Button {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.allowsMultipleSelection = true
                    panel.prompt = "Добавить в сессию"
                    if panel.runModal() == .OK {
                        for url in panel.urls {
                            model.addFolder(to: current.id, localPath: url.path)
                        }
                    }
                } label: {
                    Label("Добавить папку в проект…", systemImage: "plus.circle")
                }
            } header: {
                Text("Папки проекта в сессии (\(current.folders.count))")
            } footer: {
                Text("Все добавленные папки зеркалируются в рабочее пространство на сервере и передаются в Claude Code через аргумент --add-dir, предоставляя модели одновременный контекст всех папок проекта.")
            }
        }
    }

    // MARK: - Вкладка «Подключение»
    @ViewBuilder
    private var connectionTab: some View {
        Section {
            TextField("Хост или SSH-псевдоним", text: $model.config.host)
            TextField("Пользователь", text: $model.config.user)
            TextField("Порт", value: $model.config.port, format: .number)
            TextField("Путь к SSH-ключу (необязательно)", text: $model.config.sshKeyPath)
            TextField("Корневая папка на сервере", text: $model.config.remoteRoot)
        } header: {
            Text("Параметры SSH")
        } footer: {
            Text("Remote AI использует стандартную модель доверия OpenSSH. Оставьте поле ключа пустым, чтобы использовать ~/.ssh/config, ssh-agent или стандартные ключи. Для хоста можно указывать псевдоним из ~/.ssh/config.")
        }

        Section {
            Toggle("Уведомлять, когда Claude Code ожидает ввода", isOn: $model.config.notifyWhenWaiting)
                .controlSize(.mini)

            LabeledContent("Обновление состояния") {
                HStack(spacing: 6) {
                    TextField("", value: $model.config.pollIntervalSeconds, format: .number)
                        .frame(width: 44)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel("Интервал обновления состояния в секундах")
                    Text("с")
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
            }
        } header: {
            Text("Поведение и уведомления")
        }
    }

    // MARK: - Вкладка «Диагностика»
    @ViewBuilder
    private var diagnosticsTab: some View {
        Section {
            Button {
                model.testSetup()
            } label: {
                HStack(spacing: 8) {
                    if model.isTestingSetup {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(model.isTestingSetup ? "Проверяем настройку…" : "Проверить настройку")
                }
            }
            .disabled(model.isTestingSetup)

            if model.setupChecks.isEmpty {
                Text("Проверка подтверждает доступ к папкам активного проекта, SSH-маршрут, Mutagen, удалённые tmux и Claude Code без запуска рабочей сессии.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.setupChecks) { check in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 7) {
                            Image(systemName: check.status.systemImage)
                                .accessibilityHidden(true)
                            Text(check.title)
                            Spacer()
                            Text(check.status.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(check.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(check.title), \(check.status.label). \(check.detail)")
                }
            }
        } header: {
            Text("Диагностика активной сессии")
        } footer: {
            Text("Диагностика работает только на чтение: она проверяет готовность удалённого хоста, не создавая лишних фоновых процессов.")
        }
    }
}
