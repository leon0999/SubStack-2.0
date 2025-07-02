// Features/Posts/CreatePostView.swift
import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var postService = PostService.shared

    @State private var content = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImage: Image?
    @State private var isPosting = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 텍스트 입력
                TextEditor(text: $content)
                    .placeholder(when: content.isEmpty) {
                        Text("AI 작업물이나 경험을 공유해주세요...")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                    .padding()

                // 이미지 프리뷰
                if let selectedImage {
                    selectedImage
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .padding()
                }

                Spacer()

                // 하단 툴바
                HStack {
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images
                    ) {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .onChange(of: selectedItem) { _ in
                        Task {
                            if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                                selectedImage = Image(uiImage: UIImage(data: data)!)
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
                .background(Color(UIColor.systemGray6))
            }
            .navigationTitle("새 포스트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("게시") {
                        Task {
                            await postContent()
                        }
                    }
                    .disabled(content.isEmpty || isPosting)
                }
            }
        }
    }

    private func postContent() async {
        isPosting = true

        do {
            _ = try await postService.createPost(
                content: content,
                mediaData: selectedImageData,
                mediaType: selectedImageData != nil ? .image : nil
            )
            dismiss()
        } catch {
            print("포스트 실패: \(error)")
        }

        isPosting = false
    }
}
