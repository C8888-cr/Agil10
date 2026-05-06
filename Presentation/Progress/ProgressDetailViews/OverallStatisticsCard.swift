//
//  OverallStatisticsCard.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import SwiftUI
import SwiftData

// MARK: - Overall Statistics Card
struct OverallStatisticsCard: View {
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gesamtstatistiken")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticItem(
                    icon: "play.circle.fill",
                    value: "\(progressVM.lifetimeCompletedWorkouts)",
                    label: "Videos geschaut",
                    color: Color("AccentColor")
                )
                
                StatisticItem(
                    icon: "clock.fill",
                    value: "\(progressVM.lifetimeCompletedMinutes)",
                    label: "Minuten trainiert",
                    color: Color.blue
                )
                
                StatisticItem(
                    icon: "flame.fill",
                    value: "\(progressVM.lifetimeStreak)",
                    label: "Tage Streak",
                    color: Color.orange
                )
                
                StatisticItem(
                    icon: "star.fill",
                    value: String(format: "%.1f", averageRating()),
                    label: "Ø Bewertung",
                    color: Color.yellow
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
    
    private func averageRating() -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return 0.0
        }
        
        var allRatings: [Int] = []
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            
            let schedules = progressVM.schedulesFor(date: date)
            // ✅ BESTE VARIANTE:
            let completedSchedules = schedules.filter {
                       $0.isCompleted && ($0.rating ?? 0) > 0
                   }
                   allRatings.append(contentsOf: completedSchedules.compactMap { $0.rating })
        }
        
        guard !allRatings.isEmpty else { return 0.0 }
        
        let sum = allRatings.reduce(0, +)
        return Double(sum) / Double(allRatings.count)
    }
}
