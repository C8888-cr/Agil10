//
//  LocalAuthService.swift
//  Agil10.0
//
//  Created by Christiane Roth on 15.06.26.
//


//
//  LocalAuthService.swift
//  Agil
//
//  Lokaler, offline Auth-Service ohne Firebase/Netzwerk.
//  Ersetzt FirebaseAuthService hinter AuthServiceProtocol.
//  Credentials liegen gehasht in der Keychain, gerätegebunden (kein iCloud-Sync).
//

import Foundation
import CryptoKit
import Security

final class LocalAuthService: AuthServiceProtocol {

    // MARK: - Keychain Keys
    private let accountKey = "de.agil.localauth.account"
    private let sessionKey = "de.agil.localauth.session"

    // MARK: - Stored Model
    private struct StoredAccount: Codable {
        let uid: String
        let email: String
        let firstName: String
        let lastName: String
        let praxisId: UUID?
        let salt: Data
        let passwordHash: Data

        var asAuthUser: AuthUser {
            AuthUser(uid: uid, email: email, firstName: firstName, lastName: lastName, praxisId: praxisId)
        }
    }

    // MARK: - AuthServiceProtocol

    var currentUser: AuthUser? {
        guard isSessionActive, let account = loadAccount() else { return nil }
        return account.asAuthUser
    }

    func login(email: String, password: String) async throws -> AuthUser {
        guard let account = loadAccount() else { throw LocalAuthError.noAccount }
        guard account.email.lowercased() == email.lowercased(),
              hash(password: password, salt: account.salt) == account.passwordHash else {
            throw LocalAuthError.invalidCredentials
        }
        setSessionActive(true)
        return account.asAuthUser
    }

    func signUp(email: String, password: String, firstName: String,
                lastName: String, praxisId: UUID?) async throws -> AuthUser {
        let salt = Self.makeSalt()
        let account = StoredAccount(
            uid: UUID().uuidString,
            email: email,
            firstName: firstName,
            lastName: lastName,
            praxisId: praxisId,
            salt: salt,
            passwordHash: hash(password: password, salt: salt)
        )
        try saveAccount(account)
        setSessionActive(true)
        return account.asAuthUser
    }

    func signOut() throws {
        // Konto bleibt erhalten – erneuter Login (auch via Face ID) möglich.
        setSessionActive(false)
    }

    func resetPassword(email: String) async throws {
        // Offline kein Mail-Versand möglich – bewusst nicht unterstützt.
        throw LocalAuthError.passwordResetUnavailable
    }

    func deleteAccount() async throws {
        deleteKeychain(key: accountKey)
        deleteKeychain(key: sessionKey)
    }
}

// MARK: - Hashing
private extension LocalAuthService {
    func hash(password: String, salt: Data) -> Data {
        var hasher = SHA256()
        hasher.update(data: salt)
        hasher.update(data: Data(password.utf8))
        return Data(hasher.finalize())
    }

    static func makeSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }
}

// MARK: - Account & Session State
private extension LocalAuthService {
    var isSessionActive: Bool { loadKeychain(key: sessionKey) != nil }

    func setSessionActive(_ active: Bool) {
        if active { try? saveKeychain(Data([1]), key: sessionKey) }
        else { deleteKeychain(key: sessionKey) }
    }

    private func loadAccount() -> StoredAccount? {
        guard let data = loadKeychain(key: accountKey) else { return nil }
        return try? JSONDecoder().decode(StoredAccount.self, from: data)
    }

    private func saveAccount(_ account: StoredAccount) throws {
        let data = try JSONEncoder().encode(account)
        try saveKeychain(data, key: accountKey)
    }
}

// MARK: - Keychain CRUD
private extension LocalAuthService {
    func saveKeychain(_ data: Data, key: String) throws {
        deleteKeychain(key: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw LocalAuthError.keychain(status) }
    }

    func loadKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }

    func deleteKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Errors
enum LocalAuthError: LocalizedError {
    case noAccount
    case invalidCredentials
    case passwordResetUnavailable
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .noAccount:               return "Kein lokales Konto vorhanden. Bitte zuerst registrieren."
        case .invalidCredentials:      return "E-Mail oder Passwort ist falsch."
        case .passwordResetUnavailable: return "Passwort-Reset ist offline nicht verfügbar."
        case .keychain(let status):    return "Keychain-Fehler (\(status))."
        }
    }
}
