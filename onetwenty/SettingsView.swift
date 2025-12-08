import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appStore: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(AppFonts.title)
                    .primaryTextStyle()

                sectionCard(title: "Plan Import") {
                    ImportPlanView()
                        .environmentObject(appStore)
                }

                sectionCard(title: "Export & Progress Tracking") {
                    ExportSettingsView()
                        .environmentObject(appStore)
                }

                sectionCard(title: "Timer Settings") {
                    timerSettings
                }

                sectionCard(title: "Revision Settings") {
                    revisionSettings
                }

                sectionCard(title: "Appearance") {
                    appearanceSettings
                }

                if !appStore.dayPlans.isEmpty {
                    sectionCard(title: "Current Plan") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Days loaded: \(appStore.dayPlans.count)")
                                .primaryTextStyle()
                            if let current = appStore.currentDay {
                                Text("Current Day: #\(current.dayNumber) – \(current.title)")
                                    .secondaryTextStyle()
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
        }
        .background(AppColors.background)
    }
}

private extension SettingsView {
    var timerSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Customize focus, break durations, and cycles for each mode.")
                .font(AppFonts.body)
                .secondaryTextStyle()

            ForEach(timerRows, id: \.title) { row in
                timerRow(
                    title: row.title,
                    focusBinding: row.focusBinding,
                    breakBinding: row.breakBinding,
                    cyclesBinding: row.cyclesBinding
                )
                if row.title != timerRows.last?.title {
                    Divider()
                        .background(AppColors.border)
                }
            }
        }
    }

    var revisionSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tune your spaced repetition pacing.")
                .font(AppFonts.body)
                .secondaryTextStyle()

            Stepper(value: revisionBinding(for: \.dailyMaxCards), in: 1...100) {
                Text("Daily max cards: \(appStore.revisionSettings.dailyMaxCards)")
                    .primaryTextStyle()
            }
            Text("Caps how many review cards appear each day.")
                .font(AppFonts.caption)
                .secondaryTextStyle()

            Stepper(value: revisionBinding(for: \.initialIntervalDays), in: 1...30) {
                Text("Initial interval: \(appStore.revisionSettings.initialIntervalDays) day(s)")
                    .primaryTextStyle()
            }
            Text("Base spacing used for new cards before multipliers are applied.")
                .font(AppFonts.caption)
                .secondaryTextStyle()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hard multiplier")
                        .primaryTextStyle()
                    TextField("Hard multiplier", value: revisionBinding(for: \.hardIntervalMultiplier), formatter: numberFormatter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Easy multiplier")
                        .primaryTextStyle()
                    TextField("Easy multiplier", value: revisionBinding(for: \.easyIntervalMultiplier), formatter: numberFormatter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
            }

            Text("Hard lowers the interval, easy raises it—tweak to match your pacing.")
                .font(AppFonts.caption)
                .secondaryTextStyle()
        }
    }

    var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme: \(appStore.selectedTheme.displayName)")
                .primaryTextStyle()

            Picker("Theme", selection: $appStore.selectedTheme) {
                ForEach(AppThemeChoice.allCases) { choice in
                    Text(choice.displayName)
                        .tag(choice)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    var timerRows: [(title: String, focusBinding: Binding<Int>, breakBinding: Binding<Int>, cyclesBinding: Binding<Int>)] {
        [
            (
                "Focused Drill",
                binding(for: \.focusedDrillFocusMinutes),
                binding(for: \.focusedDrillBreakMinutes),
                binding(for: \.focusedDrillCycles)
            ),
            (
                "Concept Block",
                binding(for: \.conceptBlockFocusMinutes),
                binding(for: \.conceptBlockBreakMinutes),
                binding(for: \.conceptBlockCycles)
            ),
            (
                "Deep Build",
                binding(for: \.deepBuildFocusMinutes),
                binding(for: \.deepBuildBreakMinutes),
                binding(for: \.deepBuildCycles)
            ),
            (
                "Simulation Burst",
                binding(for: \.simulationBurstFocusMinutes),
                binding(for: \.simulationBurstBreakMinutes),
                binding(for: \.simulationBurstCycles)
            )
        ]
    }

    func timerRow(
        title: String,
        focusBinding: Binding<Int>,
        breakBinding: Binding<Int>,
        cyclesBinding: Binding<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFonts.headline)
                .primaryTextStyle()

            HStack(spacing: 16) {
                Stepper(value: focusBinding, in: 5...240, step: 5) {
                    Text("Focus: \(focusBinding.wrappedValue) min")
                        .secondaryTextStyle()
                }

                Stepper(value: breakBinding, in: 0...120, step: 5) {
                    Text("Break: \(breakBinding.wrappedValue) min")
                        .secondaryTextStyle()
                }

                Stepper(value: cyclesBinding, in: 1...10, step: 1) {
                    Text("Cycles: \(cyclesBinding.wrappedValue)")
                        .secondaryTextStyle()
                }
            }
        }
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

    func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .sectionTitleStyle()

            content()
        }
        .cardBackground()
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
