import SwiftUI
import SwiftData
import FirebaseAuth

@MainActor
class AuthService: ObservableObject {
    
    // MARK: - Published
    @Published var currentUser: User? = nil
    @Published var isLoading = false
    @Published var sessionToken: String? = nil
    @Published var isAuthenticated: Bool = false
    
    // MARK: - Private
    private weak var modelContext: ModelContext?
    private let authServiceProtocol: AuthServiceProtocol
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // MARK: - Init
    init(authServiceProtocol: AuthServiceProtocol, modelContext: ModelContext? = nil) {
        self.authServiceProtocol = authServiceProtocol
        self.modelContext = modelContext
        self.sessionToken = KeychainHelper.load(forKey: "sessionToken")
        self.isAuthenticated = false
        
        // Firebase Auth State beobachten
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if firebaseUser != nil {
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
    
    // MARK: - Login
    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let (user, token) = try await authServiceProtocol.login(
            email: email,
            password: password
        )
        
        self.currentUser = findOrCreateUser(user)
        self.sessionToken = token
        self.isAuthenticated = true
        KeychainHelper.save(token, forKey: "sessionToken")
        
        print("✅ AuthService Login: \(user.email)")
    }
    
    // MARK: - Logout
    func logout() async {
        await authServiceProtocol.logout()
        currentUser = nil
        sessionToken = nil
        isAuthenticated = false
        KeychainHelper.delete(forKey: "sessionToken")
        print("👋 AuthService: User geloggt aus")
    }
    
    // MARK: - Session wiederherstellen
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
    
    // MARK: - Fetch Current User
    func fetchCurrentUser() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let token = KeychainHelper.load(forKey: "sessionToken") else {
            print("⚠️ Kein Token gefunden")
            throw AuthError.invalidToken
        }
        
        self.sessionToken = token
        
        guard let user = try await authServiceProtocol.fetchCurrentUser() else {
            print("⚠️ Kein User für Token gefunden")
            throw AuthError.userNotFound
        }
        
        self.currentUser = findOrCreateUser(user)
        self.isAuthenticated = true
        print("✅ User geladen: \(user.email)")
    }
    
    // MARK: - Sign Up
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
        
        guard ValidationHelper.isValidEmail(email) else { throw AuthError.invalidEmail }
        guard ValidationHelper.isValidPassword(password) else { throw AuthError.passwordTooShort }
        
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
    }
    
    // MARK: - Password Reset
    func sendPasswordResetEmail(email: String) async throws -> String {
        let code = try await authServiceProtocol.sendPasswordResetEmail(email: email)
        print("📧 Reset Code für \(email): \(code)")
        return code
    }
    
    func confirmPasswordReset(email: String, resetCode: String, newPassword: String) async throws {
        guard ValidationHelper.isValidPassword(newPassword) else { throw AuthError.passwordTooShort }
        try await authServiceProtocol.confirmPasswordReset(
            email: email,
            resetCode: resetCode,
            newPassword: newPassword
        )
        print("✅ Passwort geändert für: \(email)")
    }
    
    // MARK: - User aktualisieren
    func updateUser(firstName: String, lastName: String) throws {
        guard let user = currentUser, let context = modelContext else { return }
        user.firstName = firstName
        user.lastName = lastName
        try context.save()
        objectWillChange.send()
        print("✅ User gespeichert: \(user.fullName)")
    }
    
    // MARK: - findOrCreateUser (privat!)
    private func findOrCreateUser(_ user: User) -> User {
        guard let context = modelContext else { return user }
        
        // 1. Nach firebaseUID suchen
        let firebaseUID = user.firebaseUID
        if !firebaseUID.isEmpty {
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.firebaseUID == firebaseUID }
            )
            if let existing = (try? context.fetch(descriptor))?.first {
                print("✅ User per firebaseUID gefunden: \(existing.email)")
                return existing
            }
        }
        
        // 2. Fallback: nach Email suchen
        let email = user.email
        let emailDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.email == email }
        )
        if let existing = (try? context.fetch(emailDescriptor))?.first {
            // firebaseUID nachtragen falls leer
            if existing.firebaseUID.isEmpty && !firebaseUID.isEmpty {
                existing.firebaseUID = firebaseUID
                try? context.save()
            }
            print("✅ User per Email gefunden: \(existing.email)")
            return existing
        }
        
        // 3. Neuer User
        context.insert(user)
        try? context.save()
        print("🆕 Neuer User angelegt: \(user.email)")
        return user
    }
}
