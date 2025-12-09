import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var selectedFilter: ReviewFilter = .all
    @State private var showFutureCards = false

    private var completedDaysCount: Int {
        let ids = Set(appStore.reflections.map { $0.dayPlanId })
        return ids.count
    }

    private var focusBreakdown: [(FocusMode, Int)] {
        var totals: [FocusMode: Int] = [:]
        for session in appStore.timerSessions {
            totals[session.mode, default: 0] += session.focusSeconds
        }
        return totals.sorted { $0.value > $1.value }
    }

    private var topModeLabel: String {
        guard let top = focusBreakdown.first else { return "No data yet" }
        return top.0.displayName
    }

    private var totalFocusHours: Int {
        let totalSeconds = appStore.timerSessions.reduce(0) { $0 + $1.focusSeconds }
        return Int(round(Double(totalSeconds) / 3600.0))
    }

    private var activeStreak: Int {
        let days = appStore.reflections.map { $0.dayPlanId }
        let plansById = Dictionary(uniqueKeysWithValues: appStore.dayPlans.map { ($0.id, $0) })
        let dayNumbers = days.compactMap { plansById[$0]?.dayNumber }.sorted()
        guard !dayNumbers.isEmpty else { return 0 }

        var streak = 1
        var current = 1
        for pair in zip(dayNumbers.dropFirst(), dayNumbers) {
            if pair.0 == pair.1 + 1 {
                current += 1
            } else {
                streak = max(streak, current)
                current = 1
            }
        }
        streak = max(streak, current)
        return streak
    }

    private var scheduledBreaks: Int { appStore.totalBreaksScheduled() }
    private var skippedBreaks: Int { appStore.totalBreaksSkipped() }
    private var complianceRate: Double { appStore.breakComplianceRate() }
    private var complianceText: String { String(format: "%.0f%%", complianceRate * 100) }

    private var dueCards: [ReviewCard] {
        let items = appStore.reviewItemsDueToday()
        guard let type = selectedFilter.reviewType else { return items }
        return items.filter { $0.type == type }
    }

    private var futureCards: [ReviewCard] {
        let type = selectedFilter.reviewType
        return appStore.upcomingReviewItems(type: type)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                statGrid
                revisionSection
                breakSection
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.background)
    }

    private var statGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Dashboard")
                .font(AppFonts.title)
                .primaryTextStyle()

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    statCard(title: "Days Completed", value: "\(completedDaysCount)", subtitle: "Logged reflections")
                    statCard(title: "Total Focus Time", value: "\(totalFocusHours)h", subtitle: "Mostly \(topModeLabel)")
                    statCard(title: "Active Streak", value: "\(activeStreak)", subtitle: "Consecutive days")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func statCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.caption)
                .secondaryTextStyle()

            Text(value)
                .font(AppFonts.title)
                .primaryTextStyle()

            Text(subtitle)
                .font(AppFonts.body)
                .secondaryTextStyle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
        .background(AppColors.surface)
    }

    private var revisionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Revision Queue")
                .sectionTitleStyle()

            filterControls

            if dueCards.isEmpty {
                Text("No review cards due today.")
                    .secondaryTextStyle()
            } else {
                VStack(spacing: 10) {
                    ForEach(dueCards) { card in
                        revisionCard(card)
                    }
                }
            }

            if showFutureCards {
                Divider().background(AppColors.border)
                Text("Upcoming")
                    .font(AppFonts.headline)
                    .primaryTextStyle()

                if futureCards.isEmpty {
                    Text("No upcoming cards queued.")
                        .secondaryTextStyle()
                } else {
                    VStack(spacing: 10) {
                        ForEach(futureCards) { card in
                            revisionCard(card)
                        }
                    }
                }
            }
        }
        .cardBackground()
    }

    private func revisionCard(_ card: ReviewCard) -> some View {
        HStack(spacing: 12) {
            icon(for: card.type)
                .foregroundColor(AppColors.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(derivedLabel(for: card))
                    .font(AppFonts.body)
                    .primaryTextStyle()
                Text(card.dueDate, style: .date)
                    .font(AppFonts.caption)
                    .secondaryTextStyle()
            }
            Spacer()

            HStack(spacing: 8) {
                Button("Done") {
                    appStore.handleReviewResult(card: card, hard: false)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppColors.accent.opacity(0.2))
                .foregroundColor(AppColors.textPrimary)
                .clipShape(Capsule())

                Button("Hard") {
                    appStore.handleReviewResult(card: card, hard: true)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .overlay(Capsule().stroke(AppColors.accent, lineWidth: 1))
                .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding()
        .background(AppColors.surfaceElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var filterControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(ReviewFilter.allCases) { filter in
                    Text(filter.title)
                        .tag(filter)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Show future cards", isOn: $showFutureCards)
                .toggleStyle(.switch)
                .font(AppFonts.body)
                .primaryTextStyle()
        }
        .tint(AppColors.accent)
    }

    private var breakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Break Discipline")
                .sectionTitleStyle()

            if scheduledBreaks == 0 {
                Text("No breaks recorded yet.")
                    .secondaryTextStyle()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Scheduled breaks")
                            .secondaryTextStyle()
                        Spacer()
                        Text("\(scheduledBreaks)")
                            .primaryTextStyle()
                    }

                    HStack {
                        Text("Skipped breaks")
                            .secondaryTextStyle()
                        Spacer()
                        Text("\(skippedBreaks)")
                            .primaryTextStyle()
                    }

                    HStack {
                        Text("Compliance")
                            .secondaryTextStyle()
                        Spacer()
                        Text(complianceText)
                            .primaryTextStyle()
                            .monospacedDigit()
                    }

                    barForBreaks
                        .frame(height: 14)
                }
            }
        }
        .cardBackground()
    }

    private var barForBreaks: some View {
        let taken = max(scheduledBreaks - skippedBreaks, 0)
        let total = max(scheduledBreaks, 1)

        return GeometryReader { geometry in
            let takenWidth = geometry.size.width * CGFloat(taken) / CGFloat(total)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(AppColors.surfaceElevated)
                RoundedRectangle(cornerRadius: 7)
                    .fill(AppColors.accentSoft)
                RoundedRectangle(cornerRadius: 7)
                    .fill(AppColors.accent)
                    .frame(width: takenWidth)
            }
        }
    }

    private func icon(for type: ReviewType) -> some View {
        let name: String
        switch type {
        case .pattern: name = "square.stack"
        case .mlTopic: name = "brain.head.profile"
        case .project: name = "hammer"
        case .behavioral: name = "person.2.circle"
        }
        return Image(systemName: name)
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
}

#Preview {
    ProgressView()
        .environmentObject(AppStore())
        .environmentObject(TimerManager())
}

private enum ReviewFilter: String, CaseIterable, Identifiable {
    case all
    case patterns
    case ml
    case projects
    case behavioral

    var id: String { rawValue }

    var reviewType: ReviewType? {
        switch self {
        case .all: return nil
        case .patterns: return .pattern
        case .ml: return .mlTopic
        case .projects: return .project
        case .behavioral: return .behavioral
        }
    }

    var title: String {
        switch self {
        case .all: return "All"
        case .patterns: return "Patterns"
        case .ml: return "ML"
        case .projects: return "Projects"
        case .behavioral: return "Behavioral"
        }
    }
}
