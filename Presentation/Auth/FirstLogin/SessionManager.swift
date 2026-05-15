import Combine
import FirebaseAuth

@MainActor
final class SessionManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var requiresBiometricUnlock: Bool = false
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let userRepository: UserRepository
    private let unlockUseCase: UnlockAppUseCase
    private let preferences: BiometricPreferences
    
    // NEU: Lock-Timing
    private var backgroundedAt: Date?
    private let lockTimeout: TimeInterval = 30 

    init(
        userRepository: UserRepository,
        unlockUseCase: UnlockAppUseCase,
        preferences: BiometricPreferences
    ) {
        self.userRepository = userRepository
        self.unlockUseCase = unlockUseCase
        self.preferences = preferences
        
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                guard let self else { return }
                guard !self.isAuthenticated else { return }
                
                if let firebaseUser {
                    self.currentUser = self.userRepository.findOrCreate(
                        firebaseUID: firebaseUser.uid,
                        email: firebaseUser.email ?? ""
                    )
                    self.isAuthenticated = true
                    
                    // App-Kaltstart mit aktiver Biometrie → immer sperren
                    if self.preferences.isBiometricLoginEnabled {
                        self.requiresBiometricUnlock = true
                    }
                    
                    if let token = try? await firebaseUser.getIDToken() {
                        KeychainHelper.save(token, forKey: "sessionToken")
                    }
                } else {
                    self.clearSession()
                }
            }
        }
    }

    func setAuthenticatedUser(_ authUser: AuthUser) {
        self.currentUser = userRepository.findOrCreate(
            firebaseUID: authUser.uid,
            email: authUser.email,
            firstName: authUser.firstName,
            lastName: authUser.lastName
        )
        self.isAuthenticated = true
        self.requiresBiometricUnlock = false
        self.backgroundedAt = nil
    }

    func clearSession() {
        KeychainHelper.delete(forKey: "sessionToken")
        currentUser = nil
        isAuthenticated = false
        requiresBiometricUnlock = false
        backgroundedAt = nil
    }
    
    // MARK: - Biometrie Lock/Unlock
    
    /// Wird aufgerufen wenn App in Background geht — merkt sich nur den Zeitpunkt
    func didEnterBackground() {
        guard isAuthenticated else { return }
        guard preferences.isBiometricLoginEnabled else { return }
        backgroundedAt = Date()
    }
    
    /// Wird aufgerufen wenn App in Foreground kommt — prüft ob Timeout abgelaufen ist
    func didEnterForeground() {
        guard isAuthenticated else { return }
        guard preferences.isBiometricLoginEnabled else { return }
        guard let backgroundedAt else { return }
        
        let elapsed = Date().timeIntervalSince(backgroundedAt)
        if elapsed >= lockTimeout {
            requiresBiometricUnlock = true
        }
        
        // Zeitstempel zurücksetzen — egal ob gelockt oder nicht
        self.backgroundedAt = nil
    }
    
    func unlockSession() async throws {
        print("🔐 SessionManager.unlockSession() — ruft UseCase")
        try await unlockUseCase.execute()
        print("✅ UseCase erfolgreich")
        requiresBiometricUnlock = false
    }
}
