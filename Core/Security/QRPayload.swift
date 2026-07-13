//
//  QRPayload.swift
//  AgilCore
//
//  Steuer-Ebene pro Patient/Besuch. Transportiert zugewiesene KGG-Übungen
//  und das Warmup als reine Trainings-Metadaten — kein Video mehr im QR
//  (Video läuft separat über AirDrop/Mediathek, siehe Roadmap).
//

import Foundation

/// Eine einzelne zugewiesene Übung. Kein Video mehr enthalten.
public struct ExerciseAssignment: Codable, Identifiable, Equatable {

    // MARK: - Identification

    public let exerciseId: UUID
    public let videoTitle: String

    // MARK: - Training Parameters (aus KGGExercise)

    public let reps: Int
    public let sets: Int
    public let weight: Double
    public let pauseBetweenSets: Int

    // MARK: - Tempo Protocol (concentric-hold-eccentric)

    public let tempo: String                 // Format: "2-0-2"

    // MARK: - Geräte-Einstellungen (optional)

    public let level: Int?
    public let seatLevel: Int?
    public let notes: String?

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
        level: Int? = nil,
        seatLevel: Int? = nil,
        notes: String? = nil
    ) {
        self.exerciseId = exerciseId
        self.videoTitle = videoTitle
        self.reps = reps
        self.sets = sets
        self.weight = weight
        self.pauseBetweenSets = pauseBetweenSets
        self.tempo = tempo
        self.level = level
        self.seatLevel = seatLevel
        self.notes = notes
    }
}

/// Ein zugewiesenes Warmup — rein informative Anzeige beim Patienten.
public struct WarmupAssignment: Codable, Identifiable, Equatable {

    public let id: UUID
    public let type: String
    public let duration: Int
    public let level: Int?
    public let seatLevel: Int?
    public let speedKmh: Double?
    public let weight: Double?
    public let notes: String?
    public let order: Int

    public init(
        id: UUID,
        type: String,
        duration: Int,
        level: Int? = nil,
        seatLevel: Int? = nil,
        speedKmh: Double? = nil,
        weight: Double? = nil,
        notes: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.type = type
        self.duration = duration
        self.level = level
        self.seatLevel = seatLevel
        self.speedKmh = speedKmh
        self.weight = weight
        self.notes = notes
        self.order = order
    }
}

/// Gesamter QR-Inhalt für einen Besuch. Letzter gescannter QR = Single Source of Truth.
public struct QRPayload: Codable, Equatable {

    public let version: Int
    public let issuedAt: Date
    public let assignments: [ExerciseAssignment]
    public let warmups: [WarmupAssignment]

    public init(
        version: Int = 1,
        issuedAt: Date = Date(),
        assignments: [ExerciseAssignment],
        warmups: [WarmupAssignment] = []
    ) {
        self.version = version
        self.issuedAt = issuedAt
        self.assignments = assignments
        self.warmups = warmups
    }
}
