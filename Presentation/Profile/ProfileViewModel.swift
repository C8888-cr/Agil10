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
    
    private let userRepository: UserRepository
    private let session: SessionManager
    
    @Published var currentUserInContext: User?
    
    var modelContext: ModelContext { userRepository.modelContext }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(userRepository: UserRepository, session: SessionManager) {
        self.userRepository = userRepository
        self.session = session
        
        print("🔧 ProfileViewModel.init()")
        loadCurrentUser()
        
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
        currentUserInContext = userRepository.fetchUser(by: userId)
        
        if let user = currentUserInContext {
            print("✅ ProfileVM: User geladen - \(user.email)")
        } else {
            print("⚠️ ProfileVM: User nicht in Context gefunden")
        }
    }
    
    func refreshUser() {
        loadCurrentUser()
    }
}
