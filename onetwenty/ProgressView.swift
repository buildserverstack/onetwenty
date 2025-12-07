import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var appStore: AppStore

    private var completedDaysCount: Int {
        let ids = Set(appStore.reflections.map { $0.dayPlanId })
        return ids.count
    }

    private var focusBreakdown: [(FocusMode, Int)] {
        var totals: [FocusMode: Int] = [:]
        for session in appStore.timerSessions {
            totals[session.mode, default: 0] += session.focusSeconds
        }
        return totals.sorted { $0.key.displayName < $1.key.displayName }
    }

    private var dueCards: [ReviewCard] {
        appStore.reviewItemsDueToday()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summarySection
                focusSection
                revisionSection
            }
            .padding()
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress Overview")
                .font(.title2)
            Text("Completed days: \(completedDaysCount)")
                .font(.headline)
        }
    }

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timer Sessions")
                .font(.headline)

            if focusBreakdown.isEmpty {
                Text("No timer sessions logged yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(focusBreakdown, id: \.0) { mode, seconds in
                    HStack {
                        Text(mode.displayName)
                        Spacer()
                        Text(formattedDuration(seconds))
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var revisionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Revision Queue")
                .font(.headline)

            if dueCards.isEmpty {
                Text("No review cards due today.")
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(dueCards) { card in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(card.type.displayName)
                                    .font(.subheadline)
                                Spacer()
                                Text(card.dueDate, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text(derivedLabel(for: card))
                                .font(.body)

                            HStack {
                                Button("Done") {
                                    appStore.handleReviewResult(card: card, hard: false)
                                }
                                Button("Hard") {
                                    appStore.handleReviewResult(card: card, hard: true)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private func derivedLabel(for card: ReviewCard) -> String {
        switch card.type {
        case .pattern:
            return appStore.patternNotes.first(where: { $0.id == card.referenceId })?.name ?? "Pattern"
        case .mlTopic:
            return "ML / LLM Topic"
        case .project:
            return appStore.projects.first(where: { $0.id == card.referenceId })?.name ?? "Project"
        case .behavioral:
            return appStore.behavioralStories.first(where: { $0.id == card.referenceId })?.question ?? "Behavioral Story"
        }
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, remainingMinutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}

private extension ReviewType {
    var displayName: String {
        switch self {
        case .pattern: return "Pattern"
        case .mlTopic: return "ML Topic"
        case .project: return "Project"
        case .behavioral: return "Behavioral"
        }
    }
}

#Preview {
    ProgressView()
        .environmentObject(AppStore())
        .environmentObject(TimerManager())
}
