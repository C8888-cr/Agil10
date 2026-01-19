//
//  ProfileViewModel.swift
//  Agil10.0
//
//  Created by Christiane Roth on 18.01.26.
//

import SwiftUI
import SwiftData
import Combine


@MainActor
class ProfileViewModel: ObservableObject {
    
    let modelContext: ModelContext
    let authService: AuthService  // ✅ Als Property speichern
    
    
     var currentUserInContext: User? {
        guard let userId = authService.currentUser?.id else { return nil }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == userId
            }
        )
        
        return try? modelContext.fetch(descriptor).first
    }
    
    // ✅ AuthService als Parameter übergeben
    init(modelContext: ModelContext, authService: AuthService) {
        self.modelContext = modelContext
        self.authService = authService  // ✅ Speichern!
        
      
        print("👤 AuthService.currentUser: \(authService.currentUser?.email ?? "nil")")
        
        guard let user = authService.currentUser else {
            print("⚠️ No user logged in - warte auf setUser()")
            return
        }
        
        print("✅ User gefunden: \(user.email)")
      
    }
}
