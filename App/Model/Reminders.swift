import Foundation
import UserNotifications

enum Reminders {
    static let id = "daily-study"

    static func requestAndSchedule(hour: Int, minute: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return false }
        schedule(hour: hour, minute: minute)
        return true
    }

    static func schedule(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Word Partners"
        content.body = "Пара минут на выражения: повторения ждут."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: minute), repeats: true)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
