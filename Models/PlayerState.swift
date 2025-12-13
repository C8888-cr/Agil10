//
//  PlayerState.swift
//  Agil
//
//  Created by Christiane Roth on 26.11.25.
//


//
//  PlayerState.swift
//  Agil7.0
//
//  Created by Christiane Roth on 10.10.25.
//

//
//  PlayerState.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.01.25.
//
import Foundation
import AVFoundation
/// Player-Zustand
enum PlayerState: Equatable {
    case idle
    case loading
    case ready
    case playing
    case paused
    case buffering
    case ended
    case failed(Error)
    
    static func == (lhs: PlayerState, rhs: PlayerState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.ready, .ready),
             (.playing, .playing),
             (.paused, .paused),
             (.buffering, .buffering),
             (.ended, .ended):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}
/// Wiedergabe-Modus
enum PlaybackMode: String, CaseIterable {
    case normal = "Normal"
    case loop = "Loop"
    case training = "Training"
    
    var icon: String {
        switch self {
        case .normal: return "play.circle"
        case .loop: return "repeat"
        case .training: return "figure.run"
        }
    }
}
/// Wiedergabe-Geschwindigkeit
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
