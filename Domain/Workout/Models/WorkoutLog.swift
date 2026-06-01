
//  WorkoutLog.swift
//  Agil
//
//  Append-only Trainingshistorie. Jeder Eintrag ist ein unveränderlicher
//  Snapshot eines Workout-Abschlusses oder einer Korrektur.
//  Snapshots statt @Relationship: Historie überlebt Löschungen von Video/Schedule.
//

import SwiftData
import Foundation

@Model
final class WorkoutLog {
    @Attribute(.unique) var id: UUID = UUID()

    /// Zeitpunkt des Eintrags (= completedAt zum Zeitpunkt des Schreibens).
    var date: Date

    /// "completion" wenn Workout abgeschlossen wurde.
    /// "correction" wenn ein zuvor abgeschlossenes Workout zurückgesetzt wurde.
    /// Bei "correction" ist `durationSeconds` negativ, damit Summen sich aufheben.
    var entryType: String

    // MARK: - Referenz (kann brechen)

    /// Referenz auf den ursprünglichen Schedule.
    /// Bleibt erhalten, auch wenn der Schedule später gelöscht wird.
    var scheduleId: UUID?

    // MARK: - Snapshots (unveränderlich)

    /// Snapshot der Video-ID zum Zeitpunkt des Abschlusses.
    var videoId: UUID?

    /// Snapshot des Video-Titels, damit die Historie auch nach
    /// Video-Löschung lesbar bleibt.
    var videoTitle: String

    /// Eingefrorener Modus (WorkoutModus.rawValue) zum Zeitpunkt des Abschlusses.
    var modusRaw: String

    /// Snapshot der berechneten Dauer in Sekunden.
    /// Negativ bei entryType == "correction".
    var durationSeconds: Int

    /// Snapshot des User-Ratings – falls erfasst.
    var rating: Int?

    /// Snapshot des Progress-Feedbacks, normalisiert auf 0.0-1.0.
    /// Slider direkt, Smileys (0-5) als value/5.0 gespeichert.
    var progressFeedback: Double?

    /// Snapshot der User-ID.
    var userId: UUID

    // MARK: - Computed

    var entryTypeEnum: EntryType {
        EntryType(rawValue: entryType) ?? .completion
    }

    var modus: WorkoutModus {
        WorkoutModus(rawValue: modusRaw) ?? .standard
    }

    enum EntryType: String {
        case completion
        case correction
    }

    // MARK: - Init

    init(
        date: Date,
        entryType: EntryType,
        scheduleId: UUID?,
        videoId: UUID?,
        videoTitle: String,
        modusRaw: String,
        durationSeconds: Int,
        rating: Int?,
        progressFeedback: Double?,
        userId: UUID
    ) {
        self.id = UUID()
        self.date = date
        self.entryType = entryType.rawValue
        self.scheduleId = scheduleId
        self.videoId = videoId
        self.videoTitle = videoTitle
        self.modusRaw = modusRaw
        self.durationSeconds = durationSeconds
        self.rating = rating
        self.progressFeedback = progressFeedback
        self.userId = userId
    }
}
