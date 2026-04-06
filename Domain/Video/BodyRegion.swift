//
//  BodyRegion.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import Foundation

enum BodyRegion: String, Codable, CaseIterable, Identifiable, Hashable {
    case head = "Kopf"
    case cervicalSpine = "HWS"
    case thoracicSpine = "BWS"
    case lumbarSpine = "LWS"
    case spine = "Wirbelsäule"
    case back = "Rücken"
    case abdomen = "Bauch"
    case glutes = "Po"
    case arms = "Arme"
    case legs = "Beine"
    case fullBody = "Ganzkörper"
    
    var id: String { rawValue }
}