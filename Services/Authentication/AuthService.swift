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
        
        let authUser = try await authServiceProtocol.login(email: email, password: password)
        self.currentUser = findOrCreateUser(firebaseUID: authUser.uid, email: authUser.email)
        self.isAuthenticated = true
        print("✅ AuthService Login: \(authUser.email)")
    }
    
    // MARK: - Logout
    // MARK: - Logout
    func logout() async {
        try? authServiceProtocol.signOut()
        currentUser = nil
        sessionToken = nil
        isAuthenticated = false
        KeychainHelper.delete(forKey: "sessionToken")
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
        guard let authUser = authServiceProtocol.currentUser else {
            throw AuthError.userNotFound
        }
        self.currentUser = findOrCreateUser(firebaseUID: authUser.uid, email: authUser.email)
        self.isAuthenticated = true
    }

    
    // MARK: - Sign Up
    func signUp(email: String, password: String, firstName: String,
                lastName: String, role: UserRole, praxisId: UUID?) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard ValidationHelper.isValidEmail(email) else { throw AuthError.invalidEmail }
        guard ValidationHelper.isValidPassword(password) else { throw AuthError.passwordTooShort }
        
        let authUser = try await authServiceProtocol.signUp(
            email: email,
            password: password,
            firstName: firstName,    // ← ergänzt
            lastName: lastName,      // ← ergänzt
            praxisId: praxisId       // ← ergänzt
        )
        self.currentUser = findOrCreateUser(
            firebaseUID: authUser.uid,
            email: authUser.email,
            firstName: firstName,
            lastName: lastName,
            praxisId: praxisId
        )
        self.isAuthenticated = true
    }
    
    // MARK: - Password Reset
    func sendPasswordResetEmail(email: String) async throws {
        try await authServiceProtocol.resetPassword(email: email)
    }
    
    
    func confirmPasswordReset(email: String, resetCode: String, newPassword: String) async throws {
        guard ValidationHelper.isValidPassword(newPassword) else { throw AuthError.passwordTooShort }
        // confirmPasswordReset gibt es nicht mehr im Protokoll
        // Firebase macht das direkt über den Link in der Email
        // Hier nur noch lokale Validierung nötig
        print("✅ Passwort-Reset angefordert für: \(email)")
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
    
    // MARK: - findOrCreateUser
    private func findOrCreateUser(firebaseUID: String, email: String,
                                   firstName: String = "",
                                   lastName: String = "",
                                   praxisId: UUID? = nil) -> User {
        guard let context = modelContext else {
            return User(email: email, passwordHash: "firebase", role: .patient, praxisId: praxisId)
        }
        
        // 1. Nach firebaseUID suchen
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
        let emailDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.email == email }
        )
        if let existing = (try? context.fetch(emailDescriptor))?.first {
            if existing.firebaseUID.isEmpty && !firebaseUID.isEmpty {
                existing.firebaseUID = firebaseUID
                try? context.save()
            }
            print("✅ User per Email gefunden: \(existing.email)")
            return existing
        }
        
        // 3. Neuer User anlegen
        let newUser = User(email: email, passwordHash: "firebase", role: .patient, praxisId: praxisId)
        newUser.firebaseUID = firebaseUID
        newUser.firstName = firstName
        newUser.lastName = lastName
        context.insert(newUser)
        try? context.save()
        print("🆕 Neuer User angelegt: \(email)")
        return newUser
    }
}
