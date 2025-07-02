// Core/Services/PostService.swift
import Foundation
import Supabase

@MainActor
class PostService: ObservableObject {
    static let shared = PostService()
    private let client = SupabaseManager.shared.client

    @Published var posts: [Post] = []
    @Published var isLoading = false

    // 포스트 생성
    func createPost(content: String, mediaData: Data? = nil, mediaType: MediaType? = nil) async throws -> Post {
        // 1. 미디어 업로드 (있는 경우)
        var mediaUrl: String? = nil
        if let data = mediaData, let type = mediaType {
            mediaUrl = try await MediaUploadService.shared.uploadMedia(data, type: type)
        }

        // 2. 포스트 생성
        let request = Post.CreateRequest(
            userId: AuthService.shared.currentUser?.id ?? UUID(),
            content: content,
            mediaUrl: mediaUrl,
            mediaType: mediaType?.rawValue
        )

        let response = try await client
            .from("posts")
            .insert(request)
            .select("*, author:users(*)")
            .single()
            .execute()

        return try JSONDecoder().decode(Post.self, from: response.data)
    }

    // 피드 가져오기
    func fetchFeed(limit: Int = 20, offset: Int = 0) async throws {
        isLoading = true

        let response = try await client
            .from("posts")
            .select("*, author:users(*), is_liked_by_me:likes(user_id)")
            .order("created_at", ascending: false)
            .limit(limit)
            .range(from: offset, to: offset + limit - 1)
            .execute()

        let newPosts = try JSONDecoder().decode([Post].self, from: response.data)

        if offset == 0 {
            posts = newPosts
        } else {
            posts.append(contentsOf: newPosts)
        }

        isLoading = false
    }

    // 좋아요 토글
    func toggleLike(for post: Post) async throws {
        guard let userId = AuthService.shared.currentUser?.id else { return }

        if post.isLikedByMe {
            // 좋아요 취소
            try await client
                .from("likes")
                .delete()
                .match(["user_id": userId, "post_id": post.id])
                .execute()
        } else {
            // 좋아요 추가
            try await client
                .from("likes")
                .insert(["user_id": userId, "post_id": post.id])
                .execute()
        }

        // 로컬 상태 업데이트
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isLikedByMe.toggle()
            posts[index].likesCount += post.isLikedByMe ? -1 : 1
        }
    }
}
