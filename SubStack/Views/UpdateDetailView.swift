// Views/UpdateDetailView.swift
import SwiftUI

struct UpdateDetailView: View {
    let update: ServiceUpdate
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 헤더
                    HStack {
                        Text(update.serviceIcon)
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text(update.service)
                                .font(.headline)
                            Text(update.publishedDate.formatted())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }

                    // 제목
                    Text(update.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    // 카테고리와 중요도
                    HStack {
                        Label(update.category.rawValue, systemImage: update.category.icon)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(update.category.color.opacity(0.15))
                            .foregroundColor(update.category.color)
                            .cornerRadius(12)

                        if update.importance == .critical {
                            Label("중요", systemImage: "exclamationmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }

                    // 요약
                    Text(update.summary)
                        .font(.body)

                    // 원문 보기 버튼
                    Button(action: {
                        if let url = URL(string: update.link) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("원문 보기", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("업데이트 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }
}
