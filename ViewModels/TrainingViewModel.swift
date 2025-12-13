
import Foundation
import SwiftUI


class TrainingViewModel: ObservableObject {
    @Published var weekPlan: [DayPlan] = []
    @Published var settings = WeeklySettings()
    @Published var selectedDayIndex = 0
    @Published var showingVideoPlayer = false
    @Published var selectedVideo: Video?
    @Published var showingRating = false
    
    // NEU: Zuweisungen Video → Datum
    @Published var dateExercises: [Date: [DailyExercise]] = [:]
    
    init() {
        setupWeekPlan()
        loadDateExercises()
    }
    
    func setupWeekPlan() {
        let dayNames = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
        weekPlan = dayNames.map { dayName in
            var day = DayPlan(dayName: dayName, targetDuration: TimeInterval(settings.dailyTargetMinutes * 60))
            
            // Dummy Videos für jeden Tag
            if settings.activeDays.contains(dayName) {
                       day.videos = (1...5).map { index in
                           Video(
                               title: "Video \(index)",
                               videoFileName: "video_\(index).mp4",
                               category: .warmup,
                               bodyRegion: .fullBody,
                               equipment: .bodyweight,
                               durationSeconds: 300,
                               fileSizeBytes: 5_000_000,
                               defaultRepetitions: 1,
                               defaultPauseSeconds: 30,
                               loopDurationSeconds: 300,
                               userEmail: "demo@example.com",
                               rating: 3

                           )
                }
            }
            return day
        }
    }
    
    func watchedDuration(for dayIndex: Int) -> TimeInterval {
        return weekPlan[dayIndex].videos
            .filter { $0.isWatched }
            .reduce(0.0) { $0 + Double($1.durationSeconds) }
    }
    
    func weeklyProgress() -> Double {
        let totalTarget = Double(settings.activeDays.count * settings.dailyTargetMinutes * 60)
        let totalWatched = weekPlan.enumerated()
            .filter { settings.activeDays.contains($0.element.dayName) }
            .reduce(0.0) { result, day in
                result + watchedDuration(for: day.offset)
            }
        guard totalTarget > 0 else { return 0.0 }
        return min(totalWatched / totalTarget, 1.0)
    }
    
    func markVideoWatched(_ video: Video) {
        if let dayIndex = weekPlan.firstIndex(where: { $0.videos.contains { $0.id == video.id } }),
           let videoIndex = weekPlan[dayIndex].videos.firstIndex(where: { $0.id == video.id }) {
            weekPlan[dayIndex].videos[videoIndex].isWatched = true
            showingRating = true
        }
    }
    
    func rateVideo(_ video: Video, rating: Int) {
        if let dayIndex = weekPlan.firstIndex(where: { $0.videos.contains { $0.id == video.id } }),
           let videoIndex = weekPlan[dayIndex].videos.firstIndex(where: { $0.id == video.id }) {
            weekPlan[dayIndex].videos[videoIndex].rating = rating
        }
    }
    
    // MARK: - NEU: Date-Based Exercise Management
    
    /// Übungen für ein bestimmtes Datum abrufen
    func exercises(for date: Date) -> [DailyExercise]? {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return dateExercises[normalizedDate]
    }
    
    /// Video einem bestimmten Datum zuweisen
    func assignVideo(_ videoId: UUID, to date: Date, sets: Int? = nil, reps: Int? = nil, notes: String? = nil) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        let exercise = DailyExercise(
            videoId: videoId,
            sets: sets,
            reps: reps,
            notes: notes
        )
        
        if dateExercises[normalizedDate] != nil {
            dateExercises[normalizedDate]?.append(exercise)
        } else {
            dateExercises[normalizedDate] = [exercise]
        }
        
        saveDateExercises()
    }
    
    /// Mehrere Videos einem Datum zuweisen
    func assignVideos(_ videoIds: [UUID], to date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        let exercises = videoIds.map { videoId in
            DailyExercise(videoId: videoId)
        }
        
        if dateExercises[normalizedDate] != nil {
            dateExercises[normalizedDate]?.append(contentsOf: exercises)
        } else {
            dateExercises[normalizedDate] = exercises
        }
        
        saveDateExercises()
    }
    
    /// Übung von einem Datum entfernen
    func removeExercise(_ exerciseId: UUID, from date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        dateExercises[normalizedDate]?.removeAll { $0.id == exerciseId }
        saveDateExercises()
    }
    
    /// Übung als erledigt markieren
    func markExerciseCompleted(_ exerciseId: UUID, on date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        if let index = dateExercises[normalizedDate]?.firstIndex(where: { $0.id == exerciseId }) {
            dateExercises[normalizedDate]?[index].isCompleted = true
            dateExercises[normalizedDate]?[index].completedAt = Date()
            saveDateExercises()
        }
    }
    
    /// Alle Übungen für ein Datum löschen
    func clearExercises(for date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        dateExercises[normalizedDate] = nil
        saveDateExercises()
    }
    
    /// Prüfen ob Datum Übungen hat
    func hasExercises(on date: Date) -> Bool {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return dateExercises[normalizedDate]?.isEmpty == false
    }
    
    /// Fortschritt für ein bestimmtes Datum
    func progressForDate(_ date: Date) -> Double {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        guard let exercises = dateExercises[normalizedDate], !exercises.isEmpty else { return 0.0 }
        
        let completed = exercises.filter { $0.isCompleted }.count
        return Double(completed) / Double(exercises.count)
    }
    
    // MARK: - Storage
    
    private func saveDateExercises() {
        // Konvertiere Dictionary für Storage
        let encodableDict = dateExercises.map { (key, value) in
            DateExerciseEntry(date: key, exercises: value)
        }
        
        if let encoded = try? JSONEncoder().encode(encodableDict) {
            UserDefaults.standard.set(encoded, forKey: "dateExercises")
        }
    }
    
    private func loadDateExercises() {
        if let data = UserDefaults.standard.data(forKey: "dateExercises"),
           let decoded = try? JSONDecoder().decode([DateExerciseEntry].self, from: data) {
            dateExercises = Dictionary(uniqueKeysWithValues: decoded.map { ($0.date, $0.exercises) })
        }
    }

}
// MARK: - Supporting Models
/// Repräsentiert eine Übung an einem bestimmten Tag
struct DailyExercise: Identifiable, Codable, Hashable {
    let id: UUID
    let videoId: UUID
    var sets: Int?
    var reps: Int?
    var notes: String?
    var isCompleted: Bool
    var completedAt: Date?
    
    init(
        id: UUID = UUID(),
        videoId: UUID,
        sets: Int? = nil,
        reps: Int? = nil,
        notes: String? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.videoId = videoId
        self.sets = sets
        self.reps = reps
        self.notes = notes
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}
/// Helper für Storage
struct DateExerciseEntry: Codable {
    let date: Date
    let exercises: [DailyExercise]
}
// MARK: - Training ViewModel Extension (KORRIGIERT)
extension TrainingViewModel {
    /// Übung zu einem Datum hinzufügen (vereinfachte Methode)
    func addExerciseToDate(videoId: UUID, date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        let exercise = DailyExercise(
            videoId: videoId,
            sets: nil,
            reps: nil,
            isCompleted: false
        )
        
        if dateExercises[normalizedDate] != nil {
            dateExercises[normalizedDate]?.append(exercise)
        } else {
            dateExercises[normalizedDate] = [exercise]
        }
        
        saveDateExercises()
    }
}
