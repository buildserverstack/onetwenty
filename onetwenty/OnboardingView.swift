import SwiftUI

private enum BudgetOption: String, CaseIterable, Identifiable {
    case three
    case four
    case five
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .three: return "3h"
        case .four: return "4h"
        case .five: return "5h"
        case .custom: return "Custom"
        }
    }

    var minutes: Int {
        switch self {
        case .three: return 180
        case .four: return 240
        case .five: return 300
        case .custom: return 0
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject var appStore: AppStore

    @State private var selectedDayNumber: Int?
    @State private var budgetSelection: BudgetOption = .four
    @State private var customMinutes: Int = 240
    @State private var dsaWeight: Double = 25
    @State private var mlWeight: Double = 25
    @State private var projectWeight: Double = 25
    @State private var interviewWeight: Double = 25

    private var availableDayNumbers: [Int] {
        appStore.dayPlans.map(\.dayNumber).sorted()
    }

    private var normalizedWeights: FocusWeights {
        FocusWeights(
            dsa: dsaWeight,
            ml: mlWeight,
            projects: projectWeight,
            interview: interviewWeight
        ).normalized()
    }

    private var selectedBudgetMinutes: Int {
        budgetSelection == .custom ? max(customMinutes, 0) : budgetSelection.minutes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Welcome to AICoachMac")
                .font(.largeTitle)
                .bold()

            Text("Set your starting day, daily time budget, and focus emphasis to tailor the 120-day plan.")
                .foregroundColor(.secondary)

            dayPickerSection
            budgetSection
            focusWeightsSection

            Spacer()

            Button(action: continueTapped) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedDayNumber == nil || selectedBudgetMinutes <= 0)
        }
        .padding(32)
        .onAppear {
            if selectedDayNumber == nil {
                selectedDayNumber = appStore.startDayNumber ?? availableDayNumbers.first
            }

            dsaWeight = appStore.focusWeights.dsa * 100
            mlWeight = appStore.focusWeights.ml * 100
            projectWeight = appStore.focusWeights.projects * 100
            interviewWeight = appStore.focusWeights.interview * 100
            customMinutes = appStore.dailyTimeBudgetMinutes
        }
    }

    private var dayPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Starting Day")
                .font(.headline)

            if availableDayNumbers.isEmpty {
                Text("No day plans loaded. Import a plan to select a starting day.")
                    .foregroundColor(.secondary)
            } else {
                Picker("Day", selection: Binding(get: {
                    selectedDayNumber ?? availableDayNumbers.first
                }, set: { newValue in
                    selectedDayNumber = newValue
                })) {
                    ForEach(availableDayNumbers, id: \.self) { day in
                        Text("Day \(day)").tag(day as Int?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 240)
            }
        }
    }

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Time Budget")
                .font(.headline)

            Picker("Budget", selection: $budgetSelection) {
                ForEach(BudgetOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 360)

            if budgetSelection == .custom {
                HStack {
                    Text("Minutes:")
                    TextField("Minutes", value: $customMinutes, formatter: NumberFormatter())
                        .frame(width: 80)
                }
            }

            Text("Selected: \(selectedBudgetMinutes) minutes per day")
                .foregroundColor(.secondary)
        }
    }

    private var focusWeightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Weights")
                .font(.headline)

            weightSlider(title: "DSA", value: $dsaWeight)
            weightSlider(title: "ML", value: $mlWeight)
            weightSlider(title: "Projects", value: $projectWeight)
            weightSlider(title: "Interview", value: $interviewWeight)

            let normalized = normalizedWeights
            Text(String(format: "Normalized: DSA %.0f%% • ML %.0f%% • Projects %.0f%% • Interview %.0f%%",
                        normalized.dsa * 100,
                        normalized.ml * 100,
                        normalized.projects * 100,
                        normalized.interview * 100))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private func weightSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .foregroundColor(.secondary)
            }
            Slider(value: value, in: 0...100)
        }
    }

    private func continueTapped() {
        guard let startDay = selectedDayNumber else { return }
        let weights = FocusWeights(
            dsa: dsaWeight,
            ml: mlWeight,
            projects: projectWeight,
            interview: interviewWeight
        )
        appStore.applyOnboarding(startDay: startDay, dailyBudgetMinutes: selectedBudgetMinutes, focusWeights: weights)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppStore())
}
