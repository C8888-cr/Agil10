//
//  Video+UI.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//
import Foundation


// MARK: - Computed Properties & Helpers
extension Video {
    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds)) Min"
        } else {
            return "\(seconds) Sec"
        }
    }
    
    var formattedFileSize: String {
        let mb = Double(fileSizeBytes) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }
}

