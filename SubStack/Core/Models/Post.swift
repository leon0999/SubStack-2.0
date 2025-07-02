import Foundation

// MARK: - Post Model
struct Post: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let content: String
    var mediaUrl: String?
    var mediaType: MediaType?
    var likesCount: Int
    var commentsCount: Int
    let createdAt: Date
    let updatedAt: Date

    // 관계 데이터 (조인 시 포함)
    var author: User?
    var isLikedByMe: Bool = false

    // MARK: - Computed Properties

    /// 미디어가 있는지 확인
    var hasMedia: Bool {
        return mediaUrl != nil && mediaType != nil
    }

    /// 미디어 URL
    var mediaURL: URL? {
        guard let urlString = mediaUrl else { return nil }
        return URL(string: urlString)
    }

    /// 시간 표시 (1시간 전, 2일 전 등)
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// 좋아요 수 포맷팅 (1.2K, 3.4M 등)
    var formattedLikesCount: String {
        if likesCount < 1000 {
            return "\(likesCount)"
        } else if likesCount < 1_000_000 {
            return String(format: "%.1fK", Double(likesCount) / 1000)
        } else {
            return String(format: "%.1fM", Double(likesCount) / 1_000_000)
        }
    }

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case author
        case isLikedByMe = "is_liked_by_me"
    }
}

// MARK: - MediaType Enum
enum MediaType: String, Codable, CaseIterable {
    case image = "image"
    case video = "video"

    var icon: String {
        switch self {
        case .image:
            return "photo"
        case .video:
            return "video"
        }
    }

    var maxSize: Int {
        switch self {
        case .image:
            return 10 * 1024 * 1024  // 10MB
        case .video:
            return 100 * 1024 * 1024 // 100MB
        }
    }
}

// MARK: - Post Extension
extension Post {
    /// 포스트 생성 요청용 구조체
    struct CreateRequest: Encodable {
        let userId: UUID
        let content: String
        let mediaUrl: String?
        let mediaType: String?

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case content
            case mediaUrl = "media_url"
            case mediaType = "media_type"
        }
    }

    /// 업데이트 요청용 구조체
    struct UpdateRequest: Encodable {
        let content: String?
        let mediaUrl: String?
        let mediaType: String?

        enum CodingKeys: String, CodingKey {
            case content
            case mediaUrl = "media_url"
            case mediaType = "media_type"
        }
    }
}

// MARK: - Mock Data
extension Post {
    static let mockPost = Post(
        id: UUID(),
        userId: UUID(),
        content: "ChatGPT Plus를 Claude Pro로 바꿨는데 정말 만족스럽네요! 코드 작성이 훨씬 자연스러워졌어요.",
        mediaUrl: nil,
        mediaType: nil,
        likesCount: 42,
        commentsCount: 5,
        createdAt: Date().addingTimeInterval(-3600),
        updatedAt: Date().addingTimeInterval(-3600),
        author: User.mockUser,
        isLikedByMe: false
    )

    static let mockPostWithImage = Post(
        id: UUID(),
        userId: UUID(),
        content: "새로운 AI 도구들을 비교해봤습니다!",
        mediaUrl: "https://example.com/image.jpg",
        mediaType: .image,
        likesCount: 128,
        commentsCount: 23,
        createdAt: Date().addingTimeInterval(-7200),
        updatedAt: Date().addingTimeInterval(-7200),
        author: User.mockUser,
        isLikedByMe: true
    )
}
