import Foundation
import SwiftUI

@MainActor
class SubscriptionManager: ObservableObject {
  @Published var subscriptions: [Subscription] = []
  @Published var isLoading = false
  @Published var error: String?

  // UserDefaults 키
  private let storageKey = "SubStack_Subscriptions"

  init() {
    loadSubscriptions()
  }

  // MARK: - CRUD Operations

  func addSubscription(name: String, category: String, price: Int, billingCycle: BillingCycle, startDate: Date) {
      let newSubscription = Subscription(
          id: UUID(),
          name: name,
          category: category,
          price: price,
          icon: iconForService(name),
          colorName: colorForCategory(category),
          billingCycle: billingCycle,
          startDate: startDate,
          lastPaymentDate: startDate,
          isActive: true
      )

      subscriptions.append(newSubscription)
      saveSubscriptions()

      // 알림 설정
      NotificationManager.shared.scheduleNotification(for: newSubscription)
  }

  func updateSubscription(_ subscription: Subscription) {
    if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
      subscriptions[index] = subscription
      saveSubscriptions()
    }
  }

  func deleteSubscription(_ subscription: Subscription) {
      subscriptions.removeAll { $0.id == subscription.id }
      saveSubscriptions()

      // 알림 취소
      NotificationManager.shared.cancelNotifications(for: subscription)
  }

  // MARK: - Persistence

  private func saveSubscriptions() {
    if let encoded = try? JSONEncoder().encode(subscriptions) {
      UserDefaults.standard.set(encoded, forKey: storageKey)
    }
  }

  private func loadSubscriptions() {
    guard let data = UserDefaults.standard.data(forKey: storageKey),
          let decoded = try? JSONDecoder().decode([Subscription].self, from: data) else {
      // 초기 데이터 로드
      loadInitialData()
      return
    }
    subscriptions = decoded
  }

  // MARK: - Helper Methods

  private func iconForService(_ name: String) -> String {
    let lowercased = name.lowercased()
    if lowercased.contains("chatgpt") || lowercased.contains("openai") { return "🤖" }
    if lowercased.contains("claude") { return "🧠" }
    if lowercased.contains("midjourney") { return "🎨" }
    if lowercased.contains("github") { return "💻" }
    if lowercased.contains("notion") { return "📝" }
    if lowercased.contains("cursor") { return "⚡" }
    return "📱"
  }

  private func colorForCategory(_ category: String) -> String {
    switch category {
    case "코딩": return "blue"
    case "글쓰기": return "green"
    case "이미지": return "purple"
    case "생산성": return "orange"
    default: return "gray"
    }
  }

  // MARK: - Notifications

  private func scheduleNotification(for subscription: Subscription) {
    // TODO: 알림 구현
  }

  private func cancelNotification(for subscription: Subscription) {
    // TODO: 알림 취소 구현
  }

  // MARK: - Analytics

  var totalMonthlySpend: Int {
    subscriptions
      .filter { $0.isActive }
      .reduce(0) { total, subscription in
        switch subscription.billingCycle {
        case .monthly:
          return total + subscription.price
        case .yearly:
          return total + (subscription.price / 12)
        case .weekly:
          return total + (subscription.price * 4)
        }
      }
  }

  var subscriptionsByCategory: [String: [Subscription]] {
    Dictionary(grouping: subscriptions.filter { $0.isActive }, by: { $0.category })
  }

  var upcomingPayments: [Subscription] {
    subscriptions
      .filter { $0.isActive && $0.daysUntilNextPayment <= 7 }
      .sorted { $0.nextBillingDate < $1.nextBillingDate }
  }

  // MARK: - Initial Data

  // SubscriptionManager.swift의 loadInitialData 메서드
  private func loadInitialData() {
    // 테스트용 초기 데이터
    subscriptions = [
      Subscription(
        name: "ChatGPT Plus",
        category: "개발",
        price: 25000,
        icon: "🤖",
        colorName: "green",
        billingCycle: .monthly,
        startDate: Date().addingTimeInterval(-30*24*60*60),
        lastPaymentDate: Date().addingTimeInterval(-5*24*60*60)
      ),
      Subscription(
        name: "GitHub Copilot",
        category: "개발",
        price: 13000,
        icon: "💻",
        colorName: "black",
        billingCycle: .monthly,
        startDate: Date().addingTimeInterval(-60*24*60*60),
        lastPaymentDate: Date().addingTimeInterval(-10*24*60*60)
      )
    ]
  }
}
extension SubscriptionManager {
    var topCategory: String? {
        let categoryCounts = subscriptionsByCategory.mapValues { $0.count }
        return categoryCounts.max(by: { $0.value < $1.value })?.key
    }
}
