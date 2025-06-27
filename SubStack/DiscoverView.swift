import SwiftUI

struct DiscoverView: View {
    @State private var recommendations: [Recommendation] = Recommendation.sampleData
    @State private var isRefreshing = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 개인화된 추천 헤더
                    PersonalizedHeader()

                    // 추천 카드들
                    LazyVStack(spacing: 16) {
                        ForEach(recommendations) { recommendation in
                            RecommendationCard(recommendation: recommendation)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("발견하기")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshRecommendations()
            }
        }
    }

    func refreshRecommendations() async {
        isRefreshing = true
        // 실제로는 여기서 API 호출
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }
}

struct PersonalizedHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("당신을 위한 추천")
                .font(.title2)
                .fontWeight(.bold)
            Text("시니어 백엔드 개발자를 위한 맞춤 추천")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RecommendationCard: View {
    let recommendation: Recommendation
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack(spacing: 12) {
                // 아이콘
                RoundedRectangle(cornerRadius: 12)
                    .fill(recommendation.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(recommendation.icon)
                            .font(.title)
                    )

                // 제목과 태그
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.name)
                        .font(.headline)
                    HStack(spacing: 6) {
                        ForEach(recommendation.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor.systemGray5))
                                .cornerRadius(10)
                        }
                    }
                }

                Spacer()

                // 가격
                VStack(alignment: .trailing) {
                    Text("₩\(recommendation.price.formatted())")
                        .font(.headline)
                    Text("/월")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // AI 추천 이유
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("AI 추천 이유")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Text(recommendation.aiReason)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 2)

                if recommendation.aiReason.count > 100 {
                    Button(action: { isExpanded.toggle() }) {
                        Text(isExpanded ? "접기" : "더보기")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)

            // 대체하는 서비스
            if let replacing = recommendation.replacing {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.green)
                    Text("\(replacing) 대신 사용하면 월 ₩\(recommendation.savings.formatted()) 절약")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            // CTA 버튼
            HStack(spacing: 12) {
              NavigationLink(destination: RecommendationDetailView(recommendation: recommendation)) {
                  Text("자세히 보기")
                      .font(.subheadline)
                      .fontWeight(.medium)
                      .foregroundColor(.blue)
                      .frame(maxWidth: .infinity)
                      .padding(.vertical, 12)
                      .background(Color.blue.opacity(0.1))
                      .cornerRadius(10)
              }

                Button(action: {}) {
                    Text("관심 없음")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

// 추천 데이터 모델
struct Recommendation: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let price: Int
    let tags: [String]
    let aiReason: String
    let replacing: String?
    let savings: Int

    static let sampleData = [
        Recommendation(
            name: "Cursor",
            icon: "⚡",
            color: .blue,
            price: 20000,
            tags: ["AI 코딩", "VS Code 대체"],
            aiReason: "GitHub Copilot을 사용 중이신 것을 확인했습니다. Cursor는 더 강력한 AI 기능과 함께 전체 코드베이스를 이해하는 능력을 제공합니다. 특히 Spring 프로젝트에서 뛰어난 성능을 보입니다.",
            replacing: "GitHub Copilot",
            savings: 13000
        ),
        Recommendation(
            name: "Linear",
            icon: "📊",
            color: .purple,
            price: 8000,
            tags: ["프로젝트 관리", "이슈 트래킹"],
            aiReason: "Notion을 프로젝트 관리용으로 사용하시는 것 같습니다. Linear는 개발자를 위해 특별히 설계된 이슈 트래킹 도구로, GitHub와의 연동이 매우 강력합니다.",
            replacing: nil,
            savings: 0
        ),
        Recommendation(
            name: "Raycast Pro",
            icon: "🚀",
            color: .orange,
            price: 10000,
            tags: ["생산성", "맥OS"],
            aiReason: "맥을 사용하시는 개발자라면 Raycast는 필수입니다. AI 기능이 포함된 Pro 버전은 코드 스니펫 관리와 빠른 검색으로 하루 30분 이상을 절약할 수 있습니다.",
            replacing: nil,
            savings: 0
        )
    ]
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}
