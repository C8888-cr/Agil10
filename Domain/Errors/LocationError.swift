//
//  LocationError.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import Foundation

enum LocationError: LocalizedError {
    case geocodingFailed
    case reverseGeocodingFailed
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .geocodingFailed:
            return "Adresse konnte nicht gefunden werden"
        case .reverseGeocodingFailed:
            return "Koordinaten konnten nicht in Adresse umgewandelt werden"
        case .unauthorized:
            return "Standort-Berechtigung fehlt"
        }
    }
}