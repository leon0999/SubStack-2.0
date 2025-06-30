import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @AppStorage("notifyDaysBefore") var notifyDaysBefore = 3
    @AppStorage("notifyOnPaymentDay") var notifyOnPaymentDay = true
    @AppStorage("notificationTime") var notificationTimeString = "09:00"

    var notificationTime: DateComponents {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let date = formatter.date(from: notificationTimeString) ?? Date()
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return components
    }

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    print("알림 권한 승인됨")
                } else if let error = error {
                    print("알림 권한 오류: \(error.localizedDescription)")
                }
            }
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule Notifications

    func scheduleNotification(for subscription: Subscription) {
        guard isAuthorized else { return }

        // 기존 알림 취소
        cancelNotifications(for: subscription)

        // 결제 당일 알림
        if notifyOnPaymentDay {
            schedulePaymentDayNotification(for: subscription)
        }

        // 사전 알림 (D-3 등)
        if notifyDaysBefore > 0 {
            scheduleAdvanceNotification(for: subscription)
        }
    }

    private func schedulePaymentDayNotification(for subscription: Subscription) {
        let content = UNMutableNotificationContent()
        content.title = "💳 오늘 결제 예정"
        content.body = "\(subscription.name) ₩\(subscription.price.formatted())이 오늘 결제됩니다"
        content.sound = .default
        content.badge = 1

        // 카테고리 설정 (액션 버튼용)
        content.categoryIdentifier = "PAYMENT_NOTIFICATION"

        // 다음 결제일의 알림 시간에 발송
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: subscription.nextBillingDate)
        dateComponents.hour = notificationTime.hour
        dateComponents.minute = notificationTime.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(subscription.id.uuidString)-payment",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 등록 실패: \(error.localizedDescription)")
            }
        }
    }

    private func scheduleAdvanceNotification(for subscription: Subscription) {
        let content = UNMutableNotificationContent()
        content.title = "💡 결제 예정 알림"
        content.body = "\(subscription.name)이 \(notifyDaysBefore)일 후 결제됩니다 (₩\(subscription.price.formatted()))"
        content.sound = .default

        // D-N 날짜 계산
        guard let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -notifyDaysBefore,
            to: subscription.nextBillingDate
        ) else { return }

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = notificationTime.hour
        dateComponents.minute = notificationTime.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(subscription.id.uuidString)-advance",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel Notifications

    func cancelNotifications(for subscription: Subscription) {
        let identifiers = [
            "\(subscription.id.uuidString)-payment",
            "\(subscription.id.uuidString)-advance"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Reschedule All

    func rescheduleAllNotifications(for subscriptions: [Subscription]) {
        cancelAllNotifications()

        for subscription in subscriptions where subscription.isActive {
            scheduleNotification(for: subscription)
        }
    }

    // MARK: - Debug

    func printPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("예정된 알림: \(requests.count)개")
            for request in requests {
                print("- \(request.identifier): \(request.content.title)")
            }
        }
    }
}

// MARK: - Notification Categories
extension NotificationManager {
    func setupNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "자세히 보기",
            options: [.foreground]
        )

        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER_ACTION",
            title: "나중에 알림",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "PAYMENT_NOTIFICATION",
            actions: [viewAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
