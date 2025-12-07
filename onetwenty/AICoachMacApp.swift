import SwiftUI

@main
struct AICoachMacApp: App {
    @StateObject private var appStore = AppStore()
    @StateObject private var timerManager = TimerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appStore)
                .environmentObject(timerManager)
                .onAppear {
                    appStore.loadInitialData()
                }
        }
    }
}
