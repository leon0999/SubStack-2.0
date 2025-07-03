import SwiftUI

struct SubscriptionListView: View {
    let subscriptions: [Subscription]
    @Binding var selectedCategory: String
    let categories: [String]
    let totalMonthlySpend: Int
    let onDelete: (IndexSet) -> Void

    var body: some View {
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
            if !subscriptions.isEmpty {
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
            }

            // 구독 리스트
            List {
                ForEach(subscriptions) { subscription in
                    SubscriptionRow(subscription: subscription)
                }
                .onDelete(perform: onDelete)
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
}

// MARK: - CategoryChip
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .medium : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(UIColor.tertiarySystemFill))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - SubscriptionRow
struct SubscriptionRow: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 16) {
            // 아이콘
            Text(subscription.icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(subscription.displayColor.opacity(0.1))
                .cornerRadius(10)

            // 구독 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(subscription.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(8)

                    Text(subscription.billingCycle.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 가격과 다음 결제일
            VStack(alignment: .trailing, spacing: 4) {
                Text("₩\(subscription.price.formatted())")
                    .font(.headline)
                    .fontWeight(.semibold)

                if subscription.daysUntilNextPayment <= 7 {
                    Text("\(subscription.daysUntilNextPayment)일 후")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text(subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview
struct SubscriptionListView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionListView(
            subscriptions: [
                Subscription(
                    name: "ChatGPT Plus",
                    category: "코딩",
                    price: 25000,
                    icon: "🤖",
                    colorName: "blue",
                    billingCycle: .monthly,
                    startDate: Date(),
                    lastPaymentDate: Date()
                )
            ],
            selectedCategory: .constant("전체"),
            categories: ["전체", "코딩", "글쓰기"],
            totalMonthlySpend: 25000,
            onDelete: { _ in }
        )
    }
}
