//
//  MonthGridView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import SwiftUI
import SwiftData

// MARK: - MonthGridView
struct MonthGridView: View {
    let month: Date
    let selectedDate: Date
    let hasSchedules: (Date) -> Bool
    let hasAppointments: (Date) -> Bool
    let onSelectDate: (Date) -> Void
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    private var monthDays: [Date?] {
        guard let firstDay = month.firstDayOfMonth() as Date?,
              let range = calendar.range(of: .day, in: .month, for: month) else {
            return []
        }
        
        // Wochentag des ersten Tages (0=Mo, 6=So)
        let firstWeekday = (calendar.component(.weekday, from: firstDay) + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Monatsname
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 4)
            
            // Tage Grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasSchedules: hasSchedules(date),
                            hasAppointments: hasAppointments(date),
                            onTap: { onSelectDate(date) }
                        )
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            Divider()
                .padding(.top, 8)
        }
    }
}
