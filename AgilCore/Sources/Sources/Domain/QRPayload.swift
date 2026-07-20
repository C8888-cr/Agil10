//
//  QRPayload.swift
//  AgilCore
//
//  Steuer- & Schlüsselebene pro Patient/Besuch.
//  Transportiert zugewiesene KGG-Übungen inkl. Datenschlüssel der Videos.
//  Enthält bewusst KEINE Videobytes — nur IDs, Zahlen und Keys.
//

import Foundation

/// Eine einzelne zugewiesene Übung inkl. allem, was Handy zum Freischalten braucht.
public struct ExerciseAssignment: Codable, Identifiable, Equatable {
    public let exerciseId: UUID      // Welche KGG-Übung/welches Video
    public let reps: Int             // Vorgegebene Wiederholungen
    public let weight: Double        // Vorgegebenes Gewicht (kg)
    public let videoKey: Data        // Datenschlüssel des zugewiesenen Videos (Envelope)

    public var id: UUID { exerciseId }
    
    public init(exerciseId: UUID, reps: Int, weight: Double, videoKey: Data) {
        self.exerciseId = exerciseId
        self.reps = reps
        self.weight = weight
        self.videoKey = videoKey
    }
}

/// Gesamter QR-Inhalt für einen Besuch. Letzter gescannter QR = Single Source of Truth.
public struct QRPayload: Codable, Equatable {
    public let version: Int                          // Schema-Version, für spätere Migration
    public let issuedAt: Date                        // Wann erstellt (Gültigkeit/Frische prüfbar)
    public let assignments: [ExerciseAssignment]     // Die zugewiesenen Übungen

    public init(version: Int = 1,
         issuedAt: Date = Date(),
         assignments: [ExerciseAssignment]) {
        self.version = version
        self.issuedAt = issuedAt
        self.assignments = assignments
    }
}
