// Features/Posts/PostCard.swift
import SwiftUI

struct PostCard: View {
    let post: Post
    @StateObject private var postService = PostService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.gray)

                VStack(alignment: .leading) {
                    Text(post.author?.displayName ?? "사용자")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(post.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Menu {
                    Button("신고", action: {})
                    Button("공유", action: {})
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }

            // 콘텐츠
            Text(post.content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            // 미디어 (있는 경우)
            if let mediaURL = post.mediaURL {
                AsyncImage(url: mediaURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(maxHeight: 400)
            }

            // 액션 버튼
            HStack(spacing: 24) {
                // 좋아요 버튼
                Button {
                    Task {
                        try? await postService.toggleLike(for: post)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                            .foregroundColor(post.isLikedByMe ? .red : .gray)
                        Text("\(post.formattedLikesCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // 댓글 버튼
                Button {
                    // TODO: 댓글 화면으로 이동
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.gray)
                        Text("\(post.commentsCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                // 공유 버튼
                Button {
                    // TODO: 공유 기능
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }
}
