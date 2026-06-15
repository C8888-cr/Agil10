//
//  KeyManager.swift
//  Agil10.0
//
//  Created by Christiane Roth on 15.06.26.
//


//
//  KeyManager.swift
//  Agil
//
//  Erzeugt und verwahrt den symmetrischen App-Schlüssel gerätegebunden
//  in der Keychain. Liefert zusätzlich ephemere Schlüssel (z. B. pro Video
//  für spätere Envelope Encryption).
//

import Foundation
import CryptoKit

final class KeyManager {

    private let keychain: KeychainStore
    private let dataKeyAccount = "primary-data-key"

    init(keychain: KeychainStore = KeychainStore(service: "de.agil.crypto")) {
        self.keychain = keychain
    }

    /// Liefert den symmetrischen App-Schlüssel; erzeugt ihn beim ersten Aufruf.
    func dataKey() throws -> SymmetricKey {
        if let data = try keychain.load(account: dataKeyAccount) {
            return SymmetricKey(data: data)
        }
        let key = SymmetricKey(size: .bits256)
        try keychain.save(key.asData, account: dataKeyAccount)
        return key
    }

    /// Frischer, NICHT persistierter Schlüssel – z. B. ein eigener Key pro KGG-Video.
    func makeEphemeralKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }
}

extension SymmetricKey {
    /// Rohbytes des Schlüssels als `Data`.
    var asData: Data {
        withUnsafeBytes { Data($0) }
    }
}