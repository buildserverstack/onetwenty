import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case today
    case roadmap
    case notebooks
    case progress
    case interviewGym
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .roadmap: return "Roadmap"
        case .notebooks: return "Notebooks"
        case .progress: return "Progress"
        case .interviewGym: return "Interview Gym"
        case .settings: return "Settings"
        }
    }

    var systemImageName: String {
        switch self {
        case .today: return "sun.max"
        case .roadmap: return "map"
        case .notebooks: return "book"
        case .progress: return "chart.bar.doc.horizontal"
        case .interviewGym: return "bolt"
        case .settings: return "gear"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appStore: AppStore
    @EnvironmentObject var timerManager: TimerManager
    @State private var selectedItem: SidebarItem? = .today

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if appStore.dayPlans.isEmpty || appStore.startDayNumber == nil {
                OnboardingView()
                    .environmentObject(appStore)
            } else {
                NavigationSplitView {
                    SidebarView(selectedItem: $selectedItem)
                } detail: {
                    detailView(for: selectedItem)
                        .background(AppColors.background)
                }
                .tint(AppColors.accent)
                .toolbar {
                    ToolbarItemGroup(placement: .automatic) {
                        Button {
                            appStore.toggleQuickCapture()
                        } label: {
                            Label("Quick Capture", systemImage: "plus.bubble")
                        }
                    }
                }
                .sheet(
                    isPresented: Binding(get: { appStore.isQuickCaptureVisible }, set: { appStore.isQuickCaptureVisible = $0 })
                ) {
                    QuickCaptureView()
                        .environmentObject(appStore)
                        .background(AppColors.background)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func detailView(for item: SidebarItem?) -> some View {
        switch item {
        case .today, .none:
            TodayView()
        case .roadmap:
            RoadmapView()
        case .notebooks:
            NotebooksView()
        case .progress:
            ProgressView()
        case .interviewGym:
            InterviewGymView()
        case .settings:
            SettingsView()
        }
    }
}

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?

    var body: some View {
        List(SidebarItem.allCases, selection: $selectedItem) { item in
            Label(item.title, systemImage: item.systemImageName)
                .tag(item)
                .primaryTextStyle()
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .listRowBackground(AppColors.surface)
        .navigationTitle("AICoachMac")
        .tint(AppColors.accent)
    }
}

struct TodayView: View {
    @EnvironmentObject var appStore: AppStore
    @EnvironmentObject var timerManager: TimerManager
    @State private var selectedBlock: Block?

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 900

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DaySelectorView()
                        .environmentObject(appStore)
                        .cardBackground()

                    if let currentDay = appStore.currentDay {
                        if isCompact {
                            VStack(alignment: .leading, spacing: 16) {
                                blockList(for: currentDay)
                                detailPanel(for: currentDay)
                            }
                        } else {
                            HStack(alignment: .top, spacing: 16) {
                                blockList(for: currentDay)
                                    .frame(maxWidth: 340)
                                detailPanel(for: currentDay)
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        ReflectionCardView(dayPlan: currentDay)
                            .environmentObject(appStore)
                    } else {
                        Text("Select or create a day plan to get started.")
                            .font(.title3)
                            .secondaryTextStyle()
                            .cardBackground()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AppColors.background)
            .tint(AppColors.accent)
        }
    }

    private func blockList(for currentDay: DayPlan) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(currentDay.blocks, id: \.id) { block in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(block.title)
                                    .primaryTextStyle()
                                    .font(.headline)
                                Text(block.type.displayName)
                                    .secondaryTextStyle()
                                    .font(.caption)
                            }

                            Spacer()

                            if block.isCompleted {
                                Text("Done")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(AppColors.background)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppColors.accent)
                                    .clipShape(Capsule())
                            }
                        }

                        if !block.description.isEmpty {
                            Text(block.description)
                                .secondaryTextStyle()
                                .font(.subheadline)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedBlock?.id == block.id ? AppColors.surfaceElevated : AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedBlock?.id == block.id ? AppColors.accent : AppColors.border, lineWidth: 1)
                    )
                    .cornerRadius(10)
                    .onTapGesture {
                        selectedBlock = block
                    }
                }
            }
            .padding(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if selectedBlock == nil {
                selectedBlock = currentDay.blocks.first
            }
        }
        .onChange(of: appStore.currentDay?.id) { _ in
            selectedBlock = appStore.currentDay?.blocks.first
        }
        .background(AppColors.surfaceElevated.opacity(0.4))
        .cornerRadius(12)
    }

    private func detailPanel(for currentDay: DayPlan) -> some View {
        Group {
            if let block = selectedBlock {
                ScrollView {
                    BlockDetailView(block: block, dayPlan: currentDay)
                        .environmentObject(appStore)
                        .environmentObject(timerManager)
                }
                .cardBackground()
            } else {
                Text("Select a block to view details")
                    .secondaryTextStyle()
                    .cardBackground()
            }
        }
    }

}

