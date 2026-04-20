//
//  VideoRepository.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import Foundation
import SwiftData
import AVFoundation
import UIKit

@MainActor
final class VideoRepository: VideoRepositoryProtocol {
    
    // MARK: - Properties
    private let modelContext: ModelContext
    private let storageService: VideoStorageService
    private let thumbnailService: ThumbnailGeneratorService
    
    // MARK: - Init
    init(
        modelContext: ModelContext,
        storageService: VideoStorageService,
        thumbnailService: ThumbnailGeneratorService) {
        self.modelContext = modelContext
        self.storageService = VideoStorageService.shared
        self.thumbnailService = ThumbnailGeneratorService.shared
            
            print("🔧 VideoRepository init")
            print("📦 ModelContext: \(modelContext)")
    }
    
    // MARK: - Fetch All Videos (Safe)
    func fetchAllVideos(for user: User) async throws -> [Video] {
        print("🔍 fetchAllVideos for user: \(user.email) (ID: \(user.id))")
        
   
        // ✅ NO Predicate - fetch all and filter manually
        let descriptor = FetchDescriptor<Video>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let allVideos = try modelContext.fetch(descriptor)
        print("📦 Total videos in DB: \(allVideos.count)")
        
        // ✅ Filter by user relationship
         let userVideos = allVideos.filter { video in
             video.user?.id == user.id
         }
        print("👤 Videos for user \(user.email): \(userVideos.count)")
        
        
        // ✅ Filter corrupted entries
        var validVideos: [Video] = []
        
        for video in userVideos {
            // Try to access critical properties
            if !video.title.isEmpty,
               !video.videoFileName.isEmpty {
                validVideos.append(video)
            } else {
                print("⚠️ Corrupted video entry found, deleting...")
                modelContext.delete(video)
            }
        }
        
        // Save deletions
        if validVideos.count < userVideos.count {
            try modelContext.save()
            print("🗑️ Cleaned up \(userVideos.count - validVideos.count) corrupted entries")
        }
        
        return validVideos
    }
    
    func uploadVideo(
        from sourceURL: URL,
        title: String,
        category: ExerciseCategory,
        bodyRegion: BodyRegion,
        equipment: Equipment,
        exerciseSubtype: ExerciseSubtype? = nil,   // NEU: nur relevant bei Kraft
        for user: User
    ) async throws -> Video {
        
        print("🔍 uploadVideo START for user: \(user.email) (ID: \(user.id))")
        
        let userID = user.persistentModelID
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.persistentModelID == userID }
        )
        guard let validUser = try modelContext.fetch(userDescriptor).first else {
            throw NSError(
                domain: "VideoRepository",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "User nicht im Context gefunden"]
            )
        }
        print("✅ User found: \(validUser.email)")
        
        // 1. Save video file
        print("📁 Saving video file...")
        let (fileName, fileSize, duration) = try await storageService.saveVideo(from: sourceURL)
        print("✅ File saved: \(fileName), size: \(fileSize), duration: \(duration)")
        
        // 2. Generate thumbnail
        print("🖼️ Generating thumbnail...")
        let videoURL = try storageService.getVideoURL(for: fileName)
        let thumbnailFileName = try await thumbnailService.generateThumbnail(from: videoURL)
        print("✅ Thumbnail saved: \(thumbnailFileName)")
        
        // 3. Create Video object
        print("📝 Creating Video object...")
        let video = Video(
            id: UUID(),
            title: title,
            videoFileName: fileName,
            category: category,
            bodyRegion: bodyRegion,
            equipment: equipment,
            durationSeconds: Int(duration),
            fileSizeBytes: fileSize,
            loopDurationSeconds: Int(duration),
            user: validUser,
            uploadedByTherapist: nil,
            isWatched: false,
            rating: 0
        )
        video.thumbnailFileName = thumbnailFileName
        
        // NEU: TempoProtocol nur bei Kraft + Dynamisch erstellen
        if category == .strength, exerciseSubtype == .dynamic {
            let tempoProtocol = TempoProtocol(
                concentricSec: 2,
                holdSec: 0,
                eccentricSec: 3,
                sets: 3,
                reps: 12,
                restBetweenSetsSec: 60,
                subtype: .dynamic
            )
            modelContext.insert(tempoProtocol)
            video.tempoProtocol = tempoProtocol
            print("🏋️ TempoProtocol erstellt: 2-0-3, 3×12, 60s Pause")
        }
        
        print("💾 Inserting & Saving...")
        modelContext.insert(video)
        try modelContext.save()
        print("✅ SAVED!")
        
        // 4. Verify
        modelContext.processPendingChanges()
        let videoID = video.persistentModelID
        let verifyDescriptor = FetchDescriptor<Video>(
            predicate: #Predicate { $0.persistentModelID == videoID }
        )
        guard (try modelContext.fetch(verifyDescriptor)).first != nil else {
            throw NSError(
                domain: "VideoRepository",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Video nicht gespeichert"]
            )
        }
        
        print("✅ Upload complete: \(title)")
        return video
    }
    
    // MARK: - Delete Video
    func deleteVideo(metadata: Video) async throws {
        
        print("🗑️ Starting deletion for: \(metadata.title)")
        
        
        // 1. Delete video file
        try storageService.deleteVideo(fileName: metadata.videoFileName)
        
        // 2. Delete thumbnail
        if let thumbnailFileName = metadata.thumbnailFileName {
            try storageService.deleteThumbnail(fileName: thumbnailFileName)
        }
        
        // 3. Delete from database
        modelContext.delete(metadata)
        try modelContext.save()
        
        print("✅ Video deleted: \(metadata.title)")
    }
    
    // MARK: - Protocol Methods
    func createVideo(metadata: Video) async throws {
        modelContext.insert(metadata)
        try modelContext.save()
    }
    
    func fetchVideo(by id: UUID) async throws -> Video? {
        let descriptor = FetchDescriptor<Video>()
        let allVideos = try modelContext.fetch(descriptor)
        return allVideos.first { $0.id == id }
    }
    
    func updateVideo(metadata: Video) async throws {
        try modelContext.save()
    }
    
    func toggleFavorite(metadata: Video) async throws {
        metadata.isFavorite.toggle()
        try modelContext.save()
    }
    
    func updateLastUsed(metadata: Video) async throws {
        metadata.lastUsedAt = Date()
        try modelContext.save()
    }
    
    func fetchFilteredVideos(
        category: ExerciseCategory?,
        bodyRegion: BodyRegion?,
        equipment: Equipment?,
        searchText: String?,
        favoritesOnly: Bool,
        for user: User
    ) async throws -> [Video] {
        let allVideos = try await fetchAllVideos(for: user)
        
        var filtered = allVideos
        
        // Filter by category
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by body region
        if let bodyRegion = bodyRegion {
            filtered = filtered.filter { $0.bodyRegion == bodyRegion }
        }
        
        // Filter by equipment
        if let equipment = equipment {
            filtered = filtered.filter { $0.equipment == equipment }
        }
        
        // Filter by search text
        if let searchText = searchText, !searchText.isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Filter favorites
        if favoritesOnly {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        return filtered
    }
}
