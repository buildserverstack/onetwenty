import SwiftUI
import Combine

@main
struct AICoachMacApp: App {
    @StateObject private var appStore = AppStore()
    @StateObject private var timerManager = TimerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appStore)
                .environmentObject(timerManager)
                .preferredColorScheme(resolvedColorScheme)
                .onAppear {
                    appStore.loadInitialData()
                    timerManager.updatePreferences(appStore.timerPreferences)
                }
                .onReceive(appStore.$timerPreferences) { newPreferences in
                    timerManager.updatePreferences(newPreferences)
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Quick Capture") {
                    appStore.toggleQuickCapture()
                }
                .keyboardShortcut(.space, modifiers: [.option])
            }
        }

        MenuBarExtra {
            VStack(alignment: .leading, spacing: 8) {
                Text("Timer Status")
                    .font(.headline)

                HStack {
                    Text("State:")
                    Text(menuStateLabel)
                        .bold()
                }

                HStack {
                    Text("Remaining:")
                    Text(formattedTime(timerManager.remainingSeconds))
                        .monospacedDigit()
                }

                HStack {
                    Text("Mode:")
                    Text(timerManager.mode.displayName)
                }

                HStack(spacing: 12) {
                    Button("Start") {
                        let blockId = timerManager.activeBlockId ?? UUID()
                        timerManager.start(
                            for: blockId,
                            mode: timerManager.mode,
                            preferences: appStore.timerPreferences
                        )
                    }

                    Button("Pause") {
                        timerManager.pause()
                    }

                    Button("Stop") {
                        let dayPlanId = appStore.currentDay?.id ?? UUID()
                        _ = timerManager.stopAndBuildSession(dayPlanId: dayPlanId)
                    }

                    Button("Quick Capture") {
                        appStore.toggleQuickCapture()
                    }
                }
            }
            .padding()
            .environmentObject(timerManager)
            .environmentObject(appStore)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
            Text(compactStatusText)
                .monospacedDigit()
        }
    }

    private var compactStatusText: String {
        switch timerManager.state {
        case .focus:
            return "F \(formattedTime(timerManager.remainingSeconds))"
        case .breakTime:
            return "B \(formattedTime(timerManager.remainingSeconds))"
        case .idle:
            return "Idle"
        }
    }

    private var menuStateLabel: String {
        switch timerManager.state {
        case .focus:
            return "Focus"
        case .breakTime:
            return "Break"
        case .idle:
            return "Idle"
        }
    }

    private var resolvedColorScheme: ColorScheme? {
        switch appStore.selectedTheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    private func formattedTime(_ totalSeconds: Int) -> String {
        let seconds = max(totalSeconds, 0)
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d", minutes, remaining)
    }
}
