// Views/SimpleFeedView.swift
import SwiftUI

struct SimpleFeedView: View {
    @StateObject private var feedManager = SimpleFeedManager()
    @State private var selectedUpdate: ServiceUpdate?
    @State private var showingDetail = false

    var body: some View {
        NavigationView {
            ZStack {
                // 배경색 (토스 스타일)
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // 상단 요약 카드
                        if !feedManager.updates.isEmpty {
                            SummaryCard(
                                totalUpdates: feedManager.updates.count,
                                unreadCount: feedManager.updates.filter { !$0.isRead }.count
                            )
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }

                        // 업데이트 리스트
                        LazyVStack(spacing: 0) {
                            ForEach(feedManager.updates) { update in
                                VStack(spacing: 0) {
                                    SimpleUpdateCard(
                                        update: update,
                                        onTap: {
                                            feedManager.markAsRead(update)
                                            selectedUpdate = update
                                            showingDetail = true
                                        }
                                    )

                                    // 구분선
                                    if update.id != feedManager.updates.last?.id {
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                }
                .refreshable {
                    await feedManager.refreshAllFeeds()
                }

                // 로딩 인디케이터
                if feedManager.isLoading && feedManager.updates.isEmpty {
                    ProgressView("업데이트를 불러오는 중...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .navigationTitle("AI 업데이트")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if feedManager.hasUnreadUpdates {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("모두 읽음") {
                            feedManager.markAllAsRead()
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let update = selectedUpdate {
                UpdateDetailSheet(update: update)
            }
        }
    }
}

// MARK: - Preview
struct SimpleFeedView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleFeedView()
    }
}

// MARK: - 상단 요약 카드
struct SummaryCard: View {
    let totalUpdates: Int
    let unreadCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("오늘의 AI 업데이트")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Text("\(unreadCount)")
                        .font(.system(size: 28, weight: .bold))
                    Text("개의 새 소식")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 아이콘
            Image(systemName: "bell.badge")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - 심플한 업데이트 카드 (토스 스타일)
struct SimpleUpdateCard: View {
    let update: ServiceUpdate
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                // 서비스 아이콘
                Text(update.serviceIcon)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)

                // 콘텐츠
                VStack(alignment: .leading, spacing: 6) {
                    // 서비스명과 시간
                    HStack {
                        Text(update.service)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if !update.isRead {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 5, height: 5)
                        }

                        Spacer()

                        Text(timeAgo(from: update.publishedDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // 제목
                    Text(update.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    // 카테고리
                    HStack {
                        CategoryBadge(category: update.category)

                        if update.importance == .critical {
                            Text("중요")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                        }
                    }
                }

                // 화살표
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressedButtonStyle())
    }

    func timeAgo(from date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)

        if minutes < 60 {
            return "\(minutes)분 전"
        } else if minutes < 1440 {
            return "\(minutes / 60)시간 전"
        } else {
            return "\(minutes / 1440)일 전"
        }
    }
}

// MARK: - 카테고리 배지
struct CategoryBadge: View {
    let category: ServiceUpdate.UpdateCategory

    var body: some View {
        Text(category.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(category.color.opacity(0.1))
            .foregroundColor(category.color)
            .cornerRadius(4)
    }
}

// MARK: - 상세 화면
struct UpdateDetailSheet: View {
    let update: ServiceUpdate
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 헤더
                    HStack {
                        Text(update.serviceIcon)
                            .font(.largeTitle)

                        VStack(alignment: .leading) {
                            Text(update.service)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(update.publishedDate.formatted())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    // 제목
                    Text(update.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    // 카테고리와 중요도
                    HStack {
                        CategoryBadge(category: update.category)

                        if update.importance == .critical {
                            Label("중요", systemImage: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    // 내용
                    Text(update.summary)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    // 원문 보기 버튼
                    Button(action: {
                        if let url = URL(string: update.link) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("원문 보기", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("상세 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 버튼 스타일
struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
