import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appStore: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.largeTitle)

                ImportPlanView()
                    .environmentObject(appStore)

                if !appStore.dayPlans.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Plan")
                            .font(.headline)
                        Text("Days loaded: \(appStore.dayPlans.count)")
                        if let current = appStore.currentDay {
                            Text("Current Day: #\(current.dayNumber) – \(current.title)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStore())
}
