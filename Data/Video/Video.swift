//
//  Video.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import SwiftData
import Foundation
import SwiftUI

@Model
final class Video {
    
    // ✅ CASCADE DELETE: Wenn Video gelöscht wird
    @Relationship(deleteRule: .cascade)
        var schedules: [VideoSchedule]?
    // NEU: Tempo-Protokoll für Expertenmodus (nur bei category == .strength)
    @Relationship(deleteRule: .cascade)
    var tempoProtocol: TempoProtocol?

    @Attribute(.unique) var id: UUID = UUID()
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
