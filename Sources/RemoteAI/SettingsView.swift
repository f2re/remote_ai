import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section("Remote host") {
                TextField("Host or SSH alias", text: $model.config.host)
                TextField("User", text: $model.config.user)
                TextField("Port", value: $model.config.port, format: .number)
                TextField("SSH key", text: $model.config.sshKeyPath)
                TextField("Remote workspace root", text: $model.config.remoteRoot)
            }

            Section("Behavior") {
                Toggle("Notify when Claude waits for input", isOn: $model.config.notifyWhenWaiting)
                HStack {
                    Text("Poll every")
                    TextField("Seconds", value: $model.config.pollIntervalSeconds, format: .number)
                        .frame(width: 70)
                    Text("seconds")
                }
            }

            Section("Current project") {
                Text(model.workspace?.localPath ?? "No project selected")
                    .textSelection(.enabled)
                Button("Choose Project…") { model.chooseProject() }
            }

            HStack {
                Spacer()
                Button("Save") { model.saveSettings() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .formStyle(.grouped)
        .padding(12)
        .frame(width: 520)
    }
}
