import AppKit
import SwiftUI
import UserNotifications

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
final class AppDelegate: NSObject, NSApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {
    let model = AppModel()
    private var mascotWindow: MascotWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = self
        mascotWindow = MascotWindowController(model: model)
        mascotWindow?.show()
        model.requestNotificationPermission()
        model.restoreExistingSession()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        guard response.notification.request.content.categoryIdentifier == RemoteAINotification.waitingCategory else { return }

        let notificationWorkspaceID = response.notification.request.content.userInfo[RemoteAINotification.workspaceIDKey] as? String
        if let notificationWorkspaceID,
           let currentWorkspace = model.workspace,
           notificationWorkspaceID != currentWorkspace.id {
            return
        }

        model.openWarp()
    }
}
