//
//  BodyRegion.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//

import SwiftData
import Foundation
import SwiftUICore

/// Körperregionen
enum BodyRegion: String, Codable, CaseIterable, Identifiable {
    case head = "Kopf"
    case cervicalSpine = "HWS"
    case thoracicSpine = "BWS"
    case lumbarSpine = "LWS"
    case spine = "Wirbelsäule"
    case back = "Rücken"
    case abdomen = "Bauch"
    case glutes = "Po"
    case arms = "Arme"
    case legs = "Beine"
    case fullBody = "Ganzkörper"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .head: return "brain.head.profile"
        case .cervicalSpine: return "figure.stand"
        case .thoracicSpine: return "figure.stand"
        case .lumbarSpine: return "figure.stand"
        case .spine: return "figure.stand"
        case .back: return "figure.stand"
        case .abdomen: return "figure.core.training"
        case .glutes: return "figure.strengthtraining.traditional"
        case .arms: return "figure.arms.open"
        case .legs: return "figure.walk"
        case .fullBody: return "figure.mixed.cardio"
        }
    }
}
