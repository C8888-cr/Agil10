//
//  AppointmentStatus.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  AppointmentStatus.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.10.25.
//

// Features/Appointments/Models/AppointmentStatus.swift
import Foundation
import SwiftUI
import SwiftData

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
    
    var icon: String {
        switch self {
        case .scheduled: return "clock.fill"
        case .modified: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .confirmed: return "checkmark.circle.fill"
        }
    }
    
    var colorString: String {
        switch self {
        case .scheduled: return "blue"
        case .modified: return "orange"
        case .cancelled: return "red"
        case .confirmed: return "green"
        }
    }

    // ✅ Color für SwiftUI Views
    var color: Color {
        switch self {
        case .scheduled: return .black
        case .modified: return .orange
        case .cancelled: return .red
        case .confirmed: return .accent
        }
    }
}
