import Foundation
import UserNotifications

enum RemoteAINotification {
    static let waitingCategory = "REMOTE_AI_WAITING"
    static let workspaceIDKey = "workspaceID"
}

struct NotificationService: Sendable {
    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func notifyWaiting(workspace: Workspace, detail: String?) async {
        let content = UNMutableNotificationContent()
        content.title = "Remote AI"
        content.body = detail.map { "\(workspace.name): \($0)" } ?? "\(workspace.name): Claude Code is waiting for input."
        content.sound = .default
        content.categoryIdentifier = RemoteAINotification.waitingCategory
        content.userInfo = [RemoteAINotification.workspaceIDKey: workspace.id]

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
