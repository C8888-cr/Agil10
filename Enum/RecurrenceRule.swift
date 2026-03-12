//
//  RecurrenceRule.swift
//  Agil10.0
//
//  Created by Christiane Roth on 05.03.26.
//


// RecurrenceRule.swift
//wdh. der eingesetzten videos
import Foundation
enum RecurrenceRule: String, Codable, CaseIterable {
    case single   = "Einmalig"
    case daily    = "Täglich"
    case weekly   = "Wöchentlich"
    case monthly  = "Monatlich"
    
    var icon: String {
        switch self {
        case .single:  return "1.circle"
        case .daily:   return "arrow.clockwise"
        case .weekly:  return "calendar.badge.clock"
        case .monthly: return "calendar"
        }
    }
    
    var description: String {
        switch self {
        case .single:  return "Nur an diesem Tag"
        case .daily:   return "Jeden Tag wiederholen"
        case .weekly:  return "Jede Woche am gleichen Wochentag"
        case .monthly: return "Jeden Monat am gleichen Wochentag"
        }
    }
}
