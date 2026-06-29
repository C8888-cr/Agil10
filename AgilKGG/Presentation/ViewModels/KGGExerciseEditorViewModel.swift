//
//  KGGExerciseEditorViewModel.swift
//  Agil10.0
//
//  Created by Christiane Roth on 27.06.26.
//


//
//  KGGExerciseEditorViewModel.swift
//  AgilKGG
//
//  Übung editieren: Reps, Sets, Gewicht, Tempo, ROM, etc.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class KGGExerciseEditorViewModel: ObservableObject {
    @Published var exercise: KGGExercise
    @Published var editingReps: String
    @Published var editingSets: String
    @Published var editingWeight: String
    @Published var editingPause: String
    @Published var editingTempo: String
    @Published var editingROM: String
    @Published var editingNote: String = ""
    @Published var isSaving = false
    @Published var errorMessage: String?
    
    private let modelContext: ModelContext
    private let patientId: UUID
    
    init(exercise: KGGExercise, modelContext: ModelContext, patientId: UUID) {
        self.exercise = exercise
        self.modelContext = modelContext
        self.patientId = patientId
        
        // Initiale Werte
        self.editingReps = "\(exercise.reps)"
        self.editingSets = "\(exercise.sets)"
        self.editingWeight = String(format: "%.1f", exercise.weight)
        self.editingPause = "\(exercise.pauseBetweenSets)"
        self.editingTempo = exercise.tempo
        self.editingROM = exercise.rangeOfMotion
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        guard let reps = Int(editingReps), reps > 0 else { return false }
        guard let sets = Int(editingSets), sets > 0 else { return false }
        guard let weight = Double(editingWeight), weight >= 0 else { return false }
        guard let pause = Int(editingPause), pause >= 0 else { return false }
        guard !editingTempo.isEmpty else { return false }
        guard !editingROM.isEmpty else { return false }
        return true
    }
    
    // MARK: - Save Changes
    
    func saveChanges() throws {
        guard isValid else {
            errorMessage = "Bitte überprüfen Sie alle Eingaben"
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        let reps = Int(editingReps) ?? exercise.reps
        let sets = Int(editingSets) ?? exercise.sets
        let weight = Double(editingWeight) ?? exercise.weight
        let pause = Int(editingPause) ?? exercise.pauseBetweenSets
        
        exercise.updateParams(
            reps: reps,
            sets: sets,
            weight: weight,
            pauseBetweenSets: pause,
            tempo: editingTempo,
            rangeOfMotion: editingROM
        )
        
        // History-Eintrag erstellen
        if !editingNote.isEmpty {
            let history = KGGExerciseHistory(
                exerciseId: exercise.id,
                patientId: patientId,
                changedBy: "Therapeut",  // Später: aktueller Therapeut
                action: .updated,
                changes: "Reps: \(exercise.reps)→\(reps), Sets: \(exercise.sets)→\(sets), Weight: \(exercise.weight)→\(weight)kg",
                notes: editingNote
            )
            modelContext.insert(history)
        }
        
        try modelContext.save()
        errorMessage = nil
    }
    
    // MARK: - Stepper Helpers
    
    func incrementReps() {
        if let reps = Int(editingReps) {
            editingReps = "\(reps + 1)"
        }
    }
    
    func decrementReps() {
        if let reps = Int(editingReps), reps > 1 {
            editingReps = "\(reps - 1)"
        }
    }
    
    func incrementSets() {
        if let sets = Int(editingSets) {
            editingSets = "\(sets + 1)"
        }
    }
    
    func decrementSets() {
        if let sets = Int(editingSets), sets > 1 {
            editingSets = "\(sets - 1)"
        }
    }
    
    func incrementWeight() {
        if let weight = Double(editingWeight) {
            editingWeight = String(format: "%.1f", weight + 0.5)
        }
    }
    
    func decrementWeight() {
        if let weight = Double(editingWeight), weight >= 0.5 {
            editingWeight = String(format: "%.1f", weight - 0.5)
        }
    }
    
    func incrementPause() {
        if let pause = Int(editingPause) {
            editingPause = "\(pause + 15)"
        }
    }
    
    func decrementPause() {
        if let pause = Int(editingPause), pause >= 15 {
            editingPause = "\(pause - 15)"
        }
    }
}
