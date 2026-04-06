//
//  VideoStorageError.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import Foundation
import AVFoundation
import UIKit
enum VideoStorageError: LocalizedError {
    case invalidURL
    case fileNotFound
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case insufficientSpace
    case fileTooLarge(maxSize: Int64)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige Video-URL"
        case .fileNotFound:
            return "Video-Datei wurde nicht gefunden"
        case .saveFailed(let reason):
            return "Speichern fehlgeschlagen: \(reason)"
        case .loadFailed(let reason):
            return "Laden fehlgeschlagen: \(reason)"
        case .deleteFailed(let reason):
            return "Löschen fehlgeschlagen: \(reason)"
        case .insufficientSpace:
            return "Nicht genügend Speicherplatz verfügbar"
        case .fileTooLarge(let maxSize):
            let maxMB = Double(maxSize) / (1024 * 1024)
            return "Video ist zu groß (max. \(Int(maxMB)) MB)"
        }
    }
}