import Foundation
import SwiftUI
import Supabase
import Combine

// MARK: - AuthService
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var authStateListener: RealtimeChannelV2?
    private let client = SupabaseManager.shared.client
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    private init() {
        checkAuthStatus()
        setupAuthListener()
    }

    // MARK: - Authentication Status

    /// 현재 인증 상태 확인
    func checkAuthStatus() {
        Task {
            do {
                let session = try await client.auth.session
                let authUser = session.user  // Optional이 아님
                await handleAuthSuccess(authUser: authUser)
            } catch {
                print("❌ Auth 상태 확인 실패: \(error)")
                await handleAuthLogout()
            }
        }
    }

    /// Auth 상태 변경 리스너 설정
    private func setupAuthListener() {
        Task {
            for await state in client.auth.authStateChanges {
                switch state.event {
                case .signedIn:
                    if let authUser = state.session?.user {  // 여기는 Optional이 맞음
                        await handleAuthSuccess(authUser: authUser)
                    }
                case .signedOut:
                    await handleAuthLogout()
                case .userUpdated:
                    if let authUser = state.session?.user {  // 여기도 Optional이 맞음
                        await updateUserProfile(authUser: authUser)
                    }
                default:
                    break
                }
            }
        }
    }

    // MARK: - Sign Up

    /// 이메일/비밀번호로 회원가입
    func signUp(email: String, password: String, nickname: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Supabase Auth에 회원가입
            let authResponse = try await client.auth.signUp(
                email: email,
                password: password
            )

            let authUser = authResponse.user  // Optional이 아님, 실패시 throw

            // 2. users 테이블에 프로필 생성
            let newUser = User(
                id: authUser.id,
                email: email,
                nickname: nickname,
                profileImageUrl: nil,
                authProvider: "email",
                createdAt: Date(),
                updatedAt: Date()
            )

            // 3. 프로필 저장
            try await createUserProfile(newUser)

            // 4. 현재 사용자 설정
            currentUser = newUser
            isAuthenticated = true

            // 5. SubscriptionManager에 사용자 설정
            SubscriptionManager().setCurrentUser(authUser.id)

            isLoading = false

        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Sign In

    /// 이메일/비밀번호로 로그인
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )

            let authUser = session.user  // Optional이 아님

            await handleAuthSuccess(authUser: authUser)
            isLoading = false

        } catch {
            isLoading = false
            errorMessage = getErrorMessage(error)
            throw error
        }
    }

    // MARK: - Sign Out

    /// 로그아웃
    func signOut() async throws {
        isLoading = true

        do {
            try await client.auth.signOut()
            await handleAuthLogout()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "로그아웃 실패: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Password Reset

    /// 비밀번호 재설정 이메일 발송
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            try await client.auth.resetPasswordForEmail(email)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "비밀번호 재설정 이메일 발송 실패"
            throw error
        }
    }

    // MARK: - Profile Management

    /// 프로필 업데이트
    func updateProfile(nickname: String? = nil, profileImageUrl: String? = nil) async throws {
        guard let currentUser = currentUser else {  // 이건 Optional이므로 guard let 사용
            throw AuthError.notAuthenticated
        }

        isLoading = true

        do {
            // Encodable 구조체로 업데이트 데이터 준비
            struct ProfileUpdate: Encodable {
                let nickname: String?
                let profile_image_url: String?
                let updated_at: String
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let updates = ProfileUpdate(
                nickname: nickname,
                profile_image_url: profileImageUrl,
                updated_at: formatter.string(from: Date())
            )

            // Supabase 업데이트
            try await client
                .from("users")
                .update(updates)
                .eq("id", value: currentUser.id)
                .execute()

            // 로컬 상태 업데이트 - 새 User 인스턴스 생성
            let updatedUser = User(
                id: currentUser.id,
                email: currentUser.email,
                nickname: nickname ?? currentUser.nickname,
                profileImageUrl: profileImageUrl ?? currentUser.profileImageUrl,
                authProvider: currentUser.authProvider,
                createdAt: currentUser.createdAt,
                updatedAt: Date()
            )

            self.currentUser = updatedUser
            isLoading = false

        } catch {
            isLoading = false
            errorMessage = "프로필 업데이트 실패"
            throw error
        }
    }

    // MARK: - Private Helpers

    /// 인증 성공 처리
    private func handleAuthSuccess(authUser: Supabase.User) async {
        do {
            // users 테이블에서 프로필 정보 가져오기
            let response = try await client
                .from("users")
                .select()
                .eq("id", value: authUser.id)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return formatter.date(from: dateString) ?? Date()
            }

            let user = try decoder.decode(User.self, from: response.data)

            currentUser = user
            isAuthenticated = true

            // SubscriptionManager에 사용자 설정
            SubscriptionManager().setCurrentUser(authUser.id)

        } catch {
            print("❌ 사용자 프로필 조회 실패: \(error)")
            // 프로필이 없으면 생성 시도
            if let email = authUser.email {
                let newUser = User(
                    id: authUser.id,
                    email: email,
                    nickname: email.split(separator: "@").first.map(String.init) ?? "사용자",
                    profileImageUrl: nil,
                    authProvider: "email",
                    createdAt: Date(),
                    updatedAt: Date()
                )

                do {
                    try await createUserProfile(newUser)
                    currentUser = newUser
                    isAuthenticated = true
                } catch {
                    print("❌ 프로필 생성 실패: \(error)")
                }
            }
        }
    }

    /// 로그아웃 처리
    private func handleAuthLogout() async {
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil

        // 로컬 데이터 정리
        UserDefaults.standard.removeObject(forKey: "currentUserId")
    }

    /// 사용자 프로필 생성
    private func createUserProfile(_ user: User) async throws {
        // Encodable 구조체 정의
        struct UserCreateRequest: Encodable {
            let id: String
            let email: String
            let nickname: String
            let profile_image_url: String?
            let auth_provider: String
            let created_at: String
            let updated_at: String
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let userRequest = UserCreateRequest(
            id: user.id.uuidString,
            email: user.email,
            nickname: user.nickname,
            profile_image_url: user.profileImageUrl,
            auth_provider: user.authProvider,
            created_at: formatter.string(from: user.createdAt),
            updated_at: formatter.string(from: user.updatedAt)
        )

        try await client
            .from("users")
            .insert(userRequest)
            .execute()
    }

    /// 사용자 프로필 업데이트 (Auth 이벤트에서)
    private func updateUserProfile(authUser: Supabase.User) async {
        guard let email = authUser.email,
              let currentUser = currentUser,  // Optional 체크
              currentUser.email != email else { return }

        // 이메일이 변경된 경우 새 User 인스턴스 생성
        let updatedUser = User(
            id: currentUser.id,
            email: email,
            nickname: currentUser.nickname,
            profileImageUrl: currentUser.profileImageUrl,
            authProvider: currentUser.authProvider,
            createdAt: currentUser.createdAt,
            updatedAt: Date()
        )

        self.currentUser = updatedUser
    }

    /// 에러 메시지 변환
    private func getErrorMessage(_ error: Error) -> String {
        if let authError = error as? AuthError {
            return authError.localizedDescription
        }

        let errorString = error.localizedDescription.lowercased()

        if errorString.contains("invalid") && errorString.contains("credentials") {
            return "이메일 또는 비밀번호가 올바르지 않습니다"
        } else if errorString.contains("user not found") {
            return "존재하지 않는 계정입니다"
        } else if errorString.contains("email") && errorString.contains("already") {
            return "이미 사용중인 이메일입니다"
        } else if errorString.contains("password") && errorString.contains("weak") {
            return "비밀번호는 최소 6자 이상이어야 합니다"
        } else if errorString.contains("network") {
            return "네트워크 연결을 확인해주세요"
        }

        return "로그인 중 오류가 발생했습니다"
    }
}

