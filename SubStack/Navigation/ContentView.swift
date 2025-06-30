import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("대시보드", systemImage: "chart.pie.fill")
                }

            MySubscriptionsView()
                .tabItem {
                    Label("내 구독", systemImage: "creditcard.fill")
                }

            SimpleFeedView()  // 👈 새로 추가
              .tabItem {
                  Label("업데이트", systemImage: "bell.badge")
              }

            DiscoverView()
                .tabItem {
                    Label("발견하기", systemImage: "sparkles")
                }

            ProfileView()
                .tabItem {
                    Label("프로필", systemImage: "person.fill")
                }
        }
    }
}

// 임시 뷰들

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
