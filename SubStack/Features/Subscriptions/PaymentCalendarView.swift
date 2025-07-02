import SwiftUI

struct PaymentCalendarView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false

    let calendar = Calendar.current

    var currentMonth: Date {
        calendar.dateInterval(of: .month, for: selectedDate)?.start ?? Date()
    }

    var monthDays: [Date] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }

        return monthRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 월 선택 헤더
                MonthHeader(selectedDate: $selectedDate, showingDatePicker: $showingDatePicker)
                    .padding(.horizontal)

                // 캘린더 그리드
                CalendarGrid(monthDays: monthDays)
                    .padding(.horizontal)

                // 이번 달 결제 요약
                MonthlyPaymentSummary()
                    .padding(.horizontal)

                // 결제 일정 리스트
                PaymentScheduleList(selectedDate: selectedDate)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate)
        }
    }
}

// MARK: - 월 선택 헤더
struct MonthHeader: View {
    @Binding var selectedDate: Date
    @Binding var showingDatePicker: Bool

    var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }

    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            Spacer()

            Button(action: { showingDatePicker = true }) {
                Text(monthYearFormatter.string(from: selectedDate))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }

    func previousMonth() {
        withAnimation {
            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    func nextMonth() {
        withAnimation {
            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }
    }
}

// MARK: - 캘린더 그리드
struct CalendarGrid: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    let monthDays: [Date]
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(spacing: 16) {
            // 요일 헤더
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 날짜 그리드
            LazyVGrid(columns: columns, spacing: 12) {
                // 첫 주 빈 공간
                ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                    Color.clear
                        .frame(height: 50)
                }

                // 날짜들
                ForEach(monthDays, id: \.self) { date in
                    DayCell(date: date)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    var firstWeekdayOffset: Int {
        guard let firstDay = monthDays.first else { return 0 }
        let weekday = Calendar.current.component(.weekday, from: firstDay)
        return weekday - 1
    }
}

// MARK: - 날짜 셀
struct DayCell: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    let date: Date

    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var paymentsOnDate: [Subscription] {
        subscriptionManager.subscriptions.filter { subscription in
            Calendar.current.isDate(subscription.nextBillingDate, inSameDayAs: date)
        }
    }

    var totalAmount: Int {
        paymentsOnDate.reduce(0) { $0 + $1.price }
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .medium)
                .foregroundColor(isToday ? .white : .primary)

            if !paymentsOnDate.isEmpty {
                Text("₩\(totalAmount / 1000)K")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isToday ? .white : .blue)
            }

            // 결제 개수 표시
            if paymentsOnDate.count > 1 {
                HStack(spacing: 2) {
                    ForEach(0..<min(paymentsOnDate.count, 3), id: \.self) { _ in
                        Circle()
                            .fill(isToday ? Color.white : Color.blue)
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color.blue : (paymentsOnDate.isEmpty ? Color.clear : Color.blue.opacity(0.1)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(paymentsOnDate.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 월별 결제 요약
struct MonthlyPaymentSummary: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    var monthlyPayments: [(date: Date, subscriptions: [Subscription])] {
        let grouped = Dictionary(grouping: subscriptionManager.subscriptions) { subscription in
            Calendar.current.dateComponents([.year, .month, .day], from: subscription.nextBillingDate).day ?? 0
        }

        return grouped.compactMap { (day, subscriptions) in
            guard let date = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: day)) else { return nil }
            return (date, subscriptions)
        }
        .sorted { $0.date < $1.date }
    }

    var totalMonthlyPayments: Int {
        subscriptionManager.totalMonthlySpend
    }

    var paymentDays: Int {
        Set(subscriptionManager.subscriptions.map { subscription in
            Calendar.current.component(.day, from: subscription.nextBillingDate)
        }).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("이번 달 결제 요약")
                .font(.headline)

            HStack(spacing: 20) {
                CalendarSummaryItem(
                    title: "총 결제액",
                    value: "₩\(totalMonthlyPayments.formatted())",
                    icon: "creditcard.fill",
                    color: .blue
                )

                CalendarSummaryItem(
                    title: "결제일",
                    value: "\(paymentDays)일",
                    icon: "calendar.badge.clock",
                    color: .orange
                )

                CalendarSummaryItem(
                    title: "평균",
                    value: "₩\((totalMonthlyPayments / max(paymentDays, 1)).formatted())",
                    icon: "chart.bar.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct CalendarSummaryItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 결제 일정 리스트
struct PaymentScheduleList: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    let selectedDate: Date

    var upcomingPayments: [(date: Date, subscriptions: [Subscription])] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? Date()
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.end ?? Date()

        // 이번 달의 구독 그룹화
        let grouped = Dictionary(grouping: subscriptionManager.subscriptions.filter { subscription in
            subscription.nextBillingDate >= startOfMonth && subscription.nextBillingDate < endOfMonth
        }) { subscription in
            calendar.startOfDay(for: subscription.nextBillingDate)
        }

        return grouped.map { (key, value) in (key, value) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("결제 일정")
                .font(.headline)

            if upcomingPayments.isEmpty {
                Text("이번 달 예정된 결제가 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(upcomingPayments, id: \.date) { payment in
                        PaymentDateSection(date: payment.date, subscriptions: payment.subscriptions)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct PaymentDateSection: View {
    let date: Date
    let subscriptions: [Subscription]

    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter
    }

    var totalAmount: Int {
        subscriptions.reduce(0) { $0 + $1.price }
    }

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }

    var daysText: String {
        if daysUntil == 0 { return "오늘" }
        else if daysUntil == 1 { return "내일" }
        else if daysUntil < 0 { return "지남" }
        else { return "\(daysUntil)일 후" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 날짜 헤더
            HStack {
                Text(dateFormatter.string(from: date))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(daysText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(daysUntil <= 3 ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundColor(daysUntil <= 3 ? .orange : .blue)
                    .cornerRadius(8)
            }

            // 구독 목록
            VStack(spacing: 8) {
                ForEach(subscriptions) { subscription in
                    HStack {
                        Text(subscription.icon)
                            .font(.title3)

                        Text(subscription.name)
                            .font(.caption)
                            .lineLimit(1)

                        Spacer()

                        Text("₩\(subscription.price.formatted())")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(8)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(8)

            // 일일 총액
            HStack {
                Spacer()
                Text("일일 총액: ₩\(totalAmount.formatted())")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - 날짜 선택 시트
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            DatePicker(
                "날짜 선택",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            .navigationTitle("날짜 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}
