import SwiftUI

struct MySubscriptionsView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var selectedCategory = "전체"
    @State private var showingAddSubscription = false  // 추가

    let categories = ["전체", "코딩", "글쓰기", "이미지", "생산성", "기타"]

    var filteredSubscriptions: [Subscription] {
        if selectedCategory == "전체" {
            return subscriptionManager.subscriptions.filter { $0.isActive }
        }
        return subscriptionManager.subscriptions.filter { $0.isActive && $0.category == selectedCategory }
    }

    var totalMonthlySpend: Int {
        subscriptionManager.totalMonthlySpend
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 카테고리 필터
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding()
                }

                // 총액 표시
                HStack {
                    Text("월 총액")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("₩\(totalMonthlySpend.formatted())")
                        .font(.headline)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                // 구독 리스트 또는 빈 상태
                if filteredSubscriptions.isEmpty {
                    EmptyStateView()  // 추가
                } else {
                    List {
                        ForEach(filteredSubscriptions) { subscription in
                            SubscriptionRow(subscription: subscription)
                        }
                        .onDelete { indexSet in  // 추가
                            deleteSubscriptions(at: indexSet)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("내 구독")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {  // 추가
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSubscription = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSubscription) {  // 추가
                AddSubscriptionView()
                    .environmentObject(subscriptionManager)
            }
        }
    }

    // 삭제 함수 추가
    private func deleteSubscriptions(at offsets: IndexSet) {
        for index in offsets {
            let subscription = filteredSubscriptions[index]
            subscriptionManager.deleteSubscription(subscription)
        }
    }
}

// 빈 상태 뷰 추가
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("아직 추가된 구독이 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("AI 서비스를 추가하고\n비용을 관리해보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
          HStack(spacing: 4) {
              if let icon = icon {  // 👈 아이콘이 있으면 표시
                  Image(systemName: icon)
                      .font(.caption)
              }
              Text(title)
          }
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(UIColor.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct SubscriptionRow: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 12) {
            // 아이콘
            RoundedRectangle(cornerRadius: 12)
                .fill(subscription.displayColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(subscription.icon)
                        .font(.title2)
                )

            // 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                HStack {
                    Text(subscription.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("다음 결제일: \(subscription.nextBillingDateString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 가격
            VStack(alignment: .trailing, spacing: 4) {
                Text("₩\(subscription.price.formatted())")
                    .font(.headline)
                Text("/\(subscription.billingCycle.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MySubscriptionsView_Previews: PreviewProvider {
    static var previews: some View {
        MySubscriptionsView()
            .environmentObject(SubscriptionManager())
    }
}
