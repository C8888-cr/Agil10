//
//  DayPlan.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//
import Foundation
import SwiftUI


// MARK: - DayPlan (UNVERÄNDERT)
struct DayPlan: Identifiable {
    var id = UUID()
    var dayName: String
    var videos: [Video] = []
    var targetDuration: Double = 900 // 15 Minuten in Sekunden
    
    /// Gesamtdauer aller Videos in Minuten
    var totalDurationInMinutes: Int {
        let totalSeconds = videos.reduce(0) { $0 + $1.loopDurationSeconds }
           return totalSeconds / 60  // ✅ In Minuten umwandeln
    }
    
    /// Fortschritt (0.0 - 1.0)
    var progress: Double {
        let completed = videos.filter { $0.isWatched }
            .reduce(into: 0) { $0 += $1.loopDurationSeconds }
        return targetDuration > 0 ? Double(completed) / targetDuration : 0
    }
    
    /// Gruppiert Videos nach Typ
    var videosByType: [ExerciseCategory: [Video]] {
        Dictionary(grouping: videos) { $0.category }
    }
}
