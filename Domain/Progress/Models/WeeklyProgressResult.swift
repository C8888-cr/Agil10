//
//  WeeklyProgressResult.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//


struct WeeklyProgressResult {
    let completedSeconds: Int
    let targetSeconds: Int

    var completedMinutes: Int { completedSeconds / 60 }
    var targetMinutes: Int { targetSeconds / 60 }
    var weeklyProgress: Double {
        guard targetSeconds > 0 else { return 0.0 }
        return Double(completedSeconds) / Double(targetSeconds)
    }
}
