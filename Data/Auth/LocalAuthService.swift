//
//  LocalAuthService.swift
//  Agil
//
//  Lokaler, offline Auth-Service ohne Firebase/Netzwerk.
//  Ersetzt FirebaseAuthService hinter AuthServiceProtocol.
//  Persistenz über den zentralen KeychainStore (gerätegebunden).
//

import Foundation
import CryptoKit

final class LocalAuthService: AuthServiceProtocol {

    private let keychain = KeychainStore(service: "de.agil.localauth")
    private let accountKey = "account"
    private let sessionKey = "session"

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
        keychain.delete(account: accountKey)
        keychain.delete(account: sessionKey)
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

    /// 16 zufällige Bytes aus dem CSPRNG von CryptoKit.
    static func makeSalt() -> Data {
        SymmetricKey(size: .bits128).asData
    }
}

// MARK: - Account & Session State
private extension LocalAuthService {
    var isSessionActive: Bool {
        keychain.exists(account: sessionKey)
    }

    func setSessionActive(_ active: Bool) {
        if active { try? keychain.save(Data([1]), account: sessionKey) }
        else { keychain.delete(account: sessionKey) }
    }

    private func loadAccount() -> StoredAccount? {
        guard let data = try? keychain.load(account: accountKey) else { return nil }
        return try? JSONDecoder().decode(StoredAccount.self, from: data)
    }

    private func saveAccount(_ account: StoredAccount) throws {
        let data = try JSONEncoder().encode(account)
        try keychain.save(data, account: accountKey)
    }
}

// MARK: - Errors
enum LocalAuthError: LocalizedError {
    case noAccount
    case invalidCredentials
    case passwordResetUnavailable

    var errorDescription: String? {
        switch self {
        case .noAccount:                return "Kein lokales Konto vorhanden. Bitte zuerst registrieren."
        case .invalidCredentials:       return "E-Mail oder Passwort ist falsch."
        case .passwordResetUnavailable: return "Passwort-Reset ist offline nicht verfügbar."
        }
    }
}
