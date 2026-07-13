// MARK: - ViewModels/QRGeneratorViewModel.swift

import Foundation
import Combine
import AgilCore

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
            ExerciseAssignment(
                exerciseId: UUID(),
                videoTitle: "Bizeps-Curls",
                reps: 10,
                sets: 3,
                weight: 20,
                pauseBetweenSets: 60,
                tempo: "2-0-2",
                videoKey: Data(),
                encryptedVideoBase64: ""
            ),
            ExerciseAssignment(
                exerciseId: UUID(),
                videoTitle: "Kniebeugen",
                reps: 15,
                sets: 3,
                weight: 5,
                pauseBetweenSets: 45,
                tempo: "2-0-2",
                videoKey: Data(),
                encryptedVideoBase64: ""
            ),
        ]
    }
}
