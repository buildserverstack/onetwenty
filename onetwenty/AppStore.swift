import Foundation
import Combine

final class AppStore: ObservableObject {
    @Published var dayPlans: [DayPlan] = []
    @Published var currentDay: DayPlan?

    enum CSVLoadingError: Error {
        case missingRequiredColumn(String)
        case invalidDayNumber(String)
    }

    func loadFromCSV(url: URL) throws {
        let parser = CSVPlanLoader()
        let plans = try parser.loadPlans(from: url)
        let sortedPlans = plans.sorted { $0.dayNumber < $1.dayNumber }

        dayPlans = sortedPlans
        currentDay = sortedPlans.first
    }
}

private struct CSVPlanLoader {
    private let requiredColumns: [String] = [
        "daynumber",
        "date",
        "phase",
        "title",
        "dsatopic",
        "mltopic",
        "projectwork",
        "mlopsfocus",
        "communicationfocus",
        "revisiontasks",
        "resources"
    ]

    func loadPlans(from url: URL) throws -> [DayPlan] {
        let content = try String(contentsOf: url)
        let lines = content.split(whereSeparator: { $0.isNewline }).map(String.init)
        guard let headerLine = lines.first else { return [] }

        let headers = parse(line: headerLine).map { $0.lowercased() }
        try validate(headers: headers)

        let headerLookup = headers.enumerated().reduce(into: [String: Int]()) { result, header in
            result[header.element] = header.offset
        }

        return try lines
            .dropFirst()
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { line in
                let values = parse(line: line)
                return try makeDayPlan(values: values, headers: headerLookup)
            }
    }

    private func validate(headers: [String]) throws {
        for column in requiredColumns {
            if !headers.contains(column) {
                throw AppStore.CSVLoadingError.missingRequiredColumn(column)
            }
        }
    }

    private func makeDayPlan(values: [String], headers: [String: Int]) throws -> DayPlan {
        func value(for key: String) -> String {
            guard let index = headers[key], index < values.count else { return "" }
            return values[index].trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let dayNumberString = value(for: "daynumber")
        guard let dayNumber = Int(dayNumberString) else {
            throw AppStore.CSVLoadingError.invalidDayNumber(dayNumberString)
        }

        let isoFormatter = ISO8601DateFormatter()
        let dateString = value(for: "date")
        let parsedDate = dateString.isEmpty ? nil : isoFormatter.date(from: dateString)

        let dsaTopic = value(for: "dsatopic")
        let mlTopic = value(for: "mltopic")
        let projectWork = value(for: "projectwork")
        let mlopsFocus = value(for: "mlopsfocus")
        let communicationFocus = value(for: "communicationfocus")
        let revisionTasks = splitList(value(for: "revisiontasks"))
        let resources = parseResources(value(for: "resources"))

        let blocks = buildBlocks(
            dsaTopic: dsaTopic,
            mlTopic: mlTopic,
            projectWork: projectWork,
            mlopsFocus: mlopsFocus,
            communicationFocus: communicationFocus,
            revisionTasks: revisionTasks,
            resources: resources
        )

        return DayPlan(
            dayNumber: dayNumber,
            date: parsedDate,
            phase: value(for: "phase"),
            title: value(for: "title"),
            dsaTopic: dsaTopic,
            mlTopic: mlTopic,
            projectWork: projectWork,
            mlopsFocus: mlopsFocus,
            communicationFocus: communicationFocus,
            revisionTasks: revisionTasks,
            resources: resources,
            blocks: blocks
        )
    }

    private func parseResources(_ input: String) -> [ResourceLink] {
        splitList(input).compactMap { entry in
            let parts = entry.split(separator: "|", maxSplits: 1).map(String.init)
            let label: String
            let urlString: String

            if parts.count == 2 {
                label = parts[0]
                urlString = parts[1]
            } else if let value = parts.first {
                label = value
                urlString = value
            } else {
                return nil
            }

            guard let url = URL(string: urlString) else { return nil }
            return ResourceLink(label: label, url: url)
        }
    }

    private func buildBlocks(
        dsaTopic: String,
        mlTopic: String,
        projectWork: String,
        mlopsFocus: String,
        communicationFocus: String,
        revisionTasks: [String],
        resources: [ResourceLink]
    ) -> [Block] {
        var blocks: [Block] = []

        if !dsaTopic.isEmpty {
            blocks.append(Block(title: "DSA", tasks: [Task(title: dsaTopic, link: nil)]))
        }

        if !mlTopic.isEmpty {
            blocks.append(Block(title: "Machine Learning", tasks: [Task(title: mlTopic, link: nil)]))
        }

        if !projectWork.isEmpty {
            blocks.append(Block(title: "Project Work", tasks: [Task(title: projectWork, link: nil)]))
        }

        if !mlopsFocus.isEmpty {
            blocks.append(Block(title: "MLOps Focus", tasks: [Task(title: mlopsFocus, link: nil)]))
        }

        if !communicationFocus.isEmpty {
            blocks.append(Block(title: "Communication Focus", tasks: [Task(title: communicationFocus, link: nil)]))
        }

        if !revisionTasks.isEmpty {
            blocks.append(Block(title: "Revision Tasks", tasks: revisionTasks.map { Task(title: $0, link: nil) }))
        }

        if !resources.isEmpty {
            blocks.append(Block(title: "Resources", tasks: resources.map { Task(title: $0.label, link: $0.url) }))
        }

        return blocks
    }

    private func splitList(_ input: String) -> [String] {
        input
            .split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func parse(line: String) -> [String] {
        var values: [String] = []
        var current = ""
        var isInQuotes = false
        var iterator = line.makeIterator()

        while let character = iterator.next() {
            if character == "\"" {
                if isInQuotes {
                    if let next = iterator.next() {
                        if next == "\"" {
                            current.append("\"")
                        } else if next == "," {
                            values.append(current)
                            current = ""
                            isInQuotes = false
                            continue
                        } else {
                            current.append(next)
                            isInQuotes = false
                        }
                    } else {
                        isInQuotes = false
                    }
                } else {
                    isInQuotes = true
                }
            } else if character == "," && !isInQuotes {
                values.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }

        values.append(current)
        return values
    }
}
