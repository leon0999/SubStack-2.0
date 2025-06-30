import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingAddSubscription = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 메인 요약 카드
                    MainSummaryCard()

                    // 이번 주 결제 예정
                    UpcomingPaymentsSection()

                    // 카테고리별 지출 분석
                    CategorySpendingSection()

                    // AI 서비스 업데이트 피드 (Phase 2에서 구현)
                    UpdateFeedPreview()
                }
                .padding()
            }
            .navigationTitle("SubStack")
            .background(Color(UIColor.systemGroupedBackground))
            .sheet(isPresented: $showingAddSubscription) {
                AddSubscriptionView()
                    .environmentObject(subscriptionManager)
            }
        }
    }
}

// 메인 요약 카드
struct MainSummaryCard: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    var monthlyTrend: Double {
        // TODO: 실제 트렌드 계산
        return 5.2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("이번 달 AI 구독료")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("₩\(subscriptionManager.totalMonthlySpend.formatted())")
                        .font(.system(size: 36, weight: .bold))
                }

                Spacer()

                // 트렌드 인디케이터
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: monthlyTrend > 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(monthlyTrend > 0 ? .red : .green)
                    Text("\(abs(monthlyTrend), specifier: "%.1f")%")
                        .font(.caption)
                        .foregroundColor(monthlyTrend > 0 ? .red : .green)
                }
            }

            Divider()

            HStack(spacing: 20) {
                SummaryItem(
                    title: "활성 구독",
                    value: "\(subscriptionManager.subscriptions.filter { $0.isActive }.count)개",
                    icon: "creditcard.fill",
                    color: .blue
                )

                SummaryItem(
                    title: "연간 예상",
                    value: "₩\((subscriptionManager.totalMonthlySpend * 12).formatted())",
                    icon: "calendar",
                    color: .orange
                )

                SummaryItem(
                    title: "주 카테고리",
                    value: subscriptionManager.topCategory ?? "없음",
                    icon: "star.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

struct SummaryItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)

            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 이번 주 결제 예정
struct UpcomingPaymentsSection: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("이번 주 결제 예정")
                    .font(.headline)

                Spacer()

                if !subscriptionManager.upcomingPayments.isEmpty {
                    Text("총 ₩\(upcomingTotal.formatted())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if subscriptionManager.upcomingPayments.isEmpty {
                EmptyUpcomingView()
            } else {
                VStack(spacing: 8) {
                    ForEach(subscriptionManager.upcomingPayments.prefix(3)) { subscription in
                        UpcomingPaymentRow(subscription: subscription)
                    }
                }
            }
        }
    }

    var upcomingTotal: Int {
        subscriptionManager.upcomingPayments.reduce(0) { $0 + $1.price }
    }
}

struct UpcomingPaymentRow: View {
    let subscription: Subscription

    var daysText: String {
        let days = subscription.daysUntilNextPayment
        if days == 0 { return "오늘" }
        else if days == 1 { return "내일" }
        else { return "\(days)일 후" }
    }

    var urgencyColor: Color {
        let days = subscription.daysUntilNextPayment
        if days <= 1 { return .red }
        else if days <= 3 { return .orange }
        else { return .blue }
    }

    var body: some View {
        HStack {
            // 아이콘
            Text(subscription.icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(subscription.displayColor.opacity(0.1))
                .cornerRadius(8)

            // 정보
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("₩\(subscription.price.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // D-day
            Text(daysText)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(urgencyColor.opacity(0.1))
                .foregroundColor(urgencyColor)
                .cornerRadius(12)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
    }
}

struct EmptyUpcomingView: View {
    var body: some View {
        HStack {
            Image(systemName: "calendar.badge.checkmark")
                .font(.title2)
                .foregroundColor(.green)

            Text("이번 주는 결제 예정이 없습니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

// 카테고리별 지출
struct CategorySpendingSection: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("카테고리별 지출")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(Array(subscriptionManager.subscriptionsByCategory.keys.sorted()), id: \.self) { category in
                    if let subscriptions = subscriptionManager.subscriptionsByCategory[category] {
                        CategorySpendingRow(
                            category: category,
                            amount: subscriptions.reduce(0) { $0 + $1.price },
                            count: subscriptions.count,
                            percentage: calculatePercentage(for: subscriptions)
                        )
                    }
                }
            }
        }
    }

    func calculatePercentage(for subscriptions: [Subscription]) -> Double {
        let categoryTotal = subscriptions.reduce(0) { $0 + $1.price }
        let total = subscriptionManager.totalMonthlySpend
        return total > 0 ? Double(categoryTotal) / Double(total) : 0
    }
}

struct CategorySpendingRow: View {
    let category: String
    let amount: Int
    let count: Int
    let percentage: Double

    var categoryColor: Color {
        switch category {
        case "코딩": return .blue
        case "글쓰기": return .green
        case "이미지": return .purple
        case "생산성": return .orange
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 8, height: 8)

                    Text(category)
                        .font(.subheadline)

                    Text("\(count)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(4)
                }

                Spacer()

                Text("₩\(amount.formatted())")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // 프로그레스 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(categoryColor)
                        .frame(width: geometry.size.width * percentage, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
    }
}

// 업데이트 피드 미리보기 (Phase 2에서 구현)
struct UpdateFeedPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI 서비스 업데이트")
                    .font(.headline)

                Spacer()

                Text("준비 중")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }

            Text("곧 AI 서비스들의 최신 업데이트와 기능 변경사항을 확인할 수 있습니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
        }
    }
}
