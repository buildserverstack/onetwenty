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
    @State private var selectedItem: SidebarItem? = .today

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $selectedItem)
        } detail: {
            detailView(for: selectedItem)
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
    var body: some View {
        Text("Today")
            .font(.title)
            .padding()
    }
}

struct RoadmapView: View {
    var body: some View {
        Text("Roadmap")
            .font(.title)
            .padding()
    }
}

struct NotebooksView: View {
    var body: some View {
        Text("Notebooks")
            .font(.title)
            .padding()
    }
}

struct ProgressView: View {
    var body: some View {
        Text("Progress & Revision")
            .font(.title)
            .padding()
    }
}

struct InterviewGymView: View {
    var body: some View {
        Text("Interview Gym")
            .font(.title)
            .padding()
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .font(.title)
            .padding()
    }
}

#Preview {
    ContentView()
}
