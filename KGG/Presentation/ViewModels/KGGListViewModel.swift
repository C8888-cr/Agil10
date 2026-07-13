//
//  KGGListViewModel.swift
//  Agil
//
//  ViewModel für KGG-Übungsliste.
//  Verwaltet: QR-Scanning, Base64→Decrypt→Save, Exercise-Updates, Visibility-Timer.
//

import Foundation
import Combine
import AgilCore
import CryptoKit

@MainActor
public final class KGGListViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published public private(set) var visibleExercises: [KGGScannedExercise] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: String?
    @Published public private(set) var timeRemainingSeconds: Int = 0
    
    @Published public var visibilityState: KGGExerciseVisibilityManager.VisibilityState = .noKGG {
        didSet { updateDisplay() }
    }
    
    // MARK: - Dependencies
    
    private let repository: KGGExerciseRepository
    private let decoderService: KGGQRDecoderService
    private let cryptoService = CryptoService()
    public let visibilityManager: KGGExerciseVisibilityManager
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(
        repository: KGGExerciseRepository,
        decoderService: KGGQRDecoderService = KGGQRDecoderService(),
        visibilityManager: KGGExerciseVisibilityManager? = nil
    ) {
        self.repository = repository
        self.decoderService = decoderService
        self.visibilityManager = visibilityManager ?? KGGExerciseVisibilityManager()
        
        bindVisibilityManager()
        loadExercises()
    }
    
    // MARK: - Public API
    
    /// Scannt QR-String, dekodiert & verarbeitet Videos aus Base64
    /// - Neue Übungen werden hinzugefügt
    /// - Geänderte Übungen werden aktualisiert
    /// - Gelöschte Übungen werden gelöscht
    public func handleQRCodeScanned(_ qrString: String) {
        Task {
            do {
                isLoading = true
                error = nil
                
                // 1. Dekodiere QR-String zu QRPayload
                let payload = try decoderService.decodeQRString(qrString)
                
                // 2. Validiere Frische (max 24h alt)
                guard decoderService.isPayloadFresh(payload) else {
                    error = "QR-Code zu alt (>24h). Bitte neuen QR scannen."
                    isLoading = false
                    return
                }
                
                // 3. Lade bestehende Übungen
                let existingExercises = try await repository.fetchAll()
                let newAssignments = payload.assignments
                
                // 4. Smart Update + Base64→Decrypt→Save Videos
                try await performSmartUpdateWithVideos(
                    existing: existingExercises,
                    new: newAssignments,
                    issuedAt: payload.issuedAt
                )
                
                // 5. Starte Visibility-Timer
                visibilityManager.startSession()
                
                // 6. Lade aktualisierte Liste
                await loadExercisesAsync()
                isLoading = false
                
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    /// Lädt aktuelle (sichtbare) Übungen
    public func loadExercises() {
        Task {
            await loadExercisesAsync()
        }
    }
    
    /// Markiert Übung als completed
    public func completeExercise(_ exerciseId: UUID) {
        Task {
            do {
                try await repository.markCompleted(exerciseId)
                await loadExercisesAsync()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    /// Löscht abgelaufene Übungen (Cleanup)
    public func cleanupExpired() {
        Task {
            do {
                try await repository.deleteExpired()
                await loadExercisesAsync()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    /// Löscht alle KGG-Übungen (z.B. Account-Löschung)
    public func deleteAll() {
        Task {
            do {
                try await repository.deleteAll()
                await loadExercisesAsync()
                visibilityManager.reset()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    /// Cleard Fehler-Message
    public func clearError() {
        error = nil
    }
    
    /// Prüft eine ggf. bestehende Sichtbarkeits-Session (z.B. beim App-Start).
    public func checkExistingVisibilitySession() {
        visibilityManager.checkExistingSession()
    }
    
    // MARK: - Private: Smart Update + Video Processing
    
    /// Intelligente Update-Logik + Base64→Decrypt→Save:
    /// - Dekodiert Base64 Videos aus QRPayload
    /// - Entschlüsselt mit videoKey (AES-GCM)
    /// - Speichert lokal verschlüsselt
    /// - Erkannt neue/geänderte/gelöschte Übungen
    private func performSmartUpdateWithVideos(
        existing: [KGGScannedExercise],
        new: [ExerciseAssignment],
        issuedAt: Date
    ) async throws {
        
        let newIds = Set(new.map { $0.exerciseId })
        let existingIds = Set(existing.map { $0.exerciseId })
        
        // MARK: Neue Übungen hinzufügen
        for assignment in new {
            if !existingIds.contains(assignment.exerciseId) {
                // Base64 dekodieren + entschlüsseln + speichern
                let videoFileName = try await processAndSaveVideo(
                    exerciseId: assignment.exerciseId,
                    encryptedBase64: assignment.encryptedVideoBase64,
                    videoKey: assignment.videoKey
                )
                
                let exercise = KGGScannedExercise(
                    exerciseId: assignment.exerciseId,
                    exerciseTitle: assignment.videoTitle,
                    videoFileName: videoFileName,
                    isVideoDownloaded: true,  // Gerade gespeichert
                    reps: assignment.reps,
                    sets: assignment.sets,
                    weightKg: assignment.weight,
                    concentricSec: extractConcentricSeconds(from: assignment.tempo),
                    holdSec: extractHoldSeconds(from: assignment.tempo),
                    eccentricSec: extractEccentricSeconds(from: assignment.tempo),
                    restBetweenSetsSec: assignment.pauseBetweenSets,
                    scannedAt: issuedAt,
                    expiresAt: issuedAt.addingTimeInterval(
                        TimeInterval(KGGConfiguration.exerciseVisibilityDurationSeconds)
                    )
                )
                try await repository.save(exercise)
            }
        }
        
        // MARK: Geänderte Übungen aktualisieren
        for assignment in new {
            if let existing = existing.first(where: { $0.exerciseId == assignment.exerciseId }) {
                
                // Tempo-Werte einmal parsen, für Vergleich UND Speichern wiederverwenden
                let newConcentric = extractConcentricSeconds(from: assignment.tempo)
                let newHold = extractHoldSeconds(from: assignment.tempo)
                let newEccentric = extractEccentricSeconds(from: assignment.tempo)
                
                // Prüfe ob Änderungen vorliegen
                // (KGGScannedExercise speichert Tempo als Sekunden-Werte, nicht als
                // "2-0-2"-String — deshalb hier komponentenweise vergleichen)
                let hasChanges =
                    existing.exerciseTitle != assignment.videoTitle ||
                    existing.reps != assignment.reps ||
                    existing.sets != assignment.sets ||
                    existing.weightKg != assignment.weight ||
                    existing.restBetweenSetsSec != assignment.pauseBetweenSets ||
                    existing.concentricSec != newConcentric ||
                    existing.holdSec != newHold ||
                    existing.eccentricSec != newEccentric
                
                if hasChanges {
                    // Video erneut dekodieren + speichern (überschreibt alte)
                    let videoFileName = try await processAndSaveVideo(
                        exerciseId: assignment.exerciseId,
                        encryptedBase64: assignment.encryptedVideoBase64,
                        videoKey: assignment.videoKey
                    )
                    
                    let updated = KGGScannedExercise(
                        id: existing.id,
                        exerciseId: existing.exerciseId,
                        exerciseTitle: assignment.videoTitle,
                        videoFileName: videoFileName,
                        isVideoDownloaded: true,
                        reps: assignment.reps,
                        sets: assignment.sets,
                        weightKg: assignment.weight,
                        concentricSec: newConcentric,
                        holdSec: newHold,
                        eccentricSec: newEccentric,
                        restBetweenSetsSec: assignment.pauseBetweenSets,
                        scannedAt: existing.scannedAt,
                        expiresAt: issuedAt.addingTimeInterval(
                            TimeInterval(KGGConfiguration.exerciseVisibilityDurationSeconds)
                        ),
                        isCompleted: false, // Reset completion
                        completedAt: nil
                    )
                    try await repository.save(updated)
                }
            }
        }
        
        // MARK: Gelöschte Übungen entfernen
        for exerciseId in existingIds.subtracting(newIds) {
            try await repository.delete(exerciseId)
        }
    }
    
    /// Konvertiert Base64 → Data → Decrypt → Speichern
    private func processAndSaveVideo(
        exerciseId: UUID,
        encryptedBase64: String,
        videoKey: Data
    ) async throws -> String {
        
        // 1. Base64 dekodieren
        guard let encryptedData = Data(base64Encoded: encryptedBase64) else {
            throw NSError(domain: "KGGListViewModel", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Base64 dekodierung fehlgeschlagen"])
        }
        
        // 2. Mit videoKey entschlüsseln (AES-GCM)
        let symmetricKey = SymmetricKey(data: videoKey)
        let decryptedData = try cryptoService.decrypt(encryptedData, using: symmetricKey)
        
        // 3. Lokal speichern (verschlüsselt als .agkv)
        let fileName = "\(exerciseId.uuidString).agkv"
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "KGGListViewModel", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "Dokumentverzeichnis nicht gefunden"])
        }
        
        let videoDir = docsURL.appendingPathComponent("KGG/Videos", isDirectory: true)
        try FileManager.default.createDirectory(at: videoDir, withIntermediateDirectories: true)
        
        let filePath = videoDir.appendingPathComponent(fileName)
        try decryptedData.write(to: filePath)
        
        return fileName
    }
    
    // MARK: - Private: Tempo-Parser
    
    /// Extrahiert concentric Sekunden aus "2-0-2" Format
    private func extractConcentricSeconds(from tempoString: String) -> Int {
        let parts = tempoString.split(separator: "-").map { String($0) }
        return Int(parts.first ?? "2") ?? 2
    }
    
    /// Extrahiert hold Sekunden aus "2-0-2" Format
    private func extractHoldSeconds(from tempoString: String) -> Int {
        let parts = tempoString.split(separator: "-").map { String($0) }
        return Int(parts.indices.contains(1) ? parts[1] : "0") ?? 0
    }
    
    /// Extrahiert eccentric Sekunden aus "2-0-2" Format
    private func extractEccentricSeconds(from tempoString: String) -> Int {
        let parts = tempoString.split(separator: "-").map { String($0) }
        return Int(parts.last ?? "2") ?? 2
    }
    
    // MARK: - Private: Loading
    
    private func loadExercisesAsync() async {
        do {
            let exercises = try await repository.fetchVisibleExercises()
            await MainActor.run {
                self.visibleExercises = exercises
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    // MARK: - Private: Visibility Manager Binding
    
    private func bindVisibilityManager() {
        visibilityManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.visibilityState = state
            }
            .store(in: &cancellables)
        
        visibilityManager.$timeRemainingSeconds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] seconds in
                self?.timeRemainingSeconds = seconds
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private: Display Update
    
    private func updateDisplay() {
        switch visibilityState {
        case .noKGG:
            visibleExercises = []
        case .visible:
            Task {
                await loadExercisesAsync()
            }
        case .completed:
            // Sichtbar bleiben, aber nicht interaktiv
            break
        }
    }
}
