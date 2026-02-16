//
//  VideoError.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  VideoError.swift
//  Agil7.0
//
//  Created by Christiane Roth on 10.10.25.
//

//
//  VideoError.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.01.25.
//
import Foundation
enum VideoError: LocalizedError {
    case directoryNotFound
    case fileNotFound
    case thumbnailGenerationFailed
    case assetNotFound
    case invalidURL
    case exportFailed
    case permissionDenied
    case playerNotReady
    
    var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            return "Video-Verzeichnis konnte nicht gefunden werden"
        case .fileNotFound:
            return "Video-Datei konnte nicht gefunden werden"
        case .thumbnailGenerationFailed:
            return "Thumbnail konnte nicht erstellt werden"
        case .assetNotFound:
            return "Video-Asset konnte nicht gefunden werden"
        case .invalidURL:
            return "Ungültige Video-URL"
        case .exportFailed:
            return "Video-Export fehlgeschlagen"
        case .permissionDenied:
            return "Keine Berechtigung für Video-Zugriff"
        case.playerNotReady:
            return "Video-Player nicht bereit"
        }
    }
}
