//
//  WeeklySettings.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//
import SwiftUI
import Foundation
import SwiftData

// MARK: - WeeklySettings (UNVERÄNDERT)
class WeeklySettings: Codable, ObservableObject {
    var activeDays: [String] = ["Mo", "Di", "Mi", "Do", "Fr"]
    var dailyTargetMinutes: Int = 15
    
    /// Wochenziel in Minuten
    var weeklyTargetMinutes: Int {
        return activeDays.count * dailyTargetMinutes
    }
  
}
