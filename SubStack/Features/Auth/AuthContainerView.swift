import SwiftUI

struct AuthContainerView: View {
    @StateObject private var authService = AuthService.shared

    var body: some View {
        Group {
            if authService.isAuthenticated {
                // 로그인된 상태 - 메인 앱 화면
                ContentView()
                    .transition(.opacity)
            } else {
                // 로그아웃 상태 - 로그인 화면
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

// SubStackApp.swift 수정 필요
// WindowGroup {
//     AuthContainerView()  // ContentView 대신 이걸로 변경
//         .environmentObject(...)
// }
