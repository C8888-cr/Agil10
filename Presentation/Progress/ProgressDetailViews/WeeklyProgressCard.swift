//
//  WeeklyProgressCard.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import SwiftUI
import SwiftData

struct WeeklyProgressCard: View {
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    private let weekDays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wochenübersicht")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Dein Trainingsfortschritt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Wochenfortschritt Badge
                Text("\(Int(progressVM.weeklyProgress * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accent.opacity(0.15))
                    .cornerRadius(10)
            }
            
            // Balken für jeden Wochentag
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    DayProgressBar(
                        dayName: weekDays[index],
                        progress: dailyProgress(for: index),
                        isToday: isToday(index)
                    )
                }
            }
            .frame(height: 120)
            
            // Legende
            HStack(spacing: 16) {
                LegendItem(color: .accent, text: "Erledigt")
                LegendItem(color: .gray.opacity(0.3), text: "Ausstehend")
            }
            .font(.caption)
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
        
        guard !schedules.isEmpty else { return 0.0 }
        
        // Hole Tagesziel
        guard let goal = settingsVM.preferences.getGoalFor(dayOfWeek: dayIndex) else {
            return 0.0
        }
        
        // ✅ Sekunden statt Minuten
           let completedSeconds = completedSchedules.reduce(0) { $0 + $1.totalDurationSeconds }
           let targetSeconds = goal.targetMinutes * 60
           
           return targetSeconds > 0 ? min(1.0, Double(completedSeconds) / Double(targetSeconds)) : 0.0
       }
    
    private func isToday(_ index: Int) -> Bool {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday
        let rawWeekday = calendar.component(.weekday, from: Date())
        let todayIndex = (rawWeekday - firstWeekday + 7) % 7
        return index == todayIndex
    }
}
