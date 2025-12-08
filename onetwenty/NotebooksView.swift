import SwiftUI

private enum NotebookSection: String, CaseIterable, Identifiable {
    case patterns = "Patterns"
    case mlIntuition = "ML / LLM"
    case projects = "Projects"
    case behavioral = "Behavioral"

    var id: String { rawValue }
    var title: String { rawValue }
}

struct NotebooksRootView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var selection: NotebookSection = .patterns

    var body: some View {
        VStack(spacing: 12) {
            tabBar
            Divider()
                .overlay(AppColors.border)
                .padding(.horizontal)

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
        .padding(.top, 12)
        .background(AppColors.background.ignoresSafeArea())
    }

    private var tabBar: some View {
        HStack(spacing: 10) {
            ForEach(NotebookSection.allCases) { section in
                Button {
                    selection = section
                } label: {
                    Text(section.title)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .font(.headline)
                        .foregroundColor(selection == section ? AppColors.textPrimary : AppColors.textSecondary)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selection == section ? AppColors.accent : AppColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
}

struct PatternNotebookView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var selectedNoteID: UUID?

    private var selectedNote: PatternNote? {
        appStore.patternNotes.first { $0.id == selectedNoteID } ?? appStore.patternNotes.first
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 900
            ScrollView {
                adaptiveLayout(isCompact: isCompact)
            }
            .padding()
            .background(AppColors.background)
        }
    }

    @ViewBuilder
    private func adaptiveLayout(isCompact: Bool) -> some View {
        if isCompact {
            VStack(spacing: 16) {
                patternList
                patternDetail
            }
        } else {
            HStack(alignment: .top, spacing: 16) {
                patternList
                    .frame(width: 340)
                patternDetail
            }
        }
    }

    private var patternList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DSA Patterns")
                    .sectionTitleStyle()
                Spacer()
                Button {
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
                } label: {
                    Label("New Pattern", systemImage: "plus")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppColors.accent)
                        .foregroundColor(AppColors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 10) {
                ForEach(appStore.patternNotes) { note in
                    Button {
                        selectedNoteID = note.id
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.name)
                                .sectionTitleStyle()
                            Text(note.summary)
                                .secondaryTextStyle()
                                .lineLimit(2)
                            if !note.smells.isEmpty {
                                tagWrap(note.smells)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedNoteID == note.id ? AppColors.accent : AppColors.border, lineWidth: selectedNoteID == note.id ? 2 : 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var patternDetail: some View {
        Group {
            if let note = selectedNote {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(for: note)
                        Divider().overlay(AppColors.border)
                        labeledSection(title: "Decision Rules", content: note.decisionRules)
                        labeledList(title: "Smells", items: note.smells)
                        labeledSection(title: "Template", content: note.templateCode)
                        labeledList(title: "Edge Cases", items: note.edgeCases)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .cardBackground()
            } else {
                Text("Select or create a pattern to view details.")
                    .secondaryTextStyle()
                    .cardBackground()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func header(for note: PatternNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.name)
                .sectionTitleStyle()
            Text(note.summary)
                .secondaryTextStyle()
        }
    }

    @ViewBuilder
    private func labeledSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .primaryTextStyle()
            Text(content)
                .secondaryTextStyle()
        }
    }

    @ViewBuilder
    private func labeledList(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .primaryTextStyle()
            if items.isEmpty {
                Text("No items")
                    .secondaryTextStyle()
            } else {
                ForEach(items, id: \.self) { item in
                    Text("• \(item)")
                        .secondaryTextStyle()
                }
            }
        }
    }

    @ViewBuilder
    private func tagWrap(_ tags: [String]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.surfaceElevated)
                    .foregroundColor(AppColors.textSecondary)
                    .clipShape(Capsule())
            }
        }
    }
}

