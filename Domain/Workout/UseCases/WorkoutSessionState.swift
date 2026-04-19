//
//  WorkoutSessionState.swift
//  Agil10.0
//
//  Created by Christiane Roth on 19.04.26.
//


//
//  WorkoutSessionState.swift
//  Agil
//
//  State-Definition für eine Expertenmodus-Trainingssession.
//

import Foundation

// MARK: - Session State

enum WorkoutSessionState: Equatable {
    case idle                    // Bereit, noch nicht gestartet
    case working(SetProgress)    // Aktiver Satz läuft
    case resting(RestProgress)   // Pause zwischen Sätzen
    case done                    // Alle Sätze fertig
}

// MARK: - Set Progress

/// Fortschritt während eines laufenden Satzes
struct SetProgress: Equatable {
    let currentSet: Int          // 1-indexiert (1/3, 2/3, 3/3)
    let totalSets: Int
    let currentRep: Int          // 0-indexiert intern, UI zeigt currentRep+1 oder currentRep als "absolviert"
    let totalReps: Int
    let phase: RepPhase
    /// Verbleibende Zeit in der aktuellen Phase, in Sekunden (Dezimal für smoothe Animation)
    let phaseTimeRemaining: Double
    /// Fortschritt der aktuellen Phase von 0.0 bis 1.0 (für Balken-Füllung)
    let phaseProgress: Double
}

// MARK: - Rep Phase

enum RepPhase: Equatable {
    case concentric   // Hoch / anspannen
    case hold         // Halten
    case eccentric    // Runter / langsam ablassen
    case isometric    // Statisches Halten (nur bei Subtype .isometric)
    
    var displayLabel: String {
        switch self {
        case .concentric: return "HOCH"
        case .hold:       return "HALTEN"
        case .eccentric:  return "RUNTER"
        case .isometric:  return "HALTEN"
        }
    }
}

// MARK: - Rest Progress

/// Fortschritt während der Pause zwischen Sätzen
struct RestProgress: Equatable {
    /// Der gerade beendete Satz (z.B. 1 wenn Satz 1 fertig ist und Pause läuft vor Satz 2)
    let completedSet: Int
    let totalSets: Int
    let secondsRemaining: Int
    let totalSeconds: Int
    
    /// Fortschritt der Pause von 0.0 (gerade gestartet) bis 1.0 (vorbei)
    var progress: Double {
        guard totalSeconds > 0 else { return 1.0 }
        return 1.0 - (Double(secondsRemaining) / Double(totalSeconds))
    }
}
// MARK: - Bar Position

/// Normalisierte Position des wandernden Langbalkens innerhalb der Pille (0.0 = unten, 1.0 = oben).
/// Fix-Marker ist separat in der View bei konstanter Höhe.
extension SetProgress {
    /// Bar-Position zwischen 0.05 (Start unten) und 0.90 (Peak oben)
    var longBarPosition: Double {
        let minPos = 0.05
        let maxPos = 0.90
        
        switch phase {
        case .concentric:
            return minPos + phaseProgress * (maxPos - minPos)
        case .hold:
            return maxPos
        case .eccentric:
            return maxPos - phaseProgress * (maxPos - minPos)
        case .isometric:
            return minPos + phaseProgress * (maxPos - minPos)
        }
    }
}
