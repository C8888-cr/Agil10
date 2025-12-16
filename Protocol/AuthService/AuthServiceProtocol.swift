//
//  AuthServiceProtocol.swift
//  Agil10.0
//
//  Created by Christiane Roth on 16.12.25.
//

import SwiftUI
import SwiftData


@MainActor
protocol AuthServiceProtocol {

    func login(email: String, password: String) async throws -> (user: User, sessionToken: String)
    func sendPasswordResetEmail(email: String) async throws -> String
    func confirmPasswordReset(email: String, resetCode: String, newPassword: String) async throws
    func fetchCurrentUser() async throws -> User?  // ← NEU!
    func logout() async                           // ← NEU!
}
/*  für später

class RealAuthService: AuthServiceProtocol {
    func fetchCurrentUser() async throws -> User? {
        // Backend API Call → echten User
        return try await backend.fetchUser()
    }
}
*/
@MainActor
final class MockAuthService: AuthServiceProtocol {
    
    // 🎭 Fake-Datenbank
    var mockUsers: [String: MockUserRecord] = [
        "patient@agil.de": MockUserRecord(
            id: MockAuthService.mockPatientId,
            email: "patient@agil.de",
            firstName: "Max",
            lastName: "Mustermann",
            password: "patient1",
            isTherapist: false
        ),
        "therapist@agil.de": MockUserRecord(
            id: MockAuthService.mockTherapistId,
            email: "therapist@agil.de",
            firstName: "Christiane",
            lastName: "Roth",
            password: "therapist1",
            isTherapist: true
        )
    ]
    // ✅ FESTER Mock-Patient mit STATISCHER UUID!
     static let mockPatientId = UUID(uuidString: "12345678-1234-5678-1234-123456789ABC")!
    // ✅ Statische Mock-User für Preview
    static let mockPatient = User(
        id: mockPatientId,
        firstName: "Max",
        lastName: "Mustermann",
        passwordHash: "patient1"
    )
    static let mockTherapistId = UUID(uuidString: "87654321-4321-8765-4321-CBA987654321")!
      static let mockTherapist = User(
        id: mockTherapistId,  // ← IMMER GLEICH!
        firstName: "Christiane",
        lastName: "Roth",
        passwordHash: "therapist1"
    )
    
    struct MockUserRecord {
        let id: UUID
        let email: String
        let firstName: String
        let lastName: String
        let password: String
        let isTherapist: Bool
    }
    
    // 🔐 LOGIN
    func login(email: String, password: String) async throws -> (user: User, sessionToken: String) {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        guard let record = mockUsers[email.lowercased()] else {
            throw AuthError.userNotFound
        }
        
        guard record.password == password else {
            throw AuthError.invalidCredentials
        }
        
        let user = User(
            id: record.id,
            firstName: record.firstName,
            lastName: record.lastName,
            passwordHash: record.password
        )
        
        let sessionToken = UUID().uuidString
        print("✅ Mock Login erfolgreich für: \(email)")
        return (user, sessionToken)
    }
    
    // 📧 PASSWORD RESET - Link senden
    func sendPasswordResetEmail(email: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard mockUsers[email.lowercased()] != nil else {
            throw AuthError.userNotFound
        }
        
        let resetCode = String(UUID().uuidString.prefix(6))
        print("📧 Password Reset Code für \(email): \(resetCode)")
        
        return resetCode
    }
    
    // 🔑 PASSWORD RESET - Bestätigen
    func confirmPasswordReset(
        email: String,
        resetCode: String,
        newPassword: String
    ) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard ValidationHelper.isValidPassword(newPassword) else {
            throw AuthError.passwordTooShort
        }
        
        guard mockUsers[email.lowercased()] != nil else {
            throw AuthError.userNotFound
        }
        
        if var record = mockUsers[email.lowercased()] {
            record = MockUserRecord(
                id: record.id,
                email: record.email,
                firstName: record.firstName,
                lastName: record.lastName,
                password: newPassword,
                isTherapist: record.isTherapist
            )
            mockUsers[email.lowercased()] = record
        }
        
        print("✅ Passwort zurückgesetzt für: \(email)")
    }
    // 🔥 NEU: Nur diese 2 Zeilen hinzufügen!

       func fetchCurrentUser() async throws -> User? {
           return MockAuthService.mockPatient  // Automatischer "eingeloggter" Patient
       }
       
       func logout() async {
           print("👋 Mock Logout")
       }
}
