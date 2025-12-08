import SwiftUI

struct InterviewSession: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let totalMinutes: Int
    let slots: [InterviewSlot]
}

struct InterviewSlot: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let recommendedMode: FocusMode
    let durationMinutes: Int
}

struct InterviewGymView: View {
    @EnvironmentObject var appStore: AppStore
    @EnvironmentObject var timerManager: TimerManager

    @State private var selectedSession: InterviewSession?
    @State private var activeSlotIndex: Int?

    private var sessions: [InterviewSession] {
        [
            InterviewSession(
                name: "30-min Mini interview",
                totalMinutes: 30,
                slots: [
                    InterviewSlot(label: "DSA Coding", recommendedMode: .focusedDrill, durationMinutes: 18),
                    InterviewSlot(label: "ML Theory", recommendedMode: .conceptBlock, durationMinutes: 12)
                ]
            ),
            InterviewSession(
                name: "60-min Standard AI interview",
                totalMinutes: 60,
                slots: [
                    InterviewSlot(label: "DSA Coding", recommendedMode: .focusedDrill, durationMinutes: 25),
                    InterviewSlot(label: "ML / LLM Intuition", recommendedMode: .conceptBlock, durationMinutes: 15),
                    InterviewSlot(label: "System Design", recommendedMode: .deepBuild, durationMinutes: 20)
                ]
            ),
            InterviewSession(
                name: "90-min Full onsite simulation",
                totalMinutes: 90,
                slots: [
                    InterviewSlot(label: "DSA Warmup", recommendedMode: .simulationBurst, durationMinutes: 15),
                    InterviewSlot(label: "System Design", recommendedMode: .deepBuild, durationMinutes: 30),
                    InterviewSlot(label: "ML Case Study", recommendedMode: .conceptBlock, durationMinutes: 20),
                    InterviewSlot(label: "Debugging / Ops", recommendedMode: .simulationBurst, durationMinutes: 10),
                    InterviewSlot(label: "Behavioral", recommendedMode: .conceptBlock, durationMinutes: 15)
                ]
            )
        ]
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            HStack(alignment: .top, spacing: 16) {
                sessionList
                    .frame(minWidth: 260, maxWidth: 320)

                if let session = selectedSession ?? sessions.first {
                    sessionDetail(for: session)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Select a preset to begin an interview session.")
                        .secondaryTextStyle()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardBackground()
                }
            }
            .padding()
        }
        .onAppear {
            if selectedSession == nil {
                selectedSession = sessions.first
            }
        }
    }

    private var sessionList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(sessions) { session in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.name)
                            .font(AppFonts.headline)
                            .primaryTextStyle()
                        Text("\(session.totalMinutes) minutes")
                            .font(AppFonts.caption)
                            .secondaryTextStyle()
                        Text(shortDescription(for: session))
                            .font(AppFonts.body)
                            .secondaryTextStyle()
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(session == selectedSession ? AppColors.accent : AppColors.border, lineWidth: session == selectedSession ? 1.5 : 1)
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSession = session
                            activeSlotIndex = nil
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func sessionDetail(for session: InterviewSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            timerHeader(for: session)

            Divider()

            Text("Session Steps")
                .sectionTitleStyle()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(session.slots.enumerated()), id: \.offset) { index, slot in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppColors.surfaceElevated)
                                .frame(width: 30, height: 30)
                            Text("\(index + 1)")
                                .font(AppFonts.caption)
                                .primaryTextStyle()
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(slot.label)
                                    .primaryTextStyle()
                                Spacer()
                                Text("\(slot.durationMinutes) min")
                                    .font(AppFonts.caption)
                                    .secondaryTextStyle()
                            }

                            HStack(spacing: 8) {
                                Text(slot.recommendedMode.displayName)
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(AppColors.accentSoft)
                                    )
                                if index == activeSlotIndex {
                                    Text("Active")
                                        .font(AppFonts.caption)
                                        .foregroundColor(AppColors.accent)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .stroke(AppColors.accent, lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(index == activeSlotIndex ? AppColors.surfaceElevated : AppColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(index == activeSlotIndex ? AppColors.accent : AppColors.border, lineWidth: index == activeSlotIndex ? 1.2 : 1)
                    )
                }
            }
        }
        .cardBackground()
    }

    private func timerHeader(for session: InterviewSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.name)
                        .font(AppFonts.headline)
                        .primaryTextStyle()
                    Text("Total \(session.totalMinutes) minutes")
                        .font(AppFonts.body)
                        .secondaryTextStyle()
                }
                Spacer()
                stateBadge
            }

            progressRow(for: activeSlot(in: session))

            HStack(spacing: 10) {
                Button("Start Session") {
                    startSession(session)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accent)
                .disabled(session.slots.isEmpty)

                Button("Previous Slot") {
                    moveSlot(by: -1, in: session)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.accent)
                .disabled(!canMove(by: -1, in: session))

                Button("Next Slot") {
                    moveSlot(by: 1, in: session)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.accent)
                .disabled(!canMove(by: 1, in: session))
            }
        }
    }

    private var stateBadge: some View {
        Text(timerManager.state == .focus ? "Focus" : (timerManager.state == .breakTime ? "Break" : "Idle"))
            .font(AppFonts.caption)
            .foregroundColor(AppColors.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(AppColors.accentSoft)
            )
    }

    private func progressRow(for slot: InterviewSlot?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Remaining")
                    .secondaryTextStyle()
                Spacer()
                Text(formattedTime(timerManager.remainingSeconds))
                    .font(.system(.title, design: .monospaced))
                    .primaryTextStyle()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppColors.surfaceElevated)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppColors.accent)
                        .frame(width: geo.size.width * CGFloat(progress(for: slot)))
                }
            }
            .frame(height: 12)
        }
    }

    private func startSession(_ session: InterviewSession) {
        guard let firstSlot = session.slots.first else { return }
        activeSlotIndex = 0
        startSlot(firstSlot)
    }

    private func moveSlot(by offset: Int, in session: InterviewSession) {
        guard let currentIndex = activeSlotIndex else { return }
        let newIndex = currentIndex + offset
        guard newIndex >= 0 && newIndex < session.slots.count else { return }

        // Stop the current timer before starting the next slot.
        _ = timerManager.stopAndBuildSession(dayPlanId: appStore.currentDay?.id ?? UUID())

        activeSlotIndex = newIndex
        let slot = session.slots[newIndex]
        startSlot(slot)
    }

    private func canMove(by offset: Int, in session: InterviewSession) -> Bool {
        guard let currentIndex = activeSlotIndex else { return false }
        let newIndex = currentIndex + offset
        return newIndex >= 0 && newIndex < session.slots.count
    }

    private func startSlot(_ slot: InterviewSlot) {
        timerManager.mode = slot.recommendedMode
        timerManager.start(
            for: UUID(),
            mode: slot.recommendedMode,
            customFocusDuration: slot.durationMinutes * 60,
            customBreakDuration: 0,
            customTotalCycles: 1
        )
    }

    private func formattedTime(_ totalSeconds: Int) -> String {
        let seconds = max(totalSeconds, 0)
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d", minutes, remaining)
    }

    private func progress(for slot: InterviewSlot?) -> Double {
        guard let slot, timerManager.state != .idle, activeSlotIndex != nil else { return 0 }
        let total = max(Double(slot.durationMinutes * 60), 1)
        let remaining = Double(timerManager.remainingSeconds)
        let progress = 1 - (remaining / total)
        return min(max(progress, 0), 1)
    }

    private func activeSlot(in session: InterviewSession) -> InterviewSlot? {
        guard let index = activeSlotIndex, index < session.slots.count else { return nil }
        return session.slots[index]
    }

    private func shortDescription(for session: InterviewSession) -> String {
        switch session.name {
        case _ where session.name.contains("Mini"):
            return "Focused warmup covering core DSA and ML theory."
        case _ where session.name.contains("Standard"):
            return "Balanced mix of coding, ML intuition, and system design."
        case _ where session.name.contains("Full"):
            return "End-to-end onsite simulation across all areas."
        default:
            return "Multi-step interview practice." 
        }
    }
}

#Preview {
    InterviewGymView()
        .environmentObject(AppStore())
        .environmentObject(TimerManager())
}
