// Core/Services/SupabaseClient.swift
import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        // Supabase 프로젝트 정보 입력
        let supabaseURL = "https://shtznywlgdopslugjmce.supabase.co"  // 여기에 Project URL 입력
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNodHpueXdsZ2RvcHNsdWdqbWNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzMzI0OTYsImV4cCI6MjA2NjkwODQ5Nn0.B-9hvNRWqY1kbAsAuCDX8qoW1e3UqDFl_EBs7KPPAF8"  // 여기에 anon public key 입력

        self.client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
    }
}

// 사용 예시
extension SupabaseManager {
    // 사용자 생성 - User 모델과 일치하도록 수정
    func createUser(_ email: String, nickname: String) async throws -> User {
        // User 모델과 일치하는 요청 구조체
        struct CreateUserRequest: Encodable {
            let id: UUID
            let email: String
            let nickname: String
            let auth_provider: String
            let created_at: String
            let updated_at: String
        }

        let now = ISO8601DateFormatter().string(from: Date())
        let userId = UUID()

        let request = CreateUserRequest(
            id: userId,
            email: email,
            nickname: nickname,
            auth_provider: "email",
            created_at: now,
            updated_at: now
        )

        let response = try await client
            .from("users")
            .insert(request)
            .select()
            .single()
            .execute()

        // 디버깅: 응답 데이터 확인
        if let jsonString = String(data: response.data, encoding: .utf8) {
            print("📝 응답 JSON: \(jsonString)")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.date(from: dateString) ?? Date()
        }

        return try decoder.decode(User.self, from: response.data)
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
