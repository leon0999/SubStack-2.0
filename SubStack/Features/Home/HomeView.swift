import SwiftUI

struct HomeView: View {
    @StateObject private var feedManager = SimpleFeedManager()
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedFilter = "전체"
    @State private var showingCreatePost = false

    let filters = ["전체", "OpenAI", "Claude", "Midjourney", "개발", "AI 연구"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 스크롤 가능한 콘텐츠
                ScrollView {
                    VStack(spacing: 20) {
                        // 구독 요약 헤더 (컴팩트)
                        CompactSubscriptionHeader()
                            .padding(.horizontal)
                            .padding(.top)

                        // AI 서비스 업데이트 섹션
                        VStack(alignment: .leading, spacing: 16) {
                            // 섹션 헤더
                            HStack {
                                Text("AI 서비스 업데이트")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Spacer()

                                if feedManager.hasUnreadUpdates {
                                    Label("\(unreadCount)", systemImage: "circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)

                            // 필터 칩
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(filters, id: \.self) { filter in
                                        FilterChip(
                                            title: filter,
                                            isSelected: selectedFilter == filter
                                        ) {
                                            withAnimation {
                                                selectedFilter = filter
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }

                            // 피드 카드들
                            if feedManager.isLoading && feedManager.updates.isEmpty {
                                LoadingView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 50)
                            } else if filteredUpdates.isEmpty {
                                EmptyFeedView(filter: selectedFilter)
                                    .padding()
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredUpdates.prefix(10)) { update in
                                        FeedCard(update: update)
                                            .padding(.horizontal)
                                            .onTapGesture {
                                                feedManager.markAsRead(update)
                                            }
                                    }

                                    // 더보기 버튼
                                    if filteredUpdates.count > 10 {
                                        NavigationLink(destination: SimpleFeedView()) {
                                            Text("모든 업데이트 보기")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.blue)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(12)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.bottom)

                        // 인기 포스트 섹션
                        TrendingPostsSection(showingCreatePost: $showingCreatePost)
                            .padding(.bottom, 20)
                    }
                }
                .refreshable {
                    await feedManager.refreshAllFeeds()
                }
            }
            .navigationTitle("SubStack")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(UIColor.systemGroupedBackground))
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView()
            }
        }
    }

    var filteredUpdates: [ServiceUpdate] {
        if selectedFilter == "전체" {
            return feedManager.updates
        } else if ["OpenAI", "Claude", "Midjourney"].contains(selectedFilter) {
            return feedManager.updates.filter { $0.service == selectedFilter }
        } else {
            // 카테고리로 필터링
            return feedManager.updates.filter {
                $0.service.contains(selectedFilter) ||
                $0.category.rawValue.contains(selectedFilter)
            }
        }
    }

    var unreadCount: Int {
        feedManager.updates.filter { !$0.isRead }.count
    }
}

// MARK: - 컴팩트 구독 헤더
struct CompactSubscriptionHeader: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingSubscriptions = false

    var monthlyTrend: Double {
        // TODO: 실제 트렌드 계산
        return -2.5
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("이번 달 구독료")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("₩\(subscriptionManager.totalMonthlySpend.formatted())")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                // 트렌드 인디케이터
                HStack(spacing: 8) {
                    Image(systemName: monthlyTrend > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                        .foregroundColor(monthlyTrend > 0 ? .red : .green)

                    Text("\(abs(monthlyTrend), specifier: "%.1f")%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(monthlyTrend > 0 ? .red : .green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(monthlyTrend > 0 ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                .cornerRadius(20)
            }

            // 빠른 통계
            HStack(spacing: 20) {
                QuickStat(
                    title: "활성",
                    value: "\(subscriptionManager.subscriptions.filter { $0.isActive }.count)",
                    icon: "checkmark.circle.fill",
                    color: .blue
                )

                QuickStat(
                    title: "이번 주",
                    value: "\(upcomingThisWeek)",
                    icon: "calendar",
                    color: .orange
                )

                QuickStat(
                    title: "카테고리",
                    value: "\(subscriptionManager.subscriptionsByCategory.count)",
                    icon: "square.grid.2x2",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .onTapGesture {
            showingSubscriptions = true
        }
        .sheet(isPresented: $showingSubscriptions) {
            MySubscriptionsView()
        }
    }

    var upcomingThisWeek: Int {
        subscriptionManager.upcomingPayments.filter { subscription in
            subscription.daysUntilNextPayment <= 7
        }.count
    }
}

// MARK: - 빠른 통계
struct QuickStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 필터 칩
struct FilterChip: View {
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

// MARK: - 피드 카드
struct FeedCard: View {
    let update: ServiceUpdate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Text(update.serviceIcon)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(update.service)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(update.publishedDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !update.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }

            // 제목
            Text(update.title)
                .font(.headline)
                .lineLimit(2)

            // 요약
            Text(update.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)

            // 카테고리와 중요도
            HStack {
                Label(update.category.rawValue, systemImage: update.category.icon)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(update.category.color.opacity(0.1))
                    .foregroundColor(update.category.color)
                    .cornerRadius(12)

                if update.importance == .critical {
                    Label("중요", systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Spacer()

                Button(action: {
                    if let url = URL(string: update.link) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - 빈 피드 뷰
struct EmptyFeedView: View {
    let filter: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text(filter == "전체" ? "아직 업데이트가 없습니다" : "\(filter) 관련 업데이트가 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("잠시 후 다시 확인해주세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}

// MARK: - 인기 포스트 섹션
struct TrendingPostsSection: View {
    @StateObject private var postService = PostService.shared
    @Binding var showingCreatePost: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            HStack {
                Text("커뮤니티 인기 포스트")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                NavigationLink(destination: PostFeedView()) {
                    Text("모두 보기")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            if postService.posts.isEmpty {
                // 빈 상태
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text("아직 포스트가 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button(action: { showingCreatePost = true }) {
                        Label("첫 포스트 작성하기", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal)
            } else {
                // 인기 포스트 미리보기
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(postService.posts.prefix(5)) { post in
                            NavigationLink(destination: PostFeedView()) {
                                PostPreviewCard(post: post)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - 포스트 미리보기 카드
struct PostPreviewCard: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 미디어 또는 콘텐츠 미리보기
            if let mediaURL = post.mediaURL {
                AsyncImage(url: mediaURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 150)
                        .clipped()
                        .cornerRadius(8)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 150)
                        .overlay(
                            ProgressView()
                        )
                }
            } else {
                // 텍스트만 있는 경우
                Text(post.content)
                    .font(.subheadline)
                    .lineLimit(4)
                    .frame(width: 200, height: 150)
                    .padding()
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
            }

            // 작성자와 좋아요
            HStack {
                Text(post.author?.displayName ?? "익명")
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                Label("\(post.formattedLikesCount)", systemImage: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 200)
    }
}
