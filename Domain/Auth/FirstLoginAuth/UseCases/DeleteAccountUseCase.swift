//
//  DeleteAccountUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 13.04.26.
//
import Foundation

// DeleteAccountUseCase.swift
@MainActor
struct DeleteAccountUseCase {
  
        let authService: AuthServiceProtocol
        let scheduleRepository: VideoScheduleRepositoryProtocol
        let userRepository: UserRepository
        let session: SessionManager
        let workoutLogRepository: WorkoutLogRepositoryProtocol
    
        func execute(userId: UUID) async throws {
                // 1. Alle Daten löschen
                try scheduleRepository.deleteAllSchedules(for: userId)
                try scheduleRepository.deleteAllTemplates(for: userId)
                try workoutLogRepository.deleteAll(for: userId)
                // 2. User aus SwiftData löschen
        try userRepository.delete(userId: userId)
        // 3. Firebase Account löschen
        try await authService.deleteAccount()
        // 4. Session beenden
        session.clearSession()
    }
}
