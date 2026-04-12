//
//  DailyProgressResult.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//


struct DailyProgressResult {
    let schedules: [VideoSchedule]
    let targetMinutes: Int
    let totalScheduledSeconds: Int
    let completedSeconds: Int
    let interVideoPauseSeconds: Int

    var targetSeconds: Int { targetMinutes * 60 }
    var completedMinutes: Int { (completedSeconds + 59) / 60 }
    var totalScheduledMinutes: Int { totalScheduledSeconds / 60 }
    var remainingMinutes: Int { max(0, targetMinutes - totalScheduledMinutes) }
    var remainingSeconds: Int { max(0, targetSeconds - completedSeconds) }
    var dailyProgress: Double {
        guard targetSeconds > 0, completedSeconds > 0 else { return 0.0 }
        return Double(completedSeconds) / Double(targetSeconds)
    }
    var progressPercentage: Double {
        guard targetSeconds > 0 else { return 0.0 }
        return Double(totalScheduledSeconds) / Double(targetSeconds)
    }
    var canAddMoreVideos: Bool { remainingMinutes > 0 }
}
