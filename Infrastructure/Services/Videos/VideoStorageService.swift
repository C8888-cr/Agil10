//
//  VideoStorageError.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import Foundation
import AVFoundation
import UIKit

final class VideoStorageService {
    static let shared = VideoStorageService()
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let videoDirectory: URL
    private let thumbnailDirectory: URL
    
    // Constants
    private let maxVideoSizeBytes: Int64 = 200 * 1024 * 1024 // 200 MB
    private let maxVideoDurationSeconds: Double = 180 // 3 Minuten
    
    // MARK: - Init
    private init() {
        // Videos Ordner
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.videoDirectory = documentsPath.appendingPathComponent("Videos", isDirectory: true)
        self.thumbnailDirectory = documentsPath.appendingPathComponent("Thumbnails", isDirectory: true)
        
        // Ordner erstellen falls nicht vorhanden
        createDirectoriesIfNeeded()
    }
    
    // MARK: - Setup
    private func createDirectoriesIfNeeded() {
        do {
            if !fileManager.fileExists(atPath: videoDirectory.path) {
                try fileManager.createDirectory(at: videoDirectory, withIntermediateDirectories: true)
            }
            if !fileManager.fileExists(atPath: thumbnailDirectory.path) {
                try fileManager.createDirectory(at: thumbnailDirectory, withIntermediateDirectories: true)
            }
        } catch {
            print("❌ Error creating directories: \(error)")
        }
    }
    
    // MARK: - Save Video
    
    /// Video von einer temporären URL speichern
    func saveVideo(from sourceURL: URL) async throws -> (fileName: String, fileSize: Int64, duration: Int) {
        // 1. Validierung
        try await validateVideo(at: sourceURL)
        
        // 2. Eindeutigen Dateinamen generieren
        let fileName = generateUniqueFileName(originalURL: sourceURL)
        let destinationURL = videoDirectory.appendingPathComponent(fileName)
        
        // 3. Datei kopieren
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw VideoStorageError.saveFailed("Kopieren fehlgeschlagen: \(error.localizedDescription)")
        }
        
        // 4. Dateigröße ermitteln
        let fileSize = try getFileSize(at: destinationURL)
        
        // 5. Video-Dauer ermitteln
        let duration = try await getVideoDuration(at: destinationURL)
        
        return (fileName, fileSize, duration)
    }
    
    // MARK: - Load Video
    
    /// Video-URL für Playback laden
    func getVideoURL(for fileName: String) throws -> URL {
        let videoURL = videoDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: videoURL.path) else {
            throw VideoStorageError.fileNotFound
        }
        
        return videoURL
    }
    
    // MARK: - Delete Video
    
    /// Video und zugehöriges Thumbnail löschen
    func deleteVideo(fileName: String) throws {
        let videoURL = videoDirectory.appendingPathComponent(fileName)
        
        do {
            if fileManager.fileExists(atPath: videoURL.path) {
                try fileManager.removeItem(at: videoURL)
            }
        } catch {
            throw VideoStorageError.deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Delete Thumbnail
    
    func deleteThumbnail(fileName: String) throws {
        let thumbnailURL = thumbnailDirectory.appendingPathComponent(fileName)
        
        do {
            if fileManager.fileExists(atPath: thumbnailURL.path) {
                try fileManager.removeItem(at: thumbnailURL)
            }
        } catch {
            throw VideoStorageError.deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Storage Info
    
    /// Gesamten genutzten Speicherplatz berechnen
    func getTotalStorageUsed() -> Int64 {
        var totalSize: Int64 = 0
        
        do {
            let videoFiles = try fileManager.contentsOfDirectory(at: videoDirectory, includingPropertiesForKeys: [.fileSizeKey])
            
            for fileURL in videoFiles {
                let fileSize = try getFileSize(at: fileURL)
                totalSize += fileSize
            }
        } catch {
            print("❌ Error calculating storage: \(error)")
        }
        
        return totalSize
    }
    
    /// Verfügbaren Speicherplatz prüfen
    func getAvailableSpace() -> Int64? {
        do {
            let systemAttributes = try fileManager.attributesOfFileSystem(forPath: videoDirectory.path)
            return systemAttributes[.systemFreeSize] as? Int64
        } catch {
            print("❌ Error getting available space: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateVideo(at url: URL) async throws {
        // 1. Datei existiert?
        guard fileManager.fileExists(atPath: url.path) else {
            throw VideoStorageError.fileNotFound
        }
        
        // 2. Dateigröße prüfen
        let fileSize = try getFileSize(at: url)
        guard fileSize <= maxVideoSizeBytes else {
            throw VideoStorageError.fileTooLarge(maxSize: maxVideoSizeBytes)
        }
        
        // 3. Genug Speicherplatz?
        if let availableSpace = getAvailableSpace() {
            guard availableSpace > fileSize * 2 else { // 2x für Sicherheit
                throw VideoStorageError.insufficientSpace
            }
        }
        
        // 4. Video-Dauer prüfen
        let duration = try await getVideoDuration(at: url)
        guard duration <= Int(maxVideoDurationSeconds) else {
            throw VideoStorageError.saveFailed("Video ist länger als \(Int(maxVideoDurationSeconds / 60)) Minuten")
        }
    }
    
    private func generateUniqueFileName(originalURL: URL) -> String {
        let fileExtension = originalURL.pathExtension
        let uuid = UUID().uuidString
        let timestamp = Int(Date().timeIntervalSince1970)
        return "\(timestamp)_\(uuid).\(fileExtension)"
    }
    
    private func getFileSize(at url: URL) throws -> Int64 {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
    
    private func getVideoDuration(at url: URL) async throws -> Int {
        let asset = AVURLAsset(url: url)
        
        do {
            let duration = try await asset.load(.duration)
            return Int(CMTimeGetSeconds(duration))
        } catch {
            throw VideoStorageError.loadFailed("Dauer konnte nicht ermittelt werden")
        }
    }
    
    // MARK: - Thumbnail Path
    
    func getThumbnailURL(for fileName: String) -> URL {
        thumbnailDirectory.appendingPathComponent(fileName)
    }
}
// MARK: - Extensions
extension VideoStorageService {
    /// Formatierte Speicher-Info für UI
    func getStorageInfo() -> (used: String, available: String) {
        let usedBytes = getTotalStorageUsed()
        let usedMB = Double(usedBytes) / (1024 * 1024)
        let usedFormatted = String(format: "%.1f MB", usedMB)
        
        var availableFormatted = "Unbekannt"
        if let availableBytes = getAvailableSpace() {
            let availableGB = Double(availableBytes) / (1024 * 1024 * 1024)
            availableFormatted = String(format: "%.1f GB", availableGB)
        }
        
        return (usedFormatted, availableFormatted)
    }
}