// MARK: - AuthError
enum AuthError: LocalizedError {
    case notAuthenticated
    case signUpFailed
    case signInFailed
    case profileCreationFailed
    case invalidEmail
    case weakPassword
    case networkError

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "로그인이 필요합니다"
        case .signUpFailed:
            return "회원가입에 실패했습니다"
        case .signInFailed:
            return "로그인에 실패했습니다"
        case .profileCreationFailed:
            return "프로필 생성에 실패했습니다"
        case .invalidEmail:
            return "올바른 이메일 형식이 아닙니다"
        case .weakPassword:
            return "비밀번호는 최소 6자 이상이어야 합니다"
        case .networkError:
            return "네트워크 연결을 확인해주세요"
        }
    }
}

// MARK: - Validation Extensions
extension AuthService {
    /// 이메일 유효성 검사
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// 비밀번호 강도 검사
    static func passwordStrength(_ password: String) -> PasswordStrength {
        if password.count < 6 {
            return .weak
        } else if password.count < 8 {
            return .medium
        } else if password.count >= 8 &&
                  password.contains(where: { $0.isUppercase }) &&
                  password.contains(where: { $0.isLowercase }) &&
                  password.contains(where: { $0.isNumber }) {
            return .strong
        } else {
            return .medium
        }
    }

    enum PasswordStrength {
        case weak, medium, strong

        var color: Color {
            switch self {
            case .weak: return .red
            case .medium: return .orange
            case .strong: return .green
            }
        }

        var text: String {
            switch self {
            case .weak: return "약함"
            case .medium: return "보통"
            case .strong: return "강함"
            }
        }
    }
}
