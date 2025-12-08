import SwiftUI

struct DaySelectorView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var selectedDayNumber: Int?
    @State private var selectedDate: Date?

    private var availableDayNumbers: [Int] {
        appStore.dayPlans.map { $0.dayNumber }.sorted()
    }

    private var availableDates: [Date] {
        appStore.dayPlans.compactMap { $0.date.map { Calendar.current.startOfDay(for: $0) } }.sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if appStore.dayPlans.isEmpty {
                Text("No day plans loaded yet.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                HStack(alignment: .center, spacing: 16) {
                    Picker("Day", selection: Binding(get: {
                        selectedDayNumber ?? appStore.currentDay?.dayNumber
                    }, set: { newValue in
                        selectedDayNumber = newValue
                        selectedDate = appStore.dayPlans.first { $0.dayNumber == newValue }?.date
                        if let newValue {
                            appStore.goToDay(newValue)
                        }
                    })) {
                        ForEach(availableDayNumbers, id: \.self) { day in
                            Text("Day \(day)").tag(Optional(day))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 200)

                    if !availableDates.isEmpty {
                        Picker("Date", selection: Binding(get: {
                            selectedDate ?? appStore.currentDay?.date.map { Calendar.current.startOfDay(for: $0) }
                        }, set: { newValue in
                            selectedDate = newValue
                            if let date = newValue {
                                appStore.goToDate(date)
                                selectedDayNumber = appStore.currentDay?.dayNumber
                            }
                        })) {
                            ForEach(availableDates, id: \.self) { date in
                                Text(date, style: .date).tag(Optional(date))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 200)
                    }
                }
            }

            if let current = appStore.currentDay {
                Text("Loaded: Day \(current.dayNumber) – \(current.title)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear(perform: syncSelection)
        .onChange(of: appStore.currentDay?.id) { _ in
            syncSelection()
        }
    }

    private func syncSelection() {
        selectedDayNumber = appStore.currentDay?.dayNumber
        if let date = appStore.currentDay?.date {
            selectedDate = Calendar.current.startOfDay(for: date)
        }
    }
}

#Preview {
    DaySelectorView()
        .environmentObject(AppStore())
}
