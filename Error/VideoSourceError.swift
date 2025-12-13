//
//  VideoSourceError.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//

import SwiftUI

// MARK: - Errors
enum VideoSourceError: LocalizedError {
    case fileNotFound
    case unsupportedSource
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "Video-Datei nicht gefunden"
        case .unsupportedSource: return "Nicht unterstützte Video-Quelle"
        case .downloadFailed: return "Download fehlgeschlagen"
        }
    }
}
