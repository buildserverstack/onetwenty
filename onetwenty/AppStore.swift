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

    /// Imports day plans from a CSV file. Expected headers (case-insensitive):
    /// dayNumber, date (optional), phase, title, dsaTopic, mlTopic, projectWork,
    /// mlopsFocus, communicationFocus, revisionTasks, resources.
    /// Each row becomes a DayPlan with blocks generated from the per-topic columns.
    func loadFromCSV(url: URL) throws {
        let content = try String(contentsOf: url)
        let rows = content.split(whereSeparator: { $0.isNewline })

        guard let header = rows.first else { return }
        let headers = parseColumns(from: String(header))
        let headerIndex = headers.enumerated().reduce(into: [String: Int]()) { dict, pair in
            dict[pair.element.lowercased()] = pair.offset
        }

        var importedPlans: [DayPlan] = []

        for line in rows.dropFirst() {
            let columns = parseColumns(from: String(line))
            if columns.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                continue
            }

            guard let dayNumberValue = value(for: "daynumber", in: columns, headerIndex: headerIndex),
                  let dayNumber = Int(dayNumberValue.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                continue
            }

            let phase = value(for: "phase", in: columns, headerIndex: headerIndex) ?? ""
            let title = value(for: "title", in: columns, headerIndex: headerIndex) ?? "Day \(dayNumber)"
            let dateValue = value(for: "date", in: columns, headerIndex: headerIndex)
            let parsedDate = parseDate(from: dateValue)
            let dayPlanId = UUID()
            var blocks: [Block] = []

            if let dsa = value(for: "dsatopic", in: columns, headerIndex: headerIndex), !dsa.isEmpty {
                blocks.append(createBlock(id: UUID(), dayPlanId: dayPlanId, type: .dsa, title: dsa, description: dsa))
            }

            if let ml = value(for: "mltopic", in: columns, headerIndex: headerIndex), !ml.isEmpty {
                blocks.append(createBlock(id: UUID(), dayPlanId: dayPlanId, type: .ml, title: ml, description: ml))
            }

            if let project = value(for: "projectwork", in: columns, headerIndex: headerIndex), !project.isEmpty {
                blocks.append(createBlock(id: UUID(), dayPlanId: dayPlanId, type: .project, title: project, description: project))
            }

            if let mlops = value(for: "mlopsfocus", in: columns, headerIndex: headerIndex), !mlops.isEmpty {
                blocks.append(createBlock(id: UUID(), dayPlanId: dayPlanId, type: .mlops, title: mlops, description: mlops))
            }

            if let comms = value(for: "communicationfocus", in: columns, headerIndex: headerIndex), !comms.isEmpty {
                blocks.append(createBlock(id: UUID(), dayPlanId: dayPlanId, type: .communication, title: comms, description: comms))
            }

            if let revision = value(for: "revisiontasks", in: columns, headerIndex: headerIndex), !revision.isEmpty {
                blocks.append(createRevisionBlock(from: revision, dayPlanId: dayPlanId))
            }

            let resourcesString = value(for: "resources", in: columns, headerIndex: headerIndex) ?? ""
            let resources = parseResources(from: resourcesString)

            let plan = DayPlan(
                id: dayPlanId,
                dayNumber: dayNumber,
                phase: phase,
                title: title,
                blocks: blocks,
                date: parsedDate,
                resources: resources
            )

            importedPlans.append(plan)
        }

        if !importedPlans.isEmpty {
            dayPlans = importedPlans.sorted { $0.dayNumber < $1.dayNumber }
            currentDay = importedPlans.sorted { $0.dayNumber < $1.dayNumber }.first
        }
    }

    // MARK: - CSV Helpers

    private func parseColumns(from line: String) -> [String] {
        // Simple CSV splitter that respects quoted values
        var columns: [String] = []
        var current = ""
        var insideQuotes = false

        for character in line {
            if character == "\"" {
                insideQuotes.toggle()
            } else if character == "," && !insideQuotes {
                columns.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }
        columns.append(current)

        return columns.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private func value(for key: String, in columns: [String], headerIndex: [String: Int]) -> String? {
        guard let index = headerIndex[key.lowercased()], index < columns.count else { return nil }
        return columns[index]
    }

    private func createBlock(id: UUID, dayPlanId: UUID, type: BlockType, title: String, description: String) -> Block {
        let task = Task(id: UUID(), blockId: id, title: title, isDone: false)
        return Block(
            id: id,
            dayPlanId: dayPlanId,
            type: type,
            title: title,
            description: description,
            defaultMode: defaultMode(for: type),
            isCompleted: false,
            tasks: [task]
        )
    }

    private func createRevisionBlock(from value: String, dayPlanId: UUID) -> Block {
        let blockId = UUID()
        let tasks = value
            .split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { Task(id: UUID(), blockId: blockId, title: $0, isDone: false) }

        let description = tasks.isEmpty ? value : "Revision tasks"

        return Block(
            id: blockId,
            dayPlanId: dayPlanId,
            type: .reflection,
            title: "Revision",
            description: description,
            defaultMode: .focusedDrill,
            isCompleted: false,
            tasks: tasks
        )
    }

    private func defaultMode(for type: BlockType) -> FocusMode {
        switch type {
        case .dsa: return .focusedDrill
        case .ml: return .conceptBlock
        case .project: return .deepBuild
        case .mlops: return .simulationBurst
        case .communication: return .conceptBlock
        case .reflection: return .focusedDrill
        }
    }

    private func parseResources(from value: String) -> [ResourceLink] {
        let entries = value.split(separator: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        var resources: [ResourceLink] = []

        for entry in entries {
            let parts = entry.split(separator: "|", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            let label: String
            let urlString: String

            if parts.count == 2 {
                label = parts[0].isEmpty ? "Resource" : parts[0]
                urlString = parts[1]
            } else {
                urlString = parts[0]
                label = URL(string: urlString)?.host ?? "Resource"
            }

            guard let url = URL(string: urlString) else { continue }
            let resource = ResourceLink(id: UUID(), label: label, url: url, tags: [])
            resources.append(resource)
        }

        return resources
    }

    private func parseDate(from value: String?) -> Date? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }

        if let isoDate = ISO8601DateFormatter().date(from: raw) {
            return isoDate
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: raw)
    }

    func goToDay(_ dayNumber: Int) {
        currentDay = dayPlans.first { $0.dayNumber == dayNumber }
    }

    func goToDate(_ date: Date) {
        let target = dayPlans.first { plan in
            guard let planDate = plan.date else { return false }
            return Calendar.current.isDate(planDate, inSameDayAs: date)
        }
        currentDay = target
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
