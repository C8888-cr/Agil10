//
//  MockAuthService.swift
//  Agil10.0
//
//  Created by Christiane Roth on 21.12.25.
//
import SwiftUI
import SwiftData

final class MockAuthService: AuthServiceProtocol {
    private weak var modelContext: ModelContext?
    
    // ✅ NEU: Init mit ModelContext
      init(modelContext: ModelContext? = nil) {
          self.modelContext = modelContext
      }
    // ✅ NEU: Token-Mapping
     private var activeTokens: [String: String] = [:]
    
    
    // ✅ FESTE IDs
    static let mockPatientId = UUID(uuidString: "12345678-1234-5678-1234-123456789ABC")!
    static let mockTherapistId = UUID(uuidString: "87654321-4321-8765-4321-CBA987654321")!
    
    // ✅ Mock User Record Struktur
    struct MockUserRecord {
        let id: UUID
        let email: String
        let firstName: String
        let lastName: String
        let password: String
        let isTherapist: Bool
        let praxisId: UUID?
        
        func toUser() -> User {
            User(
                id: id,
                firstName: firstName,
                lastName: lastName,
                email: email,
                passwordHash: password,
                role: isTherapist ? .therapist : .patient,
                praxisId: praxisId
            )
        }
    }
    
    // 🎭 Fake-Datenbank
    private var mockUsers: [String: MockUserRecord] = [
        "patient@agil.de": MockUserRecord(
            id: MockAuthService.mockPatientId,
            email: "patient@agil.de",
            firstName: "Max",
            lastName: "Mustermann",
            password: "patient1",
            isTherapist: false,
            praxisId: PraxisDataManager.praxis4Id
        ),
        "therapist@agil.de": MockUserRecord(
            id: MockAuthService.mockTherapistId,
            email: "therapist@agil.de",
            firstName: "Christiane",
            lastName: "Roth",
            password: "therapist1",
            isTherapist: true,
            praxisId: PraxisDataManager.praxis4Id
        )
    ]
  
    
    
    // ✅ SIGN UP (neue User registrieren)
    func signUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        role: UserRole,
        praxisId: UUID?
    ) async throws -> (User, String) {
        
        // ✅ Prüfe ob Email bereits existiert
        if mockUsers[email.lowercased()] != nil {
            throw AuthError.emailAlreadyExists
        }
        
        // ✅ Erstelle neuen User
        let newUserId = UUID()
        let newRecord = MockUserRecord(
            id: newUserId,
            email: email.lowercased(),
            firstName: firstName,
            lastName: lastName,
            password: password,
            isTherapist: role == .therapist,
            praxisId: praxisId
        )
        
        // ✅ Speichere in Mock-Datenbank
        mockUsers[email.lowercased()] = newRecord
        
        // ✅ Erstelle User-Objekt
        let newUser = User(
            id: newUserId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            passwordHash: "",  // ✅ Wird nie zurückgegeben
            role: role,
            praxisId: praxisId
        )
        
        // ✅ Token generieren
        let token = "mock-token-\(UUID().uuidString)"
        activeTokens[token] = email.lowercased()
        
        
        print("✅ MockAuthService: User registriert - \(email)")
        print("🔑 Token: \(token)")
        // ✅ In SwiftData einfügen
             if let context = modelContext {
                 context.insert(newUser)
                 try? context.save()
             }
        // ✅ Simuliere Netzwerk-Delay
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        return (newUser, token)
    }

    

    // 🔐 LOGIN
    func login(email: String, password: String) async throws -> (user: User, sessionToken: String) {
        // ✅ Simuliere Netzwerk-Delay
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // ✅ Suche User
        guard let record = mockUsers[email.lowercased()] else {
            throw AuthError.userNotFound
        }
        
        // ✅ Prüfe Passwort
        guard record.password == password else {
            throw AuthError.invalidCredentials
        }
        
        // ✅ Erstelle User-Objekt
        let user = User(
            id: record.id,
            firstName: record.firstName,
            lastName: record.lastName,
            email: record.email,
            passwordHash: "",
            role: .patient,
            praxisId: record.praxisId
        )
        
        // ✅ Token generieren
        let token = "mock-token-\(UUID().uuidString)"
        activeTokens[token] = email.lowercased()
        print("✅ Mock Login erfolgreich für: \(email)")
        print("🔑 Token: \(token)")
        
        return (user, sessionToken: token)
    }
    
    // 👤 FETCH CURRENT USER (mit Token)
    func fetchCurrentUser() async throws -> User? {
        
        guard let token = KeychainHelper.load(forKey: "sessionToken") else {
                  return nil
              }
        // ✅ In echter App: Token validieren
        // ✅ Hier: Return einfach ersten User
        // ✅ NEU: Email aus Token holen
              guard let email = activeTokens[token] else {
                  return nil
              }
        
        
        guard let record = mockUsers["patient@agil.de"] else {
            return nil
        }
        
        print("✅ Mock: Current User geladen")
        return record.toUser()
    }
    
    // 👋 LOGOUT
    func logout() async {
        print("👋 Mock Logout")
    }
    
    // 📧 PASSWORD RESET EMAIL
    func sendPasswordResetEmail(email: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard mockUsers[email.lowercased()] != nil else {
            throw AuthError.userNotFound
        }
        
        let resetCode = String(UUID().uuidString.prefix(6))
        print("📧 Password Reset Code für \(email): \(resetCode)")
        return resetCode
    }
    
    // 🔐 CONFIRM PASSWORD RESET
    func confirmPasswordReset(email: String, resetCode: String, newPassword: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard ValidationHelper.isValidPassword(newPassword) else {
            throw AuthError.passwordTooShort
        }
        
        guard let record = mockUsers[email.lowercased()] else {
            throw AuthError.userNotFound
        }
        
        // ✅ Update Passwort in Mock-DB
        let updatedRecord = MockUserRecord(
            id: record.id,
            email: record.email,
            firstName: record.firstName,
            lastName: record.lastName,
            password: newPassword,
            isTherapist: record.isTherapist,
            praxisId: record.praxisId
        )
        mockUsers[email.lowercased()] = updatedRecord
        
        print("✅ Passwort zurückgesetzt für: \(email)")
    }
}
