//
//  Equipment.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//
import SwiftData
import Foundation
import SwiftUI

enum Equipment: String, Codable, CaseIterable, Identifiable, Hashable {
    case noEquipment = "Kein Equipment"
    case bodyweight = "Bodyweight"
    case theraband = "Theraband"
    case resistanceBand = "Widerstandsband"
    case weights = "Gewichte"
    case dumbbells = "Kurzhanteln"
    case kettlebell = "Kettlebell"
    case foamRoller = "Faszienrolle"
    case mat = "Matte"
    case ball = "Ball"
    case balanceBoard = "Balance Board"
    case chair = "Stuhl"
    case wall = "Wand"
    case steps = "Treppe/Stufe"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .noEquipment: return "hand.raised.fill"
        case .bodyweight: return "figure.walk"
        case .theraband: return "bandage"
        case .resistanceBand: return "arrow.left.and.right"
        case .weights: return "dumbbell"
        case .dumbbells: return "dumbbell.fill"
        case .kettlebell: return "circle.fill"
        case .foamRoller: return "cylinder.fill"
        case .mat: return "rectangle.fill"
        case .ball: return "soccerball"
        case .balanceBoard: return "minus"
        case .chair: return "chair.lounge.fill"
        case .wall: return "square.lefthalf.filled"
        case .steps: return "stairs"
        }
    }
}
