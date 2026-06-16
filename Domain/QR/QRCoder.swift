//
//  QRCoder.swift
//  Agil10.0
//
//  Wandelt QRPayload <-> kompakte Transportform (JSON -> Base64-String).
//  Rein und testbar — kein UIKit, kein CoreImage. Das QR-Bild rendert die UI-Schicht.
//

import Foundation

enum QRCoderError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:           return "QR-Code konnte nicht erstellt werden."
        case .decodingFailed:           return "QR-Code konnte nicht gelesen werden."
        case .unsupportedVersion(let v): return "QR-Version \(v) wird nicht unterstützt."
        }
    }
}

struct QRCoder {

    /// Höchste Schema-Version, die dieser Client lesen kann.
    static let supportedVersion = 1

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Encode

    /// QRPayload -> Base64-String (das ist der reine QR-Inhalt, noch kein Bild).
    func encode(_ payload: QRPayload) throws -> String {
        do {
            let json = try encoder.encode(payload)
            return json.base64EncodedString()
        } catch {
            throw QRCoderError.encodingFailed
        }
    }

    // MARK: - Decode

    /// Base64-String (aus einem gescannten QR) -> QRPayload.
    func decode(_ string: String) throws -> QRPayload {
        guard let json = Data(base64Encoded: string) else {
            throw QRCoderError.decodingFailed
        }
        let payload: QRPayload
        do {
            payload = try decoder.decode(QRPayload.self, from: json)
        } catch {
            throw QRCoderError.decodingFailed
        }
        guard payload.version <= Self.supportedVersion else {
            throw QRCoderError.unsupportedVersion(payload.version)
        }
        return payload
    }
}
