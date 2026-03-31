//
//  AuthService.swift
//  Agil10.0
//
//  Created by Christiane Roth on 21.12.25.
//

import SwiftUI
import SwiftData
import FirebaseAuth


@MainActor
class AuthService: ObservableObject {
    
    private weak var modelContext: ModelContext?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    @Published var currentUser: User? = nil
    @Published var isLoading = false
    @Published var sessionToken: String? = nil
    @Published var isAuthenticated: Bool = false
    
    private let authServiceProtocol: AuthServiceProtocol
    
    init(authServiceProtocol: AuthServiceProtocol,
         modelContext: ModelContext? = nil) {
        self.authServiceProtocol = authServiceProtocol
        self.modelContext = modelContext
        self.sessionToken = KeychainHelper.load(forKey: "sessionToken")
        self.isAuthenticated = false
        
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    self?.isAuthenticated = true
                } else {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                    self?.sessionToken = nil
                    KeychainHelper.delete(forKey: "sessionToken")
                }
            }
        }
    }
    
    // MARK: - Helper: User in SwiftData suchen oder anlegen
    private func findOrCreateUser(_ user: User) -> User {
        guard let context = modelContext else { return user }
        let email = user.email
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.email == email }
        )
        if let existingUser = (try? context.fetch(descriptor))?.first {
            return existingUser
        } else {
            context.insert(user)
            try? context.save()
            return user
        }
    }
    
    // 🔐 LOGIN
    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        let (user, token) = try await authServiceProtocol.login(
            email: email,
            password: password
        )
        
        self.currentUser = findOrCreateUser(user)
        self.sessionToken = token
        self.isAuthenticated = true
        KeychainHelper.save(token, forKey: "sessionToken")
        
        print("✅ AuthService Login: \(user.email)")
        print("🔑 Token: \(token)")
    }
    
    // 👋 LOGOUT
    func logout() async {
        await authServiceProtocol.logout()
        currentUser = nil
        sessionToken = nil
        isAuthenticated = false
        KeychainHelper.delete(forKey: "sessionToken")
        print("👋 AuthService: User geloggt aus")
    }
    
    // ✅ FETCH CURRENT USER
    func fetchCurrentUser() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let token = KeychainHelper.load(forKey: "sessionToken") else {
            print("⚠️ Kein Token gefunden")
            throw AuthError.invalidToken
        }
        
        self.sessionToken = token
        
        let user = try await authServiceProtocol.fetchCurrentUser()
        guard let user = user else {
            print("⚠️ Kein User für Token gefunden")
            throw AuthError.userNotFound
        }
        
        self.currentUser = findOrCreateUser(user)
        self.isAuthenticated = true
        print("✅ User geladen: \(user.email)")
    }
    
    // ✅ SIGN UP
    func signUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        role: UserRole,
        praxisId: UUID?
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
        
        let (newUser, token) = try await authServiceProtocol.signUp(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            role: role,
            praxisId: praxisId
        )
        
        self.currentUser = findOrCreateUser(newUser)
        self.sessionToken = token
        self.isAuthenticated = true
        KeychainHelper.save(token, forKey: "sessionToken")
        
        print("✅ User registriert: \(newUser.email)")
        print("🔑 Token: \(token)")
    }
    
    // ✅ CONFIRM PASSWORD RESET
    func confirmPasswordReset(email: String, resetCode: String, newPassword: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        guard ValidationHelper.isValidPassword(newPassword) else {
            throw AuthError.passwordTooShort
        }
        try await authServiceProtocol.confirmPasswordReset(email: email, resetCode: resetCode, newPassword: newPassword)
        print("✅ Passwort geändert für: \(email)")
    }
    
    // 📧 PASSWORD RESET
    func sendPasswordResetEmail(email: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let code = try await authServiceProtocol.sendPasswordResetEmail(email: email)
        print("📧 Reset Code für \(email): \(code)")
        return code
    }
    
    // ✅ USER AKTUALISIEREN
    func updateUser(firstName: String, lastName: String) throws {
        guard let user = currentUser,
              let context = modelContext else { return }
        
        user.firstName = firstName
        user.lastName = lastName
        
        try context.save()
        objectWillChange.send()
        print("✅ User gespeichert: \(user.fullName)")
    }
}

extension AuthService {
    
    func loadSavedSession() async {
        guard KeychainHelper.load(forKey: "sessionToken") != nil else {
            print("⚠️ Kein gespeicherter Token gefunden")
            return
        }
        
        do {
            try await fetchCurrentUser()
            print("✅ Session wiederhergestellt")
        } catch {
            print("❌ Session konnte nicht geladen werden: \(error)")
            await logout()
        }
    }
}
