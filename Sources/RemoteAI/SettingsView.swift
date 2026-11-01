import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section {
                TextField("Host or SSH alias", text: $model.config.host)
                TextField("User", text: $model.config.user)
                TextField("Port", value: $model.config.port, format: .number)
                TextField("SSH key path (optional)", text: $model.config.sshKeyPath)
                TextField("Remote workspace root", text: $model.config.remoteRoot)
            } header: {
                Text("Connection")
            } footer: {
                Text("Remote AI uses normal OpenSSH trust. Leave the key field empty to use ~/.ssh/config, ssh-agent, or default identities. For a non-default key, also configure IdentityFile in ~/.ssh/config so Mutagen follows the same route.")
            }

            Section {
                LabeledContent("Project") {
                    Text(model.workspace?.localPath ?? "Not selected")
                        .foregroundStyle(model.workspace == nil ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(model.workspace?.localPath ?? "No local project selected")
                }

                Button("Choose Project…") { model.chooseProject() }
            } header: {
                Text("Workspace")
            } footer: {
                Text("The selected folder is mirrored to a route-scoped remote workspace with Mutagen two-way-safe synchronization.")
            }

            Section {
                Toggle("Notify when Claude waits for input", isOn: $model.config.notifyWhenWaiting)
                    .controlSize(.mini)

                LabeledContent("Refresh status") {
                    HStack(spacing: 6) {
                        TextField("", value: $model.config.pollIntervalSeconds, format: .number)
                            .frame(width: 44)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Refresh interval in seconds")
                        Text("seconds")
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }
                }
            } header: {
                Text("Behavior")
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
                        Text(model.isTestingSetup ? "Testing Setup…" : "Test Setup")
                    }
                }
                .disabled(model.isTestingSetup)

                if model.setupChecks.isEmpty {
                    Text("Run Test Setup to verify the local project, SSH route, Mutagen, remote tmux, and Claude Code without starting a session.")
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
                Text("Diagnostics")
            } footer: {
                Text("Diagnostics are read-only: they do not create a Mutagen session or start Claude Code.")
            }

            Section {
                HStack {
                    Button("Save Configuration") { model.saveSettings() }
                    Spacer()
                    Button("Start / Reconnect") { model.start() }
                        .keyboardShortcut(.defaultAction)
                }
            } footer: {
                Text("Start / Reconnect runs the same preflight checks before changing any remote or synchronization state.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 560)
        .frame(minHeight: 760)
    }
}
