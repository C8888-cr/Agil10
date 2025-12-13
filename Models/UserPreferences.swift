//
//  UserPreferences.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import SwiftData
import Foundation
//neue usersettings
@Model
final class UserPreferences {
    @Attribute(.unique) var id: UUID
    
    // ✅ Pro Tag einzeln konfigurierbar
    var weeklyGoals: [DayGoal] = []  // Mo-So mit Minuten & Pause
    
    // Notifications
    var notificationsEnabled: Bool
    var reminderTime: Date
    
    // Audio Feedback
    var soundEnabled: Bool
    
    // Auto-Play
    var autoPlayNextVideo: Bool
    
    // Display
    var showCompletedExercises: Bool
    var weekStartsOnMonday: Bool
    
    // Relationship
    var user: User?
    
  
    var defaultDailyTrainingMinutes: Int
    var activeDays: [String]

    
    init(
        notificationsEnabled: Bool = true,
        reminderTime: Date = Calendar.current.date(
            bySettingHour: 18,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date(),
        soundEnabled: Bool = true,
        autoPlayNextVideo: Bool = false,
        showCompletedExercises: Bool = true,
        weekStartsOnMonday: Bool = true,
        user: User? = nil,
        defaultDailyTrainingMinutes: Int = 30,
        activeDays: [String]? = nil
            
    ) {
        self.id = UUID()
        self.weeklyGoals = (0..<7).map {
            DayGoal(dayOfWeek: $0, targetMinutes: 30, interVideoPauseSeconds: 30)
        }
        self.notificationsEnabled = notificationsEnabled
        self.reminderTime = reminderTime
        self.soundEnabled = soundEnabled
        self.autoPlayNextVideo = autoPlayNextVideo
        self.showCompletedExercises = showCompletedExercises
        self.weekStartsOnMonday = weekStartsOnMonday
        self.user = user
        self.defaultDailyTrainingMinutes = defaultDailyTrainingMinutes
        self.activeDays = activeDays ?? ["Mo","Di","Mi","Do","Fr"]
   
    }
    
    func getGoalFor(dayOfWeek: Int) -> DayGoal? {
        weeklyGoals.first(where: { $0.dayOfWeek == dayOfWeek })
    }
}
@Model

//TODO: Dayplan? DayGoal = Same??
final class DayGoal {
    var dayOfWeek: Int           // 0=Mo, 6=So
    var targetMinutes: Int       // 0 = kein Training
    var interVideoPauseSeconds: Int
    var isActive: Bool = true    // Training an/aus für diesen Tag
    
    // ✅ NEU: Pro Tag einzelne Erinnerungen
      var reminderEnabled: Bool = true
      var reminderTime: Date = Calendar.current.date(
          bySettingHour: 18,
          minute: 0,
          second: 0,
          of: Date()
      ) ?? Date()
      
    init(dayOfWeek: Int, targetMinutes: Int, interVideoPauseSeconds: Int = 30) {
          self.dayOfWeek = dayOfWeek
          self.targetMinutes = targetMinutes
          self.interVideoPauseSeconds = interVideoPauseSeconds
          self.isActive = targetMinutes > 0
      }
  }
