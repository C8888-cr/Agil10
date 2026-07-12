//
//  WeekStripView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 23.05.26.
//


//
//  WeekStripView.swift
//  Agil10.0
//
//  Anklickbare Wochenleiste mit zwei Indikator-Balken (Übungen + Termine).
//  Generisch & wiederverwendbar – kennt kein ViewModel.
//

import SwiftUI
import AgilCore


struct WeekStripView: View {

    // MARK: - Input
    let selectedDate: Date
    let weekDays: [Date]
    let hasAppointment: (Date) -> Bool
    let hasExercise: (Date) -> Bool
    let onSelect: (Date) -> Void
    let onSwipeWeek: (Int) -> Void

    @EnvironmentObject var themeManager: ThemeManager

    private let calendar = Calendar.current

    // MARK: - Body
    var body: some View {
        HStack(spacing: 4) {
            ForEach(weekDays, id: \.self) { day in
                dayCell(day)
                    .onTapGesture { onSelect(calendar.startOfDay(for: day)) }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    guard abs(horizontal) > abs(vertical) * 1.5,
                          abs(horizontal) > 50 else { return }
                    onSwipeWeek(horizontal < 0 ? 1 : -1)
                }
        )
    }

    // MARK: - Tageszelle (DayCell-Stil)
    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)
        let weekdayShort = day.formatted(
            .dateTime.weekday(.abbreviated).locale(Locale(identifier: "de_DE"))
        )
        let dayNumber = calendar.component(.day, from: day)

        return VStack(spacing: 4) {
            // Wochentag-Kürzel
            Text(weekdayShort)
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Tagnummer mit Auswahl-Kreis
            Text("\(dayNumber)")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(
                    isSelected ? .white :
                    isToday ? themeManager.currentTheme.accentColor :
                    .primary
                )
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? themeManager.currentTheme.accentColor : Color.clear)
                )

            // Indikator-Balken
            VStack(spacing: 2) {
                if hasExercise(day) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("AccentColor"))
                        .frame(height: 4)
                }
                if hasAppointment(day) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("Blau"))
                        .frame(height: 4)
                }
            }
            .frame(height: 10)
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}
