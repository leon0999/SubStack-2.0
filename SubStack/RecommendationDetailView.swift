import SwiftUI

struct RecommendationDetailView: View {
    let recommendation: Recommendation
    @Environment(\.dismiss) var dismiss
    @State private var showingSubscribeAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더
                VStack(spacing: 16) {
                    // 아이콘
                    Text(recommendation.icon)
                        .font(.system(size: 80))
                        .frame(width: 120, height: 120)
                        .background(recommendation.color.opacity(0.2))
                        .cornerRadius(30)

                    Text(recommendation.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("₩\(recommendation.price.formatted())/월")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)

                // AI 추천 이유
                VStack(alignment: .leading, spacing: 12) {
                    Label("AI가 추천하는 이유", systemImage: "sparkles")
                        .font(.headline)

                    Text(recommendation.aiReason)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)

                // 주요 기능
                VStack(alignment: .leading, spacing: 12) {
                    Text("주요 기능")
                        .font(.headline)

                    FeatureRow(icon: "checkmark.circle.fill", text: "AI 기반 코드 자동 완성")
                    FeatureRow(icon: "checkmark.circle.fill", text: "전체 코드베이스 이해")
                    FeatureRow(icon: "checkmark.circle.fill", text: "자연어로 코드 수정")
                    FeatureRow(icon: "checkmark.circle.fill", text: "멀티 파일 편집")
                }

                // 비교
                if recommendation.replacing != nil {
                    ComparisonSection(recommendation: recommendation)
                }

                // CTA 버튼들
                VStack(spacing: 12) {
                    Button(action: { showingSubscribeAlert = true }) {
                        Text("구독하기")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    Button(action: {}) {
                        Text("무료 체험하기")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("구독 완료", isPresented: $showingSubscribeAlert) {
            Button("확인") { dismiss() }
        } message: {
            Text("\(recommendation.name) 구독이 추가되었습니다.")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct ComparisonSection: View {
    let recommendation: Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(recommendation.replacing ?? "") vs \(recommendation.name)")
                .font(.headline)

            HStack(spacing: 20) {
                // 현재 사용 중
                VStack(alignment: .leading, spacing: 8) {
                    Text(recommendation.replacing ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("₩\(recommendation.price + recommendation.savings)/월")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.right")
                    .foregroundColor(.green)

                // 추천 서비스
                VStack(alignment: .leading, spacing: 8) {
                    Text(recommendation.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("₩\(recommendation.price)/월")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("월 ₩\(recommendation.savings) 절약")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(20)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}
