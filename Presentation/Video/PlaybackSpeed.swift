//
//  PlaybackSpeed.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import Foundation

enum PlaybackSpeed: Float, CaseIterable, Identifiable {
    case slow = 0.5
    case normal = 1.0
    case fast = 1.5
    case veryFast = 2.0
    
    var id: Float { rawValue }
    
    var displayText: String {
        switch self {
        case .slow: return "0.5x"
        case .normal: return "1x"
        case .fast: return "1.5x"
        case .veryFast: return "2x"
        }
    }
}