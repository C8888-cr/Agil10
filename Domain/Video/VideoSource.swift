//
//  VideoSource.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import Foundation

enum VideoSource: String, Codable {
    case recorded = "recorded"
    case downloaded = "downloaded"
    case cloud = "cloud"
    
    var displayName: String {
        switch self {
        case .recorded: return "Aufgenommen"
        case .downloaded: return "Heruntergeladen"
        case .cloud: return "Cloud"
        }
    }
}