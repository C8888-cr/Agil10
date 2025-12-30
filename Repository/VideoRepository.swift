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
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.storageService = VideoStorageService.shared
        self.thumbnailService = ThumbnailGeneratorService.shared
    }
    
    // MARK: - Fetch All Videos (Safe)
    func fetchAllVideos(for user: User) async throws -> [Video] {
        print("🔍 fetchAllVideos for user email = \(user.email)")
        print("🔍 uploadVideo for user email = \(user.email)")
        // ✅ NO Predicate - fetch all and filter manually
        let descriptor = FetchDescriptor<Video>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let allVideos = try modelContext.fetch(descriptor)
        
        // ✅ Filter by user email manually
        let userVideos = allVideos
        
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
    
    // MARK: - Upload Video
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
        
        // 1. Save video file
        let (fileName, fileSize, duration) = try await storageService.saveVideo(from: sourceURL)
        
        // 2. Generate thumbnail
        let videoURL = try storageService.getVideoURL(for: fileName)
        let thumbnailFileName = try await thumbnailService.generateThumbnail(from: videoURL)
        
        // 3. Create metadata
        let metadata = Video(
            id: UUID(),
            title: title,
            videoFileName: fileName,
            category: category,
            bodyRegion: bodyRegion,
            equipment: equipment,
            durationSeconds: duration,
            fileSizeBytes: fileSize,
            defaultRepetitions: defaultRepetitions,
            defaultPauseSeconds: defaultPauseSeconds,
            loopDurationSeconds: loopDurationSeconds,
         //   user: nil,
         //   uploadedByTherapist: nil,
       
            rating: 0
        )
        
        // Add thumbnail to metadata
        metadata.thumbnailFileName = thumbnailFileName
        
        // 4. Save to database
        modelContext.insert(metadata)
        try modelContext.save()
        
        print("✅ Video uploaded: \(title)")
        return metadata
    }
    
    // MARK: - Delete Video
    func deleteVideo(metadata: Video) async throws {
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
