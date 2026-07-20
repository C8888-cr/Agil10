//
//  KGGExerciseEditorViewModel.swift
//  AgilKGG
//
//  Übung editieren: Reps, Sätze, Gewicht, Pause, Tempo.
//  Typisierte Werte (statt Strings) — passt direkt an das gemeinsame
//  KGGExerciseParameterForm. Änderungen werden in der History protokolliert.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class KGGExerciseEditorViewModel: ObservableObject {
    @Published var exercise: KGGExercise

    // Editier-Werte (typisiert, gebunden an KGGExerciseParameterForm)
    @Published var reps: Int
    @Published var sets: Int
    @Published var weight: Double
    @Published var pause: Int
    @Published var tempo: String

    @Published var isSaving = false
    @Published var errorMessage: String?

    private let modelContext: ModelContext
    private let patientId: UUID

    init(exercise: KGGExercise, modelContext: ModelContext, patientId: UUID) {
        self.exercise = exercise
        self.modelContext = modelContext
        self.patientId = patientId

        self.reps = exercise.reps
        self.sets = exercise.sets
        self.weight = exercise.weight
        self.pause = exercise.pauseBetweenSets
        self.tempo = exercise.tempo
    }

    // MARK: - Validation

    var isValid: Bool {
        reps > 0 && sets > 0 && weight >= 0 && pause >= 0 &&
        !tempo.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Save

    func saveChanges() throws {
        guard isValid else {
            errorMessage = "Bitte überprüfen Sie alle Eingaben"
            return
        }

        isSaving = true
        defer { isSaving = false }

        // Änderungen VOR dem Update erfassen (für die History)
        var changes: [String] = []
        if reps != exercise.reps { changes.append("Reps: \(exercise.reps)→\(reps)") }
        if sets != exercise.sets { changes.append("Sätze: \(exercise.sets)→\(sets)") }
        if weight != exercise.weight { changes.append("Gewicht: \(exercise.weight.formatted())→\(weight.formatted())kg") }
        if pause != exercise.pauseBetweenSets { changes.append("Pause: \(exercise.pauseBetweenSets)→\(pause)s") }
        if tempo != exercise.tempo { changes.append("Tempo: \(exercise.tempo)→\(tempo)") }

        exercise.updateParams(
            reps: reps,
            sets: sets,
            weight: weight,
            pauseBetweenSets: pause,
            tempo: tempo,
            rangeOfMotion: nil   // ROM bleibt unverändert (nicht mehr im UI)
        )

        if !changes.isEmpty {
            let history = KGGExerciseHistory(
                exerciseId: exercise.id,
                exerciseName: exercise.videoTitle,
                videoId: exercise.videoId,
                patientId: patientId,
                changedBy: "Therapeut",
                action: .updated,
                changes: changes.joined(separator: ", "),
                notes: nil
            )
            modelContext.insert(history)
        }

        try modelContext.save()
        errorMessage = nil
    }
}
