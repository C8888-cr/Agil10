//
//  PlayerState.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import Foundation

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
        case (.idle, .idle), (.loading, .loading), (.ready, .ready),
             (.playing, .playing), (.paused, .paused),
             (.buffering, .buffering), (.ended, .ended):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}