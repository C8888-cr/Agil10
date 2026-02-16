//
//  RatingHelpers.swift
//  Agil10.0
//
//  Created by Christiane Roth on 15.02.26.
//


import SwiftUI
// Gemeinsame Rating-Hilfsfunktionen
struct RatingHelpers {
    static func smileyForRating(_ rating: Int) -> String {
        switch rating {
        case 1: return "😞"
        case 2: return "😐"
        case 3: return "🙂"
        case 4: return "😊"
        case 5: return "🤩"
        default: return "🙂"
        }
    }
    
    static func ratingText(_ rating: Int) -> String {
        switch rating {
        case 1: return "Schwer"
        case 2: return "Okay"
        case 3: return "Gut"
        case 4: return "Super"
        case 5: return "Perfekt"
        default: return ""
        }
    }
}