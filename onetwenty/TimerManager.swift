import Foundation
import Combine
import _Concurrency

final class TimerManager: ObservableObject {
    enum TimerState {
        case idle
        case focus
        case breakTime
    }

    @Published var state: TimerState = .idle
    @Published var mode: FocusMode = .focusedDrill
    @Published var remainingSeconds: Int = 0
    @Published var cyclesCompleted: Int = 0
    @Published var totalCycles: Int = 0
    @Published var activeBlockId: UUID?

    private var focusDuration: Int = 0
    private var breakDuration: Int = 0
    private var focusAccumulated: Int = 0
    private var breakAccumulated: Int = 0
    private var breaksSkipped: Int = 0
    private var startedAt: Date?
    private var tickTask: _Concurrency.Task<Void, Never>?
    private var isPaused = false
    private var storedPreferences: TimerPreferences = .defaults

    func start(
        for blockId: UUID,
        mode: FocusMode,
        preferences: TimerPreferences? = nil,
        customFocusDuration: Int? = nil,
        customBreakDuration: Int? = nil,
        customTotalCycles: Int? = nil
    ) {
        stopTimerLoop()

        let resolvedPreferences = preferences ?? storedPreferences
        configure(from: resolvedPreferences, for: mode)
        self.mode = mode
        if let customFocusDuration { focusDuration = customFocusDuration }
        if let customBreakDuration { breakDuration = customBreakDuration }
        if let customTotalCycles { totalCycles = customTotalCycles }
        remainingSeconds = mode == .stopwatch ? 0 : focusDuration
        cyclesCompleted = 0
        focusAccumulated = 0
        breakAccumulated = 0
        breaksSkipped = 0
        activeBlockId = blockId
        startedAt = Date()
        state = .focus
        isPaused = false

        tickTask = _Concurrency.Task { [weak self] in
            await self?.runTimerLoop()
        }
    }

    func updatePreferences(_ preferences: TimerPreferences) {
        storedPreferences = preferences
    }

    func pause() {
        isPaused = true
    }

    func resume() {
        guard state != .idle else { return }
        isPaused = false
    }

    func stopAndBuildSession(dayPlanId: UUID) -> TimerSession? {
        guard let blockId = activeBlockId, let startedAt else {
            reset()
            return nil
        }

        stopTimerLoop()
        let endedAt = Date()
        let recordedCycles = mode == .stopwatch ? max(cyclesCompleted, 1) : cyclesCompleted

        let session = TimerSession(
            id: UUID(),
            dayPlanId: dayPlanId,
            blockId: blockId,
            mode: mode,
            startedAt: startedAt,
            endedAt: endedAt,
            focusSeconds: focusAccumulated,
            breakSeconds: breakAccumulated,
            cyclesCompleted: recordedCycles,
            breaksSkipped: breaksSkipped
        )

        reset()
        return session
    }

    func skipBreak() {
        guard state == .breakTime else { return }

        breaksSkipped += 1
        completeCycleAndTransition()
    }

    func configure(from preferences: TimerPreferences, for mode: FocusMode) {
        storedPreferences = preferences
        switch mode {
        case .focusedDrill:
            focusDuration = preferences.focusedDrillFocusMinutes * 60
            breakDuration = preferences.focusedDrillBreakMinutes * 60
            totalCycles = preferences.focusedDrillCycles
        case .conceptBlock:
            focusDuration = preferences.conceptBlockFocusMinutes * 60
            breakDuration = preferences.conceptBlockBreakMinutes * 60
            totalCycles = preferences.conceptBlockCycles
        case .deepBuild:
            focusDuration = preferences.deepBuildFocusMinutes * 60
            breakDuration = preferences.deepBuildBreakMinutes * 60
            totalCycles = preferences.deepBuildCycles
        case .simulationBurst:
            focusDuration = preferences.simulationBurstFocusMinutes * 60
            breakDuration = preferences.simulationBurstBreakMinutes * 60
            totalCycles = preferences.simulationBurstCycles
        case .stopwatch:
            focusDuration = 0
            breakDuration = 0
            totalCycles = 1
        }
    }

    private func runTimerLoop() async {
        while !_Concurrency.Task.isCancelled {
            try? await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                self.tick()
            }
        }
    }

    private func tick() {
        guard !isPaused else { return }

        switch state {
        case .idle:
            stopTimerLoop()
        case .focus:
            handleFocusTick()
        case .breakTime:
            handleBreakTick()
        }
    }

    private func handleFocusTick() {
        if mode == .stopwatch {
            remainingSeconds += 1
            focusAccumulated += 1
            return
        }

        guard remainingSeconds > 0 else {
            transitionToBreak()
            return
        }

        remainingSeconds -= 1
        focusAccumulated += 1

        if remainingSeconds == 0 {
            transitionToBreak()
        }
    }

    private func handleBreakTick() {
        guard remainingSeconds > 0 else {
            completeCycleAndTransition()
            return
        }

        remainingSeconds -= 1
        breakAccumulated += 1

        if remainingSeconds == 0 {
            completeCycleAndTransition()
        }
    }

    private func transitionToBreak() {
        guard mode != .stopwatch else { return }

        state = .breakTime
        remainingSeconds = breakDuration
    }

    private func completeCycleAndTransition() {
        cyclesCompleted += 1

        if cyclesCompleted < totalCycles {
            state = .focus
            remainingSeconds = mode == .stopwatch ? remainingSeconds : focusDuration
        } else {
            state = .idle
            remainingSeconds = 0
            stopTimerLoop()
        }
    }

    private func stopTimerLoop() {
        tickTask?.cancel()
        tickTask = nil
    }

    private func reset() {
        stopTimerLoop()
        state = .idle
        remainingSeconds = 0
        cyclesCompleted = 0
        totalCycles = 0
        focusDuration = 0
        breakDuration = 0
        focusAccumulated = 0
        breakAccumulated = 0
        breaksSkipped = 0
        activeBlockId = nil
        startedAt = nil
        isPaused = false
    }
}
