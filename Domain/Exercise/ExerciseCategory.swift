//
//  ExerciseCategory.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import Foundation

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case warmup = "Aufwärmen"
    case strength = "Kraft"
    case mobility = "Mobilisation"
    case stretching = "Dehnung"
    case cardio = "Ausdauer"
    case cooldown = "Cool Down"
    case coordination = "Koordination"
    
    var id: String { rawValue }
    
    var colorHex: String {
        switch self {
        case .warmup: return "FF6B6B"
        case .strength: return "4ECDC4"
        case .mobility: return "95E1D3"
        case .stretching: return "F38181"
        case .cardio: return "FF8B94"
        case .cooldown: return "A8E6CF"
        case .coordination: return "FFD93D"
        }
    }
}