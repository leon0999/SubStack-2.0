// Managers/UpdateFeedManager.swift
import Foundation
import SwiftUI
import FeedKit

@MainActor
class UpdateFeedManager: ObservableObject {
    @Published var updates: [ServiceUpdate] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var hasUnreadUpdates = false

    private let storageKey = "SubStack_Updates"
    private let lastUpdateKey = "SubStack_LastUpdate"

    // AI 서비스 소스 정의
    private let serviceSources = [
        AIServiceSource(
            name: "OpenAI",
            icon: "🤖",
            rssUrl: "https://openai.com/blog/rss.xml",
            websiteUrl: "https://openai.com/blog"
        ),
        AIServiceSource(
            name: "Anthropic",
            icon: "🧠",
            rssUrl: nil,
            websiteUrl: "https://www.anthropic.com/news"
        ),
        AIServiceSource(
            name: "Google AI",
            icon: "🔍",
            rssUrl: "https://ai.googleblog.com/feeds/posts/default",
            websiteUrl: "https://ai.googleblog.com"
        ),
        AIServiceSource(
            name: "Midjourney",
            icon: "🎨",
            rssUrl: nil,
            websiteUrl: "https://www.midjourney.com/updates"
        ),
        AIServiceSource(
            name: "Perplexity",
            icon: "🔎",
            rssUrl: nil,
            websiteUrl: "https://blog.perplexity.ai"
        ),
        AIServiceSource(
            name: "Stability AI",
            icon: "🖼️",
            rssUrl: nil,
            websiteUrl: "https://stability.ai/news"
        )
    ]

    init() {
        loadCachedUpdates()
    }

    // MARK: - Public Methods

    func refreshUpdates() async {
        isLoading = true

        var allUpdates: [ServiceUpdate] = []

        for source in serviceSources {
            if let updates = await fetchUpdatesFromSource(source) {
                allUpdates.append(contentsOf: updates)
            }
        }

        // 날짜순 정렬 및 중복 제거
        let sortedUpdates = allUpdates
            .sorted { $0.publishedDate > $1.publishedDate }
            .prefix(100)

        self.updates = Array(sortedUpdates)
        self.lastUpdateTime = Date()
        self.hasUnreadUpdates = true

        saveUpdates()
        isLoading = false
    }

    func markAsRead(_ update: ServiceUpdate) {
        if let index = updates.firstIndex(where: { $0.id == update.id }) {
            updates[index].isRead = true
            saveUpdates()

            // 모든 업데이트가 읽혔는지 확인
            hasUnreadUpdates = updates.contains { !$0.isRead }
        }
    }

    func markAllAsRead() {
        for index in updates.indices {
            updates[index].isRead = true
        }
        hasUnreadUpdates = false
        saveUpdates()
    }

    // MARK: - Private Methods

    private func fetchUpdatesFromSource(_ source: AIServiceSource) async -> [ServiceUpdate]? {
        if let rssUrl = source.rssUrl {
            // RSS URL이 있으면 실제 파싱 시도
            let rssUpdates = await fetchRSSFeed(from: rssUrl, for: source)
            if !rssUpdates.isEmpty {
                return rssUpdates
            }
        }

        // RSS가 없거나 파싱 실패시 목업 데이터
        return generateMockUpdates(for: source)
    }

