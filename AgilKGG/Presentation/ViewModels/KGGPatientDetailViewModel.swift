//
//  KGGPatientDetailViewModel.swift
//  Agil10.0
//
//  Created by Christiane Roth on 27.06.26.
//


//
//  KGGPatientDetailViewModel.swift
//  AgilKGG
//
//  Patient-Detail: Therapie-Info, Übungen, Warmup, QR-Code generieren
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
    
    init(patient: KGGPatient, modelContext: ModelContext) {
        self.patient = patient
        self.modelContext = modelContext
    }
    
    // MARK: - History (zentral, Single Source of Truth)

        /// Schreibt einen History-Eintrag. Wird von allen Aktionen genutzt.
        private func logHistory(
            exerciseId: UUID,
            action: KGGExerciseHistory.HistoryAction,
            changes: String,
            notes: String? = nil
        ) {
            let entry = KGGExerciseHistory(
                exerciseId: exerciseId,
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
                reps: exercise.reps,
                weight: exercise.weight,
                videoKey: Data()  // Placeholder – später aus Keychain
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
        weight: Double = 0.0
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
            weight: weight
        )
        
        patient.addExercise(exercise)
                logHistory(
                    exerciseId: exercise.id,
                    action: .created,
                    changes: "Übung hinzugefügt: \(videoTitle) (\(reps)x\(sets) @ \(Int(weight))kg)"
                )
                try modelContext.save()
    }
    
    /// Deaktiviert die Übung (Patient sieht sie nicht mehr, KGG behält sie inkl. History).
        func deactivateExercise(_ exercise: KGGExercise, reason: String? = nil) throws {
            exercise.deactivate(reason: reason)
            logHistory(
                exerciseId: exercise.id,
                action: .deleted,
                changes: "Übung deaktiviert",
                notes: reason
            )
            try modelContext.save()
        }

        /// Reaktiviert eine deaktivierte Übung.
        func reactivateExercise(_ exercise: KGGExercise) throws {
            exercise.reactivate()
            logHistory(
                exerciseId: exercise.id,
                action: .resumed,
                changes: "Übung reaktiviert"
            )
            try modelContext.save()
        }
    
    
    func updateExercise(
            _ exercise: KGGExercise,
            reps: Int? = nil,
            sets: Int? = nil,
            weight: Double? = nil,
            pauseBetweenSets: Int? = nil,
            tempo: String? = nil,
            rangeOfMotion: String? = nil,
            note: String? = nil
        ) throws {
            var changes: [String] = []
            if let reps, reps != exercise.reps { changes.append("Reps: \(exercise.reps)→\(reps)") }
            if let sets, sets != exercise.sets { changes.append("Sätze: \(exercise.sets)→\(sets)") }
            if let weight, weight != exercise.weight { changes.append("Gewicht: \(Int(exercise.weight))→\(Int(weight))kg") }
            if let pauseBetweenSets, pauseBetweenSets != exercise.pauseBetweenSets { changes.append("Pause: \(exercise.pauseBetweenSets)→\(pauseBetweenSets)s") }
            if let tempo, tempo != exercise.tempo { changes.append("Tempo: \(exercise.tempo)→\(tempo)") }
            if let rangeOfMotion, rangeOfMotion != exercise.rangeOfMotion { changes.append("ROM: \(exercise.rangeOfMotion)→\(rangeOfMotion)") }

            exercise.updateParams(
                reps: reps,
                sets: sets,
                weight: weight,
                pauseBetweenSets: pauseBetweenSets,
                tempo: tempo,
                rangeOfMotion: rangeOfMotion
            )

            if !changes.isEmpty || (note?.isEmpty == false) {
                logHistory(
                    exerciseId: exercise.id,
                    action: .updated,
                    changes: changes.isEmpty ? "Notiz hinzugefügt" : changes.joined(separator: ", "),
                    notes: note
                )
            }
            try modelContext.save()
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
    }
    
    func removeWarmup(_ warmupId: UUID) throws {
        patient.warmupTemplate.removeAll { $0.id == warmupId }
        try modelContext.save()
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
