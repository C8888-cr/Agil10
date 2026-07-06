//
//  KGGExerciseHistory.swift
//  Agil10.0
//
//  Created by Christiane Roth on 27.06.26.
//


//
//  KGGExerciseHistory.swift
//  AgilCore
//
//  Timeline: Alle Änderungen an einer Übung dokumentieren
//

import Foundation
import SwiftData

@Model
public final class KGGExerciseHistory {
    @Attribute(.unique) public var id: UUID
    
    public var exerciseId: UUID
    public var exerciseName: String
    public var videoId: UUID
    public var patientId: UUID
    
    // Änderung
    public var timestamp: Date
    public var changedBy: String  // "Dr. Schmidt" / "Therapeut XY"
    public var action: HistoryAction
    public var changes: String  // "Reps: 10→12, Weight: 5→7.5kg"
    public var notes: String?   // Optional: Notiz
    
    public enum HistoryAction: String, Codable {
        case created = "ERSTELLT"
        case updated = "AKTUALISIERT"
        case deleted = "GELÖSCHT"
        case paused = "PAUSIERT"
        case resumed = "WIEDERAUFGENOMMEN"
    }
    
    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        videoId: UUID,
        patientId: UUID,
        changedBy: String,
        action: HistoryAction,
        changes: String,
        notes: String? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.videoId = videoId
        self.patientId = patientId
        self.timestamp = Date()
        self.changedBy = changedBy
        self.action = action
        self.changes = changes
        self.notes = notes
    }
    
    // MARK: - Helpers
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    public var displaySummary: String {
        "\(changedBy) - \(action.rawValue)\n\(changes)"
    }
}
