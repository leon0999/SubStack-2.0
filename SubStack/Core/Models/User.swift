import Foundation

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    var nickname: String
    var profileImageUrl: String?
    let authProvider: String
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Computed Properties

    /// 표시할 이름 (닉네임이 없으면 이메일 앞부분 사용)
    var displayName: String {
        if !nickname.isEmpty {
            return nickname
        }
        return email.split(separator: "@").first.map(String.init) ?? "사용자"
    }

    /// 프로필 이미지 URL (없으면 기본 이미지)
    var profileImageURL: URL? {
        if let urlString = profileImageUrl {
            return URL(string: urlString)
        }
        return nil
    }

    /// 프로필 완성도 (%)
    var profileCompleteness: Int {
        var score = 0
        if !email.isEmpty { score += 40 }
        if !nickname.isEmpty { score += 30 }
        if profileImageUrl != nil { score += 30 }
        return score
    }

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case nickname
        case profileImageUrl = "profile_image_url"
        case authProvider = "auth_provider"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Supabase Response Extension
extension User {
    /// Supabase 응답을 User 모델로 변환
    static func from(supabaseData: [String: Any]) throws -> User {
        let jsonData = try JSONSerialization.data(withJSONObject: supabaseData)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(User.self, from: jsonData)
    }
}

// MARK: - Mock Data
extension User {
    static let mockUser = User(
        id: UUID(),
        email: "test@example.com",
        nickname: "테스트유저",
        profileImageUrl: nil,
        authProvider: "email",
        createdAt: Date(),
        updatedAt: Date()
    )
}