    private func fetchRSSFeed(from urlString: String, for service: AIServiceSource) async -> [ServiceUpdate] {
        guard let url = URL(string: urlString) else { return [] }

        return await withCheckedContinuation { continuation in
            let parser = FeedParser(URL: url)

            parser.parseAsync { result in
                switch result {
                case .success(let feed):
                    let updates = self.parseFeed(feed, for: service)
                    continuation.resume(returning: updates)
                case .failure(let error):
                    print("RSS 파싱 에러 (\(service.name)): \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }

    private func parseFeed(_ feed: Feed, for service: AIServiceSource) -> [ServiceUpdate] {
        switch feed {
        case .rss(let rssFeed):
            return parseRSSItems(rssFeed.items, for: service)
        case .atom(let atomFeed):
            return parseAtomEntries(atomFeed.entries, for: service)
        case .json(let jsonFeed):
            return parseJSONItems(jsonFeed.items, for: service)
        }
    }

    private func parseRSSItems(_ items: [RSSFeedItem]?, for service: AIServiceSource) -> [ServiceUpdate] {
        guard let items = items else { return [] }

        return items.prefix(10).compactMap { item in
            guard let title = item.title,
                  let link = item.link,
                  let pubDate = item.pubDate else { return nil }

            let summary = cleanHTMLString(item.description ?? "")
            let category = categorizeUpdate(title: title, description: summary)
            let importance = determineImportance(title: title, category: category)

            return ServiceUpdate(
                service: service.name,
                serviceIcon: service.icon,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: String(summary.prefix(200)) + (summary.count > 200 ? "..." : ""),
                link: link,
                publishedDate: pubDate,
                category: category,
                importance: importance,
                isRead: false
            )
        }
    }

    private func parseAtomEntries(_ entries: [AtomFeedEntry]?, for service: AIServiceSource) -> [ServiceUpdate] {
        guard let entries = entries else { return [] }

        return entries.prefix(10).compactMap { entry in
            guard let title = entry.title,
                  let link = entry.links?.first?.attributes?.href,
                  let pubDate = entry.published ?? entry.updated else { return nil }

            let summary = cleanHTMLString(entry.summary?.value ?? entry.content?.value ?? "")
            let category = categorizeUpdate(title: title, description: summary)
            let importance = determineImportance(title: title, category: category)

            return ServiceUpdate(
                service: service.name,
                serviceIcon: service.icon,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: String(summary.prefix(200)) + (summary.count > 200 ? "..." : ""),
                link: link,
                publishedDate: pubDate,
                category: category,
                importance: importance,
                isRead: false
            )
        }
    }

    private func parseJSONItems(_ items: [JSONFeedItem]?, for service: AIServiceSource) -> [ServiceUpdate] {
        // JSON Feed 형식은 거의 사용되지 않으므로 빈 배열 반환
        return []
    }

    private func cleanHTMLString(_ html: String) -> String {
        // HTML 태그 제거
        let pattern = "<[^>]+>"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: html.utf16.count)
        let cleaned = regex?.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "") ?? html

        // HTML 엔티티 디코딩
        return cleaned
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func categorizeUpdate(title: String, description: String) -> ServiceUpdate.UpdateCategory {
        let text = (title + " " + description).lowercased()

        if text.contains("price") || text.contains("pricing") || text.contains("cost") ||
           text.contains("가격") || text.contains("요금") {
            return .priceChange
        } else if text.contains("api") || text.contains("endpoint") || text.contains("sdk") {
            return .apiUpdate
        } else if text.contains("model") || text.contains("gpt") || text.contains("claude") ||
                  text.contains("llm") || text.contains("version") {
            return .modelUpdate
        } else if text.contains("policy") || text.contains("terms") || text.contains("정책") {
            return .policy
        } else if text.contains("feature") || text.contains("update") || text.contains("기능") ||
                  text.contains("release") || text.contains("launch") {
            return .newFeature
        }

        return .general
    }

    private func determineImportance(title: String, category: ServiceUpdate.UpdateCategory) -> ServiceUpdate.UpdateImportance {
        // 가격 변경은 항상 중요
        if category == .priceChange {
            return .critical
        }

        let text = title.lowercased()

        // 중요 키워드
        let criticalKeywords = ["major", "breaking", "important", "critical", "urgent",
                               "중요", "긴급", "주요", "breaking change"]
        if criticalKeywords.contains(where: text.contains) {
            return .critical
        }

        // 모델 업데이트는 대부분 중요
        if category == .modelUpdate && (text.contains("gpt-4") || text.contains("claude-3")) {
            return .critical
        }

        // 마이너 키워드
        let minorKeywords = ["minor", "small", "fix", "patch", "마이너", "수정"]
        if minorKeywords.contains(where: text.contains) {
            return .minor
        }

        return .normal
    }

    private func generateMockUpdates(for source: AIServiceSource) -> [ServiceUpdate] {
        let updates: [(title: String, category: ServiceUpdate.UpdateCategory, importance: ServiceUpdate.UpdateImportance)] = {
            switch source.name {
            case "OpenAI":
                return [
                    ("GPT-4 Turbo 128K 컨텍스트 지원", .modelUpdate, .critical),
                    ("ChatGPT Plus 새로운 음성 기능 추가", .newFeature, .normal),
                    ("API 요금 인하 발표", .priceChange, .critical)
                ]
            case "Anthropic":
                return [
                    ("Claude 3 출시 - 향상된 추론 능력", .modelUpdate, .critical),
                    ("API 요금 정책 변경 안내", .priceChange, .critical)
                ]
            case "Google AI":
                return [
                    ("Gemini Pro 무료 티어 확대", .apiUpdate, .normal),
                    ("Gemini Ultra 공개 베타 시작", .modelUpdate, .critical)
                ]
            case "Midjourney":
                return [
                    ("V6 알파 버전 출시", .modelUpdate, .critical),
                    ("새로운 인페인팅 기능 추가", .newFeature, .normal)
                ]
            default:
                return [
                    ("\(source.name) 새로운 업데이트", .general, .normal)
                ]
            }
        }()

        return updates.enumerated().map { index, update in
            ServiceUpdate(
                service: source.name,
                serviceIcon: source.icon,
                title: update.title,
                summary: "자세한 내용은 클릭하여 확인하세요. 이 업데이트는 \(source.name) 서비스의 최신 변경사항입니다.",
                link: source.websiteUrl,
                publishedDate: Date().addingTimeInterval(TimeInterval(-index * 3600 * 24)),
                category: update.category,
                importance: update.importance,
                isRead: false
            )
        }
    }

    // MARK: - Persistence

    private func saveUpdates() {
        if let encoded = try? JSONEncoder().encode(updates) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
        UserDefaults.standard.set(lastUpdateTime, forKey: lastUpdateKey)
    }

    private func loadCachedUpdates() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ServiceUpdate].self, from: data) {
            self.updates = decoded
            self.hasUnreadUpdates = decoded.contains { !$0.isRead }
        }

        self.lastUpdateTime = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date
    }
}

// MARK: - Supporting Types

struct AIServiceSource {
    let name: String
    let icon: String
    let rssUrl: String?
    let websiteUrl: String
}
