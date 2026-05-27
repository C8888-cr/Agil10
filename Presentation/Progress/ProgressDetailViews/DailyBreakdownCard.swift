//
//  DailyBreakdownCard.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import SwiftUI
import SwiftData

// MARK: - Daily Breakdown Card
struct DailyBreakdownCard: View {
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    private let weekDays = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tagesübersicht")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(0..<7, id: \.self) { index in
                DailyBreakdownRow(
                    dayName: weekDays[index],
                    shortName: String(weekDays[index].prefix(2)),
                    progress: dailyProgress(for: index),
                    watchedMinutes: watchedMinutes(for: index),
                    targetMinutes: targetMinutes(for: index),
                    isToday: isToday(index)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private func dailyProgress(for dayIndex: Int) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return 0.0
        }
        
        guard let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) else {
            return 0.0
        }
        
        let schedules = progressVM.schedulesFor(date: targetDate)
        let completedSchedules = schedules.filter { $0.isCompleted }
        
        guard let goal = settingsVM.preferences.getGoalFor(dayOfWeek: dayIndex) else {
            return 0.0
        }
        
        let modus = settingsVM.preferences.workoutModus
                
                let completedMinutes = completedSchedules.reduce(0) { sum, schedule in
                    sum + schedule.effectiveDurationMinutes(modus: modus)
                }
        let targetMinutes = goal.targetMinutes
        
        return targetMinutes > 0 ? min(1.0, Double(completedMinutes) / Double(targetMinutes)) : 0.0
    }
    
    
    private func watchedMinutes(for dayIndex: Int) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return 0
        }
        
        guard let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) else {
            return 0
        }
        
        let schedules = progressVM.schedulesFor(date: targetDate)
        let completedSchedules = schedules.filter { $0.isCompleted }
        
        let modus = settingsVM.preferences.workoutModus
                
                let completedSeconds = completedSchedules.reduce(0) { sum, schedule in
                    sum + schedule.effectiveDurationSeconds(modus: modus)
                }
        return (completedSeconds + 59) / 60
    }
    
    private func targetMinutes(for dayIndex: Int) -> Int {
        return settingsVM.preferences.getGoalFor(dayOfWeek: dayIndex)?.targetMinutes ?? 0
    }
    
    private func isToday(_ index: Int) -> Bool {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday
        let rawWeekday = calendar.component(.weekday, from: Date())
        let todayIndex = (rawWeekday - firstWeekday + 7) % 7
        return index == todayIndex
    }
}
