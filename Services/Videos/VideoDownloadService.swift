//
//  VideoDownloadService.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import Foundation
final class VideoDownloadService: NSObject {
    static let shared = VideoDownloadService()
    
    private var session: URLSession!
    private var activeDownloads: [UUID: URLSessionDownloadTask] = [:]
    
    override private init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.agil.videodownload")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func downloadVideo(from url: URL, for videoId: UUID) async throws -> URL {
        let task = session.downloadTask(with: url)
        activeDownloads[videoId] = task
        task.resume()
        
        // Wait for completion
        return try await withCheckedThrowingContinuation { continuation in
            // Implementation needed
        }
    }
    
    func cancelDownload(for videoId: UUID) {
        activeDownloads[videoId]?.cancel()
        activeDownloads.removeValue(forKey: videoId)
    }
}
// MARK: - URLSessionDownloadDelegate
extension VideoDownloadService: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handle completion
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        print("Download progress: \(progress)")
    }
}
