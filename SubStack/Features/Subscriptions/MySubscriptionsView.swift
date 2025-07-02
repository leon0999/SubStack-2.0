import SwiftUI

struct MySubscriptionsView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var selectedCategory = "전체"
    @State private var showingAddSubscription = false
    @State private var viewMode: ViewMode = .list

    enum ViewMode {
        case list, chart, calendar
    }

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
                // 동기화 상태 표시
                if subscriptionManager.isSyncing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("동기화 중...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray6))
                }

                // 뷰 모드 선택 (구독이 있을 때만 표시)
                if !subscriptionManager.subscriptions.isEmpty {
                    Picker("View", selection: $viewMode) {
                        Image(systemName: "list.bullet").tag(ViewMode.list)
                        Image(systemName: "chart.pie").tag(ViewMode.chart)
                        Image(systemName: "calendar").tag(ViewMode.calendar)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                }

                // 구독이 없을 때 빈 상태 표시
                if subscriptionManager.subscriptions.isEmpty {
                    Spacer()
                    EmptyStateView()
                    Spacer()
                } else {
                    // 뷰 모드에 따른 콘텐츠 표시
                    switch viewMode {
                    case .list:
                        // 기존 리스트 뷰
                        SubscriptionListView(
                            subscriptions: filteredSubscriptions,
                            selectedCategory: $selectedCategory,
                            categories: categories,
                            totalMonthlySpend: totalMonthlySpend,
                            onDelete: deleteSubscriptions
                        )
                    case .chart:
                        // 새로운 차트 뷰
                        SubscriptionChartView()
                            .environmentObject(subscriptionManager)
                    case .calendar:
                        // 새로운 캘린더 뷰
                        PaymentCalendarView()
                            .environmentObject(subscriptionManager)
                    }
                }
            }
            .navigationTitle("내 구독")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSubscription = true }) {
                        Image(systemName: "plus")
                    }
                }

                // 수동 동기화 버튼
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: syncSubscriptions) {
                        Image(systemName: "arrow.clockwise")
                            .opacity(subscriptionManager.isSyncing ? 0.5 : 1.0)
                    }
                    .disabled(subscriptionManager.isSyncing)
                }
            }
            .sheet(isPresented: $showingAddSubscription) {
                AddSubscriptionView()
                    .environmentObject(subscriptionManager)
            }
        }
        .onAppear {
            // 자동 동기화 (마지막 동기화로부터 5분 이상 지났을 때)
            if let lastSync = subscriptionManager.lastSyncDate,
               Date().timeIntervalSince(lastSync) > 300 {
                Task {
                    await subscriptionManager.syncWithSupabase()
                }
            }
        }
    }

    private func syncSubscriptions() {
        Task {
            await subscriptionManager.syncWithSupabase()
        }
    }

    // 삭제 함수
    private func deleteSubscriptions(at offsets: IndexSet) {
        for index in offsets {
            let subscription = filteredSubscriptions[index]
            subscriptionManager.deleteSubscription(subscription)
        }
    }
}

// 빈 상태 뷰
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

// CategoryChip과 SubscriptionRow는 SubscriptionListView.swift로 이동

struct MySubscriptionsView_Previews: PreviewProvider {
    static var previews: some View {
        MySubscriptionsView()
            .environmentObject(SubscriptionManager())
    }
}
