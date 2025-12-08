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
    @State private var mlInsight1: String = ""
    @State private var mlInsight2: String = ""
    @State private var dsaPattern: String = ""
    @State private var communicationLearning: String = ""
    @State private var mistake: String = ""
    @State private var questionForTomorrow: String = ""
    @State private var rating: Int = 3
    @State private var weaknessTagsText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DaySelectorView()
                    .environmentObject(appStore)
                    .cardBackground()

                if let currentDay = appStore.currentDay {
                    HStack(alignment: .top, spacing: 16) {
                        List(currentDay.blocks, id: \.id) { block in
                            HStack {
                                Image(systemName: block.type.systemImageName)
                                    .foregroundColor(AppColors.accent)
                                VStack(alignment: .leading) {
                                    Text(block.title)
                                        .font(.headline)
                                        .primaryTextStyle()
                                    Text(block.description)
                                        .font(.subheadline)
                                        .secondaryTextStyle()
                                }
                                Spacer()
                                Image(systemName: block.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(block.isCompleted ? AppColors.accent : AppColors.textSecondary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedBlock = block
                            }
                        }
                        .frame(minWidth: 260)
                        .listStyle(.inset)
                        .scrollContentBackground(.hidden)
                        .background(AppColors.surface)
                        .listRowBackground(AppColors.surface)
                        .cardBackground()
                        .onAppear {
                            if selectedBlock == nil {
                                selectedBlock = currentDay.blocks.first
                            }
                        }
                        .onChange(of: appStore.currentDay?.id) { _ in
                            selectedBlock = appStore.currentDay?.blocks.first
                        }

                        if let block = selectedBlock {
                            BlockDetailView(block: block, dayPlan: currentDay)
                                .environmentObject(appStore)
                                .environmentObject(timerManager)
                                .cardBackground()
                        } else {
                            Text("Select a block to view details")
                                .secondaryTextStyle()
                                .cardBackground()
                        }
                    }

                    reflectionSection(for: currentDay)
                        .cardBackground()
                } else {
                    Text("Select or create a day plan to get started.")
                        .font(.title3)
                        .secondaryTextStyle()
                        .cardBackground()
                }
            }
            .padding()
        }
        .background(AppColors.background)
        .tint(AppColors.accent)
    }

    @ViewBuilder
    private func reflectionSection(for dayPlan: DayPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reflection & Rating")
                .font(AppFonts.title)
                .primaryTextStyle()

            VStack(alignment: .leading, spacing: 8) {
                Text("ML / LLM / DL Insights")
                    .sectionTitleStyle()
                VoiceDictationField(text: $mlInsight1, placeholder: "ML / LLM insight #1")
                VoiceDictationField(text: $mlInsight2, placeholder: "ML / LLM insight #2")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("DSA Pattern")
                    .sectionTitleStyle()
                TextField("Pattern name", text: $dsaPattern)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Communication / Interview Learning")
                    .sectionTitleStyle()
                VoiceDictationField(text: $communicationLearning, placeholder: "What improved?")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Mistake")
                    .sectionTitleStyle()
                VoiceDictationField(text: $mistake, placeholder: "What went wrong?")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Question for Tomorrow")
                    .sectionTitleStyle()
                TextField("What to clarify next?", text: $questionForTomorrow)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Weakness Tags (comma-separated)")
                    .sectionTitleStyle()
                TextField("e.g., arrays, gradient descent", text: $weaknessTagsText)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Rating")
                    .sectionTitleStyle()
                Stepper(value: $rating, in: 1...5) {
                    Text("\(rating)")
                        .primaryTextStyle()
                }
            }

            Button {
                let tags = weaknessTagsText
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                let insights = [mlInsight1, mlInsight2]
                appStore.saveReflection(
                    for: dayPlan,
                    mlInsights: insights,
                    dsaPattern: dsaPattern,
                    communicationLearning: communicationLearning,
                    mistake: mistake,
                    questionForTomorrow: questionForTomorrow,
                    rating: rating,
                    weaknessTags: tags
                )

                mlInsight1 = ""
                mlInsight2 = ""
                dsaPattern = ""
                communicationLearning = ""
                mistake = ""
                questionForTomorrow = ""
                weaknessTagsText = ""
                rating = 3
            } label: {
                Text("Save Reflection & Mark Day Complete")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accent)
        }
        .padding(.top, 12)
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
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(workingBlock.title)
                    .font(.title2)
                    .primaryTextStyle()
                Text(workingBlock.description)
                    .secondaryTextStyle()
            }
            .cardBackground()

            tasksSection.cardBackground()
            resourcesSection.cardBackground()
            timerSection.cardBackground()

            Spacer()
        }
        .padding()
        .background(AppColors.background)
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tasks")
                .sectionTitleStyle()
            ForEach($workingBlock.tasks, id: \.id) { $task in
                Toggle(task.title, isOn: $task.isDone)
                    .primaryTextStyle()
            }
        }
    }

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resources")
                .sectionTitleStyle()

            let resources = availableResources
            if resources.isEmpty {
                Text("No resources for this block.")
                    .secondaryTextStyle()
                    .font(.subheadline)
            } else {
                ForEach(resources) { resource in
                    Link(resource.label, destination: resource.url)
                        .font(.body)
                        .primaryTextStyle()
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Timer")
                .sectionTitleStyle()

            Picker("Mode", selection: $timerManager.mode) {
                ForEach(FocusMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text(timerManager.state.label)
                        .font(.caption)
                        .secondaryTextStyle()
                    Text(formattedTime(timerManager.remainingSeconds))
                        .font(.title2)
                        .monospacedDigit()
                        .primaryTextStyle()
                }

                Spacer()

                Button("Start") {
                    timerManager.start(
                        for: block.id,
                        mode: timerManager.mode,
                        preferences: appStore.timerPreferences
                    )
                }
                Button("Pause") {
                    timerManager.pause()
                }
                Button("Resume") {
                    timerManager.resume()
                }
                Button("Stop") {
                    if let session = timerManager.stopAndBuildSession(dayPlanId: dayPlan.id) {
                        appStore.addTimerSession(session)
                    }
                }
            }
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d", minutes, remaining)
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
