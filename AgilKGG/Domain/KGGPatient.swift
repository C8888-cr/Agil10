//
//  KGGPatient.swift
//  AgilCore
//
//  Patient-Model für KGG-Therapeuten-App
//  Therapist-spezifische Daten (KEINE Auth/Login)
//

import Foundation
import SwiftData

@Model
public final class KGGPatient {
    @Attribute(.unique) public var id: UUID
    @Attribute(.unique) public var patientNumber: String  // Pat1, Pat2, etc.
    
    // Therapist-only Info (VERTRAULICH)
    public var diagnosis: String = ""
    public var movementLimitation: String = ""
    public var restrictions: String = ""
    public var therapeutistNotes: String = ""
    
    // Übungen & Daten
    public var exercises: [KGGExercise] = []
    public var warmupTemplate: [KGGWarmup] = []
    public var goals: [String] = []  // ["Kraft", "Mobilität", etc.]
    
    // Timing
    public var createdAt: Date
    public var lastModified: Date
    public var praxisId: UUID  // "praxis1", "praxis2", etc.
    
    public init(
        id: UUID = UUID(),
        patientNumber: String,
        praxisId: UUID,
        diagnosis: String = "",
        movementLimitation: String = "",
        restrictions: String = ""
    ) {
        self.id = id
        self.patientNumber = patientNumber
        self.praxisId = praxisId
        self.diagnosis = diagnosis
        self.movementLimitation = movementLimitation
        self.restrictions = restrictions
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    // MARK: - Helpers
    
    public func addExercise(_ exercise: KGGExercise) {
        exercises.append(exercise)
        lastModified = Date()
    }
    
    public func removeExercise(_ exerciseId: UUID) {
        exercises.removeAll { $0.id == exerciseId }
        lastModified = Date()
    }
    
    public func addWarmup(_ warmup: KGGWarmup) {
        warmupTemplate.append(warmup)
        lastModified = Date()
    }
}
