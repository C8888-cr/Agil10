//
//  ExerciseCategory+UI.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//

import SwiftUI

extension ExerciseCategory {
    var icon: String {
        switch self {
        case .warmup: return "flame.fill"
        case .strength: return "dumbbell.fill"
        case .mobility: return "figure.flexibility"
        case .stretching: return "figure.stand"
        case .cardio: return "heart.fill"
        case .cooldown: return "wind"
        case .coordination: return "figure.walk"
        }
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
}
