import Combine
import Foundation

@MainActor
final class SessionManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var requiresBiometricUnlock: Bool = false
    
    private let authService: AuthServiceProtocol
    private let userRepository: UserRepository
    private let unlockUseCase: UnlockAppUseCase
    private let preferences: BiometricPreferences

    // NEU: Lock-Timing
    private var backgroundedAt: Date?
    private let lockTimeout: TimeInterval = 60

    init(
           authService: AuthServiceProtocol,
           userRepository: UserRepository,
           unlockUseCase: UnlockAppUseCase,
           preferences: BiometricPreferences
       ) {
           self.authService = authService
           self.userRepository = userRepository
           self.unlockUseCase = unlockUseCase
           self.preferences = preferences

           restoreSession()
       }

       /// Stellt eine bestehende lokale Session beim App-Start wieder her.
       private func restoreSession() {
           guard let authUser = authService.currentUser else { return }
           currentUser = userRepository.findOrCreate(
               firebaseUID: authUser.uid,
               email: authUser.email,
               firstName: authUser.firstName,
               lastName: authUser.lastName
           )
           isAuthenticated = true

           // Kaltstart mit aktiver Biometrie → sperren
           if preferences.isBiometricLoginEnabled {
               requiresBiometricUnlock = true
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