struct MLIntuitionView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var selectedNoteID: UUID?

    private var selectedNote: MLNote? {
        appStore.mlNotes.first { $0.id == selectedNoteID } ?? appStore.mlNotes.first
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 900
            ScrollView {
                if isCompact {
                    VStack(spacing: 16) {
                        mlList
                        mlDetail
                    }
                } else {
                    HStack(alignment: .top, spacing: 16) {
                        mlList.frame(width: 320)
                        mlDetail
                    }
                }
            }
            .padding()
            .background(AppColors.background)
        }
    }

    private var mlList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ML / LLM Intuition")
                .sectionTitleStyle()
            VStack(spacing: 10) {
                ForEach(appStore.mlNotes) { note in
                    Button {
                        selectedNoteID = note.id
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .primaryTextStyle()
                            Text(note.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            Text(note.details)
                                .secondaryTextStyle()
                                .lineLimit(2)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedNoteID == note.id ? AppColors.accent : AppColors.border, lineWidth: selectedNoteID == note.id ? 2 : 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mlDetail: some View {
        Group {
            if let note = selectedNote {
                VStack(alignment: .leading, spacing: 14) {
                    Text(note.title)
                        .sectionTitleStyle()
                    Text("Created: \(note.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    VoiceDictationField(
                        text: Binding(get: { note.details }, set: { newValue in
                            update(note: note, details: newValue)
                        }),
                        placeholder: "Describe the ML / LLM intuition"
                    )
                    .frame(minHeight: 200)
                }
                .padding()
                .cardBackground()
            } else {
                Text("Select a note to view details.")
                    .secondaryTextStyle()
                    .cardBackground()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func update(note: MLNote, details: String) {
        if let idx = appStore.mlNotes.firstIndex(where: { $0.id == note.id }) {
            var updated = note
            updated.details = details
            appStore.mlNotes[idx] = updated
            selectedNoteID = note.id
        }
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
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 960
            ScrollView {
                if isCompact {
                    VStack(spacing: 16) {
                        projectList
                        projectDetail
                    }
                } else {
                    HStack(alignment: .top, spacing: 16) {
                        projectList.frame(width: 320)
                        projectDetail
                    }
                }
            }
            .padding()
            .background(AppColors.background)
        }
    }

    private var projectList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Projects")
                .sectionTitleStyle()
            VStack(spacing: 10) {
                ForEach(appStore.projects) { project in
                    Button {
                        selectedProjectID = project.id
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(project.name)
                                .primaryTextStyle()
                            Text(project.description)
                                .secondaryTextStyle()
                                .lineLimit(2)
                            Text("Entries: \(project.entries.count)")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedProjectID == project.id ? AppColors.accent : AppColors.border, lineWidth: selectedProjectID == project.id ? 2 : 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var projectDetail: some View {
        Group {
            if let project = selectedProject {
                VStack(alignment: .leading, spacing: 16) {
                    Text(project.name)
                        .sectionTitleStyle()
                    Text(project.description)
                        .secondaryTextStyle()
                    Divider().overlay(AppColors.border)
                    Text("Journal Entries")
                        .primaryTextStyle()
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(project.entries.sorted(by: { $0.date > $1.date })) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text(entry.whatIDid)
                                    .primaryTextStyle()
                                if !entry.whatILearned.isEmpty {
                                    Text("Learned: \(entry.whatILearned)")
                                        .secondaryTextStyle()
                                }
                                if !entry.whatBroke.isEmpty {
                                    Text("Broke: \(entry.whatBroke)")
                                        .secondaryTextStyle()
                                }
                                if !entry.nextStep.isEmpty {
                                    Text("Next: \(entry.nextStep)")
                                        .secondaryTextStyle()
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(AppColors.surfaceElevated))
                        }
                    }

                    Divider().overlay(AppColors.border)
                    entryForm(projectId: project.id)
                }
                .padding()
                .cardBackground()
            } else {
                Text("Select a project to view details.")
                    .secondaryTextStyle()
                    .cardBackground()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func entryForm(projectId: UUID) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add Entry")
                .primaryTextStyle()
            DatePicker("Date", selection: $entryDate, displayedComponents: [.date])
                .labelsHidden()
                .padding(8)
                .background(AppColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VoiceDictationField(text: $entryWhatIDid, placeholder: "What I did")
            TextField("What I learned", text: $entryWhatILearned)
                .textFieldStyle(.roundedBorder)
            VoiceDictationField(text: $entryWhatBroke, placeholder: "What broke")
            TextField("Next step", text: $entryNextStep)
                .textFieldStyle(.roundedBorder)
            Button {
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
            } label: {
                Text("Save Entry")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.accent)
                    .foregroundColor(AppColors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
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
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 900
            ScrollView {
                if isCompact {
                    VStack(spacing: 16) {
                        storyList
                        storyDetail
                    }
                } else {
                    HStack(alignment: .top, spacing: 16) {
                        storyList.frame(width: 320)
                        storyDetail
                    }
                }
            }
            .padding()
            .background(AppColors.background)
        }
    }

    private var storyList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Behavioral Stories")
                .sectionTitleStyle()
            VStack(spacing: 10) {
                ForEach(appStore.behavioralStories) { story in
                    Button {
                        selectedStoryID = story.id
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(story.question)
                                .primaryTextStyle()
                                .lineLimit(2)
                            if !story.tags.isEmpty {
                                tagWrap(story.tags)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedStoryID == story.id ? AppColors.accent : AppColors.border, lineWidth: selectedStoryID == story.id ? 2 : 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var storyDetail: some View {
        Group {
            if let story = selectedStory {
                VStack(alignment: .leading, spacing: 12) {
                    Text(story.question)
                        .sectionTitleStyle()
                    detailRow(label: "Situation", value: story.situation)
                    detailRow(label: "Task", value: story.task)
                    detailRow(label: "Action", value: story.action)
                    detailRow(label: "Result", value: story.result)
                    detailRow(label: "Learning", value: story.learning)
                    detailRow(label: "Tags", value: story.tags.joined(separator: ", "))
                }
                .padding()
                .cardBackground()
            } else {
                Text("Select a story to view details.")
                    .secondaryTextStyle()
                    .cardBackground()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .primaryTextStyle()
            Text(value)
                .secondaryTextStyle()
        }
    }

    @ViewBuilder
    private func tagWrap(_ tags: [String]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.surfaceElevated)
                    .foregroundColor(AppColors.textSecondary)
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    NotebooksRootView()
        .environmentObject(AppStore())
}
