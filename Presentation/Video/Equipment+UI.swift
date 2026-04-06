//
//  Equipment+UI.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//

extension Equipment {
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
