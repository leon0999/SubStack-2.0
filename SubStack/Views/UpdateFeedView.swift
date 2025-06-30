// Views/UpdateFeedView.swift
import SwiftUI

struct UpdateFeedView: View {
    @StateObject private var feedManager = UpdateFeedManager()
    @State private var selectedCategory: String = "전체"
    @State private var showingDetail = false
    @State private var selectedUpdate: ServiceUpdate?

    var filteredUpdates: [ServiceUpdate] {
        if selectedCategory == "전체" {
            return feedManager.updates
        }
        return feedManager.updates.filter { $0.category.rawValue == selectedCategory }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // 카테고리 필터
                        CategoryFilterView(selectedCategory: $selectedCategory)
                            .padding(.horizontal)

                        // 업데이트 카드들
                        if feedManager.isLoading && feedManager.updates.isEmpty {
                            LoadingView()
                                .padding(.top, 100)
                        } else if filteredUpdates.isEmpty {
                            UpdateEmptyStateView(category: selectedCategory)
                                .padding(.top, 100)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredUpdates) { update in
                                    UpdateCard(update: update)
                                        .onTapGesture {
                                            feedManager.markAsRead(update)
                                            selectedUpdate = update
                                            showingDetail = true
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await feedManager.refreshUpdates()
                }
            }
            .navigationTitle("AI 서비스 업데이트")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let lastUpdate = feedManager.lastUpdateTime {
                        Text(lastUpdate.timeAgoDisplay())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let update = selectedUpdate {
                    UpdateDetailView(update: update)
                }
            }
            .task {
                if feedManager.updates.isEmpty {
                    await feedManager.refreshUpdates()
                }
            }
        }
    }
}

// 카테고리 필터 뷰
struct CategoryFilterView: View {
    @Binding var selectedCategory: String

    let categories = ["전체"] + ServiceUpdate.UpdateCategory.allCases.map { $0.rawValue }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: selectedCategory == category,
                        icon: iconForCategory(category)
                    ) {
                        withAnimation(.spring()) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }

    private func iconForCategory(_ category: String) -> String? {
        guard category != "전체" else { return nil }
        return ServiceUpdate.UpdateCategory(rawValue: category)?.icon
    }
}

// 업데이트 카드
struct UpdateCard: View {
    let update: ServiceUpdate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Text(update.serviceIcon)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(update.service)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text(update.publishedDate.timeAgoDisplay())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 중요도 표시
                if update.importance == .critical {
                    Label("중요", systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // 읽음 표시
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
                .foregroundColor(.primary)

            // 요약
            Text(update.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)

            // 카테고리 태그
            HStack {
                Label(update.category.rawValue, systemImage: update.category.icon)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(update.category.color.opacity(0.15))
                    .foregroundColor(update.category.color)
                    .cornerRadius(12)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// Date Extension for time ago
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

