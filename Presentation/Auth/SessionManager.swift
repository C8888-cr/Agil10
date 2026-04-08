import Combine
import FirebaseAuth

@MainActor
final class SessionManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        
        // Nur für App-Start: prüfen ob noch eine Session existiert
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                guard let self else { return }
                
                // Nur reagieren wenn wir noch keine Session haben
                // (Login/SignUp setzen die Session explizit via setAuthenticatedUser)
                guard !self.isAuthenticated else { return }
                
                if let firebaseUser {
                    // App-Start: Firebase kennt noch den User → Session wiederherstellen
                    // Namen sind leer — User muss ggf. Profil vervollständigen
                    self.currentUser = self.userRepository.findOrCreate(
                        firebaseUID: firebaseUser.uid,
                        email: firebaseUser.email ?? ""
                    )
                    self.isAuthenticated = true
                    
                    // Token aktualisieren
                    if let token = try? await firebaseUser.getIDToken() {
                        KeychainHelper.save(token, forKey: "sessionToken")
                    }
                } else {
                    // Kein Firebase-User → ausgeloggt
                    self.clearSession()
                }
            }
        }
    }

    // MARK: - Explizit nach Login/SignUp aufrufen
    func setAuthenticatedUser(_ authUser: AuthUser) {
        self.currentUser = userRepository.findOrCreate(
            firebaseUID: authUser.uid,
            email: authUser.email,
            firstName: authUser.firstName,
            lastName: authUser.lastName
        )
        self.isAuthenticated = true
    }

    func clearSession() {
        KeychainHelper.delete(forKey: "sessionToken")
        currentUser = nil
        isAuthenticated = false
    }
}
