//
//  AuthServiceProtocol.swift
//  Agil10.0
//
//  Created by Christiane Roth on 16.12.25.
//

import SwiftUI
import SwiftData


protocol AuthServiceProtocol {

    func login(email: String, password: String) async throws -> (user: User, sessionToken: String)
    
    func sendPasswordResetEmail(email: String) async throws -> String
    
    func confirmPasswordReset(email: String, resetCode: String, newPassword: String) async throws
    
    func fetchCurrentUser() async throws -> User?  // ← NEU!
    
    func logout() async
    
    // ✅ SignUp gibt auch Token zurück
    func signUp(
          email: String,
          password: String,
          firstName: String,
          lastName: String,
          role: UserRole)
                async throws -> (User, String)  // ✅ (User, Token)
}
