//
//  ExerciseSubtype.swift
//  Agil10.0
//
//  Created by Christiane Roth on 19.04.26.
//


//
//  ExerciseSubtype.swift
//  Agil
//
//  Unterscheidung bei Kraft-Übungen: dynamisch (mit Tempo) vs. isometrisch (mit Haltezeit)
//

import Foundation

enum ExerciseSubtype: String, Codable, CaseIterable, Identifiable, Hashable {
    case dynamic = "Dynamisch"
    case isometric = "Isometrisch"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .dynamic:   return "Mit Bewegungstempo (exzentrisch/konzentrisch)"
        case .isometric: return "Mit Haltezeit (statische Spannung)"
        }
    }
}