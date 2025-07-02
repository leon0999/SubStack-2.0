import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService.shared

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var nickname = ""
    @State private var isShowingPassword = false
    @State private var isShowingConfirmPassword = false
    @State private var agreedToTerms = false
    @State private var showingSuccessAlert = false

    private var passwordStrength: AuthService.PasswordStrength {
        AuthService.passwordStrength(password)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text("회원가입")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("SubStack과 함께 AI 구독을 관리하세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // 가입 폼
                    VStack(spacing: 20) {
                        // 이메일
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("이메일")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                Spacer()

                                if !email.isEmpty {
                                    if AuthService.isValidEmail(email) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    } else {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                }
                            }

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
                                    .stroke(borderColor(for: email, validator: AuthService.isValidEmail), lineWidth: 1)
                            )
                        }

                        // 닉네임
                        VStack(alignment: .leading, spacing: 8) {
                            Text("닉네임")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(.secondary)

                                TextField("닉네임을 입력하세요", text: $nickname)
                                    .textFieldStyle(.plain)
                                    .textContentType(.nickname)
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(UIColor.separator), lineWidth: 0.5)
                            )
                        }

                        // 비밀번호
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("비밀번호")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                Spacer()

                                if !password.isEmpty {
                                    Text(passwordStrength.text)
                                        .font(.caption2)
                                        .foregroundColor(passwordStrength.color)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(passwordStrength.color.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }

                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.secondary)

                                if isShowingPassword {
                                    TextField("6자 이상 입력하세요", text: $password)
                                        .textFieldStyle(.plain)
                                        .textContentType(.newPassword)
                                } else {
                                    SecureField("6자 이상 입력하세요", text: $password)
                                        .textFieldStyle(.plain)
                                        .textContentType(.newPassword)
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
                                    .stroke(passwordBorderColor, lineWidth: 1)
                            )

                            // 비밀번호 강도 인디케이터
                            if !password.isEmpty {
                                HStack(spacing: 4) {
                                    ForEach(0..<3) { index in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(strengthColor(for: index))
                                            .frame(height: 3)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }

                        // 비밀번호 확인
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("비밀번호 확인")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                Spacer()

                                if !confirmPassword.isEmpty && !password.isEmpty {
                                    Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(password == confirmPassword ? .green : .red)
                                        .font(.caption)
                                }
                            }

                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.secondary)

                                if isShowingConfirmPassword {
                                    TextField("비밀번호를 다시 입력하세요", text: $confirmPassword)
                                        .textFieldStyle(.plain)
                                } else {
                                    SecureField("비밀번호를 다시 입력하세요", text: $confirmPassword)
                                        .textFieldStyle(.plain)
                                }

                                Button(action: { isShowingConfirmPassword.toggle() }) {
                                    Image(systemName: isShowingConfirmPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(confirmPasswordBorderColor, lineWidth: 1)
                            )
                        }

                        // 약관 동의
                        HStack {
                            Button(action: { agreedToTerms.toggle() }) {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .foregroundColor(agreedToTerms ? .blue : .secondary)
                            }

                            Text("서비스 이용약관 및 개인정보 처리방침에 동의합니다")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()
                        }
                    }
                    .padding(.horizontal)

                    // 회원가입 버튼
                    Button(action: signUp) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("회원가입")
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

                    // 로그인 링크
                    HStack {
                        Text("이미 계정이 있으신가요?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button("로그인") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    }
                    .padding(.bottom, 50)
                }
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
        .alert("회원가입 완료", isPresented: $showingSuccessAlert) {
            Button("확인") {
                dismiss()
            }
        } message: {
            Text("회원가입이 완료되었습니다. 로그인해주세요.")
        }
        .alert("회원가입 오류", isPresented: .constant(authService.errorMessage != nil)) {
            Button("확인") {
                authService.errorMessage = nil
            }
        } message: {
            Text(authService.errorMessage ?? "")
        }
    }

    // MARK: - Helper Functions

    private var isValidForm: Bool {
        AuthService.isValidEmail(email) &&
        !nickname.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreedToTerms
    }

    private var passwordBorderColor: Color {
        if password.isEmpty {
            return Color(UIColor.separator).opacity(0.5)
        }
        switch passwordStrength {
        case .weak: return .red.opacity(0.5)
        case .medium: return .orange.opacity(0.5)
        case .strong: return .green.opacity(0.5)
        }
    }

    private var confirmPasswordBorderColor: Color {
        if confirmPassword.isEmpty {
            return Color(UIColor.separator).opacity(0.5)
        }
        return password == confirmPassword ? .green.opacity(0.5) : .red.opacity(0.5)
    }

    private func borderColor(for text: String, validator: (String) -> Bool) -> Color {
        if text.isEmpty {
            return Color(UIColor.separator).opacity(0.5)
        }
        return validator(text) ? .green.opacity(0.5) : .red.opacity(0.5)
    }

    private func strengthColor(for index: Int) -> Color {
        switch passwordStrength {
        case .weak:
            return index == 0 ? .red : Color(UIColor.systemGray5)
        case .medium:
            return index <= 1 ? .orange : Color(UIColor.systemGray5)
        case .strong:
            return .green
        }
    }

    private func signUp() {
        Task {
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    nickname: nickname
                )
                showingSuccessAlert = true
            } catch {
                print("회원가입 실패: \(error)")
            }
        }
    }
}

// MARK: - Preview
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
