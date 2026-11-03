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
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    let model = AppModel()
    private var mascotWindow: MascotWindowController?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = self
        mascotWindow = MascotWindowController(model: model)
        mascotWindow?.show()
        statusBarController = StatusBarController(model: model, mascotWindowController: mascotWindow)
        model.requestNotificationPermission()
        model.restoreExistingSession()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        guard response.notification.request.content.categoryIdentifier == RemoteAINotification.waitingCategory else { return }

        let notificationWorkspaceID = response.notification.request.content.userInfo[RemoteAINotification.workspaceIDKey] as? String
        Task { @MainActor in
            if let notificationWorkspaceID,
               let currentWorkspace = self.model.workspace,
               notificationWorkspaceID != currentWorkspace.id {
                return
            }

            self.model.openWarp()
        }
    }
}
