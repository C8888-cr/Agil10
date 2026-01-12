//
//  Equipment.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//
import SwiftData
import Foundation
import SwiftUICore

enum Equipment: String, Codable, CaseIterable, Identifiable, Hashable {
    case noEquipment = "Kein Equipment"
    case bodyweight = "Bodyweight"
    case theraband = "Theraband"
    case weights = "Gewichte"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .noEquipment:
            return "hand.raised.fill"
        case .bodyweight: return "figure.walk"
        case .theraband: return "bandage"
        case .weights: return "dumbbell"
        }
    }
}
