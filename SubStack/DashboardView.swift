import SwiftUI

struct DashboardView: View {
    @State private var totalMonthlySpend = 287000
    @State private var subscriptionCount = 15
    @State private var monthlyChange = 45000

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 메인 카드
                    MainSpendCard(
                        totalSpend: totalMonthlySpend,
                        change: monthlyChange,
                        subscriptionCount: subscriptionCount
                    )

                    // 빠른 인사이트
                    QuickInsightsSection()

                    // 이번 주 추천
                    WeeklyRecommendationCard()
                }
                .padding()
            }
            .navigationTitle("SubStack")
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

struct MainSpendCard: View {
    let totalSpend: Int
    let change: Int
    let subscriptionCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("이번 달 구독료")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("₩\(totalSpend.formatted())")
                .font(.system(size: 36, weight: .bold))

            HStack {
                Label("\(change > 0 ? "+" : "")₩\(abs(change).formatted())",
                      systemImage: change > 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(change > 0 ? .red : .green)
                    .font(.footnote)

                Spacer()

                Text("\(subscriptionCount)개 구독 중")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

struct QuickInsightsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("빠른 인사이트")
                .font(.headline)

            InsightRow(
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                title: "중복 기능 발견",
                subtitle: "Notion과 Obsidian을 모두 구독 중"
            )

            InsightRow(
                icon: "lightbulb.fill",
                iconColor: .yellow,
                title: "절약 가능",
                subtitle: "연간 플랜으로 ₩156,000 절약 가능"
            )
        }
    }
}

struct InsightRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
    }
}

struct WeeklyRecommendationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔥 이번 주 핫한 툴")
                    .font(.headline)
                Spacer()
                Text("더보기")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Cursor Editor")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("AI 기반 코드 에디터가 VS Code를 대체할까?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
