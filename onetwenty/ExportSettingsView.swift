import SwiftUI
import AppKit

struct ExportSettingsView: View {
    @EnvironmentObject var appStore: AppStore

    @State private var statusMessage: String?
    @State private var isError: Bool = false
    @State private var startDay: Int = 1
    @State private var endDay: Int = 10

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

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Export a day range on demand")
                    .font(.subheadline.weight(.semibold))
                Text("Use day numbers to re-export any slice of your plan.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                if appStore.dayPlans.isEmpty {
                    Text("Load a plan before exporting a range.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 12) {
                        Stepper(value: $startDay, in: minDayNumber...maxDayNumber) {
                            Text("Start day: \(startDay)")
                        }

                        Stepper(value: $endDay, in: minDayNumber...maxDayNumber) {
                            Text("End day: \(endDay)")
                        }
                    }

                    Button("Export Now") {
                        exportRange()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundColor(isError ? .red : .green)
            }
        }
        .padding()
        .onAppear(perform: updateRangeDefaults)
    }

    private var minDayNumber: Int {
        appStore.dayPlans.map { $0.dayNumber }.min() ?? 1
    }

    private var maxDayNumber: Int {
        appStore.dayPlans.map { $0.dayNumber }.max() ?? max(endDay, startDay)
    }

    private func chooseCSV() {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["csv"]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "AICoach_Progress.csv"
        panel.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        panel.title = "Select Progress Export CSV"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try appStore.updateExportDestination(url)
                if let resolved = appStore.exportCSVURL {
                    statusMessage = "Export file set to \(resolved.path)"
                } else {
                    statusMessage = "Export file set to \(url.lastPathComponent)"
                }
                isError = false
            } catch {
                statusMessage = error.localizedDescription
                isError = true
            }
        }
    }

    private func exportRange() {
        do {
            let count = try appStore.exportRange(start: startDay, end: endDay)
            statusMessage = "Exported days \(startDay)–\(endDay) (\(count) day(s))."
            isError = false
        } catch {
            statusMessage = error.localizedDescription
            isError = true
        }
    }

    private func updateRangeDefaults() {
        guard !appStore.dayPlans.isEmpty else { return }
        let minDay = minDayNumber
        let maxDay = maxDayNumber
        startDay = minDay
        endDay = maxDay
    }
}

#Preview {
    ExportSettingsView()
        .environmentObject(AppStore())
}
