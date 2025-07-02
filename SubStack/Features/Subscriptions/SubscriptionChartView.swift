import SwiftUI
import Charts

struct SubscriptionChartView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedTimeRange = TimeRange.month

    enum TimeRange: String, CaseIterable {
        case month = "이번 달"
        case quarter = "분기"
        case year = "연간"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 시간 범위 선택
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // 카테고리별 원형 차트
                CategoryPieChart()
                    .padding()

                // 월별 지출 트렌드
                MonthlyTrendChart()
                    .padding()

                // 상세 통계
                DetailedStatistics()
                    .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - 카테고리별 원형 차트
struct CategoryPieChart: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    var categoryData: [(category: String, amount: Int, color: Color)] {
        let categories = subscriptionManager.subscriptionsByCategory
        return categories.map { (key, subscriptions) in
            let total = subscriptions.reduce(0) { $0 + $1.price }
            let color = colorForCategory(key)
            return (key, total, color)
        }.sorted { $0.amount > $1.amount }
    }

    var totalAmount: Int {
        categoryData.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("카테고리별 지출")
                .font(.headline)

            if #available(iOS 16.0, *) {
                // iOS 16+ Chart 사용
                Chart(categoryData, id: \.category) { data in
                    SectorMark(
                        angle: .value("Amount", data.amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(data.color)
                    .cornerRadius(4)
                }
                .frame(height: 250)

                // 범례
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(categoryData, id: \.category) { data in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(data.color)
                                .frame(width: 12, height: 12)

                            Text(data.category)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("₩\(data.amount.formatted())")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text("\(Int(Double(data.amount) / Double(totalAmount) * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            } else {
                // iOS 15 이하 - 심플한 막대 차트
                VStack(spacing: 12) {
                    ForEach(categoryData, id: \.category) { data in
                        HStack {
                            Circle()
                                .fill(data.color)
                                .frame(width: 12, height: 12)

                            Text(data.category)
                                .font(.subheadline)
                                .frame(width: 80, alignment: .leading)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color(UIColor.systemGray5))
                                        .frame(height: 24)
                                        .cornerRadius(4)

                                    Rectangle()
                                        .fill(data.color)
                                        .frame(
                                            width: geometry.size.width * (Double(data.amount) / Double(totalAmount)),
                                            height: 24
                                        )
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 24)

                            Text("₩\(data.amount.formatted())")
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    func colorForCategory(_ category: String) -> Color {
        switch category {
        case "코딩": return .blue
        case "글쓰기": return .green
        case "이미지": return .purple
        case "비디오": return .orange
        case "생산성": return .pink
        case "리서치": return .indigo
        default: return .gray
        }
    }
}

// MARK: - 월별 트렌드 차트
struct MonthlyTrendChart: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    // 더미 데이터 (실제로는 계산 필요)
    let monthlyData = [
        ("1월", 280000),
        ("2월", 295000),
        ("3월", 310000),
        ("4월", 305000),
        ("5월", 320000),
        ("6월", 315000)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("월별 지출 트렌드")
                .font(.headline)

            if #available(iOS 16.0, *) {
                Chart(monthlyData, id: \.0) { data in
                    LineMark(
                        x: .value("Month", data.0),
                        y: .value("Amount", data.1)
                    )
                    .foregroundStyle(Color.blue)
                    .symbol(.circle)

                    AreaMark(
                        x: .value("Month", data.0),
                        y: .value("Amount", data.1)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
            } else {
                // iOS 15 이하 - 간단한 선 그래프
                GeometryReader { geometry in
                    ZStack {
                        // 그리드
                        ForEach(0..<5) { i in
                            Path { path in
                                let y = geometry.size.height * CGFloat(i) / 4
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                            }
                            .stroke(Color(UIColor.systemGray5), lineWidth: 0.5)
                        }

                        // 선 그래프
                        Path { path in
                            for (index, data) in monthlyData.enumerated() {
                                let x = geometry.size.width * CGFloat(index) / CGFloat(monthlyData.count - 1)
                                let y = geometry.size.height * (1 - CGFloat(data.1 - 250000) / 100000)

                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.blue, lineWidth: 2)

                        // 데이터 포인트
                        ForEach(0..<monthlyData.count, id: \.self) { index in
                            let data = monthlyData[index]
                            let x = geometry.size.width * CGFloat(index) / CGFloat(monthlyData.count - 1)
                            let y = geometry.size.height * (1 - CGFloat(data.1 - 250000) / 100000)

                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                    }
                }
                .frame(height: 200)

                // X축 레이블
                HStack {
                    ForEach(monthlyData, id: \.0) { data in
                        Text(data.0)
                            .font(.caption2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 상세 통계
struct DetailedStatistics: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    var averageSubscriptionCost: Int {
        let activeSubscriptions = subscriptionManager.subscriptions.filter { $0.isActive }
        guard !activeSubscriptions.isEmpty else { return 0 }
        return subscriptionManager.totalMonthlySpend / activeSubscriptions.count
    }

    var mostExpensiveCategory: String {
        let categories = subscriptionManager.subscriptionsByCategory
        let categoryCosts = categories.mapValues { subscriptions in
            subscriptions.reduce(0) { $0 + $1.price }
        }
        return categoryCosts.max(by: { $0.value < $1.value })?.key ?? "없음"
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("상세 통계")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    title: "평균 구독료",
                    value: "₩\(averageSubscriptionCost.formatted())",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )

                StatCard(
                    title: "연간 예상",
                    value: "₩\(subscriptionManager.totalYearlySpend.formatted())",
                    icon: "calendar",
                    color: .green
                )

                StatCard(
                    title: "최고 지출 카테고리",
                    value: mostExpensiveCategory,
                    icon: "crown.fill",
                    color: .orange
                )

                StatCard(
                    title: "활성 구독",
                    value: "\(subscriptionManager.subscriptions.filter { $0.isActive }.count)개",
                    icon: "checkmark.circle.fill",
                    color: .purple
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
