//
//  KGGQRDecoderService.swift
//  Agil
//
//  Dekodiert gescannte QR-Strings zu QRPayload.
//

import Foundation
import AgilCore

public struct KGGQRDecoderService {
    
    private let qrCoder = QRCoder()
    
    public init() {}
    
    public func decodeQRString(_ qrString: String) throws -> QRPayload {
        return try qrCoder.decode(qrString)
    }
    
    public func extractExercises(from payload: QRPayload) -> [ExerciseAssignment] {
        return payload.assignments
    }
    
    public func isPayloadFresh(
        _ payload: QRPayload,
        maxAgeHours: Int = KGGConfiguration.maxQRCodeAgeHours
    ) -> Bool {
        let maxAge = TimeInterval(maxAgeHours * 3600)
        return Date().timeIntervalSince(payload.issuedAt) < maxAge
    }
    /// Parst einen Tempo-String im Format "concentric-hold-eccentric" (z.B. "2-0-2").
    /// Fällt bei ungültigem Format auf Default-Werte zurück.
    public func parseTempo(_ tempo: String) -> (concentric: Int, hold: Int, eccentric: Int) {
        let parts = tempo.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else {
            return (concentric: 2, hold: 0, eccentric: 2)
        }
        return (concentric: parts[0], hold: parts[1], eccentric: parts[2])
    }
}
