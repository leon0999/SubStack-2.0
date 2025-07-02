// Core/Managers/SimpleFeedManager+Extensions.swift
import Foundation
import SwiftUI

// MARK: - SimpleFeedManager Extensions
extension SimpleFeedManager {

    // MARK: - 실시간 업데이트
    private static var updateTimer: Timer?

    /// 실시간 업데이트 시작 (5분마다)
    func startRealtimeUpdates() {
        // 기존 타이머 정리
        stopRealtimeUpdates()

        // 메인 스레드에서 타이머 실행
        DispatchQueue.main.async {
            Self.updateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
                Task {
                    await self.refreshAllFeeds()
                    print("🔄 실시간 피드 업데이트 완료")
                }
            }

            // 즉시 한 번 실행
            Task {
                await self.refreshAllFeeds()
            }
        }

        print("⏰ 실시간 업데이트 시작됨 (5분 간격)")
    }

    /// 실시간 업데이트 중지
    func stopRealtimeUpdates() {
        Self.updateTimer?.invalidate()
        Self.updateTimer = nil
        print("⏹ 실시간 업데이트 중지됨")
    }

    // MARK: - 필터링 기능

    /// 서비스별 필터링
    func filterByService(_ service: String) -> [ServiceUpdate] {
        if service == "전체" {
            return updates
        }
        return updates.filter { $0.service == service }
    }

    /// 카테고리별 필터링
    func filterByCategory(_ category: ServiceUpdate.UpdateCategory) -> [ServiceUpdate] {
        return updates.filter { $0.category == category }
    }

    /// 중요도별 필터링
    func filterByImportance(_ importance: ServiceUpdate.UpdateImportance) -> [ServiceUpdate] {
        return updates.filter { $0.importance == importance }
    }

    /// 읽지 않은 업데이트만 필터링
    func unreadUpdates() -> [ServiceUpdate] {
        return updates.filter { !$0.isRead }
    }

    /// 날짜 범위로 필터링
    func filterByDateRange(from startDate: Date, to endDate: Date) -> [ServiceUpdate] {
        return updates.filter { update in
            update.publishedDate >= startDate && update.publishedDate <= endDate
        }
    }

    /// 복합 필터링
    func filterUpdates(
        service: String? = nil,
        category: ServiceUpdate.UpdateCategory? = nil,
        importance: ServiceUpdate.UpdateImportance? = nil,
        unreadOnly: Bool = false
    ) -> [ServiceUpdate] {
        var filtered = updates

        if let service = service, service != "전체" {
            filtered = filtered.filter { $0.service == service }
        }

        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }

        if let importance = importance {
            filtered = filtered.filter { $0.importance == importance }
        }

        if unreadOnly {
            filtered = filtered.filter { !$0.isRead }
        }

        return filtered
    }

    // MARK: - 소셜 미디어 통합 (Phase 3)

    /// 소셜 미디어 컨텐츠 가져오기
    func fetchSocialContent() async {
        print("🌐 소셜 미디어 컨텐츠 가져오기 시작...")

        // 병렬로 여러 소스에서 데이터 가져오기
        await withTaskGroup(of: [ServiceUpdate]?.self) { group in
            // X (Twitter) 콘텐츠
            group.addTask {
                await self.fetchXContent()
            }

            // Reddit 콘텐츠
            group.addTask {
                await self.fetchRedditContent()
            }

            // YouTube 콘텐츠
            group.addTask {
                await self.fetchYouTubeContent()
            }

            // 결과 수집
            var newUpdates: [ServiceUpdate] = []
            for await result in group {
                if let updates = result {
                    newUpdates.append(contentsOf: updates)
                }
            }

            // 기존 업데이트와 병합
            // mergeUpdates가 private이므로 직접 구현
            await MainActor.run {
                var merged = self.updates

                for update in newUpdates {
                    // 링크로 중복 체크
                    if !merged.contains(where: { $0.link == update.link }) {
                        merged.append(update)
                    }
                }

                // 날짜순 정렬
                merged.sort { $0.publishedDate > $1.publishedDate }

                // 최대 100개까지만 유지
                self.updates = Array(merged.prefix(100))

                // 읽지 않은 업데이트 확인
                self.hasUnreadUpdates = self.updates.contains { !$0.isRead }

                // 로컬에 저장
                self.saveUpdates()
            }
        }
    }

    /// X (Twitter) 콘텐츠 가져오기
    private func fetchXContent() async -> [ServiceUpdate]? {
        // TODO: X API 구현 (API 키 필요)
        // 임시 더미 데이터
        return [
            ServiceUpdate(
                service: "X",
                serviceIcon: "🐦",
                title: "OpenAI DevDay 2025 발표",
                summary: "GPT-5 프리뷰와 새로운 API 기능이 공개되었습니다.",
                link: "https://x.com/openai",
                publishedDate: Date().addingTimeInterval(-3600),
                category: .newFeature,
                importance: .critical,
                isRead: false
            )
        ]
    }

    /// Reddit 콘텐츠 가져오기
    private func fetchRedditContent() async -> [ServiceUpdate]? {
        // 실제 Reddit RSS 파싱을 위해 parseRSSFeed 기능 복사
        let additionalSubreddits = [
            RSSSource(name: "Reddit AI", icon: "🤖", url: "https://www.reddit.com/r/artificial/.rss", category: "AI 커뮤니티"),
            RSSSource(name: "Reddit OpenAI", icon: "🤖", url: "https://www.reddit.com/r/OpenAI/.rss", category: "AI 커뮤니티"),
            RSSSource(name: "Reddit LocalLLaMA", icon: "🤖", url: "https://www.reddit.com/r/LocalLLaMA/.rss", category: "AI 커뮤니티")
        ]

        var redditUpdates: [ServiceUpdate] = []

        for source in additionalSubreddits {
            // parseRSSFeed가 private이므로 직접 구현
            guard let url = URL(string: source.url) else { continue }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let parser = SimpleRSSParser()
                let items = parser.parse(data: data)

                let updates = items.prefix(5).map { item in
                    ServiceUpdate(
                        service: source.name,
                        serviceIcon: source.icon,
                        title: item.title,
                        summary: self.cleanHTML(item.description),
                        link: item.link,
                        publishedDate: item.pubDate ?? Date(),
                        category: self.categorizeUpdate(item.title),
                        importance: .normal,
                        isRead: false
                    )
                }

                redditUpdates.append(contentsOf: updates)
            } catch {
                print("RSS 파싱 에러 (\(source.name)): \(error)")
            }
        }

        return redditUpdates
    }

    /// YouTube 콘텐츠 가져오기
    private func fetchYouTubeContent() async -> [ServiceUpdate]? {
        // TODO: YouTube Data API 구현 (API 키 필요)
        // 임시 더미 데이터
        return [
            ServiceUpdate(
                service: "YouTube",
                serviceIcon: "📺",
                title: "Two Minute Papers: 새로운 AI 논문 리뷰",
                summary: "최신 Diffusion 모델 개선 논문을 다룹니다.",
                link: "https://youtube.com",
                publishedDate: Date().addingTimeInterval(-7200),
                category: .general,
                importance: .normal,
                isRead: false
            )
        ]
    }

    // MARK: - Helper Methods (SimpleFeedManager에서 private으로 선언된 메서드들)

    private func cleanHTML(_ html: String) -> String {
        let pattern = "<[^>]+>"
        let cleaned = html.replacingOccurrences(
            of: pattern,
            with: "",
            options: .regularExpression
        )
        return String(cleaned.prefix(200))
    }

    private func categorizeUpdate(_ title: String) -> ServiceUpdate.UpdateCategory {
        let lower = title.lowercased()

        if lower.contains("price") || lower.contains("pricing") {
            return .priceChange
        } else if lower.contains("api") {
            return .apiUpdate
        } else if lower.contains("model") || lower.contains("gpt") {
            return .modelUpdate
        } else if lower.contains("feature") || lower.contains("update") {
            return .newFeature
        }

        return .general
    }

    private func saveUpdates() {
        if let encoded = try? JSONEncoder().encode(updates) {
            UserDefaults.standard.set(encoded, forKey: "SimpleFeedUpdates")
        }
    }

    // MARK: - 통계 기능

    /// 서비스별 업데이트 수
    func updateCountByService() -> [String: Int] {
        let grouped = Dictionary(grouping: updates) { $0.service }
        return grouped.mapValues { $0.count }
    }

    /// 카테고리별 업데이트 수
    func updateCountByCategory() -> [ServiceUpdate.UpdateCategory: Int] {
        let grouped = Dictionary(grouping: updates) { $0.category }
        return grouped.mapValues { $0.count }
    }

    /// 오늘의 업데이트
    func todayUpdates() -> [ServiceUpdate] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return updates.filter { update in
            calendar.isDate(update.publishedDate, inSameDayAs: today)
        }
    }

    /// 이번 주 업데이트
    func thisWeekUpdates() -> [ServiceUpdate] {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            return []
        }

        return updates.filter { update in
            update.publishedDate >= weekAgo
        }
    }

    // MARK: - 검색 기능

    /// 텍스트 검색
    func searchUpdates(query: String) -> [ServiceUpdate] {
        let lowercasedQuery = query.lowercased()

        return updates.filter { update in
            update.title.lowercased().contains(lowercasedQuery) ||
            update.summary.lowercased().contains(lowercasedQuery) ||
            update.service.lowercased().contains(lowercasedQuery)
        }
    }

    // MARK: - 알림 기능

    /// 중요 업데이트 알림
    func checkForCriticalUpdates() {
        let criticalUnread = updates.filter {
            $0.importance == .critical && !$0.isRead
        }

        if !criticalUnread.isEmpty {
            // 로컬 알림 발송
            sendLocalNotification(
                title: "중요 AI 업데이트",
                body: "\(criticalUnread.count)개의 중요한 업데이트가 있습니다.",
                badge: criticalUnread.count
            )
        }
    }

    private func sendLocalNotification(title: String, body: String, badge: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.badge = NSNumber(value: badge)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "ai-update-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - 추가 데이터 모델
extension SimpleFeedManager {
    /// 피드 소스 타입
    enum FeedSourceType: String, CaseIterable {
        case rss = "RSS"
        case twitter = "X"
        case reddit = "Reddit"
        case youtube = "YouTube"
        case manual = "Manual"

        var icon: String {
            switch self {
            case .rss: return "📡"
            case .twitter: return "🐦"
            case .reddit: return "🤖"
            case .youtube: return "📺"
            case .manual: return "✏️"
            }
        }
    }

    /// 피드 통계
    struct FeedStatistics {
        let totalUpdates: Int
        let unreadCount: Int
        let todayCount: Int
        let criticalCount: Int
        let byService: [String: Int]
        let byCategory: [ServiceUpdate.UpdateCategory: Int]
    }

    /// 현재 피드 통계 가져오기
    func getStatistics() -> FeedStatistics {
        FeedStatistics(
            totalUpdates: updates.count,
            unreadCount: unreadUpdates().count,
            todayCount: todayUpdates().count,
            criticalCount: updates.filter { $0.importance == .critical }.count,
            byService: updateCountByService(),
            byCategory: updateCountByCategory()
        )
    }
}
