import SwiftUI

struct ReflectionCardView: View {
    @EnvironmentObject var appStore: AppStore

    let dayPlan: DayPlan

    @State private var mlInsight1: String = ""
    @State private var mlInsight2: String = ""
    @State private var dsaPattern: String = ""
    @State private var communicationLearning: String = ""
    @State private var mistake: String = ""
    @State private var questionForTomorrow: String = ""
    @State private var weaknessTagsText: String = ""
    @State private var rating: Int = 3
    @State private var statusMessage: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Reflection & Rating")
                    .sectionTitleStyle()

                insightSection
                dsaSection
                communicationSection
                mistakeSection
                questionSection
                tagsSection
                ratingSection

                saveButton

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding()
        }
        .cardBackground()
    }

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ML / LLM / DL Insights")
                .sectionTitleStyle()
            VoiceDictationField(text: $mlInsight1, placeholder: "ML / LLM insight #1")
            VoiceDictationField(text: $mlInsight2, placeholder: "ML / LLM insight #2")
        }
    }

    private var dsaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DSA Pattern")
                .sectionTitleStyle()
            TextField("Pattern name", text: $dsaPattern)
                .padding(10)
                .background(AppColors.surfaceElevated)
                .cornerRadius(8)
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private var communicationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Communication / Interview Learning")
                .sectionTitleStyle()
            VoiceDictationField(text: $communicationLearning, placeholder: "What improved?")
        }
    }

    private var mistakeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mistake")
                .sectionTitleStyle()
            VoiceDictationField(text: $mistake, placeholder: "What went wrong?")
        }
    }

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Question for Tomorrow")
                .sectionTitleStyle()
            TextField("What to clarify next?", text: $questionForTomorrow)
                .padding(10)
                .background(AppColors.surfaceElevated)
                .cornerRadius(8)
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weakness Tags (comma-separated)")
                .sectionTitleStyle()
            TextField("e.g., arrays, gradient descent", text: $weaknessTagsText)
                .padding(10)
                .background(AppColors.surfaceElevated)
                .cornerRadius(8)
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rating")
                .sectionTitleStyle()
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        rating = value
                    } label: {
                        Text("\(value)")
                            .frame(width: 36, height: 32)
                            .font(.headline)
                            .foregroundColor(rating == value ? AppColors.background : AppColors.textPrimary)
                            .background(rating == value ? AppColors.accent : AppColors.surfaceElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(rating == value ? AppColors.accent : AppColors.border, lineWidth: 1)
                            )
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var saveButton: some View {
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

            if let exportURL = appStore.exportCSVURL, FileManager.default.fileExists(atPath: exportURL.path) {
                statusMessage = "Saved and exported to \(exportURL.lastPathComponent)."
            } else {
                statusMessage = "Reflection saved."
            }

            resetForm()
        } label: {
            Text("Save Reflection & Mark Day Complete")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColors.accent)
                .foregroundColor(AppColors.background)
                .cornerRadius(10)
                .font(.headline)
        }
        .buttonStyle(.plain)
    }

    private func resetForm() {
        mlInsight1 = ""
        mlInsight2 = ""
        dsaPattern = ""
        communicationLearning = ""
        mistake = ""
        questionForTomorrow = ""
        weaknessTagsText = ""
        rating = 3
    }
}

#Preview {
    ReflectionCardView(dayPlan: DayPlan(
        id: UUID(),
        dayNumber: 1,
        phase: "Foundation",
        title: "Sample Day",
        blocks: []
    ))
    .environmentObject(AppStore())
    .padding()
    .background(AppColors.background)
}