struct RoadmapView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var selectedDayPlan: DayPlan?

    var body: some View {
        HStack(alignment: .top) {
            List(appStore.dayPlans) { day in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(day.dayNumber)")
                            .font(.headline)
                        Text(day.phase)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(day.title)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    let isCompleted = dayCompleted(day)
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCompleted ? .green : .secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedDayPlan = day
                }
            }
            .frame(minWidth: 280)
            .onAppear {
                if selectedDayPlan == nil {
                    selectedDayPlan = appStore.dayPlans.first
                }
            }

            Divider()

            if let dayPlan = selectedDayPlan {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Day \(dayPlan.dayNumber) • \(dayPlan.phase)")
                        .font(.title2)
                    Text(dayPlan.title)
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Blocks")
                            .font(.headline)
                        ForEach(dayPlan.blocks) { block in
                            HStack {
                                Image(systemName: block.type.systemImageName)
                                VStack(alignment: .leading) {
                                    Text(block.title)
                                        .font(.subheadline)
                                    Text(block.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    if let reflection = latestReflection(for: dayPlan) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Latest Reflection")
                                .font(.headline)
                            Text("Rating: \(reflection.rating)")
                            if !reflection.mlInsights.isEmpty {
                                Text("ML Insights: \(reflection.mlInsights.prefix(2).joined(separator: ", "))")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Button("Open as Today") {
                        appStore.currentDay = dayPlan
                    }

                    Spacer()
                }
                .padding()
            } else {
                Text("Select a day to view its details.")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }

    private func dayCompleted(_ dayPlan: DayPlan) -> Bool {
        if latestReflection(for: dayPlan) != nil {
            return true
        }

        let allBlocksCompleted = dayPlan.blocks.allSatisfy { $0.isCompleted }
        return allBlocksCompleted
    }

    private func latestReflection(for dayPlan: DayPlan) -> Reflection? {
        appStore.getReflections(for: dayPlan.id).last
    }
}

struct NotebooksView: View {
    var body: some View {
        NotebooksRootView()
    }
}

struct BlockDetailView: View {
    let block: Block
    let dayPlan: DayPlan

    @EnvironmentObject var appStore: AppStore
    @EnvironmentObject var timerManager: TimerManager
    @State private var workingBlock: Block

    init(block: Block, dayPlan: DayPlan) {
        self.block = block
        self.dayPlan = dayPlan
        _workingBlock = State(initialValue: block)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    summarySection

                    Divider().background(AppColors.border)

                    tasksSection

                    Divider().background(AppColors.border)

                    resourcesSection

                    Divider().background(AppColors.border)

                    timerSection
                }
                .cardBackground()
            }
            .padding()
        }
        .background(AppColors.background)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Text(workingBlock.title)
                    .font(.title2)
                    .primaryTextStyle()

                Spacer()

                Text(blockTypeLabel)
                    .font(.caption)
                    .secondaryTextStyle()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.surfaceElevated)
                    .clipShape(Capsule())
            }

            Text(workingBlock.description)
                .secondaryTextStyle()
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks")
                .sectionTitleStyle()

            if workingBlock.tasks.isEmpty {
                Text("No tasks for this block.")
                    .secondaryTextStyle()
            } else {
                VStack(spacing: 8) {
                    ForEach($workingBlock.tasks, id: \.id) { $task in
                        HStack(alignment: .center, spacing: 10) {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isDone ? AppColors.accent : AppColors.textSecondary)
                                .font(.title3)

                            Text(task.title)
                                .primaryTextStyle()

                            Spacer()
                        }
                        .padding(10)
                        .background(AppColors.surfaceElevated)
                        .cornerRadius(10)
                        .onTapGesture {
                            task.isDone.toggle()
                        }
                    }
                }
            }
        }
    }

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resources")
                .sectionTitleStyle()

            let resources = availableResources
            if resources.isEmpty {
                Text("No resources for this block yet.")
                    .secondaryTextStyle()
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(resources) { resource in
                        VStack(alignment: .leading, spacing: 4) {
                            Link(resource.label, destination: resource.url)
                                .foregroundColor(AppColors.accent)
                                .font(.body)

                            if let host = resource.url.host {
                                Text(host)
                                    .font(.caption)
                                    .secondaryTextStyle()
                            }
                        }
                    }
                }
            }
        }
    }

    private var availableResources: [ResourceLink] {
        if let blockResources = workingBlock.resources, !blockResources.isEmpty {
            return blockResources
        }
        return dayPlan.resources
    }

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timer")
                .sectionTitleStyle()

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timerManager.state.label)
                            .font(.caption)
                            .secondaryTextStyle()
                        Text(formattedTime(timerManager.remainingSeconds))
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .primaryTextStyle()
                    }

                    Spacer()

                    Picker("Mode", selection: $timerManager.mode) {
                        ForEach(FocusMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(AppColors.accent)
                }

                HStack(spacing: 12) {
                    Button("Start") {
                        timerManager.start(
                            for: block.id,
                            mode: timerManager.mode,
                            preferences: appStore.timerPreferences
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.accent)

                    Button("Pause") {
                        timerManager.pause()
                    }
                    .buttonStyle(.bordered)

                    Button("Stop") {
                        if let session = timerManager.stopAndBuildSession(dayPlanId: dayPlan.id) {
                            appStore.addTimerSession(session)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(AppColors.surfaceElevated)
            .cornerRadius(12)
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d", minutes, remaining)
    }

    private var blockTypeLabel: String {
        workingBlock.type.rawValue.capitalized
    }
}

extension BlockType {
    var systemImageName: String {
        switch self {
        case .dsa: return "circle.grid.cross"
        case .ml: return "brain"
        case .project: return "hammer"
        case .mlops: return "server.rack"
        case .communication: return "bubble.left.and.bubble.right"
        case .reflection: return "sparkles"
        }
    }
}

extension FocusMode {
    var displayName: String {
        switch self {
        case .focusedDrill: return "Focused Drill"
        case .conceptBlock: return "Concept"
        case .deepBuild: return "Deep Build"
        case .simulationBurst: return "Simulation"
        case .stopwatch: return "Stopwatch"
        }
    }
}

private extension TimerManager.TimerState {
    var label: String {
        switch self {
        case .idle: return "Idle"
        case .focus: return "Focus"
        case .breakTime: return "Break"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStore())
        .environmentObject(TimerManager())
}
