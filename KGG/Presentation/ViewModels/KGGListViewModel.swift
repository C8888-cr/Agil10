//
//  KGGListViewModel.swift
//  Agil
//
//  ViewModel für KGG-Übungsliste + Warmup-Anzeige.
//  Verwaltet: QR-Scanning, Exercise-/Warmup-Updates, Visibility-Timer.
//  Kein Video mehr im QR-Pfad — Video läuft separat (AirDrop/Mediathek, Roadmap).
//

import Foundation
import Combine
import AgilCore

@MainActor
public final class KGGListViewModel: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var visibleExercises: [KGGScannedExercise] = []
    @Published public private(set) var visibleWarmups: [KGGScannedWarmup] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: String?
    @Published public private(set) var timeRemainingSeconds: Int = 0

    @Published public var visibilityState: KGGExerciseVisibilityManager.VisibilityState = .noKGG {
        didSet { updateDisplay() }
    }

    @Published public private(set) var showAssignmentConfirmation: Bool = false
    @Published public private(set) var assignmentConfirmationMessage: String = ""

    private var confirmationDismissTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let repository: KGGExerciseRepository
    private let warmupRepository: KGGWarmupRepository
    private let decoderService: KGGQRDecoderService
    public let visibilityManager: KGGExerciseVisibilityManager

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(
        repository: KGGExerciseRepository,
        warmupRepository: KGGWarmupRepository,
        decoderService: KGGQRDecoderService = KGGQRDecoderService(),
        visibilityManager: KGGExerciseVisibilityManager? = nil
    ) {
        self.repository = repository
        self.warmupRepository = warmupRepository
        self.decoderService = decoderService
        self.visibilityManager = visibilityManager ?? KGGExerciseVisibilityManager()

        bindVisibilityManager()
        loadExercises()
    }

    // MARK: - Public API

    /// Erkennt zuerst den QR-Typ (Start-Trigger vs. Übungs-Zuweisung) und
    /// verzweigt entsprechend. Bewusst KEIN Try-Catch-Raten zwischen zwei
    /// Formaten — der Start-QR hat ein eigenes, sofort erkennbares Präfix.
    public func handleQRCodeScanned(_ qrString: String) {
        if KGGStartSessionCoder.isStartSessionQR(qrString) {
            handleStartSessionQR(qrString)
        } else {
            handleAssignmentQR(qrString)
        }
    }

    /// Schaltet NUR die 60-Minuten-Sichtbarkeit frei. Rührt keine
    /// Übungsdaten an.
    private func handleStartSessionQR(_ qrString: String) {
        do {
            let token = try KGGStartSessionCoder.decode(qrString)
            guard visibilityManager.consumeStartToken(token) else {
                error = "Dieser QR-Code wurde bereits verwendet. Bitte einen neuen Start-QR scannen lassen."
                return
            }
            error = nil
        } catch {
            self.error = "Start-QR konnte nicht gelesen werden."
        }
    }

    /// Synchronisiert Übungen + Warmup (Name, Gewicht, Stufe, Tempo, Notizen).
    /// Schaltet NICHT die 60-Minuten-Sichtbarkeit frei — das übernimmt
    /// ausschließlich der separate Start-QR.
    private func handleAssignmentQR(_ qrString: String) {
        Task {
            do {
                isLoading = true
                error = nil

                let payload = try decoderService.decodeQRString(qrString)

                guard decoderService.isPayloadFresh(payload) else {
                    error = "QR-Code zu alt (>24h). Bitte neuen QR scannen."
                    isLoading = false
                    return
                }

                let existingExercises = try await repository.fetchAll()

                try await performSmartUpdate(
                    existing: existingExercises,
                    new: payload.assignments,
                    issuedAt: payload.issuedAt
                )

                try await performWarmupReplace(
                    warmups: payload.warmups,
                    issuedAt: payload.issuedAt
                )

                await loadDataAsync()
                showBriefAssignmentConfirmation(count: payload.assignments.count)
                isLoading = false

            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }

    /// Lädt aktuelle (sichtbare) Übungen + Warmups
    public func loadExercises() {
        Task {
            await loadDataAsync()
        }
    }

    private func showBriefAssignmentConfirmation(count: Int) {
        confirmationDismissTask?.cancel()
        assignmentConfirmationMessage = count == 1
            ? "1 Übung aktualisiert"
            : "\(count) Übungen aktualisiert"
        showAssignmentConfirmation = true
        confirmationDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 Sek.
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.showAssignmentConfirmation = false
            }
        }
    }

    /// Markiert Übung als completed
    public func completeExercise(_ exerciseId: UUID) {
        Task {
            do {
                try await repository.markCompleted(exerciseId)
                await loadDataAsync()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    /// Löscht abgelaufene Übungen + Warmups (Cleanup)
    public func cleanupExpired() {
        Task {
            do {
                try await repository.deleteExpired()
                try await warmupRepository.deleteExpired()
                await loadDataAsync()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    /// Löscht alle KGG-Daten (z.B. Account-Löschung)
    public func deleteAll() {
        Task {
            do {
                try await repository.deleteAll()
                try await warmupRepository.deleteAll()
                await loadDataAsync()
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

    // MARK: - Private: Smart Update (Exercises)

    /// Intelligente Update-Logik für Übungen:
    /// - Erkennt neue/geänderte/gelöschte Übungen
    /// - Tempo-String wird über den zentralen Parser (KGGQRDecoderService)
    ///   in Sekunden-Werte zerlegt — kein doppelter Parsing-Code hier.
    private func performSmartUpdate(
        existing: [KGGScannedExercise],
        new: [ExerciseAssignment],
        issuedAt: Date
    ) async throws {

        let newIds = Set(new.map { $0.exerciseId })
        let existingIds = Set(existing.map { $0.exerciseId })

        // Neue Übungen hinzufügen
        for assignment in new where !existingIds.contains(assignment.exerciseId) {
            let tempoParts = decoderService.parseTempo(assignment.tempo)

            let exercise = KGGScannedExercise(
                exerciseId: assignment.exerciseId,
                exerciseTitle: assignment.videoTitle,
                videoFileName: "",
                isVideoDownloaded: false,
                reps: assignment.reps,
                sets: assignment.sets,
                weightKg: assignment.weight,
                concentricSec: tempoParts.concentric,
                holdSec: tempoParts.hold,
                eccentricSec: tempoParts.eccentric,
                restBetweenSetsSec: assignment.pauseBetweenSets,
                level: assignment.level,
                seatLevel: assignment.seatLevel,
                notes: assignment.notes,
                scannedAt: issuedAt,
                expiresAt: issuedAt.addingTimeInterval(
                    TimeInterval(KGGConfiguration.exerciseVisibilityDurationSeconds)
                )
            )
            try await repository.save(exercise)
        }

        // Geänderte Übungen aktualisieren
        for assignment in new {
            guard let existing = existing.first(where: { $0.exerciseId == assignment.exerciseId }) else { continue }

            let tempoParts = decoderService.parseTempo(assignment.tempo)

            let hasChanges =
                existing.exerciseTitle != assignment.videoTitle ||
                existing.reps != assignment.reps ||
                existing.sets != assignment.sets ||
                existing.weightKg != assignment.weight ||
                existing.restBetweenSetsSec != assignment.pauseBetweenSets ||
                existing.concentricSec != tempoParts.concentric ||
                existing.holdSec != tempoParts.hold ||
                existing.eccentricSec != tempoParts.eccentric ||
                existing.level != assignment.level ||
                existing.seatLevel != assignment.seatLevel ||
                existing.notes != assignment.notes

            guard hasChanges else { continue }

            let updated = KGGScannedExercise(
                id: existing.id,
                exerciseId: existing.exerciseId,
                exerciseTitle: assignment.videoTitle,
                videoFileName: existing.videoFileName,
                isVideoDownloaded: existing.isVideoDownloaded,
                reps: assignment.reps,
                sets: assignment.sets,
                weightKg: assignment.weight,
                concentricSec: tempoParts.concentric,
                holdSec: tempoParts.hold,
                eccentricSec: tempoParts.eccentric,
                restBetweenSetsSec: assignment.pauseBetweenSets,
                level: assignment.level,
                seatLevel: assignment.seatLevel,
                notes: assignment.notes,
                scannedAt: existing.scannedAt,
                expiresAt: issuedAt.addingTimeInterval(
                    TimeInterval(KGGConfiguration.exerciseVisibilityDurationSeconds)
                ),
                isCompleted: false, // Reset completion
                completedAt: nil
            )
            try await repository.save(updated)
        }

        // Gelöschte Übungen entfernen
        for exerciseId in existingIds.subtracting(newIds) {
            try await repository.delete(exerciseId)
        }
    }

    // MARK: - Private: Warmup Replace

    /// Warmup hat keine langfristige Identität über mehrere Scans hinweg —
    /// bei jedem Assignment-Scan wird der komplette Satz durch den aktuellen
    /// ersetzt (Snapshot, letzter QR = Single Source of Truth).
    private func performWarmupReplace(warmups: [WarmupAssignment], issuedAt: Date) async throws {
        let expiresAt = issuedAt.addingTimeInterval(
            TimeInterval(KGGConfiguration.exerciseVisibilityDurationSeconds)
        )

        let scanned = warmups.map { assignment in
            KGGScannedWarmup(
                id: assignment.id,
                type: assignment.type,
                duration: assignment.duration,
                level: assignment.level,
                seatLevel: assignment.seatLevel,
                speedKmh: assignment.speedKmh,
                weight: assignment.weight,
                notes: assignment.notes,
                order: assignment.order,
                scannedAt: issuedAt,
                expiresAt: expiresAt
            )
        }

        try await warmupRepository.replaceAll(scanned)
    }

    // MARK: - Private: Loading

    private func loadDataAsync() async {
        do {
            let exercises = try await repository.fetchVisibleExercises()
            let warmups = try await warmupRepository.fetchVisible()
            await MainActor.run {
                self.visibleExercises = exercises
                self.visibleWarmups = warmups
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
            visibleWarmups = []
        case .visible:
            Task {
                await loadDataAsync()
            }
        case .completed:
            break
        }
    }
}
