//
//  QRPayload.swift
//  AgilCore
//
//  Steuer- & Schlüsselebene pro Patient/Besuch.
//  Transportiert zugewiesene KGG-Übungen mit verschlüsselten Videos als Base64.
//  Alles was der Patient braucht ist im QR enthalten.
//

import Foundation

/// Eine einzelne zugewiesene Übung mit verschlüsseltem Video als Base64.
/// Alles was das Handy zum Spielen braucht.
public struct ExerciseAssignment: Codable, Identifiable, Equatable {
    
    // MARK: - Video & Identification
    
    public let exerciseId: UUID              // Eindeutige Übungs-ID
    public let videoTitle: String            // Titel für Patient (z.B. "Bizeps-Curls")
    public let videoKey: Data                // AES-GCM Schlüssel zum Entschlüsseln
    public let encryptedVideoBase64: String  // Verschlüsseltes Video als Base64
    
    // MARK: - Training Parameters (aus KGGExercise)
    
    public let reps: Int                     // Wiederholungen pro Satz
    public let sets: Int                     // Anzahl Sätze
    public let weight: Double                // Gewicht in kg
    public let pauseBetweenSets: Int         // Pause zwischen Sätzen (Sekunden)
    
    // MARK: - Tempo Protocol (eccentric-hold-concentric)
    
    public let tempo: String                 // Format: "2-0-2" (concentric-hold-eccentric)
    
    // MARK: - Identifiable
    
    public var id: UUID { exerciseId }
    
    // MARK: - Initializer
    
    public init(
        exerciseId: UUID,
        videoTitle: String,
        reps: Int,
        sets: Int,
        weight: Double,
        pauseBetweenSets: Int,
        tempo: String,
        videoKey: Data,
        encryptedVideoBase64: String
    ) {
        self.exerciseId = exerciseId
        self.videoTitle = videoTitle
        self.reps = reps
        self.sets = sets
        self.weight = weight
        self.pauseBetweenSets = pauseBetweenSets
        self.tempo = tempo
        self.videoKey = videoKey
        self.encryptedVideoBase64 = encryptedVideoBase64
    }
}

/// Gesamter QR-Inhalt für einen Besuch. Letzter gescannter QR = Single Source of Truth.
public struct QRPayload: Codable, Equatable {
    
    public let version: Int                          // Schema-Version, für Migration
    public let issuedAt: Date                        // Wann erstellt (Frische prüfbar)
    public let assignments: [ExerciseAssignment]     // Die zugewiesenen Übungen (mit Videos!)
    
    public init(
        version: Int = 1,
        issuedAt: Date = Date(),
        assignments: [ExerciseAssignment]
    ) {
        self.version = version
        self.issuedAt = issuedAt
        self.assignments = assignments
    }
}
