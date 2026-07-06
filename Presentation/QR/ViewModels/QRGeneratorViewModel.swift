// MARK: - ViewModels/QRGeneratorViewModel.swift

import Foundation
import Combine
import AgilCore//import AgilCore

@MainActor
final class QRGeneratorViewModel: ObservableObject {
    @Published var assignments: [ExerciseAssignment] = []
    @Published var qrCodeString: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let qrCoder = QRCoder()
    private let keyManager = KeyManager()
    
    init() {
        loadMockAssignments()
    }
    
    func generateQR() {
        isLoading = true
        errorMessage = nil
        
        do {
            let payload = QRPayload(assignments: assignments)
            let qrString = try qrCoder.encode(payload)
            self.qrCodeString = qrString
        } catch {
            errorMessage = "QR-Generierung fehlgeschlagen: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func loadMockAssignments() {
        assignments = [
            ExerciseAssignment(exerciseId: UUID(), reps: 10, weight: 20, videoKey: Data()),
            ExerciseAssignment(exerciseId: UUID(), reps: 15, weight: 5, videoKey: Data()),
        ]
    }
}
