//
//  AppState.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//


// MARK: - AppState.swift
import SwiftUI
import SwiftData
@MainActor
class AppState: ObservableObject {
    @Published var currentUser: User
    @Published var isLoading = true
    @Published var isAuthenticated = false
    
    
    let modelContext: ModelContext
    
    private let authService: AuthServiceProtocol
    
    init(modelContext: ModelContext, authService: AuthServiceProtocol) {
           self.modelContext = modelContext
           self.authService = authService
           self.currentUser = MockAuthService.mockPatient
           Task { await loadUser() }
       }
    
    
    private func loadUser() async {
           defer { isLoading = false }

           // Für dein Setup: es gibt erstmal keinen „persistierten“ User → nicht eingeloggt
           isAuthenticated = false
       }

       func setLoggedIn(user: User) {
           currentUser = user
           isAuthenticated = true
       }

       func logout() {
           isAuthenticated = false
           // optional: currentUser auf Mock zurücksetzen
       }
   }
