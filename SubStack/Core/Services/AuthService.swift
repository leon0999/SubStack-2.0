import Foundation
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
    private var authStateListener: RealtimeChannel?
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
                if let user = session.user {
                    await handleAuthSuccess(authUser: user)
                } else {
                    await handleAuthLogout()
                }
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
                    if let user = state.session?.user {
                        await handleAuthSuccess(authUser: user)
                    }
                case .signedOut:
                    await handleAuthLogout()
                case .userUpdated:
                    if let user = state.session?.user {
                        await updateUserProfile(authUser: user)
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

            guard let authUser = authResponse.user else {
                throw AuthError.signUpFailed
            }

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
            await SubscriptionManager.shared.setCurrentUser(authUser.id)

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

            guard let user = session.user else {
                throw AuthError.signInFailed
            }

            await handleAuthSuccess(authUser: user)
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
        guard let currentUser = currentUser else {
            throw AuthError.notAuthenticated
        }

        isLoading = true

        do {
            // 업데이트할 데이터 준비
            var updates: [String: Any] = [:]
            if let nickname = nickname {
                updates["nickname"] = nickname
            }
            if let profileImageUrl = profileImageUrl {
                updates["profile_image_url"] = profileImageUrl
            }
            updates["updated_at"] = Date().timeIntervalSince1970

            // Supabase 업데이트
            try await client
                .from("users")
                .update(updates)
                .eq("id", value: currentUser.id)
                .execute()

            // 로컬 상태 업데이트
            var updatedUser = currentUser
            if let nickname = nickname {
                updatedUser.nickname = nickname
            }
            if let profileImageUrl = profileImageUrl {
                updatedUser.profileImageUrl = profileImageUrl
            }

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
            decoder.dateDecodingStrategy = .iso8601

            let user = try decoder.decode(User.self, from: response.data)

            currentUser = user
            isAuthenticated = true

            // SubscriptionManager에 사용자 설정
            await SubscriptionManager.shared.setCurrentUser(authUser.id)

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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let userData = try encoder.encode(user)
        let userDict = try JSONSerialization.jsonObject(with: userData) as? [String: Any] ?? [:]

        try await client
            .from("users")
            .insert(userDict)
            .execute()
    }

    /// 사용자 프로필 업데이트 (Auth 이벤트에서)
    private func updateUserProfile(authUser: Supabase.User) async {
        guard let email = authUser.email else { return }

        // 이메일 변경 등의 업데이트 처리
        if var user = currentUser, user.email != email {
            user.email = email
            currentUser = user
        }
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
