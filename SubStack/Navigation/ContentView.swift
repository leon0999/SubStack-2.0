import SwiftUI

struct ContentView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var postService = PostService.shared

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(subscriptionManager)
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }

            MySubscriptionsView()
                .environmentObject(subscriptionManager)
                .tabItem {
                    Label("내 구독", systemImage: "creditcard.fill")
                }

            PostFeedView()
                .environmentObject(postService)
                .tabItem {
                    Label("포스트", systemImage: "square.grid.2x2.fill")
                }

            ProfileView()
                .environmentObject(subscriptionManager)
                .tabItem {
                    Label("프로필", systemImage: "person.fill")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
