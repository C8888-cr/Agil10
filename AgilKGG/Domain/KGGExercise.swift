//  KGGExercise.swift
//  AgilCore
//
//  Übungs-Modell: Referenz zu KGG-Video + alle therapeutischen Parameter
//

import Foundation
import SwiftData

@Model
public final class KGGExercise {
    @Attribute(.unique) public var id: UUID
    
    // Video-Referenz
    public var videoId: UUID  // Referenz zu Video in Library
    public var notes: String?
    public var videoTitle: String
    public var videoUrl: URL?
    
    // Kategorisierung
    public var sparte: String  // "Schulter", "Hüfte", etc.
    public var muskelgruppe: String
    public var equipment: String
    
    // AKTUELLE Parameter (editierbar)
    public var reps: Int = 10
    public var sets: Int = 3
    public var weight: Double = 0.0  // kg
    public var pauseBetweenSets: Int = 60  // Sekunden
    public var tempo: String = "2-0-2"   // concentric-hold-eccentric
    public var rangeOfMotion: String = "Full ROM"
    public var level: Int?       // Geräte-Stufe, z.B. Seilzug/Beinpresse-Widerstand
    public var seatLevel: Int?   // Sitzhöhe als Stufe, z.B. Latissimuszug/Beinpresse
        
    
    // Ziele
    public var goals: [String] = []  // ["Kraft", "Mobilität"]
    
    // Timing
    public var assignedAt: Date
    public var lastModified: Date
    
    // Aktiv/Inaktiv (statt Löschen → archivieren, KGG sieht alles, Patient nur aktive)
        public var isActive: Bool = true
        public var deactivatedAt: Date?
        public var deactivationReason: String?
    
    // History (Referenz)
    public var patientId: UUID
    
    public init(
        id: UUID = UUID(),
        videoId: UUID,
        videoTitle: String,
        sparte: String,
        muskelgruppe: String,
        equipment: String,
        patientId: UUID,
        reps: Int = 10,
        sets: Int = 3,
        weight: Double = 0.0,
        pauseBetweenSets: Int = 60,
        tempo: String = "2-0-2",
        rangeOfMotion: String = "Full ROM",
        level: Int? = nil,
        seatLevel: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.videoId = videoId
        self.videoTitle = videoTitle
        self.sparte = sparte
        self.muskelgruppe = muskelgruppe
        self.equipment = equipment
        self.patientId = patientId
        self.reps = reps
        self.sets = sets
        self.weight = weight
        self.pauseBetweenSets = pauseBetweenSets
        self.tempo = tempo
        self.rangeOfMotion = rangeOfMotion
        self.level = level
        self.seatLevel = seatLevel
        self.notes = notes
        self.assignedAt = Date()
        self.lastModified = Date()
    }
    
    // MARK: - Helpers
    
    public func updateParams(
        reps: Int? = nil,
        sets: Int? = nil,
        weight: Double? = nil,
        pauseBetweenSets: Int? = nil,
        tempo: String? = nil,
        rangeOfMotion: String? = nil,
        level: Int? = nil,
        seatLevel: Int? = nil,
        notes: String? = nil
    ) {
        if let reps { self.reps = reps }
        if let sets { self.sets = sets }
        if let weight { self.weight = weight }
        if let pauseBetweenSets { self.pauseBetweenSets = pauseBetweenSets }
        if let tempo { self.tempo = tempo }
        if let rangeOfMotion { self.rangeOfMotion = rangeOfMotion }
        if let level { self.level = level }
        if let seatLevel { self.seatLevel = seatLevel }
        if let notes { self.notes = notes }
        self.lastModified = Date()
    }
    
    public var parameterSummary: String {
        "\(reps)x\(sets) @ \(Int(weight))kg, Pause \(pauseBetweenSets)s"
    }
    /// Deaktiviert die Übung (Patient sieht sie nicht mehr, KGG schon).
        public func deactivate(reason: String? = nil) {
            isActive = false
            deactivatedAt = Date()
            deactivationReason = reason
            lastModified = Date()
        }

        /// Reaktiviert eine zuvor deaktivierte Übung.
        public func reactivate() {
            isActive = true
            deactivatedAt = nil
            deactivationReason = nil
            lastModified = Date()
        }

        public var statusText: String {
            if isActive { return "Aktiv" }
            if let date = deactivatedAt {
                let f = DateFormatter()
                f.locale = Locale(identifier: "de_DE")
                f.dateStyle = .medium
                return "Inaktiv seit \(f.string(from: date))"
            }
            return "Inaktiv"
        }
}
