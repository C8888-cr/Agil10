

// Core/Domain/Models/Exercise.swift
import SwiftData
import Foundation
@Model
final class Exercise {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var videoURL: URL?            // Lokal oder Cloud
    var isLocal: Bool             // true = eigenes Video
    var thumbnailData: Data?
    
    // Timer-Settings
    var durationSeconds: Int      // Einzelne Übung
    var repetitions: Int          // Wie oft wiederholen?
    var pauseSeconds: Int         // Pause zwischen Reps
    
    // Scheduling
    var scheduledDate: Date?
    var isCompleted: Bool
    var difficultyRating: Int?    // 1-5 nach Ausführung
    
    // Relationships
    var user: User?
    var assignedByTherapist: User? // nil = selbst hinzugefügt
    
    init(
        name: String,
        videoURL: URL?,
        isLocal: Bool = true,
        durationSeconds: Int = 60,
        repetitions: Int = 1,
        pauseSeconds: Int = 30
    ) {
        self.id = UUID()
        self.name = name
        self.videoURL = videoURL
        self.isLocal = isLocal
        self.durationSeconds = durationSeconds
        self.repetitions = repetitions
        self.pauseSeconds = pauseSeconds
        self.isCompleted = false
    }
}
