//
//  AppointmentStatus.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import Foundation

enum AppointmentStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case modified = "modified"
    case cancelled = "cancelled"
    case confirmed = "confirmed"
    
    var displayName: String {
        switch self {
        case .scheduled: return "Geplant"
        case .modified: return "Geändert"
        case .cancelled: return "Abgesagt"
        case .confirmed: return "Bestätigt"
        }
    }
}