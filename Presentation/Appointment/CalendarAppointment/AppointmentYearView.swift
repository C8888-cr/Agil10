//
//  AppointmentYearView.swift
//  Agil10.0
//
//  Jahresansicht – Exakt wie Apple Calendar.
//  Mit Sticky Header, Navigation zu MonthView.
//

import SwiftUI

struct AppointmentYearView: View {

    @ObservedObject var viewModel: AppointmentPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var onMonthSelected: (Date) -> Void
    var onCloseAll: () -> Void

    @State private var scrollPosition: String? = nil
    
    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Montag
        return cal
    }()
    
    private var currentYear: Int {
        calendar.component(.year, from: Date())
    }
    
    // Jahre: -2 bis +2 um aktuelles Jahr
    private var yearsToDisplay: [Int] {
        Array((currentYear - 2)...(currentYear + 2))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        ForEach(yearsToDisplay, id: \.self) { year in
                            yearSection(year: year)
                                .id(String(year))
                        }
                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .scrollPosition(id: $scrollPosition)

                // Sticky Header
                stickyHeader
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                // < Zurück Button
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // Zurück zu MonthView mit aktuellem Jahr/Monat
                        var components = DateComponents()
                        components.year = currentYear
                        components.month = calendar.component(.month, from: Date())
                        components.day = 1
                        if let date = calendar.date(from: components) {
                            onMonthSelected(date)
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundStyle(themeManager.currentTheme.accentColor)
                        .frame(width: 32, height: 32)
                        .glassEffect(in: Circle())
                    }
                }

                // X Button
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onCloseAll()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(themeManager.currentTheme.accentColor)
                            .frame(width: 32, height: 32)
                            .glassEffect(in: Circle())
                    }
                }
            }
            .onAppear {
                // Scroll zu aktuellem Jahr
                DispatchQueue.main.async {
                    scrollPosition = String(currentYear)
                }
            }
        }
    }

    // MARK: - Sticky Header (Heute Button)

    private var stickyHeader: some View {
        VStack {
            Spacer()
            HStack {
                Button {
                    withAnimation {
                        scrollPosition = String(currentYear)
                    }
                } label: {
                    Text("Heute")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.accentColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect(in: Capsule())
                }
                .padding(.leading, 16)
                .padding(.bottom, 20)

                Spacer()
            }
        }
    }

    // MARK: - Jahr-Sektion

    private func yearSection(year: Int) -> some View {
        let isCurrentYear = year == currentYear

        return VStack(alignment: .leading, spacing: 12) {
            // Jahr
            Text(String(year))
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(isCurrentYear ? themeManager.currentTheme.accentColor : .primary)

            Divider()

            // 4 Reihen à 3 Monate
            VStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(alignment: .top, spacing: 8) {
                        ForEach(0..<3, id: \.self) { col in
                            let month = row * 3 + col + 1
                            if month <= 12 {
                                miniMonthView(year: year, month: month)
                                    .frame(maxWidth: .infinity)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        handleMonthTap(year: year, month: month)
                                    }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mini-Monats-Grid

    private func miniMonthView(year: Int, month: Int) -> some View {
        let monthName = monthFormatter.monthSymbols[month - 1]
        let isCurrentMonth = isCurrent(year: year, month: month)

        return VStack(alignment: .leading, spacing: 4) {
            Text(monthName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isCurrentMonth ? themeManager.currentTheme.accentColor : .primary)

            monthGrid(year: year, month: month)
        }
    }

    // MARK: - Monats-Grid (7 Spalten, mit Offset)

    private func monthGrid(year: Int, month: Int) -> some View {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return AnyView(EmptyView())
        }

        // Wochentag des 1. (Montag = 0, Sonntag = 6)
        let weekdayRaw = calendar.component(.weekday, from: firstOfMonth)
        let offset = (weekdayRaw + 5) % 7

        // Leere Zellen + Tage
        var cells: [Int?] = Array(repeating: nil, count: offset)
        cells += range.map { Optional($0) }

        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

        return AnyView(
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                    if let day = day {
                        dayCell(day: day, year: year, month: month)
                    } else {
                        Text("")
                            .font(.system(size: 10))
                            .frame(height: 14)
                    }
                }
            }
        )
    }

    // MARK: - Tag-Zelle

    private func dayCell(day: Int, year: Int, month: Int) -> some View {
        let isToday = isToday(day: day, year: year, month: month)

        return ZStack {
            if isToday {
                Circle()
                    .fill(themeManager.currentTheme.accentColor)
                    .frame(width: 18, height: 18)
            }

            Text("\(day)")
                .font(.system(size: 10, weight: isToday ? .semibold : .regular))
                .foregroundStyle(isToday ? .white : .primary)
        }
        .frame(height: 14)
    }

    // MARK: - Handler

    private func handleMonthTap(year: Int, month: Int) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        if let date = calendar.date(from: components) {
            onMonthSelected(date)
        }
    }

    // MARK: - Helper

    private func isToday(day: Int, year: Int, month: Int) -> Bool {
        let now = Date()
        return calendar.component(.year, from: now) == year
            && calendar.component(.month, from: now) == month
            && calendar.component(.day, from: now) == day
    }

    private func isCurrent(year: Int, month: Int) -> Bool {
        let now = Date()
        return calendar.component(.year, from: now) == year
            && calendar.component(.month, from: now) == month
    }

    private var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        return f
    }
}
