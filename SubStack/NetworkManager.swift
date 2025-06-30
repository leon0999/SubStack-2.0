import Foundation
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    private let baseURL = "https://172.30.1.62/api"

    @Published var isLoading = false
    @Published var errorMessage: String?

    // 카드 연동
    func connectCard(cardCompany: String, userId: String, password: String) async throws -> [Subscription] {
        guard let url = URL(string: "\(baseURL)/connect-card") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "cardCompany": cardCompany,
            "userId": userId,
            "password": password
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CardConnectionResponse.self, from: data)

        if response.success {
            return response.subscriptions.map { sub in
                Subscription(
                    name: sub.merchant,
                    category: sub.category,
                    price: sub.amount,
                    icon: iconForService(sub.merchant),
                    colorName: colorForCategory(sub.category),
                    billingCycle: .monthly,
                    startDate: Date(),
                    lastPaymentDate: Date()
                )
            }
        } else {
            throw NetworkError.serverError(response.message)
        }
    }

    // AI 추천 가져오기
    func getRecommendations(userProfile: UserProfile) async throws -> [Recommendation] {
        guard let url = URL(string: "\(baseURL)/recommendations") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["userProfile": userProfile.toDictionary()]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(RecommendationResponse.self, from: data)

        return response.recommendations.map { rec in
            Recommendation(
                name: rec.name,
                icon: "⚡",
                color: .blue,
                price: rec.price,
                tags: [rec.category],
                aiReason: rec.reason,
                replacing: nil,
                savings: rec.savings
            )
        }
    }

    private func iconForService(_ name: String) -> String {
        let lowercased = name.lowercased()
        if lowercased.contains("github") { return "💻" }
        if lowercased.contains("netflix") { return "🎬" }
        if lowercased.contains("spotify") { return "🎵" }
        if lowercased.contains("notion") { return "📝" }
        if lowercased.contains("chatgpt") { return "🤖" }
        if lowercased.contains("claude") { return "🧠" }
        return "📱"
    }

    private func colorForCategory(_ category: String) -> String {
        switch category {
        case "개발", "코딩": return "blue"
        case "엔터테인먼트": return "red"
        case "음악": return "green"
        case "디자인": return "purple"
        case "교육": return "orange"
        default: return "gray"
        }
    }
}

// MARK: - Error Types
enum NetworkError: LocalizedError {
    case invalidURL
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다"
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Response Models
struct CardConnectionResponse: Codable {
    let success: Bool
    let subscriptions: [DetectedSubscription]
    let message: String
}

struct DetectedSubscription: Codable {
    let merchant: String
    let amount: Int
    let frequency: String
    let category: String
}

struct RecommendationResponse: Codable {
    let recommendations: [RecommendationData]
}

struct RecommendationData: Codable {
    let id: Int
    let name: String
    let price: Int
    let category: String
    let reason: String
    let savings: Int
}

// MARK: - User Profile
struct UserProfile: Codable {
    let developerType: String
    let experienceLevel: String

    func toDictionary() -> [String: Any] {
        return [
            "developerType": developerType,
            "experienceLevel": experienceLevel
        ]
    }
}
