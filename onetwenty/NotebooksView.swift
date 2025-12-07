import SwiftUI

private enum NotebookSection: String, CaseIterable, Identifiable {
    case patterns = "DSA Patterns"
    case mlIntuition = "ML / LLM Intuition"
    case projects = "Projects"
    case behavioral = "Behavioral Stories"

    var id: String { rawValue }
    var title: String { rawValue }
}

struct NotebooksRootView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var selection: NotebookSection = .patterns

    var body: some View {
        VStack(alignment: .leading) {
            Picker("Notebook", selection: $selection) {
                ForEach(NotebookSection.allCases) { section in
                    Text(section.title).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding([.top, .horizontal])

            Divider()

            switch selection {
            case .patterns:
                PatternNotebookView()
            case .mlIntuition:
                MLIntuitionView()
            case .projects:
                ProjectsView()
            case .behavioral:
                BehavioralStoriesView()
            }
        }
    }
}

struct PatternNotebookView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var selectedNoteID: UUID?

    private var selectedNote: PatternNote? {
        appStore.patternNotes.first { $0.id == selectedNoteID } ?? appStore.patternNotes.first
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Patterns")
                        .font(.headline)
                    Spacer()
                    Button("New Pattern") {
                        let note = PatternNote(
                            id: UUID(),
                            name: "New Pattern",
                            summary: "Describe the approach",
                            decisionRules: "When to use it",
                            smells: ["Common pitfalls"],
                            templateCode: "// template code",
                            edgeCases: ["Edge case"],
                            lastReviewed: nil
                        )
                        appStore.addPatternNote(note)
                        selectedNoteID = note.id
                    }
                }

                List(appStore.patternNotes, selection: $selectedNoteID) { note in
                    VStack(alignment: .leading) {
                        Text(note.name)
                            .font(.headline)
                        Text(note.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(minWidth: 250)
            }

            Divider()

            if let note = selectedNote {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(note.name)
                            .font(.title2)
                        Text(note.summary)
                            .font(.body)
                        labeledSection(title: "Decision Rules", content: note.decisionRules)
                        labeledList(title: "Smells", items: note.smells)
                        labeledSection(title: "Template", content: note.templateCode)
                        labeledList(title: "Edge Cases", items: note.edgeCases)
                    }
                    .padding()
                }
            } else {
                Text("Select or create a pattern to view details.")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
    }

    @ViewBuilder
    private func labeledSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
        }
    }

    @ViewBuilder
    private func labeledList(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            if items.isEmpty {
                Text("No items")
                    .foregroundColor(.secondary)
            } else {
                ForEach(items, id: \.self) { item in
                    Text("• \(item)")
                }
            }
        }
    }
}

struct MLIntuitionView: View {
    struct MLNote: Identifiable {
        let id: UUID
        var title: String
        var createdAt: Date
        var details: String
    }

    @State private var notes: [MLNote] = [
        MLNote(id: UUID(), title: "Transformer intuition", createdAt: Date(), details: "Key ideas behind attention and scaling."),
        MLNote(id: UUID(), title: "Data centric approach", createdAt: Date(), details: "Validate, clean, and iterate on datasets.")
    ]
    @State private var selectedNoteID: UUID?

    private var selectedNoteBinding: Binding<MLNote?> {
        Binding<MLNote?> {
            notes.first { $0.id == selectedNoteID } ?? notes.first
        } set: { newValue in
            guard let newValue else { return }
            if let idx = notes.firstIndex(where: { $0.id == newValue.id }) {
                notes[idx] = newValue
            }
        }
    }

    private var selectedNote: MLNote? {
        selectedNoteBinding.wrappedValue
    }

