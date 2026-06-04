
//  WriteWorkoutLogUseCase.swift
//  Agil
//
//  Schreibt unveränderliche Log-Einträge in die Trainingshistorie.
//  Wird vom ToggleScheduleCompletionUseCase aufgerufen:
//  - logCompletion: bei markCompleted
//  - logCorrection: bei markIncomplete (mit negativer Dauer → neutralisiert Summen)
//

import Foundation

@MainActor
final class WriteWorkoutLogUseCase {
    private let repository: WorkoutLogRepositoryProtocol

    init(repository: WorkoutLogRepositoryProtocol) {
        self.repository = repository
    }

    /// Schreibt einen Completion-Eintrag aus einem abgeschlossenen Schedule.
    /// Erwartet, dass schedule.isCompleted == true und completedAt/completedModusRaw gesetzt sind.
    func logCompletion(from schedule: VideoSchedule) throws {
        guard let userId = schedule.user?.id else {
            // Ohne User kein Eintrag — Historie ist user-gebunden.
            return
        }

        let modusRaw = schedule.completedModusRaw ?? WorkoutModus.standard.rawValue
        let modus = WorkoutModus(rawValue: modusRaw) ?? .standard
        let duration = schedule.effectiveDurationSeconds(modus: modus)

                // Feedback aus mehreren Quellen ableiten:
                // 1. explizites progressFeedback, 2. mobilityFeedback (Slider),
                // 3. rating (Smiley 1-5) normalisiert auf 0.0-1.0.
                let derivedFeedback: Double? = {
                    if let pf = schedule.progressFeedback { return pf }
                    if let mf = schedule.mobilityFeedback { return mf }
                    if let r = schedule.rating { return Double(r) / 5.0 }
                    return nil
                }()

                let log = WorkoutLog(
                    date: schedule.completedAt ?? Date(),
                    entryType: .completion,
                    scheduleId: schedule.id,
                    videoId: schedule.video?.id,
                    videoTitle: schedule.video?.title ?? "Unbekannt",
                    modusRaw: modusRaw,
                    durationSeconds: duration,
                    rating: schedule.rating,
                    progressFeedback: derivedFeedback,
                    weightKg: schedule.activeWeightKg(modus: modus),
                    userId: userId
                )

        try repository.insert(log)
    }

    /// Schreibt einen Korrektur-Eintrag wenn ein abgeschlossener Schedule
    /// wieder auf "nicht erledigt" gesetzt wird. Negative Dauer neutralisiert
    /// vorherige Completion in Statistik-Summen.
    func logCorrection(for schedule: VideoSchedule, originalModusRaw: String?) throws {
        guard let userId = schedule.user?.id else { return }

        let modusRaw = originalModusRaw ?? WorkoutModus.standard.rawValue
        let modus = WorkoutModus(rawValue: modusRaw) ?? .standard
        // Negative Dauer im selben Modus wie die ursprüngliche Completion
        let duration = -schedule.effectiveDurationSeconds(modus: modus)

        let log = WorkoutLog(
                    date: Date(),
                    entryType: .correction,
                    scheduleId: schedule.id,
                    videoId: schedule.video?.id,
                    videoTitle: schedule.video?.title ?? "Unbekannt",
                    modusRaw: modusRaw,
                    durationSeconds: duration,
                    rating: nil,
                    progressFeedback: nil,
                    weightKg: nil,
                    userId: userId
                )

        try repository.insert(log)
    }
}
