// PASTE TO: AgilCore/Sources/QR/KGGStartSessionToken.swift (NEU)

import Foundation

/// Anonymer, einmalig gültiger Trigger zum Freischalten der 60-Minuten-
/// Sichtbarkeit beim Patienten. Enthält bewusst KEINE Patienten- oder
/// Übungsdaten – nur eine eindeutige ID + Zeitstempel.
public struct KGGStartSessionToken: Codable, Equatable {
    public let id: UUID
    public let issuedAt: Date

    public init(id: UUID = UUID(), issuedAt: Date = Date()) {
        self.id = id
        self.issuedAt = issuedAt
    }
}

/// Kodiert/dekodiert den Start-QR als eigenständiges, klar unterscheidbares
/// Format (Prefix), damit der Scanner auf Patientenseite sofort erkennt:
/// "Das ist ein Start-Trigger, keine Übungszuweisung" – ohne die bestehende
/// verschlüsselte QRCoder-Pipeline für sensible Daten anzufassen.
public enum KGGStartSessionCoder {
    private static let prefix = "KGGSTART|"

    public static func isStartSessionQR(_ qrString: String) -> Bool {
        qrString.hasPrefix(prefix)
    }

    public static func encode(_ token: KGGStartSessionToken) throws -> String {
        let data = try JSONEncoder().encode(token)
        return prefix + data.base64EncodedString()
    }

    public static func decode(_ qrString: String) throws -> KGGStartSessionToken {
        guard qrString.hasPrefix(prefix) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Kein Start-Session-QR")
            )
        }
        guard let data = Data(base64Encoded: String(qrString.dropFirst(prefix.count))) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Ungültige Base64-Daten")
            )
        }
        return try JSONDecoder().decode(KGGStartSessionToken.self, from: data)
    }
}
