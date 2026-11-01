import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section {
                TextField("Хост или SSH-псевдоним", text: $model.config.host)
                TextField("Пользователь", text: $model.config.user)
                TextField("Порт", value: $model.config.port, format: .number)
                TextField("Путь к SSH-ключу (необязательно)", text: $model.config.sshKeyPath)
                TextField("Корневая папка на сервере", text: $model.config.remoteRoot)
            } header: {
                Text("Подключение")
            } footer: {
                Text("Remote AI использует стандартную модель доверия OpenSSH. Оставьте поле ключа пустым, чтобы использовать ~/.ssh/config, ssh-agent или стандартные ключи. Для нестандартного ключа также задайте IdentityFile в ~/.ssh/config, чтобы Mutagen использовал тот же маршрут.")
            }

            Section {
                LabeledContent("Проект") {
                    Text(model.workspace?.localPath ?? "Не выбран")
                        .foregroundStyle(model.workspace == nil ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(model.workspace?.localPath ?? "Локальный проект не выбран")
                }

                Button("Выбрать проект…") { model.chooseProject() }
            } header: {
                Text("Рабочее пространство")
            } footer: {
                Text("Выбранная папка зеркалируется в отдельное рабочее пространство на сервере через безопасную двустороннюю синхронизацию Mutagen two-way-safe.")
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
                Text("Поведение")
            }

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
                    Text("Проверка подтверждает доступ к локальному проекту, SSH-маршрут, Mutagen, удалённые tmux и Claude Code без запуска рабочей сессии.")
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
                Text("Диагностика")
            } footer: {
                Text("Диагностика работает только на чтение: она не создаёт сессию Mutagen и не запускает Claude Code.")
            }

            Section {
                HStack {
                    Button("Сохранить настройки") { model.saveSettings() }
                    Spacer()
                    Button("Запустить / переподключить") { model.start() }
                        .keyboardShortcut(.defaultAction)
                }
            } footer: {
                Text("Перед изменением удалённой сессии или синхронизации Remote AI повторно выполняет те же предварительные проверки.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 620)
        .frame(minHeight: 820)
    }
}
