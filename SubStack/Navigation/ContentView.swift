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

          PostFeedView() //
                .tabItem {
                    Label("포스트", systemImage: "square.grid.2x2.fill")
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
