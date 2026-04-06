//
//  Equipment.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import Foundation

enum Equipment: String, Codable, CaseIterable, Identifiable, Hashable {
    case noEquipment = "Kein Equipment"
    case bodyweight = "Bodyweight"
    case theraband = "Theraband"
    case resistanceBand = "Widerstandsband"
    case weights = "Gewichte"
    case dumbbells = "Kurzhanteln"
    case kettlebell = "Kettlebell"
    case foamRoller = "Faszienrolle"
    case mat = "Matte"
    case ball = "Ball"
    case balanceBoard = "Balance Board"
    case chair = "Stuhl"
    case wall = "Wand"
    case steps = "Treppe/Stufe"
    
    var id: String { rawValue }
}