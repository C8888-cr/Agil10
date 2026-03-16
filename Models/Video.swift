//
//  VideoMetadata.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//
import SwiftData
import Foundation
import SwiftUICore

@Model
final class Video: @unchecked Sendable {
    
    // ✅ CASCADE DELETE: Wenn Video gelöscht wird
    @Relationship(deleteRule: .cascade)
        var schedules: [VideoSchedule]?

    @Attribute(.unique) var id: UUID
    var title: String
    var videoFileName: String           // Lokaler Dateiname
    var thumbnailFileName: String?      // Thumbnail Dateiname
    var thumbnailData: Data?  
    // Kategorisierung
    var categoryRaw: String
    var bodyRegionRaw: String
    var equipmentRaw: String
    
    // Video-Eigenschaften
    var durationSeconds: Int            // Tatsächliche Video-Länge
    var fileSizeBytes: Int64            // Dateigröße
    
    // Planung & Wiedergabe
    var defaultRepetitions: Int         // Standard-Wiederholungen
    var defaultPauseSeconds: Int        // Standard-Pause
    var loopDurationSeconds: Int        // Wie lange soll es in Dauerschleife laufen?

    // Favorit
    var isFavorite: Bool
    
    // Timestamps
    var createdAt: Date
    var lastUsedAt: Date?
    
    var rating: Int?
    
    // Relationships
    var user: User?
    var uploadedByTherapist: User?      // nil = User selbst, sonst Therapeut
    
    // Computed Properties
    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .warmup }
        set { categoryRaw = newValue.rawValue }
    }
    
    var bodyRegion: BodyRegion {
        get { BodyRegion(rawValue: bodyRegionRaw) ?? .fullBody }
        set { bodyRegionRaw = newValue.rawValue }
    }
    
    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .noEquipment }
        set { equipmentRaw = newValue.rawValue }
    }
    
 //   var isFromTherapist: Bool {
  //      uploadedByTherapist != nil
 //   }
    
    var fileSizeMB: Double {
        Double(fileSizeBytes) / (1024 * 1024)
    }
    
    var durationMinutes: Int {
        durationSeconds / 60
    }
    
    // ✅ NEU: Source Tracking
    var sourceRaw: String = VideoSource.recorded.rawValue
    var isCloudVideo: Bool = false
    var cloudVideoID: String?  // ID für Cloud-API
    var requiresPremium: Bool = false  // Freischaltung nötig?
    
    // ✅ NEU: Download Status
    var isDownloaded: Bool = false
    var downloadProgress: Double = 0.0
    var downloadedAt: Date?
    
    // ✅ NEU: Planung
    var scheduledFor: Date?  // Für TodayView/WeekView
    var completedAt: Date?   // Wann wurde das Video zuletzt abgeschlossen?
    var lastPlayedAt: Date?
    
    // Computed Properties
    var source: VideoSource {
        get { VideoSource(rawValue: sourceRaw) ?? .recorded }
        set { sourceRaw = newValue.rawValue }
    }
    
    var availability: VideoAvailability {
        if requiresPremium && !UserDefaults.standard.bool(forKey: "hasPremium") {
            return .requiresPurchase
        }
        
        if downloadProgress > 0 && downloadProgress < 1.0 {
            return .downloading(progress: downloadProgress)
        }
        
        if isDownloaded || source == .recorded {
            return .available
        }
        
        return .cloudOnly
    }
    
    //   var isAvailableOffline: Bool {
    //       availability == .available
    //   }
    var isWatched: Bool
    
    // ✅ KORRIGIERT: Safe accessor - kein Crash bei gelöschtem Video
       var isValid: Bool {
           // ✅ Check if model is still in context
           return !isDeleted
       }
       
       // ✅ KORRIGIERT: Richtiger Property-Name
       var safeThumbnailFileName: String {
           guard isValid else { return "placeholder" }
           return thumbnailFileName ?? "placeholder"
       }
    
    
    init(
        id: UUID = UUID(),
        title: String,
        videoFileName: String,
        category: ExerciseCategory,
        bodyRegion: BodyRegion,
        equipment: Equipment,
        durationSeconds: Int,
        fileSizeBytes: Int64 = 0,
        defaultRepetitions: Int = 1,
        defaultPauseSeconds: Int = 30,
        loopDurationSeconds: Int,
        user: User? = nil,
        uploadedByTherapist: User? = nil,
     
        isWatched: Bool = false,
        rating: Int
    ) {
        self.id = id
        self.title = title
        self.videoFileName = videoFileName
        self.thumbnailFileName = nil  // ✅ Set after creation
        self.categoryRaw = category.rawValue
        self.bodyRegionRaw = bodyRegion.rawValue
        self.equipmentRaw = equipment.rawValue
        self.durationSeconds = durationSeconds
        self.fileSizeBytes = fileSizeBytes
        self.defaultRepetitions = defaultRepetitions
        self.defaultPauseSeconds = defaultPauseSeconds
        self.loopDurationSeconds = loopDurationSeconds

        self.isFavorite = false
        self.createdAt = Date()
        self.lastUsedAt = nil
        self.user = user
        self.uploadedByTherapist = uploadedByTherapist
        self.isWatched = isWatched
        self.rating = rating
    }
}
// MARK: - Computed Properties & Helpers
extension Video {
    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds)) Min"
        } else {
            return "\(seconds) Sec"
        }
    }
    
    var formattedFileSize: String {
        let mb = Double(fileSizeBytes) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }
}

