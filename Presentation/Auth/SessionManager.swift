//
//  SessionManager.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import Combine
import FirebaseAuth

// SessionManager.swift
@MainActor
final class SessionManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var isSigningIn = false  // ← NEU

    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        self.isAuthenticated = KeychainHelper.load(forKey: "sessionToken") != nil

        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser {
                    self?.isSigningIn = true  // ← Login läuft
                    self?.isAuthenticated = true
                    if self?.currentUser == nil {
                        self?.currentUser = self?.userRepository.findOrCreate(
                            firebaseUID: firebaseUser.uid,
                            email: firebaseUser.email ?? ""
                        )
                    }
                    // Token speichern
                    if let token = try? await firebaseUser.getIDToken() {
                        KeychainHelper.save(token, forKey: "sessionToken")
                    }
                    self?.isSigningIn = false
                } else {
                    // Nur ausloggen wenn wir nicht gerade einloggen
                    guard self?.isSigningIn == false else {
                        print("⚠️ Temporäres nil während Login – ignoriert")
                        return
                    }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    if Auth.auth().currentUser == nil && self?.isSigningIn == false {
                        self?.isAuthenticated = false
                        self?.currentUser = nil
                        KeychainHelper.delete(forKey: "sessionToken")
                    }
                }
            }
        }
    }

    func saveSession(token: String) {
        KeychainHelper.save(token, forKey: "sessionToken")
    }

    func clearSession() {
        KeychainHelper.delete(forKey: "sessionToken")
        currentUser = nil
        isAuthenticated = false
    }
}
