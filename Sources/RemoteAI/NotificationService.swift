import Foundation
import UserNotifications

struct NotificationService: Sendable {
    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func notifyWaiting(projectName: String, detail: String?) async {
        let content = UNMutableNotificationContent()
        content.title = "Remote AI"
        content.body = detail.map { "\(projectName): \($0)" } ?? "\(projectName): Claude Code is waiting for input."
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
