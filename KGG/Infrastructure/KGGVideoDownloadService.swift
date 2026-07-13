//
//  KGGVideoDownloadService.swift
//  Agil
//
//  Video-Verarbeitung: Decrypt + Lokale Speicherung.
//  Hinweis: Videos kommen jetzt als Base64 im QR, kein Download nötig.
//

import Foundation
import AgilCore
import CryptoKit

public final class KGGVideoDownloadService {
    
    public enum VideoError: LocalizedError {
        case decryptionFailed(String)
        case storageFailed(String)
        case invalidFileFormat
        case insufficientDiskSpace
        
        public var errorDescription: String? {
            switch self {
            case .decryptionFailed(let reason):
                return "Entschlüsselung fehlgeschlagen: \(reason)"
            case .storageFailed(let reason):
                return "Speichern fehlgeschlagen: \(reason)"
            case .invalidFileFormat:
                return "Video-Format ungültig."
            case .insufficientDiskSpace:
                return "Nicht genug Speicherplatz verfügbar."
            }
        }
    }
    
    private let fileManager = FileManager.default
    private let cryptoService = CryptoService()
    
    private var kggVideosDirectory: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("KGG")
            .appendingPathComponent("Videos")
    }
    
    public init() {
        createDirectoriesIfNeeded()
    }
    
    // MARK: - Public API
    
    /// Entschlüsselt Video-Data und speichert sie lokal
    /// - Parameters:
    ///   - exerciseId: UUID der Übung
    ///   - encryptedData: AES-GCM verschlüsselte Video-Bytes
    ///   - decryptionKey: Entschlüsselungs-Schlüssel
    /// - Returns: Lokaler Dateiname
    public func decryptAndSaveVideo(
        exerciseId: UUID,
        encryptedData: Data,
        using decryptionKey: SymmetricKey
    ) throws -> String {
        
        // 1. Prüfe Disk-Space
        try checkAvailableDiskSpace()
        
        // 2. Entschlüssele
        let decrypted = try cryptoService.decrypt(encryptedData, using: decryptionKey)
        
        // 3. Speichere lokal
        let fileName = videoFileName(for: exerciseId)
        guard let finalURL = kggVideosDirectory?.appendingPathComponent(fileName) else {
            throw VideoError.storageFailed("Zielverzeichnis nicht verfügbar")
        }
        
        try decrypted.write(to: finalURL)
        return fileName
    }
    
    /// Prüft ob Video lokal existiert
    public func videoExists(exerciseId: UUID) -> Bool {
        guard let dir = kggVideosDirectory else { return false }
        let path = dir.appendingPathComponent(videoFileName(for: exerciseId)).path
        return fileManager.fileExists(atPath: path)
    }
    
    /// Gibt URL des lokalen Videos zurück (wenn existiert)
    public func getVideoURL(for exerciseId: UUID) -> URL? {
        guard let dir = kggVideosDirectory else { return nil }
        let url = dir.appendingPathComponent(videoFileName(for: exerciseId))
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return url
    }
    
    /// Löscht lokales Video
    public func deleteVideo(exerciseId: UUID) throws {
        guard let dir = kggVideosDirectory else {
            throw VideoError.storageFailed("Verzeichnis nicht verfügbar")
        }
        let url = dir.appendingPathComponent(videoFileName(for: exerciseId))
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    
    /// Löscht alle Videos
    public func deleteAllVideos() throws {
        guard let dir = kggVideosDirectory else { return }
        try fileManager.removeItem(at: dir)
        createDirectoriesIfNeeded()
    }
    
    // MARK: - Private
    
    private func checkAvailableDiskSpace() throws {
        guard let videoDir = kggVideosDirectory else { return }
        
        let fileSystem = try fileManager.attributesOfFileSystem(forPath: videoDir.path)
        guard let freeSpace = fileSystem[.systemFreeSize] as? NSNumber else {
            throw VideoError.storageFailed("Kann Speicherplatz nicht bestimmen")
        }
        
        // Minimum 100MB verfügbar
        let minimumRequired: Int64 = 100 * 1024 * 1024
        
        if freeSpace.int64Value < minimumRequired {
            throw VideoError.insufficientDiskSpace
        }
    }
    
    private func createDirectoriesIfNeeded() {
        guard let dir = kggVideosDirectory else { return }
        try? fileManager.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )
    }
    
    private func videoFileName(for exerciseId: UUID) -> String {
        "\(exerciseId.uuidString).agkv"
    }
    
 
}
