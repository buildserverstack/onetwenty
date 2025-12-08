import Foundation

// MARK: - Enums

enum BlockType: String, Codable, CaseIterable {
    case dsa
    case ml
    case project
    case mlops
    case communication
    case reflection
}

enum FocusMode: String, Codable, CaseIterable {
    case focusedDrill
    case conceptBlock
    case deepBuild
    case simulationBurst
    case stopwatch
}

enum ReviewType: String, Codable, CaseIterable {
    case pattern
    case mlTopic
    case project
    case behavioral
}

// MARK: - Entities

struct DayPlan: Identifiable, Codable {
    let id: UUID
    var dayNumber: Int
    var phase: String
    var title: String
    var blocks: [Block]
    var resources: [ResourceLink] = []
}

struct Block: Identifiable, Codable {
    let id: UUID
    var dayPlanId: UUID
    var type: BlockType
    var title: String
    var description: String
    var defaultMode: FocusMode
    var isCompleted: Bool
    var tasks: [Task]
}

struct Task: Identifiable, Codable {
    let id: UUID
    var blockId: UUID
    var title: String
    var isDone: Bool
}

struct ResourceLink: Identifiable, Codable {
    let id: UUID
    var label: String
    var url: URL
    var tags: [String]
}

struct TimerSession: Identifiable, Codable {
    let id: UUID
    var dayPlanId: UUID
    var blockId: UUID
    var mode: FocusMode
    var startedAt: Date
    var endedAt: Date?
    var focusSeconds: Int
    var breakSeconds: Int
    var cyclesCompleted: Int
    var breaksSkipped: Int
}

struct Reflection: Identifiable, Codable {
    let id: UUID
    var dayPlanId: UUID
    var mlInsights: [String]
    var dsaPattern: String
    var communicationLearning: String
    var mistake: String
    var questionForTomorrow: String
    var rating: Int
    var weaknessTags: [String]
}

struct PatternNote: Identifiable, Codable {
    let id: UUID
    var name: String
    var summary: String
    var decisionRules: String
    var smells: [String]
    var templateCode: String
    var edgeCases: [String]
    var lastReviewed: Date?
}

struct MLNote: Identifiable, Codable {
    let id: UUID
    var title: String
    var details: String
    var createdAt: Date
}

struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var entries: [ProjectJournalEntry]
}

struct ProjectJournalEntry: Identifiable, Codable {
    let id: UUID
    var projectId: UUID
    var date: Date
    var whatIDid: String
    var whatILearned: String
    var whatBroke: String
    var nextStep: String
}

struct BehavioralStory: Identifiable, Codable {
    let id: UUID
    var question: String
    var situation: String
    var task: String
    var action: String
    var result: String
    var learning: String
    var tags: [String]
}

struct ReviewCard: Identifiable, Codable {
    let id: UUID
    var type: ReviewType
    var referenceId: UUID
    var dueDate: Date
    var easeScore: Int
}
