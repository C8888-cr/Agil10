//
//  AppointmentYearView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 10.05.26.
//


//
//  AppointmentYearView.swift
//  Agil10.0
//
//  Jahresansicht – 12 Mini-Monate. Tap auf einen Monat → AppointmentMonthView.
//

import SwiftUI

struct AppointmentYearView: View {

    @StateObject var viewModel: AppointmentPlannerViewModel
    @State private var displayedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Date? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Jahr-Navigation
                    HStack {
                        Button { displayedYear -= 1 } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                        }
                        Spacer()
                        Text(String(displayedYear))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        Button { displayedYear += 1 } label: {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal)
                    .foregroundStyle(themeManager.currentTheme.accentColor)

                    // 12 Mini-Monate
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(1...12, id: \.self) { month in
                            miniMonth(month: month)
                                .onTapGesture {
                                    var components = DateComponents()
                                    components.year = displayedYear
                                    components.month = month
                                    components.day = 1
                                    if let date = Calendar.current.date(from: components) {
                                        selectedMonth = date
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Termin planen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Heute") {
                        displayedYear = Calendar.current.component(.year, from: Date())
                        selectedMonth = Date()
                    }
                    .foregroundStyle(themeManager.currentTheme.accentColor)
                }
            }
            .navigationDestination(item: $selectedMonth) { month in
                AppointmentMonthView(
                    viewModel: viewModel,
                    initialMonth: month
                )
            }
        }
    }

    // MARK: - Mini-Monat
    private func miniMonth(month: Int) -> some View {
        let monthName = DateFormatter().monthSymbols[month - 1]
        let isCurrentMonth = isCurrent(month: month)

        return VStack(alignment: .leading, spacing: 6) {
            Text(monthName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(isCurrentMonth ? themeManager.currentTheme.accentColor : .primary)

            miniMonthGrid(month: month)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }

    private func miniMonthGrid(month: Int) -> some View {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = displayedYear
        components.month = month
        components.day = 1

        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return AnyView(EmptyView())
        }

        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        // Montag = 1 (statt Sonntag = 1)
        let leadingEmpties = (weekdayOfFirst + 5) % 7

        let cells: [Int?] = Array(repeating: nil, count: leadingEmpties)
            + range.map { Optional($0) }

        let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)

        return AnyView(
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                    if let day = day {
                        Text("\(day)")
                            .font(.system(size: 8))
                            .frame(maxWidth: .infinity, minHeight: 10)
                            .foregroundStyle(.primary)
                    } else {
                        Color.clear.frame(height: 10)
                    }
                }
            }
        )
    }

    private func isCurrent(month: Int) -> Bool {
        let now = Date()
        let cal = Calendar.current
        return cal.component(.year, from: now) == displayedYear
            && cal.component(.month, from: now) == month
    }
}