//
//  DatabaseHealthService.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  DatabaseHealthService.swift
//  Agil7.0
//
//  Created by Christiane Roth on 10.01.25.
//
import Foundation
import SwiftData
@MainActor
final class DatabaseHealthService {
    static let shared = DatabaseHealthService()
    
    private init() {}
    
    /// Check and cleanup corrupted data
    func performHealthCheck(context: ModelContext) async {
        print("🔍 Starting database health check...")
        
        // 1. Fetch all videos
        let descriptor = FetchDescriptor<Video>()
        
        guard let allVideos = try? context.fetch(descriptor) else {
            print("❌ Failed to fetch videos")
            return
        }
        
        let corruptedCount = 0
        var orphanedCount = 0
        
        // 2. Check each video
        for video in allVideos {
            // Check if accessible
            do {
                _ = video.title
                _ = video.videoFileName
                
                // Check if file exists
                do {
                    _ = try await VideoSourceManager.shared.getVideoURL(for: video)
                } catch {
                    print("⚠️ Orphaned: \(video.title)")
                    context.delete(video)
                    orphanedCount += 1
                }
                
            }
        }
        // 3. Save changes
        if corruptedCount > 0 || orphanedCount > 0 {
            try? context.save()
            print("✅ Cleaned up \(corruptedCount) corrupted + \(orphanedCount) orphaned entries")
        } else {
            print("✅ Database is healthy")
        }
    }
}
