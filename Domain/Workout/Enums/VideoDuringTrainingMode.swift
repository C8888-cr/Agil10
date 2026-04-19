//
//  VideoDuringTrainingMode.swift
//  Agil10.0
//
//  Created by Christiane Roth on 19.04.26.
//


//
//  VideoDuringTrainingMode.swift
//  Agil
//
//  Legt fest, wie sich das Video in der ExpertModePlayerView beim Starten eines Satzes verhält.
//

import Foundation

enum VideoDuringTrainingMode: String, Codable, CaseIterable, Identifiable {
    case alwaysOn = "immerAn"
    case alwaysOff = "immerAus"
    case toggleable = "umschaltbar"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .alwaysOn:    return "Immer an"
        case .alwaysOff:   return "Immer aus"
        case .toggleable:  return "Pro Satz umschaltbar"
        }
    }
    
    var description: String {
        switch self {
        case .alwaysOn:    return "Video läuft während des Trainings mit"
        case .alwaysOff:   return "Video wird beim Satz-Start ausgeblendet"
        case .toggleable:  return "Du entscheidest pro Satz"
        }
    }
}