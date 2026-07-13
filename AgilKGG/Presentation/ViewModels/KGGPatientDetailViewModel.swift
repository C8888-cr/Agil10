//
//  KGGPatientDetailViewModel.swift
//  AgilKGG
//
//  Patient-Detail: Therapie-Info, Übungen (inkl. Thumbnail-Lookup zur Library),
//  Warmup, QR-Code generieren. History-Einträge zentral (Single Source of Truth).
//

import Foundation
import SwiftData
import CryptoKit
import Combine
import AgilCore

@MainActor
final class KGGPatientDetailViewModel: ObservableObject {
    @Published var patient: KGGPatient
    @Published var qrPayload: QRPayload?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let modelContext: ModelContext
    private let qrCoder = QRCoder()
    private lazy var libraryRepository = KGGLibraryRepository(modelContext: modelContext)

    init(patient: KGGPatient, modelContext: ModelContext) {
        self.patient = patient
        self.modelContext = modelContext
    }

    // MARK: - Abgeleitete Daten

    /// Nur aktive Übungen (deaktivierte bleiben in der DB + History erhalten).
    var activeExercises: [KGGExercise] {
        patient.exercises.filter { $0.isActive }
    }

    /// Thumbnail der verknüpften Library-Übung (Lookup über videoId).
    func libraryThumbnail(for exercise: KGGExercise) -> Data? {
        (try? libraryRepository.fetchExercise(id: exercise.videoId))?.thumbnailData
    }

    // MARK: - History (zentral, Single Source of Truth)

    /// Schreibt einen History-Eintrag. Wird von allen Aktionen genutzt.
    private func logHistory(
        exerciseId: UUID,
        exerciseName: String,
        videoId: UUID,
        action: KGGExerciseHistory.HistoryAction,
        changes: String,
        notes: String? = nil
    ) {
        let entry = KGGExerciseHistory(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            videoId: videoId,
            patientId: patient.id,
            changedBy: "Therapeut",
            action: action,
            changes: changes,
            notes: notes
        )
        modelContext.insert(entry)
    }

    // MARK: - Generate QR

    func generateQRCode() throws -> QRPayload {
        // Übungen zu ExerciseAssignment konvertieren
        let assignments = patient.exercises.filter { $0.isActive }.map { exercise in
            ExerciseAssignment(
                exerciseId: exercise.videoId,
                videoTitle: exercise.videoTitle,
                reps: exercise.reps,
                sets: exercise.sets,
                weight: exercise.weight,
                pauseBetweenSets: exercise.pauseBetweenSets,
                tempo: exercise.tempo,
                videoKey: Data(),           // Placeholder – später aus Keychain
                encryptedVideoBase64: ""    // TODO: echtes verschlüsseltes Video als Base64
            )
        }
        guard !assignments.isEmpty else {
            throw QRError.noExercises
        }

        let payload = QRPayload(
            version: 1,
            issuedAt: Date(),
            assignments: assignments
        )

        self.qrPayload = payload
        return payload
    }

    func encodeQRContent() throws -> String {
        guard let payload = qrPayload else {
            throw QRError.noPayload
        }
        return try qrCoder.encode(payload)
    }

    // MARK: - Exercise Management

    func addExercise(
        videoId: UUID,
        videoTitle: String,
        sparte: String,
        muskelgruppe: String,
        equipment: String,
        reps: Int = 10,
        sets: Int = 3,
        weight: Double = 0.0,
        pauseBetweenSets: Int = 60,
        tempo: String = "2-0-2"
    ) throws {
        let exercise = KGGExercise(
            videoId: videoId,
            videoTitle: videoTitle,
            sparte: sparte,
            muskelgruppe: muskelgruppe,
            equipment: equipment,
            patientId: patient.id,
            reps: reps,
            sets: sets,
            weight: weight,
            pauseBetweenSets: pauseBetweenSets,
            tempo: tempo
        )

        patient.addExercise(exercise)
        logHistory(
            exerciseId: exercise.id,
            exerciseName: videoTitle,
            videoId: videoId,
            action: .created,
            changes: "Übung hinzugefügt: \(videoTitle) (\(reps)x\(sets) @ \(Int(weight))kg)"
        )
        try modelContext.save()
        objectWillChange.send()
    }

    /// Deaktiviert die Übung (Patient sieht sie nicht mehr, KGG behält sie inkl. History).
    func deactivateExercise(_ exercise: KGGExercise, reason: String? = nil) throws {
        exercise.deactivate(reason: reason)
        logHistory(
            exerciseId: exercise.id,
            exerciseName: exercise.videoTitle,
            videoId: exercise.videoId,
            action: .deleted,
            changes: "Übung gelöscht: \(exercise.videoTitle)",
            notes: reason
        )
        try modelContext.save()
        objectWillChange.send()
    }

    /// Reaktiviert eine deaktivierte Übung.
    func reactivateExercise(_ exercise: KGGExercise) throws {
        exercise.reactivate()
        logHistory(
            exerciseId: exercise.id,
            exerciseName: exercise.videoTitle,
            videoId: exercise.videoId,
            action: .resumed,
            changes: "Übung reaktiviert: \(exercise.videoTitle)"
        )
        try modelContext.save()
        objectWillChange.send()
    }

    // MARK: - Warmup Management

    func addWarmup(
        type: String,
        duration: Int,
        intensity: String,
        notes: String? = nil
    ) throws {
        let warmup = KGGWarmup(
            patientId: patient.id,
            type: type,
            duration: duration,
            intensity: intensity,
            notes: notes,
            order: patient.warmupTemplate.count
        )

        patient.addWarmup(warmup)
        try modelContext.save()
        objectWillChange.send()
    }

    func removeWarmup(_ warmupId: UUID) throws {
        patient.warmupTemplate.removeAll { $0.id == warmupId }
        patient.lastModified = Date()
        try modelContext.save()
        objectWillChange.send()
    }

    // MARK: - Update Therapist Info

    func updateTherapistInfo(
        diagnosis: String,
        movementLimitation: String,
        restrictions: String,
        notes: String
    ) throws {
        patient.diagnosis = diagnosis
        patient.movementLimitation = movementLimitation
        patient.restrictions = restrictions
        patient.therapeutistNotes = notes
        patient.lastModified = Date()

        try modelContext.save()
    }

    // MARK: - Errors

    enum QRError: LocalizedError {
        case noExercises
        case noPayload

        var errorDescription: String? {
            switch self {
            case .noExercises: return "Patient hat keine Übungen zugewiesen"
            case .noPayload: return "QR-Payload konnte nicht generiert werden"
            }
        }
    }
}
