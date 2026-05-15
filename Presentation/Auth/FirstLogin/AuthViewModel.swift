import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading = false

    let session: SessionManager

    private let loginUseCase: LoginUseCase
    private let signUpUseCase: SignUpUseCase
    private let signOutUseCase: SignOutUseCase
    private let resetPasswordUseCase: ResetPasswordUseCase
    private let deleteAccountUseCase: DeleteAccountUseCase
    private let resetUserDataUseCase: ResetUserDataUseCase
    private let loginWithBiometricUseCase: LoginWithBiometricUseCase  // NEU
    private let credentialStorage: BiometricCredentialStorage          // NEU

    init(
        session: SessionManager,
        loginUseCase: LoginUseCase,
        signUpUseCase: SignUpUseCase,
        signOutUseCase: SignOutUseCase,
        resetPasswordUseCase: ResetPasswordUseCase,
        deleteAccountUseCase: DeleteAccountUseCase,
        resetUserDataUseCase: ResetUserDataUseCase,
        loginWithBiometricUseCase: LoginWithBiometricUseCase,   // NEU
        credentialStorage: BiometricCredentialStorage           // NEU
    ) {
        self.session = session
        self.loginUseCase = loginUseCase
        self.signUpUseCase = signUpUseCase
        self.signOutUseCase = signOutUseCase
        self.resetPasswordUseCase = resetPasswordUseCase
        self.deleteAccountUseCase = deleteAccountUseCase
        self.resetUserDataUseCase = resetUserDataUseCase
        self.loginWithBiometricUseCase = loginWithBiometricUseCase    // NEU
        self.credentialStorage = credentialStorage                    // NEU
    }
    
    // NEU: Prüft ob Face-ID-Login möglich ist
    var canUseBiometricLogin: Bool {
        credentialStorage.hasStoredCredentials
    }

    func login(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let authUser = try await loginUseCase.execute(email: email, password: password)
            session.setAuthenticatedUser(authUser)
            
            // NEU: Credentials für Face-ID-Login speichern
            try? credentialStorage.save(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // NEU: Login mit Face ID
    func loginWithBiometric() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let authUser = try await loginWithBiometricUseCase.execute()
            session.setAuthenticatedUser(authUser)
        } catch {
            errorMessage = "Anmeldung mit Face ID fehlgeschlagen"
        }
    }

    func signUp(request: SignUpRequest) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let authUser = try await signUpUseCase.execute(request: request)
            session.setAuthenticatedUser(authUser)
            
            // NEU: Auch nach SignUp Credentials speichern
            try? credentialStorage.save(email: request.email, password: request.password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await signOutUseCase.execute()
            session.clearSession()
            // Keychain NICHT löschen — User soll mit Face ID wieder rein können
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword(email: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await resetPasswordUseCase.execute(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteAccount() async {
        guard let userId = session.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await deleteAccountUseCase.execute(userId: userId)
            
            // NEU: Account gelöscht → Keychain auch leeren
            credentialStorage.clear()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetAllData() async {
        guard let userId = session.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try resetUserDataUseCase.execute(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
