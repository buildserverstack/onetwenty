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
        ZStack {
            AppColors.background.opacity(0.75)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Quick Capture")
                        .font(AppFonts.headline)
                        .primaryTextStyle()

                    Spacer()

                    Picker("Type", selection: $captureType) {
                        ForEach(CaptureType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(AppColors.accent)
                    .frame(maxWidth: 220)
                }

                VoiceDictationField(text: $content, placeholder: "Speak or type your note…")
                    .frame(minHeight: 140)

                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .secondaryTextStyle()

                    Spacer()

                    Button {
                        handleSave()
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppColors.accent)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                }
            }
            .frame(maxWidth: 380)
            .cardBackground()
            .padding()
        }
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
        appStore.isQuickCaptureVisible = false
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
