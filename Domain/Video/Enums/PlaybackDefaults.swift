//
//  PlaybackDefaults.swift
//  Agil10.0
//
//  Created by Christiane Roth on 25.05.26.
//


import Foundation

/// Standardwerte für den Standard-Wiedergabemodus (nicht Expertenmodus).
/// Single Source of Truth – hier zentral ändern, nicht verstreut.
enum PlaybackDefaults {
    static let repetitions = 3
    static let pauseSeconds = 30
    static let loopDurationSeconds = 60
}
