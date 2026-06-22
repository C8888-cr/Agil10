
//
//  QRPayload.swift
//  Agil10.0
//
//  Steuer- & Schlüsselebene pro Patient/Besuch.
//  Transportiert zugewiesene KGG-Übungen inkl. Datenschlüssel der Videos.
//  Enthält bewusst KEINE Videobytes — nur IDs, Zahlen und Keys.
//

import Foundation

/// Eine einzelne zugewiesene Übung inkl. allem, was Handy zum Freischalten braucht.
struct ExerciseAssignment: Codable, Identifiable, Equatable {
    let exerciseId: UUID      // Welche KGG-Übung/welches Video
    let reps: Int             // Vorgegebene Wiederholungen
    let weight: Double        // Vorgegebenes Gewicht (kg)
    let videoKey: Data        // Datenschlüssel des zugewiesenen Videos (Envelope)

    var id: UUID { exerciseId }
}

/// Gesamter QR-Inhalt für einen Besuch. Letzter gescannter QR = Single Source of Truth.
struct QRPayload: Codable, Equatable {
    let version: Int                          // Schema-Version, für spätere Migration
    let issuedAt: Date                        // Wann erstellt (Gültigkeit/Frische prüfbar)
    let assignments: [ExerciseAssignment]     // Die zugewiesenen Übungen

    init(version: Int = 1,
         issuedAt: Date = Date(),
         assignments: [ExerciseAssignment]) {
        self.version = version
        self.issuedAt = issuedAt
        self.assignments = assignments
    }
}
