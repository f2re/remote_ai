import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section {
                TextField("Host or SSH alias", text: $model.config.host)
                TextField("User", text: $model.config.user)
                TextField("Port", value: $model.config.port, format: .number)
                TextField("SSH key path", text: $model.config.sshKeyPath)
                TextField("Remote workspace root", text: $model.config.remoteRoot)
            } header: {
                Text("Connection")
            } footer: {
                Text("Remote AI uses your normal OpenSSH configuration and never stores Claude credentials.")
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
                Text("The selected folder is mirrored to a deterministic remote workspace with Mutagen.")
            }

            Section {
                Toggle("Notify when Claude waits for input", isOn: $model.config.notifyWhenWaiting)
                    .controlSize(.mini)

                LabeledContent("Refresh status") {
                    HStack(spacing: 6) {
                        TextField("Seconds", value: $model.config.pollIntervalSeconds, format: .number)
                            .frame(width: 64)
                            .multilineTextAlignment(.trailing)
                        Text("seconds")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Behavior")
            }

            Section {
                HStack {
                    Spacer()
                    Button("Save Configuration") { model.saveSettings() }
                        .keyboardShortcut(.defaultAction)
                }
            } footer: {
                Text("Connection settings are validated together when saved so an incomplete host or path is never used to start a remote session.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 520)
    }
}
