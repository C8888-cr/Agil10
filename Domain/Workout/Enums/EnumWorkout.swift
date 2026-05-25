//
//  WorkoutModus.swift
//  Agil
//
//  Unterscheidung verschiedener Trainings-Modi mit jeweils eigenem Tempo-Schema.
//

import Foundation

enum WorkoutModus: String, Codable, CaseIterable, Identifiable {
    case mobility = "mobility"
    case reha = "reha"
    case strength = "kraftaufbau"
    case expert = "experte"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .mobility: return "Mobility"
        case .reha:     return "Reha"
        case .strength: return "Kraftaufbau"
        case .expert:   return "Experte"
        }
    }
    
    /// Passt zum Tempo-Schema: konzentrisch-halten-exzentrisch in Sekunden.
    /// Wird zum Matchen verwendet, damit "Experte" erkennt ob das geladene
    /// TempoProtocol tatsächlich noch seinem Preset entspricht.
    var tempoPreset: (concentric: Int, hold: Int, eccentric: Int) {
        switch self {
        case .mobility:     return (3, 0, 3)    // langsam, bewusst
        case .reha:     return (2, 1, 2)    // moderat
        case .strength: return (1, 0, 1)    // standard
        case .expert:   return (1, 0, 2)    // Hypertrophie: exzentrisch betont
        }
    }
    
    /// Erkennt anhand eines TempoProtocol welcher Modus passt.
    /// Findet kein Match → .expert (weil das der frei konfigurierbare Modus ist).
    static func matching(_ tempo: TempoProtocol) -> WorkoutModus {
        for modus in WorkoutModus.allCases {
            let preset = modus.tempoPreset
            if tempo.concentricSec == preset.concentric
                && tempo.holdSec == preset.hold
                && tempo.eccentricSec == preset.eccentric {
                return modus
            }
        }
        return .expert
    }
}
