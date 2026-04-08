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
    private let session: SessionManager
    
    @Published var currentUserInContext: User?  // ✅ Published, damit View reagiert
    
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext, session: SessionManager) {
        self.modelContext = modelContext
        self.session = session
        
        print("🔧 ProfileViewModel.init()")
        
        // ✅ Initial User laden
        loadCurrentUser()
        
        // ✅ Bei User-Änderung neu laden
        session.$currentUser
            .sink { [weak self] _ in
                self?.loadCurrentUser()
            }
            .store(in: &cancellables)
    }
    
    private func loadCurrentUser() {
        guard let userId = session.currentUser?.id else {
            print("⚠️ ProfileVM: Kein User eingeloggt")
            currentUserInContext = nil
            return
        }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == userId
            }
        )
        
        currentUserInContext = try? modelContext.fetch(descriptor).first
        
        if let user = currentUserInContext {
            print("✅ ProfileVM: User geladen - \(user.email)")
        } else {
            print("⚠️ ProfileVM: User nicht in Context gefunden")
        }
    }
    
    // ✅ Nach Edit neu laden
    func refreshUser() {
        loadCurrentUser()
    }
}
