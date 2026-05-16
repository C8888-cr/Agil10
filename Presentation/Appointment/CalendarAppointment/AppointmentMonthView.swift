//
//  AppointmentMonthView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 10.05.26.
//


//
//  AppointmentMonthView.swift
//  Agil10.0
//
//  Monatsansicht mit Tagen und Punkt-Markern an Tagen mit Terminen.
//  Tap auf Tag → AppointmentDayView.
//

import SwiftUI

struct AppointmentMonthView: View {

    @ObservedObject var viewModel: AppointmentPlannerViewModel
    @State private var displayedMonth: Date
    @State private var selectedDay: Date? = nil
    @EnvironmentObject var themeManager: ThemeManager

    init(viewModel: AppointmentPlannerViewModel, initialMonth: Date = Date()) {
        self.viewModel = viewModel
        let firstOfMonth = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: initialMonth)
        ) ?? initialMonth
        _displayedMonth = State(initialValue: firstOfMonth)
    }

    private let weekdayLabels = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    private var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "MMMM yyyy"
        return f
    }

    var body: some View {
        VStack(spacing: 0) {
            // Monat-Navigation
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                Spacer()
                Text(monthFormatter.string(from: displayedMonth))
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
            }
            .padding()
            .foregroundStyle(themeManager.currentTheme.accentColor)

            // Wochentags-Header
            HStack(spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Tage-Grid
            monthGrid
                .padding(.horizontal)

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadEventsForDisplayedMonth()
        }
        .onChange(of: displayedMonth) { _, _ in
            Task { await loadEventsForDisplayedMonth() }
        }
        .navigationDestination(item: $selectedDay) { day in
            AppointmentDayView(viewModel: viewModel, initialDay: day)
        }
    }

    // MARK: - Grid

    private var monthGrid: some View {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth) else {
            return AnyView(EmptyView())
        }

        let firstOfMonth = cal.date(
            from: cal.dateComponents([.year, .month], from: displayedMonth)
        ) ?? displayedMonth

        let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth)
        let leadingEmpties = (weekdayOfFirst + 5) % 7   // Montag-Start

        let daysInMonth: [Date?] = Array(repeating: nil as Date?, count: leadingEmpties)
            + range.compactMap { day -> Date? in
                cal.date(byAdding: .day, value: day - 1, to: firstOfMonth)
            }

        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return AnyView(
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, day in
                    if let day = day {
                        dayCell(day)
                            .onTapGesture {
                                selectedDay = day
                            }
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        )
    }

    private func dayCell(_ day: Date) -> some View {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(day)
        let dayNumber = cal.component(.day, from: day)
        let hasEvents = !viewModel.events(on: day).isEmpty

        return VStack(spacing: 4) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(themeManager.currentTheme.accentColor)
                        .frame(width: 32, height: 32)
                }
                Text("\(dayNumber)")
                    .font(.body)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isToday ? .white : .primary)
            }
            .frame(height: 32)

            // Marker-Linie
            Rectangle()
                .fill(hasEvents ? Color("Blau") : Color.clear)
                .frame(width: 16, height: 2)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .contentShape(Rectangle())
    }

    // MARK: - Helpers

    private func changeMonth(by offset: Int) {
        guard let newDate = Calendar.current.date(byAdding: .month, value: offset, to: displayedMonth) else { return }
        displayedMonth = newDate
    }

    private func loadEventsForDisplayedMonth() async {
        let cal = Calendar.current
        guard let monthInterval = cal.dateInterval(of: .month, for: displayedMonth) else { return }
        // Etwas Puffer rechts und links für Events, die in den Monat reichen
        let start = cal.date(byAdding: .day, value: -7, to: monthInterval.start) ?? monthInterval.start
        let end = cal.date(byAdding: .day, value: 7, to: monthInterval.end) ?? monthInterval.end
        await viewModel.loadEvents(from: start, to: end)
    }
}
