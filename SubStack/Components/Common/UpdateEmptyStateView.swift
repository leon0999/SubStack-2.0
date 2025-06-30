// Views/Components/EmptyStateView.swift
import SwiftUI

struct UpdateEmptyStateView: View {
    let category: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text(category == "전체" ? "아직 업데이트가 없습니다" : "\(category) 관련 업데이트가 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("잠시 후 다시 확인해주세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
