//
//  AuthService.swift
//  Agil10.0
//
//  Created by Christiane Roth on 21.12.25.
//

import SwiftUI

@MainActor
class AuthService: ObservableObject {
    

    
    
    
    @Published var currentUser: User? = nil
    @Published var isLoading = false
    @Published var sessionToken: String? = nil
    @Published var isAuthenticated: Bool = false
    
    private let authServiceProtocol: AuthServiceProtocol
    
    
    init(authServiceProtocol: AuthServiceProtocol) {  // ✅ Normal!
          self.authServiceProtocol = authServiceProtocol
        // ✅ Token beim Start laden
              self.sessionToken = KeychainHelper.load(forKey: "sessionToken")
              self.isAuthenticated = sessionToken != nil
          }
    
    // 🔐 LOGIN mit Token
     func login(email: String, password: String) async throws {
         isLoading = true
         defer { isLoading = false }
         
         try await Task.sleep(nanoseconds: 1_500_000_000)
         
         // ✅ User UND Token erhalten
         let (user, token) = try await authServiceProtocol.login(
             email: email,
             password: password
         )
         
         // ✅ Beide speichern
         self.currentUser = user
         self.sessionToken = token
         self.isAuthenticated = true
         
         // ✅ Token in Keychain speichern
         KeychainHelper.save(token, forKey: "sessionToken")
         
         print("✅ AuthService Login: \(user.email)")
         print("🔑 Token: \(token)")
     }
    
    // 👋 LOGOUT
      func logout() async {
          await authServiceProtocol.logout()
          currentUser = nil
          sessionToken = nil  // ✅ Token löschen
          isAuthenticated = false
          
          
          KeychainHelper.delete(forKey: "sessionToken")  // ✅ Aus Keychain löschen
          print("👋 AuthService: User geloggt aus")
      }
    
    //MockLogin für jetzt
    // ✅ FETCH CURRENT USER (mit Token aus Keychain)

    func fetchCurrentUser() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // ✅ Token aus Keychain laden
        guard let token = KeychainHelper.load(forKey: "sessionToken") else {
            print("⚠️ Kein Token gefunden")
            throw AuthError.invalidToken  // ✅ Wirft Fehler statt nil
        }
        
        self.sessionToken = token
        
        // ✅ User mit Token laden
        // ✅ Swift 6 FIX:
            let user = try await authServiceProtocol.fetchCurrentUser()
            guard let user = user else {
                print("⚠️ Kein User für Token gefunden")
                throw AuthError.userNotFound
            }
        
        self.currentUser = user
        self.isAuthenticated = true
        print("✅ User geladen: \(user.email)")
    }
    
  //real login für später
 /*   func fetchCurrentUser() async throws -> User? {
        return try await authServiceProtocol.fetchCurrentUser()
    }
  
  */
    // ✅ CONFIRM (mit Validation + Sleep)
    func confirmPasswordReset(email: String, resetCode: String, newPassword: String) async throws {
        
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        guard ValidationHelper.isValidPassword(newPassword) else {
            throw AuthError.passwordTooShort
        }
        try await authServiceProtocol.confirmPasswordReset(email: email, resetCode: resetCode, newPassword: newPassword)
        print("✅ Passwort geändert für: \(email)")
    }
    // 📧 PASSWORD RESET (mit Sleep + Print)
     func sendPasswordResetEmail(email: String) async throws -> String {
         try await Task.sleep(nanoseconds: 1_000_000_000)
         let code = try await authServiceProtocol.sendPasswordResetEmail(email: email)
         print("📧 Reset Code für \(email): \(code)")
         return code
     }
    // ✅ SIGN UP mit Token
      func signUp(
          email: String,
          password: String,
          firstName: String,
          lastName: String,
          isTherapist: Bool,
          praxisId: Int?
      ) async throws {
          isLoading = true
          defer { isLoading = false }
          
          guard ValidationHelper.isValidEmail(email) else {
              throw AuthError.invalidEmail
          }
          guard ValidationHelper.isValidPassword(password) else {
              throw AuthError.passwordTooShort
          }
          
          try await Task.sleep(nanoseconds: 1_500_000_000)
          
          // ✅ User UND Token erhalten
          let (newUser, token) = try await authServiceProtocol.signUp(
              email: email,
              password: password,
              firstName: firstName,
              lastName: lastName,
              role: isTherapist ? .therapist : .patient,
              praxisId: praxisId 
          )
          
          // ✅ Beide speichern
          self.currentUser = newUser
          self.sessionToken = token
          self.isAuthenticated = true
          
          // ✅ Token in Keychain speichern (für App-Neustart)
          KeychainHelper.save(token, forKey: "sessionToken")
          
          print("✅ User registriert: \(newUser.email)")
          print("🔑 Token: \(token)")
      }
}