    var body: some View {
        HStack(alignment: .top) {
            List(selection: $selectedNoteID) {
                ForEach(notes) { note in
                    VStack(alignment: .leading) {
                        Text(note.title)
                        Text(note.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(minWidth: 240)

            Divider()

            if var note = selectedNoteBinding.wrappedValue {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Title", text: Binding(get: { note.title }, set: { newValue in
                        note.title = newValue
                        selectedNoteBinding.wrappedValue = note
                    }))
                        .textFieldStyle(.roundedBorder)
                    Text("Created: \(note.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: Binding(get: { note.details }, set: { newValue in
                        note.details = newValue
                        selectedNoteBinding.wrappedValue = note
                    }))
                        .frame(minHeight: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3))
                        )
                    Spacer()
                }
                .padding()
            } else {
                Text("Select a note to view details.")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
    }
}

struct ProjectsView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var selectedProjectID: UUID?
    @State private var entryWhatIDid: String = ""
    @State private var entryWhatILearned: String = ""
    @State private var entryWhatBroke: String = ""
    @State private var entryNextStep: String = ""
    @State private var entryDate: Date = Date()

    private var selectedProject: Project? {
        appStore.projects.first { $0.id == selectedProjectID } ?? appStore.projects.first
    }

    var body: some View {
        HStack(alignment: .top) {
            List(appStore.projects, selection: $selectedProjectID) { project in
                VStack(alignment: .leading) {
                    Text(project.name)
                        .font(.headline)
                    Text("Entries: \(project.entries.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(minWidth: 220)

            Divider()

            if let project = selectedProject {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(project.name)
                            .font(.title2)
                        Text(project.description)
                            .font(.body)
                        Text("Journal Entries")
                            .font(.headline)
                        ForEach(project.entries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(entry.whatIDid)
                                    .font(.body)
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }

                        entryForm(projectId: project.id)
                    }
                    .padding()
                }
            } else {
                Text("Select a project to view details.")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
    }

    @ViewBuilder
    private func entryForm(projectId: UUID) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add Entry")
                .font(.headline)
            DatePicker("Date", selection: $entryDate, displayedComponents: [.date])
            TextField("What I did", text: $entryWhatIDid)
            TextField("What I learned", text: $entryWhatILearned)
            TextField("What broke", text: $entryWhatBroke)
            TextField("Next step", text: $entryNextStep)
            Button("Save Entry") {
                let entry = ProjectJournalEntry(
                    id: UUID(),
                    projectId: projectId,
                    date: entryDate,
                    whatIDid: entryWhatIDid,
                    whatILearned: entryWhatILearned,
                    whatBroke: entryWhatBroke,
                    nextStep: entryNextStep
                )
                appStore.addProjectEntry(entry, to: projectId)
                entryWhatIDid = ""
                entryWhatILearned = ""
                entryWhatBroke = ""
                entryNextStep = ""
                entryDate = Date()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct BehavioralStoriesView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var selectedStoryID: UUID?

    private var selectedStory: BehavioralStory? {
        appStore.behavioralStories.first { $0.id == selectedStoryID } ?? appStore.behavioralStories.first
    }

    var body: some View {
        HStack(alignment: .top) {
            List(appStore.behavioralStories, selection: $selectedStoryID) { story in
                VStack(alignment: .leading) {
                    Text(story.question)
                        .font(.headline)
                    if let tag = story.tags.first {
                        Text(tag)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(minWidth: 240)

            Divider()

            if let story = selectedStory {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        detailRow(label: "Question", value: story.question)
                        detailRow(label: "Situation", value: story.situation)
                        detailRow(label: "Task", value: story.task)
                        detailRow(label: "Action", value: story.action)
                        detailRow(label: "Result", value: story.result)
                        detailRow(label: "Learning", value: story.learning)
                        detailRow(label: "Tags", value: story.tags.joined(separator: ", "))
                    }
                    .padding()
                }
            } else {
                Text("Select a story to view details.")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.headline)
            Text(value)
                .font(.body)
        }
    }
}

#Preview {
    NotebooksRootView()
        .environmentObject(AppStore())
}
