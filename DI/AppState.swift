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
    @Published var currentUser: User?
    @Published var isLoading = true
    let modelContext: ModelContext
    
    private let authService: AuthServiceProtocol
    
    init(modelContext: ModelContext, authService: AuthServiceProtocol) {
           self.modelContext = modelContext
           self.authService = authService
           Task { await loadUser() }
       }
       
       private func loadUser() async {
           defer { isLoading = false }
           currentUser = try? await authService.fetchCurrentUser()
       }
   }
