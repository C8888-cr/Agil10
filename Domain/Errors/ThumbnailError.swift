//
//  ThumbnailError.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import Foundation
import AVFoundation
import UIKit
enum ThumbnailError: LocalizedError {
    case generationFailed(String)
    case saveFailed(String)
    case invalidVideo
    
    var errorDescription: String? {
        switch self {
        case .generationFailed(let reason):
            return "Thumbnail-Erstellung fehlgeschlagen: \(reason)"
        case .saveFailed(let reason):
            return "Thumbnail-Speicherung fehlgeschlagen: \(reason)"
        case .invalidVideo:
            return "Ungültiges Video für Thumbnail-Erstellung"
        }
    }
}