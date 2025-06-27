import SwiftUI

struct MySubscriptionsView: View {
    @State private var subscriptions: [Subscription] = Subscription.sampleData
    @State private var selectedCategory = "전체"

    let categories = ["전체", "개발", "디자인", "교육", "엔터테인먼트"]

    var filteredSubscriptions: [Subscription] {
        if selectedCategory == "전체" {
            return subscriptions
        }
        return subscriptions.filter { $0.category == selectedCategory }
    }

    var totalMonthlySpend: Int {
        filteredSubscriptions.reduce(0) { $0 + $1.price }
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

                // 구독 리스트
                List {
                    ForEach(filteredSubscriptions) { subscription in
                        SubscriptionRow(subscription: subscription)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("내 구독")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
                .fill(subscription.color.opacity(0.2))
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
                    Text("다음 결제일: \(subscription.nextBillingDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 가격
            VStack(alignment: .trailing, spacing: 4) {
                Text("₩\(subscription.price.formatted())")
                    .font(.headline)
                Text("/월")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// 데이터 모델
struct Subscription: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let price: Int
    let icon: String
    let color: Color
    let nextBillingDate: String

    static let sampleData = [
        Subscription(name: "GitHub Pro", category: "개발", price: 7000, icon: "💻", color: .black, nextBillingDate: "12월 15일"),
        Subscription(name: "ChatGPT Plus", category: "개발", price: 25000, icon: "🤖", color: .green, nextBillingDate: "12월 20일"),
        Subscription(name: "Notion", category: "개발", price: 10000, icon: "📝", color: .black, nextBillingDate: "12월 1일"),
        Subscription(name: "Figma", category: "디자인", price: 15000, icon: "🎨", color: .purple, nextBillingDate: "12월 5일"),
        Subscription(name: "Netflix", category: "엔터테인먼트", price: 17000, icon: "🎬", color: .red, nextBillingDate: "12월 10일"),
        Subscription(name: "Spotify", category: "엔터테인먼트", price: 11000, icon: "🎵", color: .green, nextBillingDate: "12월 8일"),
        Subscription(name: "인프런", category: "교육", price: 19000, icon: "📚", color: .orange, nextBillingDate: "12월 25일"),
        Subscription(name: "AWS", category: "개발", price: 45000, icon: "☁️", color: .orange, nextBillingDate: "12월 1일"),
    ]
}

struct MySubscriptionsView_Previews: PreviewProvider {
    static var previews: some View {
        MySubscriptionsView()
    }
}
