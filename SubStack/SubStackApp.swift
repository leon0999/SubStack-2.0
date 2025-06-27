import SwiftUI

@main
struct SubStackApp: App {
    @StateObject private var bankDataManager = BankDataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bankDataManager)
        }
    }
}
