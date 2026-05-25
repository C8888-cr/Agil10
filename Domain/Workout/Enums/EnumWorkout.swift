//
//  WorkoutModus.swift
//  Agil
//
//  Unterscheidung verschiedener Trainings-Modi mit jeweils eigenem Tempo-Schema.
//

import Foundation

enum WorkoutModus: String, Codable, CaseIterable, Identifiable {
    case standard = "standard"
    case mobility = "mobility"
    case reha = "reha"
    case strength = "kraftaufbau"
    case expert = "experte"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .mobility: return "Mobilität"
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
        case .standard:     return (0, 0, 0)
        case .mobility:     return (3, 0, 3)    // langsam, bewusst
        case .reha:     return (2, 1, 2)    // moderat
        case .strength: return (1, 0, 1)    // standard
        case .expert:   return (1, 0, 2)    // Hypertrophie: exzentrisch betont
        }
    }
    
    /// Erkennt anhand eines TempoProtocol welcher Modus passt.
    /// Findet kein Match → .expert (weil das der frei konfigurierbare Modus ist).
    static func matching(_ tempo: TempoProtocol) -> WorkoutModus {
           for modus in WorkoutModus.allCases where modus != .standard {
               let preset = modus.tempoPreset
               if tempo.concentricSec == preset.concentric
                   && tempo.holdSec == preset.hold
                   && tempo.eccentricSec == preset.eccentric {
                   return modus
               }
           }
           return .expert
       }
    
    
    // NEU — in WorkoutModus ergänzen:

    /// Modi, die der Nutzer in den Einstellungen wählen darf.
    /// (reha / strength sind interne Modi, nicht in der UI sichtbar.)
    static var selectableCases: [WorkoutModus] {
        [.standard, .mobility, .expert]
    }

    /// Erklärtext für die Einstellungen.
    var settingsHint: String {
        switch self {
        case .standard:
            return "Klassisches Training ohne Tempo-Vorgabe."
        case .mobility:
            return "Ruhiges Training mit höheren Wiederholungen und sanftem Tempo."
        case .expert:
            return "Krafttraining mit Tempo-Vorgabe und Gewichts-Tracking."
        case .reha, .strength:
            return ""
        }
    }
}
