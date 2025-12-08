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

                Divider()

                ExportSettingsView()
                    .environmentObject(appStore)

                Divider()
                timerSettings

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

private extension SettingsView {
    var timerSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timer Settings")
                .font(.headline)

            Text("Customize focus and break durations (minutes) and cycles for each focus mode.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            timerRow(
                title: "Focused Drill",
                focusBinding: binding(for: \.focusedDrillFocusMinutes),
                breakBinding: binding(for: \.focusedDrillBreakMinutes),
                cyclesBinding: binding(for: \.focusedDrillCycles)
            )

            timerRow(
                title: "Concept Block",
                focusBinding: binding(for: \.conceptBlockFocusMinutes),
                breakBinding: binding(for: \.conceptBlockBreakMinutes),
                cyclesBinding: binding(for: \.conceptBlockCycles)
            )

            timerRow(
                title: "Deep Build",
                focusBinding: binding(for: \.deepBuildFocusMinutes),
                breakBinding: binding(for: \.deepBuildBreakMinutes),
                cyclesBinding: binding(for: \.deepBuildCycles)
            )

            timerRow(
                title: "Simulation Burst",
                focusBinding: binding(for: \.simulationBurstFocusMinutes),
                breakBinding: binding(for: \.simulationBurstBreakMinutes),
                cyclesBinding: binding(for: \.simulationBurstCycles)
            )
        }
    }

    func timerRow(
        title: String,
        focusBinding: Binding<Int>,
        breakBinding: Binding<Int>,
        cyclesBinding: Binding<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)

            HStack(spacing: 16) {
                Stepper(value: focusBinding, in: 1...240) {
                    Text("Focus: \(focusBinding.wrappedValue) min")
                }

                Stepper(value: breakBinding, in: 0...120) {
                    Text("Break: \(breakBinding.wrappedValue) min")
                }

                Stepper(value: cyclesBinding, in: 1...10) {
                    Text("Cycles: \(cyclesBinding.wrappedValue)")
                }
            }
        }
        .padding(.vertical, 6)
    }

    func binding(for keyPath: WritableKeyPath<TimerPreferences, Int>) -> Binding<Int> {
        Binding(
            get: { appStore.timerPreferences[keyPath: keyPath] },
            set: { newValue in
                appStore.timerPreferences[keyPath: keyPath] = max(0, newValue)
            }
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStore())
}
