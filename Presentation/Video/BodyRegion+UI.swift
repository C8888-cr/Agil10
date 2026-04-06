//
//  BodyRegion+UI.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//

extension BodyRegion {
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
