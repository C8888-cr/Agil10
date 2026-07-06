//
//  QRError.swift
//  AgilCore
//
//  Fehlertypen für QR-Code Verarbeitung (Encoding/Decoding).

import Foundation

public enum QRError: LocalizedError {
    case encodingFailed(String)
    case decodingFailed(String)
    case unsupportedVersion(Int)
    case invalidPayload(String)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let reason):
            return "QR-Code konnte nicht erstellt werden: \(reason)"
        case .decodingFailed(let reason):
            return "QR-Code konnte nicht gelesen werden: \(reason)"
        case .unsupportedVersion(let v):
            return "QR-Version \(v) wird nicht unterstützt."
        case .invalidPayload(let reason):
            return "Ungültiger QR-Inhalt: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .encodingFailed:
            return "Bitte überprüfe die Eingabedaten und versuche es erneut."
        case .decodingFailed:
            return "Bitte stelle sicher, dass der QR-Code lesbar und korrekt ist."
        case .unsupportedVersion:
            return "Die App muss aktualisiert werden, um diese QR-Version zu unterstützen."
        case .invalidPayload:
            return "Bitte scanne einen gültigen Agil-QR-Code."
        }
    }
}
