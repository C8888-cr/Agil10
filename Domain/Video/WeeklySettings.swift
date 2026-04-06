//
//  WeeklySettings.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import Foundation
import SwiftUI

class WeeklySettings: Codable, ObservableObject {
    var activeDays: [String] = ["Mo", "Di", "Mi", "Do", "Fr"]
    var dailyTargetMinutes: Int = 15
    
    var weeklyTargetMinutes: Int {
        activeDays.count * dailyTargetMinutes
    }
}
