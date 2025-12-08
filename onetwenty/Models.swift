import Foundation

struct ResourceLink: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let url: URL
}

struct Task: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let link: URL?
}

struct Block: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let tasks: [Task]
}

struct DayPlan: Identifiable, Equatable {
    let id = UUID()
    let dayNumber: Int
    let date: Date?
    let phase: String
    let title: String
    let dsaTopic: String
    let mlTopic: String
    let projectWork: String
    let mlopsFocus: String
    let communicationFocus: String
    let revisionTasks: [String]
    let resources: [ResourceLink]
    let blocks: [Block]
}
