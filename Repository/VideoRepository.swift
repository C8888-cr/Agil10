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
        defaultRepetitions: Int,
        defaultPauseSeconds: Int,
        loopDurationSeconds: Int?,
        for user: User
    ) async throws -> Video {
        
        print("🔍 uploadVideo START for user: \(user.email) (ID: \(user.id))")
        
        // ✅ WICHTIG: User im aktuellen Context holen!
        let userInContext = await MainActor.run { () -> User? in
            let descriptor = FetchDescriptor<User>()
            
            do {
                let allUsers = try modelContext.fetch(descriptor)
                let foundUser = allUsers.first(where: { $0.id == user.id })
                
                if let foundUser = foundUser {
                    print("✅ User found in context: \(foundUser.email)")
                    return foundUser
                } else {
                    print("❌ User NOT in context, inserting...")
                    modelContext.insert(user)
                    try modelContext.save()
                    return user
                }
            } catch {
                print("❌ Failed to fetch user: \(error)")
                return nil
            }
        }
        
        guard let validUser = userInContext else {
            throw NSError(
                domain: "VideoRepository",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "User nicht im Context gefunden"]
            )
        }
        
        // 1. Save video file
        print("📁 Saving video file...")
        let (fileName, fileSize, duration) = try await storageService.saveVideo(from: sourceURL)
        print("✅ File saved: \(fileName), size: \(fileSize), duration: \(duration)")
        
        // 2. Generate thumbnail
        print("🖼️ Generating thumbnail...")
        let videoURL = try storageService.getVideoURL(for: fileName)
        let thumbnailFileName = try await thumbnailService.generateThumbnail(from: videoURL)
        print("✅ Thumbnail saved: \(thumbnailFileName)")
        
        // 3. Create metadata mit VALIDEM User
        print("📝 Creating Video object...")
        let metadata = Video(
            id: UUID(),
            title: title,
            videoFileName: fileName,
            category: category,
            bodyRegion: bodyRegion,
            equipment: equipment,
            durationSeconds: Int(duration),
            fileSizeBytes: fileSize,
            defaultRepetitions: defaultRepetitions,
            defaultPauseSeconds: defaultPauseSeconds,
            loopDurationSeconds: loopDurationSeconds,
            user: validUser,  // ✅ User aus Context!
            uploadedByTherapist: nil,
            isWatched: false,
            rating: 0
        )
        
        metadata.thumbnailFileName = thumbnailFileName
        print("📦 Video created: \(metadata.title) for user: \(validUser.email)")
        
        // 4. Save on MainActor
        await MainActor.run {
            print("💾 [MainActor] Inserting...")
            modelContext.insert(metadata)
            
            do {
                print("💾 [MainActor] Saving...")
                try modelContext.save()
                print("✅ [MainActor] SAVED!")
            } catch {
                print("❌ [MainActor] Save failed: \(error)")
            }
        }
        
        // 5. Verify
        let verified = await MainActor.run { () -> Bool in
            print("🔍 [MainActor] Verifying...")
            modelContext.processPendingChanges()
            
            let descriptor = FetchDescriptor<Video>()
            
            do {
                let allVideos = try modelContext.fetch(descriptor)
                print("📊 [MainActor] Total videos: \(allVideos.count)")
                
                return allVideos.contains(where: { $0.id == metadata.id })
            } catch {
                print("❌ [MainActor] Verify failed: \(error)")
                return false
            }
        }
        
        if !verified {
            throw NSError(
                domain: "VideoRepository",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Video nicht gespeichert"]
            )
        }
        
        print("✅ Upload complete: \(title)")
        return metadata
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
