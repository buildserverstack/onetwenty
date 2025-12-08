import SwiftUI
import AppKit

struct ExportSettingsView: View {
    @EnvironmentObject var appStore: AppStore

    @State private var statusMessage: String?
    @State private var isError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Export")
                .font(.headline)

            Text("Choose where to save your daily progress CSV. You can change this anytime.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let url = appStore.exportCSVURL {
                Label {
                    Text(url.path)
                        .lineLimit(2)
                        .truncationMode(.middle)
                } icon: {
                    Image(systemName: "doc.text")
                }
            } else {
                Text("No export file selected yet.")
                    .foregroundColor(.secondary)
            }

            Button("Choose Export CSV…") {
                chooseCSV()
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundColor(isError ? .red : .green)
            }
        }
        .padding()
    }

    private func chooseCSV() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["csv"]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.title = "Select Progress Export CSV"

        if panel.runModal() == .OK, let url = panel.url {
            appStore.exportCSVURL = url
            statusMessage = "Export file set to \(url.lastPathComponent)"
            isError = false
        }
    }
}

#Preview {
    ExportSettingsView()
        .environmentObject(AppStore())
}
