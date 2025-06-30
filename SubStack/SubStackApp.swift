import SwiftUI

@main
struct SubStackApp: App {
    @StateObject private var bankDataManager = BankDataManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var notificationManager = NotificationManager.shared  // 추가

    init() {
        // 알림 카테고리 설정
        NotificationManager.shared.setupNotificationCategories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bankDataManager)
                .environmentObject(subscriptionManager)
                .environmentObject(notificationManager)  // 추가
        }
    }
}
