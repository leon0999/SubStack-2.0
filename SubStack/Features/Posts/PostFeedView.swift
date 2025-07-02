// Features/Posts/PostFeedView.swift
import SwiftUI

struct PostFeedView: View {
    @StateObject private var postService = PostService.shared
    @State private var showingCreatePost = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(postService.posts) { post in
                        PostCard(post: post)
                            .background(Color(UIColor.systemBackground))
                    }

                    // 로딩 인디케이터
                    if postService.isLoading {
                        ProgressView()
                            .padding()
                    }
                }
            }
            .background(Color(UIColor.systemGray6))
            .navigationTitle("AI 커뮤니티")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreatePost = true
                    } label: {
                        Image(systemName: "plus")
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
