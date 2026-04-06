//
//  VideoSourceManager.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import Foundation
final class VideoSourceManager {
    static let shared = VideoSourceManager()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    func getVideoURL(for metadata: Video) async throws -> URL {
        return try getLocalVideoURL(for: metadata)
    }
    
     func getLocalVideoURL(for metadata: Video) throws -> URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosURL = documentsURL.appendingPathComponent("Videos", isDirectory: true)
        let videoURL = videosURL.appendingPathComponent(metadata.videoFileName)
        
        guard fileManager.fileExists(atPath: videoURL.path) else {
            throw VideoSourceError.fileNotFound
        }
        
        return videoURL
    }
    
    func deleteVideo(metadata: Video) async throws {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosURL = documentsURL.appendingPathComponent("Videos", isDirectory: true)
        let videoURL = videosURL.appendingPathComponent(metadata.videoFileName)
        
        if fileManager.fileExists(atPath: videoURL.path) {
            try fileManager.removeItem(at: videoURL)
        }
        
        // ✅ Delete thumbnail if exists
              if let thumbnailFileName = metadata.thumbnailFileName {
                  let thumbnailsURL = documentsURL.appendingPathComponent("Thumbnails", isDirectory: true)
                  let thumbnailURL = thumbnailsURL.appendingPathComponent(thumbnailFileName)
                  
                  if fileManager.fileExists(atPath: thumbnailURL.path) {
                      try? fileManager.removeItem(at: thumbnailURL)
                  }
              }
          }
      }
