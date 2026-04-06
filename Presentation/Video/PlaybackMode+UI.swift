//
//  PlaybackMode+UI.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//
import Foundation

extension PlaybackMode {
    var icon: String {
        switch self {
        case .normal: return "play.circle"
        case .loop: return "repeat"
        case .training: return "figure.run"
        }
    }
}
