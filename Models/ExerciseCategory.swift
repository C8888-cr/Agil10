//
//  ExerciseCategory.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import SwiftData
import Foundation
import SwiftUICore
/// Kategorien für Übungstypen
 enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case warmup = "Aufwärmen"
    case strength = "Kraft"
    case mobility = "Mobilisation"
    case stretching = "Dehnung"
    case cardio = "Ausdauer"
    case cooldown = "Cool Down"
    case coordination = "Koordination"
    
 var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .warmup: return "flame.fill"
        case .strength: return "dumbbell.fill"
        case .mobility: return "figure.flexibility"
        case .stretching: return "figure.stand"
        case .cardio: return "heart.fill"
        case .cooldown: return "wind"
        case .coordination: return "figure.walk"
        }
    }
    
    var colorHex: String {
        switch self {
        case .warmup: return "FF6B6B"      // Rot
        case .strength: return "4ECDC4"    // Türkis
        case .mobility: return "95E1D3"    // Mint
        case .stretching: return "F38181"  // Rosa
        case .cardio: return "FF8B94"      // Pink
        case .cooldown: return "A8E6CF"    // Hellgrün
        case .coordination: return "FFD93D" // Gelb
        }
    }
    // ✅ NEU: SwiftUI Color für direkte Verwendung
     var color: Color {
         Color(hex: colorHex)  // ✅ MIT "hex:" PARAMETER
     }
}
// MARK: - Color Extension (HEX Support)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

