//
//  VideoFileService.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  VideoFileService.swift
//  Agil7.0
//
//  Created by Christiane Roth on 10.10.25.
//

//
//  VideoFileService.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.01.25.
//
import Foundation
import UIKit
import AVFoundation
final class VideoFileService {
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    
    private var videosDirectory: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Videos")
    }
    
    private var thumbnailsDirectory: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Thumbnails")
    }
    
    // MARK: - Initialization
    
    init() {
        createDirectoriesIfNeeded()
    }
    
    private func createDirectoriesIfNeeded() {
        guard let videosDir = videosDirectory,
              let thumbnailsDir = thumbnailsDirectory else {
            return
        }
        
        try? fileManager.createDirectory(
            at: videosDir,
            withIntermediateDirectories: true
        )
        try? fileManager.createDirectory(
            at: thumbnailsDir,
            withIntermediateDirectories: true
        )
    }
    
    // MARK: - Video URL
    
    func getVideoURL(for fileName: String) -> URL? {
        guard let videosDir = videosDirectory else { return nil }
        let url = videosDir.appendingPathComponent(fileName)
        
        // Prüfen ob Datei existiert
        guard fileManager.fileExists(atPath: url.path) else {
            print("❌ Video file not found: \(fileName)")
            return nil
        }
        
        return url
    }
    
    func getThumbnailURL(for fileName: String) -> URL? {
        guard let thumbnailsDir = thumbnailsDirectory else { return nil }
        return thumbnailsDir.appendingPathComponent(fileName)
    }
    
    // MARK: - Save Video
    
    func saveVideo(from url: URL) async throws -> String {
        guard let videosDir = videosDirectory else {
            throw VideoError.directoryNotFound
        }
        
        let fileName = "\(UUID().uuidString).mp4"
        let destinationURL = videosDir.appendingPathComponent(fileName)
        
        try fileManager.copyItem(at: url, to: destinationURL)
        
        return fileName
    }
    
    // MARK: - Save Thumbnail
    
    func saveThumbnail(_ image: UIImage) throws -> String {
        guard let thumbnailsDir = thumbnailsDirectory
            else {
                throw VideoError.directoryNotFound
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let destinationURL = thumbnailsDir.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8)
            else {
                throw VideoError.thumbnailGenerationFailed
        }
        
        try imageData.write(to: destinationURL)
        
        return fileName
    }
    
    // MARK: - Delete
    
    func deleteVideo(fileName: String) throws {
        guard let videosDir = videosDirectory else {
            throw VideoError.directoryNotFound
        }
        
        let url = videosDir.appendingPathComponent(fileName)
        try fileManager.removeItem(at: url)
    }
    
    func deleteThumbnail(fileName: String) throws {
        guard let thumbnailsDir = thumbnailsDirectory else {
            throw VideoError.directoryNotFound
        }
        
        let url = thumbnailsDir.appendingPathComponent(fileName)
        try fileManager.removeItem(at: url)
    }
}
