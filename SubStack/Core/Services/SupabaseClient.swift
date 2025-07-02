// Core/Services/SupabaseClient.swift
import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        // Supabase 프로젝트 정보 입력
        let supabaseURL = "https://YOUR_PROJECT_ID.supabase.co"  // 여기에 Project URL 입력
        let supabaseKey = "YOUR_ANON_KEY"  // 여기에 anon public key 입력

        self.client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
    }
}

// 사용 예시
extension SupabaseManager {
    // 사용자 생성
    func createUser(kakaoId: String, nickname: String) async throws -> User {
        // 전송할 데이터를 명확히 정의
        struct CreateUserRequest: Encodable {
            let kakao_id: String
            let nickname: String
        }

        let request = CreateUserRequest(
            kakao_id: kakaoId,
            nickname: nickname
        )

        let response = try await client
            .from("users")
            .insert(request)
            .select("id,kakao_id,nickname,profile_image_url,created_at")  // 명시적으로 컬럼 지정
            .single()
            .execute()

        // 디버깅: 응답 데이터 확인
        if let jsonString = String(data: response.data, encoding: .utf8) {
            print("📝 응답 JSON: \(jsonString)")
        }

        // 임시 디코딩 구조체
        struct UserResponse: Decodable {
            let id: Int
            let kakao_id: String
            let nickname: String
            let profile_image_url: String?
            let created_at: String
        }

        let decoder = JSONDecoder()
        let userResponse = try decoder.decode(UserResponse.self, from: response.data)

        // User 모델로 변환
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return User(
            id: userResponse.id,
            kakaoId: userResponse.kakao_id,
            nickname: userResponse.nickname,
            profileImageUrl: userResponse.profile_image_url,
            createdAt: formatter.date(from: userResponse.created_at)
        )
    }

    // 구독 추가
    func addSubscription(_ subscription: Subscription) async throws {
        try await client
            .from("subscriptions")
            .insert(subscription)
            .execute()
    }

    // 구독 목록 가져오기
    func fetchSubscriptions(userId: UUID) async throws -> [Subscription] {
        let response = try await client
            .from("subscriptions")
            .select()
            .eq("user_id", value: userId)
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode([Subscription].self, from: response.data)
    }
}

