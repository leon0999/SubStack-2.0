// Features/Posts/PostFeedView.swift
import SwiftUI

struct PostFeedView: View {
    @StateObject private var postService = PostService.shared
    @State private var showingCreatePost = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(postService.posts) { post in
                        InstagramStylePostCard(post: post)

                        // 구분선
                        Rectangle()
                            .fill(Color(UIColor.separator))
                            .frame(height: 0.5)
                    }

                    // 로딩 인디케이터
                    if postService.isLoading {
                        ProgressView()
                            .padding()
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("AI 커뮤니티")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreatePost = true
                    } label: {
                        Image(systemName: "plus.app")
                            .font(.title3)
                    }
                }
            }
            .refreshable {
                try? await postService.fetchFeed()
            }
        }
        .sheet(isPresented: $showingCreatePost) {
            CreatePostView()
        }
        .task {
            try? await postService.fetchFeed()
        }
    }
}

// MARK: - 인스타그램 스타일 포스트 카드
struct InstagramStylePostCard: View {
    let post: Post
    @StateObject private var postService = PostService.shared
    @State private var isLiked = false
    @State private var showingComments = false
    @State private var showingShareSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. 헤더 (프로필 + 이름 + 더보기)
            PostHeader(post: post)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            // 2. 미디어 콘텐츠 (전체 너비)
            PostMedia(post: post)

            // 3. 액션 버튼들
            PostActions(
                post: post,
                isLiked: $isLiked,
                showingComments: $showingComments,
                showingShareSheet: $showingShareSheet
            )
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // 4. 좋아요 수
            if post.likesCount > 0 {
                Text("좋아요 \(post.formattedLikesCount)개")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }

            // 5. 캡션
            PostCaption(post: post, showingComments: $showingComments)
                .padding(.horizontal, 12)
                .padding(.top, 4)

            // 6. 댓글 미리보기
            if post.commentsCount > 0 {
                Button {
                    showingComments = true
                } label: {
                    Text("댓글 \(post.commentsCount)개 모두 보기")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
            }

            // 7. 시간
            Text(post.timeAgo)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, 12)
        }
        .onAppear {
            isLiked = post.isLikedByMe
        }
        .sheet(isPresented: $showingComments) {
            CommentsView(post: post)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [post.content])
        }
    }
}

// MARK: - 포스트 헤더
struct PostHeader: View {
    let post: Post
    @State private var showingMenu = false

    var body: some View {
        HStack(spacing: 12) {
            // 프로필 이미지
            if let profileURL = post.author?.profileImageURL {
                AsyncImage(url: profileURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
            }

            // 사용자 정보
            VStack(alignment: .leading, spacing: 2) {
                Text(post.author?.displayName ?? "익명")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let _ = post.mediaUrl {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("AI 작업물")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 더보기 메뉴
            Menu {
                Button("신고", action: {})
                Button("공유", action: {})
                if post.userId == AuthService.shared.currentUser?.id {
                    Divider()
                    Button("삭제", role: .destructive, action: {})
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.primary)
                    .padding(8)
                    .contentShape(Rectangle())
            }
        }
    }
}

// MARK: - 포스트 미디어
struct PostMedia: View {
    let post: Post

    var body: some View {
        if let mediaURL = post.mediaURL {
            if post.mediaType == .image {
                AsyncImage(url: mediaURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                } placeholder: {
                    Rectangle()
                        .fill(Color(UIColor.systemGray6))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            ProgressView()
                        )
                }
            } else if post.mediaType == .video {
                // 비디오 플레이어 (추후 구현)
                Rectangle()
                    .fill(Color.black)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    )
            }
        } else {
            // 텍스트만 있는 경우
            Text(post.content)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(
                    LinearGradient(
                        colors: [
                            Color(UIColor.systemIndigo).opacity(0.3),
                            Color(UIColor.systemPurple).opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

// MARK: - 액션 버튼들
struct PostActions: View {
    let post: Post
    @Binding var isLiked: Bool
    @Binding var showingComments: Bool
    @Binding var showingShareSheet: Bool
    @StateObject private var postService = PostService.shared

    var body: some View {
        HStack(spacing: 16) {
            // 좋아요
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isLiked.toggle()
                }
                Task {
                    try? await postService.toggleLike(for: post)
                }
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(isLiked ? .red : .primary)
                    .scaleEffect(isLiked ? 1.1 : 1.0)
            }

            // 댓글
            Button {
                showingComments = true
            } label: {
                Image(systemName: "bubble.right")
                    .font(.title3)
                    .foregroundColor(.primary)
            }

            // 공유
            Button {
                showingShareSheet = true
            } label: {
                Image(systemName: "paperplane")
                    .font(.title3)
                    .foregroundColor(.primary)
            }

            Spacer()

            // 북마크 (추후 구현)
            Button {
                // TODO: 북마크 기능
            } label: {
                Image(systemName: "bookmark")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - 포스트 캡션
struct PostCaption: View {
    let post: Post
    @Binding var showingComments: Bool
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 6) {
                Text(post.author?.displayName ?? "익명")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(post.content)
                    .font(.subheadline)
                    .lineLimit(isExpanded ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if post.content.count > 100 && !isExpanded {
                Button("더 보기") {
                    withAnimation {
                        isExpanded = true
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 댓글 뷰
struct CommentsView: View {
    let post: Post
    @Environment(\.dismiss) var dismiss
    @State private var commentText = ""
    @State private var comments: [Comment] = []

    var body: some View {
        NavigationView {
            VStack {
                // 댓글 리스트
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        // 원본 포스트
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(post.author?.displayName ?? "익명")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(post.content)
                                    .font(.subheadline)

                                Text(post.timeAgo)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding()

                        Divider()

                        // 댓글들
                        ForEach(comments) { comment in
                            CommentRow(comment: comment)
                                .padding(.horizontal)
                        }
                    }
                }

                // 댓글 입력
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.gray)

                    TextField("댓글 달기...", text: $commentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("게시") {
                        // TODO: 댓글 게시
                    }
                    .disabled(commentText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("댓글")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 댓글 행
struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.author?.displayName ?? "익명")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(comment.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(comment.content)
                    .font(.subheadline)
            }

            Spacer()

            Button {
                // TODO: 댓글 좋아요
            } label: {
                Image(systemName: "heart")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - 공유 시트
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
