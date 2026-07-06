//
//  OverallStatisticsCard.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import SwiftUI
import SwiftData
import AgilCore

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
    
    // NEU
    private func averageRating() -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return 0.0 }

        var normalized: [Double] = []

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            for schedule in progressVM.schedulesFor(date: date) where schedule.isCompleted {
                if let rating = schedule.rating, rating > 0 {
                    normalized.append(Double(rating) / 5.0)
                } else if let feedback = schedule.progressFeedback ?? schedule.mobilityFeedback {
                    normalized.append(feedback)
                }
            }
        }

        guard !normalized.isEmpty else { return 0.0 }
        return (normalized.reduce(0, +) / Double(normalized.count)) * 5.0
    }
}