//
//  Exercise.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.10.25.
//

// Core/Domain/Models/Exercise.swift
import SwiftData
import Foundation
@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
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

//
//  VideoSchedule.swift
//  Agil7.0
//
//  Created by Christiane Roth on 08.10.25.
//
import SwiftData
import Foundation
/// Ein geplantes Video für einen bestimmten Tag
@Model
final class VideoSchedule {
    @Attribute(.unique) var id: UUID = UUID()
    
    var scheduledDate: Date             // Für welchen Tag
    var orderIndex: Int                 // Reihenfolge (0, 1, 2...)
    
    //  Startzeit (für Timeline-View)
    var startTime: Date?  // Wann am Tag? (z.B. 18:00)
    
    // Training Details (aus DailyExercise)
       var sets: Int?
       var reps: Int?
       
    
    // Überschreibbare Settings (von VideoMetadata defaults)
    var customRepetitions: Int?
    var customPauseSeconds: Int?
    var customLoopDurationSeconds: Int?
    
    // Status
    var isCompleted: Bool = false
    var completedAt: Date?              // ✅ MUSS DRIN SEIN!
    var rating: Int?                    // 1-5 nach Abschluss
    var notes: String?                  // Notizen nach Training
    
    
    // Wiederholungsregel
       var recurrenceRuleRaw: String = RecurrenceRule.single.rawValue
       
       var recurrenceRule: RecurrenceRule {
           get { RecurrenceRule(rawValue: recurrenceRuleRaw) ?? .single }
           set { recurrenceRuleRaw = newValue.rawValue }
       }
    // ✅ NEU: Für Wiederholungsserien - alle verknüpften Schedules
        // haben dieselbe recurrenceGroupID
        var recurrenceGroupID: UUID?
    
    var isAutoGenerated: Bool = false
    var dayOfWeek: Int = 0
    
    var isTemplate: Bool = false
    var templateUserId: UUID?
    
    
    // Relationships
    // ✅ Relationships - CASCADE DELETE funktioniert!
    @Relationship(inverse: \Video.schedules)
       var video: Video?
       var user: User?
    
    // MARK: - Computed Properties
    
    /// Anzahl Wiederholungen (custom oder default)
    var effectiveRepetitions: Int {
        customRepetitions ?? video?.defaultRepetitions ?? 1
    }
    
    /// Pausenzeit zwischen Wiederholungen (custom oder default)
    var effectivePauseSeconds: Int {
        customPauseSeconds ?? video?.defaultPauseSeconds ?? 30
    }
    
    /// Dauer eines einzelnen Loops (custom oder default)
    var effectiveLoopDurationSeconds: Int {
        customLoopDurationSeconds ?? video?.loopDurationSeconds ?? 0
    }
    
    /// Gesamtdauer dieser Übung (Übungszeit + Pausen zwischen Wiederholungen)
    /// ⚠️ Inter-Video Pause ist NICHT enthalten - wird auf Tagesebene berechnet
    var totalDurationSeconds: Int {
        let singleDuration = effectiveLoopDurationSeconds
        let totalExerciseTime = singleDuration * effectiveRepetitions
        
        // Pausen zwischen Wiederholungen
        // Beispiel: 3 Wiederholungen → 2 Pausen (zwischen 1-2 und 2-3)
        let pauseBetweenReps = effectivePauseSeconds * max(0, effectiveRepetitions - 1)
        
        return totalExerciseTime + pauseBetweenReps
    }
    
    /// Gesamtdauer in Minuten
    var totalDurationMinutes: Int {
        totalDurationSeconds / 60
    }
    
    /// Formatierte Zeitangabe (z.B. "7:30 Min" oder "5 Min")
    var formattedDuration: String {
        let minutes = totalDurationSeconds / 60
        let seconds = totalDurationSeconds % 60
        
        if seconds > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return "\(minutes)"
    }
    
    // MARK: - Init
    
    init(
        scheduledDate: Date,
        startTime: Date? = nil,
        orderIndex: Int,
        video: Video,
        customRepetitions: Int? = nil,
        customPauseSeconds: Int? = nil,
        customLoopDurationSeconds: Int? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        user: User? = nil,
        sets: Int? = nil,
        reps: Int? = nil,
        recurrenceRule: RecurrenceRule = .single,
        recurrenceGroupID: UUID? = nil
     
    ) {
        self.id = UUID()
        self.scheduledDate = scheduledDate
        self.startTime = startTime ?? scheduledDate
        self.orderIndex = orderIndex
        self.video = video
        self.customRepetitions = customRepetitions
        self.customPauseSeconds = customPauseSeconds
        self.customLoopDurationSeconds = customLoopDurationSeconds
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.user = user
        self.sets = sets
        self.reps = reps
        self.recurrenceRuleRaw = recurrenceRule.rawValue  
        self.recurrenceGroupID = recurrenceGroupID
    }
}
