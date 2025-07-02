import Foundation

// MARK: - Comment Model
struct Comment: Identifiable, Codable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let content: String
    let createdAt: Date
    let updatedAt: Date

    // 관계 데이터
    var author: User?

    // MARK: - Computed Properties

    /// 시간 표시
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// 댓글 내용 미리보기 (최대 100자)
    var preview: String {
        if content.count > 100 {
            return String(content.prefix(100)) + "..."
        }
        return content
    }

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case author
    }
}

// MARK: - Comment Extension
extension Comment {
    /// 댓글 생성 요청용 구조체
    struct CreateRequest: Encodable {
        let postId: UUID
        let userId: UUID
        let content: String

        enum CodingKeys: String, CodingKey {
            case postId = "post_id"
            case userId = "user_id"
            case content
        }
    }
}

// MARK: - Like Model (추가)
struct Like: Codable {
    let userId: UUID
    let postId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case postId = "post_id"
        case createdAt = "created_at"
    }
}

// MARK: - PostFeed Model (피드용 래퍼)
struct PostFeed: Codable {
    let posts: [Post]
    let hasMore: Bool
    let nextCursor: String?

    /// 피드 새로고침용
    mutating func append(_ newPosts: [Post]) {
        var uniquePosts = posts
        for post in newPosts {
            if !uniquePosts.contains(where: { $0.id == post.id }) {
                uniquePosts.append(post)
            }
        }
        self = PostFeed(posts: uniquePosts, hasMore: hasMore, nextCursor: nextCursor)
    }
}

// MARK: - Mock Data
extension Comment {
    static let mockComment = Comment(
        id: UUID(),
        postId: UUID(),
        userId: UUID(),
        content: "정말 유용한 정보네요! 저도 Claude Pro 써봐야겠어요.",
        createdAt: Date().addingTimeInterval(-1800),
        updatedAt: Date().addingTimeInterval(-1800),
        author: User.mockUser
    )
}
