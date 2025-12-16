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
           
           if let fetchedUser = try? await authService.fetchCurrentUser() {
               currentUser = fetchedUser
               isAuthenticated = true  // ← Login-Status!
           } else {
               currentUser = MockAuthService.mockPatient
               isAuthenticated = false  // ← Noch nicht "echt" eingeloggt
           }
       }
   }
