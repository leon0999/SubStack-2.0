import SwiftUI

@main
struct SubStackApp: App {
  @StateObject private var bankDataManager = BankDataManager()
  @StateObject private var subscriptionManager = SubscriptionManager()
  @StateObject private var notificationManager = NotificationManager.shared

  init() {
    // 알림 카테고리 설정
    NotificationManager.shared.setupNotificationCategories()
  }

  var body: some Scene {
    WindowGroup {
      AuthContainerView()
        .environmentObject(bankDataManager)
        .environmentObject(subscriptionManager)
        .environmentObject(notificationManager)
    }
  }
}
