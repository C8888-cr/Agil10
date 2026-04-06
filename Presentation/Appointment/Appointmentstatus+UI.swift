//
//  Appointmentstatus+UI.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//

import SwiftUI

extension AppointmentStatus {
    var icon: String {
        switch self {
        case .scheduled: return "clock.fill"
        case .modified: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .confirmed: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .scheduled: return .black
        case .modified: return .orange
        case .cancelled: return .red
        case .confirmed: return .accent
        }
    }
}
