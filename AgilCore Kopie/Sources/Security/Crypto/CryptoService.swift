//
//  CryptoService.swift
//  AgilCore
//
//  AES-GCM Verschlüsselung/Entschlüsselung von Data.
//  Zustandslos und rein – die Schlüssel kommen vom KeyManager.
//

import Foundation
import CryptoKit

public struct CryptoService {

    public enum CryptoError: LocalizedError {
        case sealFailed

        public var errorDescription: String? {
            switch self {
            case .sealFailed: return "Verschlüsselung fehlgeschlagen."
            }
        }
    }

    public init() {}

    /// Verschlüsselt `data` mit AES-GCM. Rückgabe ist die kombinierte Form (Nonce + Ciphertext + Tag).
    public func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else { throw CryptoError.sealFailed }
        return combined
    }

    /// Entschlüsselt eine zuvor mit `encrypt(_:using:)` erzeugte kombinierte AES-GCM-Form.
    public func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: key)
    }
}
