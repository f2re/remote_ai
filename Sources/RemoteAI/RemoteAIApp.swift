import AppKit
import SwiftUI

@main
struct RemoteAIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(model: appDelegate.model)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var mascotWindow: MascotWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        mascotWindow = MascotWindowController(model: model)
        mascotWindow?.show()
        model.requestNotificationPermission()
    }
}
