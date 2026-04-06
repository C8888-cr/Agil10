//
//  DayPlan.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import Foundation

struct DayPlan: Identifiable {
    var id = UUID()
    var dayName: String
    var videos: [Video] = []
    var targetDuration: Double = 900
    
    var totalDurationInMinutes: Int {
        let totalSeconds = videos.reduce(0) { $0 + $1.loopDurationSeconds }
        return totalSeconds / 60
    }
    
    var progress: Double {
        let completed = videos.filter { $0.isWatched }
            .reduce(into: 0) { $0 += $1.loopDurationSeconds }
        return targetDuration > 0 ? Double(completed) / targetDuration : 0
    }
    
    var videosByType: [ExerciseCategory: [Video]] {
        Dictionary(grouping: videos) { $0.category }
    }
}