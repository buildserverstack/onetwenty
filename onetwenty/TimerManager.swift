import Foundation
import Combine

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
    private var tickTask: Swift.Task<Void, Never>?
    private var isPaused = false

    func start(for blockId: UUID, mode: FocusMode) {
        stopTimerLoop()

        let defaults = defaults(for: mode)
        self.mode = mode
        focusDuration = defaults.focus
        breakDuration = defaults.break
        totalCycles = defaults.cycles
        remainingSeconds = mode == .stopwatch ? 0 : focusDuration
        cyclesCompleted = 0
        focusAccumulated = 0
        breakAccumulated = 0
        breaksSkipped = 0
        activeBlockId = blockId
        startedAt = Date()
        state = .focus
        isPaused = false

        tickTask = Swift.Task { [weak self] in
            await self?.runTimerLoop()
        }
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

    private func defaults(for mode: FocusMode) -> (focus: Int, break: Int, cycles: Int) {
        switch mode {
        case .focusedDrill:
            return (25 * 60, 5 * 60, 4)
        case .conceptBlock:
            return (40 * 60, 10 * 60, 2)
        case .deepBuild:
            return (50 * 60, 10 * 60, 3)
        case .simulationBurst:
            return (18 * 60, 4 * 60, 3)
        case .stopwatch:
            return (0, 0, 1)
        }
    }

    private func runTimerLoop() async {
        while !Swift.Task.isCancelled {
            try? await Swift.Task.sleep(nanoseconds: 1_000_000_000)
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
