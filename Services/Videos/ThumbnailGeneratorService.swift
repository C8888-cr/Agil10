//
//  ThumbnailError.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import Foundation
import AVFoundation
import UIKit

final class ThumbnailGeneratorService {
    static let shared = ThumbnailGeneratorService()
    
    private let fileManager = FileManager.default
    private let thumbnailSize = CGSize(width: 400, height: 300) // 4:3 Ratio
    private let jpegQuality: CGFloat = 0.7
    
    private init() {}
    
    // MARK: - Generate & Save Thumbnail
    
    /// Thumbnail aus Video generieren und speichern
    func generateThumbnail(
        from videoURL: URL,
        at timeInSeconds: Double = 1.0
    ) async throws -> String {
        // 1. Thumbnail-Image generieren
        let image = try await generateThumbnailImage(from: videoURL, at: timeInSeconds)
        
        // 2. Eindeutigen Dateinamen erstellen
        let fileName = generateThumbnailFileName()
        
        // 3. Als JPEG speichern
        try saveThumbnail(image: image, fileName: fileName)
        
        return fileName
    }
    
    // MARK: - Generate Image
    
    private func generateThumbnailImage(
        from videoURL: URL,
        at timeInSeconds: Double
    ) async throws -> UIImage {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        // Qualität & Performance Settings
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = thumbnailSize
        
        // Zeitpunkt für Screenshot
        let time = CMTime(seconds: timeInSeconds, preferredTimescale: 600)
        
        do {
            let cgImage = try await imageGenerator.image(at: time).image
            return UIImage(cgImage: cgImage)
        } catch {
            throw ThumbnailError.generationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Save Thumbnail
    
    private func saveThumbnail(image: UIImage, fileName: String) throws {
        guard let data = image.jpegData(compressionQuality: jpegQuality) else {
            throw ThumbnailError.saveFailed("JPEG-Konvertierung fehlgeschlagen")
        }
        
        let thumbnailURL = VideoStorageService.shared.getThumbnailURL(for: fileName)
        
        do {
            try data.write(to: thumbnailURL)
        } catch {
            throw ThumbnailError.saveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Load Thumbnail
    
    /// Thumbnail laden
    func loadThumbnail(fileName: String) -> UIImage? {
        let thumbnailURL = VideoStorageService.shared.getThumbnailURL(for: fileName)
        
        guard fileManager.fileExists(atPath: thumbnailURL.path),
              let data = try? Data(contentsOf: thumbnailURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    // MARK: - Helper
    
    private func generateThumbnailFileName() -> String {
        let uuid = UUID().uuidString
        return "thumb_\(uuid).jpg"
    }
}
// MARK: - Convenience
extension ThumbnailGeneratorService {
    /// Thumbnail generieren oder Platzhalter zurückgeben
    func getThumbnailOrPlaceholder(fileName: String?) -> UIImage {
        guard let fileName = fileName,
              let thumbnail = loadThumbnail(fileName: fileName) else {
            return createPlaceholderImage()
        }
        return thumbnail
    }
    
    private func createPlaceholderImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        return renderer.image { context in
            // Gradient Background
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0.0, 1.0]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: thumbnailSize.width, y: thumbnailSize.height),
                options: []
            )
            
            // Play Icon
            let iconSize: CGFloat = 80
            let iconRect = CGRect(
                x: (thumbnailSize.width - iconSize) / 2,
                y: (thumbnailSize.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            
            let config = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .light)
            let playIcon = UIImage(systemName: "play.circle.fill", withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            
            playIcon?.draw(in: iconRect)
        }
    }
}
