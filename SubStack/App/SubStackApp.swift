import SwiftUI

@main
struct SubStackApp: App {
    @StateObject private var bankDataManager = BankDataManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var notificationManager = NotificationManager.shared

    init() {
        // 알림 카테고리 설정
        NotificationManager.shared.setupNotificationCategories()

        // Supabase 연결 테스트
        testSupabaseConnection()
    }

    var body: some Scene {
        WindowGroup {
          AuthContainerView()
                .environmentObject(bankDataManager)
                .environmentObject(subscriptionManager)
                .environmentObject(notificationManager)
        }
    }

    private func testSupabaseConnection() {
        Task {
            do {
                print("🚀 Supabase 연결 테스트 시작...")

                // 1. 테스트 사용자 생성
                let testUser = try await SupabaseManager.shared.createUser(
                    kakaoId: "test_\(UUID().uuidString.prefix(8))",
                    nickname: "테스트유저_\(Int.random(in: 1000...9999))"
                )
                print("✅ 사용자 생성 성공:")
                print("   - ID: \(testUser.id?.uuidString ?? "없음")")
                print("   - 닉네임: \(testUser.nickname)")
                print("   - 생성일: \(testUser.createdAt?.formatted() ?? "없음")")

                // 2. 테스트 구독 추가 (사용자 ID가 있을 때만)
                if let userId = testUser.id {
                    // 기존 Subscription 모델 사용 - 정확한 파라미터 순서
                    let testSubscription = Subscription(
                        name: "ChatGPT Plus",
                        category: "AI 도구",
                        price: 25000,
                        icon: "🤖",
                        colorName: "blue",
                        billingCycle: .monthly,
                        startDate: Date(),
                        lastPaymentDate: Date()
                        // isActive는 기본값이 true라서 생략 가능
                    )

                    // Encodable한 구조체로 변경
                    struct SupabaseSubscription: Encodable {
                        let user_id: String
                        let name: String
                        let category: String
                        let price: Int
                        let icon: String
                    }

                    let supabaseData = SupabaseSubscription(
                        user_id: userId.uuidString,
                        name: testSubscription.name,
                        category: testSubscription.category,
                        price: testSubscription.price,
                        icon: testSubscription.icon
                    )

                    // Supabase에 직접 삽입
                    try await SupabaseManager.shared.client
                        .from("subscriptions")
                        .insert(supabaseData)
                        .execute()

                    print("✅ 구독 추가 성공: \(testSubscription.name)")

                    // 3. 구독 목록 조회
                    let response = try await SupabaseManager.shared.client
                        .from("subscriptions")
                        .select()
                        .eq("user_id", value: userId)
                        .execute()

                    print("✅ 구독 목록 조회 성공!")
                    print("   응답 데이터: \(String(data: response.data, encoding: .utf8) ?? "없음")")
                }

                print("🎉 Supabase 연결 테스트 완료!")

            } catch {
                print("❌ Supabase 테스트 실패: \(error)")
                print("   에러 상세: \(error.localizedDescription)")

                // 일반적인 문제 진단
                if error.localizedDescription.contains("401") {
                    print("💡 해결방법: API 키를 확인하세요")
                } else if error.localizedDescription.contains("relation") {
                    print("💡 해결방법: 테이블 관계 설정을 확인하세요")
                } else if error.localizedDescription.contains("permission") {
                    print("💡 해결방법: RLS 정책을 확인하세요")
                }
            }
        }
    }
}
