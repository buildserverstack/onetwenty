import SwiftUI
import AppKit

struct ImportPlanView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var statusMessage: String?
    @State private var isError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import 120-day Plan")
                .font(.headline)

            Text("Choose your CSV file to load the full 120-day schedule into the app.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                presentOpenPanel()
            } label: {
                Label("Choose 120-day CSV…", systemImage: "square.and.arrow.down")
            }

            if let statusMessage {
                Text(statusMessage)
                    .foregroundColor(isError ? .red : .secondary)
                    .font(.footnote)
            }
        }
    }

    private func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["csv"]

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try appStore.loadFromCSV(url: url)
                statusMessage = "Loaded \(appStore.dayPlans.count) days"
                isError = false
            } catch {
                statusMessage = error.localizedDescription
                isError = true
            }
        }
    }
}

#Preview {
    ImportPlanView()
        .environmentObject(AppStore())
}
