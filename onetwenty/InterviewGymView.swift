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
        HStack(alignment: .top) {
            sessionList
                .frame(minWidth: 240)

            Divider()

            if let session = selectedSession ?? sessions.first {
                sessionDetail(for: session)
            } else {
                Text("Select a preset to begin an interview session.")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .onAppear {
            if selectedSession == nil {
                selectedSession = sessions.first
            }
        }
    }

    private var sessionList: some View {
        List(sessions, selection: $selectedSession) { session in
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.headline)
                Text("\(session.totalMinutes) minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedSession = session
                activeSlotIndex = nil
            }
        }
    }

    private func sessionDetail(for session: InterviewSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.title2)
                Text("Total: \(session.totalMinutes) minutes")
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Slots")
                    .font(.headline)
                ForEach(Array(session.slots.enumerated()), id: \.offset) { index, slot in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(slot.label)
                                .font(.subheadline)
                            Text("\(slot.durationMinutes) min • \(slot.recommendedMode.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if index == activeSlotIndex {
                            Text("Active")
                                .font(.caption)
                                .padding(6)
                                .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                        }
                    }
                    .padding(8)
                    .background(index == activeSlotIndex ? Color.accentColor.opacity(0.05) : Color.clear)
                    .cornerRadius(8)
                }
            }

            HStack(spacing: 12) {
                Button("Start Session") {
                    startSession(session)
                }
                .disabled(session.slots.isEmpty)

                Button("Previous Slot") {
                    moveSlot(by: -1, in: session)
                }
                .disabled(!canMove(by: -1, in: session))

                Button("Next Slot") {
                    moveSlot(by: 1, in: session)
                }
                .disabled(!canMove(by: 1, in: session))
            }

            if let activeSlotIndex {
                Text("Currently on slot \(activeSlotIndex + 1) of \(session.slots.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
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
}

#Preview {
    InterviewGymView()
        .environmentObject(AppStore())
        .environmentObject(TimerManager())
}
