import Foundation
import Combine

final class AppStore: ObservableObject {
    @Published var dayPlans: [DayPlan]
    @Published var currentDay: DayPlan?
    @Published var reflections: [Reflection]
    @Published var timerSessions: [TimerSession]
    @Published var patternNotes: [PatternNote]
    @Published var mlNotes: [MLNote]
    @Published var projects: [Project]
    @Published var behavioralStories: [BehavioralStory]
    @Published var reviewCards: [ReviewCard]
    @Published var showQuickCapture: Bool

    init(
        dayPlans: [DayPlan] = [],
        currentDay: DayPlan? = nil,
        reflections: [Reflection] = [],
        timerSessions: [TimerSession] = [],
        patternNotes: [PatternNote] = [],
        mlNotes: [MLNote] = [],
        projects: [Project] = [],
        behavioralStories: [BehavioralStory] = [],
        reviewCards: [ReviewCard] = [],
        showQuickCapture: Bool = false
    ) {
        self.dayPlans = dayPlans
        self.currentDay = currentDay
        self.reflections = reflections
        self.timerSessions = timerSessions
        self.patternNotes = patternNotes
        self.mlNotes = mlNotes
        self.projects = projects
        self.behavioralStories = behavioralStories
        self.reviewCards = reviewCards
        self.showQuickCapture = showQuickCapture
    }

    func loadInitialData() {
        let day1Id = UUID()
        let block1Id = UUID()
        let block1 = Block(
            id: block1Id,
            dayPlanId: day1Id,
            type: .dsa,
            title: "DSA Warmup",
            description: "Practice arrays and strings",
            defaultMode: .focusedDrill,
            isCompleted: false,
            tasks: [
                Task(id: UUID(), blockId: block1Id, title: "Solve two easy problems", isDone: false),
                Task(id: UUID(), blockId: block1Id, title: "Review string manipulation", isDone: false)
            ]
        )

        let block2Id = UUID()
        let block2 = Block(
            id: block2Id,
            dayPlanId: day1Id,
            type: .ml,
            title: "ML Concept",
            description: "Study gradient descent",
            defaultMode: .conceptBlock,
            isCompleted: false,
            tasks: [
                Task(id: UUID(), blockId: block2Id, title: "Read notes", isDone: false),
                Task(id: UUID(), blockId: block2Id, title: "Implement toy example", isDone: false)
            ]
        )

        let sampleDay = DayPlan(
            id: day1Id,
            dayNumber: 1,
            phase: "Foundations",
            title: "Kickoff",
            blocks: [block1, block2]
        )

        let projectId = UUID()
        let sampleProject = Project(
            id: projectId,
            name: "ML Playground",
            description: "Experiments with small datasets",
            entries: []
        )

        let note = PatternNote(
            id: UUID(),
            name: "Two Sum",
            summary: "Use hashmap to store complements",
            decisionRules: "When searching for pairs in O(n)",
            smells: ["Sorting not allowed", "Need O(n)"],
            templateCode: "func twoSum(...) -> ...",
            edgeCases: ["Empty array", "No solution"],
            lastReviewed: nil
        )

        let mlNote = MLNote(
            id: UUID(),
            title: "Transformer intuition",
            details: "Quick reminder about attention and scaling laws.",
            createdAt: Date()
        )

        dayPlans = [sampleDay]
        currentDay = sampleDay
        patternNotes = [note]
        mlNotes = [mlNote]
        projects = [sampleProject]
    }

    func goToDay(_ dayNumber: Int) {
        currentDay = dayPlans.first { $0.dayNumber == dayNumber }
    }

    func markDayCompleted(_ dayPlan: DayPlan, rating: Int, reflection: Reflection) {
        var updatedPlan = dayPlan
        updatedPlan.blocks = dayPlan.blocks.map { block in
            var mutableBlock = block
            mutableBlock.isCompleted = true
            return mutableBlock
        }

        if let index = dayPlans.firstIndex(where: { $0.id == dayPlan.id }) {
            dayPlans[index] = updatedPlan
        }

        var newReflection = reflection
        newReflection.rating = rating
        reflections.append(newReflection)
        currentDay = updatedPlan
    }

    func addTimerSession(_ session: TimerSession) {
        timerSessions.append(session)
    }

    func addPatternNote(_ note: PatternNote) {
        patternNotes.append(note)
    }

    func addMLNote(_ note: MLNote) {
        mlNotes.append(note)
    }

    func addProjectEntry(_ entry: ProjectJournalEntry, to projectId: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[index].entries.append(entry)
    }

    func addProjectBugEntry(description: String) {
        var targetProjectId: UUID

        if let firstProject = projects.first {
            targetProjectId = firstProject.id
        } else {
            let newProjectId = UUID()
            let placeholder = Project(
                id: newProjectId,
                name: "Quick Capture Bugs",
                description: "Auto-created for quick captured bugs",
                entries: []
            )
            projects.append(placeholder)
            targetProjectId = newProjectId
        }

        let entry = ProjectJournalEntry(
            id: UUID(),
            projectId: targetProjectId,
            date: Date(),
            whatIDid: "", 
            whatILearned: "", 
            whatBroke: description,
            nextStep: ""
        )

        addProjectEntry(entry, to: targetProjectId)
    }

    func addBehavioralStory(_ story: BehavioralStory) {
        behavioralStories.append(story)
    }

    func enqueueReviewCard(for type: ReviewType, referenceId: UUID, dueDate: Date) {
        let card = ReviewCard(
            id: UUID(),
            type: type,
            referenceId: referenceId,
            dueDate: dueDate,
            easeScore: 0
        )
        reviewCards.append(card)
    }

    func getReflections(for dayPlanId: UUID) -> [Reflection] {
        reflections.filter { $0.dayPlanId == dayPlanId }
    }

    func reviewItemsDueToday() -> [ReviewCard] {
        let today = Calendar.current.startOfDay(for: Date())
        return reviewCards
            .filter { Calendar.current.startOfDay(for: $0.dueDate) <= today }
            .sorted { $0.dueDate < $1.dueDate }
    }

    func handleReviewResult(card: ReviewCard, hard: Bool) {
        guard let index = reviewCards.firstIndex(where: { $0.id == card.id }) else { return }

        let easeAdjustment = hard ? -1 : 1
        let intervalDays = hard ? 1 : 3
        let newEase = max(0, reviewCards[index].easeScore + easeAdjustment)
        let newDueDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: Date()) ?? Date()

        reviewCards[index].easeScore = newEase
        reviewCards[index].dueDate = newDueDate
    }
}
