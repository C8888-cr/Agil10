//
//  DataManager.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//


import Foundation
import Combine
import SwiftData


/// Zentrale Verwaltung aller App-Daten und -Manager
@MainActor
final class DataManager: ObservableObject {
    
    // MARK: - Properties
    
    /// Verwaltet Benutzereinstellungen (Trainingszeiten, aktive Tage)
    let weeklySettings: WeeklySettings
    
    /// Verwaltet Trainingsdaten und Fortschritt
    let trainingData: TrainingData
    
    /// Verwaltet Video-Auswahl und -Verwaltung
  //  let videoManager: VideoSelectionManager
    
    let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.weeklySettings = WeeklySettings()
        self.trainingData = TrainingData(weeklySettings: weeklySettings)
     //   self.videoManager = VideoSelectionManager()
    }
    
    // MARK: - Public Methods
    
    /// Setzt alle Daten zurück (z.B. bei Logout)
 //   func resetAllData() {
 //       weeklySettings.reset()
      //   trainingData.reset()
      //   videoManager.reset()
//    }
    
    /// Speichert alle Daten persistent
//    func saveAllData() {
//        weeklySettings.saveSettings()
//    }
}
// MARK: - Convenience Methods
extension DataManager {
    
    
    /// Gibt den aktuellen Wochenfortschritt zurück (0.0 - 1.0)
    var weeklyProgress: Double {
        let completedMinutes = trainingData.getWatchedVideos()
           // .reduce(into: 0) { $0 += $1.totalDurationSeconds }
        
        //TODO: rausfinden ob Minutes oder Seconds besser ist
            .reduce(0) { $0 + $1.durationMinutes }
        let targetMinutes = weeklyTargetMinutes
        return targetMinutes > 0 ? Double(completedMinutes) / Double(targetMinutes) : 0
    }
    
    /// Wochenziel in Minuten
    var weeklyTargetMinutes: Int {
        return weeklySettings.activeDays.count * weeklySettings.dailyTargetMinutes
    }
    
    /// Prüft ob heute ein Trainingstag ist
    var isTodayActiveDay: Bool {
        let today = Calendar.current.component(.weekday, from: Date())
        let dayNames = ["", "So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"]
        guard today < dayNames.count else { return false }
        return weeklySettings.activeDays.contains(dayNames[today])
    }
}
