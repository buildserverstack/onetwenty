import SwiftUI

struct QuickCaptureView: View {
    enum CaptureType: String, CaseIterable, Identifiable {
        case pattern = "Pattern"
        case mlIdea = "ML Idea"
        case projectBug = "Project Bug"
        case behavioral = "Behavioral Story"

        var id: String { rawValue }
    }

    @EnvironmentObject var appStore: AppStore
    @State private var captureType: CaptureType = .pattern
    @State private var content: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Type", selection: $captureType) {
                ForEach(CaptureType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            VoiceDictationField(text: $content, placeholder: "Capture notes quickly")
                .frame(minHeight: 120)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    handleSave()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 360)
    }

    private func handleSave() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch captureType {
        case .pattern:
            let note = PatternNote(
                id: UUID(),
                name: titleFromContent(defaultName: "New Pattern"),
                summary: trimmed,
                decisionRules: "",
                smells: [],
                templateCode: "",
                edgeCases: [],
                lastReviewed: nil
            )
            appStore.addPatternNote(note)
        case .mlIdea:
            let note = MLNote(
                id: UUID(),
                title: titleFromContent(defaultName: "ML Idea"),
                details: trimmed,
                createdAt: Date()
            )
            appStore.addMLNote(note)
        case .projectBug:
            appStore.addProjectBugEntry(description: trimmed)
        case .behavioral:
            let story = BehavioralStory(
                id: UUID(),
                question: titleFromContent(defaultName: "Behavioral Story"),
                situation: trimmed,
                task: "",
                action: "",
                result: "",
                learning: "",
                tags: []
            )
            appStore.addBehavioralStory(story)
        }

        dismiss()
    }

    private func dismiss() {
        content = ""
        appStore.showQuickCapture = false
    }

    private func titleFromContent(defaultName: String) -> String {
        let lines = content.split(separator: "\n")
        return lines.first.map { String($0) } ?? defaultName
    }
}

#Preview {
    QuickCaptureView()
        .environmentObject(AppStore())
}
