//
//  ExerciseTypeStatsCard.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import SwiftUI
import SwiftData

struct ExerciseTypeStatsCard: View {
    @EnvironmentObject var progressVM: ProgressViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Übungsarten")
                .font(.title2)
                .fontWeight(.bold)
            
            let stats = getExerciseTypeStats()
            
            if stats.isEmpty {
                Text("Noch keine Trainingsdaten")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Array(stats.sorted { $0.value.minutes > $1.value.minutes }), id: \.key) { category, data in
                        ExerciseTypeStatItem(
                            category: category,
                            minutes: data.minutes,
                            isCompleted: data.isCompleted
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private func getExerciseTypeStats() -> [ExerciseCategory: (minutes: Int, isCompleted: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return [:]
        }
        
        var stats: [ExerciseCategory: (minutes: Int, isCompleted: Bool)] = [:]
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            
            let schedules = progressVM.schedulesFor(date: date)
            
            for schedule in schedules {
                guard let video = schedule.video else { continue }
                
                let category = video.category
                let minutes = schedule.totalDurationMinutes
                let isCompleted = schedule.isCompleted
                
                if var existing = stats[category] {
                    existing.minutes += minutes
                    existing.isCompleted = existing.isCompleted && isCompleted
                    stats[category] = existing
                } else {
                    stats[category] = (minutes: minutes, isCompleted: isCompleted)
                }
            }
        }
        
        return stats
    }
}
