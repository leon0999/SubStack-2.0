// Views/Components/LoadingView.swift
import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("업데이트를 불러오는 중...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
