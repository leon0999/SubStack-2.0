import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingResetPassword = false
    @State private var isShowingPassword = false

    var body: some View {
        NavigationView {
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // 로고
                        VStack(spacing: 16) {
                            Image(systemName: "cube.transparent.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            Text("SubStack")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("AI 구독 관리의 시작")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)

                        // 로그인 폼
                        VStack(spacing: 20) {
                            // 이메일 필드
                            VStack(alignment: .leading, spacing: 8) {
                                Text("이메일")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.secondary)

                                    TextField("example@email.com", text: $email)
                                        .textFieldStyle(.plain)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .textContentType(.emailAddress)
                                }
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(UIColor.separator), lineWidth: 0.5)
                                )
                            }

                            // 비밀번호 필드
                            VStack(alignment: .leading, spacing: 8) {
                                Text("비밀번호")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.secondary)

                                    if isShowingPassword {
                                        TextField("••••••••", text: $password)
                                            .textFieldStyle(.plain)
                                            .textContentType(.password)
                                    } else {
                                        SecureField("••••••••", text: $password)
                                            .textFieldStyle(.plain)
                                            .textContentType(.password)
                                    }

                                    Button(action: { isShowingPassword.toggle() }) {
                                        Image(systemName: isShowingPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(UIColor.separator), lineWidth: 0.5)
                                )
                            }

                            // 비밀번호 찾기
                            HStack {
                                Spacer()
                                Button("비밀번호를 잊으셨나요?") {
                                    showingResetPassword = true
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)

                        // 로그인 버튼
                        Button(action: signIn) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("로그인")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(!isValidForm || authService.isLoading)
                            .opacity(!isValidForm ? 0.6 : 1)
                        }
                        .padding(.horizontal)

                        // 회원가입 링크
                        HStack {
                            Text("아직 계정이 없으신가요?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Button("회원가입") {
                                showingSignUp = true
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        }

                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showingResetPassword) {
            ResetPasswordView()
        }
        .alert("로그인 오류", isPresented: .constant(authService.errorMessage != nil)) {
            Button("확인") {
                authService.errorMessage = nil
            }
        } message: {
            Text(authService.errorMessage ?? "")
        }
    }

    // MARK: - Helper Functions

    private var isValidForm: Bool {
        !email.isEmpty && !password.isEmpty && AuthService.isValidEmail(email)
    }

    private func signIn() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                print("로그인 실패: \(error)")
            }
        }
    }
}

// MARK: - Password Reset View
struct ResetPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var showingSuccessAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 헤더
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("비밀번호 재설정")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("가입하신 이메일로 재설정 링크를 보내드립니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // 이메일 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("이메일")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.secondary)

                        TextField("example@email.com", text: $email)
                            .textFieldStyle(.plain)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(UIColor.separator), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal)

                Spacer()

                // 전송 버튼
                Button(action: resetPassword) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("재설정 링크 보내기")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(!AuthService.isValidEmail(email) || authService.isLoading)
                    .opacity(!AuthService.isValidEmail(email) ? 0.6 : 1)
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
        .alert("이메일 전송 완료", isPresented: $showingSuccessAlert) {
            Button("확인") {
                dismiss()
            }
        } message: {
            Text("비밀번호 재설정 링크를 이메일로 보냈습니다. 이메일을 확인해주세요.")
        }
    }

    private func resetPassword() {
        Task {
            do {
                try await authService.resetPassword(email: email)
                showingSuccessAlert = true
            } catch {
                print("비밀번호 재설정 실패: \(error)")
            }
        }
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
