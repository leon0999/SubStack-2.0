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
