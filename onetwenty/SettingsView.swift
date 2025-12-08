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

                Divider()
                revisionSettings

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

    var revisionSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Revision Settings")
                .font(.headline)

            Text("Control how many cards you see daily and the interval multipliers for review scheduling.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Stepper(value: revisionBinding(for: \.dailyMaxCards), in: 1...100) {
                Text("Daily max cards: \(appStore.revisionSettings.dailyMaxCards)")
            }

            Stepper(value: revisionBinding(for: \.initialIntervalDays), in: 1...30) {
                Text("Initial interval (days): \(appStore.revisionSettings.initialIntervalDays)")
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Hard multiplier")
                    TextField("Hard multiplier", value: revisionBinding(for: \.hardIntervalMultiplier), formatter: numberFormatter)
                        .frame(width: 100)
                }

                VStack(alignment: .leading) {
                    Text("Easy multiplier")
                    TextField("Easy multiplier", value: revisionBinding(for: \.easyIntervalMultiplier), formatter: numberFormatter)
                        .frame(width: 100)
                }
            }
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

    func revisionBinding(for keyPath: WritableKeyPath<RevisionSettings, Int>) -> Binding<Int> {
        Binding(
            get: { appStore.revisionSettings[keyPath: keyPath] },
            set: { newValue in
                appStore.revisionSettings[keyPath: keyPath] = max(0, newValue)
            }
        )
    }

    func revisionBinding(for keyPath: WritableKeyPath<RevisionSettings, Double>) -> Binding<Double> {
        Binding(
            get: { appStore.revisionSettings[keyPath: keyPath] },
            set: { newValue in
                appStore.revisionSettings[keyPath: keyPath] = max(0.1, newValue)
            }
        )
    }

    var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimum = 0
        return formatter
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStore())
}
