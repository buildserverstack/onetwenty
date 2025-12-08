import SwiftUI
import UniformTypeIdentifiers

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
        NavigationSplitView {
            SidebarView(selectedItem: $selectedItem)
        } detail: {
            detailView(for: selectedItem)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    appStore.showQuickCapture = true
                } label: {
                    Label("Quick Capture", systemImage: "plus.bubble")
                }
            }
        }
        .sheet(
            isPresented: Binding(get: { appStore.showQuickCapture }, set: { appStore.showQuickCapture = $0 })
        ) {
            QuickCaptureView()
                .environmentObject(appStore)
        }
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
        }
        .navigationTitle("AICoachMac")
    }
}

struct TodayView: View {
    @EnvironmentObject var appStore: AppStore
    @EnvironmentObject var timerManager: TimerManager
    @State private var selectedBlock: Block?

    var body: some View {
        Group {
            if let currentDay = appStore.currentDay {
                HStack(alignment: .top) {
                    List(currentDay.blocks, id: \.id) { block in
                        HStack {
                            Image(systemName: block.type.systemImageName)
                            VStack(alignment: .leading) {
                                Text(block.title)
                                    .font(.headline)
                                Text(block.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: block.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(block.isCompleted ? .green : .secondary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedBlock = block
                        }
                    }
                    .frame(minWidth: 260)
                    .onAppear {
                        if selectedBlock == nil {
                            selectedBlock = currentDay.blocks.first
                        }
                    }
                    .onChange(of: appStore.currentDay?.id) { _ in
                        selectedBlock = appStore.currentDay?.blocks.first
                    }

                    Divider()

                    if let block = selectedBlock {
                        BlockDetailView(block: block, dayPlan: currentDay)
                            .environmentObject(appStore)
                            .environmentObject(timerManager)
                    } else {
                        Text("Select a block to view details")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            } else {
                Text("Select or create a day plan to get started.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding()
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

struct SettingsView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var showImporter = false
    @State private var importError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title)

            Text("Import your 120-day plan from a CSV file to replace the current schedule.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button {
                    showImporter = true
                } label: {
                    Label("Import 120-Day CSV", systemImage: "square.and.arrow.down")
                }

                if let error = importError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }

            if !appStore.dayPlans.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Plan")
                        .font(.headline)
                    Text("Days loaded: \(appStore.dayPlans.count)")
                    if let current = appStore.currentDay {
                        Text("Current Day: #\(current.dayNumber) – \(current.title)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    try appStore.loadFromCSV(url: url)
                    importError = nil
                } catch {
                    importError = error.localizedDescription
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
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
                Text(workingBlock.description)
                    .foregroundColor(.secondary)
            }

            tasksSection
            resourcesSection
            timerSection

            Spacer()
        }
        .padding()
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tasks")
                .font(.headline)
            ForEach($workingBlock.tasks, id: \.id) { $task in
                Toggle(task.title, isOn: $task.isDone)
            }
        }
    }

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resources")
                .font(.headline)
            Text("Add links to resources or references here.")
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
    }

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timer")
                .font(.headline)

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
                        .foregroundColor(.secondary)
                    Text(formattedTime(timerManager.remainingSeconds))
                        .font(.title2)
                        .monospacedDigit()
                }

                Spacer()

                Button("Start") {
                    timerManager.start(for: block.id, mode: timerManager.mode)
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
